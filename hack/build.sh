#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

ROOT=$(unset CDPATH && cd $(dirname "${BASH_SOURCE[0]}")/.. && pwd)
cd $ROOT

GIT_REF=719ba8f2dfa8cf40505843a74ef4683ee070d552
VERSION=v0.0.1
# switch to official repo if all our features are merged in
GIT_REPO=https://github.com/cofyc/test-infra

tmpdir=$(mktemp -d)
trap "rm -rf ${tmpdir}" EXIT
cd ${tmpdir}
git clone --depth=1 -b kubetest2 $GIT_REPO
git checkout $GIT_REF
cd test-infra
GO111MODULE=on GOBIN=$ROOT go install ./kubetest2/...

binaries=(
    kubetest2
    kubetest2-kind
    kubetest2-gke
)

for b in ${binaries[@]}; do
    tar -czvf $b-binary-$VERSION.tar.gz $b
done
