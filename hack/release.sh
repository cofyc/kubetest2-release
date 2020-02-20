#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

TOKEN=$TOKEN
echo "info: getting release tagged with $VERSION"
release_id=$(curl -s -H 'Accept: application/vnd.github.v3+json' -H "Authorization: token $TOKEN" \
    https://api.github.com/repos/cofyc/kubetest2/releases/tags/$VERSION | jq '.id')
if [[ ! "$release_id" =~ ^[0-9]+$ ]]; then
    echo "info: create release $VERSION"
    curl -H 'Accept: application/vnd.github.v3+json' -H "Authorization: token $TOKEN" \
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
release_id=$(curl -s -H 'Accept: application/vnd.github.v3+json' -H "Authorization: token $TOKEN" \
    https://api.github.com/repos/cofyc/kubetest2/releases/tags/$VERSION | jq '.id')
if [[ ! "$release_id" =~ ^[0-9]+$ ]]; then
    echo "error: failed after creation, exit"
    exit 1
fi

echo "info: upload assets"
binaries=(
    kubetest2
    kubetest2-kind
    kubetest2-eks
    kubetest2-gke
)

function upload_asset() {
    local release_id="$1"
    local asset="$2"
    local name=$(basename $asset)
    curl -H 'Accept: application/vnd.github.v3+json' -H "Authorization: token $TOKEN" \
        -H 'Content-Type: application/gzip' \
        -X POST \
        --data-binary @$asset \
        "https://uploads.github.com/repos/cofyc/kubetest2/releases/23828885/assets?name=$name"
}

for b in ${binaries[@]}; do
    gzip -c $b > $b.gz
    upload_asset $release_id $b.gz
done
