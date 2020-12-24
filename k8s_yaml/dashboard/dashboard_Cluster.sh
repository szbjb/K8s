#!/bin/bash
#  net=$(ls  -l /etc/sysconfig/network-scripts/ifcfg-*|awk   -F  "-" '{print  $NF}'|grep -v lo)
#  IP=$(for var in $net;do ifconfig $var 2>/dev/null;done|grep inet|grep -v  inet6|awk  '{print $2}')
IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."$3}')) ||IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."}'))

 SHELL_FOLDER=$(dirname "$0")
 cd  $SHELL_FOLDER;pwd
#  alias kubectl="/usr/local/bin/kubectl -s http://${IP}:8080"
#给master打标签定向调度到master(本机)
kubectl label node $IP  dashboard=master
#
kubectl create -f dashboard-rabc.yaml
kubectl create -f dashboard-controller.yaml
kubectl create -f dashboard-service.yaml

#检查
kubectl cluster-info
kubectl get pod -o wide -n kube-system
kubectl get svc -o wide -n kube-system 



# kubectl delete -f dashboard-rabc.yaml
# kubectl delete -f dashboard-controller.yaml
# kubectl delete -f dashboard-service.yaml

