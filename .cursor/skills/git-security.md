---
description: >
  Governs safe Git practices, branch protection policies, and repository security.
  Prevents accidental history rewrites, leaked secrets in git, unprotected branches,
  and forced pushes. Covers protected branch rules, CODEOWNERS, signed commits,
  and the "undo" patterns every non-technical founder needs to know.
  Use when: (1) setting up a new repository, (2) configuring branch protection,
  (3) reviewing git policies, (4) recovering from git mistakes, (5) auditing repo
  security settings, (6) onboarding team members to git workflows.
globs: [".gitconfig", ".gitattributes", ".github/workflows/**", ".gitignore", "**/.git/**"]
alwaysApply: false
tags: [product]
---

# Git Security & Branch Protection

## Purpose

Git is powerful but unforgiving. Non-technical founders frequently lose work, accidentally expose secrets in commit history, push directly to main, and lack the protections to catch mistakes before they ship.

This skill covers the minimum git security and protection setup every project needs — especially projects where AI agents are generating and committing code.

**For teachers and non-technical founders:** Git is your undo button for code. But if your undo button isn't configured properly, "undo" can also become "delete everything." The rules below make sure your git history is both useful and safe.

## Activation

This skill activates when you mention:
- "branch protection", "protected branch", "main branch"
- "git security", "repo security", "force push"
- "CODEOWNERS", "commit signing", "signed commits"
- "git mistake", "lost commits", "undo commit"
- "main branch push", "direct push"
- "git history", "git log"
- "secret in git", "leaked in commit"

Also activates when:
- Setting up a new GitHub/GitLab repository
- Configuring `.github/workflows/` or `.gitlab-ci.yml`
- Reviewing repository settings
- Running `git push`, `git reset`, or `git rebase`

## Critical Rules

### 1. Never Push Secrets — Even If You Remove Them Later

The #1 git mistake:

```bash
# You commit a file with an API key
git add . && git commit -m "add config"

# You realise and fix it
git add . && git commit -m "remove secret"

# The secret is STILL in your git history. Anyone can find it.
git log -p | grep "sk_live"  # Found it.
```

If you commit a secret, even in one commit, it's exposed forever. Actions you must take:
1. **Rotate the secret immediately** — treat it as compromised
2. **Use git-filter-repo or BFG** to rewrite history (not `git filter-branch`)
3. **Force-push the cleaned history** (on your own repo only)
4. **Revoke the old secret** at the provider (OpenAI, Stripe, etc.)

```bash
# If you just pushed a secret in the last commit (before anyone pulled):
git reset HEAD~1
# Fix the file, then recommit and push

# If the secret is deeper in history — use BFG Repo-Cleaner:
# Download: https://rtyley.github.io/bfg-repo-cleaner/
bfg --replace-text secrets.txt my-repo.git
cd my-repo.git && git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push --force
```

### 2. Branch Protection Rules (GitHub)

Every production repository MUST have these branch protection rules on `main` (and `production` if you have it):

- [ ] **Require pull request reviews** before merging
  - Minimum 1 approving review
  - Dismiss stale reviews when new commits are pushed
- [ ] **Require status checks** to pass before merging
  - Include all CI workflow checks
  - Require branches to be up-to-date before merging
- [ ] **Require signed commits** (at minimum: enforce for team members, allow bots to bypass if needed)
- [ ] **Include administrators** in the rules (no one is above the rules)
- [ ] **Restrict pushes** (disable direct pushes — all changes via PR)
- [ ] **Restrict force pushes** (disable force push to main entirely)
- [ ] **Restrict deletions** (prevent main branch deletion)

```yaml
# GitHub branch protection (via repo settings — API equivalent):
{
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true
  },
  "required_status_checks": {
    "strict": true,
    "contexts": ["build", "test", "security-scan"]
  },
  "enforce_admins": true,
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
```

### 3. CODEOWNERS for AI Config Files

AI tooling configuration files should be CODEOWNERS-protected:

```
# .github/CODEOWNERS
# Protect AI config files from unauthorized changes

# AI config files — require review from maintainers
.cursor/                         @your-handle
.cursorrules                     @your-handle
governance.yaml                  @your-handle
.claude/                         @your-handle
.github/copilot-instructions.md  @your-handle

# Production config
.env*                            @your-handle
docker-compose.yml               @your-handle

# CI/CD
.github/workflows/               @your-handle
```

Without CODEOWNERS, anyone with write access can change your AI tooling's behaviour. This is especially critical because AI tools (Cursor, Claude Code, Copilot) implicitly trust these files.

### 4. Signed Commits

Signed commits provide cryptographic proof of who authored each commit. This matters for:
- Audit trails (proving who made what change)
- Preventing impersonation (anyone can set `git config user.name` to your name)
- Compliance requirements (some regulators demand commit authenticity)

```bash
# Set up GPG signing
gpg --full-generate-key  # Create a GPG key (RSA 4096, no expiry)
gpg --list-secret-keys --keyid-format=long  # Find your key ID
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true
git config --global tag.gpgsign true

# Add your GPG public key to GitHub/GitLab
gpg --armor --export YOUR_KEY_ID  # Copy this to GitHub Settings > SSH and GPG keys
```

### 5. Git Ignore Best Practices

```gitignore
# Secrets
.env
.env.*
!.env.example

# OS files
.DS_Store
Thumbs.db
desktop.ini

# IDE
.cursor/automations/     # Don't commit automation configs unless intentional
.vscode/*.json           # Workspace settings (can contain injection vectors)
!.vscode/extensions.json # Allowed: recommended extensions only
.claude/                 # Claude Code config — protect with CODEOWNERS

# Build outputs
dist/
build/
.next/
node_modules/

# Large files
*.sqlite
*.db
*.log

# AI-generated files that shouldn't be committed
.cursor/rules/generated-*  # Auto-generated rules
```

### 6. Safe Git Undo Patterns

Every non-technical founder needs these patterns:

```bash
# Undo last commit (keep changes in working directory)
git reset --soft HEAD~1

# Undo last commit (discard changes entirely)
git reset --hard HEAD~1

# Undo committed file changes (keep everything else)
git checkout HEAD~1 -- path/to/file

# Recover lost commits (the git time machine)
git reflog  # Shows every HEAD movement in the last 30 days
git checkout COMMIT_HASH  # Restore to that point

# Revert a pushed commit (public-safe — no history rewrite)
git revert COMMIT_HASH

# See what changed in the last N commits
git log -p -n 5  # Last 5 commits with full diffs

# Find a specific change (needle in haystack)
git log -S "function_name" --all
git log -G "regex_pattern" --all  # Search diffs with regex
```

### 7. Pre-Commit Hooks for Security

```bash
#!/bin/bash
# .git/hooks/pre-commit
# Prevent secrets from being committed

# Check for common secret patterns
if git diff --cached | grep -iE \
  '(sk_live_|sk_test_|ghp_|xoxb_|AIza|BEGIN RSA PRIVATE KEY|password\s*=\s*["\x27])'; then
  echo "⚠️  POSSIBLE SECRET DETECTED in staged changes."
  echo "If this is intentional, commit with --no-verify (but you REALLY shouldn't)."
  exit 1
fi

echo "✓ Pre-commit check passed"
```

Make it executable: `chmod +x .git/hooks/pre-commit`

## ⚠️ CVE-2026-26268: Embedded Bare Repo / Git Hook RCE

**Patched February 2026. You must update Cursor to v2.5+.**

A high-severity vulnerability allows arbitrary code execution via embedded bare repositories containing malicious git hooks. The attack works because:

1. A malicious actor embeds a bare repository inside a legitimate-looking repository.
2. The embedded bare repo contains a malicious pre-commit or post-checkout hook.
3. When an AI agent runs `git checkout`, `git init`, or similar on the cloned repo, the hook fires automatically — **no prompt required**.

This is specifically dangerous for AI agents because:
- AI agents follow `.cursor/rules/` and `.github/copilot-instructions.md` instructions from any cloned repo.
- An attacker can place instructions like "set up the project" in the README, triggering the agent to run git operations.
- The hook executes with the agent's full local access.

### Protections

**Immediate (every project):**
- Update Cursor to v2.5+ (CVE patched).
- Disable automatic hook execution in `~/.gitconfig`:
  ```ini
  [safe]
    directory = *
  ```
- Never run `git checkout`, `git init`, or `git reset` on untrusted repos without reviewing `.git/` first.

**For AI agents (add to .cursorrules):**
```
Before running ANY git operations on a cloned repository:
1. Check for embedded bare repos: `git submodule status` + `find . -name HEAD -path '*/.git/HEAD'`
2. Review `.git/hooks/` directory contents
3. Flag any .git directories NOT at the repo root
4. Ask the user before proceeding if anything unusual is found
```

**For repo owners:**
- Enable GitHub's automated scanning for embedded bare repos.
- Add `.git/` to `.gitignore` at root level.
- Review CODEOWNERS to cover all `.gitaccess` and hook-related paths.

## AI Agent-Specific Git Concerns

When AI agents (Cursor Cloud Agent, Bugbot, Automations) commit code:

1. **Require PR, not direct push** — AI should never push directly to main
2. **Auto-approve with limits** — If automations auto-approve PRs, limit:
   - Max files changed per auto-approved PR
   - Max lines changed per auto-approved PR
   - Never auto-approve security-related changes
3. **Verify commit identity** — AI commits should have a distinguishable author:
   ```bash
   git config user.name "Cursor Bot [Automated]"
   git config user.email "cursor-bot@your-domain.com"
   ```
4. **Log all AI commits** — Use commit conventions that make AI origin clear:
   ```
   chore(cursor): regenerate auth component
   fix(cloud-agent): fix race condition in user service
   feat(automation): add webhook handler for stripe payments
   ```

## Cross-References

- **Security Gate**: For the full pre-deployment security scan
- **Secrets Management**: For handling API keys and credentials
- **AI Project Config Security**: For protecting `.cursor/` and `.claude/` config
- **Cloud Agent Governance**: For AI agent PR review policies
- **Cursor Automations Governance**: For automation commit policies
- **Human Approval**: For deciding when AI changes need review
