#!/usr/bin/env bash

cleanup() {
  echo Cleanup "${1}"...
  echo ---------------------------
  echo -n "Stopping container: "
  docker stop "${1}" 2>/dev/null
  test $? -eq 0 || echo "no any"
  echo -n "Removing container: "
  docker rm "${1}" 2>/dev/null
  test $? -eq 0 || echo "no any"
#  docker ps -a | grep "${1}"
  touch $logfile
  echo ---------------------------
  echo
}

getImage() {
  echo Pulling image
  docker pull consul | tee -a $logfile &>/dev/null
  docker images -f 'reference=consul' | tee -a $logfile &>/dev/null
}

init() {
  echo CTask implementation purposed
  echo -----------------------------
  export consul_server=csrv
  export consul_client=ccli
  export logfile=all.log
  cleanup
}

server_start() {

  echo Starting consul server
  echo ">>>>>>>>>>>>>>>>>>>>>>"
  docker run \
    -d \
    -p 8500:8500 \
    -p 8600:8600/udp \
    --name=$consul_server \
    consul agent -server -ui -node=server-1 -bootstrap-expect=1 -client=0.0.0.0 | tee -a $logfile &>/dev/null
}

client_start() {
  echo Starting consul client
  echo ">>>>>>>>>>>>>>>>>>>>>>"
  docker run \
    -d \
    --name=${consul_client} \
    consul agent -node=client-1 -join=172.17.0.2 | tee -a $logfile &>/dev/null
  echo
}

click1() {

  echo Click 1
  echo -------
  echo 1st click for initializing your environment
  echo -------------------------------------------
  echo Clicking 1...
  echo -------------

  getImage
  server_start
  client_start
}

justwaiting() {
  #  docker ps
  echo "waiting ${1} seconds"
  sleep "${1}"
}

init
click1
justwaiting 3
cleanup $consul_server
cleanup $consul_client
