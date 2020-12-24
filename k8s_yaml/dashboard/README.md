#启用dashboard,暴露端口42346,内部80
kubectl create -f dashboard-rabc.yaml
kubectl create -f dashboard-controller.yaml
kubectl create -f dashboard-service.yaml

<!-- #创建本地yum _nginx仓库
kubectl label nodes $IP disktype=master
kubectl create -f   /root/K8s/shell_01/nginx_yum_sevice.yaml
kubectl create -f   /root/K8s/shell_01/nginx_yum.yaml
echo "内网yum端口42346"
echo "内网yum路径/data/nginx/yum" -->

#检查
kubectl cluster-info
kubectl get pod -o wide -n kube-system
kubectl get svc -o wide -n kube-system 