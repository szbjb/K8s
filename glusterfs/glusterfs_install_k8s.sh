
#!/bin/bash

grep  "\."  /root/K8s/ip_db.txt||{
echo  "所选存储节点无可用块设备,k8s集群持久化部署终止Heketi+GlusterFS"
exit 4
}
ansible  all -m shell -a  "yum -y install glusterfs-fuse"
ansible all  -m shell -a  "modprobe dm_snapshot;modprobe dm_mirror;modprobe dm_thin_pool"
#下载heketi客户端工具.master节点执行
cd  /root/K8s/glusterfs/
tar  xzvf heketi-client-v9.0.0.linux.amd64.tar.gz
cp -ar heketi-client/share/heketi/  /usr/local/share/
cp -ar heketi-client/bin/heketi-cli  /usr/local/bin/
cp -ar heketi-client/bin/heketi-cli  /usr/bin/


#给需要部署GlusterFS节点的Node打上标签
for i in $(sed   '$d'  /root/K8s/ip_db.txt)
do
kubectl label node  ${i} storagenode=glusterfs
done
#部署glusterfs
kubectl create -f glusterfs-daemonset.json
#部署heketi server端
kubectl create -f heketi-service-account.json
kubectl create clusterrolebinding heketi-gluster-admin --clusterrole=edit --serviceaccount=default:heketi-service-account
kubectl create secret generic heketi-config-secret --from-file=./heketi.json
kubectl create -f heketi-bootstrap.json
##等待期
while  [ true ]; do  
var_01=$(kubectl  get pods   | egrep  "heketi|glusterfs"|wc  -l)
var_02=$(kubectl  get pods   | egrep  "heketi|glusterfs"|grep Running|wc -l)
echo "等待heketi,glusterfs启动完毕$(date |xargs -n 1 |grep  :)"
sleep 0.5
[[  $var_01  =  $var_02 ]] && break  1   ;done


heketi_sv_ip=$(kubectl get svc| grep   deploy-heketi|awk   '{print $3}')
export HEKETI_CLI_SERVER=http://${heketi_sv_ip}:8080

cat > topology-sample.json  << 'EOF'
{
  "clusters": [
    {
      "nodes": [
      ]
    }
  ]
}
EOF
#文件格式处理
disk_var01=$(tail -n 1 /root/K8s/ip_db.txt)
for db_IP  in $(sed  '$d'  /root/K8s/ip_db.txt)
    do 
    sed "/\"nodes\": \[/a\{ \"node\": { \"hostnames\": { \"manage\": [ \"$db_IP\" ], \"storage\": [ \"$db_IP\" ] }, \"zone\": 1 }, \"devices\": [ \"/dev/${disk_var01}1\" ] }," topology-sample.json  -i
done
NR=$(grep  -n  '},'  topology-sample.json |tail -n 1|awk  -F  ':'  '{print  $1}')
sed "${NR}s/\,$//" topology-sample.json -i
cat topology-sample.json
while  [ true ]; do  heketi-cli topology load --json=topology-sample.json   && break  1   ;done

# echo 调试模式300000秒
# sleep  300000


#Heketi生产化,Heketi数据持久化到glusterfs

echo $HEKETI_CLI_SERVER
heketi-cli topology load --json=topology-sample.json

#将生成heketi-storage.json文件
heketi-cli setup-openshift-heketi-storage  ||{
echo 'Error: Failed to allocate new volume: No spac'
echo 'Heketi持久化失败'
exit 2
}
sed   's/heketi:dev/heketi:latest/g'  -i  heketi-storage.json
 kubectl create -f heketi-storage.json
 #等到job完成后，删除bootstrap Heketi实例相关的组件：
# kubectl get job |grep '1\/1'  && kubectl delete all,service,jobs,deployment,secret --selector="deploy-heketi"
 while  [ true ]; do  
 kubectl get job |grep '1\/1'   && break  1 
  kubectl get job
echo "等待等到job完成删除bootstrap Heketi实例相关的组件$(date |xargs -n 1 |grep  :)"
sleep 0.5
done
kubectl delete all,service,jobs,deployment,secret --selector="deploy-heketi" 
  
kubectl create -f heketi-deployment.json 
 
heketi_sv_ip=$(kubectl get svc| grep   heketi| grep 8080|awk   '{print $3}')
export HEKETI_CLI_SERVER=http://${heketi_sv_ip}:8080
# heketi-cli topology load --json=topology-sample.json
while  [ true ]; do  heketi-cli topology load --json=topology-sample.json   && break  1   ;done


#测试创建一个storage class
var_replicate_01=$(sed  '$d'  /root/K8s/ip_db.txt|wc -l)
if [[ $var_replicate_01 -ge 3 ]]  
  then 
      echo  节点数大于或等于3,副本数为3
      var_replicate=3 
  else 
        echo  节点数小于3,副本数为2
      var_replicate=2
fi
cat >gluster-storage-class.yaml  << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gluster-heketi                        #-------------存储类的名字
provisioner: kubernetes.io/glusterfs
parameters:
  resturl: "$HEKETI_CLI_SERVER"       #-------------heketi service的cluster ip 和端口
  restuser: "admin"                           #-------------heketi的认证用户，这里随便填，因为没有启用鉴权模式
  gidMin: "40000"
  gidMax: "50000"
  volumetype: "replicate:${var_replicate}"
EOF
kubectl  apply  -f  gluster-storage-class.yaml
#创建一个pvc
cat   >gluster-pvc.yaml   <<'EOF'
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: gluster1-test
  annotations:
    volume.beta.kubernetes.io/storage-class: gluster-heketi    #----------上面创建的存储类的名称
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi

EOF

kubectl  apply  -f  gluster-pvc.yaml
#
kubectl get  pvc






