#!/bin/bash

# Batch TypeScript Error Fix Script
# Systematically categorize and fix TypeScript errors from agent deliverables

set -e  # Exit on error

echo "🔍 TypeScript Batch Error Fix"
echo "=============================="
echo ""

# Step 1: Run typecheck and capture errors
echo "📝 Step 1: Running typecheck and capturing errors..."
npm run typecheck 2>&1 | tee typecheck-errors.txt || true
echo ""

# Step 2: Count total errors
ERROR_COUNT=$(grep -c "error TS" typecheck-errors.txt || echo "0")
echo "📊 Total TypeScript errors found: $ERROR_COUNT"
echo ""

if [ "$ERROR_COUNT" -eq "0" ]; then
    echo "✅ No TypeScript errors found!"
    exit 0
fi

# Step 3: Categorize errors by type
echo "📋 Step 2: Categorizing errors by type..."
echo ""
echo "Error categories (sorted by frequency):"
grep "error TS" typecheck-errors.txt | sed 's/.*error TS[0-9]*: //' | sort | uniq -c | sort -rn | head -20
echo ""

# Step 4: Show affected files
echo "📁 Step 3: Files with errors:"
grep "error TS" typecheck-errors.txt | sed 's/\([^(]*\).*/\1/' | sort | uniq -c | sort -rn | head -20
echo ""

# Step 5: Instructions for manual fixing
echo "🔧 Step 4: Fix errors systematically"
echo ""
echo "Strategy:"
echo "1. Fix most common error type first (highest count above)"
echo "2. Fix across ALL affected files before moving to next error type"
echo "3. Verify after each category: npm run typecheck"
echo ""
echo "Common error patterns and fixes:"
echo ""
echo "❌ Property 'X' does not exist on type 'Y'"
echo "   → Check component prop types, may need to rename props"
echo ""
echo "❌ Cannot find module 'X'"
echo "   → Remove unused imports or install missing dependencies"
echo ""
echo "❌ Type 'X' is not assignable to type 'Y'"
echo "   → Check prop types, may need optional chaining or type assertion"
echo ""
echo "❌ Argument of type 'X' is not assignable to parameter of type 'Y'"
echo "   → Check function signatures, may need to update call sites"
echo ""

# Step 6: Save report
echo "💾 Saving error report to: typecheck-errors.txt"
echo ""
echo "Next steps:"
echo "1. Review error categories above"
echo "2. Fix most common error across all files"
echo "3. Run: npm run typecheck"
echo "4. Repeat for next error category"
echo "5. When complete, delete typecheck-errors.txt"
echo ""
echo "✅ Error analysis complete!"
