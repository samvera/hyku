# Getting Started

- [Docker (Recommended)](#docker)
- [Locally without Docker](#locally-without-docker)
- [Kubernetes](#kubernetes)
- [AWS](#aws)

## Docker

We distribute two `docker-compose.yml` configuration files.  The first is set up for development / running the specs. The other, `docker-compose.production.yml` is for running the Hyku stack in a production setting.

*Note: You may need to add your user to the "docker" group:*

```bash
sudo gpasswd -a $USER docker
newgrp docker
```

### Installation

1) **Clone the repository and checkout the last release:**

    ```bash
    git clone https://github.com/samvera/hyku.git
    cd hyku
    git checkout tags/v5.2.0
    ```

2) **Set up DNS:**

    Hyku makes heavy use of domain names to determine which tenant to serve. On MacOS/Linux, it is recommended to use [Stack Car](https://github.com/notch8/stack_car) to handle the necessary SSL certs and proxy setup.

    #### Stack Car Installation

    ```bash
    gem install stack_car
    sc proxy cert # Only need this once per stack_car version
    sc proxy up
    ```

    #### Running Without Proxy

    By copying `docker-compose.override-noproxy.yml` to `docker-compose.override.yml`, you can run Hyku without Dory, but you will have to set up your own DNS entries.
    ```bash
    cp docker-compose.override-noproxy.yml docker-compose.override.yml
    ```

3) **Build the Docker images:**

    ```bash
    docker compose build
    ```
### Configuration

Hyku configuration is primarily found in the `.env` file, which will get you running out of the box. To customize your configuration, see the [Configuration Guide](./configuration.md).

### Running the Application

#### Starting

```bash
docker compose up web
```

It will take some time for the application to start up, and a bit longer if it's the first startup. When you see `Listening on tcp://0.0.0.0:3000` in the logs, the application is ready.

If you used `sc proxy`, the application will be available from the browser at `https://admin-${APP_NAME}.localhost.direct`. APP_NAME defaults to `hyku`. You can also see the other services as listed in the docker-compose.yml file.

**You are now ready to start using Hyku! Please refer to  [Using Hyku](./using-hyku.md) for instructions on getting your first tenant set up.**

#### Stopping

```bash
docker compose down
```

### Testing

The full spec suite can be run in docker locally. There are several ways to do this, but one way is to run the following:

```bash
docker compose exec web rake
```

## Locally without Docker

Please note that this is unused by most contributors at this point and will likely become unsupported in a future release of Hyku unless someone in the community steps up to maintain it.

### Compatibility

* Ruby 2.7 is recommended.  Later versions may also work.
* Rails 5.2 is required.

```bash
solr_wrapper
fcrepo_wrapper
postgres -D ./db/postgres
redis-server /usr/local/etc/redis.conf
bin/setup
DISABLE_REDIS_CLUSTER=true ./bin/worker
DISABLE_REDIS_CLUSTER=true ./bin/web
```


## Kubernetes

Hyku relies on the helm charts provided by Hyrax. See [Deployment Info](https://github.com/samvera/hyrax/blob/main/CONTAINERS.md#deploying-to-production) for more information. We also provide a basic helm [deployment script](/bin/helm_deploy). Hyku currently needs some additional volumes and ENV vars over the base Hyrax. See (ops/review-deploy.tmpl.yaml) for an example of what that might look like.

## AWS

AWS CloudFormation templates for the Hyku stack are available in a separate repository:

https://github.com/hybox/aws

# Troubleshooting

## Troubleshooting on Windows
1. When creating a work and adding a file, you get an internal server error due to ownership/permissions issues of the tmp directory:
    - Gain root access to the container (in a slightly hacky way, check_volumes container runs from root): `docker compose run check_volumes bash`
    - Change ownership to app: `chown -R app:app /app/samvera/hyrax-webapp`
