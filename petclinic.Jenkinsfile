pipeline {
  options {
    ansiColor('xterm')
  }
  environment {
    //MAVEN_OPTS = '-Djansi.force=true'
    //registry_url = https://registry-1.docker.io/v2/
    dockerhub_credentials = 'jenkins-dockerhub'
    image_name = 'spring-petclinic'
    spring_boot_release = '2.3.0.BUILD-SNAPSHOT'
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
  containers:
    - name: maven
      image: maven:latest
      command:
      - cat
      tty: true
      volumeMounts:
        - mountPath: "/root/.m2"
          name: m2
    - name: docker
      image: docker:latest
      command:
      - cat
      tty: true
      volumeMounts:
        - mountPath: /var/run/docker.sock
          name: docker-sock
    - name: docker-compose
      image: pwbdod/docker-compose-aws-tf:latest
      command:
      - cat
      tty: true
      volumeMounts:
        - mountPath: /var/run/docker.sock
          name: docker-sock
  volumes:
    - name: docker-sock
      hostPath:
        path: /var/run/docker.sock
    - name: m2
      persistentVolumeClaim:
        claimName: m2
"""
}
   }
  stages {
    stage("Build") {
      steps {
          container('docker') {
              sh """
              pwd
              ls -ltra --color
              docker build --build-arg url=https://github.com/spring-projects/spring-petclinic.git\
              --build-arg project=spring-petclinic\
              --build-arg artifactid=spring-petclinic\
              --build-arg version=${spring_boot_release}\
              -t nfrankel/spring-petclinic - < Dockerfile
              """
          }
      }
    }
    stage ('Docker Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${dockerhub_credentials}", passwordVariable: 'dockerhub_pw', usernameVariable: 'dockerhub_user')]) {
          container('docker') {
            sh '''
                #!/bin/bash
                # Docker Registry: Dockerhub public registry login (https://hub.docker.com)
                docker login -u ${dockerhub_user} -p ${dockerhub_pw}
                docker tag nfrankel/spring-petclinic ${dockerhub_user}/${image_name}
                docker push ${dockerhub_user}/${image_name}  
                docker images 
                docker logout 
                '''
          }
        }
      }
    }
    stage ('kubernetes deploy'){
      steps {
        kubernetesDeploy(kubeconfigId: 'digitalocean',
            configs: 'deployment.yaml', 
            enableConfigSubstitution: true,
            secretNamespace: '',
            secretName: '', 
            dockerCredentials: [
              [credentialsId: "${dockerhub_credentials}"],
            ]    
        )
      }
    }
    stage ('kubernetes service + ingress'){
      steps {
        kubernetesDeploy(kubeconfigId: 'digitalocean',
            configs: 'service.yaml', 
            enableConfigSubstitution: true,
            secretNamespace: '',
            secretName: ''
        )
        kubernetesDeploy(kubeconfigId: 'digitalocean',
            configs: 'ingress.yaml', 
            enableConfigSubstitution: true,
            secretNamespace: '',
            secretName: '' 
        )
      }
    }

  }
}