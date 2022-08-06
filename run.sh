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
  mkdir -vp $jenkins_home | tee -a $logfile &>/dev/null
  #  export JAVA_OPTS=-Djenkins.install.runSetupWizard=false
  #  export JENKINS_OPTS=--argumentsRealm.roles.user=admin --argumentsRealm.passwd.admin=admin --argumentsRealm.roles.admin=admin
  docker run \
    -d \
    -p 8080:8080 -p 50000:50000 \
    --env JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
    --env JENKINS_OPTS="--argumentsRealm.roles.user=admin --argumentsRealm.passwd.admin=admin --argumentsRealm.roles.admin=admin" \
    --name=$jenkins \
    -v $jenkins_home:/var/jenkins_home \
    jenkins/jenkins:lts-jdk11 | tee -a $logfile &>/dev/null

  #  while ! nc -z localhost 8080; do
  #    sleep 0.5
  #    echo -n .
  #  done

  echo "Waiting jenkins to launch on 8080..."
#  wget --tries=30 --read-timeout=20 http://localhost:8080/ && echo "Jenkins up and running" && echo ------------------------ && echo "URL is http://localhost:8080/"
  while ! wget http://localhost:8080;  do echo -n .; sleep 1; done | tee -a $logfile &>/dev/null
  echo "Jenkins up and running"

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

jenkinsActivate() {
  echo Jenkins banner:
  echo ---------------

  #  http://localhost:8080/login?from=%2F
  # security-token
  #  echo "Step1: enter below passphrase in http://localhost:8080/ and then install suggested plugins"
  #  echo "Step2: paste there next passphras: $(cat  /tmp/jenkins_home/secrets/initialAdminPassword)"
  #  echo "Step3: push the button 'Install suggested plugins'"

  #  echo "Waiting initialAdminPassword to appear..."
  #
  #  while [ ! -f /tmp/jenkins_home/secrets/initialAdminPassword ]; do
  #    sleep 0.5
  #    echo -n .
  #  done
  #  echo

  #  curl -v -d "security-token=$(cat /tmp/jenkins_home/secrets/initialAdminPassword)" -X POST http://localhost:8080/login?from=%2F

  #  JSESSIONID=$(curl -X GET -sS -H "Authorization: Bearer $SA_TOKEN" -D - "http://localhost:8080" -o /dev/null | grep JSESSIONID | sed "s/^Set-Cookie: \(.*\); Path=\(.*\)$/\1/")

  #  echo "Step1: enter $(cat /tmp/jenkins_home/secrets/initialAdminPassword) in http://localhost:8080/"
  #  echo "Step2: push the button 'Install suggested plugins'"
  #  echo "Step3: user creation: skip and continue as admin"
  #  echo "Step4: keep Jenkins URL as default"
  #  echo "Step5: Save and Finish"

  echo
}

init

wipingJenkinshome

click1
#justwaiting 3
#jenkinsActivate

echo "Press any key to stop containers and cleanup"
read
cleanup $consul_server
cleanup $consul_client
cleanup $jenkins

wipingJenkinshome
