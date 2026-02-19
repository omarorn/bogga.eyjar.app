#!/usr/bin/env node

/**
 * Auto-fix GitHub Issues with Claude
 *
 * This script:
 * 1. Analyzes a GitHub issue using Claude
 * 2. Searches the codebase for relevant files
 * 3. Creates a fix if possible
 * 4. Outputs results for GitHub Actions to create a PR
 */

import Anthropic from '@anthropic-ai/sdk';
import crypto from 'crypto';
import fs from 'fs/promises';
import path from 'path';
import { execSync } from 'child_process';

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

const ISSUE_NUMBER = process.env.ISSUE_NUMBER;
const ISSUE_TITLE = process.env.ISSUE_TITLE;
const ISSUE_BODY = process.env.ISSUE_BODY || '';
const REPO_NAME = process.env.REPO_NAME;

// Helper function to get repository context
async function getRepoContext() {
  try {
    // Get list of files
    const files = execSync('git ls-files', { encoding: 'utf-8' })
      .split('\n')
      .filter(f => f.trim())
      .slice(0, 100); // Limit to first 100 files

    // Get recent commits
    const commits = execSync('git log --oneline -10', { encoding: 'utf-8' });

    return { files, commits };
  } catch (error) {
    console.error('Error getting repo context:', error);
    return { files: [], commits: '' };
  }
}

// Helper function to search for relevant files
async function findRelevantFiles(issue) {
  try {
    // Extract keywords from issue
    const keywords = issue.toLowerCase().match(/\b\w{4,}\b/g) || [];

    // Search for files containing these keywords
    const searchResults = [];
    for (const keyword of keywords.slice(0, 5)) {
      try {
        const results = execSync(
          `git grep -l -i "${keyword}" || true`,
          { encoding: 'utf-8' }
        ).trim();
        if (results) {
          searchResults.push(...results.split('\n'));
        }
      } catch (error) {
        // Ignore grep errors
      }
    }

    // Remove duplicates and limit
    return [...new Set(searchResults)].slice(0, 10);
  } catch (error) {
    console.error('Error finding relevant files:', error);
    return [];
  }
}

// Helper function to read file contents
async function readFiles(filePaths) {
  const fileContents = {};
  for (const filePath of filePaths) {
    try {
      const content = await fs.readFile(filePath, 'utf-8');
      // Limit file size to prevent token overflow
      fileContents[filePath] = content.slice(0, 5000);
    } catch (error) {
      console.error(`Error reading ${filePath}:`, error.message);
    }
  }
  return fileContents;
}

// Main function to analyze and fix the issue
async function fixIssue() {
  console.log(`🔍 Analyzing issue #${ISSUE_NUMBER}: ${ISSUE_TITLE}`);

  // Get repository context
  const repoContext = await getRepoContext();
  const relevantFiles = await findRelevantFiles(ISSUE_TITLE + ' ' + ISSUE_BODY);
  const fileContents = await readFiles(relevantFiles);

  console.log(`📁 Found ${relevantFiles.length} potentially relevant files`);

  // Prepare context for Claude
  const contextMessage = `
Repository: ${REPO_NAME}

Issue #${ISSUE_NUMBER}: ${ISSUE_TITLE}

Description:
${ISSUE_BODY}

Repository Files (first 100):
${repoContext.files.join('\n')}

Recent Commits:
${repoContext.commits}

Relevant File Contents:
${Object.entries(fileContents).map(([path, content]) =>
  `\n--- ${path} ---\n${content}\n`
).join('\n')}
`;

  // Call Claude to analyze and create a fix
  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-5-20250929',
    max_tokens: 8000,
    temperature: 0,
    messages: [
      {
        role: 'user',
        content: `You are an expert software engineer helping to fix GitHub issues automatically.

${contextMessage}

Your task:
1. Analyze this issue carefully
2. Determine if you can create an automated fix
3. If yes, provide the exact file changes needed
4. If no, explain why and what would be needed

Respond in this JSON format:
{
  "can_fix": true/false,
  "analysis": "Brief analysis of the issue",
  "confidence": "high/medium/low",
  "files_to_change": [
    {
      "path": "path/to/file.js",
      "action": "edit/create/delete",
      "content": "full new content of the file (for edit/create)",
      "explanation": "why this change fixes the issue"
    }
  ],
  "summary": "User-friendly summary of the fix for the PR description"
}

Important:
- Only set can_fix=true if you're confident the fix is correct and safe
- Provide complete file contents, not diffs
- Consider the existing code style and patterns
- Don't introduce breaking changes
- If the issue is vague or requires clarification, set can_fix=false`
      }
    ]
  });

  // Parse Claude's response
  const responseText = response.content[0].text;
  console.log('\n📋 Claude Response:\n', responseText);

  let result;
  try {
    // Try to extract JSON from the response
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      result = JSON.parse(jsonMatch[0]);
    } else {
      throw new Error('No JSON found in response');
    }
  } catch (error) {
    console.error('Error parsing Claude response:', error);
    result = {
      can_fix: false,
      analysis: responseText,
      confidence: 'low',
      files_to_change: [],
      summary: 'Could not parse response from Claude'
    };
  }

  // Apply the fix if Claude says it can fix it
  if (result.can_fix && result.files_to_change && result.files_to_change.length > 0) {
    console.log(`\n✅ Claude can fix this issue! Applying changes...`);

    for (const fileChange of result.files_to_change) {
      console.log(`  📝 ${fileChange.action}: ${fileChange.path}`);

      try {
        if (fileChange.action === 'create' || fileChange.action === 'edit') {
          // Create directory if needed
          const dir = path.dirname(fileChange.path);
          await fs.mkdir(dir, { recursive: true });

          // Write the file
          await fs.writeFile(fileChange.path, fileChange.content, 'utf-8');
          console.log(`    ✓ ${fileChange.path} updated`);
        } else if (fileChange.action === 'delete') {
          await fs.unlink(fileChange.path);
          console.log(`    ✓ ${fileChange.path} deleted`);
        }
      } catch (error) {
        console.error(`    ✗ Error applying change to ${fileChange.path}:`, error.message);
      }
    }

    // Set output for GitHub Actions via GITHUB_OUTPUT
    if (process.env.GITHUB_OUTPUT) {
      const delimiter = `ghadelimiter_${crypto.randomUUID()}`;
      await fs.appendFile(
        process.env.GITHUB_OUTPUT,
        `has_changes=true\nsummary<<${delimiter}\n${result.summary}\n${delimiter}\n`
      );
    }
  } else {
    console.log(`\n❌ Claude cannot auto-fix this issue`);
    console.log(`Reason: ${result.analysis}`);

    // Set output for GitHub Actions via GITHUB_OUTPUT
    if (process.env.GITHUB_OUTPUT) {
      const delimiter = `ghadelimiter_${crypto.randomUUID()}`;
      await fs.appendFile(
        process.env.GITHUB_OUTPUT,
        `has_changes=false\nanalysis<<${delimiter}\n${result.analysis}\n${delimiter}\n`
      );
    }
  }
}

// Run the script
fixIssue().catch(error => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});
