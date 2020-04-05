#!/bin/sh

# params
branch_or_release=$1
dist_version=$2
arch=$3

# variables
tmp_image=/tmp/image.tar
tmp_workdir=/tmp/image_workdir

usage_example() {
cat << EOF

To download branch or release packages please use
pull-packages.sh {branch_or_release} {dist_version} {arch}

Example:
pull-packages.sh 5.3.2 centos-8 amd64
EOF
}


if [ -z "${branch_or_release}" ]; then
  echo "error: please specifi branch or release"
  usage_example
  exit 1
fi

if [ -z "${dist_version}" ]; then
  echo "error: please specifi branch or release"
  usage_example
  exit 1
fi

if [ -z "${arch}" ]; then
  echo "error: please specifi branch or release"
  usage_example
  exit 1
fi

echo docker rmi kamailio/kamailio-store:${branch_or_release}-${dist_version}.${arch} 2> /dev/null || true

# To get image info without pulling please read https://ops.tips/blog/inspecting-docker-image-without-pull/
docker pull kamailio/kamailio-store:${branch_or_release}-${dist_version}.${arch} 2> /dev/null
if [ $? -ne 0 ]; then
    echo "error: cannot pull image \"kamailio/kamailio-store:${branch_or_release}-${dist_version}.${arch}\""
    exit 1
fi

rm -f ${tmp_image}
docker save --output ${tmp_image} kamailio/kamailio-store:${branch_or_release}-${dist_version}.${arch}
rm -Rf ${tmp_workdir}
mkdir ${tmp_workdir}
tar x -C ${tmp_workdir} -f ${tmp_image}
# extract repo files
mkdir ${tmp_workdir}/files
tar x -C ${tmp_workdir}/files -f ${tmp_workdir}/*/layer.tar

echo "extracted:"
ls -l ${tmp_workdir}/files
mv ${tmp_workdir}/files/* .

