# Kubernetes Deployment Guide - SQLite StatefulSet

Ghid pentru Laboratorul 3: crearea obiectelor Kubernetes și lansarea aplicației pe Kubernetes folosind Docker Desktop. SQL Server a fost înlocuit cu SQLite pentru a evita eroarea de memorie din Rancher/Docker Desktop.

## Cerințe

1. Docker Desktop instalat.
2. Kubernetes activat în Docker Desktop: **Settings** -> **Kubernetes** -> **Enable Kubernetes** -> **Apply & Restart**.
3. Rancher pornit, dacă vrei să demonstrezi vizual podurile.

Verificare rapidă:

```powershell
kubectl cluster-info
docker version
```

Dacă `kubectl` nu este recunoscut, scripturile caută automat executabilul în:

```text
C:\Program Files\Docker\Docker\resources\bin
```

## Obiecte Kubernetes create

Manifestele sunt în directorul `k8s/`:

- `namespace.yaml` - namespace-ul `inventory-app`;
- `configmap.yaml` - configurare backend cu profilul `sqlite`;
- `sqlite-statefulset.yaml` - PVC, Service headless și StatefulSet pentru SQLite;
- `backend-deployment.yaml` - Deployment și Service ClusterIP pentru backend;
- `frontend-deployment.yaml` - Deployment și Service LoadBalancer pentru frontend;
- `kustomization.yaml` - lista manifestelor active.

## Deploy recomandat

Din rădăcina proiectului:

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy-k8s.ps1
```

Scriptul:

- verifică Docker și Kubernetes;
- descarcă imaginea `keinos/sqlite3:latest`;
- construiește imaginile locale `inventory-backend:latest` și `inventory-frontend:latest`;
- încarcă imaginea SQLite și imaginile locale în containerd-ul nodului Kubernetes Docker Desktop;
- aplică namespace-ul și ConfigMap-ul;
- pornește SQLite ca `StatefulSet`;
- pornește backend-ul și frontend-ul;
- afișează statusul podurilor, serviciilor și PVC-ului.

Dacă imaginile sunt deja construite și vrei doar redeploy:

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy-k8s.ps1 -SkipBuild
```

## Deploy manual

```powershell
docker pull keinos/sqlite3:latest
docker build -t inventory-backend:latest .\backend
docker build -t inventory-frontend:latest .\frontend

kubectl apply -f k8s/namespace.yaml
kubectl config set-context --current --namespace=inventory-app

$node = kubectl get nodes -o jsonpath="{.items[0].metadata.name}"
cmd /c "docker save keinos/sqlite3:latest | kubectl debug node/$node -n inventory-app --image=busybox:1.36 -i --quiet --profile=general -- chroot /host ctr -n k8s.io images import -"
cmd /c "docker save inventory-backend:latest | kubectl debug node/$node -n inventory-app --image=busybox:1.36 -i --quiet --profile=general -- chroot /host ctr -n k8s.io images import -"
cmd /c "docker save inventory-frontend:latest | kubectl debug node/$node -n inventory-app --image=busybox:1.36 -i --quiet --profile=general -- chroot /host ctr -n k8s.io images import -"
kubectl delete pod -n inventory-app -l app.kubernetes.io/managed-by=kubectl-debug --ignore-not-found

kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/sqlite-statefulset.yaml
kubectl rollout status statefulset/sqlite -n inventory-app --timeout=120s

kubectl apply -f k8s/backend-deployment.yaml
kubectl rollout status deployment/backend -n inventory-app --timeout=240s

kubectl apply -f k8s/frontend-deployment.yaml
kubectl rollout status deployment/frontend -n inventory-app --timeout=120s
```

## Verificare

```powershell
powershell -ExecutionPolicy Bypass -File .\status-k8s.ps1
```

Sau manual:

```powershell
kubectl get statefulsets -n inventory-app
kubectl get deployments -n inventory-app
kubectl get pods -n inventory-app
kubectl get svc -n inventory-app
kubectl get pvc -n inventory-app
kubectl exec -n inventory-app pod/sqlite-0 -- sqlite3 /db/inventory.db ".tables"
```

Loguri utile:

```powershell
kubectl logs -f pod/sqlite-0 -n inventory-app
kubectl logs -f deployment/backend -n inventory-app
kubectl logs -f deployment/frontend -n inventory-app
```

## Accesare aplicație

Pe Docker Desktop, frontend-ul este expus prin Service `LoadBalancer`:

```text
Frontend:    http://localhost:3001
Backend API: http://localhost:3001/api/products
```

În interfața frontend, câmpul `Backend API` trebuie să rămână:

```text
/api/products
```

Pentru backend direct:

```powershell
kubectl port-forward -n inventory-app service/backend 8081:8080
```

Apoi deschide:

```text
http://localhost:8081/api/products
```

## Rancher

În Rancher, deschide clusterul în care rulează Docker Desktop Kubernetes și caută namespace-ul `inventory-app`. Pentru laboratorul 3, poți face screenshot cu:

- `StatefulSet` `sqlite`;
- podul `sqlite-0`;
- podul `backend-...`;
- podul `frontend-...`;
- PVC-ul `sqlite-data`;
- Service-ul `frontend`.

Dacă Rancher arată cluster importat în `Provisioning`, folosește clusterul `local` pentru demo. Importul aceluiași cluster în Rancher poate rămâne blocat dacă agentul are URL de tip `https://127.0.0.1:8443`, deoarece din pod `127.0.0.1` nu este hostul Windows.

## Cleanup

```powershell
kubectl delete namespace inventory-app
```

Această comandă șterge toate obiectele aplicației, inclusiv PVC-ul și baza SQLite din Kubernetes.
