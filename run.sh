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
  #  touch $logfile

  echo Wiping Jenkins home...
  echo ----------------------
  echo "Press any key to wipe ${jenkins_home}"
  read
  rm -rf $jenkins_home
  echo
}

getImages() {
  echo Pulling images
  echo ">>>>>>>>>>>>>>"
  docker pull consul | tee -a $logfile &>/dev/null
  docker pull jenkins/jenkins:lts-jdk11 | tee -a $logfile &>/dev/null
  docker images -f 'reference=consul' | tee -a $logfile &>/dev/null
}

init() {
  echo CTask implementation purposed
  echo -----------------------------
  export consul_server=csrv
  export consul_client=clnt
  export jenkins=jenkins
  export logfile=all.log
  export jenkins_home=/tmp/jenkins_home
  cleanup
}

serverStart() {

  echo Starting consul server
  echo ">>>>>>>>>>>>>>>>>>>>>>"
  docker run \
    -d \
    -p 8500:8500 \
    -p 8600:8600/udp \
    --name=$consul_server \
    consul agent -server -ui -node=server-1 -bootstrap-expect=1 -client=0.0.0.0 | tee -a $logfile &>/dev/null
  echo
}

clientStart() {
  echo Starting consul client
  echo ">>>>>>>>>>>>>>>>>>>>>>"
  docker run \
    -d \
    --name=${consul_client} \
    consul agent -node=client-1 -join=172.17.0.2 | tee -a $logfile &>/dev/null
  echo
}

jenkinsStart() {
  echo Starting Jenkins
  echo ">>>>>>>>>>>>>>>>"
  mkdir -vp $jenkins_home
  docker run \
    -d \
    -p 8080:8080 -p 50000:50000 \
    --name=$jenkins \
    -v $jenkins_home:/var/jenkins_home \
    jenkins/jenkins:lts-jdk11 | tee -a $logfile &>/dev/null
  echo
}

click1() {

  echo Click 1
  echo -------
  echo 1st click for initializing your environment
  echo -------------------------------------------
  echo Clicking 1...
  echo -------------

  getImages
  serverStart
  clientStart
  jenkinsStart
}

justwaiting() {
  #  docker ps
  echo "waiting ${1} seconds"
  sleep "${1}"
  echo
}

jenkinsBanner() {
  echo "Enter below passphrase in http://localhost:8080/ and then install suggested plugins"
  cat /tmp/jenkins_home/secrets/initialAdminPassword
}

init
click1
justwaiting 5
jenkinsBanner
echo "Press any key to stop containers and cleanup"
read
cleanup $consul_server
cleanup $consul_client
cleanup $jenkins
