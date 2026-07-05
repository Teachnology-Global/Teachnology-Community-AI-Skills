---
description: >
  Governs safe use of the Cursor SDK (@cursor/sdk, released May 1, 2026) for building
  programmatic agents. Covers API key management, model selection, sandbox configuration,
  error handling, and cost controls when creating agents outside the IDE. Use when:
  (1) building custom agents with the Cursor SDK, (2) deploying agents to CI/CD or
  serverless, (3) creating multi-agent workflows programmatically, (4) using agent output
  in production systems.
globs: ["**/*.ts", "**/*.js", "**/agent*", "**/cursor-agent*"]
alwaysApply: false
tags: [product]
---

# Cursor SDK Governance

## What Changed

On **May 1, 2026**, Cursor released the **Cursor SDK** (`@cursor/sdk`) — a TypeScript library for building agents that use Cursor's runtime, harness, and models *outside the IDE*.

### June 2026 SDK Update: Custom Tools, Stores, and Auto-Review

The **June 2026 SDK release** added four new primitives that move Cursor from an IDE assistant into a deployable agent runtime:

1. **Custom Tools** — Wire your own functions into the agent's tool set. The agent can call these during execution. Governance implication: custom tool outputs become agent inputs — validate both directions.
2. **Configurable Persistence Stores** — Agents can now maintain state across runs. Governance implication: persistent state can accumulate credentials or PII — enforce data retention policies on agent stores.
3. **Contextual Classifier** — Gates tool availability based on task context. Governance implication: reduces blast radius by limiting which tools are available per task type.
4. **Auto-Review Pipeline** — Automated quality checks on agent output before delivery. Governance implication: useful safety layer but don't rely on it as sole validation.

**For TYO community:** The June SDK makes agents significantly more powerful. If you're building products with the SDK, custom tools are your biggest risk — every tool you wire in is a new attack surface. Audit tools the same way you'd audit MCP servers (see MCP Security skill).

```typescript
// June 2026: Custom Tools
import { Agent, Tool } from "@cursor/sdk";

const queryDatabase = new Tool({
  name: "query_db",
  description: "Run a read-only SQL query",
  parameters: { query: "string" },
  handler: async ({ query }) => {
    // ⚠️ GOVERNANCE: Validate and sanitise inputs
    if (query.match(/DROP|DELETE|UPDATE|INSERT/i)) {
      throw new Error("Write operations not permitted");
    }
    return await db.query(query);
  },
});

const agent = await Agent.create({
  apiKey: process.env.CURSOR_API_KEY!,
  model: { id: "composer-2" },
  tools: [queryDatabase], // Custom tools attached
  store: { type: "sqlite", path: "/tmp/agent-store.db" }, // Persistence store
});
```

```typescript
import { Agent } from "@cursor/sdk";

const agent = await Agent.create({
  apiKey: process.env.CURSOR_API_KEY!,
  model: { id: "composer-2" },
  local: { cwd: process.cwd() },
});

const run = await agent.send("Summarize this repository");
for await (const event of run.stream()) {
  console.log(event);
}
```

This is a **fundamental shift**: Cursor agents are no longer confined to the IDE. They can now run on servers, in CI/CD pipelines, on cloud VMs, or anywhere Node.js runs.

**For non-technical founders:** This means the same powerful AI agent that helps you write code in Cursor can now run *without you watching it* — on a server, processing repositories, making changes. The risk profile is identical to Cloud Agent Governance but with even less visibility.

**For teachers learning to code:** This is powerful but dangerous. An SDK agent with repo access can read all your code, install packages, run terminal commands, and push changes. Treat it like giving someone your laptop with admin access.

## Activation

This skill activates when you mention:
- "Cursor SDK", "@cursor/sdk", "agent.create"
- "programmatic agent", "CI agent", "serverless agent"
- "Agent.send", "cursor agent automation"
- "build agent with SDK"

Also activates when:
- Importing `@cursor/sdk` in any file
- Creating Agent instances outside Cursor IDE
- Configuring agents for CI/CD or serverless deployment

## Risk Model

### What the SDK Enables (and Risks)

| Capability | Risk | Mitigation |
|---|---|---|
| **Run agents anywhere** | Agents running on servers with no human oversight | Require human-in-the-loop for consequential actions |
| **Any frontier model** | Cost explosion with expensive models | Pin model selection; set token budgets |
| **Full repo access** | Agent can read all code, including secrets | Sandbox filesystem; deny sensitive paths |
| **Streaming output** | Unbounded output generation | Set output size limits |
| **Cloud VM execution** | Agent runs on infrastructure you may not control | Use trusted Cursor cloud for production agents |
| **No IDE UI** | No visual feedback, harder to debug what agent is doing | Require structured logging and trace output |

## Governance Rules

### API Key Management

```typescript
// ❌ NEVER hardcode the API key
const agent = Agent.create({ apiKey: "cursk_abc123..." });

// ✅ Always from environment
const agent = Agent.create({
  apiKey: process.env.CURSOR_API_KEY!,
});

// ✅ With validation
if (!process.env.CURSOR_API_KEY?.startsWith("cursk_")) {
  throw new Error("Invalid Cursor API key format");
}
```

**The Cursor SDK key (`cursk_...`) is a high-privilege credential.** It gives programmatic access to Cursor's agent infrastructure. If leaked:
1. Attackers can run agents using your quota (costs you money)
2. Agents may access repos you've configured
3. Token consumption is billed to your account

**Treat it like a Stripe secret key or database password.**

### Model Selection and Cost Control

```typescript
// ❌ Using the most expensive model for everything
const agent = Agent.create({
  model: { id: "claude-3-opus" }, // Very expensive
});

// ✅ Choose model based on task
function getAgentForTask(task: 'simple' | 'complex') {
  return Agent.create({
    model: { 
      id: task === 'complex' ? 'composer-2' : 'cursor-fast' 
    },
  });
}
```

**Cost considerations:**
- SDK agents use **token-based consumption pricing** (not the flat Cursor subscription)
- Each SDK run counts against your API usage, not your IDE usage
- A long-running agent processing a large repo can consume significant tokens
- Monitor usage in the Cursor dashboard

### Sandbox Configuration

```typescript
// ✅ Always restrict filesystem access
const agent = Agent.create({
  local: { 
    cwd: process.cwd(),
    // Deny access to sensitive directories
    deny: ["~/.ssh", "~/.aws", "secrets/", ".env"],
  },
});
```

**Sandbox requirements for SDK agents:**
1. **Explicit working directory** — never use root or home directory
2. **Deny sensitive paths** — SSH keys, credential stores, secrets directories
3. **Network restrictions** — if possible, limit network access to required endpoints only
4. **Timeout enforcement** — agents should not run indefinitely

### Error Handling

```typescript
// ✅ Proper error handling for agent runs
async function runAgentSafely(task: string) {
  const agent = await Agent.create({
    apiKey: process.env.CURSOR_API_KEY!,
    model: { id: "cursor-fast" },
    local: { cwd: process.cwd() },
  });

  let run;
  try {
    run = await agent.send(task);
  } catch (error) {
    // Agent failed to start — log and abort
    console.error("Agent creation failed:", error.message);
    throw new Error(`Agent failed: ${error.message}`);
  }

  try {
    for await (const event of run.stream()) {
      // Process events with timeout protection
      await Promise.race([
        processAgentEvent(event),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error("Agent timeout")), 300_000)
        )
      ]);
    }
  } catch (error) {
    // Agent run failed — clean up and report
    console.error("Agent stream error:", error.message);
    throw error;
  }
}
```

### Output Validation

SDK agents produce streaming events. Validate what they do before trusting the results:

```typescript
// Track what files the agent modifies
const modifiedFiles: Set<string> = new Set();

for await (const event of run.stream()) {
  if (event.type === "file_write") {
    modifiedFiles.add(event.path);
    
    // Validate: agent shouldn't modify certain files
    if (event.path.includes(".env") || event.path.includes("secret")) {
      throw new Error(`Agent attempted to modify sensitive file: ${event.path}`);
    }
  }
  
  if (event.type === "terminal_exec") {
    // Validate: agent shouldn't run dangerous commands
    const dangerous = ["rm -rf /", "curl", "wget", "export", "chmod 777"];
    if (dangerous.some(cmd => event.command?.includes(cmd))) {
      throw new Error(`Agent attempted dangerous command: ${event.command}`);
    }
  }
}
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: SDK Agent Review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  sdk-agent-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Cursor SDK
        run: npm install @cursor/sdk
        
      - name: Run SDK agent review
        env:
          CURSOR_API_KEY: ${{ secrets.CURSOR_API_KEY }}
        run: node scripts/sdk-agent-review.mjs
```

### Important CI/CD Rules

1. **API key from GitHub Secrets** — never embed in workflow files
2. **Set timeout on the job** — agents can hang or run long
3. **Run on a separate branch** — agents should not modify the PR branch directly
4. **Review agent output as comments** — not automated merges

## Agent Types and Governance Levels

| Agent Purpose | Risk Level | Requirements |
|---|---|---|
| **Code review agent** | Low | Read-only access; output as PR comments |
| **Documentation agent** | Low | Write access to docs/ only |
| **Test generation agent** | Medium | Write access to test files only; review before merge |
| **Migration agent** | High | Database changes require human approval; run on staging first |
| **Security agent** | High | Results only — never auto-apply security fixes |

## Production Deployment Rules

When deploying SDK agents to production (serverless, containers, always-on):

1. **Dedicated API key** — don't share your IDE key with production agents
2. **Strict token limits** — set `max_tokens` equivalent via the model config
3. **Input sanitisation** — sanitise any data you send to agents
4. **Output validation** — validate agent outputs before using them
5. **Audit logging** — log every agent invocation for debugging
6. **Cost monitoring** — set up alerts for unusual token consumption
7. **Rate limiting** — don't let users trigger unlimited agent runs

### Production Architecture Pattern

```typescript
// Pattern for production SDK agent usage
import { Agent } from "@cursor/sdk";
import { createHash } from "crypto";

class AgentOrchestrator {
  private activeAgents: Map<string, { agent: any; started: number }> = new Map();
  
  static MAX_CONCURRENT = 3;
  static TIMEOUT_MS = 5 * 60 * 1000; // 5 minutes
  
  async runTask(task: string, requestId: string): Promise<string> {
    // Rate limiting: reject if too many concurrent agents
    if (this.activeAgents.size >= AgentOrchestrator.MAX_CONCURRENT) {
      throw new Error("Too many concurrent agent runs");
    }
    
    // Idempotency: same input → same cached result
    const cacheKey = createHash("sha256").update(task).digest("hex");
    const cached = await this.getCache(cacheKey);
    if (cached) return cached;
    
    const agent = await Agent.create({
      apiKey: process.env.CURSOR_API_KEY!,
      model: { id: "cursor-fast" },
      local: { 
        cwd: "/tmp/agent-workspace", // Isolated workspace
        deny: ["~/.ssh", "~/.aws", "secrets/"],
      },
    });
    
    const started = Date.now();
    this.activeAgents.set(requestId, { agent, started });
    
    try {
      const run = await agent.send(task);
      let result = "";
      
      for await (const event of run.stream()) {
        // Timeout check
        if (Date.now() - started > AgentOrchestrator.TIMEOUT_MS) {
          throw new Error("Agent timed out");
        }
        if (event.type === "final_answer") {
          result = event.content;
        }
      }
      
      // Cache successful result
      await this.setCache(cacheKey, result);
      return result;
    } finally {
      this.activeAgents.delete(requestId);
    }
  }
}
```

## Cross-References

| Related Skill | How It Interacts |
|---|---|
| Cloud Agent Governance | SDK agents share the same "agent running without direct oversight" risk profile |
| Secrets Management | CURSOR_API_KEY is a high-value secret — rotation and protection required |
| Cost Governance | SDK usage is billed separately from IDE usage — monitor both |
| AI Output Validation | Validate SDK agent outputs before trusting or merging them |
| Deployment Checklist | If deploying agents to production, run the deployment checklist first |
| API Rate Limiting | Implement per-user rate limits on agent invocation if agents are user-facing |

## Checklist: Before Using Cursor SDK

- [ ] **API key stored securely** — environment variable, not in code
- [ ] **Model appropriate for task** — not using expensive model for simple tasks
- [ ] **Filesystem sandbox configured** — sensitive paths denied
- [ ] **Error handling implemented** — agent failures don't crash your system
- [ ] **Output validation in place** — agent outputs verified before use
- [ ] **Logging enabled** — every agent run logged with request ID
- [ ] **Cost monitoring set up** — token usage tracked and alerted
- [ ] **Rate limiting configured** — prevents runaway usage
- [ ] **Timeout set** — agents don't run indefinitely
- [ ] **Review process defined** — who approves agent outputs before merge?
