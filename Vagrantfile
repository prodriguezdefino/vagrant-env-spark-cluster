VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|  
  config.vm.provider :virtualbox do |vb|
    #memory
    vb.customize ["modifyvm", :id, "--memory", "5120"]
  end
  config.vm.hostname = "env-host.dev"
  config.vm.box = "ubuntu/trusty64"
  config.vm.network "forwarded_port", guest: 4444, host: 4444
  config.vm.provision "docker" do |d|
    d.run "prodriguezdefino/spark-1.2.0-standalone",
      daemonize: true
  end 
end
