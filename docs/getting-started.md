# Getting Started

- [Docker Development Environment (Start Here)](#docker-development-environment)
- [Kubernetes](#kubernetes)
- [AWS](#aws)
- [Troubleshooting](#troubleshooting)

## Docker Development Environment
Start off by setting up a local development environment where you can experiment with Hyku features and capabilities. This will help familiarize you with terminology and configuration, even if you plan on installing Hyku in your own cloud or data center later.

### Installation

1) **Clone the repository and checkout the latest release:**

    ```bash
    git clone https://github.com/samvera/hyku.git
    cd hyku
    git checkout tags/v6.2.0
    ```

2) **Set up DNS and TLS certificates using Stack Car:**

    Hyku makes heavy use of domain names to determine which tenant(s) to serve. On MacOS/Linux, 
    we recommended using [Stack Car](https://github.com/notch8/stack_car) to handle the necessary proxy setup including
    SSL certstificates.<br/><br/>

    During the certificate installation, you will be prompted for two passwords.
    The first is to unzip the wildcard certificate, you can find that password
    [here](https://github.com/Upinel/localhost.direct?tab=readme-ov-file#a-non-public-ca-certificate-if-you-have-admin-right-on-your-development-environment-you-can-use-the-following-10-years-long-pre-generated-self-signed-certificate).
    The second is your local system password to add the certificate to your local keychain.

    ```bash
    gem install stack_car
    sc proxy cert # Only need this once per stack_car version, requires passwords
    sc proxy up
    ```

3) **Build the Docker images:**

    Downloading the base images your first time may take up to 10 minutes on a 100Mbit connection. 
    If you're on a slower connection, please be patient.

    ```bash
    docker compose build
    ```
### Running the Application

1. **Starting**

    The first time you start the application, the system will initialize the required containers 
    from the images downloaded during the build process. This may take 3-5 minutes on a 
    relatively fast connection.  After the first run, stopping and starting the containers will be 
    significantly faster (typically under a minute).
    ```bash
    docker compose up web
    ```
    When you see `Listening on tcp://0.0.0.0:3000` in the logs, the application is ready.

    #### Congratulations!!!

   You can access the admin app in your browser at
   [https://admin-hyku.localhost.direct](https://admin-hyku.localhost.direct).
   > :thumbsup: You are now ready to start using Hyku! Please refer to **[Using Hyku](./using-hyku.md)**
   > for instructions on getting your first tenant set up.

2. **Stopping (stop)**

    If you ran `docker compose up` in the foreground, you can use *Control + C* to stop the running 
    containers. If you're running in the background - e.g. `docker compose up -d`, you can stop the 
    containers using:
    ```bash
    docker compose stop
    ```
   
3. **Stopping & releasing resources (down)**

    Stop halts the runnining containers but does not tear down ephemeral resources used by Docker.
    If you want to release resources associated with your containers, for instance to rebuild from 
    a newer commit, you can use the "down" command:

    ```bash
    docker compose down
    ```

### Additional Docker Options

#### Configuration

Hyku configuration is primarily found in the `.env` file. Using the defaults checked out from
GitHub will get you running out of the box. To customize your configuration later,
see the [Configuration Guide](./configuration.md).

#### Application name in URL

The APP_NAME environment variable defaults to `hyku`, You can set this to another value in your
local environment - e.g. `export APP_NAME=sandbox` - or via the `.env` file. The application path 
will be "https://admin-${APP_NAME}.localhost.direct" - e.g. 
[https://admin-**sandbox**.localhost.direct](https://admin-sandbox.localhost.direct).

#### DNS & Certificates

Stack Car provides DNS and TLS from local development using the `localhost.direct` domain.
To use your own DNS you can run the application without Stack Car by
copying `docker-compose.override-noproxy.yml` to `docker-compose.override.yml`,
This lets you run Hyku without Dory, but you will have to set up your own DNS entries.
>```bash
>cp docker-compose.override-noproxy.yml docker-compose.override.yml
>```

#### Local development without Docker

You may be able to run the application locally without docker by ensuring you have met the following
requirements:

* Ruby 3.3.x is required (minimum for Rails 7.2). Later versions may also work.
* Rails 7.2.x is required.

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

## Troubleshooting

1. **Browser displays "404 Page not found"** OR **"Bad gateway" error**

   This can occur after your containers have started, and before the rails (web) application has
   finished initialization. Wait until you see this line in your terminal or log:
   ```
   web-1  | * Listening on http://0.0.0.0:3000
   ```
   If this issue persists for more than a minute or two, and you see activity from containers
   in your terminal window, you may want to start over from scratch.

2. **Nothing is working, I want to start over**
   - **Gentle**
     ```
     # type Control+C to stop your running containers
     docker compose up
     ```
   - **Firmer** 
     ```
     docker compose down
     docker compose up web
     ```
   - **Sledgehammer**
     ```
     docker compose down
     docker system prune --all --force
     docker compose build
     docker compose up web
     ```
   - **Nu-clear**
     ```
     docker compose down
     docker system prune --all --force --volumes
     cd ..
     rm -rf hyku
     git clone https://github.com/samvera/hyku.git
     cd hyku
     git checkout tags/v6.2.0 # or the release, branch, or commit of your choice
     docker compose build
     docker compose up web
     ```

### Windows Specific Issues
1. When creating a work and adding a file, you get an internal server error due to ownership/permissions issues of the tmp directory:
    - Gain root access to the container (in a slightly hacky way, check_volumes container runs from root): `docker compose run check_volumes bash`
    - Change ownership to app: `chown -R app:app /app/samvera/hyrax-webapp`
