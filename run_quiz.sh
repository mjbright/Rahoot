#!/usr/bin/env bash

# Source based on 2025-Dec-14, 1.0.2 release

cd $( dirname $0 )

IP=localhost
#IMAGE=ralex91/rahoot:latest
#IMAGE=mjbright/rahoot:v1
#IMAGE=mjbright/rahoot:v1.1
#IMAGE=mjbright/rahoot:v1.2
#IMAGE=mjbright/rahoot:v1.3
IMAGE=mjbright/rahoot:v1.4
EXT_PORT=8445

if [ "$1" = "-pub" ]; then
    IP="0.0.0.0"
    case $(hostname) in
        #air) BROWSE_IP=$( ifconfig | grep -A10 bridge101 | awk '/inet / { print $2; }' );;
        air) BROWSE_IP=$( ifconfig | grep -A10 en0: | awk '/inet / { print $2; }' );;
      *)   BROWSE_IP=$( hostname -i);;
    esac
fi

# docker run -d -p 3000:3000 -p 3001:3001 -e WEB_ORIGIN=http://localhost:3000 -e SOCKET_URL=http://localhost:3001 \
#            -v ./config:/app/config ralex91/rahoot:latest
#

docker ps -a | grep mjb_rahoot_quiz &&
    docker rm -f mjb_rahoot_quiz

#docker run -d -p $EXT_PORT:3000 -p 3001:3001 -e WEB_ORIGIN=http://$IP:3000 -e SOCKET_URL=http://$IP:3001 \
docker run -d -p $EXT_PORT:3000 -e WEB_ORIGIN=http://$IP:3000 -e SOCKET_URL=http://$IP:3001 \
           -v ./config:/app/config --name mjb_rahoot_quiz $IMAGE

sleep 5
docker ps | grep mjb_rahoot_quiz
echo "Now students browse to http://$IP:$EXT_PORT"
echo "Now manager  browse to http://$IP:$EXT_PORT/manager (mdp: St****00..)"
echo "Viewing logs ... ( docker logs -f mjb_rahoot_quiz ):"
docker logs -f mjb_rahoot_quiz



