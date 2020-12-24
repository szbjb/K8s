#部署dns
kubectl  apply -f coredns.yaml
#测试效果  容器内Ping  nginx-yum.default.svc.cluster.local
[root@k8s-master-db4 ~]#  kubectl  run --image=busybox:1.28.4 -it  --rm --restart=Never  dns-test /bin/nslookup kubernetes
Server:    10.0.0.2
Address 1: 10.0.0.2 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.0.0.1 kubernetes.default.svc.cluster.local
pod "dns-test" deleted
[root@k8s-master-db4 ~]#
[root@k8s-master-db4 ~]#  kubectl get pods -n kube-system| grep coredns
coredns-57656b67bb-95k69               1/1     Running   0          68s
[root@k8s-master-db4 ~]#



#测试yaml，，，加个app: xxxx
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx-yum
  labels:
    name: nginx-yum
spec:
  replicas: 1
  selector:
    name: nginx-yum
  template:
    metadata:
      labels:
       name: nginx-yum
       app: nginx-yum
    spec:
      containers:
      - name: nginx-yum
        image: docker.io/nginx
        ports:
        - containerPort: 80
        volumeMounts:
          - mountPath: /etc/nginx/
            name: nginx-data
      volumes:
       - name: nginx-data
         hostPath:
          path: /data/nginx
      nodeSelector:
       disktype: master
       
[root@k8s-master-db4 shell_01]#  kubectl  run --image=busybox:1.28.4 -it  --rm --restart=Never  dns-test /bin/nslookup   nginx-yum
Server:    10.0.0.2
Address 1: 10.0.0.2 kube-dns.kube-system.svc.cluster.local

Name:      nginx-yum
Address 1: 10.0.0.167 nginx-yum.default.svc.cluster.local
pod "dns-test" deleted
[root@k8s-master-db4 shell_01]#


