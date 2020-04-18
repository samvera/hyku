Helm Chart
==========

This is a Hyku Helm Chart which can be used to deploy a Hyku instance to a Kubernetes cluster.

# Requirements

* helm
```
brew install helm
```

* kubernetes
Kubectl is the command line tool for controlling Kubernetes clusters. It is available via (https://docs.docker.com/docker-for-mac/)[Docker for Mac]

Alternatively:
```
brew install kubectl
```

# Getting Started Locally using Docker for Mac

## Setup

Install Docker for Mac (DfM)

Enable the Kubernetes Cluster in the DfM Settings

In the menu bar item for DfM you'll 'Kubernetes', this will list the available clusters. For local deployment make sure docker-desktop is selected.

## KubeConfig

Kubernetetes creates a config file at `~/.kube/config`. When we come to setting up access to external clusters, we will be editing this file. That will add clusters to the DfM Kubernetes list. Remember that if you are running deployment actions using helm or kubectl they will use the cluster selected in that list, so if you were deploying to a production server yesterday, that will still be selected. It is a good practice to run `kubectl cluster-info` or `kubectl config current-context` before starting any deployment to make sure you are deploying to the right cluster.

## GitLab Secret

To pull images from a private registry, you'll need a secret 

For GitLab, create a Personal Access Token in GitLab with read access.

Create your secret (called gitlab) in kubectl, substituting the items in {} with your data:
```
create secret docker-registry gitlab --docker-server=https://registry.gitlab.com --docker-username={YOUR USERNAME} --docker-password={PERSONAL ACCESS TOKEN} --docker-email={YOUR EMAIL} --namespace {NAMESPACE eg. hyku}
```

Reference the secret in `imagePullSecrets`, see the sample.yamnl file for an example.

For other private registries, please consult their documentation on access tokens.

## TLS Secret

We also need to setup a secret for TLS certificates.

```
# this command will generate self signed server certificate and key: server.pem, server.key
# key and cert are stored in Secret object named `demoapp-puma-tls`.
# you can confirm this object by `kubectl describe secret demoapp-puma-tls`
export COMMON_NAME=localhost
openssl req -new -x509 -nodes -keyout server.key -days 3650 \
  -subj "/CN=${COMMON_NAME}" \
  -extensions v3_req \
  -config <(cat openssl.conf | sed s/\${COMMON_NAME}/$COMMON_NAME/) > server.pem
```

NOTE: you may need change openssl.conf to point to your local path, eg. /System/Library/OpenSSL/openssl.cnf

```
kubectl create secret tls demoapp-puma-tls --key server.key --cert server.pem
```

## Add Helm Chart Repository

We are going to need to install a couple of things on our local cluster. For this we need to install charts from the Helm stable chart repository.

One off installation of the repository:
```
helm repo add stable https://kubernetes-charts.storage.googleapis.com
```

## Install NFS

To run locally and use NFS file mounts we'll need an NFS server:

Helm install to run the nfs server on kubernetes:
```
helm install stable/nfs-server-provisioner --generate-name
```

NOTE: you can substitute --generate-name with --name followed by your chosen name for the resource

NOTE: stop / remove it with helm uninstall {name} --namespace default

### Ingress

To run locally we'll need an Ingress controller - this provides us with the ability to access the application on the web:

Helm install to run the ingress controller on kubernetes:
```
helm install stable/nginx-ingress --generate-name
```

NOTE: you can substitute --generate-name with --name followed by your chosen name for the resource

NOTE: stop / remove it with helm uninstall {name} --namespace default

## Values

When deploying the Helm chart we will provide a yaml file containing various configurations choices.

To use the `./bin/deploy` script, follow the convention of naming the values file  ENVIRONMENT-values.yaml, eg. development-values.yaml

Values files are included in `.gitignore` and MUST NOT be added to the repository. To store values in the repository, encrypt the file, eg. with keybase as ENVIRONMENT.yaml.enc eg. staging.yaml.enc.

A sample values file is provided to give defaults: `sample.yaml`. Copy this file (eg. to development-values.yamnl) and change values as appropriate.

## Deploy using Helm

From ./chart/

```
./bin/deploy development latest
```

Open demoapp in browser
```
open locaallhost
```

## Cleanup
helm uninstall development --namespace REPO_NAME

eg. `helm uninstall development --namespace hyku`

Tip: add the --dry-run to see what will be deleted

## Kubernetes Dashboard

Kubernetes provides a web-based dashboard for viewing and managing the deployed resources.

# Install it:
```
helm install stable/kubernetes-dashboard --generate-name
```

Make a note of the start command printed on install. It includes the release name (eg. kubernetes-dashboard-1579333192).

Tip: You can replace --generate-name with --name and supply a name for the release to give you a stable name. 

Start it:
```
(RELEASE_NAME will be the value from your installation - find it with helm ls)

export POD_NAME=$(kubectl get pods -n default -l "app=kubernetes-dashboard,release=RELEASE_NAME" -o jsonpath="{.items[0].metadata.name}")
echo https://127.0.0.1:8443/
kubectl -n default port-forward $POD_NAME 8443:8443
```

Open it:
```
https://127.0.0.1:8443/
```

It will ask you to login by one of two methods. Opt for 'access token'.

Print your access token in a console as follwos, and then copy paste it into the token box on the dashboard login:
```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | awk '/^deployment-controller-token-/{print $1}') | awk '$1=="token:"{print $2}'
```

# Deploying to Staging and Production clusters

Staging and Production deployment require the following steps:

1. Add the necessary kube config for your remote cluster

2. Switch kubernetes context

Either using the list in DfM Kubernetes, or with the following:

```
# check the current context
kubectl config current-context
# find the context you want in the list
kubectl config get-contexts
# switch
kubectl config use-context CONTEXT_NAME
```

3. Setup the *-values.yaml for staging or production

4. Deploy

```
# bin/deploy ENVIRONMENT TAG
bin/deploy staging latest
```

NOTE: the TAG will be used to pull the latest image from the GitLab repository. If the code has changed, make sure it's been pushed and the tagged image in the repository updated.

The namespace will be set to the git repository name, eg. hyku. Make sure the namespace exists in your cluster. Create it with `kubectl create namespace hyku`

# Troubleshooting

The Kubernetes Dashboard (locally) allows you to view logs and access a shell session. If problems occur during deployment, there is an event history that can provide more information. 

There are equivalent kubectl commands for logs and accessing a shell, eg.

```
kubectl kubectl exec -it POD --namespace NAMESPACE -- /bin/bash
kubectl kubectl logs POD --namespace NAMESPACE
```
