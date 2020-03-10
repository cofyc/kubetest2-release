#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

ROOT=$(unset CDPATH && cd $(dirname "${BASH_SOURCE[0]}")/.. && pwd)
cd $ROOT

source $ROOT/hack/lib.sh

GITHUB_TOKEN=${GITHUB_TOKEN:-1}
VERSION=${VERSION:-}

if [[ ! "$VERSION" =~ v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "error: VERSION must match regex 'v[0-9]+\.[0-9]+\.[0-9]+'"
    exit 1
fi

if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "error: GITHUB_TOKEN is required"
    exit 1
fi

exit
echo "info: getting release tagged with $VERSION"
release_id=$(curl -s -H 'Accept: application/vnd.github.v3+json' -H "Authorization: token $GITHUB_TOKEN" \
    https://api.github.com/repos/cofyc/kubetest2/releases/tags/$VERSION | jq '.id')
if [[ ! "$release_id" =~ ^[0-9]+$ ]]; then
    echo "info: create release $VERSION"
    curl -H 'Accept: application/vnd.github.v3+json' -H "Authorization: token $GITHUB_TOKEN" \
        -XPOST \
        -d @- \
        https://api.github.com/repos/cofyc/kubetest2/releases <<EOF
    {
      "tag_name": "$VERSION",
      "target_commitish": "master",
      "name": "$VERSION",
      "body": "$VERSION",
      "draft": false,
      "prerelease": false
    }
EOF
fi

echo "info: getting release id"
release_id=$(curl -s -H 'Accept: application/vnd.github.v3+json' -H "Authorization: token $GITHUB_TOKEN" \
    https://api.github.com/repos/cofyc/kubetest2/releases/tags/$VERSION | jq '.id')
if [[ ! "$release_id" =~ ^[0-9]+$ ]]; then
    echo "error: failed after creation, exit"
    exit 1
fi

echo "info: upload assets"
function upload_asset() {
    local release_id="$1"
    local asset="$2"
    local name=$(basename $asset)
    curl -H 'Accept: application/vnd.github.v3+json' -H "Authorization: token $GITHUB_TOKEN" \
        -H 'Content-Type: application/gzip' \
        -X POST \
        --data-binary @$asset \
        "https://uploads.github.com/repos/cofyc/kubetest2/releases/$release_id/assets?name=$name"
}

for platform in ${platforms[@]}; do
    export GOOS=${platform%/*}
    export GOARCH=${platform##*/}
    cd $ROOT/output/$GOOS/$GOARCH
    for b in ${binaries[@]}; do
        name=$b-$GOOS-$GOARCH.gz
        gzip -c $b > $name
        upload_asset $release_id $name
    done
done
