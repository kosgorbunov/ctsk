#!/usr/bin/env bash

echo CTask implementation purposed
echo ----------------------------

echo Click 1
echo ------------
echo 1st click for initializing your environment
echo -------------------------------------------
echo Clicking 1...

echo Starting consul server
docker pull consul
docker images -f 'reference=consul'
docker run \
    -d \
    -p 8500:8500 \
    -p 8600:8600/udp \
    --name=consul-server \
    consul agent -server -ui -node=server-1 -bootstrap-expect=1 -client=0.0.0.0

