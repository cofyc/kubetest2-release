#!/bin/bash

readonly platforms=(
    linux/amd64
    linux/386
    linux/arm
    linux/arm64
    darwin/amd64
    windows/amd64
)

readonly binaries=(
    kubetest2
    kubetest2-kind
    kubetest2-eks
    kubetest2-gke
)
