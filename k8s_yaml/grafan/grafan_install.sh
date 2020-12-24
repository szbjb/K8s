#!/bin/bash
#helm方式安装暴露端口30000
cd  /root/K8s/k8s_yaml/grafan/grafana/  && {
# helm install --name my-grafana  ../grafana   --set  "service.nodePort=30000,admin.password=admin,"   
helm install  my-grafana  ../grafana   --set  "service.nodePort=30000,admin.password=admin,"   
}

#删除命令
# helm delete my-grafana;helm del --purge my-grafana