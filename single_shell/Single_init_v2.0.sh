#!/bin/bash
# Deploy the master node.
rpm -aq | grep net-tools   ||  yum install net-tools -y  >   /dev/null
#检测本机master IP地址
IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."$3}')) ||IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."}'))
######
# 工具准备就绪
cd  /root/K8s/Software_package/
cfssl_name01=$(ls    cfssl_*  |head -n 1)
cfssl_name02=$(ls    cfssl-certinfo_* |head -n 1 )
cfssl_name03=$(ls    cfssljson_* |head -n 1 )
etcd_name01=$(ls etcd-*|head  -n 1)
flannel_name=$(ls flannel-*|head  -n 1)
heketi_name=$(ls heketi-*|head  -n 1)
helm_name=$(ls helm-*|head  -n 1)
kubernetes_name=$(ls kubernetes-*|head  -n 1)

for var_name in    $(echo ${cfssl_name01} ${cfssl_name02} ${cfssl_name03} ${etcd_name01}  ${flannel_name}  ${heketi_name}  ${helm_name} ${kubernetes_name})
  do 
  sleep  0.1 
  echo  $var_name
 done 

# cfssl
_cfssl_etcd  () {
rm -rfv  /usr/local/bin/cfssl*
\cp -avr  /root/K8s/Software_package/${cfssl_name01}  /usr/local/bin/cfssl
\cp -avr  /root/K8s/Software_package/${cfssl_name02}  /usr/local/bin/cfssl-certinfo
\cp -avr  /root/K8s/Software_package/${cfssl_name03}  /usr/local/bin/cfssljson

#
chmod +x /usr/local/bin/cfssl*
ETCD_SSL=/etc/etcd/ssl
mkdir -p $ETCD_SSL

cat<<EOF>$ETCD_SSL/ca-config.json
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "www": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF
cat<<EOF>$ETCD_SSL/ca-csr.json
{
    "CN": "etcd CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing"
        }
    ]
}
EOF
cat<<EOF>$ETCD_SSL/server-csr.json
{
    "CN": "etcd",
    "hosts": [
    "${IP}",
    "${IP}"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing"
        }
    ]
}
EOF
cd $ETCD_SSL &&  rm -rvf *.pem
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=www server-csr.json | cfssljson -bare server
cd ~
# ca-key.pem  ca.pem  server-key.pem  server.pem
ls $ETCD_SSL/*.pem

}









####################################################################################
###################################################################################
####################################################################################
####################################################################################
####################################################################################

#02 配置etcd服务
_etcd  ()  {
systemctl  stop  etcd 2> /dev/null
etcd_name01_path=$(echo ${etcd_name01}|sed  's/.tar.gz//g')
mkdir -p  /etc/etcd/
ETCD_CONF=/etc/etcd/etcd.conf
ETCD_SSL=/etc/etcd/ssl
ETCD_SERVICE=/usr/lib/systemd/system/etcd.service
tar -xzf /root/K8s/Software_package/${etcd_name01}  -C /root/K8s/Software_package/
\cp -avr /root/K8s/Software_package/${etcd_name01_path}/etc* /usr/local/bin/

# The etcd configuration file. 
cat>$ETCD_CONF<<EOF
#[Member]
ETCD_NAME="etcd-01"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://${IP}:2380"
ETCD_LISTEN_CLIENT_URLS="http://${IP}:2379"


#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${IP}:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://${IP}:2379"
ETCD_INITIAL_CLUSTER="etcd-01=http://${IP}:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"

EOF

# The etcd servcie configuration file.
cat>$ETCD_SERVICE<<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
EnvironmentFile=$ETCD_CONF
ExecStart=/usr/local/bin/etcd \
--cert-file=/etc/etcd/ssl/server.pem \
--key-file=/etc/etcd/ssl/server-key.pem \
--peer-cert-file=/etc/etcd/ssl/server.pem \
--peer-key-file=/etc/etcd/ssl/server-key.pem \
--trusted-ca-file=/etc/etcd/ssl/ca.pem \
--peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \
--enable-v2=true
Restart=always
RestartSec=5
StartLimitInterval=0
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable etcd.service --now
systemctl status etcd  


}
####################################################################################
####################################################################################
####################################################################################
#ETCD

#安装 Flannel网络
_Flannel  ()  {

KUBE_CONF=/etc/kubernetes
FLANNEL_CONF=$KUBE_CONF/flannel.conf
mkdir -p $KUBE_CONF
tar -xvzf /root/K8s/Software_package/${flannel_name}  -C  /root/K8s/Software_package/
cd  /root/K8s/Software_package/
\cp -avr {flanneld,mk-docker-opts.sh} /usr/local/bin/
# Check whether etcd cluster is healthy.
# old 3.2
# etcdctl \
# --ca-file=/etc/etcd/ssl/ca.pem \
# --cert-file=/etc/etcd/ssl/server.pem \
# --key-file=/etc/etcd/ssl/server-key.pem \
# --endpoints="http://${IP}:2379" cluster-health
#new3.4
etcdctl \
--cacert=/etc/etcd/ssl/ca.pem \
--cert=/etc/etcd/ssl/server.pem \
--key=/etc/etcd/ssl/server-key.pem  \
--endpoints="http://${IP}:2379"  endpoint health
etcdctl \
--cacert=/etc/etcd/ssl/ca.pem \
--cert=/etc/etcd/ssl/server.pem \
--key=/etc/etcd/ssl/server-key.pem  \
--endpoints="http://${IP}:2379"  --write-out=table  endpoint status
# Writing into a predetermined subnetwork.
cd /etc/etcd/ssl
export  ETCDCTL_API=2   

etcdctl \
--ca-file=ca.pem --cert-file=server.pem --key-file=server-key.pem \
--endpoints="http://${IP}:2379" \
set /coreos.com/network/config  '{ "Network": "172.17.0.0/16", "Backend": {"Type": "vxlan"}}'
cd ~

# Configuration the flannel service.
cat>$FLANNEL_CONF<<EOF
FLANNEL_OPTIONS="--etcd-endpoints=http://${IP}:2379 -etcd-cafile=/etc/etcd/ssl/ca.pem -etcd-certfile=/etc/etcd/ssl/server.pem -etcd-keyfile=/etc/etcd/ssl/server-key.pem"
FLANNEL_ETCD_PREFIX="/coreos.com/network"
EOF
cat>/usr/lib/systemd/system/flanneld.service<<EOF
[Unit]
Description=Flanneld overlay address etcd agent
After=network-online.target network.target
Before=docker.service

[Service]
Type=notify
EnvironmentFile=$FLANNEL_CONF
ExecStart=/usr/local/bin/flanneld --ip-masq \$FLANNEL_OPTIONS
ExecStartPost=/usr/local/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/subnet.env
Restart=always
RestartSec=5
StartLimitInterval=0
[Install]
WantedBy=multi-user.target
EOF

# Modify the docker service.
sed -i.bak -e '/ExecStart/i EnvironmentFile=\/run\/flannel\/subnet.env' -e 's/ExecStart=\/usr\/bin\/dockerd/ExecStart=\/usr\/bin\/dockerd $DOCKER_NETWORK_OPTIONS/g' /usr/lib/systemd/system/docker.service

# Start or restart related services.
systemctl daemon-reload
systemctl enable flanneld --now
systemctl restart docker
systemctl status flanneld || systemctl restart  flanneld
systemctl status docker
ip address show


}



#准备k8s相关证书
_cfssl_k8s   ()  {
  

KUBE_SSL=/etc/kubernetes/ssl
mkdir -p $KUBE_SSL

# Create CA.
cat>$KUBE_SSL/ca-config.json<<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF
cat>$KUBE_SSL/ca-csr.json<<EOF
{
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF
cat>$KUBE_SSL/server-csr.json<<EOF
{
    "CN": "kubernetes",
    "hosts": [
      "10.0.0.1",
      "127.0.0.1",
      "${IP}",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF
cd $KUBE_SSL
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes server-csr.json | cfssljson -bare server

# Create kube-proxy CA.
cat>$KUBE_SSL/kube-proxy-csr.json<<EOF
{
  "CN": "system:kube-proxy",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "ST": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy
ls *.pem
cd ~

}




#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
# 3.6.2 安装配置kube-apiserver服务
# 将备好的安装包解压，并移动到相关目录，进行相关配置，执行脚本KubernetesInstall-10.sh。
#master上执行
_kube_apiserver ()  {
KUBE_ETC=/etc/kubernetes
KUBE_API_CONF=/etc/kubernetes/apiserver.conf
tar   xjf  /root/K8s/Software_package/*kubernetes-server-linux-amd64.tar.gz  -C  /root/K8s/Software_package/ 2>/dev/null || {
tar   xzvf  /root/K8s/Software_package/*kubernetes-server-linux-amd64.tar.gz  -C  /root/K8s/Software_package/ 
}
chmod   755  /root/K8s/Software_package/kube-controller-manager    2> /dev/null|| true
\cp -av  /root/K8s/Software_package/kube-controller-manager   /root/K8s/Software_package/kubernetes/server/bin   2> /dev/null|| true
mv /root/K8s/Software_package/kubernetes/server/bin/{kube-apiserver,kube-scheduler,kube-controller-manager} /usr/local/bin/

# Create a token file.
cat>$KUBE_ETC/token.csv<<EOF
$(head -c 16 /dev/urandom | od -An -t x | tr -d ' '),kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF

# Create a kube-apiserver configuration file.
cat >$KUBE_API_CONF<<EOF
KUBE_APISERVER_OPTS="--logtostderr=true \
--v=4 \
--etcd-servers=http://${IP}:2379 \
--bind-address=${IP} \
--insecure-bind-address=0.0.0.0 \
--secure-port=6443 \
--advertise-address=${IP} \
--advertise-address=0.0.0.0 \
--allow-privileged=true \
--service-cluster-ip-range=10.0.0.0/24 \
--enable-admission-plugins=PodPreset,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota,NodeRestriction,MutatingAdmissionWebhook,ValidatingAdmissionWebhook \
--runtime-config=batch/v2alpha1=true,settings.k8s.io/v1alpha1=true \
--authorization-mode=RBAC,Node \
--enable-bootstrap-token-auth \
--token-auth-file=$KUBE_ETC/token.csv \
--service-node-port-range=30000-50000 \
--tls-cert-file=$KUBE_ETC/ssl/server.pem  \
--tls-private-key-file=$KUBE_ETC/ssl/server-key.pem \
--client-ca-file=$KUBE_ETC/ssl/ca.pem \
--service-account-key-file=$KUBE_ETC/ssl/ca-key.pem \
--etcd-cafile=/etc/etcd/ssl/ca.pem \
--etcd-certfile=/etc/etcd/ssl/server.pem \
--etcd-keyfile=/etc/etcd/ssl/server-key.pem"
EOF
#--authorization-mode=RBAC,Node \
#--authorization-rbac-super-user=kubectl \

# Create the kube-apiserver service.
cat>/usr/lib/systemd/system/kube-apiserver.service<<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
After=etcd.service
Wants=etcd.service

[Service]
EnvironmentFile=-$KUBE_API_CONF
ExecStart=/usr/local/bin/kube-apiserver \$KUBE_APISERVER_OPTS
Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl enable kube-apiserver.service --now
systemctl status kube-apiserver.service

}
# --------------------- # --------------------- # --------------------- 
# 参数说明：

# –logtostderr：启用日志。
# –v：日志等级。
# –etcd-servers：etcd集群地址。
# –bind-address：监听地址。
# –secure-port：https安全端口。
# –advertise-address：集群通告地址。
# –allow-privileged：启用授权。
# –service-cluster-ip-range：Service虚拟IP地址段。
# –enable-admission-plugins：准入控制模块。
# –authorization-mode：认证授权，启用RBAC授权和节点自管理。
# –enable-bootstrap-token-auth：启用TLS bootstrap功能。
# –token-auth-file：token文件。
# –service-node-port-range：Service Node类型默认分配端口范围。
# --------------------- # --------------------- # --------------------- 
#




#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
#####安装配置kube-scheduler服务
#master上执行
_kube_scheduler  ()  {
KUBE_ETC=/etc/kubernetes
KUBE_SCHEDULER_CONF=$KUBE_ETC/kube-scheduler.conf
cat>$KUBE_SCHEDULER_CONF<<EOF
KUBE_SCHEDULER_OPTS="--logtostderr=true \
--v=4 \
--master=127.0.0.1:8080 \
--leader-elect"
EOF

cat>/usr/lib/systemd/system/kube-scheduler.service<<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-$KUBE_SCHEDULER_CONF
ExecStart=/usr/local/bin/kube-scheduler \$KUBE_SCHEDULER_OPTS
Restart=always
RestartSec=5
StartLimitInterval=0
LimitNOFILE=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-scheduler.service --now
sleep 5
systemctl status kube-scheduler.service
}




# 参数说明：

# –master：连接本地apiserver。
# –leader-elect：当该组件启动多个时，自动选举（HA），被选为 leader的节点负责处理工作，其它节点为阻塞状态。


#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
#master上执行
_kube_controller  () {
#安装配置kube-controller服务
KUBE_CONTROLLER_CONF=/etc/kubernetes/kube-controller-manager.conf

cat>$KUBE_CONTROLLER_CONF<<EOF
KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=true \
--v=4 \
--master=127.0.0.1:8080 \
--leader-elect=true \
--address=127.0.0.1 \
--service-cluster-ip-range=10.0.0.0/24 \
--cluster-name=kubernetes \
--cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem \
--cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem  \
--root-ca-file=/etc/kubernetes/ssl/ca.pem \
--experimental-cluster-signing-duration=87600h0m0s  \
--feature-gates=RotateKubeletServerCertificate=true  \
--service-account-private-key-file=/etc/kubernetes/ssl/ca-key.pem"
EOF

cat>/usr/lib/systemd/system/kube-controller-manager.service<<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-$KUBE_CONTROLLER_CONF
ExecStart=/usr/local/bin/kube-controller-manager \$KUBE_CONTROLLER_MANAGER_OPTS
Restart=always
RestartSec=5
StartLimitInterval=0
LimitNOFILE=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-controller-manager.service --now
sleep 5
systemctl status kube-controller-manager.service
}



_cherk  ()  {
##############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
#master上执行
#移动kkubectl工具检查集群状态
\cp -avr /root/K8s/Software_package/kubernetes/server/bin/kubectl /usr/local/bin/
ss -lntup| grep api

#  kubectl -s  http://${IP}:8080 get cs
kubectl -s  http://${IP}:8080  get cs  || {
 echo  462行出错
  exit 2
}
#添加自动命令行补全
grep completion /root/.bash_profile  || echo   'source <(kubectl completion bash)'  >> /root/.bash_profile
grep helm /etc/profile || echo  'source <(helm completion bash)'  >>/etc/profile

}




##############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
# 3.7.1 创建bootstrap和kube-proxy的kubeconfig文件
# Master apiserver启用TLS认证后，Node节点kubelet组件想要加入集群，必须使用CA签发的有效证书才能与apiserver通信，
# 当Node节点很多时，签署证书是一件很繁琐的事情，因此有了TLS Bootstrapping机制，kubelet会以一个低权限用户自动向apiserver申请证书，kubelet的证书由apiserver动态签署。在前面创建的token文件在这一步派上了用场，在Master节点上执行脚本KubernetesInstall-14.sh创建bootstrap.kubeconfig和kube-proxy.kubeconfig。
#master执行
#####ip环境
#####ip环境
_kubeconfig_k8s  ()  {
BOOTSTRAP_TOKEN=$(awk -F "," '{print $1}' /etc/kubernetes/token.csv)
KUBE_SSL=/etc/kubernetes/ssl/
KUBE_APISERVER="https://${IP}:6443"

cd $KUBE_SSL
# Set cluster parameters.
kubectl config set-cluster kubernetes \
  --certificate-authority=./ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=bootstrap.kubeconfig

# Set client parameters.
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=bootstrap.kubeconfig

# Set context parameters. 
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig

# Set context.
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig

# Create kube-proxy kubeconfig file. 
kubectl config set-cluster kubernetes \
  --certificate-authority=./ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials kube-proxy \
  --client-certificate=./kube-proxy.pem \
  --client-key=./kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
cd ~

# Bind kubelet-bootstrap user to system cluster roles.
kubectl create clusterrolebinding kubelet-bootstrap \
  --clusterrole=system:node-bootstrapper \
  --user=kubelet-bootstrap
}

#############################################################################################
#############################################################################################
#############################################################################################
###创建admin kubeconfig文件

_kubeconfig_admin  ()  {
cd /etc/kubernetes/ssl


cat > admin-csr.json  <<  'EOF'
{
    "CN": "admin",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "beijing",
            "L": "beijing",
            "O": "od",
            "OU": "ops"
        }
    ]
}
EOF

cfssl  gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin

#生成集群配置文件
kubectl config set-cluster myk8s \
--certificate-authority=/etc/kubernetes/ssl/ca.pem \
--embed-certs=true \
--server=https://${IP}:6443 \
--kubeconfig=kube-admin.kubeconfig

# 设置admin管理账号

kubectl config set-credentials admin \
--client-certificate=/etc/kubernetes/ssl/admin.pem \
--client-key=/etc/kubernetes/ssl/admin-key.pem \
--embed-certs=true \
--kubeconfig=kube-admin.kubeconfig
#绑定账号和管理的集群

kubectl config set-context myk8s-context \
--cluster=myk8s \
--user=admin \
--kubeconfig=kube-admin.kubeconfig



#选择指定集群 一般在需要远程控制的机器上操作
kubectl config use-context myk8s-context --kubeconfig=kube-admin.kubeconfig

#绑定账号到指定的角色
cat  >  k8s-admin.yaml  << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: admin
EOF
kubectl apply -f k8s-admin.yaml
kubectl get clusterrolebinding  admin   -o yaml

#证书授权kubelet-client-current.pem
kubectl apply -f - << EOF
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: approve-node-server-renewal-csr
rules:
- apiGroups: ["certificates.k8s.io"]
  resources: ["certificatesigningrequests/selfnodeserver"]
  verbs: ["create"]
EOF


kubectl get clusterrole|egrep approve
kubectl create clusterrolebinding node-client-auto-approve-csr --clusterrole=system:certificates.k8s.io:certificatesigningrequests:nodeclient --user=kubelet-bootstrap
kubectl create clusterrolebinding node-client-auto-renew-crt --clusterrole=system:certificates.k8s.io:certificatesigningrequests:selfnodeclient --group=system:nodes
kubectl create clusterrolebinding node-server-auto-renew-crt --clusterrole=system:certificates.k8s.io:certificatesigningrequests:selfnodeserver --group=system:nodes

} 



#单机加入node节点

_master_node  ()  {
KUBE_CONF=/etc/kubernetes
KUBE_SSL=$KUBE_CONF/ssl
mkdir -p  $KUBE_SSL
\cp /root/K8s/Software_package/kubernetes/server/bin/{kube-proxy,kubelet} /usr/local/bin/
\cp $KUBE_CONF/ssl/{bootstrap.kubeconfig,kube-proxy.kubeconfig} $KUBE_CONF
cat>$KUBE_CONF/kube-proxy.conf<<EOF
KUBE_PROXY_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=$IP \
--cluster-cidr=10.0.0.0/24 \
--kubeconfig=$KUBE_CONF/kube-proxy.kubeconfig"
EOF
cat>/usr/lib/systemd/system/kube-proxy.service<<EOF
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=-/etc/kubernetes/kube-proxy.conf
ExecStart=/usr/local/bin/kube-proxy  \
 --bind-address=192.168.4.23 \
  --hostname-override=server23 \
  --cluster-cidr=172.35.0.0/16 \
  --kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig \
  --masquerade-all \
  --feature-gates=SupportIPVSProxyMode=true \
  --proxy-mode=ipvs \
  --ipvs-min-sync-period=5s \
  --ipvs-sync-period=5s \
  --ipvs-scheduler=rr \
  --logtostderr=true \
  --v=2
Restart=always
RestartSec=5
StartLimitInterval=0
RestartSec=5
LimitNOFILE=665536
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable kube-proxy.service --now
sleep 5
systemctl status kube-proxy.service -l
cat>$KUBE_CONF/kubelet.yaml<<EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: $IP
port: 10250
readOnlyPort: 10255
cgroupDriver: cgroupfs
clusterDNS: ["10.0.0.2"]
clusterDomain: cluster.local.
failSwapOn: false
authentication:
  anonymous:
    enabled: true
EOF
cat>$KUBE_CONF/kubelet.conf<<EOF
KUBELET_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=$IP \
--kubeconfig=$KUBE_CONF/kubelet.kubeconfig \
--bootstrap-kubeconfig=$KUBE_CONF/bootstrap.kubeconfig \
--config=$KUBE_CONF/kubelet.yaml \
--cert-dir=$KUBE_SSL \
--pod-infra-container-image=registry.cn-chengdu.aliyuncs.com/set/k8s/pause-amd64:3.1   \
--feature-gates=RotateKubeletServerCertificate=true  \
--feature-gates=RotateKubeletClientCertificate=true   \
--rotate-certificates   \
--max-pods=254"
EOF
cat>/usr/lib/systemd/system/kubelet.service<<EOF
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=$KUBE_CONF/kubelet.conf
ExecStart=/usr/local/bin/kubelet \$KUBELET_OPTS
Restart=always
RestartSec=5
StartLimitInterval=0
KillMode=process
LimitNOFILE=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kubelet.service --now 
sleep 5
systemctl status kubelet.service -l

}




####接受crs
_approve_csr ()  {
# Approve kubelet CSR请求
# 可以手动或自动approve CSR请求。推荐使用自动的方式，因为从 v1.8 版本开始，可以自动轮转approve csr后生成的证书。未approve之前如下：
/usr/local/bin/kubectl  get csr
while  [ true ]; do  sleep 5;echo 检测csr请求就绪;/usr/local/bin/kubectl  get csr |egrep "Pending|Approved"   && break  1   ;done

while  [ true ]
  do  
  sleep 5
  echo 等待node就绪中................................
     node_list=$(kubectl  get nodes|egrep   NAME -v |wc -l)  
     
     [ $node_list -eq 1 ]&&  { 
       echo  NOde已经就绪
       break  1   
      }
done
#去掉原始手工生产证书      
# CSRS=$(/usr/local/bin/kubectl  get csr | awk '{if(NR>1) print $1}')
# echo "获取CSRS-------->>>>>>   ${CSRS}"
# for csr in $CSRS;
#     do
#         /usr/local/bin/kubectl   certificate approve $csr;
#     done
# done
#去掉原始手工生产证书   
/usr/local/bin/kubectl  get node
/usr/local/bin/kubectl   get cs
#####ip环境
# .  /root/Installation/ip.txt
# master_ip=${IP}
######
sleep 1
/usr/local/bin/kubectl -s  http://${IP}:8080 label node ${IP}  node-role.kubernetes.io/node='master'
/usr/local/bin/kubectl -s  http://${IP}:8080  get node
#修复授权
/usr/local/bin/kubectl -s  http://${IP}:8080  create clusterrolebinding me-cluster-admin   --clusterrole=cluster-admin   --user=system:anonymous
/usr/local/bin/kubectl -s  http://${IP}:8080  create clusterrolebinding system:anonymous   --clusterrole=cluster-admin   --user=system:anonymous
#修复pod时区为中国上海
kubectl apply -f - << EOF
apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: timezone
spec:
  selector:
    matchLabels:
  env:
    - name: TZ
      value: Asia/Shanghai
EOF

}


#优化单机版环境
# etcd
_cfssl_etcd
_etcd
_Flannel
_cfssl_k8s 
_kube_apiserver
_kube_scheduler
_kube_controller 
_cherk 

_kubeconfig_k8s  
_kubeconfig_admin 

_master_node 
_approve_csr 
while  [ true ]; do  sleep 5;echo 等待csr请求就绪;/usr/local/bin/kubectl  get csr |grep Pending    || break  1   ;done
_approve_csr




#新增证书文件


# cat /etc/kubernetes/kubelet.kubeconfig > /root/.kube/config

#开启clusterDNS
 /usr/local/bin/kubectl  -s http://${IP}:8080    apply -f /root/K8s/k8s_yaml/coredns/coredns.yaml
 #安装helm
_helm_install () { 
yum install -y socat  2> /dev/null
tar  -xzvf  /root/K8s/Software_package/${helm_name}   -C    /usr/local/bin/
\cp  -av /usr/local/bin/linux-amd64/helm    /usr/local/bin
rm  -rvf  /usr/local/bin/linux-amd64/
helm  version&& echo  "helm安装成功！！"
# egrep  kubeconfig  /etc/profile ||echo  'export KUBECONFIG=/etc/kubernetes/ssl/kube-admin.kubeconfig ' >>/etc/profile

 }
_helm_install
sleep 5
#启用单机版nfs
sh  /root/K8s/nfs/nfs_install.sh

#启用监控环境
sleep 5
sh  /root/K8s/k8s_yaml/prometheus/prometheus_install.sh
sh  /root/K8s/k8s_yaml/grafan/grafan_install.sh