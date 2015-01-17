#Vagrant + Docker environment for Spark standalone testing

This environment will allow us to run Spark on a standalone environment configurated using:
 - Vagrant
 - Docker
 - prodriguezdefino/spark-1.2.0-standalone

All the tests and installation was realized in an OSX machine, but it should be fairly easy to replicate for Windows or Linux boxes (using binaries or with a package manager). 

To start we need to install in a dev machine VirtualBox and Vagrant, those two will allow us to virtualize a machine in a repeteable and easy way.

Installing VirtualBox it's easy, it can be downloaded from [here](https://www.virtualbox.org/wiki/Downloads).

Vagrant can be found in this [url](https://www.vagrantup.com/downloads.html). 

In the root directory you can find the Vagrantfile which contains the information needed by Vagrant to startup the virtual machine with the desired configuration. Our example will pull an Ubuntu image, will install it, then it will install Docker in the newly created box to finally pull the Docker image to create our Spark environment.

Running in the console ```vagrant up --provision``` will do the trick. If it's the first time it will take a while since it needs to download everything from the remote repositories.

After the machine completed the installation of the needed components we can log into the spark-host with ```vagrant ssh```. To access the Docker container you can use first ```docker ps``` to find out container's id (first 3 characters will be suficient and then ```docker exec -it <CONTAINER-ID> bash``` to get us a bash interface with the loaded Spark environment (all inside the container).

Then, once in the container bash, we can load up the master's spark console with ```spark-shell --master yarn-client --driver-memory 1g --executor-memory 1g --executor-cores 1``` and start testing the environment with:
```
	val NUM_SAMPLES = 10000000
	val count = sc.parallelize(1 to NUM_SAMPLES).map{i =>
	  val x = Math.random()
	  val y = Math.random()
	  if (x*x + y*y < 1) 1 else 0
	}.reduce(_ + _)
	println("Pi is roughly " + 4.0 * count / NUM_SAMPLES)
```
this will calculate an approximation of Pi, to improve the result increase NUM_SAMPLES variable.

If everything went smoot we can move to something more interesting.

## Testing Spark with a CSV dataset

In the hadoop-2.6.0-base image we added to the Docker container's filesystem a set of CSV files that contains the historical information of the MLB player's statistics from 1930's to 2013. It is not a big dataset (that worth for use this platform), but indeed it will help as an example for this tutorial. Since our Spark image is built based on the Hadoop image the files are available in the filesystem for free.

Okay, lets copy the information of Pitcher's statistics to the hdfs local node.
```
root@037c6175146c:/# hdfs dfs -mkdir /tests
root@037c6175146c:/# hdfs dfs -put /test-data/Pitching.csv /tests/   
```

Now we have available the information inside the hadoop ecosystem, so lets fire up the Spark console to start crunching it.
```
spark-shell --master yarn-client --driver-memory 1g --executor-memory 1g --executor-cores 1
```

So, first up, we need to load the file inside using the Spark context with this command
```
scala> val pitchs = sc.textFile("hdfs:///tests/Pitching.csv")
pitchs: org.apache.spark.rdd.RDD[String] = hdfs:///tests MappedRDD[1] at textFile at <console>:12
```
with this we will be able to operate in the dataset, for example sample the information in it. We'll try to find out the information's schema since this is a CSV file.

If we run the next command in the recently created RDD:
```
scala> pitchs.first
res0: String = playerID,yearID,stint,teamID,lgID,W,L,G,GS,CG,SHO,SV,IPouts,H,ER,HR,BB,SO,BAOpp,ERA,IBB,WP,HBP,BK,BFP,GF,R,SH,SF,GIDP
```
we see the information of the schema of the csv file. In our examples we'll focus on the playerID (player's name'ish, index = 0), yearID (the year, index = 1), teamID (initials of the team's name, index = 3), W (total wins of the season, index = 5), SV (games saved, , index = 11) and ERA (earned runs average per 9 innings, index = 19).

Next up, lets find out which pitchers played more seasons, like a top 10 or so. Since each line is a season for each player in a team we can do:
```
scala> pitchs.map(_.split(",")).map(l => (l(0),1)).reduceByKey(_+_).sortBy(_._2,false).take(10).foreach(println)
(newsobo01,29)
(kaatji01,28)
(johnto01,28)
(moyerja01,27)
(carltst01,27)
(ryanno01,27)
(niekrph01,26)
(oroscje01,26)
(wilheho01,26)
(houghch01,26)
```
Lets recap the last sentence, first we take all the file lines and splited them forming a list of arrays (basically each data in the file like a matrix), next we map every array in the list taking just the first element (the name of the player) and put a 1 counting its appearance in a season, then we reduce the pair list using the key (in this case the name) summing each appearance, to then order it by the appearance (second element in the pair) to finally take the top ten and print them. Sweet.

Some can say "hey! what happens if a player gets traded in mid-season?", clever, if a player gets traded then he must have two entries with different teams in the same year. So lets group the by year and then do the same calculation again. 
```
scala> pitchs.map(_.split(",")).groupBy(_(1)).flatMap(l=>l._2).map(l=>(l(0),1)).reduceByKey(_+_).sortBy(_._2,false).take(10).foreach(println)
(newsobo01,29)
(kaatji01,28)
(johnto01,28)
(moyerja01,27)
(carltst01,27)
(ryanno01,27)
(wilheho01,26)
(houghch01,26)
(weathda01,26)
(mulhote01,26)
```
With some trickery we grouped by year and then flatten the results (since after grouping we got a list of pairs, with the second element being our player's annual stats), to finally calculate the result. Luckily the results are the same, but good catch.

Next, how many games saved Mariano Rivera in its career? 
```
scala> pitchs.map(_.split(",")).filter(_(0).startsWith("riverma")).map(l=>(l(0),Integer.valueOf(l(11)))).reduceByKey(_+_).collect().foreach(println)
(riverma01,652)
```

And how many wins Greg Maddux earn in 1993 season?
```
scala> pitchs.map(_.split(",")).filter(p=>p(0).startsWith("maddugr") && p(1).equals("1993")).map(l=>(l(0),Integer.valueOf(l(5)))).reduceByKey(_+_).collect().foreach(println)
(maddugr01,20)
```

Finally, what's the career ERA for Pedro Martinez while playing for Boston?
```
scala> pitchs.map(_.split(",")).filter(p=>p(0).startsWith("martipe") && p(3).equals("BOS")).map(l=>(l(0),Integer.valueOf(l(5)))).max()
res60: (String, Integer) = (martipe02,23)
```

Hope this examples help, thanks =P
