pipeline {
  options {
    ansiColor('xterm')
  }
  environment {
    //MAVEN_OPTS = '-Djansi.force=true'
    //registry_url = https://registry-1.docker.io/v2/
    dockerhub_credentials = 'jenkins-dockerhub'
    image_name = 'spring-petclinic'
  }
  agent {
    kubernetes {
      label 'k8s-agent'
      defaultContainer 'jnlp'
      yaml """
apiVersion: v1
kind: Pod
metadata:
labels:
  component: ci
spec:
  # Use service account that can deploy to all namespaces
  serviceAccountName: k8s-agent
"""
}
   }
  stages {
    stage ('kubernetes delete'){
      steps {
        kubernetesDeploy(kubeconfigId: 'digitalocean',
            configs: 'deployment.yaml', 
            enableConfigSubstitution: true,
            secretNamespace: '',
            secretName: '', 
            deleteResource: true
        )
      }
    }
  }
}