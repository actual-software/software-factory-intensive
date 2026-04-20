# Excalidraw Prerequisites

The designer agent uses two external binaries for Excalidraw integration.
Both must be installed on the host before starting the factory.
Install via npm — neither is available via Homebrew.

## 1. excalidraw-mcp (MCP server)

Source: https://github.com/excalidraw/excalidraw-mcp

Provides the `mcp__excalidraw__*` tools the designer uses to draw wireframes
on an Excalidraw canvas from inside Claude Code.

**Install:**
```bash
npm install -g excalidraw-mcp
```

**Verify:**
```bash
command -v excalidraw-mcp && echo "ok"
```

> **Note:** `excalidraw-mcp` is an MCP stdio server — running it directly
> will hang (it waits for JSON-RPC input). Do NOT run `excalidraw-mcp --version`.
> Just verify the binary is on PATH using `command -v`.

The MCP server is wired automatically via the overlay `.mcp.json` —
no manual configuration needed once the binary is on PATH.

## 2. excalidraw-export-cli (PNG export)

Package: `excalidraw-export-cli` — installs binary as **`excalidraw-export`**

Source: https://www.npmjs.com/package/excalidraw-export-cli

Converts a saved `.excalidraw` scene file to a PNG for inline markdown embedding.

**Install:**
```bash
npm install -g excalidraw-export-cli
```

**Verify:**
```bash
excalidraw-export --version
```

**Usage:**
```bash
excalidraw-export <file>.excalidraw <file>.png
```

> **Note:** The npm package is `excalidraw-export-cli` but the installed binary
> is `excalidraw-export` (without `-cli`). Use `excalidraw-export` in scripts.

## 3. Doctor check

Run the designer pack doctor to verify both binaries are present:

```bash
gc doctor --pack=actual-designer
```

The check script at `doctor/check-designer.sh` verifies `excalidraw-mcp`
and `excalidraw-export` are on PATH and exits non-zero if either is missing.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `excalidraw-mcp` hangs | Expected — it's an MCP server waiting for input | Use `command -v` to verify, never `--version` |
| `mcp__excalidraw__*` tools not available | `excalidraw-mcp` not on PATH | `npm install -g excalidraw-mcp` |
| `excalidraw-export: command not found` | Export CLI missing or wrong binary name | `npm install -g excalidraw-export-cli` (binary is `excalidraw-export`) |
| PNG is blank | Export CLI version mismatch | `npm update -g excalidraw-export-cli` |
| No brew formula | Not in Homebrew | npm is the only install method |
