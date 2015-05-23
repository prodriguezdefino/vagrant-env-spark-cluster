#!/bin/bash

if [ -z "$1" ]
  then
    echo "No argument supplied, worker name needed."
    exit 1
fi

# inspect the container to extract the IP of our DNS server
DNS_IP=$(sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' skydns)

echo "Starting worker node $1.sparkworker.dev.docker ..."
echo "******************************************************"
# launch a slave node (with a worker and a datanode in it)
sudo docker run -itd --name=$1 -h $1.sparkworker.dev.docker --dns=$DNS_IP -e "http_proxy=$http_proxy" -e "https_proxy=$https_proxy" prodriguezdefino/sparkworker
echo " "
