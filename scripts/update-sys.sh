#!/bin/bash -e

. $(dirname $0)/config.sh

pkg=$1-sys-${SUFFIX}
oldver=$2
newver=$3

${DRY_RUN} git reset --hard HEAD
${DRY_RUN} opam update ${SUFFIX}

oldarchive=$(cat packages/${pkg}.${oldver}/url | head -n1)
oldurl=$(sed -e 's/archive: //' -e 's/"//g' <<<"${oldarchive}")
newarchive=$(sed -e s/${oldver}/${newver}/g <<<"${oldarchive}")
newurl=$(sed -e s/${oldver}/${newver}/g <<<"${oldurl}")
newmd5=$(curl --fail --location ${newurl} | md5sum)

if [ "${DRY_RUN}" != "true" ]; then
  urlfile=packages/${pkg}.${newver}/url
fi
${DRY_RUN} git mv packages/${pkg}.${oldver} packages/${pkg}.${newver}
tee ${urlfile} <<END
${newarchive}
checksum: "${newmd5/  -/}"
END
${DRY_RUN} git add packages/${pkg}.${newver}

${DRY_RUN} opam remove -y ${pkg}.${oldver}
${DRY_RUN} opam update android
${DRY_RUN} opam install -y ${pkg}.${newver}

${DRY_RUN} git commit -m "${pkg}.{${oldver}→${newver}}"
