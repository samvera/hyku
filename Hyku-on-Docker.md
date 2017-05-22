### Running Hyku on Docker

We distribute a `docker-compose.yml` configuration for running the Hyku stack and application using docker. Once you have [docker](https://docker.com) installed and running, launch the stack using e.g.:

```bash
docker-compose up -d
```

Now you can visit http://localhost:8080/ and see the site running in multitenancy mode.  


## How do I run it in single tenant mode?

## How do I update the application?
The containers are meant to be immutable, so we just discard the container and build a new one by running `docker-compose build`
