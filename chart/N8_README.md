N8 Helm Deployment
==================

# Using NOOP with Helm

Use the `--dry-run` and `--verbose` flags to see what Helm is going to do, without creating or deleting any resources.

eg.

`helm upgrade --install --dry-run --verbose --namespace staging-palni-palci . -f staging-values.yaml --set rails.image.tag=latest`

# Deploying to Staging and Production clusters

N8 Rancher: (https://r.notch8.cloud)[https://r.notch8.cloud]

Staging and Production deployment require the following steps:

1. Add the necessary kube config

For Rancher, the Kubeconfig can be accessed in the cluster. This will need to be copied to your local ~/.kube/config file.

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

3. Decrypt the encrypted values file

There is a utility script for decrypting. You will need to have keybase installed and configured.

```
# bin/decrypt ENVIRONMENT
bin/decrypt staging
```

NOTE: There is a similar script for encrypting updated values to replace the *.yaml.enc file. For this you will need to have been added to the keybase team.

```
# bin/encrypt ENVIRONMENT TEAM
bin/encrypt staging hyku
```

4. Ensure the Namespace exists in Rancher

The namespace convention is ENVIRONMENT-GHREPONAME, eg. (staging-palni-palci)

5. Deploy

```
# bin/deploy ENVIRONMENT TAG
bin/deploy staging latest
```

NOTE: the TAG will be used to pull the latest image from the GitLab repository. If the code has changed, make sure it's been pushed and CI has updated the tagged image in the repository.

# Deploying with GitLab CI

Helm deployment can be added as part of the GitLab CI process (see `.gitlab-ci.yml`).

GitLab requires the following ENV VARS to have been set:

* KUBE_CONFIG
* STAGING_VALUES (for staging deploys)
* PRODUCTION_VALUES (for production deploys)

# Troubleshooting

The Rancher interface both allows you to view logs and access a shell session. If problems occur during deployment, there is an event history that can provide more information. 

There are equivalent kubectl commands for logs and accessing a shell, eg.

```
kubectl kubectl exec -it POD --namespace NAMESPACE -- /bin/bash
kubectl kubectl logs POD --namespace NAMESPACE
```