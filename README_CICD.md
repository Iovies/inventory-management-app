# CI/CD for Inventory Management App

Acest fișier descrie pașii pentru integrarea continuă și livrarea pe Google Cloud folosind GitHub Actions și Jenkins.

## GitHub Actions

- Workflow-ul se află în `.github/workflows/ci-cd.yml`.
- Ce face: compilează backend-ul (`backend/pom.xml`), construiește imaginea Docker (folosind `backend/Dockerfile`), o împinge în Artifact Registry și face deploy pe Cloud Run.

### Secrete GitHub necesare

- `GCP_PROJECT_ID` - ID proiect GCP
- `GCP_SA_KEY` - cheie JSON pentru service account cu permisiuni Artifact Registry + Cloud Run
- `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `CLOUD_SQL_CONNECTION_NAME` - (opțional) pentru configurare Cloud SQL

## Jenkins

- `Jenkinsfile` la root a fost actualizat pentru a realiza aceleași etape: build Maven, autentificare GCP, build/push Docker și deploy Cloud Run.
- În Jenkins trebuie să adaugi următoarele credentials:
  - `gcp-sa-key` (Secret File) — cheia JSON a service account-ului
  - `GCP_PROJECT_ID` (Secret Text) — project id
  - `DB_USER`, `DB_PASSWORD`, `CLOUD_SQL_CONNECTION_NAME` (String) — dacă folosești Cloud SQL

## Pași rapizi de configurare

1. În GitHub repo -> Settings -> Secrets, creează secretele listate mai sus.
2. Dacă folosești Jenkins: adaugă credential `gcp-sa-key` (secret file) și celelalte variabile ca Secret Text/String.
3. Pentru Cloud Run, asigură-te că Service Account are permisiunile: `roles/run.admin`, `roles/storage.admin` (sau Artifact Registry writer), `roles/iam.serviceAccountUser`.
4. Fă push pe `main` pentru a declanșa workflow-ul GitHub Actions.

Dacă dorești, pot:
- Ajusta numele `REPOSITORY`/`SERVICE_NAME` după preferințe.
- Adăuga pași pentru rulare de teste și sonarqube.
