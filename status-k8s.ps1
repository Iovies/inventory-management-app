# Kubernetes status helper for Docker Desktop.

$kubectlCmd = "kubectl"
$dockerDesktopBin = "C:\Program Files\Docker\Docker\resources\bin"

if (-not (Get-Command $kubectlCmd -ErrorAction SilentlyContinue)) {
    $kubectlFallback = Join-Path $dockerDesktopBin "kubectl.exe"
    if (Test-Path $kubectlFallback) {
        $kubectlCmd = $kubectlFallback
    }
}

if (-not (Get-Command $kubectlCmd -ErrorAction SilentlyContinue) -and -not (Test-Path $kubectlCmd)) {
    Write-Host "ERROR: kubectl was not found." -ForegroundColor Red
    Write-Host "Install Docker Desktop or add this folder to PATH:" -ForegroundColor Yellow
    Write-Host $dockerDesktopBin -ForegroundColor Yellow
    exit 1
}

Write-Host "Kubernetes cluster:" -ForegroundColor Cyan
& $kubectlCmd cluster-info
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Kubernetes is not running. Enable Kubernetes in Docker Desktop." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "`nStatefulSets:" -ForegroundColor Cyan
& $kubectlCmd get statefulsets -n inventory-app

Write-Host "`nDeployments:" -ForegroundColor Cyan
& $kubectlCmd get deployments -n inventory-app

Write-Host "`nPods:" -ForegroundColor Cyan
& $kubectlCmd get pods -n inventory-app

Write-Host "`nServices:" -ForegroundColor Cyan
& $kubectlCmd get svc -n inventory-app

Write-Host "`nPersistent volumes:" -ForegroundColor Cyan
& $kubectlCmd get pvc -n inventory-app

Write-Host "`nSQLite tables:" -ForegroundColor Cyan
& $kubectlCmd exec -n inventory-app pod/sqlite-0 -- sqlite3 /db/inventory.db ".tables"

Write-Host "`nAccess URLs:" -ForegroundColor Green
Write-Host "Frontend:    http://localhost:3001" -ForegroundColor Yellow
Write-Host "Backend API: http://localhost:3001/api/products" -ForegroundColor Yellow
