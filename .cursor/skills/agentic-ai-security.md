---
description: >
  Maps the OWASP Top 10 for Agentic Applications (ASI) 2026 to concrete governance
  rules for Cursor-based AI agent workflows. Covers agent goal hijack, tool misuse,
  privilege abuse, supply chain compromise, unexpected code execution, memory poisoning,
  inter-agent communication, cascading failures, human-agent trust exploitation, and
  autonomous behaviour boundaries.
  Use when: (1) configuring AI agents with tool access, (2) reviewing agent-generated
  code that calls APIs or executes commands, (3) setting up multi-agent workflows,
  (4) onboarding teams to agentic AI development, (5) auditing agent permissions
  and tool chains.
globs: ["**/.cursorrules", "**/.cursor/rules/**", "**/AGENTS.md", "**/CLAUDE.md", "**/.cursor/mcp.json", "**/package.json"]
alwaysApply: false
tags: [product]
---

# Agentic AI Security (OWASP ASI 2026)

## Purpose

The OWASP Top 10 for Agentic Applications (ASI) 2026 identifies the most critical security risks introduced by autonomous and semi-autonomous AI agents. Unlike traditional LLM applications, agentic systems combine reasoning, memory, tools, and multi-step execution — introducing new vulnerability classes that extend beyond prompt-level attacks.

This skill translates each ASI risk into concrete, actionable governance rules for Cursor-based development.

## Why This Matters for TYO Community

If you're a teacher, founder, or non-technical builder using Cursor agents to ship products, you are operating agentic AI. Your agents call APIs, execute code, read databases, and make decisions. The OWASP ASI framework is your security checklist.

## The 10 Risks and Your Governance Response

### ASI01: Agent Goal Hijack

**Risk:** An attacker manipulates the agent's objective through poisoned inputs, causing it to pursue unintended goals while appearing to work correctly.

**Governance:**
- Every agent task must have a written, scoped objective (not "make it better")
- Review agent output against the *original* stated goal, not just code quality
- Flag any output that addresses unasked questions or solves unreported problems
- Use `human-approval.md` for any agent action that deviates from the stated task

**Cursor-specific:** When using `/multitask` or Build in Parallel, each subagent must have a single, bounded objective. Ambiguous task descriptions are a goal-hijack vector.

### ASI02: Tool Misuse & Exploitation

**Risk:** Agents with access to tools (APIs, databases, file systems, shell) can be tricked into using them maliciously or excessively.

**Governance:**
- Document every tool an agent can access (MCP servers, API keys, shell access)
- Apply least-privilege: agents should only access tools needed for their current task
- Monitor tool invocation logs for unusual patterns (rate, scope, timing)
- Reference: `mcp-security.md` for MCP-specific tool governance

**Cursor-specific:** Cursor's `.cursor/mcp.json` grants tool access. Every MCP server is a tool surface. See MCP Security skill for vetting requirements.

### ASI03: Agent Identity & Privilege Abuse

**Risk:** Agents operate with inherited or excessive privileges, accessing resources beyond their intended scope.

**Governance:**
- Never give agents admin-level API keys when read-only access suffices
- Scope agent credentials to specific repos, not organisation-wide
- Rotate agent API keys separately from human keys
- Audit agent access quarterly — agents accumulate permissions over time

**Cursor-specific:** Cloud Agent environments inherit your Cursor account permissions. Multi-repo automations can access credentials from all attached repos. See Cloud Agent Governance.

### ASI04: Agentic Supply Chain Compromise

**Risk:** Malicious MCP servers, poisoned agent configs, or compromised dependencies injected through agent tool chains.

**Governance:**
- Pin MCP server versions; never auto-update without review
- Audit `.cursor/mcp.json` changes with the same rigour as `package.json`
- Treat agent config files (`.cursorrules`, `AGENTS.md`) as security-critical — protect with CODEOWNERS
- Reference: `dependency-scanning.md`, `ai-project-config-security.md`

**Cursor-specific:** MCPoison (CVE-2025-54136) demonstrated that approved MCP configs can be silently modified. Re-verify MCP configs on every pull.

### ASI05: Unexpected Code Execution

**Risk:** Agents execute code that was not part of the intended workflow — through tool chaining, dynamic code generation, or exploited integrations.

**Governance:**
- All agent-generated code must pass the Security Gate before deployment
- Restrict shell access for agents to specific, documented commands
- Log every code execution an agent triggers (not just the final output)
- Use `input-validation.md` patterns for any data flowing through agent pipelines

**Cursor-specific:** Cursor agents can run terminal commands. Set explicit allow-lists for agent-executable commands in your project governance.

### ASI06: Memory & Context Poisoning

**Risk:** Persistent agent memory (context files, conversation history, vector stores) is corrupted with malicious instructions that persist across sessions.

**Governance:**
- Treat `.cursorrules`, `AGENTS.md`, `CLAUDE.md`, and memory files as attack surfaces
- Review agent memory/context files for injected instructions on every PR
- Never allow agents to self-modify their own governance files without human approval
- Implement memory cleanup — stale context accumulates risk

**Cursor-specific:** Cursor's context system reads `.cursorrules` and rule files on every session. A poisoned `.cursorrules` file affects every future agent interaction until detected.

### ASI07: Insecure Inter-Agent Communication

**Risk:** Multi-agent systems pass messages that can be intercepted, spoofed, or manipulated, causing agents to act on false information.

**Governance:**
- Log all inter-agent messages (subagent ↔ parent agent communication)
- Validate agent-to-agent outputs before using them as inputs to other agents
- Use structured data formats (not free-text) for agent handoffs
- Reference: `async-subagent-governance.md`

**Cursor-specific:** Cursor's Build in Parallel spawns multiple subagents. Each subagent's output should be validated before being consumed by another agent or merged into the main branch.

### ASI08: Cascading Agent Failures

**Risk:** A single agent failure propagates through connected tools, memory, and other agents, causing large-scale security incidents.

**Governance:**
- Implement circuit breakers: if an agent fails 3 times, stop and escalate to human
- Set spending limits per agent session (not just per-project)
- Monitor for patterns: one agent's error output becoming another agent's input
- Use `cost-governance.md` and `monitoring-alerting.md` for detection

**Cursor-specific:** Cursor's Soft Spend Limits (May 2026) help, but set them per-workspace, not just per-org. A runaway automation can exhaust budget across all projects.

### ASI09: Human-Agent Trust Exploitation

**Risk:** Attackers exploit the trust humans place in agent outputs, causing humans to approve malicious code, configurations, or decisions.

**Governance:**
- Never auto-merge agent PRs without human review (see Cloud Agent Governance)
- Train team members on the "trust but verify" pattern (see LLM Agent Governance)
- Flag agent outputs that look authoritative but lack evidence (no tests, no docs, no rationale)
- Use `human-approval.md` for any decision with security, financial, or data implications

**Cursor-specific:** Cursor's Bugbot Autofix can suggest fixes that look correct but introduce subtle vulnerabilities. Always review the diff, not just the summary.

### ASI10: Autonomous Behaviour Boundaries

**Risk:** Agents exceed their intended autonomy — making decisions, taking actions, or spending resources beyond what was authorised.

**Governance:**
- Define explicit boundaries for every agent: what it CAN do, what it MUST NOT do, what requires human approval
- Document autonomy levels in your governance.yaml or agent config
- Review agent actions weekly for boundary violations
- Reference: `cursor-automations-governance.md`, `human-approval.md`

**Cursor-specific:** Cursor automations run on triggers (Slack, Jira, schedules) without human-in-the-loop. Set explicit kill switches and weekly review cadence.

---

## Mapping to Existing Skills

| ASI Risk | Primary Skill | Supporting Skills |
|---|---|---|
| ASI01 Goal Hijack | llm-agent-governance | human-approval, cursor-automations-governance |
| ASI02 Tool Misuse | mcp-security | security-gate, input-validation |
| ASI03 Privilege Abuse | cloud-agent-governance | secrets-management, git-security |
| ASI04 Supply Chain | dependency-scanning | ai-project-config-security, mcp-security |
| ASI05 Code Execution | security-gate | input-validation, error-handling |
| ASI06 Memory Poisoning | llm-agent-governance | mcp-security, ai-project-config-security |
| ASI07 Inter-Agent Comms | async-subagent-governance | llm-agent-governance |
| ASI08 Cascading Failures | cost-governance | monitoring-alerting, incident-response |
| ASI09 Trust Exploitation | human-approval | llm-agent-governance, cloud-agent-governance |
| ASI10 Autonomy Bounds | cursor-automations-governance | human-approval, llm-agent-governance |

## Quick Checklist for Non-Technical Founders

Before enabling any AI agent with tool access:

- [ ] I know exactly what tools this agent can access
- [ ] I have spending limits set
- [ ] I review every PR the agent creates before merging
- [ ] I have a kill switch if the agent goes rogue
- [ ] I understand that agent output can be confidently wrong
- [ ] My `.cursorrules` and agent config files are protected from modification

## References

- [OWASP Top 10 for Agentic Applications 2026](https://owasp.org/www-project-top-10-for-agentic-applications/)
- [Practical DevSecOps: OWASP ASI 2026](https://www.practical-devsecops.com/owasp-top-10-agentic-applications/)
- [DeepTeam: OWASP ASI Framework](https://www.trydeepteam.com/docs/frameworks-owasp-top-10-for-agentic-applications)
