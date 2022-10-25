#!/bin/bash
set -x
ip=$(hostname -i)
sudo sed -i "1s/^/$ip k8scp \n/" /etc/hosts
