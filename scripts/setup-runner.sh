#!/bin/bash

# K3s GitHub Actions Runner Setup Script
# This script sets up a self-hosted GitHub Actions runner in your K3s cluster

set -e

REPO_URL=""
RUNNER_NAME="k3s-arm-runner"
NAMESPACE="github-runner"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}==>${NC} ${1}"
}

print_success() {
    echo -e "${GREEN}✅${NC} ${1}"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} ${1}"
}

print_error() {
    echo -e "${RED}❌${NC} ${1}"
}

# Check if repo URL is provided
if [ -z "$1" ]; then
    print_error "Repository URL is required"
    echo "Usage: $0 <github-repo-url>"
    echo "Example: $0 https://github.com/MatiasMartinez90/cognito-k3s-webhook"
    exit 1
fi

REPO_URL="$1"

print_step "Setting up GitHub Actions Runner for: ${REPO_URL}"

# Extract owner and repo from URL
if [[ $REPO_URL =~ github\.com/([^/]+)/([^/]+) ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
else
    print_error "Invalid GitHub repository URL"
    exit 1
fi

print_step "Repository: ${OWNER}/${REPO}"

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is required but not installed"
    exit 1
fi

# Generate registration token
print_step "Generating GitHub runner registration token..."
TOKEN=$(gh api -X POST "/repos/${OWNER}/${REPO}/actions/runners/registration-token" --jq .token)

if [ -z "$TOKEN" ]; then
    print_error "Failed to generate registration token"
    exit 1
fi

print_success "Registration token generated"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is required but not installed"
    exit 1
fi

# Create namespace
print_step "Creating namespace: ${NAMESPACE}"
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Create secret with GitHub token and repo URL
print_step "Creating runner secret..."
kubectl create secret generic runner-secret -n ${NAMESPACE} \
  --from-literal=github-token="${TOKEN}" \
  --from-literal=github-repo="${REPO_URL}" \
  --dry-run=client -o yaml | kubectl apply -f -

print_success "Secret created"

# Apply manifests
print_step "Applying Kubernetes manifests..."
kubectl apply -f manifests/

print_success "GitHub Actions Runner deployed!"

print_step "Waiting for pod to be ready..."
kubectl wait --for=condition=ready pod -l app=github-runner -n ${NAMESPACE} --timeout=300s

print_success "Runner is ready!"

echo ""
print_step "Runner Information:"
echo "  - Name: ${RUNNER_NAME}"
echo "  - Labels: self-hosted, k3s, arm64, linux"
echo "  - Namespace: ${NAMESPACE}"
echo "  - Repository: ${REPO_URL}"

echo ""
print_step "To check runner status:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo "  kubectl logs -f deployment/github-runner -n ${NAMESPACE}"

echo ""
print_step "To remove the runner:"
echo "  kubectl delete namespace ${NAMESPACE}"

print_success "Setup completed! Your K3s cluster now has a self-hosted GitHub Actions runner."