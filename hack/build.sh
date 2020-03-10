#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

ROOT=$(unset CDPATH && cd $(dirname "${BASH_SOURCE[0]}")/.. && pwd)
cd $ROOT

source $ROOT/hack/lib.sh

# switch to official repo if all our features are merged in
GIT_REPO=https://github.com/cofyc/test-infra

tmpdir=$(mktemp -d /tmp/build-kubetest2-XXX)
echo "info: tmpdir $tmpdir"
trap "rm -rf ${tmpdir}" EXIT
cd ${tmpdir}
git clone --depth=1 -b kubetest2 $GIT_REPO
cd test-infra

test -d $ROOT/output || mkdir $ROOT/output

export GO111MODULE=on
LDFLAGS='-X k8s.io/component-base/version.gitVersion=v0.0.8'
for platform in ${platforms[@]}; do
    export GOOS=${platform%/*}
    export GOARCH=${platform##*/}
    echo "info: build targets for $platform"
    go build -ldflags "$LDFLAGS" -o $ROOT/output/$GOOS/$GOARCH/kubetest2 ./kubetest2/
    go build -ldflags "$LDFLAGS" -o $ROOT/output/$GOOS/$GOARCH/kubetest2-gke ./kubetest2/kubetest2-gke
    go build -ldflags "$LDFLAGS" -o $ROOT/output/$GOOS/$GOARCH/kubetest2-eks ./kubetest2/kubetest2-eks
    go build -ldflags "$LDFLAGS" -o $ROOT/output/$GOOS/$GOARCH/kubetest2-kind ./kubetest2/kubetest2-kind
done
