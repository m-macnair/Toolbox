#!/bin/bash
apt install -y build-essential libpcre3 libpcre3-dev libssl-dev zlib1g-dev
wget http://nginx.org/download/nginx-1.15.1.tar.gz
wget https://github.com/sergey-dryabzhinsky/nginx-rtmp-module/archive/dev.zip
tar -xf nginx-1.15.1.tar.gz
unzip dev.zip
cd nginx-1.15.1
