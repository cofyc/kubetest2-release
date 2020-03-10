#!/usr/bin/env bash

#
# Isolated container environment for development.
#

set -o errexit
set -o nounset
set -o pipefail

ROOT=$(unset CDPATH && cd $(dirname "${BASH_SOURCE[0]}")/.. && pwd)
cd $ROOT

# the container image, by default a recent official golang image
GOIMAGE="${GOIMAGE:-golang:1.14}"
DOCKER_GO_VOLUME=${DOCKER_GO_VOLUME:-kubetest2-go}
NAME=${NAME:-kubetest2-dev}

function usage() {
    cat <<'EOF'
This script is entrypoint to start a isolated container environment for development.

Usage: hack/run-in-container.sh [-h] [command]

    -h      show this message and exit

Environments:

    CLEANUP             if passed, clean up local caches
    DOCKER_GO_VOLUME    the name of go cache volume, defaults: kubetest2-go
    NAME                the name of container, defaults: kubetest2-dev

Examples:

0) view help

    ./hack/run-in-container.sh -h

1) start an interactive shell

    ./hack/run-in-container.sh

    You can start more than one terminals and run `./hack/run-in-container.sh` to
    enter into the same container for debugging.

EOF
}

if [ "${1:-}" == "-h" ]; then
    usage
    exit 0
fi

args=(bash)
if [ $# -gt 0 ]; then
    args=($@)
fi

docker_args=(
    -it --rm
    -h $NAME
    --name $NAME
)

# required by dind
docker_args+=(
    # golang cache
    -v $DOCKER_GO_VOLUME:/go
    # golang xdg cache directory
    -e XDG_CACHE_HOME=/go/cache
)

ret=0
sts=$(docker inspect ${NAME} -f '{{.State.Status}}' 2>/dev/null) || ret=$?
if [ $ret -eq 0 ]; then
    if [[ "$sts" == "running" ]]; then
        echo "info: found a running container named '${NAME}', trying to exec into it" >&2
        exec docker exec -it ${NAME} "${args[@]}"
    else
        echo "info: found a non-running ($sts) container named '${NAME}', removing it first" >&2
        docker rm ${NAME}
    fi
fi

docker run ${docker_args[@]} \
    -v $ROOT:/go/src/github.com/cofyc/kubetest2 \
    -w /go/src/github.com/cofyc/kubetest2 \
    $GOIMAGE \
    "${args[@]}"
