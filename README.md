# Proof of Concept: Jenkins Configuration as Code on Kubernetes. A Codecentric/Jenkins Helm 3 Sample Chart on Digital Ocean Kubernetes with Spring Petclinic Demo Pipeline 
- [Introduction](#introduction)
- [Disclaimer](#disclaimer)
- [Requirements](#requirements)
- [Tips for validating JCasC YAML](#tips-for-validating-jcasc-yaml)
- [Tips for adding jenkins jobs to JCasC. Use a Seed Job](#tips-for-adding-jenkins-jobs-to-jcasc-use-a-seed-job)
- [Screenshots](#screenshots)
- [Environment](#environment)
- [YAML Settings](#yaml-settings)
  - [Settings to be updated on each DO Kubernetes Cluster](#settings-to-be-updated-on-each-do-kubernetes-cluster)
  - [Settings to be updated on Petclinic Software Delivery Demo Pipeline](#settings-to-be-updated-on-petclinic-software-delivery-demo-pipeline)
- [Setting up Nginx Ingress Controller](#setting-up-nginx-ingress-controller)
- [Setting up External Dns (included in deploy.sh)](#setting-up-external-dns-included-in-deploysh)
- [Deployment with deploy.sh](#deployment-with-deploysh)
- [Uninstall with uninstall.sh](#uninstall-with-uninstallsh)
- [Helm Commands Of Interest](#helm-commands-of-interest)
- [Troubleshooting](#troubleshooting)
- [References](#references)
  - [Jenkins Configuration as Code](#jenkins-configuration-as-code)
  - [Visual Studio Extensions for Jenkins](#visual-studio-extensions-for-jenkins)
  - [Codecentric Jenkins Helm Chart](#codecentric-jenkins-helm-chart)
  - [Digital Ocean Kubernetes](#digital-ocean-kubernetes)
  - [Declarative Pipelines DSL in Jenkins](#declarative-pipelines-dsl-in-jenkins)
  - [Job DSL](#job-dsl)
    - [Jenkins Seed Job](#jenkins-seed-job)
  - [Jenkins Kubernetes Continuous Deploy Plugin](#jenkins-kubernetes-continuous-deploy-plugin)
  - [SpringBoot Docker](#springboot-docker)
  - [Maven](#maven)
  - [Petclinic](#petclinic)
    - [Petlinic kubernetes](#petlinic-kubernetes)
    - [Petclinic on GKE](#petclinic-on-gke)

## Introduction
- This is a Proof of Concept of [Codecentric/Jenkins Helm Chart](https://hub.helm.sh/charts/codecentric/jenkins) with [Helm 3](https://helm.sh/), [Jenkins Configuration as Code](https://github.com/jenkinsci/configuration-as-code-plugin) and [Digital Ocean Kubernetes](https://www.digitalocean.com/products/kubernetes/).
- This solution is not based on Kubernetes Operators.
- A sample of Software Delivery Pipeline is included with [Spring Petclinic Demo](https://spring-petclinic.github.io/) and [Jenkins Pipeline](https://www.jenkins.io/doc/book/pipeline/).
- This is 100% automated Jenkins on Kubernetes demo with PetClinic Build & Deploy (monolithic).

## Disclaimer
- These sample configuration files may not be optimized for your environment and can be significantly improved. 

## Requirements
- A registered domain name publicly reachable from Internet. I have a registered domain for testing purposes.
- A Digital Ocean Kubernetes Cluster (kubernetes 1.16.8+) with 1 worker node with 2 VCPU and 4GB RAM. 
- A GitHub private repository *with the content of this repo*, containing sensitive data like usernames and passwords.
- A DockerHub private repository. 
- Helm 3 instead of helm 2. Simpler and with improved security (tiller is not required). 
- Apply the following Helm 3 Charts on DO Kubernetes (more details below): 
  - [External-dns Helm Chart](https://github.com/helm/charts/tree/master/stable/external-dns)
  - [Nginx Ingress Controller](https://hub.helm.sh/charts/stable/nginx-ingress) 

## Tips for validating JCasC YAML 
- Set up jenkins via User Interface and export the running configuration to a YAML file. This feature is provided by [Jenkins Configuration as Code Plugin](https://github.com/jenkinsci/configuration-as-code-plugin). This YAML file cannot be imported afterwards, but it will help you to figure out what configuration lines should be added to JCasC YAML.
- Use [Visual Studio Jenkins JCasC-Plugin](https://marketplace.visualstudio.com/items?itemName=jcasc-developers.jcasc-plugin) This extension is used to integrate a live jenkins instance configuration with your editor. It can be used to edit and validate YAML files.

## Tips for adding jenkins jobs to JCasC. Use a Seed Job
- Use 1 file per jenkins job that needs to be configured as source code. Management of pipelines by adding files instead of having 1 single file with all the configurations. Otherwise a single error would break all the pipelines and troubleshooting would be harder.
- Use a Jenkins Seed Job that loads all the Jenkins Jobs (1 file per jenkins job):
  - This seed job is usually written with JobDSL and can be set up in JCasC YAML or be imported manually as jenkins freestyle job. 
  - Use regular expressions in the seed job to select and filter out all the **Jenkinsfiles and/or JobDSL files** that describe your jenkins jobs (pipelines).

## Screenshots
- [Screenshots here](screenshots.md)

## Environment
This proof of concept was run with with the following releases:  
  - codecentric/jenkins Helm Chart version 1.6.0
  - helm 3.0.2
  - [jenkins/jenkins:2.222.3-alpine](https://hub.docker.com/layers/jenkins/jenkins/2.222.3-alpine/images/sha256-ecdbb03032fc1d473ef9a5b41c94057f129206e3e29ee6cdf48bad8368248bec?context=explore) docker Image
  - [sprint-petclinic commit 6a18eec (May 2020)](https://github.com/spring-projects/spring-petclinic/commit/adab01ef624418db4a9677c5c641a039d39b7a18)
  - Digital Ocean Kubernetes 1.16.8
  - [stable/external-dns 2.13.0](https://hub.helm.sh/charts/stable/external-dns) helm chart (currently deprecated). Use [bitnami/external-dns](https://hub.helm.sh/charts/bitnami/external-dns) instead 

## YAML Settings
1. Please do a quick search of **<my_** string to identify the settings that need to be updated accordingly in your specific environment:

```bash
$ grep -ri \<my_ ./*.yaml
./deployment.yaml:        image: <my_dockerhub_username>/spring-petclinic:latest
./externaldns-values.yaml:  apiToken: <my_digitalocean_api_token>
./externaldns-values.yaml:domainFilters: [ '<my_public_dns_domain.com>' ]
./ingress.yaml:  - host: petclinic.<my_public_dns_domain.com>
./jenkins-values.yaml:    - jenkins.<my_public_dns_domain.com>
./jenkins-values.yaml:    ADMIN_USER: <my_jenkins_admin_username>
./jenkins-values.yaml:    ADMIN_PASSWORD: <my_jenkins_admin_password>
./jenkins-values.yaml:      username: <my_dockerhub_username>
./jenkins-values.yaml:      password: <my_dockerhub_password>
./jenkins-values.yaml:                    id: "github_<my_github_username>"
./jenkins-values.yaml:                    passphrase: "<my_github_password>"
./jenkins-values.yaml:                          <my_private_key> 
./jenkins-values.yaml:                    username: "<my_github_username>"
./jenkins-values.yaml:                              certificate-authority-data: <my_k8s_certificate-authority-data>
./jenkins-values.yaml:                              server: https://<my_k8s_server_id_in_kube_config>.k8s.ondigitalocean.com
./jenkins-values.yaml:                            name: <my_k8s_name_in_kube_config>    
./jenkins-values.yaml:                              cluster: <my_k8s_name_in_kube_config>
./jenkins-values.yaml:                              user: <my_k8s_name_in_kube_config>-admin
./jenkins-values.yaml:                            name: <my_k8s_name_in_kube_config>
./jenkins-values.yaml:                          current-context: <my_k8s_name_in_kube_config>
./jenkins-values.yaml:                          - name: <my_k8s_user_name_in_kube_config>-admin
./jenkins-values.yaml:                              token: <my_k8s_user_token_in_kube_config>
./jenkins-values.yaml:              url: "https://jenkins.<my_public_dns_domain.com>"
./jenkins-values.yaml:                            url 'git@github.com:<my_github_username>/helm-charts-do.git' 
./jenkins-values.yaml:                            credentials 'github_<my_github_username>'
./jenkins-values.yaml:                            url 'git@github.com:<my_github_username>/helm-charts-do.git' 
./jenkins-values.yaml:                            credentials 'github_<my_github_username>'
```

2. Replace each setting with your own parameter. For example:
  - Replace **<my_public_dns_domain.com>** with **domain-example.com** . I set up a registered domain name that I have for testing purposes.
  - Replace <my_jenkins_admin_password> with **your_own_jenkins_admin_password** 
  - <my_digitalocean_api_token> : Digital Ocean API Token
  - Fill in some of the required parameters from your DO kubernetes settings available in *$HOME/.kube/config*.
  - etc

### Settings to be updated on each DO Kubernetes Cluster
- Each new DO Kubernetes cluster (and recreation) requires to update jenkins-values.yaml in order to authenticate against each specific cluster.
- These are the three parameters to update in "kubeconfig: id: digitalocean" section within jenkins/values.yaml:
  1. certificate-authority-data: <my_k8s_certificate-authority-data>
  2. server: https://<my_k8s_server_id_in_kube_config>.k8s.ondigitalocean.com
  3. token: <my_k8s_user_token_in_kube_config>

### Settings to be updated on Petclinic Software Delivery Demo Pipeline
- Remember to check and maintain the following environment var in petclinic.Jenkinsfile to match the SpringBoot release specified in petclinic's parent POM file ([Upgrade to Spring Boot 2.3.0.RC1](https://github.com/spring-projects/spring-petclinic/commit/d9f37ece5c865ded91b6582828142ccc33e9d54f)). 
- For example:
  - spring_boot_release = '2.3.0.BUILD-SNAPSHOT'


## Setting up Nginx Ingress Controller
- Several options: with helm and without helm (see below refs).
- With Helm 3:

```bash
$ helm install nginx-ingress stable/nginx-ingress --set controller.publishService.enabled=true
NAME: nginx-ingress
LAST DEPLOYED: Wed Jan  1 18:34:02 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The nginx-ingress controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace default get services -o wide -w nginx-ingress-controller'

An example Ingress that makes use of the controller:

  apiVersion: extensions/v1beta1
  kind: Ingress
  metadata:
    annotations:
      kubernetes.io/ingress.class: nginx
    name: example
    namespace: foo
  spec:
    rules:
      - host: www.example.com
        http:
          paths:
            - backend:
                serviceName: exampleService
                servicePort: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
        - hosts:
            - www.example.com
          secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
```

## Setting up External Dns (included in deploy.sh)
- Kubernetes' external-dns plugin is required. 
- This step is already included in **deploy.sh** script.
- Updating your hosts file (windows, WSL or similar) should not be required.
- Be aware the exposed IP address changes each time DO Kubernetes is recreated.


```bash
~/helm$ helm search repo external-dns
NAME                    CHART VERSION   APP VERSION     DESCRIPTION                                       
stable/external-dns     2.13.0          0.5.17          ExternalDNS is a Kubernetes addon that configur...
```

- [stable/external-dns 2.13.0](https://hub.helm.sh/charts/stable/external-dns) helm chart is currently deprecated. Use [bitnami/external-dns](https://hub.helm.sh/charts/bitnami/external-dns) instead 


```bash
~/helm$ helm install external-dns stable/external-dns -f externaldns-values.yaml
NAME: external-dns
LAST DEPLOYED: Fri Dec 14 10:28:35 2019
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **

To verify that external-dns has started, run:

kubectl --namespace=default get pods -l "app.kubernetes.io/name=external-dns,app.kubernetes.io/instance=external-dns"
```

## Deployment with deploy.sh
Run **./deploy.sh** script.

## Uninstall with uninstall.sh
Run **./uninstall.sh** script.

## Helm Commands Of Interest

```bash
helm pull codecentric/jenkins --version 1.6.0
helm pull codecentric/jenkins --verify --version 1.6.0
```

## Troubleshooting 

```bash
kubectl logs -f jenkins-656b5fccc7-pv6f8 | egrep -i '(error|failure|exception|volume|claim|warning)' --color
```

## References
- [Configure a CI/CD pipeline with Jenkins on Kubernetes](https://developer.ibm.com/tutorials/configure-a-cicd-pipeline-with-jenkins-on-kubernetes/)
- [Kubernetes plugin for Jenkins](https://github.com/jenkinsci/kubernetes-plugin)
- [Kubernetes plugin Pipeline examples](https://github.com/jenkinsci/kubernetes-plugin/tree/master/examples)
- [kubernetes-credentials-provider-plugin](https://jenkinsci.github.io/kubernetes-credentials-provider-plugin/examples/)

### Jenkins Configuration as Code
- [Jenkins Configuration as Code - first encounter!](https://automatingguy.com/2018/09/25/jenkins-configuration-as-code/)

### Visual Studio Extensions for Jenkins
- [Jenkins JCasC-Plugin](https://marketplace.visualstudio.com/items?itemName=jcasc-developers.jcasc-plugin) This extension is used to integrate a live jenkins instance configuration with your editor. It can be used to edit and validate YAML files.
- [Jenkins Pipeline Linter Connector](https://marketplace.visualstudio.com/items?itemName=janjoerke.jenkins-pipeline-linter-connector) Validates Jenkinsfiles by sending them to the Pipeline Linter of a Jenkins server.
- [secanis.ch: Jenkinsfile Support](https://marketplace.visualstudio.com/items?itemName=secanis.jenkinsfile-support) Adds syntax highlighting support for Jenkinsfile's. In this version, it's the same like Groovy is.
- [ivory-lab: JenkinsFile Support](https://marketplace.visualstudio.com/items?itemName=ivory-lab.jenkinsfile-support) Extension provides basic jenkinsfile support (highlighting, snippets and completion)
- [JM Meessen: Declarative Jenkinsfile Support](https://marketplace.visualstudio.com/items?itemName=jmMeessen.jenkins-declarative-support) Adds syntax highlighting support for the declarative Jenkinsfile format flavour.
- [Alessandro Fragnani: Jenkins Status](https://marketplace.visualstudio.com/items?itemName=alefragnani.jenkins-status)

### Codecentric Jenkins Helm Chart
- [Codecentric Jenkins Helm Chart 🌟](https://hub.helm.sh/charts/codecentric/jenkins) 
- [GitHub: Codecentric Jenkins Helm Chart 🌟](https://github.com/codecentric/jenkins-scripts) 

### Digital Ocean Kubernetes
- [Setting up Ingress without Helm](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes)
- [Setting up Ingress with Helm](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-on-digitalocean-kubernetes-using-helm)

### Declarative Pipelines DSL in Jenkins
- [Tips for declarative pipelines in Jenkins](http://adar.me/blog/2017/04/09/declarative-pipelines-in-jenkins/)
- [Where to put the wrapper for ansiColor Jenkins plugin in Jenkins Pipeline?](https://stackoverflow.com/questions/44003484/where-to-put-the-wrapper-for-ansicolor-jenkins-plugin-in-jenkins-pipeline)
- [Jenkins pipeline ansicolor console output](https://stackoverflow.com/questions/53198890/jenkins-pipeline-ansicolor-console-output)
- [Jenkins Pipeline Examples](https://jenkins.io/doc/pipeline/examples/)

### Job DSL
- [stackoverflow: Job DSL to create “Pipeline” type job](https://stackoverflow.com/questions/35898020/job-dsl-to-create-pipeline-type-job)

#### Jenkins Seed Job
- [How to Seed Jenkins Build Jobs](https://www.serverlab.ca/tutorials/dev-ops/automation/how-to-seed-jenkins-build-jobs/)
- [Tutorial Using the Jenkins Job DSL. Creating the Seed Job](https://github.com/jenkinsci/job-dsl-plugin/wiki/Tutorial---Using-the-Jenkins-Job-DSL)
- [What are seed jobs in Jenkins and how does it work?](https://stackoverflow.com/questions/37717728/what-are-seed-jobs-in-jenkins-and-how-does-it-work)
- [Jenkins Tutorial: Implementing a Seed Job](https://www.happycoders.eu/devops/jenkins-tutorial-implementing-seed-job/)
- [Setting up a shared library and seed job in Jenkins - Part 1](https://blog.ippon.tech/setting-up-a-shared-library-and-seed-job-in-jenkins-part-1/)
- [Jenkins Jobs as Code with Groovy DSL](https://tech.gogoair.com/jenkins-jobs-as-code-with-groovy-dsl-c8143837593a)

### Jenkins Kubernetes Continuous Deploy Plugin
- [Jenkins Kubernetes Continuous Deploy Plugin 🌟](https://jenkins.io/doc/pipeline/steps/kubernetes-cd/) 

### SpringBoot Docker
- [Sample for a Spring Boot app Dockerfile ](https://github.com/ajavageek/springboot-docker) 
  - [A Dockerfile for Maven-based Github projects](https://blog.frankel.ch/dockerfile-maven-based-github-projects/)

### Maven
- [Maven Wrapper](https://github.com/takari/maven-wrapper) The easiest way to integrate Maven into your project!
- [Maven Plugins](http://maven.apache.org/plugins/)
- [simple-java-maven-app](https://github.com/jenkins-docs/simple-java-maven-app) For an introductory tutorial on how to use Jenkins to build a simple Java application with Maven.
    - [Build a Java app with Maven 🌟](https://jenkins.io/doc/tutorials/build-a-java-app-with-maven/) ***
    - [Youtube: CloudBees - Declarative Pipelines with Jenkins](https://www.youtube.com/watch?v=79HfmjeOTEI) 

### Petclinic
- [spring-petclinic.github.io](https://spring-petclinic.github.io/)
- [A Dockerfile for Maven-based Github projects 🌟](https://blog.frankel.ch/dockerfile-maven-based-github-projects/) 
- [Building Spring Docker Images 🌟](https://tech.paulcz.net/blog/building-spring-docker-images/) 
- [A Dockerfile for Maven-Based GitHub Projects 🌟🌟🌟](https://dzone.com/articles/a-dockerfile-for-maven-based-github-projects)  
- [Jenkins CI reference pipeline for Java Spring Boot projects with Maven lifecycle and Docker packaging](https://deors.wordpress.com/2019/04/25/jenkins-ci-pipeline-java-spring-boot-maven-docker/)
    - [github.com/deors/deors-demos-petclinic 🌟](https://github.com/deors/deors-demos-petclinic) 

#### Petlinic kubernetes
- [github.com/spring-petclinic/spring-petclinic-kubernetes 🌟](https://github.com/spring-petclinic/spring-petclinic-kubernetes) 
- [github.com/spring-petclinic/spring-petclinic-microservices 🌟](https://github.com/spring-petclinic/spring-petclinic-microservices) 

#### Petclinic on GKE
- [Google Cloud Native Spring Boot PetClinic](https://github.com/saturnism/spring-petclinic-gcp) 
