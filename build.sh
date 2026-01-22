#!/usr/bin/env bash

# Multi-architecture builds
# - using buildx
# - without requiring qemu installation
# Based on info at:
# - https://andrewlock.net/combining-multiple-docker-images-into-a-multi-arch-image/

IMAGE=mjbright/rahoot
TAGGED_IMAGE=$IMAGE:v1.2

PLAIN="--progress plain"

## -- Func: --------------------------------------------------------------------------------

die() { echo "$0: die - $*">&2; exit 1; }

LINUX_BUILD() {
    ARCH=$1; shift

    PLATFORM=linux/$ARCH
    IMG=$IMAGE-$ARCH

    CMD="docker buildx build $PLAIN -t $IMG -f Dockerfile --provenance false --output push-by-digest=true,type=image,push=true --platform $PLATFORM ."
    echo "-- $CMD"
    $CMD 2>&1 | tee build.${ARCH}.log || die "Build failed - $PLATFORM"
}

BUILDS() {
    T0=$SECONDS
      LINUX_BUILD amd64
    T1=$SECONDS
    let TOOK1=T1-T0
    echo "amd64 build took $TOOK1 seconds"
    
      LINUX_BUILD arm64
    T2=$SECONDS
    let TOOK2=T2-T1
    echo "amd64 build took $TOOK1 seconds"
    echo "arm64 build took $TOOK2 seconds"
    
    let TOOK=T2-T0
    echo "Both builds took $TOOK seconds"
}

BUILDER_CREATE() {
    docker buildx ls 2>&1 | grep '^build*' || {
        CMD="docker buildx create --use --name build --node build --driver-opt network=host"
        echo "-- $CMD"
        $CMD 2>&1 | tee build.create.log || die "Buildx create failed"
    }
}

## -- Main: --------------------------------------------------------------------------------

BUILDER_CREATE

#BUILDS

M_AMD64=$( awk '/exporting manifest/ { print $4; }' build.amd64.log )
M_ARM64=$( awk '/exporting manifest/ { print $4; }' build.arm64.log )

echo "Manifest AMD64: $M_AMD64"
echo "Manifest ARM64: $M_ARM64"

#docker manifest inspect andrewlockdd/alpine-clang@sha256:038adbc4d6dc2e28f0818d5ae0fc1cae6cc42b854bd809f236435bed33f6ea63
I_AMD64=${IMAGE}-amd64@$M_AMD64
I_ARM64=${IMAGE}-arm64@$M_ARM64
docker manifest inspect $I_AMD64
docker manifest inspect $I_ARM64

#docker manifest create andrewlockdd/alpine-clang:1.0 \
#  --amend andrewlockdd/alpine-clang@sha256:038adbc4d6dc2e28f0818d5ae0fc1cae6cc42b854bd809f236435bed33f6ea63 \
#  --amend andrewlockdd/alpine-clang@sha256:9df972530f876295787deea7424db90cbd14d5a8fa602b2a3bce82977aa1025e

docker manifest create $TAGGED_IMAGE \
    --amend $I_AMD64 --amend $I_ARM64

docker manifest push $TAGGED_IMAGE

