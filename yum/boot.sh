#取消开机自启管理
# systemctl is-active  docker  kubelet  kube-proxy
#k8s-start
systemctl   start      kube-apiserver  2>/dev/null
sleep 5
systemctl   start      kube-scheduler   2>/dev/null
sleep 5
systemctl   start      kube-controller-manager   2>/dev/null
sleep 5
systemctl   start      docker   2>/dev/null
sleep 5
systemctl   start      kubelet    2>/dev/null
sleep 5
systemctl   start      kube-proxy   2>/dev/null
#master 节点
# systemctl is-active  kube-apiserver    kube-scheduler    kube-controller-manager   docker  kubelet  kube-proxy  2>/dev/null



