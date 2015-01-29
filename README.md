#Vagrant + Docker environment for Spark cluster testing

This environment will allow us to run Spark on a cluster environment made of docker containers using:
 - Vagrant
 - Docker
 - [rosbymichael/skydns](https://github.com/crosbymichael/skydns), for DNS management and service discovery registry between containers
 - [crosbymichael/skydock](https://github.com/crosbymichael/skydock), for container event listening and to propagate info to our service discovery registry
 - [prodriguezdefino/sparkmaster](https://github.com/prodriguezdefino/docker-spark-master), will coordinate worker/slaves nodes
 - [prodriguezdefino/sparkworker](https://github.com/prodriguezdefino/docker-spark-worker), as many as needed to make calculations
 - [prodriguezdefino/sparkshell](https://github.com/prodriguezdefino/docker-spark-shell), to use as the driver (interactive shell or submitter) in the cluster

All the tests and installation was realized in an OSX machine, but it should be fairly easy to replicate for Windows or Linux boxes (using binaries or with a package manager). 

To start we need to install in a dev machine VirtualBox and Vagrant, those two will allow us to virtualize a machine in a repeteable and easy way.

Installing VirtualBox it's easy, brew it or it can be downloaded from [here](https://www.virtualbox.org/wiki/Downloads).

Vagrant can be found in this [url](https://www.vagrantup.com/downloads.html) or you can brew it yoursef. 

In the root directory there is a Vagrantfile which contains the information needed by Vagrant to startup the virtual machine with the desired configuration. Our example will pull an Ubuntu image, will install it, then it will install Docker in the newly created box, then will pull the Docker images and finally will run some scripts to configure our Spark environment.

Running in the console ```vagrant up --provision``` will do the trick. If it's the first time it will take a while (several minutes!, depending on the network available bandwidth) since it needs to download everything from the remote repositories.

After the machine completed the installation of the needed components we can log into the spark-host with ```vagrant ssh```. To access the Docker container you can use first ```docker ps``` to find out the shell container's id (first 3 characters will be suficient) and then ```docker exec -it <CONTAINER-ID> bash``` to get us a bash interface with the spark shell environment ready to be launched.

Then, once in the container bash, we can load up the master's spark console with ```$RUN_SPARK_SHELL master.sparkmaster.dev.docker``` (since by default that's the address on where the master node register itself) and start testing the environment with:
```
	val NUM_SAMPLES = 10000000
	val count = sc.parallelize(1 to NUM_SAMPLES).map{i =>
	  val x = Math.random()
	  val y = Math.random()
	  if (x*x + y*y < 1) 1 else 0
	}.reduce(_ + _)
	println("Pi is roughly " + 4.0 * count / NUM_SAMPLES)
```
this will calculate an approximation of Pi (the old "throwing darts calculus" example), to improve the result increase NUM_SAMPLES variable.

If everything went smoot we are good to go. We can continue testing the environment with the CSV stuff in the [standalone environment project](https://github.com/prodriguezdefino/vagrant-env-spark-standalone).

## Launching multiple workers

Once the environment is up and running we can fire up new workers using the next command ```docker run -itd --name=slaveXX -h slaveXX.sparkworker.dev.docker --dns=$DNS_IP prodriguezdefino/sparkworker:1.2.0``` changing XX with something that identifies each new worker/slave node. 

Since this is a dynamic environment each running container (old and new ones) need to be aware of the join-to-cluster event, so the worker nodes will ssh to the master node to add themselves as datanodes in the ```slaves``` file in the hadoop config folder in the master node, also each new container need to have configured the flag ```--dns=XXX``` pointing to our DNS container in order to be able to discover IPs in the network. To find out the DNS ip we can run ```DNS_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' skydns)``` in order to store it in a variable. 

## How everything gets tied up

Docker by itself is not able to "discover" what's inside its own network, he can connect to any container running inside docker deamon but just by knowing the IP, so it needs to be configured in advance to know "who" is on the network. Doing that is fair simple, use the ```--link``` flag at container spawn time will do the trick, but in a dynamic or complex topology that could be very cumbersome (and even not possible).

To avoid that this environment uses SkyDock image to listen Docker events (image creation/destruction and container creation/start/stop/destruction) in order to register them in the SkyDns container that runs alongside. For more information on this visit the project [page](https://github.com/crosbymichael/skydock).

So, we start up a master with an specific name and hostname (carefully picked so when SkyDock register the event will use the same one) and let every other running container run with that hostname in order to be able to connect. Since every node in the topology needs to talk to each other, it is really difficult to boot all needed images in order to achieve that, that's why the DNS appears as an appealing (and very simple) service discovery solution. 

## Monitoring

Since we open an mapped some ports for the VM and also for the containers, we are able to view progress of the spark jobs in the shell web console at http://localhost:4040 (note that the shell container must be up and with a spark console running). Also we can access to the Spark master node console in http://localhost:8080 and as a cherry on top the Hadoop namenode info page in http://localhost:50070. 

## Disclaimer

Since the download time of all the needed images can take several minutes, it's recommended to boot up vagrant using a clabe connection, maybe at night (stop any torrents) or with a big bowl of coffe at hand. 

Other possibility is to build the images inside a vanilla Vagrant image (the provided one can be modified for that purpose), one by one, to load them in the next order: skydns, skydock, master, worker, shell. 