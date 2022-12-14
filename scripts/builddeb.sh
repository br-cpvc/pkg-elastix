#!/bin/bash
set -ex

BUILD_NUMBER=$1

script_dir=$(dirname "$0")
cd ${script_dir}/..

deb_root="debian"
rm -rf ${deb_root}
mkdir -p ${deb_root}/DEBIAN
mkdir -p ${deb_root}/usr

version="4.8"
elastix_pkg=elastix_linux64_v${version}.tar.bz2
url=https://elastix.lumc.nl/download/$elastix_pkg
if [[ ! -f $elastix_pkg ]]; then
 curl --insecure $url -o $elastix_pkg
fi
md5sum -c $elastix_pkg.md5sum
tar xjf $elastix_pkg --directory ${deb_root}/usr/
rm -f ${deb_root}/usr/LICENSE ${deb_root}/usr/NOTICE

cwd=`pwd`
cd $deb_root
find . -type f ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '%P ' | xargs md5sum > DEBIAN/md5sums
cd $cwd

package="elastix"
maintainer="SuperElastix/elastix <https://github.com/SuperElastix/elastix/issues>"
arch="amd64"

#date=`date -u +%Y%m%d`
#echo "date=$date"

#gitrev=`git rev-parse HEAD | cut -b 1-8`
gitrevfull=`git rev-parse HEAD`
gitrevnum=`git log --oneline | wc -l | tr -d ' '`
#echo "gitrev=$gitrev"

buildtimestamp=`date -u +%Y%m%d-%H%M%S`
hostname=`hostname`
echo "build machine=${hostname}"
echo "build time=${buildtimestamp}"
echo "gitrevfull=$gitrevfull"
echo "gitrevnum=$gitrevnum"

debian_revision="${gitrevnum}"
upstream_version="${version}"
echo "upstream_version=$upstream_version"
echo "debian_revision=$debian_revision"

packageversion="${upstream_version}-github${debian_revision}"
packagename="${package}_${packageversion}_${arch}"
echo "packagename=$packagename"
packagefile="${packagename}.deb"
echo "packagefile=$packagefile"

description="build machine=${hostname}, build time=${buildtimestamp}, git revision=${gitrevfull}"
if [ ! -z ${BUILD_NUMBER} ]; then
    echo "build number=${BUILD_NUMBER}"
    description="$description, build number=${BUILD_NUMBER}"
fi

installedsize=`du -s ${deb_root} | awk '{print $1}'`

mkdir -p ${deb_root}/DEBIAN/
#for format see: https://www.debian.org/doc/debian-policy/ch-controlfields.html
cat > ${deb_root}/DEBIAN/control << EOF |
Section: science
Priority: extra
Maintainer: $maintainer
Version: $packageversion
Package: $package
Architecture: $arch
Installed-Size: $installedsize
Description: $description
EOF

echo "Creating .deb file: $packagefile"
rm -f ${package}_*.deb
fakeroot dpkg-deb -Zxz --build ${deb_root} $packagefile

echo "Package info"
dpkg -I $packagefile
