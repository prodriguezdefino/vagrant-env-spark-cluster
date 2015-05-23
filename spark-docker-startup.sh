#!/bin/bash

    echo "Setting env variables..."
    echo "************************"
    echo " "

    # set a nameserver to forward anything outside .docker domain 
    export fwd_dns="8.8.8.8"
    # set web proxy servers if needed
    export http_proxy="" 
    export https_proxy="" 

    echo "Provisioning Docker..."
    echo "**********************"
    echo " "

    sudo sh -c 'echo "DOCKER_OPTS=\"-H tcp://0.0.0.0:4444 -H unix:///var/run/docker.sock\"" >> /etc/default/docker'
    sudo restart docker
    sleep 5
    echo " "

    echo "Starting containers..."
    echo "**********************"
    echo " "
    echo "cleaning up..."
    echo "**************"
    sudo docker stop $(sudo docker ps -qa)
    sudo docker rm $(sudo docker ps -qa)
    echo " "
    
    # first find the docker0 interface assigned IP
    DOCKER0_IP=$(ip -o -4 addr list docker0 | awk '{split($4,a,"/"); print a[1]}')
    
    echo "Starting dns regristry..."
    echo "*************************"
    # then launch a skydns container to register our network addresses
    sudo docker run -d -p $DOCKER0_IP:53:53/udp --name skydns crosbymichael/skydns -nameserver $fwd_dns:53 -domain docker
    echo " "
    
    # inspect the container to extract the IP of our DNS server
    DNS_IP=$(sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' skydns)
    
    echo "Starting docker event listener..."
    echo "*********************************"
    # launch skydock as our listener of container events in order to register/deregister all the names on skydns
    sudo docker run -d -v /var/run/docker.sock:/docker.sock --name skydock crosbymichael/skydock -ttl 30 -environment dev -s /docker.sock -domain docker -name skydns
    echo " "
    
    echo "Starting master node master.sparkmaster.dev.docker ..."
    echo "******************************************************"
    # launch our master node (hadoop master stuff and also spark master server)
    sudo docker run -itd --name=master -h master.sparkmaster.dev.docker -p 8080:8080 -p 50070:50070 -p 8088:8088 --dns=$DNS_IP -e "http_proxy=$http_proxy" -e "https_proxy=$https_proxy" prodriguezdefino/sparkmaster
    echo " "
    sleep 10
    echo "Starting worker node slave1.sparkworker.dev.docker ..."
    echo "******************************************************"
    # launch a slave node (with a worker and a datanode in it)
    sudo docker run -itd --name=slave1 -h slave1.sparkworker.dev.docker --dns=$DNS_IP -e "http_proxy=$http_proxy" -e "https_proxy=$https_proxy" prodriguezdefino/sparkworker
    echo " "
