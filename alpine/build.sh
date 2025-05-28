#!/bin/sh

# This script is wrote by Sergey Safarov <s.safarov@gmail.com>
set -eu
BUILD_ROOT=/tmp/kamailio
FILELIST=/tmp/filelist
FILELIST_BINARY=/tmp/filelist_binary
TMP_TAR=/tmp/kamailio_min.tar.gz
OS_FILELIST=/tmp/os_filelist
IMG_TAR=kamailio_img.tar.gz
apkArch="$(apk --print-arch)"

build_apk(){
    cp -R /usr/src/kamailio ~
    cd ~/kamailio
    make cfg
    make -C pkg/kamailio apk
    abuild -C pkg/kamailio/alpine -r
    doas mkdir -p /mnt/context/${apkArch}/apk_files
    doas mv /home/build/packages/kamailio/* /mnt/context/${apkArch}/apk_files/
    doas cp pkg/docker/alpine/Dockerfile* /mnt/context/
    doas chown -R --reference=/usr/src/kamailio /mnt/context/${apkArch}/apk_files
}

install_apk(){
    cd /mnt/context/${apkArch}/apk_files
    ls -1 */kamailio-*.apk |  xargs doas apk --no-cache --allow-untrusted add
}

list_installed_kamailio_packages() {
    apk info | grep kamailio
}

kamailio_files() {
    local PACKAGES
    PACKAGES=$(list_installed_kamailio_packages)
    PACKAGES="musl ca-certificates $PACKAGES"
    for pkg in $PACKAGES
    do
        # list package files and filter package name
        apk info --contents $pkg 2> /dev/null | sed -e '/\S\+ contains:/d'  -e '/^$/d' -e 's/^/\//'
    done
}

extra_files() {
    cat << EOF
/etc
/etc/ssl
/etc/ssl/certs
/etc/ssl/certs/*
/bin
/bin/busybox
/usr/bin
/usr/bin/awk
/usr/bin/gawk
/usr/lib
/usr/sbin
/usr/bin/tcpdump
/var
/var/run
/run
/tmp
EOF
    if [ "${apkArch}" != "armhf" ]; then
    cat << EOF
/usr/bin/dumpcap
EOF
    fi
}

sort_filelist() {
    sort $FILELIST | uniq > $FILELIST.new
    mv -f $FILELIST.new $FILELIST
}

filter_unnecessary_files() {
# excluded following files and directories recursive
# /usr/lib/debug/usr/lib/kamailio/
# /usr/share/doc/kamailio
# /usr/share/man
# /usr/share/snmp

    sed -i \
        -e '\|^/usr/lib/debug/|d' \
        -e '\|^/usr/share/doc/kamailio/|d' \
        -e '\|^/usr/share/man/|d' \
        -e '\|^/usr/share/snmp/|d' \
        $FILELIST
}

ldd_helper() {
    TESTFILE=$1
    LD_PRELOAD=/usr/sbin/kamailio ldd $TESTFILE 2> /dev/null > /dev/null || return
    LD_PRELOAD=/usr/sbin/kamailio ldd $TESTFILE | sed -e 's/^.* => //' -e 's/ (.*)//' -e 's/\s\+//' -e '/^ldd$/d'
}

find_binaries() {
    rm -f $FILELIST_BINARY
    set +e
    for f in $(cat $FILELIST)
    do
        ldd_helper /$f >> $FILELIST_BINARY
    done
    set -e
    sort $FILELIST_BINARY | sort | uniq > $FILELIST_BINARY.new
    mv -f $FILELIST_BINARY.new $FILELIST_BINARY

    # Resolving symbolic links and removing duplicates
    cat $FILELIST_BINARY | xargs realpath > $FILELIST_BINARY.new
    cat $FILELIST_BINARY.new >> $FILELIST_BINARY
    sort $FILELIST_BINARY | sort | uniq > $FILELIST_BINARY.new
    mv -f $FILELIST_BINARY.new $FILELIST_BINARY
}

filter_os_files() {
    local TARLIST=$1
    set +e
    for f in $(cat $TARLIST)
    do
        grep -q "$f" $OS_FILELIST
        if [ $? -ne 0 ]; then
           echo $f
        fi
    done
    set -e
}

tar_files() {
    local TARLIST=/tmp/tarlist
    cat $FILELIST > $TARLIST
    cat $FILELIST_BINARY >> $TARLIST
    filter_os_files $TARLIST > $TARLIST.without_os_files

    # awk symbolink link need to point to gawk
    echo /usr/bin/awk >> $TARLIST.without_os_files

    tar -czf $TMP_TAR --no-recursion $(cat $TARLIST)
    tar -czf $TMP_TAR.without_os_files --no-recursion -T $TARLIST.without_os_files
    rm -f $TARLIST $TARLIST.without_os_files

    # copy tar archive wuthout os files to result dir
    doas cp $TMP_TAR.without_os_files /mnt/context/${apkArch}/kamailio_img-without_os_files.tar.gz
}

make_image_tar() {
    mkdir -p $BUILD_ROOT
    cd $BUILD_ROOT
    tar xzf $TMP_TAR
    /bin/busybox --install -s bin
    tar czf /tmp/$IMG_TAR *
    doas cp /tmp/$IMG_TAR /mnt/context/${apkArch}/
}

build_apk
install_apk
kamailio_files > $FILELIST
extra_files >> $FILELIST
sort_filelist
filter_unnecessary_files
find_binaries
tar_files
make_image_tar
doas find /mnt/context -type f -exec chmod 666 -- {} +
doas find /mnt/context -type d -exec chmod 777 -- {} +
doas chown -R root:root /mnt/context
doas cp -R /mnt/context /usr/src/kamailio/pkg/docker/alpine/
