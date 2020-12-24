#!/bin/bash
#内部dns 域名 http://my-prometheus-prometheus-server.default.svc.cluster.local
#
#删除命令  
# helm delete my-prometheus;helm del --purge my-prometheus

#helm delete my-grafana;helm del --purge my-grafana
cd  /root/K8s/k8s_yaml/prometheus/prometheus/  && {
# helm install --name my-prometheus  ../prometheus   
helm install   my-prometheus  ../prometheus   
}

