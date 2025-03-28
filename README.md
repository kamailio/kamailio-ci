[![Docker Stars](https://img.shields.io/docker/stars/kamailio/kamailio-ci.svg)](https://hub.docker.com/r/kamailio/kamailio-ci/)
[![Docker Pulls](https://img.shields.io/docker/pulls/kamailio/kamailio-ci.svg)](https://hub.docker.com/r/kamailio/kamailio-ci/)
[![Docker Automated build](https://img.shields.io/docker/automated/kamailio/kamailio-ci.svg)](https://hub.docker.com/r/kamailio/kamailio-ci/)

# [Supported tags](https://github.com/kamailio/kamailio-ci/pkgs/container/kamailio-ci/versions)

-	`master`, `master-alpine`, `master-alpine.debug`
-	`latest`, `latest-alpine`, `latest-alpine.debug`
-	`6.x`, `6.x-alpine`, `6.x-alpine.debug`
-	`5.x`, `5.x-alpine`, `5.x-alpine.debug`

Tags `master`, `latest`, `X.Y` and `X.Y.Z` based on alpine image with removed all libs except libc, busybox, tcpdump, dumpcap, gawk, kamailio and dependent libs.

Tags that contains `-alpine` keyword based on alpine image. All OS tools is untouched and possible to use `apk` utility.

Tags that contains `-alpine.debug` keyword based on alpine image and includes `gdb` utility with kamailio debug files.

All images designed to run on host, bridge and swarm networks.

# Quick reference

-	**Where to get help**:  
	[the Kamailio maillist](https://www.kamailio.org/w/mailing-lists/)

-	**Where to file issues**:
	[Kamailio bug tracker](https://github.com/kamailio/kamailio/issues)


# What is Kamailio?

Kamailio is an Open Source SIP Server released under GPL, able to handle thousands of call setups per second.
Kamailio can be used to build large platforms for VoIP and realtime communications – presence, WebRTC, Instant
messaging and other applications.

> [kamailio.org](https://www.kamailio.org)

![logo](https://www.kamailio.org/w/wp-content/uploads/2016/04/kamailio-logo-2015-140x64.png)

# Image usage

Before first run need to prepare kamailio default config files. If you already have kamailio config files, then you can skip this. To prepare default config files need to execute
```console
docker create --name kamailio kamailio/kamailio-ci
docker cp kamailio:/etc/kamailio /etc
docker rm kamailio
```

Then you can start docker image

```console
docker run --net=host --name kamailio \
           -v /etc/kamailio:/etc/kamailio \
           kamailio/kamailio-ci -m 64 -M 8
```

# systemd unit file

You can use this systemd unit file on your docker host.
Unit file can be placed to `/etc/systemd/system/kamailio-docker.service` and enabled by commands
```console
systemd start kamailio-docker.service
systemd enable kamailio-docker.service
```

If you use `debug` image, then need map host directory (or volume) to contianer `/var/lib/coredump` folder. This may be done using additinal `docker run` option `-v /var/lib/coredump:/var/lib/coredump`

## host network

```console
[Unit]
Description=kamailio Container
After=docker.service network-online.target
Requires=docker.service


[Service]
Restart=always
TimeoutStartSec=0
#One ExecStart/ExecStop line to prevent hitting bugs in certain systemd versions
ExecStart=/bin/sh -c 'docker rm -f kamailio; \
          docker run -t --rm=true --log-driver=none --name kamailio \
                  --net=host \
                 -v /etc/kamailio:/etc/kamailio \
                 kamailio/kamailio-ci'
ExecStop=/usr/bin/docker stop kamailio

[Install]
WantedBy=multi-user.target
```

## default bridge network

```console
[Unit]
Description=kamailio Container
After=docker.service network-online.target
Requires=docker.service


[Service]
Restart=always
TimeoutStartSec=0
#One ExecStart/ExecStop line to prevent hitting bugs in certain systemd versions
ExecStart=/bin/sh -c 'docker rm -f kamailio; \
          docker run -t --rm=true --log-driver=none --name kamailio \
                 --network bridge \
                 -p 5060:5060/udp -p 5060:5060 -p 5061:5061 \
                 --hostname kamailio \
                 -v /etc/kamailio:/etc/kamailio \
                 kamailio/kamailio-ci'

ExecStop=/usr/bin/docker stop kamailio

[Install]
WantedBy=multi-user.target
```

## user defined bridge and swarm networks

Requred to create user defined network first.

```console
docker network create --driver bridge  --subnet 10.0.0.0/24 my-net
```

Or you can create swarm network

```console
docker network create --driver overlay --attachable --subnet 10.0.0.0/24 my-net
```

Then you can create systemd unit file

```console
[Unit]
Description=kamailio Container
After=docker.service network-online.target
Requires=docker.service


[Service]
Restart=always
TimeoutStartSec=0
#One ExecStart/ExecStop line to prevent hitting bugs in certain systemd versions
ExecStart=/bin/sh -c 'docker rm -f kamailio; \
          docker run -t --rm=true --log-driver=none --name kamailio \
                 --network my-net \
                 --ip 10.0.0.2 \
                 -p 5060:5060/udp -p 5060:5060 -p 5061:5061 \
                 --hostname kamailio.my-net \
                 -v /etc/kamailio:/etc/kamailio \
                 kamailio/kamailio-ci'

ExecStop=/usr/bin/docker stop kamailio

[Install]
WantedBy=multi-user.target
```

# .bashrc file

To simplify kamailio managment you can add alias for `kamctl` to `.bashrc` file as example bellow.
```console
alias kamctl='docker exec -i -t kamailio /usr/sbin/kamctl'
```
