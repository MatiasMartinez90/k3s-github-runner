# K3s GitHub Actions Runner

Self-hosted GitHub Actions Runner for K3s ARM clusters - Perfect for running CI/CD pipelines on your own hardware.

## 🎯 Purpose

This repository provides everything you need to run GitHub Actions workflows on your K3s cluster, eliminating dependency on GitHub-hosted runners and providing:

- ✅ **ARM64 Native Support** - Perfect for Raspberry Pi clusters
- ✅ **Cost Savings** - Use your own hardware instead of GitHub minutes  
- ✅ **Better Performance** - Direct access to your cluster resources
- ✅ **Privacy** - Keep your builds completely local

## 🚀 Quick Start

### Prerequisites
- K3s cluster running
- `kubectl` configured and working
- `gh` CLI installed and authenticated
- Docker running on K3s nodes

### Installation

```bash
# Clone this repository
git clone https://github.com/MatiasMartinez90/k3s-github-runner.git
cd k3s-github-runner

# Run setup script with your repository URL
./scripts/setup-runner.sh https://github.com/YourUsername/your-repo

# Wait for the runner to be ready
kubectl get pods -n github-runner -w
```

## 📋 What Gets Deployed

- **Namespace**: `github-runner`
- **Deployment**: Single replica runner pod
- **Secret**: GitHub token and repository configuration
- **Labels**: `self-hosted`, `k3s`, `arm64`, `linux`

## 🔧 Configuration

The runner is configured with:

- **Resource Limits**: 2Gi memory, 1 CPU core
- **Docker Access**: Mounted Docker socket for container builds
- **Privileged Mode**: Required for Docker-in-Docker operations
- **Work Directory**: `/tmp/github-runner-workdir`

## 📖 Usage in Workflows

Once deployed, use the runner in your GitHub Actions workflows:

```yaml
jobs:
  build:
    runs-on: [self-hosted, k3s, arm64]
    steps:
    - uses: actions/checkout@v4
    - name: Build on K3s
      run: |
        echo "Running on K3s ARM cluster!"
        docker build -t my-app .
```

## 🏗️ Project Structure

```
k3s-github-runner/
├── manifests/
│   ├── namespace.yaml      # GitHub runner namespace
│   └── github-runner.yaml  # Runner deployment
├── scripts/
│   └── setup-runner.sh    # Automated setup script
└── README.md
```

## 🛠️ Manual Setup (Alternative)

If you prefer manual setup:

1. **Create namespace**:
   ```bash
   kubectl apply -f manifests/namespace.yaml
   ```

2. **Generate GitHub token**:
   ```bash
   gh api -X POST /repos/OWNER/REPO/actions/runners/registration-token --jq .token
   ```

3. **Create secret**:
   ```bash
   kubectl create secret generic runner-secret -n github-runner \
     --from-literal=github-token="YOUR_TOKEN" \
     --from-literal=github-repo="https://github.com/OWNER/REPO"
   ```

4. **Deploy runner**:
   ```bash
   kubectl apply -f manifests/github-runner.yaml
   ```

## 📊 Monitoring

Check runner status:

```bash
# View pod status
kubectl get pods -n github-runner

# View logs
kubectl logs -f deployment/github-runner -n github-runner

# Check runner registration in GitHub
gh api /repos/OWNER/REPO/actions/runners --jq '.runners[] | select(.name=="k3s-arm-runner")'
```

## 🔄 Updates

To update the runner:

```bash
# Restart deployment to pull latest image
kubectl rollout restart deployment/github-runner -n github-runner

# Or delete and recreate
kubectl delete -f manifests/github-runner.yaml
kubectl apply -f manifests/github-runner.yaml
```

## 🗑️ Removal

Remove the runner completely:

```bash
kubectl delete namespace github-runner
```

## 🤝 Contributing

This runner configuration works well for ARM-based K3s clusters. Feel free to:

- Submit issues for bugs or improvements
- Create pull requests for enhancements
- Share your use cases and configurations

## 📝 Notes

- Runner uses `sumologic/github-runner` image (ARM64 compatible)
- Requires privileged mode for Docker access
- Each repository needs its own registration token
- Tokens expire, so you may need to regenerate periodically

## 🔗 Related

- [GitHub Actions Self-hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [K3s Documentation](https://k3s.io/)
- [Docker in Kubernetes](https://kubernetes.io/docs/concepts/workloads/pods/)
