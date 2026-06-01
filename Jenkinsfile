pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    triggers {
        // Poți ajusta planificarea în funcție de necesități
        pollSCM('H/5 * * * *')
    }

environment {
    PROJECT_ID = 'alien-sol-459519-s3'
    REGION = 'europe-west1'
    REPOSITORY = 'inventory-repo'

    BACKEND_SERVICE = 'inventory-backend'
    FRONTEND_SERVICE = 'inventory-frontend'

    BACKEND_IMAGE = 'europe-west1-docker.pkg.dev/alien-sol-459519-s3/inventory-repo/inventory-backend'
    FRONTEND_IMAGE = 'europe-west1-docker.pkg.dev/alien-sol-459519-s3/inventory-repo/inventory-frontend'
}

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build (Maven)') {
            steps {
                sh 'mvn -f backend/pom.xml clean package -DskipTests'
            }
        }

        stage('Authenticate to GCP') {
            steps {
                // Așteaptă un credential de tip "secret file" în Jenkins numit gcp-sa-key
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GCP_KEY_FILE')]) {
                    sh '''
                    echo "Autentificare GCP..."
                    gcloud auth activate-service-account --key-file=${GCP_KEY_FILE}
                    gcloud config set project ${PROJECT_ID}
                    gcloud auth configure-docker europe-west3-docker.pkg.dev --quiet
                    '''
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                sh '''
                IMAGE=europe-west3-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${SERVICE_NAME}:${GIT_COMMIT}
                echo "Building image $IMAGE"
                docker build -t $IMAGE -f backend/Dockerfile backend
                docker push $IMAGE
                '''
            }
        }

        stage('Deploy to Cloud Run') {
            steps {
                // Asumăm că variabilele sensibile (DB etc.) sunt setate ca Jenkins credentials
                withCredentials([string(credentialsId: 'DB_USER', variable: 'DB_USER'), string(credentialsId: 'DB_PASSWORD', variable: 'DB_PASSWORD'), string(credentialsId: 'CLOUD_SQL_CONNECTION_NAME', variable: 'CLOUD_SQL_CONNECTION_NAME')]) {
                    sh '''
                    IMAGE=europe-west3-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${SERVICE_NAME}:${GIT_COMMIT}
                    echo "Deploying $IMAGE to Cloud Run (${REGION})"
                    gcloud run deploy ${SERVICE_NAME} --image $IMAGE --region ${REGION} --platform managed --allow-unauthenticated \
                      --set-env-vars SPRING_DATASOURCE_URL=jdbc:postgresql:///${DB_USER}?cloudSqlInstance=${CLOUD_SQL_CONNECTION_NAME}&socketFactory=com.google.cloud.sql.postgres.SocketFactory,SPRING_DATASOURCE_USERNAME=${DB_USER},SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD},SPRING_JPA_HIBERNATE_DDL_AUTO=update
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline finalizat cu succes: imagine pusă și deploy Cloud Run.'
        }
        failure {
            echo 'Pipeline eșuat. Verifică Console Output în Jenkins.'
        }
    }
}
