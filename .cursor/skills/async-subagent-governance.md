---
description: >
  Governs the safe use of Cursor 3.2 async subagents (/@multitask and parallel agent
  runs). Covers resource contention, cross-branch conflicts, workspace isolation, approval
  coordination, and kill-switch protocols. Essential for anyone using Cursor 3.1+ with
  parallel agents — non-technical founders will not spot the failure modes.
  Use when: (1) using /multitask or /fan in Cursor, (2) running multiple agents in parallel,
  (3) configuring tiled agent layouts, (4) agents target overlapping files or branches,
  (5) scaling agent workloads across tasks.
globs: ["**/*.md", "**/*.py", "**/*.ts", "**/*.js", "**/*.tsx", "**/*.jsx"]
alwaysApply: false
tags: [product]
---

# Async Subagent Governance

## Purpose

Cursor 3.1+ (April 2026) introduced **async subagents** — parallel agent runs via `/multitask` in the Agents Window. Instead of queuing tasks, Cursor now spawns multiple agents simultaneously via its "fleet" system. These agents can target different branches, worktrees, or files in parallel.

This is powerful but introduces failure modes that don't exist with single-agent workflows: agents can produce conflicting changes, race on shared resources, generate redundant work, or collectively exhaust your API quota before you notice.

**For non-technical founders:** Imagine hiring 10 developers, giving them all different parts of a project, and not watching what they do until they all email you at once. That's async subagents without governance.

## Activation

This skill activates when you mention:
- "multitask", "/multitask", "parallel agents"
- "async subagent", "fleet", "fan out"
- "multiple agents", "tiled layout", "agents window"
- "cross-repo", "multi-root workspace", "worktree"
- "agent conflicted", "parallel conflict"

Also activates when:
- Using the `/multitask` slash command in Cursor
- Multiple agent sessions are visible in the Agents Window
- Running agents across worktrees or multi-root workspaces

## Risk Model

### What Async Subagents Change

| Capability | Single Agent | Async Subagents |
|---|---|---|
| Queueing | Tasks run one at a time | Tasks run simultaneously |
| Conflict detection | N/A — only one editor | Multiple agents can edit same files |
| Resource consumption | Predictable | Unbounded without limits |
| Merge complexity | One PR | Multiple simultaneous PRs |
| Cost visibility | Clear per-task cost | Bills aggregate, harder to trace |
| Error isolation | One failing task | Cascading failures across agents |
| Workspace state | Linear history | Branch divergence, merge conflicts |

### Specific Failure Modes

**1. File Contention (The Merge Problem)**
Two subagents editing the same file will produce conflicting diffs. The merge conflict resolution may silently drop changes from one agent if not carefully reviewed.

**2. Shared Resource Race Conditions**
If subagents both run database migrations, install packages, or modify shared config, the order of execution becomes non-deterministic. Results depend on timing, not logic.

**3. Budget Exhaustion**
Five parallel subagents each making expensive LLM calls can burn through your monthly API quota in minutes. No single agent looks like the problem until the bill arrives.

**4. Cascading Bad Decisions**
Agent A makes a subtle architectural mistake. Agent B, running concurrently, builds on top of that mistake. By the time Agent A's output is reviewed, Agent B has compounded the error.

**5. Cross-Worktree Contamination**
Agents running in different worktrees on the same repo may access shared build artifacts, node_modules, or cached outputs. Changes in one worktree can leak into another.

**6. Multi-Root Workspace Scope Bleed**
In Cursor 3.2's multi-root workspace mode, agents with access to multiple repos may inadvertently apply changes across repo boundaries if file paths overlap.

## Governance Rules

### Before Running Parallel Agents

1. **Scope Segregation**: Assign each subagent to distinct files, directories, or branches. Never let two agents target overlapping file paths.

2. **Branch Isolation**: Use worktrees or feature branches. Each subagent works on its own branch. Merge only after individual review.

3. **API Quota Budget**: Before fanning out, check your remaining API quota. Set a per-agent token budget that ensures the total fleet won't exceed your monthly limit.

4. **Change Log Protocol**: Each subagent should document what it changed (which files, what type of change). Use the `## Changes` convention in agent output.

### During Parallel Execution

5. **Monitor Aggregate Cost**: While subagents run, track the combined token usage. Cursor's agents window shows per-agent usage — sum them to check budget health.

6. **Stagger Review**: Review agent outputs in order of risk: database/security changes first, UI/cosmetic changes last.

7. **Kill Switch**: If any subagent produces unexpected changes (modifies files it shouldn't, generates suspicious imports, makes auth changes), cancel all other subagents immediately. Review the problematic output before deciding whether to continue.

### After Parallel Execution

8. **Sequential Merge**: Merge subagent PRs one at a time, not all at once. Test between each merge to catch interaction issues.

9. **Conflict Audit**: When subagents touched overlapping areas, manually verify the merge resolution. Don't trust automatic conflict resolution with AI-generated code.

10. **Retrospective**: After multi-agent sessions, note which scope boundaries worked and which didn't. Build a "do/don't parallelize" list for your team.

## Subagent Communication Patterns

### The "Fan Out, Gather In" Pattern

This is the safest parallel agent workflow:

```
1. Main Agent: Decompose task into independent subtasks
2. Fan Out: Launch one subagent per subtask (isolated scopes)
3. Monitor: Track output quality and resource usage
4. Gather In: Review each subagent's output individually
5. Integrate: Main agent merges reviewed outputs into main branch
```

**Rules for this pattern:**
- Subtasks must be genuinely independent (no shared state)
- Each subagent gets a clear, bounded scope
- No subagent modifies shared config files
- Main agent reviews before any merge

### Anti-Pattern: The "Blind Fan Out"

```
1. Fan out 5 agents with vague instructions
2. Wait for all to complete
3. Try to merge everything
4. Debug why they conflicted
```

**Never do this.** Always scope, always monitor, always review before merge.

## Multi-Root Workspace Rules

Cursor 3.2's multi-root workspaces let a single agent session target multiple folders/repos. This adds complexity:

- **Explicit Scope Declaration**: Before any multi-root agent runs, list which repos it may modify. If a repo is not in the list, changes to it are violations.
- **Cross-Repo Dependency Map**: If agent modifies repo A and repo B touches A, the order matters. Define the dependency chain before running.
- **No Secret Cross-Contamination**: Agents with access to multiple repos must not copy secrets or credentials between them, even accidentally.

## Integration with Other Governance Skills

| Related Skill | How It Interacts |
|---|---|
| Cloud Agent Governance | Async subagents are a form of delegation — all Cloud Agent safeguards still apply |
| Cost Governance | Aggregate fleet costs across all subagents; set per-agent budgets |
| Human Approval | Parallel agents still require individual review before merge |
| Code Quality | Subagent output must meet the same linting and complexity standards |
| Git Security | Each subagent's commits should be traceable to the originating task |

## Quick Reference: When NOT to Parallelize

Do NOT use async subagents for:
- Database schema changes (order matters)
- Authentication or authorization changes (security risk)
- API endpoint refactoring (breaking change coordination)
- Config file modifications (single source of truth)
- Deploy scripts or CI/CD changes (sequential safety)

OK to parallelize:
- Documentation updates across multiple files
- Test writing for independent modules
- CSS/styling changes in different components
- Migration of independent data files
- Code style / linting fixes across different directories

## Checklist: Before You Hit /multitask

- [ ] Tasks are genuinely independent (no shared state)
- [ ] Each agent has a clearly defined file/directory scope
- [ ] Branch or worktree isolation is configured
- [ ] API quota budget is checked and sufficient
- [ ] Per-agent token limits are set
- [ ] Kill switch procedure is understood
- [ ] Merge order is planned (sequential, not parallel)
- [ ] You know which output to review first (highest risk)
