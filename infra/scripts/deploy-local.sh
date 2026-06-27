#!/bin/bash
set -e

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log() { echo -e "${CYAN}🚀 $1${NC}"; }
wait_msg() { echo -e "${YELLOW}⏳ $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }

log "Setting up Arcus local cluster..."
kind create cluster --name arcus --config infra/k8s/kind-config.yaml

kubectl cluster-info --context kind-arcus
kubectl get nodes
kubectl apply -f infra/k8s/base/namespace.yaml

log "Installing Kong API Gateway..."
helm repo add kong https://charts.konghq.com
helm repo update

helm install kong kong/kong \
  -n kong \
  -f infra/k8s/gateway/kong-values.yaml

wait_msg "Waiting for Kong to be ready..."
kubectl wait --for=condition=ready pod \
  --selector=app.kubernetes.io/name=gateway \
  --namespace=kong \
  --timeout=120s

log "Applying base infrastructure..."
kubectl apply -k infra/k8s/base/
success "Done! Kong available at http://localhost:8080"

log "Running hello-test..."
kubectl apply -f infra/k8s/test/services/hello/hello.service.yaml
kubectl apply -f infra/k8s/test/services/hello/hello.ingress.yaml

kubectl wait --for=condition=ready pod -l app=hello -n arcus --timeout=60s

curl -s http://localhost:8000/hello
echo ""

kubectl delete -f infra/k8s/base/hello-test.yaml
success "Test completed and cleaned up successfully!"