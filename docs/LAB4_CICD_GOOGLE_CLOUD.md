# Lucrarea de laborator nr. 4 - CI/CD pe Google Cloud

## 1. Scop

Scopul lucrarii este implementarea unui flow CI/CD pentru aplicatia Inventory Management App. Pipeline-ul construieste imaginile Docker pentru backend si frontend, le incarca in Artifact Registry si le livreaza automat in Google Cloud.

## 2. Servicii Google Cloud folosite

- Cloud Build - executa pipeline-ul CI/CD la fiecare push sau manual.
- Artifact Registry - stocheaza imaginile Docker private ale aplicatiei.
- Google Kubernetes Engine - ruleaza aplicatia containerizata pe Kubernetes.
- Cloud Run - varianta optionala pentru deploy serverless; in acest proiect este recomandata doar pentru demonstratie, deoarece profilul folosit este `local`, fara persistenta reala a bazei de date.
- IAM - ofera permisiunile necesare contului de serviciu Cloud Build.
- Cloud Logging - pastreaza logurile build-urilor si ale serviciilor.

## 3. De ce recomand GKE pentru acest proiect

Proiectul existent are deja fisiere Kubernetes in folderul `k8s/` si foloseste SQLite pe un volum persistent. GKE poate folosi `PersistentVolumeClaim`, de aceea este varianta cea mai apropiata de structura actuala a proiectului.

Cloud Run este potrivit pentru containere stateless. Pentru o aplicatie cu baza de date persistenta, pe Cloud Run ar trebui folosita o baza de date externa, de exemplu Cloud SQL. In fisierul `cloudbuild.cloudrun-demo.yaml`, backend-ul este rulat cu profilul `local`, deci datele sunt doar pentru demo.

## 4. Pregatirea locala

Testeaza proiectul local cu Docker Desktop:

```powershell
docker compose up --build -d
```

Verificare:

```powershell
docker compose ps
```

Aplicatia locala:

```text
Frontend: http://localhost:3001
Backend:  http://localhost:8081/api/products
```

## 5. Pregatirea Google Cloud

Seteaza variabilele in PowerShell:

```powershell
$PROJECT_ID="id-ul-proiectului-tau"
$REGION="europe-west1"
$ZONE="europe-west1-b"
$REPOSITORY="inventory-repo"
$CLUSTER="inventory-gke"

gcloud config set project $PROJECT_ID
```

Activeaza API-urile necesare:

```powershell
gcloud services enable cloudbuild.googleapis.com artifactregistry.googleapis.com container.googleapis.com run.googleapis.com
```

Creeaza repository Docker in Artifact Registry:

```powershell
gcloud artifacts repositories create $REPOSITORY --repository-format=docker --location=$REGION --description="Docker images pentru Inventory Management App"
```

Creeaza cluster GKE standard:

```powershell
gcloud container clusters create $CLUSTER --zone=$ZONE --num-nodes=1 --machine-type=e2-medium
```

## 6. Permisiuni pentru Cloud Build

Afla numarul proiectului:

```powershell
$PROJECT_NUMBER = gcloud projects describe $PROJECT_ID --format="value(projectNumber)"
$CB_SA = "$PROJECT_NUMBER@cloudbuild.gserviceaccount.com"
```

Acorda permisiuni pentru Artifact Registry si GKE:

```powershell
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$CB_SA" --role="roles/artifactregistry.writer"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$CB_SA" --role="roles/container.developer"
```

## 7. Rulare pipeline GKE manual

Din folderul radacina al proiectului:

```powershell
gcloud builds submit --config cloudbuild.gke.yaml --substitutions _REGION=$REGION,_AR_REPOSITORY=$REPOSITORY,_GKE_CLUSTER=$CLUSTER,_GKE_LOCATION=$ZONE .
```

La final, verifica resursele:

```powershell
gcloud container clusters get-credentials $CLUSTER --zone=$ZONE
kubectl get pods -n inventory-app
kubectl get svc -n inventory-app
```

Pentru URL/IP extern:

```powershell
kubectl get svc frontend -n inventory-app
```

Acceseaza aplicatia la:

```text
http://EXTERNAL-IP:3001
```

## 8. Trigger automat CI/CD

In Google Cloud Console:

1. Deschide Cloud Build -> Triggers.
2. Creeaza trigger nou.
3. Conecteaza repository-ul GitHub/GitLab/Cloud Source.
4. Alege evenimentul: push pe branch-ul `main`.
5. La Configuration alege Cloud Build configuration file.
6. La locatie scrie: `cloudbuild.gke.yaml`.
7. Salveaza trigger-ul.

Dupa fiecare push pe `main`, Cloud Build va construi imaginile, le va incarca in Artifact Registry si va actualiza deployment-ul in GKE.

## 9. Varianta optionala: Cloud Run demo

Aceasta varianta deployeaza doua servicii Cloud Run: `inventory-backend` si `inventory-frontend`. Backend-ul ruleaza cu profilul `local`, fara persistenta externa.

```powershell
gcloud builds submit --config cloudbuild.cloudrun-demo.yaml --substitutions _REGION=$REGION,_AR_REPOSITORY=$REPOSITORY .
```

La final, Cloud Build afiseaza URL-ul frontend-ului.

## 10. Ce trebuie prezentat in laborator

Capturi de ecran recomandate:

1. Repository Git cu fisierele `cloudbuild.gke.yaml` si `k8s/overlays/gke/`.
2. Artifact Registry cu imaginile `inventory-backend` si `inventory-frontend`.
3. Cloud Build cu build reusit.
4. GKE Workloads: deployment-urile `backend`, `frontend`, `sqlite`.
5. GKE Services: serviciul `frontend` cu IP extern.
6. Aplicatia deschisa in browser.

## 11. Cleanup

Sterge resursele pentru a evita costuri:

```powershell
kubectl delete namespace inventory-app
gcloud container clusters delete $CLUSTER --zone=$ZONE
gcloud artifacts repositories delete $REPOSITORY --location=$REGION
```
