#!/usr/bin/env bash

cleanup() {
  echo Cleanup now...
  echo --------------
  echo -n "Stopping container: "
  docker stop $consul_server 2>/dev/null
  test $? -eq 0 || echo "no any"
  echo -n "Removing container: "
  docker rm $consul_server 2>/dev/null
  test $? -eq 0 || echo "no any"
  docker ps -a | grep $consul_server
  touch $logfile
  echo --------------
  echo
}

init() {
  echo CTask implementation purposed
  echo -----------------------------
  export consul_server=csrv
  export logfile=all.log
  cleanup
}

csrv_start() {
  echo Starting consul server
  docker pull consul 2>&1 | tee -a $logfile
  docker images -f 'reference=consul'
  docker run \
    -d \
    -p 8500:8500 \
    -p 8600:8600/udp \
    --name=$consul_server \
    consul agent -server -ui -node=server-1 -bootstrap-expect=1 -client=0.0.0.0 2>&1 | tee -a $logfile
}

click1() {

  echo Click 1
  echo -------
  echo 1st click for initializing your environment
  echo -------------------------------------------
  echo Clicking 1...
  echo -------------

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
