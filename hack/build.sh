#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

ROOT=$(unset CDPATH && cd $(dirname "${BASH_SOURCE[0]}")/.. && pwd)
cd $ROOT

VERSION=v0.0.2
# switch to official repo if all our features are merged in
GIT_REPO=https://github.com/cofyc/test-infra

tmpdir=$(mktemp -d /tmp/build-kubetest2-XXX)
echo "info: tmpdir $tmpdir"
trap "rm -rf ${tmpdir}" EXIT
cd ${tmpdir}
git clone --depth=1 -b kubetest2 $GIT_REPO
cd test-infra
GO111MODULE=on GOBIN=$ROOT go install ./kubetest2/...

binaries=(
    kubetest2
    kubetest2-kind
    kubetest2-eks
    kubetest2-gke
)

echo "info: packing"
cd $ROOT
for b in ${binaries[@]}; do
    gzip -c $b > $b.gz
done
