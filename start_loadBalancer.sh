#!/bin/bash
cd deploy/loadBalancerServer/ddslConfigWriter
FULL_PATH=`pwd`
echo "Starting nginx"
nginx -s stop > /dev/null 2>&1
nginx -c $FULL_PATH/generatedConfig.conf
sbt -DDDSL_CONFIG_PATH=../ddsl_config.properties run

