#!/bin/bash
# Deploy the master node.
# 3.6 部署Master节点
# 3.6.1 创建CA证书
# 这一步中创建了kube-apiserver和kube-proxy相关的CA证书，在Master节点执行脚本KubernetesInstall-09.sh。
#####ip环境
#####ip环境
. /root/K8s/ip_2.txt
master_ip=${master_hosts_}
note=$(awk -F  "="   '{print  $2}' /root/K8s/ip_2.txt|grep $master_ip -v)
###### 
######
KUBE_SSL=/etc/kubernetes/ssl
mkdir -pv $KUBE_SSL

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
      "10.10.8.170",
      "10.10.8.166",
      "10.10.8.165",
      "10.10.8.160",
      "10.103.97.123",
      "${master_ip}",
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

master_ha_list=$(ansible  Master_ha  -m ping |grep  SUCCESS|awk   '{print $1}' |wc -l)
master_ha_list02=$(ansible  Master_ha  -m ping |grep  SUCCESS|awk   '{print $1}')
master_ha_text=$(echo  -e  $master_ha_list02|xargs -n 1|sed    's/^/"/g'|sed  's/$/",/g')
[[ "$master_ha_list"   -ge   "1" ]]  &&  {
 for   var in $(echo  $master_ha_text  ); do  sleep 0.1 ; echo  $var;sed "/10.0.0.1/a  ${var}"  $KUBE_SSL/server-csr.json  -i  ;done
  

}

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


#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
# 3.6.2 安装配置kube-apiserver服务
# 将备好的安装包解压，并移动到相关目录，进行相关配置，执行脚本KubernetesInstall-10.sh。
#master上执行
KUBE_ETC=/etc/kubernetes
KUBE_API_CONF=/etc/kubernetes/apiserver.conf

tar   xjf  /root/K8s/Software_package/*kubernetes-server-linux-amd64.tar.gz  -C  /root/K8s/Software_package/ 2>/dev/null || {
tar   xzvf  /root/K8s/Software_package/*kubernetes-server-linux-amd64.tar.gz  -C  /root/K8s/Software_package/ 
}

chmod  755  /root/K8s/Software_package/kube-controller-manager   2> /dev/null|| true
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
--etcd-servers=https://${master_ip}:2379,$(echo $note |xargs -n 1  |sed  's/^/https:\/\/&/g'|sed 's/$/&:2379,/g' |xargs |sed '$s/,$//'| sed 's/ //g') \
--bind-address=${master_ip} \
--insecure-bind-address=0.0.0.0 \
--secure-port=6443 \
--advertise-address=${master_ip} \
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
--requestheader-client-ca-file=/etc/kubernetes/ssl/ca.pem \
--requestheader-allowed-names=aggregator \
--requestheader-extra-headers-prefix=X-Remote-Extra- \
--requestheader-group-headers=X-Remote-Group \
--requestheader-username-headers=X-Remote-User \
--proxy-client-cert-file=/etc/kubernetes/ssl/kube-proxy.pem \
--proxy-client-key-file=/etc/kubernetes/ssl/kube-proxy-key.pem \
--etcd-keyfile=/etc/etcd/ssl/server-key.pem"
EOF

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
systemctl restart kube-apiserver.service --now
systemctl status kube-apiserver.service



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
systemctl restart kube-scheduler.service --now
sleep 20
systemctl status kube-scheduler.service





# 参数说明：

# –master：连接本地apiserver。
# –leader-elect：当该组件启动多个时，自动选举（HA），被选为 leader的节点负责处理工作，其它节点为阻塞状态。

#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
#master上执行
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
--experimental-cluster-signing-duration=87600h0m0s \
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
systemctl restart kube-controller-manager.service --now
sleep 20
systemctl status kube-controller-manager.service




##############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
#master上执行
#移动kkubectl工具检查集群状态
mv /root/K8s/Software_package/kubernetes/server/bin/kubectl /usr/local/bin/
kubectl get cs




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
BOOTSTRAP_TOKEN=$(awk -F "," '{print $1}' /etc/kubernetes/token.csv)
KUBE_SSL=/etc/kubernetes/ssl/
KUBE_APISERVER="https://${master_ip}:6443"

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




#sleep
kubectl get cs
grep completion /root/.bash_profile  || echo   'source <(kubectl completion bash)'  >> /root/.bash_profile
grep helm /etc/profile || echo  'source <(helm completion bash)'  >>/etc/profile


#5年授权

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

