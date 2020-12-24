#!/bin/bash
IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."$3}')) ||IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."}'))
#
grep  "\."  /root/K8s/ip_db.txt||{
echo  "所选存储节点无可用块设备,k8s集群持久化部署终止Heketi+GlusterFS"
exit 4
}

ansible  master     -m shell -a  "yum install  -y  glusterfs glusterfs-server glusterfs-common glusterfs-fuse glusterfs-rdma glusterfs-cli glusterfs-geo-replication glusterfs-devel   --skip-broken"
ansible  master     -m shell -a  "systemctl restart glusterd.service;systemctl enable glusterd.service;systemctl status glusterd.service"
ansible  db      -m shell -a  "yum install  -y  glusterfs glusterfs-server glusterfs-common glusterfs-fuse glusterfs-rdma glusterfs-cli glusterfs-geo-replication glusterfs-devel   --skip-broken"
ansible  db      -m shell -a  "systemctl restart glusterd.service;systemctl enable glusterd.service;systemctl status glusterd.service"
ansible  all     -m shell -a  "modprobe dm_snapshot;modprobe dm_mirror;modprobe dm_thin_pool"
# yum install -y heketi heketi-client
# sed  's/8080/8088/g'   /etc/heketi/heketi.json   -i
# systemctl enable heketi ;systemctl restart heketi; systemctl status heketi
cd  /root/K8s/Software_package/
tar xzf heketi-v*.linux.amd64.tar.gz
mkdir -pv /data/heketi/{bin,conf,data}
cp -v heketi/heketi.json /data/heketi/conf/
cp -v heketi/{heketi,heketi-cli} /data/heketi/bin/
cat > /data/heketi/conf/heketi.json<<EOF
{
  "_port_comment": "Heketi Server Port Number",
  "port": "18080",

  "_use_auth": "Enable JWT authorization. Please enable for deployment",
  "use_auth": true,

  "_jwt": "Private keys for access",
  "jwt": {
    "_admin": "Admin has access to all APIs",
    "admin": {
      "key": "adminkey"
    },
    "_user": "User only has access to /volumes endpoint",
    "user": {
      "key": "userkey"
    }
  },

  "_glusterfs_comment": "GlusterFS Configuration",
  "glusterfs": {
    "_executor_comment": [
      "Execute plugin. Possible choices: mock, ssh",
      "mock: This setting is used for testing and development.",
      "      It will not send commands to any node.",
      "ssh:  This setting will notify Heketi to ssh to the nodes.",
      "      It will need the values in sshexec to be configured.",
      "kubernetes: Communicate with GlusterFS containers over",
      "            Kubernetes exec api."
    ],
    "executor": "ssh",

    "_sshexec_comment": "SSH username and private key file information",
    "sshexec": {
      "keyfile": "/root/.ssh/id_dsa",
      "user": "root",
      "port": "22",
      "fstab": "/etc/fstab"
    },

    "_kubeexec_comment": "Kubernetes configuration",
    "kubeexec": {
      "host" :"https://kubernetes.host:8443",
      "cert" : "/path/to/crt.file",
      "insecure": false,
      "user": "kubernetes username",
      "password": "password for kubernetes user",
      "namespace": "OpenShift project or Kubernetes namespace",
      "fstab": "Optional: Specify fstab file on node.  Default is /etc/fstab"
    },

    "_db_comment": "Database file name",
    "db": "/data/heketi/data/heketi.db",

    "_loglevel_comment": [
      "Set log level. Choices are:",
      "  none, critical, error, warning, info, debug",
      "Default is warning"
    ],
    "loglevel" : "debug"
  }
}
EOF
nohup /data/heketi/bin/heketi --config=/data/heketi/conf/heketi.json &
grep  'heketi'   /etc/rc.local  ||  echo  'nohup /data/heketi/bin/heketi --config=/data/heketi/conf/heketi.json &'  >> /etc/rc.local
alias heketi-cli="/data/heketi/bin/heketi-cli --server \"http://${IP}:18080\" --user \"admin\" --secret \"adminkey\""
#给需要部署GlusterFS节点的Node打上标签
for i in $(sed   '$d'  /root/K8s/ip_db.txt)
do
kubectl label node  ${i} storagenode=glusterfs
gluster peer probe  ${i}
done
gluster peer status

cd /root/K8s/glusterfs/

cat > topology.json  << 'EOF'
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
#文件格式处理
disk_var01=$(tail -n 1 /root/K8s/ip_db.txt)
for db_IP  in $(cat /root/K8s/ip_db.txt |xargs  -n 2|sed  's/ /-/g')
    do
     var_db_ip=$(echo ${db_IP}|awk  -F  '-'   '{print  $1}')
     var_db_dev=$(echo ${db_IP}|awk  -F  '-'   '{print  $2}')
     echo "$分布式存储节点ip${var_db_ip}"
     echo  "$分布式存储设备盘${var_db_dev}"
    sed "/\"nodes\": \[/a\{ \"node\": { \"hostnames\": { \"manage\": [ \"$var_db_ip\" ], \"storage\": [ \"$var_db_ip\" ] }, \"zone\": 1 }, \"devices\": [ { \"name\":\"/dev/${var_db_dev}1\", \"destroydata\": true  } ] },"  /root/K8s/glusterfs/topology.json  -i
    #  sed "/\"nodes\": \[/a\{ \"node\": { \"hostnames\": { \"manage\": [ \"$db_IP\" ], \"storage\": [ \"$db_IP\" ] }, \"zone\": 1 }, \"devices\": [ { \"name\":\"/dev/${disk_var01}1\", \"destroydata\": true  } ] },"  /root/K8s/glusterfs/topology.json  -i
done
NR=$(grep  -n  '},'  /root/K8s/glusterfs/topology.json  |tail -n 1|awk  -F  ':'  '{print  $1}')
sed "${NR}s/\,$//" /root/K8s/glusterfs/topology.json -i
cat /root/K8s/glusterfs/topology.json
nohup /data/heketi/bin/heketi --config=/data/heketi/conf/heketi.json &
sleep 3
while  [ true ]; do  heketi-cli  topology load --json /root/K8s/glusterfs/topology.json  && break  1   ;done


#二次深度检查
heketi-cli   node list
while  [ true ]
      do
        heketi_list=$(heketi-cli   node list|wc  -l)
        db_list=$(ansible db -m ping| grep  SUCCESS|wc  -l)
       [ $heketi_list  -eq $db_list ]  && break  1
       sleep  10
       echo  "根据硬盘性能已经节点数量 此处等待时间较长"
       heketi-cli   node list
       heketi-cli  topology load --json /root/K8s/glusterfs/topology.json

done


# echo 调试模式300000秒
# sleep  300000

#测试创建一个storage class
var_replicate_01=$(grep  '\.' /root/K8s/ip_db.txt|wc -l)
if [[ $var_replicate_01 -ge 3 ]]
  then
      echo  节点数大于或等于3,副本数为3
      var_replicate=3
  else
        echo  节点数小于3,副本数为2
      var_replicate=2
fi


cat  > secret-gfs.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: heketi-secret
  namespace: default
data:
  # base64 encoded password. E.g.: echo -n "mypassword" | base64
  key: YWRtaW5rZXk=
type: kubernetes.io/glusterfs
EOF

kubectl apply -f secret-gfs.yaml    2>/dev/null
if [[ $var_replicate_01 -eq 2 ]]
   then
   echo  节点数大于或等于2,副本数为2
cat >gluster-storage-class.yaml  << EOF
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gluster-heketi
provisioner: kubernetes.io/glusterfs
parameters:
  resturl: "http://${IP}:18080"
  restauthenabled: "true"
  restuser: "admin"
  restuserkey: "adminkey"
  gidMin: "40000"
  gidMax: "50000"
  volumetype: "replicate:${var_replicate}"
EOF
else
cat >gluster-storage-class.yaml  << EOF
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gluster-heketi
provisioner: kubernetes.io/glusterfs
parameters:
  resturl: "http://${IP}:18080"
  restauthenabled: "true"
  restuser: "admin"
  restuserkey: "adminkey"
  gidMin: "40000"
  gidMax: "50000"
  volumetype: "disperse:2:1"
EOF
fi

kubectl  apply  -f  gluster-storage-class.yaml        2>/dev/null
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
      storage: 2Gi

EOF

kubectl  apply  -f  gluster-pvc.yaml                2>/dev/null
#
kubectl get  pvc           2>/dev/null




#新增默认存储类型
kubectl patch storageclass  gluster-heketi  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'   2>/dev/null
