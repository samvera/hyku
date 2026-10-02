# Local Kubernetes Deployment

This guide deploys Antleaf Hyku to the Kubernetes cluster bundled with Docker
Desktop on macOS.

## Prerequisites
Make sure `kubectl` is targeting Docker Desktop rather than the prod cluster.

```bash
kubectl config use-context docker-desktop
kubectl config current-context
kubectl --context docker-desktop cluster-info
```

`kubectl config current-context` must print `docker-desktop`. Do not continue if
it names  the prod cluster.

Set `ANTLEAF_HYKU_DB_PASSWORD` and `ANTLEAF_HYKU_ADMIN_PASSWORD` to local
passwords. 

## Install the PostgreSQL operator

Install CloudNativePG once per Docker Desktop cluster, using the same operator
chart as the infrastructure repository:

```bash
helm repo add cnpg https://cloudnative-pg.github.io/charts --force-update
helm repo update cnpg
helm --kube-context docker-desktop upgrade --install cnpg cnpg/cloudnative-pg \
  --version 0.29.1 \
  --namespace cnpg-system \
  --create-namespace \
  --timeout 10m \
  --wait
```

## Create the standalone database

Set `ANTLEAF_HYKU_DB_PASSWORD` to a local password. Use the same value for the
database Secret and the Hyku Helm release. CloudNativePG requires a
`kubernetes.io/basic-auth` Secret with `username` and `password` keys in the
same namespace as its Cluster:

```bash
kubectl --context docker-desktop create namespace postgres
kubectl --context docker-desktop create secret generic hyku-db-credentials \
  --namespace postgres \
  --type kubernetes.io/basic-auth \
  --from-literal=username=hyrax \
  --from-literal="password=${ANTLEAF_HYKU_DB_PASSWORD}"
kubectl --context docker-desktop apply -f ops/postgres-local.yaml
kubectl --context docker-desktop --namespace postgres wait \
  --for=condition=Ready cluster/ppostgres-antleaf --timeout=10m
kubectl --context docker-desktop --namespace postgres get cluster,pods,services
```

The database endpoint is
`ppostgres-antleaf-rw.postgres.svc.cluster.local:5432`. On first bootstrap,
CloudNativePG creates the `hyrax` database and application role, grants the role
`CREATEDB` for Hyku's setup and tenant databases, then installs the PostgreSQL
extensions Hyku requires. The database is stored on its own
2 Gi persistent volume and remains available when the Hyku Helm release is
upgraded or removed.

## Create the Hyku namespace and secret

Set `ANTLEAF_HYKU_ADMIN_PASSWORD` to a local admin password, then create the
application namespace and Secret:

```bash
kubectl --context docker-desktop create namespace hyku
kubectl --context docker-desktop create secret generic hyku-secrets \
  --namespace=hyku \
  --from-literal="INITIAL_ADMIN_PASSWORD=${ANTLEAF_HYKU_ADMIN_PASSWORD}" \
  --from-literal="DB_PASSWORD=${ANTLEAF_HYKU_DB_PASSWORD}"
```

## Deploy

Hyku reads its database password from `hyku-secrets` at runtime. The same
value is supplied to Helm so the chart can generate Hyku's `DATABASE_URL`:

```bash
helm --kube-context docker-desktop upgrade --install hyku ./hyrax \
  --namespace hyku \
  --values ops/deploy-local.yaml \
  --set-string externalPostgresql.password="${ANTLEAF_HYKU_DB_PASSWORD}" \
  --timeout 20m \
  --wait
```

Watch the initial startup with:

```bash
kubectl --context docker-desktop --namespace hyku get pods --watch
```

## Access Hyku

Expose the ClusterIP service from another terminal:

```bash
kubectl --context docker-desktop --namespace hyku port-forward service/hyku-hyrax 3000:80
```

Then open:

```text
http://antleaf-hyku.localhost.direct:3000
```

## Local configuration details

The local values use the standalone CloudNativePG database plus bundled Redis,
Solr, and ZooKeeper with Docker Desktop's `standard` storage class. They do not
use production NFS, ingress, TLS, SMTP, or public hostnames. Background jobs run inline,
so the application volumes use `ReadWriteOnce` claims without a separate worker
pod. A local-only Rails initializer disables production's forced HTTPS redirect
because the application is exposed through a plain HTTP port-forward.
The local `SOLR_URL` points to `/solr/`; Hyku appends each account's collection
name when creating and indexing a tenant.

On a fresh PostgreSQL volume, CloudNativePG's bootstrap creates the
`shared_extensions` schema and the `hstore`, `uuid-ossp`, `pgcrypto`, and
`pg_trgm` extensions before Hyku runs its database setup. The `hyrax`
application user remains non-superuser. Bootstrap SQL only runs when a new
database volume is initialized.

## Remove the Hyku application

Remove the Helm release while retaining its persistent volumes:

```bash
helm --kube-context docker-desktop --namespace hyku uninstall hyku
```

Deleting the `hyku` namespace also removes the application's local persistent
volumes. The standalone PostgreSQL cluster lives in the separate `postgres`
namespace and is unaffected:

```bash
kubectl --context docker-desktop delete namespace hyku
```

## Remove the complete local deployment

To start again with empty databases and volumes, remove Hyku first, then the
PostgreSQL namespace while its operator is still running, and finally the
operator. This permanently deletes the local Hyku and PostgreSQL data:

```bash
helm --kube-context docker-desktop --namespace hyku uninstall hyku
kubectl --context docker-desktop delete namespace hyku --wait=true
kubectl --context docker-desktop delete namespace postgres --wait=true
helm --kube-context docker-desktop --namespace cnpg-system uninstall cnpg
kubectl --context docker-desktop delete namespace cnpg-system --wait=true
```

Afterward, follow this guide from **Install the PostgreSQL operator** to build
a fresh local deployment. Helm retains CloudNativePG's cluster-wide CRD
definitions when the operator is uninstalled; they contain no running database
or local application data after the namespaces above are removed.
