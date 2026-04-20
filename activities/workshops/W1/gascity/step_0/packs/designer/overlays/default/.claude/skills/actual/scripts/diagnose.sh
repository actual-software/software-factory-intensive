#!/usr/bin/env bash
# diagnose.sh - Comprehensive environment diagnostic for the actual CLI.
# Read-only: never modifies files, config, or state.
# Never prints secrets: only prints "set" or "not set" for sensitive values.
# Portable: works on macOS and Linux (requires only bash, which, command).
# Exit 0 on diagnostic findings; exit 1 only on script errors.

set -euo pipefail

# --- Helpers ---

pass() { printf "  [PASS] %s\n" "$1"; }
fail() { printf "  [FAIL] %s\n" "$1"; }
info() { printf "  [INFO] %s\n" "$1"; }
section() { printf "\n=== %s ===\n" "$1"; }

check_binary() {
  local name="$1"
  local path
  if path=$(command -v "$name" 2>/dev/null); then
    pass "$name found at $path"
    return 0
  else
    fail "$name not found in PATH"
    return 1
  fi
}

check_env_var() {
  local var_name="$1"
  local value="${!var_name:-}"
  if [ -n "$value" ]; then
    pass "$var_name is set"
  else
    fail "$var_name is not set"
  fi
}

# --- Section 1: actual CLI ---

section "actual CLI"

if check_binary "actual"; then
  version_output=$(actual --version 2>&1) || version_output="(could not get version)"
  info "Version: $version_output"
else
  fail "actual CLI is not installed. Remaining checks may be limited."
fi

# --- Section 2: Runner Binaries ---

section "Runner Binaries"

check_binary "claude"  || true
check_binary "codex"   || true
check_binary "agent"   || true

# --- Section 3: Authentication ---

section "Authentication"

if command -v actual >/dev/null 2>&1; then
  auth_output=$(actual auth 2>&1) || true
  # Print each line as info
  while IFS= read -r line; do
    [ -n "$line" ] && info "$line"
  done <<< "$auth_output"
else
  info "Skipping auth check (actual CLI not found)"
fi

# --- Section 4: Environment Variables ---

section "Environment Variables"

check_env_var "ANTHROPIC_API_KEY"
check_env_var "OPENAI_API_KEY"
check_env_var "CURSOR_API_KEY"
check_env_var "ACTUAL_CONFIG"
check_env_var "ACTUAL_CONFIG_DIR"

# --- Section 5: Configuration ---

section "Configuration"

if command -v actual >/dev/null 2>&1; then
  config_path=$(actual config path 2>&1) || config_path="(could not determine)"
  info "Config path: $config_path"

  if [ -f "$config_path" ]; then
    pass "Config file exists"
    # Check permissions (Unix only)
    if command -v stat >/dev/null 2>&1; then
      if [[ "$OSTYPE" == darwin* ]]; then
        perms=$(stat -f "%Lp" "$config_path" 2>/dev/null) || perms="unknown"
      else
        perms=$(stat -c "%a" "$config_path" 2>/dev/null) || perms="unknown"
      fi
      if [ "$perms" = "600" ]; then
        pass "Config file permissions: $perms (secure)"
      else
        info "Config file permissions: $perms (expected 600 for files with API keys)"
      fi
    fi
  else
    info "Config file does not exist (using defaults)"
  fi

  # Show config (non-sensitive fields only)
  config_output=$(actual config show 2>&1) || config_output="(could not read config)"
  while IFS= read -r line; do
    # Skip lines that look like they contain API key values
    case "$line" in
      *api_key*:*sk-*|*api_key*:*key-*)
        # Redact actual key values but show the field exists
        field=$(echo "$line" | cut -d: -f1)
        info "$field: [REDACTED]"
        ;;
      *)
        [ -n "$line" ] && info "$line"
        ;;
    esac
  done <<< "$config_output"
else
  info "Skipping config check (actual CLI not found)"
fi

# --- Section 6: Output Files ---

section "Output Files"

check_output_file() {
  local file="$1"
  local format="$2"
  if [ -f "$file" ]; then
    pass "$file exists ($format format)"
    # Check for managed section markers
    if grep -q "managed:actual-start" "$file" 2>/dev/null; then
      pass "$file has managed section markers"
      # Extract last-synced timestamp if present
      synced=$(grep -o 'last-synced: [^-]*[^ ]*' "$file" 2>/dev/null | head -1) || true
      [ -n "$synced" ] && info "$synced"
      # Extract version if present
      ver=$(grep -o 'version: [0-9]*' "$file" 2>/dev/null | head -1) || true
      [ -n "$ver" ] && info "$ver"
    else
      info "$file exists but has no managed section markers"
    fi
  else
    info "$file does not exist"
  fi
}

check_output_file "CLAUDE.md" "claude-md"
check_output_file "AGENTS.md" "agents-md"
check_output_file ".cursor/rules/actual-policies.mdc" "cursor-rules"

# --- Section 7: Git Repository ---

section "Git Repository"

if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  pass "Inside a git repository"
  branch=$(git branch --show-current 2>/dev/null) || branch="(detached HEAD)"
  info "Branch: $branch"
  remote=$(git remote get-url origin 2>/dev/null) || remote="(no origin remote)"
  info "Origin: $remote"
else
  info "Not inside a git repository (analysis caching will be disabled)"
fi

# --- Section 8: Status ---

section "Status"

if command -v actual >/dev/null 2>&1; then
  status_output=$(actual status 2>&1) || true
  while IFS= read -r line; do
    [ -n "$line" ] && info "$line"
  done <<< "$status_output"
else
  info "Skipping status check (actual CLI not found)"
fi

# --- Summary ---

section "Diagnostic Complete"
info "Review [FAIL] items above for issues to resolve."
info "For detailed error help, see references/error-catalog.md"
