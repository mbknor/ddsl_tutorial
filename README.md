DDSL Tutorial
==============


Summary
==============

In this tutorial we are going to setup an nginx load balancer in front of a web application which runs on multiple servers. The load balancer will automatically reconfigure when new web application-instances are brought up without any manually configuration. We are going to use DDSL which relies on Apache ZooKeeper for.

This tutorial is only going to use one physical server - your own - and will "emulate" different servers by starting servers on different ports.

A DDSL-enabled application will broadcast its presense when it starts up. It will identify itself with a ServiceID (environment, type, name, version) and will 
 and DDSL will automatically remove it when the application quits, crashes or goes offline due to network issues. Other applications can then find applications by querying DDSL for it. When querying DDSL for applications

This tutorial will show you how to set up a system with any number of webapp-servers spread around multiple "physical" servers

In this tutorial we are going to configure a server- and application-setup where the "only" predefined configuration is a shared ZooKeeper network. Apache ZooKeeper is a robust distributed information-storage with no single point of failure; it continues to operate as long as more than half of the ZooKeeper nodes are working.

ZooKeeper
==============
When using DDSL - everything is cordinated via ZooKeeper. We can set up a ZooKeeper network with any number of nodes, and as long as at least half of the nodes work, the network works. Sinse DDSL stores all needed info in ZooKeeper we have no single point of failure.

In this tutorial we are only going to use one ZooKeeper node.

If you do not already have ZooKeeper installed - do so.

If you are on Mac you can installed it using **brew** like this:

	brew install zookeeper

Then we must start it. Open a new tab in Terminal and start it in the foreground like this:

	zkServer start-foreground

The only DDSL specific configuration needed is to tell it about the ZooKeeper network you are using.


Starting the first server
==============

I have created a simple Play Framework 2.0 application located in the apiServer-folder. All it does is to listen to a port, and returning an informative string for all request:

	ApiServer: Answer from 10.0.0.7:9000 (ts: 1350421595931)

We are going to use this application as our web application in this tutorial.

DDSL do provide a really simple Java/Scala client so it is really easy to integrate it into any application.

Before we can start it, we must unzip it.

	chmod u+x install_appServers.sh
	./install_appServers.sh

In a new terminal, start apiServer1:

	chmod u+x start_apiServer1.sh
	./start_apiServer1.sh

You will see this output:

	Play server process ID is 20710
	[info] application - DDSL loading config from application.conf. using ddsl.environment=test. client read cache: 1000 mills
	[info] application - DDSL (application.conf) using ddsl.zkhostslist=localhost:2181
	[info] application - Registering this service as Up. ServiceID: ServiceId(test,http,ApiServer,1.0) ServiceLocation: ServiceLocation(http://10.0.0.7:10000/,0.0,2012-10-16T23:19:18.306+02:00,null)
	[info] play - Application started (Prod)
	[info] play - Listening for HTTP on port 10000...

As you can see, our "apiServer1" is up and running listening on port 10000. It has been configured to use the ZooKeeper network consisting of our single node: 

	ddsl.zkhostslist=localhost:2181.

When the app started, it told DDSL about its pressense. When it registered to DDSL, it suplied the following info about the service:

** Environment: test
** Service-Type: http
** Service-name: ApiServer
** Service-version: 1.0

All this information is 100% chosen by the application itself.

In plaintext it means that it is running in test environment, not production. This is used to create different namespace for different environments - usefull if you decide to run test and prod on the same infrastructure. 

It also says its service is of type http - this is only a string which can have any value - can be usefull if you have to registere multiple types of a service - eg: http, soap, ..

The name of the service is 'ApiServer' and it is of version '1.0'

This info is needed when other services are asking for this specific service.

It also told DDSL its ServiceLocation: http://10.0.0.7:10000/

Since our application is using the Play Framework 2.0 DDSL Module we have automatically "discovvered" the url, but an app can easy supply the url manually.

Starting the Load Balancer server
==============

In this tutorial we are going to have a "dedicated server" running **nginx** as our loadbalancer.

If you have not already installed nginx, you can do it like this on Mac:

	brew install nginx

We are going to use [ddslConfigWriter](https://github.com/mbknor/ddslConfigWriter) to read info about online services and automatically reconfigure nginx when something changes.

We must now download and build ddslConfigWriter. It uses sbt so we have to install that too:

	brew install sbt
	chmod u+x install_ddslConfigWriter.sh
	./install_ddslConfigWriter.sh

Now we must start our load balancer "server" which will start nginx listening on port 7080:

	chmod u+x start_loadBalancer.sh
	./start_loadBalancer.sh

nginx is now configured to forward all traffic comming to 7090 to our single apiServer

If you use your browser and go to:

	http://localhost:7090

You should get a result like this:

	ApiServer: Answer from 10.0.0.7:10000 (ts: 1350426635670)

If you look at the nginx config file **deploy/loadBalancerServer/ddslConfigWriter/generatedConfig.conf** you would see this:

	upstream ddsl_services {
		server 10.0.0.7:10000;
	}



Starting the second server
==============

This is starting the same application as server1, but this time listening on port 20000

In a new terminal, start apiServer2:

	chmod u+x start_apiServer2.sh
	./start_apiServer2.sh

Within maximum 10 seconds our load balancer will be reconfigured to also forward trafic to this server.

If you refresh **http://localhost:7090** multiple times in your browser you will see you get results from both server.

The nginx config file now looks somethins like:

	upstream ddsl_services {
		server 10.0.0.7:10000;
		server 10.0.0.7:20000;
	}

You can now kill (ctrl+C) server 2, and do some more requests in the browser - now you only get anwers from server1.

If you like, you can modify the http.port in start_apiServer2.sh to something else, then start it again.
