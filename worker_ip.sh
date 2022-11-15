#!/bin/bash
set -x
ip=$1
sudo sed -i "1s/^/$ip k8scp \n/" /etc/hosts
