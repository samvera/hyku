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
    git checkout production
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

### Running the Tests

Run the specs inside the `web` container:

```bash
docker compose exec web bash -lc 'cd /app/samvera/hyrax-webapp && RAILS_ENV=test bundle exec rspec'
```

#### Flexible and non-flexible metadata runs

The suite runs **without** flexible metadata by default, regardless of any `HYRAX_FLEXIBLE` value
set for development. To run it **with** flexible metadata, set `HYKU_TEST_FLEXIBLE_METADATA=true`:

```bash
docker compose exec web bash -lc 'cd /app/samvera/hyrax-webapp && HYKU_TEST_FLEXIBLE_METADATA=true RAILS_ENV=test bundle exec rspec'
```

Most specs are untagged and run in both modes. Tag a spec only when it works in just one mode:
`flexible: true` (flexible mode only) or `flexible: false` (non-flexible mode only).

Every test run answers two separate questions, each with its own setting:

1. **Which way does the app start up?** Set `HYKU_TEST_FLEXIBLE_METADATA`.
   - `true` starts the app with flexible metadata on.
   - `false`, or leaving it unset, starts it with flexible metadata off.

   This changes the app itself.
2. **Which tests do you want to run?** Set `HYKU_TEST_ONLY_FLEXIBLE_TAG`.
   - Set it to `true` or `false` to run only the specs with that `flexible:` tag, or to `untagged`
     to run only the specs with no tag.
   - Leave it unset to run every spec that makes sense for the way the app started:
     untagged and `false` specs with flexible metadata off, untagged and `true` specs with it on.

   This doesn't change the app. It only picks tests.

Examples (run inside the `web` container, as above):

- **Everything, flexible metadata off:**
  ```bash
  RAILS_ENV=test bundle exec rspec
  ```
- **Everything, flexible metadata on:**
  ```bash
  HYKU_TEST_FLEXIBLE_METADATA=true RAILS_ENV=test bundle exec rspec
  ```
- **Just the untagged specs, flexible metadata on:**
  ```bash
  HYKU_TEST_FLEXIBLE_METADATA=true HYKU_TEST_ONLY_FLEXIBLE_TAG=untagged RAILS_ENV=test bundle exec rspec
  ```

Run the suite with flexible metadata off and on to cover both modes.

**Why two settings?** Untagged specs are supposed to work whichever way the app starts, so CI
sometimes runs them with flexible metadata on and sometimes with it off. One setting says "start the app
this way", the other says "run these tests", and for untagged specs the two answers don't line up.

Day to day you'll mostly use only `HYKU_TEST_FLEXIBLE_METADATA`. The second setting is mainly for CI, and
for rerunning exactly what a CI node ran: the node's log prints the full command (see `spec/rails_helper.rb`
for how the filter works).

This format is intended to be extensible to other configurations that Hyku is able to enable.

#### CI

By default, the main `test` job runs the whole suite on three nodes with flexible metadata off.

When the repository Actions variable `HYKU_CI_FLEXIBLE_SPLIT` is set to `true` (Settings → Secrets and
variables → Actions → Variables), the job runs on six nodes instead, split by the `flexible:` tag
(see `bin/ci_rspec`):

| Node | Examples | Flexible metadata |
|---|---|---|
| 0 | `flexible: true` | on |
| 1 | `flexible: false` | off |
| 2–5 | untagged, split across the four nodes | on or off, chosen at random per node |

Each node prints its mode at the top of its log, with the command to rerun it locally. To force the
random nodes into one mode, set `CI_FLEXIBLE=true` or `CI_FLEXIBLE=false`. Because those nodes pick a
mode at random, an untagged spec that fails only in one mode fails on about half of the runs; rerun it
locally in the mode the log shows.

#### Watching browser (JavaScript) specs

Specs tagged `js: true` run in a real Chrome browser in the `chrome` container, which you can
watch live from your own browser at
[https://chrome-hyku.localhost.direct](https://chrome-hyku.localhost.direct)
(`https://chrome-${APP_NAME}.localhost.direct`). The VNC password is `secret`. Specs without
`js: true` do not use a browser, so the window stays idle while they run.

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

#### Developing with Solr 9
Hyku defaults to Solr 8; see [Using Solr 9](using-solr-9.md) to develop and test against Solr 9 instead.

#### Developing with Postgres 18
Hyku defaults to Postgres 11; see [Using Postgres 18](using-postgres-18.md) to develop and test against Postgres 18 instead.

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
