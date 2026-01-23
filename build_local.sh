
cd $(dirname $0)

PLATFORM="--platform linux/arm64"
IMAGE_NAME=mjbright/rahoot
#IMAGE_VERSION=v1.1
IMAGE_VERSION=$( cat .image_version )
IMAGE=$IMAGE_NAME:$IMAGE_VERSION

TMP=~/var/mono2micro.docker-builds
rm -rf   $TMP
mkdir -p $TMP

DIR=../../1.Monoliths
DIR=~/src/github.com/GIT_mjbright/monolith2microservice/1.Monoliths

# ???? rsync -av $DIR/* $TMP

PLAIN="--progress plain"

## -- Func: --------------------------------------------------------------------------------

die() {
    echo "$0: die - Build failed $*"
    exit 1
}

BUILD_ARM64() {
    PLATFORM="--platform linux/arm64"
    CMD="./time.py docker build $PLAIN $PLATFORM -t $IMAGE -f Dockerfile ."
    echo "-- $CMD"
    $CMD || die "Failed to build for $PLATFORM"
}

BUILD_AMD64_ARM64() {
    #PLATFORM="--platform linux/amd64"
    PLATFORM="--platform linux/amd64,linux/arm64"
    CMD="./time.py docker build $PLAIN $PLATFORM -t $IMAGE -f Dockerfile ."
    echo "-- $CMD"
    $CMD || die "Failed to build for $PLATFORM"

    CMD="docker login"
    echo "-- $CMD"
    $CMD || die "Failed to 'docker login'"

    CMD="docker push $IMAGE_NAME"
    echo "-- $CMD"
    $CMD || die "Failed to push to docker hub: $IMAGE"
}

## -- Args: --------------------------------------------------------------------------------

if [ "$1" = "-push" ]; then
    #read -p "Press <enter> to build for arm64,amd64, push to Docker hub:"
    BUILD_AMD64_ARM64
    exit $?
fi

BUILD_ARM64

exit

# Arm64:
if [ "$1" = "-local" ]; then
    BUILD_MONOLITH_IMAGES_quiz linux/arm64
    #TOOK $START_S "flask-quiz linux/arm64"
    #START_S=$SECONDS
    exit
fi

## -- Main: --------------------------------------------------------------------------------

BUILD_MONOLITH_IMAGES_onestore linux/amd64
#exit
BUILD_MONOLITH_IMAGES_onestore linux/arm64

BUILD_MONOLITH_IMAGES_survey linux/amd64
BUILD_MONOLITH_IMAGES_survey linux/arm64

BUILD_MONOLITH_IMAGES_quiz linux/amd64
BUILD_MONOLITH_IMAGES_quiz linux/arm64

TOOK $START_S_0 "All images"

docker image ls | grep flask- | grep -v '<none>'


