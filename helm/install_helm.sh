#!/bin/bash
#离线安装Helm，master节点执行
#安装helm
yum install -y socat  
IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."$3}')) ||IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."}'))
tar  -xzvf  /root/K8s/Software_package/helm-v*-linux-amd64.tar.gz   -C    /usr/local/bin/
\cp  -av /usr/local/bin/linux-amd64/helm    /usr/local/bin
rm  -rvf  /usr/local/bin/linux-amd64/
#ansible  all  -m shell -a  "yum install -y socat"

helm  version&& echo  "helm安装成功！！"


