#!/usr/bin/env bash
set -euo pipefail

# Setup Baseline Factory for Gas City
# Assumes software-factory-intensive is cloned at ~/Projects/actual-software/software-factory-intensive

SFI_DIR="$HOME/Projects/actual-software/software-factory-intensive"
PROJECT_DIR="$HOME/Projects/factory/baseline/base-project"
FACTORY_DIR="$HOME/Projects/factory/baseline/base-gc-factory"

# --- 1. Init Factory and Project ---
echo "==> Initializing project repository..."
mkdir -p "$PROJECT_DIR"
pushd "$PROJECT_DIR" > /dev/null
if [ ! -d .git ]; then
  git init
  touch README.md && git add -A && git commit -m "initial"
else
  echo "    Project repo already initialized, skipping."
fi
popd > /dev/null

echo "==> Initializing Gas City factory (custom template)..."
if [ ! -d "$FACTORY_DIR" ]; then
  echo "3" | gc init "$FACTORY_DIR"
else
  echo "    Factory directory already exists, skipping gc init."
fi

# --- 2. Configure Factory ---
echo "==> Configuring factory (city.toml + packs)..."
cp "$SFI_DIR/prerequisites/city.toml" "$FACTORY_DIR/city.toml"
rsync -av "$SFI_DIR/packs/" "$FACTORY_DIR/packs/actual/"

# --- 3. Register City ---
echo "==> Registering factory with Gas City..."
pushd "$FACTORY_DIR" > /dev/null
gc stop || true
gc register "$FACTORY_DIR"
gc service restart
gc status
gc doctor --fix

# --- 4. Add Rig ---
echo "==> Adding project rig to factory..."
gc rig add "$PROJECT_DIR"

# Add includes to the [[rigs]] entry that gc rig add created
echo "==> Patching rig includes in city.toml..."
if ! grep -q 'includes = \["packs/actual/all"\]' "$FACTORY_DIR/city.toml"; then
  sed -i '' '/^\[\[rigs\]\]/,/^path/ {
    /^path/a\
includes = ["packs/actual/all"]
  }' "$FACTORY_DIR/city.toml"
fi
popd > /dev/null

# --- 5. Patch "convoy" in Factory and Project ---
echo "==> Patching convoy type in factory and project..."
pushd "$PROJECT_DIR" > /dev/null
bd config set types.custom "convoy"
popd > /dev/null

pushd "$FACTORY_DIR" > /dev/null
bd config set types.custom "convoy"
popd > /dev/null

# --- 6. Restart Factory ---
echo "==> Restarting factory..."
pushd "$FACTORY_DIR" > /dev/null
gc stop
gc start
gc restart
popd > /dev/null

# --- 7. Start Dashboard ---
echo "==> Starting Gas City dashboard..."
pushd "$FACTORY_DIR" > /dev/null
gc dashboard serve &
popd > /dev/null

echo ""
echo "==> Baseline factory setup complete!"
echo "    Dashboard: http://localhost:8080"
echo "    Factory:   $FACTORY_DIR"
echo "    Project:   $PROJECT_DIR"
