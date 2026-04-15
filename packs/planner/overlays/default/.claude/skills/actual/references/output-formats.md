# Output Formats Reference

All 3 output formats, managed section mechanics, and merge behavior. Load this when dealing with output files or managed sections.

## Table of Contents

- [Format Summary](#format-summary)
- [claude-md Format](#claude-md-format)
- [agents-md Format](#agents-md-format)
- [cursor-rules Format](#cursor-rules-format)
- [Managed Section Markers](#managed-section-markers)
- [Merge Behavior](#merge-behavior)
- [Metadata Comments](#metadata-comments)

## Format Summary

| Format | Output File | Header | Use Case |
|--------|------------|--------|----------|
| claude-md | `CLAUDE.md` | `# Project Guidelines` | Claude Code (default) |
| agents-md | `AGENTS.md` | `# Project Guidelines` | OpenCode and other agent tools |
| cursor-rules | `.cursor/rules/actual-policies.mdc` | YAML frontmatter | Cursor IDE |

Set the format:
```bash
# CLI flag
actual adr-bot --output-format agents-md

# Config
actual config set output_format agents-md
```

## claude-md Format

**File**: `CLAUDE.md` (project root and/or subdirectories)

**Header** (root file only):
```markdown
# Project Guidelines
```

This is the default format, designed for Claude Code which reads `CLAUDE.md` files.

## agents-md Format

**File**: `AGENTS.md` (project root and/or subdirectories)

**Header** (root file only):
```markdown
# Project Guidelines
```

Identical structure to claude-md but uses `AGENTS.md` filename. Used by OpenCode and other tools that follow the Agent Skills standard.

## cursor-rules Format

**File**: `.cursor/rules/actual-policies.mdc`

**Header**:
```yaml
---
alwaysApply: true
---
```

Uses Cursor's `.mdc` rule format with YAML frontmatter. The `alwaysApply: true` ensures the policies are always active in Cursor.

## Managed Section Markers

All formats use identical HTML comment markers to delimit the CLI-managed content:

```markdown
<!-- managed:actual-start -->
<!-- last-synced: 2025-01-15T10:30:00Z -->
<!-- version: 3 -->
<!-- adr-ids: adr-001,adr-002,adr-003 -->

(ADR content goes here)

<!-- managed:actual-end -->
```

### Marker Rules

- Markers are always `<!-- managed:actual-start -->` and `<!-- managed:actual-end -->`
- They are identical across all output formats
- Content outside markers is never modified by the CLI
- The start marker is always followed by metadata comments

## Merge Behavior

The CLI handles four scenarios when writing output:

### 1. New Root File

When the output file does not exist and it's a root-level file:

```markdown
# Project Guidelines

<!-- managed:actual-start -->
(metadata comments)
(ADR content)
<!-- managed:actual-end -->
```

The header is written first, followed by the managed section.

### 2. New Subdirectory File

When the output file does not exist and it's in a subdirectory (from `--project`):

```markdown
<!-- managed:actual-start -->
(metadata comments)
(ADR content)
<!-- managed:actual-end -->
```

No header is written. Only the managed section.

### 3. Existing File with Markers

When the file exists and already contains managed section markers:

- Content **before** `<!-- managed:actual-start -->` is preserved unchanged
- Content **between** the markers is replaced with new content
- Content **after** `<!-- managed:actual-end -->` is preserved unchanged

This allows users to add their own content above or below the managed section.

### 4. Existing File without Markers

When the file exists but has no managed section markers:

- All existing content is preserved
- The managed section is appended at the end of the file

This is the safest merge strategy: the CLI never overwrites user content that wasn't originally created by the CLI.

## Metadata Comments

Three metadata comments are written immediately after the start marker:

| Comment | Purpose | Example |
|---------|---------|---------|
| `<!-- last-synced: TIMESTAMP -->` | When the sync was run | `2025-01-15T10:30:00Z` |
| `<!-- version: N -->` | Incremented on each sync | `3` |
| `<!-- adr-ids: id1,id2 -->` | Which ADRs are included | `adr-001,adr-002` |

These are used by `actual status` to report the output file state.

### Status Command

`actual status` reads the managed section markers and metadata to report:
- Which output file exists
- When it was last synced
- What version it is on
- Which ADRs are included
- Whether the file is up to date

```bash
actual status           # basic status
actual status --verbose # detailed status
```
