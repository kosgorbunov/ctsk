#!/usr/bin/env bash

cleanup() {
  echo Cleanup now...
  echo --------------
  set +x
  echo -n "Stopping container: "
  docker stop $consul_server
  set -x
  set +x
  echo -n "Removing container: "
  docker rm $consul_server
  set -x


}

init() {
  echo CTask implementation purposed
  echo -----------------------------
  export consul_server=csrv
  cleanup
}

csrv_start() {
  echo Starting consul server
  docker pull consul
  docker images -f 'reference=consul'
  docker run \
    -d \
    -p 8500:8500 \
    -p 8600:8600/udp \
    --name=$consul_server \
    consul agent -server -ui -node=server-1 -bootstrap-expect=1 -client=0.0.0.0
}

click1() {

  echo
  echo Click 1
  echo -------
  echo 1st click for initializing your environment
  echo -------------------------------------------
  echo Clicking 1...

  csrv_start
}

justwaiting() {
  docker ps
  echo "waiting ${1} seconds"
  sleep "${1}"
}

init
click1
justwaiting 10
cleanup
