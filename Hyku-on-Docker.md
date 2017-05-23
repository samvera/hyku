### Running Hyku on Docker

We distribute a `docker-compose.yml` configuration for running the Hyku stack and application using docker. Once you have [docker](https://docker.com) installed and running, launch the stack using e.g.:

```bash
docker-compose up -d
```

Now you can visit http://localhost:8080/ and see the site running in multitenancy mode.  

## How do I set up DNS for multiple tenants?

https://github.com/projecthydra-labs/hyku/wiki#using-account-switching-in-development

## How do I run it in single tenant mode?

Presently there's no way to set up the single tenant mode, because hyku uses the account creation step to initialize a Solr collection for your repository.  We could enable single tenant mode if we had a mechanism to create this collection out of band.

## How do I update the application?
The containers are meant to be immutable, so we just discard the container and build a new one by running `docker-compose build`
