# Lucrarea de laborator Nr. 4 - CI cu Jenkins, GitHub si Docker Desktop

## Obiectiv

Familiarizarea cu un flow CI pornit automat de GitHub si executat in Jenkins.

## Instrumente folosite

- GitHub - repository pentru codul sursa;
- Jenkins - ruleaza pipeline-ul la fiecare `git push`;
- Docker Desktop - construieste si porneste containerele;
- Docker Compose - porneste serviciile `sqlite`, `backend` si `frontend`;
- SQLite - baza de date persistenta in volumul Docker `sqlite-data`.

## Fluxul CI

```text
Developer modifica aplicatia
        |
        v
git add / git commit / git push
        |
        v
GitHub trimite webhook catre Jenkins
        |
        v
Jenkins citeste Jenkinsfile
        |
        v
Jenkins ruleaza testele backend
        |
        v
Jenkins construieste imaginile Docker
        |
        v
Jenkins porneste aplicatia cu docker compose
        |
        v
Aplicatia este disponibila local la http://localhost:3000
```

Pipeline-ul nu face `git push`. Push-ul este facut manual de dezvoltator, iar GitHub declanseaza Jenkins.

## 1. Pregatirea repository-ului GitHub

Din radacina proiectului:

```powershell
git init
git add .
git commit -m "Initial inventory app with Docker and Jenkins"
git branch -M main
git remote add origin https://github.com/USERNAME/inventory-management-app.git
git push -u origin main
```

## 2. Pornire Jenkins local

Din folderul `jenkins`:

```powershell
docker compose -f docker-compose.jenkins.yml up -d --build
```

Jenkins este disponibil la:

```text
http://localhost:8082
```

Parola initiala:

```powershell
docker exec inventory-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

## 3. Configurare Jenkins job

Creeaza un job nou:

```text
New Item -> Pipeline -> nume: inventory-management-cicd
```

Setari:

```text
General -> GitHub project: URL-ul repository-ului tau GitHub
Build Triggers -> GitHub hook trigger for GITScm polling
Pipeline -> Definition: Pipeline script from SCM
SCM: Git
Repository URL: URL-ul repository-ului GitHub
Branch: */main
Script Path: Jenkinsfile
```

## 4. Configurare webhook in GitHub

In repository-ul GitHub:

```text
Settings -> Webhooks -> Add webhook
```

Setari:

```text
Payload URL: http://PUBLIC_JENKINS_URL/github-webhook/
Content type: application/json
Events: Just the push event
Active: checked
```

Daca Jenkins ruleaza local pe calculatorul tau, GitHub nu poate accesa `localhost`. Pentru demonstratie poti folosi ngrok:

```powershell
ngrok http 8082
```

Exemplu Payload URL:

```text
https://adresa-ngrok/github-webhook/
```

## 5. Etapele din Jenkinsfile

Pipeline-ul executa:

1. Checkout from GitHub
2. Backend tests
3. Build Docker images
4. Deploy with Docker Desktop
5. Verify SQLite and API

La final, aplicatia ruleaza prin Docker Compose:

```text
Frontend: http://localhost:3000
Backend:  http://localhost:8081/api/products
SQLite:   volum Docker sqlite-data, fisier /db/inventory.db
```

## 6. Verificarea ceruta

Fa o modificare vizibila in cod, de exemplu in `frontend/index.html`.

Trimite modificarea in GitHub:

```powershell
git status
git add .
git commit -m "Test Jenkins pipeline"
git push origin main
```

Dupa `git push`, Jenkins trebuie sa porneasca automat. Build-ul este corect daca:

- stage-urile sunt verzi;
- `docker compose ps` arata containerele `inventory-sqlite`, `inventory-backend`, `inventory-frontend`;
- `http://localhost:3000` incarca aplicatia;
- `http://localhost:3000/api/products` raspunde cu JSON;
- comanda SQLite returneaza `ok`:

```powershell
docker compose exec sqlite sqlite3 /db/inventory.db "PRAGMA integrity_check;"
```

## Concluzie

Pentru aceasta varianta, cerinta este acoperita prin GitHub pentru cod sursa si webhook, Jenkins pentru pipeline, Docker Desktop pentru build/rulare si SQLite pentru persistenta.
