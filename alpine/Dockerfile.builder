FROM alpine:3.12

RUN echo "Prepare base image filelist" \
    && apk --no-cache upgrade \
    && export OS_FILELIST=/tmp/os_filelist \
    && find /  \( -path /etc -o -path /dev -o -path /home -o -path /media -o -path /proc -o -path /mnt -o -path /root -o -path /sys -o -path /tmp -o -path /run \) -prune  -o -print >> ${OS_FILELIST} \
    && echo "Preparing build environment" \
    && apk add --no-cache abuild git gcc build-base bison db-dev gawk flex expat-dev perl-dev postgresql-dev python3-dev pcre-dev mariadb-dev \
         libxml2-dev curl-dev unixodbc-dev confuse-dev ncurses-dev sqlite-dev lua-dev openldap-dev \
         net-snmp-dev libuuid libev-dev jansson-dev json-c-dev libevent-dev linux-headers \
         libmemcached-dev rabbitmq-c-dev hiredis-dev libmaxminddb-dev libunistring-dev freeradius-client-dev lksctp-tools-dev ruby-dev \
         wireshark-common tcpdump mongo-c-driver-dev sudo \
    && adduser -D build && addgroup build abuild \
    && echo "%abuild ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/abuild \
    && su - build -c "git config --global user.name 'Your Full Name'" \
    && su - build -c "git config --global user.email 'your@email.address'" \
    && su - build -c "abuild-keygen -a -i -n"
