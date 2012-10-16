cd deploy/loadBalancerServer
git clone https://github.com/mbknor/ddslConfigWriter
cp config.properties ddslConfigWriter/
cp generatedConfig.conf ddslConfigWriter/
cd ddslConfigWriter
sbt compile
