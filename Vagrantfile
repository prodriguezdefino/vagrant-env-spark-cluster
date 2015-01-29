VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|  
  config.vm.provider :virtualbox do |vb|
    vb.memory = 5120
    vb.cpus = 2
    vb.name = "env-host.dev"
  end
  config.vm.hostname = "env-host.dev"
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
  config.vm.provision "docker"
  # spark driver node
  config.vm.network "forwarded_port", guest: 4040, host: 4040

  config.vm.provision "docker" do |d|
    d.run "prodriguezdefino/sparkstandalone:1.2.0", args: "-p 50070:50070 -p 8080:8080 -p 4040:4040 --name=spark-standalone"
  end 
end
