#!/usr/bin/env bash
# Doctor check: verify observability service connectivity.
set -euo pipefail

found=0
warnings=0

# Sentry
if [ -n "${SENTRY_AUTH_TOKEN:-}" ]; then
    resp=$(curl -sf -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
        "https://sentry.io/api/0/organizations/" 2>/dev/null || echo "")
    if echo "$resp" | jq -e '.[0].slug' >/dev/null 2>&1; then
        found=$((found + 1))
    else
        warnings=$((warnings + 1))
        echo "  Sentry: token invalid" >&2
    fi
fi

# DataDog
if [ -n "${DATADOG_API_KEY:-}" ]; then
    site="${DATADOG_SITE:-datadoghq.com}"
    resp=$(curl -sf -H "DD-API-KEY: $DATADOG_API_KEY" \
        "https://api.${site}/api/v1/validate" 2>/dev/null || echo "")
    if echo "$resp" | jq -e '.valid == true' >/dev/null 2>&1; then
        found=$((found + 1))
    else
        warnings=$((warnings + 1))
        echo "  DataDog: API key invalid" >&2
    fi
fi

# PostHog
if [ -n "${POSTHOG_API_KEY:-}" ]; then
    host="${POSTHOG_HOST:-https://app.posthog.com}"
    resp=$(curl -sf -H "Authorization: Bearer $POSTHOG_API_KEY" \
        "${host}/api/projects/" 2>/dev/null || echo "")
    if echo "$resp" | jq -e '.results[0].id' >/dev/null 2>&1; then
        found=$((found + 1))
    else
        warnings=$((warnings + 1))
        echo "  PostHog: API key invalid" >&2
    fi
fi

# Grafana
if [ -n "${GRAFANA_API_KEY:-}" ] && [ -n "${GRAFANA_URL:-}" ]; then
    resp=$(curl -sf -H "Authorization: Bearer $GRAFANA_API_KEY" \
        "${GRAFANA_URL}/api/org" 2>/dev/null || echo "")
    if echo "$resp" | jq -e '.id' >/dev/null 2>&1; then
        found=$((found + 1))
    else
        warnings=$((warnings + 1))
        echo "  Grafana: connection failed" >&2
    fi
fi

# Gas City OTel
if [ -n "${GC_OTEL_METRICS_URL:-}" ]; then
    if curl -sf "${GC_OTEL_METRICS_URL}/health" >/dev/null 2>&1 || \
       curl -sf "${GC_OTEL_METRICS_URL}/-/healthy" >/dev/null 2>&1; then
        found=$((found + 1))
    else
        warnings=$((warnings + 1))
        echo "  OTel metrics endpoint: unreachable" >&2
    fi
fi

if [ $found -eq 0 ] && [ $warnings -eq 0 ]; then
    echo "no observability services configured (optional)"
    exit 1
fi

if [ $warnings -gt 0 ]; then
    echo "$found connected, $warnings failed"
    exit 1
fi

echo "$found observability service(s) connected"
exit 0
