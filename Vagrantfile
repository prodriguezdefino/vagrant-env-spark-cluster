VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|  
  config.vm.provider :virtualbox do |vb|
    vb.memory = 5120
    vb.cpus = 2
    vb.name = "cluster-env-host.dev"
  end
  config.vm.hostname = "cluster-env-host.dev"
  config.vm.box = "ubuntu/trusty64"

  # hadoop base ports in master
  config.vm.network "forwarded_port", guest: 50020, host: 50020
  config.vm.network "forwarded_port", guest: 50090, host: 50090
  config.vm.network "forwarded_port", guest: 50070, host: 50070
  config.vm.network "forwarded_port", guest: 50010, host: 50010
  config.vm.network "forwarded_port", guest: 50075, host: 50075
  config.vm.network "forwarded_port", guest: 8031, host: 8031
  config.vm.network "forwarded_port", guest: 8032, host: 8032
  config.vm.network "forwarded_port", guest: 8033, host: 8033
  config.vm.network "forwarded_port", guest: 8040, host: 8040
  config.vm.network "forwarded_port", guest: 8042, host: 8042
  config.vm.network "forwarded_port", guest: 49707, host: 49707
  config.vm.network "forwarded_port", guest: 8088, host: 8088
  config.vm.network "forwarded_port", guest: 8030, host: 8030
  # spark master node
  config.vm.network "forwarded_port", guest: 7077, host: 7077
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  # spark worker node 
  config.vm.network "forwarded_port", guest: 8888, host: 8888
  config.vm.network "forwarded_port", guest: 4040, host: 4040
  config.vm.provision "docker"
  # docker remote api port
  config.vm.network "forwarded_port", guest: 4444, host: 4444

  config.vm.provision :shell, inline: <<-SCRIPT
    echo "Setting env variables..."
    echo "************************"
    echo " "

    # set a nameserver to forward anything outside .docker domain 
    sh -c 'echo "export fwd_dns="8.8.8.8"" >> .bashrc' 
    # set web proxy servers if needed
    sh -c 'echo "export http_proxy=""" >> .bashrc' 
    sh -c 'echo "export https_proxy=""" >> .bashrc' 
  SCRIPT

  config.vm.provision "docker",
    images: ["crosbymichael/skydns","crosbymichael/skydock","prodriguezdefino/sparkmaster","prodriguezdefino/sparkworker"]

  config.vm.provision :shell, inline: <<-SCRIPT
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
        
  SCRIPT
end
