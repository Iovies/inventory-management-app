param(
    [switch]$SkipBuild
)

# Kubernetes deployment script for Docker Desktop + SQLite StatefulSet.

$dockerCmd = "docker"
$kubectlCmd = "kubectl"
$dockerDesktopBin = "C:\Program Files\Docker\Docker\resources\bin"

if (-not (Get-Command $dockerCmd -ErrorAction SilentlyContinue)) {
    $dockerFallback = Join-Path $dockerDesktopBin "docker.exe"
    if (Test-Path $dockerFallback) {
        $dockerCmd = $dockerFallback
    }
}

if (-not (Get-Command $kubectlCmd -ErrorAction SilentlyContinue)) {
    $kubectlFallback = Join-Path $dockerDesktopBin "kubectl.exe"
    if (Test-Path $kubectlFallback) {
        $kubectlCmd = $kubectlFallback
    }
}

function Invoke-Checked {
    param(
        [scriptblock]$Command,
        [string]$ErrorMessage
    )

    & $Command
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: $ErrorMessage" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

function Import-ImageToKubernetesNode {
    param(
        [string]$ImageName
    )

    $nodeName = & $kubectlCmd get nodes -o jsonpath="{.items[0].metadata.name}"
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($nodeName)) {
        Write-Host "ERROR: Could not detect the Kubernetes node name." -ForegroundColor Red
        exit 1
    }

    Write-Host "Loading $ImageName into Kubernetes node $nodeName..."
    $loadCommand = "`"$dockerCmd`" save $ImageName | `"$kubectlCmd`" debug node/$nodeName -n inventory-app --image=busybox:1.36 -i --quiet --profile=general -- chroot /host ctr -n k8s.io images import -"
    cmd /c $loadCommand | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Could not load $ImageName into the Kubernetes node." -ForegroundColor Red
        exit $LASTEXITCODE
    }

    & $kubectlCmd delete pod -n inventory-app -l app.kubernetes.io/managed-by=kubectl-debug --ignore-not-found | Out-Null
}

Write-Host "Step 1: Checking Docker and Kubernetes..." -ForegroundColor Cyan
Invoke-Checked { & $dockerCmd version } "Docker is not available. Start Docker Desktop and try again."
Invoke-Checked { & $kubectlCmd cluster-info } "Kubernetes is not available. Enable Kubernetes in Docker Desktop and wait until it is running."
Write-Host "OK - Docker Desktop Kubernetes is available" -ForegroundColor Green

Write-Host "`nStep 2: Pulling SQLite image..." -ForegroundColor Cyan
Invoke-Checked { & $dockerCmd pull keinos/sqlite3:latest } "SQLite image pull failed."
Write-Host "OK - SQLite image is available" -ForegroundColor Green

if (-not $SkipBuild) {
    Write-Host "`nStep 3: Building local Docker images..." -ForegroundColor Cyan
    Invoke-Checked { & $dockerCmd build -t inventory-backend:latest .\backend } "Backend image build failed."
    Invoke-Checked { & $dockerCmd build -t inventory-frontend:latest .\frontend } "Frontend image build failed."
    Write-Host "OK - Images built locally" -ForegroundColor Green
} else {
    Write-Host "`nStep 3: Skipping image build because -SkipBuild was used" -ForegroundColor Yellow
}

Write-Host "`nStep 4: Creating namespace..." -ForegroundColor Cyan
Invoke-Checked { & $kubectlCmd apply -f k8s/namespace.yaml } "Namespace apply failed."
Invoke-Checked { & $kubectlCmd config set-context --current --namespace=inventory-app } "Could not set current kubectl namespace."
Write-Host "OK - Namespace ready" -ForegroundColor Green

Write-Host "`nStep 5: Loading images into the Kubernetes node..." -ForegroundColor Cyan
Import-ImageToKubernetesNode "keinos/sqlite3:latest"
Import-ImageToKubernetesNode "inventory-backend:latest"
Import-ImageToKubernetesNode "inventory-frontend:latest"
Write-Host "OK - Images available to Kubernetes" -ForegroundColor Green

Write-Host "`nStep 6: Applying configuration..." -ForegroundColor Cyan
Invoke-Checked { & $kubectlCmd apply -f k8s/configmap.yaml } "ConfigMap apply failed."
Write-Host "OK - Configuration applied" -ForegroundColor Green

Write-Host "`nStep 7: Deploying SQLite StatefulSet..." -ForegroundColor Cyan
Invoke-Checked { & $kubectlCmd apply -f k8s/sqlite-statefulset.yaml } "SQLite StatefulSet apply failed."
Invoke-Checked { & $kubectlCmd rollout status statefulset/sqlite -n inventory-app --timeout=120s } "SQLite StatefulSet did not become ready in time."
Write-Host "OK - SQLite StatefulSet is ready" -ForegroundColor Green

Write-Host "`nStep 8: Deploying backend..." -ForegroundColor Cyan
Invoke-Checked { & $kubectlCmd apply -f k8s/backend-deployment.yaml } "Backend deployment apply failed."
Invoke-Checked { & $kubectlCmd rollout restart deployment/backend -n inventory-app } "Backend restart failed."
Invoke-Checked { & $kubectlCmd rollout status deployment/backend -n inventory-app --timeout=240s } "Backend did not become ready in time."
Write-Host "OK - Backend is ready" -ForegroundColor Green

Write-Host "`nStep 9: Deploying frontend..." -ForegroundColor Cyan
Invoke-Checked { & $kubectlCmd apply -f k8s/frontend-deployment.yaml } "Frontend deployment apply failed."
Invoke-Checked { & $kubectlCmd rollout restart deployment/frontend -n inventory-app } "Frontend restart failed."
Invoke-Checked { & $kubectlCmd rollout status deployment/frontend -n inventory-app --timeout=120s } "Frontend did not become ready in time."
Write-Host "OK - Frontend is ready" -ForegroundColor Green

Write-Host "`nStep 10: Deployment status" -ForegroundColor Cyan
& $kubectlCmd get statefulsets -n inventory-app
& $kubectlCmd get deployments -n inventory-app
& $kubectlCmd get pods -n inventory-app
& $kubectlCmd get svc -n inventory-app
& $kubectlCmd get pvc -n inventory-app

Write-Host "`nAccess URLs" -ForegroundColor Green
Write-Host "Frontend:    http://localhost:3001" -ForegroundColor Yellow
Write-Host "Backend API: http://localhost:3001/api/products" -ForegroundColor Yellow

Write-Host "`nUseful commands" -ForegroundColor Green
Write-Host "powershell -ExecutionPolicy Bypass -File .\status-k8s.ps1"
Write-Host "& `"$kubectlCmd`" logs -f pod/sqlite-0 -n inventory-app"
Write-Host "& `"$kubectlCmd`" logs -f deployment/frontend -n inventory-app"
Write-Host "& `"$kubectlCmd`" logs -f deployment/backend -n inventory-app"
Write-Host "& `"$kubectlCmd`" exec -n inventory-app -it pod/sqlite-0 -- sqlite3 /db/inventory.db `".tables`""
Write-Host "& `"$kubectlCmd`" delete namespace inventory-app"

Write-Host "`nDone!" -ForegroundColor Green
