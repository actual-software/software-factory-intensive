---
name: excalidraw-diagrams
description: Create Excalidraw wireframes and visual designs using the connected Excalidraw MCP server. Use for ALL UI/UX design work — never ASCII art.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, mcp__excalidraw__create_element, mcp__excalidraw__update_element, mcp__excalidraw__delete_element, mcp__excalidraw__query_elements, mcp__excalidraw__get_resource, mcp__excalidraw__group_elements, mcp__excalidraw__align_elements, mcp__excalidraw__distribute_elements
---

# Excalidraw Diagrams Skill

Use this skill for ALL wireframes and visual designs. Never use ASCII art.

See prerequisites: `docs/excalidraw-prerequisites.md`

## Available MCP tools (`mcp__excalidraw__` prefix)

- `create_element` — Required: `type` (rectangle, ellipse, diamond, arrow, text, label, line, arrowLabel), `x`, `y`. Optional: `width`, `height`, `backgroundColor`, `strokeColor`, `strokeWidth`, `roughness`, `opacity`, `text`, `fontSize`, `fontFamily`.
- `update_element` — Update an existing element by `id`.
- `delete_element` — Delete an element by `id`.
- `query_elements` — Query elements with optional `type` filter.
- `get_resource` — Get a resource: `scene`, `library`, `theme`, or `elements`.
- `group_elements` — Group elements by `elementIds` array.
- `align_elements` — Align: `left`, `center`, `right`, `top`, `middle`, `bottom`.
- `distribute_elements` — Distribute: `horizontal` or `vertical`.

## Required workflow — follow every step in order

### Step 1: Check canvas state
```
get_resource {"resource": "scene"}
```

### Step 2: Plan the diagram
Identify: boxes/entities, arrows/relationships, labels. Choose layout direction.

### Step 3: Create elements
Use `create_element` for rectangles (containers), text (labels), arrows (connections), diamonds (decisions).

### Step 4: Clean up layout
Use `align_elements` and `distribute_elements`. Use `group_elements` for logical groupings.

### Step 5: Save the .excalidraw file (MANDATORY)
```
get_resource {"resource": "scene"}
```
Write the full scene JSON to disk:
```bash
# Save to docs/designs/ alongside the design doc
# Use descriptive filename: <slug>-<screen-name>.excalidraw
```
Write tool: `docs/designs/<slug>-<screen>.excalidraw`

If multiple screens: save each as a separate `.excalidraw`, clear canvas between screens.

### Step 6: Export to PNG (MANDATORY)
```bash
excalidraw-export docs/designs/<slug>-<screen>.excalidraw docs/designs/<slug>-<screen>.png
```

### Step 7: Reference BOTH formats in the design doc (MANDATORY)
```markdown
### Screen: <Name>
![<Name>](./slug-screen.png)
[Edit in Excalidraw](./slug-screen.excalidraw)
```

### Step 8: Validate (MANDATORY — do not claim done until this passes)
```bash
DIR=docs/designs
FAIL=0
for f in "$DIR"/<slug>*.excalidraw; do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; FAIL=1; }
  PNG="${f%.excalidraw}.png"
  [ -s "$PNG" ] && echo "OK: $PNG" || { echo "FAIL: missing $PNG"; FAIL=1; }
done
grep -q '\.excalidraw' "$DIR"/<slug>.md || { echo "FAIL: no excalidraw link in design doc"; FAIL=1; }
[ $FAIL -eq 0 ] && echo "ALL CHECKS PASSED" || { echo "VALIDATION FAILED"; exit 1; }
```

## Layout guidelines

- Space elements 150–200px apart
- Standard box: width 160, height 80
- Text fontSize: 16 for labels, 20 for titles
- Wireframe layout: frames/containers first, then UI regions, then controls
- Keep labels short (2–4 words)

## File storage convention

```
docs/designs/
  <slug>.md                        ← design doc
  <slug>-<screen>.excalidraw       ← Excalidraw source (one per screen)
  <slug>-<screen>.png              ← PNG export (one per screen)
```
