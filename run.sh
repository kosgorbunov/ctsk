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
  echo
  #  docker ps -a | grep "${1}"
  #  touch $logfile
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
  echo
  export consul_server=csrv
  export consul_client=clnt
  export jenkins=jenkins
  export logfile=all.log
  export jenkins_home=/tmp/jenkins_home
  cleanup $consul_server
  cleanup $consul_client
  cleanup $jenkins
  # TODO declare used ports
  # TODO check if ports not occupied
  # check docker and curl availability
}

wipingJenkinshome() {

  echo Wiping Jenkins home...
  echo ----------------------
  #  echo "Press any key to wipe ${jenkins_home}"
  #  read
  rm -rf $jenkins_home
  echo
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

jenkinsInit() {
  echo Jenkins banner:
  echo ---------------

  #  http://localhost:8080/login?from=%2F
  # security-token
  #  echo "Step1: enter below passphrase in http://localhost:8080/ and then install suggested plugins"
  #  echo "Step2: paste there next passphras: $(cat  /tmp/jenkins_home/secrets/initialAdminPassword)"
  #  echo "Step3: push the button 'Install suggested plugins'"

  curl -v http://localhost:8080/
  justwaiting 1
  curl -v -d "security-token=$(cat /tmp/jenkins_home/secrets/initialAdminPassword)" -X POST http://localhost:8080/login?from=%2F
  echo "Jenkins admin password is: $(cat /tmp/jenkins_home/secrets/initialAdminPassword)"

  echo
}

init

wipingJenkinshome

click1
justwaiting 3
jenkinsInit

echo "Press any key to stop containers and cleanup"
read
cleanup $consul_server
cleanup $consul_client
cleanup $jenkins

wipingJenkinshome
