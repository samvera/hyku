# Install docker
### For Windows
\* Docker for Windows requires 64bit Windows 10 Pro and Microsoft Hyper-V. [Details](https://docs.docker.com/docker-for-windows/install/#what-to-know-before-you-install)

Download this file: https://download.docker.com/win/stable/InstallDocker.msi

Double click on the downloaded file to run the installer.

Open a terminal and type `docker run hello-world` to verify installation was correct.

You should see a message that states:
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

### For Mac
\* Docker for Mac requires OS X El Capitan 10.11 or newer macOS release running on a 2010 or newer Mac, with Intel’s hardware support for MMU virtualization. The app will run on 10.10.3 Yosemite, but with limited support.

Download this file: https://download.docker.com/mac/stable/Docker.dmg

Double-click Docker.dmg to open the installer, then drag Moby the whale to the Applications folder.
Double-click Docker.app in the Applications folder to start Docker.

Open a terminal and type `docker run hello-world` to verify installation was correct.

You should see a message that states:
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

### For Linux

Follow the guide for your distro at https://docs.docker.com/engine/installation/#supported-platforms


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