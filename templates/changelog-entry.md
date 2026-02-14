# Changelog Entry Template

Use this format when adding entries to CHANGELOG.md.

## Format

```markdown
## [Version] - YYYY-MM-DD

### Added
- New feature description (#PR)

### Changed
- What was modified and why (#PR)

### Deprecated
- What's being phased out and replacement (#PR)

### Removed
- What was removed (#PR)

### Fixed
- Bug fix description (#PR)

### Security
- Security fix with CVE reference if applicable (#PR)
```

## Writing Guidelines

### Be User-Focused

```markdown
# ❌ Bad - developer-focused
- Refactored UserService to use dependency injection

# ✅ Good - user-focused  
- Improved login performance by 40%
```

### Include Context

```markdown
# ❌ Bad - no context
- Fixed bug in checkout

# ✅ Good - clear context
- Fixed checkout failing when cart contains gift cards (#234)
```

### Mark Breaking Changes

```markdown
# ✅ Clear breaking change notice
### Changed
- **BREAKING**: Renamed `getUser()` to `fetchUser()` - see migration guide (#456)
```

### Link to Related Docs

```markdown
### Added
- OAuth2 authentication support - see [docs/auth.md](docs/auth.md) (#123)
```

## Category Definitions

| Category | When to Use |
|----------|-------------|
| **Added** | New features |
| **Changed** | Changes to existing functionality |
| **Deprecated** | Features to be removed in future |
| **Removed** | Removed features |
| **Fixed** | Bug fixes |
| **Security** | Security-related fixes |

---

*Template from Cursor Governance Skills*

