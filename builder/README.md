This repo contains Kamailio packages (RPM). Each docker image contains package for one release or branch for givent operation system and architecture.
Build for maintained branches is exist only for CentOS 7 and 8.

Supported dist
1) `centos-6` - CentOS 6;
2) `centos-7` - CentOS 7;
3) `centos-9` - CentOS 8;
4) `rhel-7` - RHEL 7;
5) `rhel-8` - RHEL 8;
6) `opensuse_leap-42` - OpenSUSE Leap 42;
7) `opensuse_leap-15` - OpenSUSE Leap 15;
8) `opensuse_tumbleweed-latest` - OpenSUSE Tumbleweed;
9) `fedora-29` - Fedora 29;
10) `fedora-30` - Fedora 30;
11) `fedora-31` - Fedora 31;
12) `fedora-32` - Fedora 32;
13) `fedora-33` - Fedora 33.

Supported Kamailio branches and versions:
1) `master`;
2) `5.3`, `5.3.3`, `5.3.2`;
3) `5.2`, `5.2.6`.

Supported archictures
1) `amd64`

To download packages you can use this command example

```sh
curl -O https://raw.githubusercontent.com/kamailio/kamailio-ci/builder/builder/pull-packages.sh
chmod 755 pull-packages.sh
pull-packages.sh 5.3.2 centos-8 amd64
```
