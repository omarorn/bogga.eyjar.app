# Session Protocol

**Purpose:** Maintain session state and phase tracking across all Claude Code sessions (local, online, team)

---

## Session Lifecycle

### 1. Session Start
**When:** Opening Claude Code or starting new work session

**Actions:**
1. Read `SESSION.md` to understand current phase
2. Check "Current Phase" and "Next Action"
3. Review "Known Issues" for context
4. Continue from last checkpoint

**Example:**
```
User: "Let's continue working on the project"
Claude: Reading SESSION.md...
        Current Phase: Phase 3 - WebSocket Integration
        Next Action: Connect WebSocket in Admin Dashboard
        Proceeding with WebSocket hook integration...
```

### 2. During Work
**When:** Actively working on a task

**Actions:**
1. Update `SESSION.md` when changing phases
2. Mark tasks as complete: `[x]` in progress checklist
3. Add "Known Issues" if encountering blockers
4. Update "Last Checkpoint" after significant milestones

**Example:**
```
# After completing task
Claude: Marking task complete in SESSION.md...
        Updated: [x] Connect WebSocket in Admin Dashboard
        Progress: 3/5 tasks complete in Phase 3
```

### 3. Phase Completion
**When:** All tasks in a phase are complete

**Actions:**
1. Change phase status from 🔄 to ✅
2. Update "Current Phase" to next phase
3. Set "Next Action" for new phase
4. Update "Last Checkpoint" with completion date

**Example:**
```markdown
## Phase 3: WebSocket Real-Time Integration ✅
**Completed**: December 30, 2025
**Summary**: WebSocket connected, real-time updates working

## Phase 4: Customer Portal Implementation 🔄
**Type**: UI | **Started**: December 30, 2025
**Next Action**: Implement authentication flow in portal/innskra.astro
```

### 4. Session End
**When:** Finishing work for the day

**Actions:**
1. Update "Last Checkpoint" with current progress
2. Document any blockers in "Known Issues"
3. Set clear "Next Action" for next session
4. Optionally create git commit

**Example:**
```markdown
**Last Checkpoint**: December 30, 2025 - Phase 3: 3/5 tasks complete (WebSocket connected)
**Next Action**: Test real-time updates with simulated IoT sensor data
```

---

## Key Files

**SESSION.md** (project root):
- Current phase and progress
- Next action to take
- Known issues and blockers
- Quick reference links

**docs/IMPLEMENTATION_PHASES.md**:
- Full phase specifications
- Task lists and verification criteria
- Exit criteria for each phase

**docs/ENV_VARIABLES.md**:
- Required secrets and configuration
- How to get API keys
- Security notes

**docs/INSTALLATION_COMMANDS.md**:
- Copy-paste commands for each phase
- Troubleshooting commands
- Quick reference

---

## Session State Updates

### Update Frequency
- **Every task completion**: Mark task as `[x]` complete
- **Every phase change**: Update current phase, status emoji
- **Every significant blocker**: Add to "Known Issues"
- **Every checkpoint** (hourly or after major milestone): Update "Last Checkpoint"

### What to Track
- ✅ **Do track**: Phase progress, blockers, next actions, completion dates
- ❌ **Don't track**: Low-level code changes, individual function modifications

### Status Emojis
- ⏸️ **Pending** - Not started yet
- 🔄 **In Progress** - Currently working on this phase
- ✅ **Complete** - Phase finished and verified
- 🚫 **Blocked** - Cannot proceed due to external dependency
- ⚠️ **Issues** - Phase has problems but can still proceed

---

## Cross-Session Context

### What Persists Across Sessions
- SESSION.md state (phase, progress, next action)
- Planning docs (IMPLEMENTATION_PHASES.md, ENV_VARIABLES.md)
- Code changes (committed to git)
- Known issues and blockers

### What Doesn't Persist
- Conversation history (summarized at context limit)
- Temporary variables or state
- Uncommitted code changes (if terminal crashes)

### Best Practices
1. **Commit often**: Commit after each phase completion
2. **Update SESSION.md**: Always update before ending session
3. **Document blockers**: Write clear descriptions in "Known Issues"
4. **Clear next actions**: Be specific (file path + line number + what to do)

---

## Phase Transition Protocol

### When Transitioning to Next Phase

1. **Verify Exit Criteria Met**:
   - Check all tasks completed: `[x]` marks
   - Run verification commands from IMPLEMENTATION_PHASES.md
   - Ensure no critical blockers remain

2. **Update SESSION.md**:
   ```markdown
   ## Phase N: [Previous Phase] ✅
   **Completed**: [Date]
   **Summary**: [1-2 sentence summary of what was accomplished]

   ## Phase N+1: [Next Phase] 🔄
   **Started**: [Date]
   **Next Action**: [Specific file + action]
   ```

3. **Optional: Create Checkpoint Commit**:
   ```bash
   git add .
   git commit -m "Checkpoint: Phase N complete - [brief summary]"
   ```

4. **Begin Next Phase**:
   - Read phase specification from IMPLEMENTATION_PHASES.md
   - Review any critical workflows or gotchas
   - Start with first task in task list

---

## Blocker Handling

### When You Encounter a Blocker

1. **Document in SESSION.md**:
   ```markdown
   **Known Issues**:
   - 🚫 **API domain unreachable** (Phase 1) - Requires manual Cloudflare Dashboard config
   - ⚠️ **WebSocket connection dropping** (Phase 3) - Investigating hibernation timeout
   ```

2. **Update Phase Status**:
   - If blocker is critical and blocks all work: 🚫 Blocked
   - If blocker is partial and work can continue: ⚠️ Issues

3. **Set Next Action**:
   - If blocker requires user action: "Waiting for user to configure X"
   - If blocker needs investigation: "Debug Y by checking Z logs"

4. **Ask User for Help (if needed)**:
   - Clearly explain blocker
   - Provide context and what you've tried
   - Suggest possible solutions

---

## Example Session Flow

### Starting Fresh Session
```
User: "Let's work on the project"
Claude: [Reads SESSION.md]
        Current Phase: Phase 3 - WebSocket Integration
        Progress: 2/5 tasks complete
        Next Action: Implement Hibernation API optimization

        I'll continue with the Hibernation API implementation.
        [Proceeds with work...]
```

### Completing a Task
```
Claude: [After implementing hibernation]
        Task complete! Updating SESSION.md...
        - [x] Implement Hibernation API optimization
        Progress: 3/5 tasks in Phase 3
        Next: Add error handling and reconnection logic
```

### Hitting a Blocker
```
Claude: [Encounters issue]
        ⚠️ Blocker found: WebSocket connection dropping after 5 min

        Updating SESSION.md with known issue...
        Investigating: Checking Worker logs and hibernation timeout config

        [After investigation]
        Found: Hibernation timeout too short (2 min instead of 10 min)
        Fix: Update wrangler.jsonc with longer timeout
        [Applies fix...]
```

### Transitioning Phases
```
Claude: [After completing all Phase 3 tasks]
        ✅ Phase 3 complete! All verification criteria met:
        - WebSocket connected and broadcasting
        - Real-time updates working
        - Hibernation active
        - Reconnection logic tested

        Updating SESSION.md...
        Phase 3: ✅ Complete (December 30, 2025)
        Phase 4: 🔄 In Progress
        Next Action: Implement authentication flow in portal/innskra.astro

        Proceeding to Phase 4...
```

---

## Troubleshooting

### SESSION.md Out of Sync
**Problem:** SESSION.md doesn't reflect actual progress

**Solution:**
1. Read actual code state (check files, git log)
2. Verify what's actually complete
3. Update SESSION.md to match reality
4. Document discrepancy in "Known Issues"

### Lost Context Between Sessions
**Problem:** Don't remember what was being worked on

**Solution:**
1. Read SESSION.md "Last Checkpoint"
2. Check "Next Action" for guidance
3. Review "Known Issues" for context
4. If still unclear, ask user: "I see we were working on Phase X. Would you like me to continue with [Next Action] or do something else?"

### Phase Seems Incomplete But Marked Complete
**Problem:** Phase marked ✅ but verification criteria not met

**Solution:**
1. Re-verify exit criteria from IMPLEMENTATION_PHASES.md
2. If criteria not met: Change status back to 🔄 or ⚠️
3. Document what's missing in "Known Issues"
4. Complete remaining tasks before moving forward

---

## Customization for This Project

**Project-Specific Files:**
- `CLAUDE.md` - Development log and session history (comprehensive context)
- `TODO.md` - High-level project status and strategic priorities
- `SESSION.md` - Current phase state (this protocol tracks)
- `docs/IMPLEMENTATION_PHASES.md` - Phase specifications
- `docs/ENV_VARIABLES.md` - Secrets and configuration
- `docs/INSTALLATION_COMMANDS.md` - Copy-paste commands

**Special Considerations:**
- Project is 95% complete - focus on deployment and integration phases
- Manual Cloudflare config required (Phase 1) - cannot be automated
- Real-time WebSocket testing needs multiple browser tabs
- GPS tracking requires physical mobile device testing
- Production deployment is irreversible - test thoroughly first

---

**This rule is committed with the project and works across all environments.**
