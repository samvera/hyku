# Some helpful shortcuts
1. List all containers (only IDs) `docker ps -aq`
1. Stop all running containers. `docker stop $(docker ps -aq)`
1. Remove all containers. `docker rm $(docker ps -aq)`
1. Remove all images. `docker rmi $(docker images -q)`

# Packaging Docker
1. Clear everything from `./tmp`. Otherwise this is going into the packaged image.
1. Run `docker-compose up --build` to pull/build all of the images. Note that hyku_app, hyku_web, hyku_workers, hyku_db_migrate, hyku_initialize_app all aliases to a single image, so we only need to pack one of them. e.g. hyku_app
1. Run `docker-compose down` to shut down once everything looks okay.
1. Export the images to a tar file and compress it:
```
docker save -o images/hyku-all.tar hyku_app solr postgres redis zookeeper memcached cbeer/fcrepo4 ruby dockercloud/haproxy
gzip images/hyku-all.tar
```
# Starting Hyku in Docker

1. Download hyku (git or zip?)
1. Modify `/etc/hosts` and add `127.0.0.1 sample.localhost` (Look into setting base host variable)
1. Open browser and go to http://localhost:8080/ enter "sample" for the "Short name"
1. Create an Image type object.


## Check out the services
```
docker ps
```

```
CONTAINER ID        IMAGE                       COMMAND                  CREATED             STATUS              PORTS                                                   NAMES
eedf5f80cdf1        dockercloud/haproxy:1.5.3   "/sbin/tini -- doc..."   17 minutes ago      Up 20 seconds       1936/tcp, 0.0.0.0:8080->80/tcp, 0.0.0.0:8443->443/tcp   hyku_lb_1
5ff4b199d09f        hyku_workers                "bundle exec sidekiq"    17 minutes ago      Up 21 seconds       3000/tcp                                                hyku_workers_1
f098b85f866b        redis:3                     "docker-entrypoint..."   17 minutes ago      Up 26 seconds       6379/tcp                                                hyku_redis_1
1512454f858a        solr                        "docker-entrypoint..."   5 days ago          Up 23 seconds       8983/tcp                                                hyku_solr_1
fcefa2663857        zookeeper                   "/docker-entrypoin..."   5 days ago          Up 24 seconds       2181/tcp, 2888/tcp, 3888/tcp                            hyku_zoo3_1
fcfb362ac61d        zookeeper                   "/docker-entrypoin..."   5 days ago          Up 26 seconds       2181/tcp, 2888/tcp, 3888/tcp                            hyku_zoo2_1
2cf7a63be590        postgres                    "docker-entrypoint..."   5 days ago          Up 26 seconds       5432/tcp                                                hyku_db_1
4ec580198c7c        cbeer/fcrepo4:4.7           "catalina.sh run"        5 days ago          Up 26 seconds       8080/tcp                                                hyku_fcrepo_1
7b5297e3903d        zookeeper                   "/docker-entrypoin..."   5 days ago          Up 25 seconds       2181/tcp, 2888/tcp, 3888/tcp                            hyku_zoo1_1
41650173eade        memcached                   "docker-entrypoint..."   5 days ago          Up 26 seconds       11211/tcp                                               hyku_memcache_1
```

## Connect to Service

```
docker exec -it hyku_workers_1 bash
```

## Rails console

```
rails console
```

## Switch tenant
```
AccountElevator.switch!('sample.localhost')
Image.all
```