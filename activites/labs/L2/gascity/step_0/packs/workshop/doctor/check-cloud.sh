#!/usr/bin/env bash
# Doctor check: verify cloud provider CLI authentication.
set -euo pipefail

found=0

# AWS
if command -v aws >/dev/null 2>&1; then
    if aws sts get-caller-identity >/dev/null 2>&1; then
        found=$((found + 1))
        account=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)
        echo "  AWS: account $account" >&2
    fi
fi

# GCP
if command -v gcloud >/dev/null 2>&1; then
    if gcloud auth print-access-token >/dev/null 2>&1; then
        found=$((found + 1))
        project=$(gcloud config get-value project 2>/dev/null)
        echo "  GCP: project $project" >&2
    fi
fi

# Azure
if command -v az >/dev/null 2>&1; then
    if az account show >/dev/null 2>&1; then
        found=$((found + 1))
        sub=$(az account show --query 'name' -o tsv 2>/dev/null)
        echo "  Azure: subscription $sub" >&2
    fi
fi

if [ $found -eq 0 ]; then
    echo "no cloud CLIs authenticated (optional)"
    echo "Run: aws configure, gcloud auth login, or az login"
    exit 1
fi

echo "$found cloud provider(s) authenticated"
exit 0
