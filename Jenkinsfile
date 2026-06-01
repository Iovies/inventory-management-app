pipeline {
agent any

```
options {
    timestamps()
    disableConcurrentBuilds()
}

triggers {
    pollSCM('H/5 * * * *')
}

environment {
    PROJECT_ID = 'alien-sol-459519-s3'
    REGION = 'europe-west1'
    REPOSITORY = 'inventory-repo'
    SERVICE_NAME = 'inventory-backend'
}

stages {
    stage('Checkout') {
        steps {
            checkout scm
        }
    }

    stage('Build Maven') {
        steps {
            sh 'mvn -f backend/pom.xml clean package -DskipTests'
        }
    }

    stage('Authenticate to GCP') {
        steps {
            withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GCP_KEY_FILE')]) {
                sh '''
                echo "Autentificare GCP..."
                gcloud auth activate-service-account --key-file=${GCP_KEY_FILE}
                gcloud config set project ${PROJECT_ID}
                gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet
                '''
            }
        }
    }

    stage('Build and Push Docker Image') {
        steps {
            sh '''
            IMAGE=${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${SERVICE_NAME}:${GIT_COMMIT}
            echo "Building image $IMAGE"
            docker build -t $IMAGE -f backend/Dockerfile backend
            docker push $IMAGE
            '''
        }
    }

    stage('Deploy to Cloud Run') {
        steps {
            sh '''
            IMAGE=${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${SERVICE_NAME}:${GIT_COMMIT}
            echo "Deploying $IMAGE to Cloud Run"

            gcloud run deploy ${SERVICE_NAME} \
              --image=$IMAGE \
              --region=${REGION} \
              --platform=managed \
              --allow-unauthenticated \
              --project=${PROJECT_ID}
            '''
        }
    }
}

post {
    success {
        echo 'Pipeline finalizat cu succes: backend build, push și deploy pe Cloud Run.'
    }
    failure {
        echo 'Pipeline eșuat. Verifică Console Output în Jenkins.'
    }
}
```

}
