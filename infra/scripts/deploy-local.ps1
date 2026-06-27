$ErrorActionPreference = "Stop"

function Log-Info ($Message)    { Write-Host "🚀 $Message" -ForegroundColor Cyan }
function Log-Wait ($Message)    { Write-Host "⏳ $Message" -ForegroundColor Yellow }
function Log-Success ($Message) { Write-Host "✅ $Message" -ForegroundColor Green }

Log-Info "Setting up Arcus local cluster..."
kind create cluster --name arcus --config infra/k8s/kind-config.yaml
if ($LASTEXITCODE -ne 0) { Write-Error "❌ Failed to create cluster"; exit 1 }

kubectl cluster-info --context kind-arcus
kubectl get nodes
kubectl apply -f infra/k8s/base/namespace.yaml

Log-Info "Installing Kong API Gateway..."
helm repo add kong https://charts.konghq.com
helm repo update

helm install kong kong/kong -n kong --create-namespace `
  -f infra/k8s/gateway/kong-values.yaml

kubectl get svc -n kong

Log-Wait "Waiting for Kong to be ready..."
Start-Sleep -Seconds 10

kubectl wait --for=condition=ready pod `
  --selector=app.kubernetes.io/name=kong `
  --namespace=kong `
  --timeout=120s

Log-Info "Applying base infrastructure..."
kubectl apply -k infra/k8s/base/
Log-Success "Done! Kong available at http://localhost:8000"

Log-Info "Running hello-test..."
kubectl apply -f infra/k8s/test/services/hello/

kubectl wait --for=condition=ready pod -l app=hello -n arcus --timeout=60s

Log-Wait "Waiting for Kong Ingress Controller to sync routes..."
Start-Sleep -Seconds 10

Log-Info "Testing endpoint..."
Invoke-RestMethod -Uri "http://localhost:8000/hello"
Write-Host ""

kubectl delete -f infra/k8s/test/services/hello/
Log-Success "Test completed and cleaned up successfully!"