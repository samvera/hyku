# Dev Environment
We distribute a `docker-compose.yml` configuration for running the Hyku stack and application using docker. Once you have [docker](https://docker.com) installed and running, launch the stack using e.g.:

```bash
docker-compose up -d
```

## Dory
Dory is a useful tool to manage the IP adresses and ports of the apps you are running locally for development.

### Directory Name
The VIRTUAL_HOST set in the docker-compose.yml file must match the name of the directory if you use default Dory settings, or match your Dory Config.  In our case, we'll assume that the directory is named "palni".  See docker-compose.yml  services:web:environment: for how your VIRTUAL_PORT is set.

### Install Dory
```bash
gem install dory
```

### And run from your project directory
```
dory up
```

Then the app is available at "http://palni.docker" or whatever the directory name you chose is.

# Developing

## Switching accounts
The recommend way to switch your current session from one account to another is by doing:

```ruby
AccountElevator.switch!('repo.example.com')
```

# Everything below may be stale

## Importing
### from CSV:

```bash
./bin/import_from_csv localhost spec/fixtures/csv/gse_metadata.csv ../hyku-objects
```

### from purl:

```bash
./bin/import_from_purl ../hyku-objects bc390xk2647 bc402fk6835 bc483gc9313
```

