---
description: >
  Governs the safe setup and use of Cursor Self-Hosted Cloud Agents (launched March 2026).
  Covers infrastructure security, secret isolation, network segmentation, and the
  critical trust differences between self-hosted and Cursor-hosted agents.
  Use when: (1) setting up self-hosted cloud agents, (2) configuring agent VMs in
  your own infrastructure, (3) migrating from Cursor-hosted to self-hosted agents,
  (4) auditing self-hosted agent configurations, (5) setting up agent VM templates.
globs: ["**/.cursor/**", "**/docker-compose*", "**/terraform/**", "**/kubernetes/**", "**/.github/**"]
alwaysApply: false
tags: [product]
---

# Self-Hosted Agent Governance

## Purpose

Cursor 3.0 introduced **Self-Hosted Cloud Agents** (March 2026) — the same cloud agent capabilities but running entirely within your own infrastructure. Your codebase, build outputs, and secrets never leave your network. This is a significant security improvement for teams with compliance requirements.

But "self-hosted" doesn't mean "self-securing." Running agents on your own infrastructure introduces a **new set of risks** that don't exist with Cursor-hosted agents.

## Why Self-Hosted Matters

### Key Differences: Self-Hosted vs Cursor-Hosted

| Dimension | Cursor-Hosted | Self-Hosted |
|-----------|--------------|-------------|
| Code location | Cursor's cloud VMs | Your infrastructure |
| Secret exposure | Secrets encrypted in Cursor VM | Secrets in your infra — YOUR responsibility |
| Network access | Isolated from your internal network | Can reach your internal services |
| Compliance burden | Cursor handles infra security | You handle everything |
| Network segmentation | Automatic | Manual configuration |
| VM lifecycle | Managed by Cursor | Your responsibility |
| Cost | Cursor pricing | Your infra costs |

**For non-technical founders:** Self-hosted means YOU are the cloud provider now. The code stays in your house, but so does every risk — and every breach.

## Self-Hosted Specific Risks

### 1. Internal Network Exposure

A self-hosted agent running in your VPC or internal network can potentially reach:
- Internal databases with production data
- Internal APIs and microservices
- Secrets managers and credential stores
- Admin dashboards and internal tooling
- Other infrastructure components

**Unlike Cursor-hosted agents**, a compromised or malicious self-hosted agent is already inside your perimeter.

### 2. VM Template Security

The VM image or container template that agents run in becomes a critical trust boundary:
- Are base images from trusted sources?
- Are they patched and up-to-date?
- Is the attack surface minimised?
- How are VMs disposed of after agent runs?

### 3. Secret Injection

Self-hosted agents need access to your repository and tools. How you inject secrets into the agent runtime is critical:
- Secrets must be injected at runtime, never baked into VM images
- Use your infra's secrets manager (AWS SSM, GCP Secret Manager, HashiCorp Vault)
- Rotate agent-specific credentials after every run if possible

## Setup Checklist

### Infrastructure Requirements

```markdown
## Self-Hosted Agent Setup Checklist

Network security:
- [ ] Agent VMs run in isolated subnet with no access to production databases
- [ ] Egress traffic restricted to required services only (GitHub, npm, package registries)
- [ ] No direct internet inbound access to agent VMs
- [ ] VPC flow logging enabled for agent subnet
- [ ] Internal load balancers or API gateways in front of agent infrastructure

Secret management:
- [ ] Secrets injected via runtime environment (not baked into images)
- [ ] Agent-specific service accounts with minimal permissions
- [ ] Credentials rotated automatically (or on a schedule)
- [ ] No shared credentials between agent and developer machines

VM/container hygiene:
- [ ] Minimal base image (alpine, distroless, or minimal)
- [ ] No unnecessary packages or services running
- [ ] Container runtime security (seccomp profiles, AppArmor, SELinux)
- [ ] VM images rebuilt from scratch on a schedule (not incrementally patched)
- [ ] Ephemeral VMs — destroyed after each agent session

Monitoring:
- [ ] Agent session logging (who triggered, what repo, what models used)
- [ ] Egress traffic monitoring from agent subnet
- [ ] Alerting on unusual outbound connections from agent VMs
- [ ] Audit trail of all tool calls made by agents
```

### Cursor Configuration

```json
// .cursor/mcp.json — Self-hosted agent configuration
{
  "mcpServers": {
    "self-hosted": {
      // Point to your self-hosted infrastructure
      // NOT to Cursor's cloud agents
      "url": "https://agents.internal.yourcompany.com",
      "headers": {
        "Authorization": "Bearer ${SELF_HOSTED_AGENT_TOKEN}"
      }
    }
  }
}
```

```yaml
# governance.yaml — Adjust thresholds for self-hosted
agents:
  type: self-hosted
  max_concurrent: 5          # Limit parallel agents to control blast radius
  max_session_duration: 60   # Minutes — auto-terminate long sessions
  allowed_networks:           # Restrict internal network access
    - "10.0.1.0/24"           # Agent subnet only
    - "10.0.5.0/24"           # Build artifacts subnet
  blocked_networks:
    - "10.0.10.0/24"          # Production database subnet
    - "10.0.20.0/24"          # Admin/management subnet
```

## Agent Isolation Strategy

### Subnet Architecture

```
┌──────────────────────────────────────────────┐
│ Your VPC                                      │
│                                              │
│  ┌─────────────────┐   ┌─────────────────┐  │
│  │  Agent Subnet   │   │  Build Subnet   │  │
│  │  (10.0.1.0/24) │──▶│  (10.0.5.0/24) │  │
│  │                 │   │                 │  │
│  │  Self-hosted    │   │  Build outputs  │  │
│  │  agent VMs      │   │  Artifacts      │  │
│  └───────┬─────────┘   └─────────────────┘  │
│          │                                   │
│          ▼                                   │
│  ┌─────────────────┐   ┌─────────────────┐  │
│  │  Block Rules    │   │ Production      │  │
│  │  No access to:  │ ❌ │ (10.0.10.0/24)  │  │
│  │  - Prod DB      │   │ Admin (10.0.20) │  │
│  │  - Admin        │   │ Secrets vault   │  │
│  │  - Internal APIs│   │                 │  │
│  └─────────────────┘   └─────────────────┘  │
│                                              │
│  Internet egress: npm, GitHub, registries    │
└──────────────────────────────────────────────┘
```

### Network Rules

```bash
# Example: AWS security group for agent subnet

# Allow outbound to GitHub
iptables -A FORWARD -s 10.0.1.0/24 -d github.com -p tcp --dport 443 -j ACCEPT

# Allow outbound to npm registry
iptables -A FORWARD -s 10.0.1.0/24 -d registry.npmjs.org -p tcp --dport 443 -j ACCEPT

# Deny ALL other egress (default deny)
iptables -A FORWARD -s 10.0.1.0/24 -j DROP

# Deny ALL internal access except build subnet
iptables -A FORWARD -s 10.0.1.0/24 -d 10.0.5.0/24 -p tcp -j ACCEPT
iptables -A FORWARD -s 10.0.1.0/24 -d 10.0.0.0/8 -j DROP
```

## Migration from Cursor-Hosted

If moving from Cursor-hosted to self-hosted agents:

1. **Audit current usage** — what are agents currently accessing? What secrets are in scope?
2. **Build infrastructure first** — subnet, security groups, VM templates — before switching over
3. **Test in isolation** — run a non-production repo through self-hosted agents first
4. **Verify network segmentation** — prove agents cannot reach your production databases
5. **Switch over repos one at a time** — not a bulk migration
6. **Keep Cursor-hosted as fallback** for at least 2 weeks

## What Changes in Cursor 3.0

### Cursor 3.0 Impact (April 2026)

**Agents Window**: The new interface makes it easier to run multiple agents in parallel — locally, in worktrees, in the cloud, and on remote SSH. This means self-hosted agents can now be controlled alongside Cursor-hosted agents from a single interface. **Ensure your self-hosted agents have separate access controls from Cursor-hosted ones.**

**10 Parallel Workers**: Cursor 3.0 allows up to 10 parallel agents per user. With self-hosted agents, this means **10 simultaneous VMs in your infrastructure**. Your network and compute must handle this.

**Design Mode**: Agents can now annotate and target UI elements directly. For self-hosted agents, this means browser instances running in your infrastructure — ensure they're isolated and can't access internal admin panels.

## Red Flags

```markdown
🚨 DANGER SIGNS for Self-Hosted Agents:
- Agent VMs have internet inbound rules (they should NEVER be publicly accessible)
- Agent subnet has access to production databases or admin panels
- VM images contain baked-in credentials or API keys
- No monitoring or logging on agent egress traffic
- Agent credentials shared between multiple developers or teams
- No session timeout or max-concurrent limit configured
```

## Related Skills

- **Cloud Agent Governance** — for Cursor-hosted agent rules
- **MCP Security** — MCP server governance for agent communication
- **Secrets Management** — proper secret injection patterns
- **Monitoring & Alerting** — monitoring for agent infrastructure
- **Cursor Automations** — automation-specific agent governance
