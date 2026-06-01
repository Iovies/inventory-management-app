# Inventory Management App

Aplicatie simpla pentru gestionarea produselor dintr-un inventar. Proiectul este pregatit pentru:

- Laboratorul 1: rularea si verificarea aplicatiei;
- Laboratorul 2: containerizarea aplicatiei cu Docker Desktop;
- Laboratorul 4: flux CI cu GitHub si Jenkins, folosind Docker Desktop.

Persistenta este realizata cu SQLite. Backend-ul foloseste profilul `sqlite` in mod implicit, iar in Docker baza de date este salvata in volumul `sqlite-data`, in fisierul `inventory.db`.

## Tehnologii

- Backend: Java 17, Spring Boot, Maven, Spring Data JPA;
- Baza de date: SQLite prin `org.xerial:sqlite-jdbc`;
- Frontend: HTML, CSS, JavaScript, Nginx;
- Containerizare: Docker Desktop si Docker Compose;
- CI: GitHub webhook + Jenkins Pipeline.

## Structura proiectului

```text
inventory-management-app/
|-- backend/
|   |-- src/main/java/com/example/inventory/
|   |-- src/main/resources/
|   |   |-- application.properties
|   |   |-- application-local.properties
|   |   `-- application-sqlite.properties
|   |-- pom.xml
|   `-- Dockerfile
|-- database/
|   `-- schema-sqlite.sql
|-- frontend/
|   |-- index.html
|   |-- style.css
|   |-- script.js
|   |-- nginx.conf
|   `-- Dockerfile
|-- jenkins/
|   |-- Dockerfile
|   |-- docker-compose.jenkins.yml
|   `-- README_JENKINS_LOCAL.md
|-- docs/
|   `-- LAB4_CICD_JENKINS_GITHUB_DOCKER.md
|-- docker-compose.yml
|-- Jenkinsfile
`-- README.md
```

## API backend

Backend-ul ruleaza pe portul `8080` in container si este expus local pe `8081`.

```text
GET    /api/products
GET    /api/products/low-stock
GET    /api/products/{id}
POST   /api/products
PUT    /api/products/{id}
PATCH  /api/products/{id}/quantity
DELETE /api/products/{id}
```

Exemplu JSON pentru creare sau actualizare:

```json
{
  "name": "Laptop",
  "description": "Laptop pentru birou",
  "category": "Electronice",
  "quantity": 10,
  "price": 2499.99,
  "lowStockThreshold": 5
}
```

## Laboratorul 2 - Docker Desktop + SQLite

Porneste Docker Desktop, apoi ruleaza din radacina proiectului:

```powershell
docker compose up --build -d
```

Aplicatia va fi disponibila la:

```text
Frontend:              http://localhost:3000
Backend prin frontend: http://localhost:3000/api/products
Backend direct:        http://localhost:8081/api/products
```

Verificare containere:

```powershell
docker compose ps
docker compose logs -f backend
```

Verificare SQLite:

```powershell
docker compose exec sqlite sqlite3 /db/inventory.db ".tables"
docker compose exec sqlite sqlite3 /db/inventory.db "PRAGMA integrity_check;"
```

Pentru oprire fara stergerea bazei de date:

```powershell
docker compose down
```

Pentru resetarea completa a bazei de date:

```powershell
docker compose down -v
```

## Laboratorul 4 - GitHub + Jenkins

Pentru lucrarea 4 se foloseste fluxul:

```text
git push catre GitHub
        |
        v
GitHub webhook
        |
        v
Jenkins citeste Jenkinsfile
        |
        v
Jenkins ruleaza teste, construieste imaginile si porneste aplicatia cu Docker Compose
```

Jenkins local se porneste pe portul `8082`, ca sa nu intre in conflict cu backend-ul aplicatiei:

```powershell
cd jenkins
docker compose -f docker-compose.jenkins.yml up -d --build
```

Jenkins:

```text
http://localhost:8082
```

Ghidul complet este in:

```text
docs/LAB4_CICD_JENKINS_GITHUB_DOCKER.md
```

## Observatie

Fisierele pentru Google Cloud sau Kubernetes pot ramane in proiect ca materiale optionale, dar pentru cerinta mentionata aici traseul folosit este Docker Desktop + SQLite + Jenkins + GitHub.
