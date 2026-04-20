# Excalidraw Prerequisites

The designer agent uses two external binaries for Excalidraw integration.
Both must be installed on the host before starting the factory.

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
excalidraw-mcp --version
```

The MCP server is wired automatically via the overlay `.mcp.json` —
no manual configuration needed once the binary is on PATH.

## 2. excalidraw-export-cli (PNG export)

Source: https://github.com/excalidraw/excalidraw

Converts a saved `.excalidraw` scene file to a PNG for inline markdown embedding.

**Install:**
```bash
npm install -g excalidraw-export-cli
```

**Verify:**
```bash
excalidraw-export-cli --version
```

## 3. Doctor check

Run the designer pack doctor to verify both binaries are present:

```bash
gc doctor --pack=actual-designer
```

The check script at `doctor/check-designer.sh` verifies `excalidraw-mcp`
and `excalidraw-export-cli` are on PATH and exits non-zero if either is missing.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `mcp__excalidraw__*` tools not available | `excalidraw-mcp` not on PATH | `npm install -g excalidraw-mcp` |
| `excalidraw-export-cli: command not found` | Export CLI missing | `npm install -g excalidraw-export-cli` |
| Canvas shows no elements | MCP server not started | Restart agent session |
| PNG is blank | Export CLI version mismatch | Update: `npm update -g excalidraw-export-cli` |
