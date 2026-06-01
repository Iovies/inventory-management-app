# Jenkins local prin Docker Desktop

Aceasta configuratie porneste Jenkins intr-un container Docker Desktop. Jenkins foloseste Docker de pe host prin `/var/run/docker.sock`, ca sa poata rula pipeline-ul din `Jenkinsfile`.

## Pornire Jenkins

Din folderul `jenkins`:

```powershell
docker compose -f docker-compose.jenkins.yml up -d --build
```

Deschide Jenkins:

```text
http://localhost:8082
```

Parola initiala:

```powershell
docker exec inventory-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

## Plugin-uri recomandate

Instaleaza plugin-urile recomandate de Jenkins si verifica sa existe:

- Git
- GitHub
- Pipeline

Nu este necesar credential Google Cloud pentru varianta folosita in acest proiect.

## Job Jenkins

Creeaza un job de tip Pipeline:

```text
New Item -> Pipeline -> inventory-management-cicd
```

Setari importante:

```text
General -> GitHub project: URL-ul repository-ului tau GitHub
Build Triggers -> GitHub hook trigger for GITScm polling
Pipeline -> Definition: Pipeline script from SCM
SCM: Git
Repository URL: URL-ul repository-ului tau GitHub
Branch: */main
Script Path: Jenkinsfile
```

Dupa `git push`, GitHub trimite webhook la Jenkins, iar Jenkins ruleaza pipeline-ul.
