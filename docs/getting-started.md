# Getting Started

- [Docker (Recommended)](#docker)
- [Locally without Docker](#locally-without-docker)
- [Vagrant](#vagrant)
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

    Hyku makes heavy use of domain names to determine which tenant to serve. On MacOS/Linux, it is recommended to use [Dory](https://github.com/FreedomBen/dory) to handle the necessary DNS changes.

    #### Dory Installation

    ```bash
    gem install dory
    dory up
    ```

    #### Running Without Dory

    By copying `docker-compose.override-nodory.yml` to `docker-compose.override.yml`, you can run Hyku without Dory, but you will have to set up your own DNS entries.
    ```bash
    cp docker-compose.override-nodory.yml docker-compose.override.yml
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

It will take some time for the application to start up, and a bit longer if it's the first startup. When you see `Passenger core running in multi-application mode.` or `Listening on tcp://0.0.0.0:3000` in the logs, the application is ready.

If you used Dory, the application will be available from the browser at `http://hyku.test`.

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
DISABLE_REDIS_CLUSTER=true bundle exec sidekiq
DISABLE_REDIS_CLUSTER=true bundle exec rails server -b 0.0.0.0
```


## Vagrant

The [samvera-vagrant project](https://github.com/samvera-labs/samvera-vagrant) provides another simple way to get started "kicking the tires" of Hyku (and [Hyrax](http://hyr.ax/)), making it easy and quick to spin up Hyku. (Note that this is not for production or production-like installations.) It requires [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/).

## Kubernetes

Hyku relies on the helm charts provided by Hyrax. See [Deployment Info](https://github.com/samvera/hyrax/blob/main/CONTAINERS.md#deploying-to-production) for more information. We also provide a basic helm [deployment script](/bin/helm_deploy). Hyku currently needs some additional volumes and ENV vars over the base Hyrax. See (ops/review-deploy.tmpl.yaml) for an example of what that might look like.

## AWS

AWS CloudFormation templates for the Hyku stack are available in a separate repository:

https://github.com/hybox/aws

# Troubleshooting

## Troubleshooting on Windows
1. Dory is running but you're unable to access hyku.test:
    - Run this in the terminal: `ip addr | grep eth0 | grep inet`
    - Copy the first IP address from the result in your terminal
    - Use the steps under "Change the File Manually" at [this link](https://www.hostinger.co.uk/tutorials/how-to-edit-hosts-file#:~:text=Change%20the%20File%20Manually,-Press%20Start%20and&text=Once%20in%20Notepad%2C%20go%20to,space%2C%20then%20your%20domain%20name) to open your host file
    - At the bottom of the host file add this line: `<your-ip-address> hyku.test`
    - Save (_You may or may not need to restart your server_)
2. When creating a work and adding a file, you get an internal server error due to ownership/permissions issues of the tmp directory:
    - Gain root access to the container (in a slightly hacky way, check_volumes container runs from root): `docker compose run check_volumes bash`
    - Change ownership to app: `chown -R app:app /app/samvera/hyrax-webapp`