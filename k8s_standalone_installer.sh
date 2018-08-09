#! /bin/bash

# set -o errexit
set -o nounset
set -o pipefail



master_inip='172.16.0.138' #本机内网IP
hostname='test.novalocal' #主机名称
workdir=$(cd $(dirname $0); pwd)
echo -e "当前脚本所在目录$workdir"

echo -e "\033[42;37m-----------正在安装单机版的k8s组件-----------\033[0m"
echo -e "\033[44;37m停止原来的服务...\033[0m" >&2
systemctl stop kubelet
systemctl stop kube-proxy
systemctl stop kube-apiserver
systemctl stop kube-controller-manager
systemctl stop kube-scheduler
#tar xf kubernetes-server-linux-amd64.tar.gz
cd kubernetes_bin


echo -e "\033[42;37m-------0, 正在安装 kube-apiserver-------\033[0m"
#防止覆盖
if [[ -e /usr/bin/kube-apiserver ]]; then
    echo -e "\033[41;37m 已存在文件  /usr/bin/kube-apiserver \033[0m" >&2
    exit 1
fi


echo -e "\033[44;37m-------1, COPY master 的 bin 文件-------\033[0m" >&2
cp kube-apiserver /usr/bin/
cp kube-controller-manager /usr/bin/
cp kube-scheduler /usr/bin/


# kube-apiserver---------------------------------------------------
echo -e "\033[44;37m-------2, kube-apiserver Config Start-------\033[0m"
echo -e "\033[44;37m编辑kube-apiserver.service的启动文件\033[0m"
cat > /usr/lib/systemd/system/kube-apiserver.service <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://kubernetes.io/docs/concepts/overview
After=network.target
After=etcd.service

[Service]
EnvironmentFile=/etc/kubernetes/apiserver
ExecStart=/usr/bin/kube-apiserver \$KUBE_API_ARGS
Restart=on-failure
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo -e "\033[44;37m创建日志目录和证书目录\033[0m"
mkdir -p /var/log/kubernetes
mkdir -p /etc/kubernetes/ssl

echo -e "\033[44;37m编辑apiserver的启动文件\033[0m"
cat > /etc/kubernetes/apiserver <<EOF
KUBE_API_ARGS="--storage-backend=etcd3 \
               --etcd-servers=http://127.0.0.1:2379 \
               --bind-address=0.0.0.0 \
               --secure-port=6443  \
               --service-cluster-ip-range=10.222.0.0/16  \
               --service-node-port-range=1-65535 \
               --client-ca-file=/etc/kubernetes/ssl/ca.crt \
               --tls-private-key-file=/etc/kubernetes/ssl/server.key  \
               --tls-cert-file=/etc/kubernetes/ssl/server.crt  \
               --enable-admission-plugins=Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota \
               --logtostderr=false \
               --log-dir=/var/log/kubernetes \
               --v=2"
EOF

echo -e "\033[44;37m-------kube-apiserver Config DONE-------\033[0m"





# kube-controller-manager---------------------------------------------------
echo -e "\033[44;37m-------3, kube-controller-manager Config Start-------\033[0m"
echo -e "\033[44;37m编辑kube-controller-manager.service的启动文件\033[0m"
cat > /usr/lib/systemd/system/kube-controller-manager.service <<EOF
[Unit]
Description=Kubernetes Controller Manager 
Documentation=https://kubernetes.io/docs/setup
After=kube-apiserver.service
Requires=kube-apiserver.service

[Service]
EnvironmentFile=/etc/kubernetes/controller-manager
ExecStart=/usr/bin/kube-controller-manager \$KUBE_CONTROLLER_MANAGER_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo -e "\033[44;37m编辑kube-controller-manager的启动参数\033[0m"
cat > /etc/kubernetes/controller-manager <<EOF
KUBE_CONTROLLER_MANAGER_ARGS="--master=https://$master_inip:6443   \
--service-account-private-key-file=/etc/kubernetes/ssl/server.key  \
--root-ca-file=/etc/kubernetes/ssl/ca.crt --kubeconfig=/etc/kubernetes/kubeconfig"
EOF

echo -e "\033[44;37m-------kube-controller-manager Config DONE-------\033[0m"




# kube-scheduler---------------------------------------------------
echo -e "\033[44;37m-------4, kube-scheduler Config Start-------\033[0m"
echo -e "\033[44;37m编辑kube-scheduler.service的启动文件\033[0m"
cat > /usr/lib/systemd/system/kube-scheduler.service  <<EOF
[Unit]
Description=Kubernetes Controller Manager 
Documentation=https://kubernetes.io/docs/setup
After=kube-apiserver.service
Requires=kube-apiserver.service

[Service]
EnvironmentFile=/etc/kubernetes/scheduler
ExecStart=/usr/bin/kube-scheduler \$KUBE_SCHEDULER_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo -e "\033[44;37m编辑scheduler的启动参数\033[0m"
cat > /etc/kubernetes/scheduler <<EOF
KUBE_SCHEDULER_ARGS="--master=https://$master_inip:6443 --kubeconfig=/etc/kubernetes/kubeconfig"
EOF

echo -e "\033[44;37m-------scheduler Config DONE-------\033[0m"




# kubeconfig 
echo -e "\033[44;37m-------5,创建kubeconfig文件-------\033[0m"
cat > /etc/kubernetes/kubeconfig <<EOF
apiVersion: v1
kind: Config
users:
- name: controllermanager
  user:
    client-certificate: /etc/kubernetes/ssl/cs_client.crt
    client-key: /etc/kubernetes/ssl/cs_client.key
clusters:
- name: local
  cluster:
    certificate-authority: /etc/kubernetes/ssl/ca.crt
contexts:
- context:
    cluster: local
    user: controllermanager
  name: my-context
current-context: my-context
EOF

# 创建CA证书
echo -e "\033[44;37m-------6,创建CA证书-------\033[0m"
cd  /etc/kubernetes/ssl/
openssl genrsa -out ca.key 2048
# CN指定Master的IP地址
openssl req -x509 -new -nodes -key ca.key -subj "/CN=$master_inip" -days 5000 -out ca.crt
openssl genrsa -out server.key 2048
# 创建master_ssl.cnf文件
cat > master_ssl.cnf  <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
DNS.5 = k8s_master
IP.1 = 10.222.0.1                     # ClusterIP 地址
IP.2 = $master_inip                         # master IP地址
EOF


echo -e "\033[44;37m-------创建server.csr和 server.crt文件-------\033[0m"
# 基于上述文件，创建server.csr和 server.crt文件，执行如下命令：
openssl req -new -key server.key -subj "/CN=$hostname" -config master_ssl.cnf -out server.csr   # CN指定主机名
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 5000 -extensions v3_req -extfile master_ssl.cnf -out server.crt
#提示： 执行以上命令后会生成6个文件，ca.crt ca.key ca.srl server.crt server.csr server.key。


echo -e "\033[44;37m-------设置kube-controller-manager相关证书-------\033[0m"
# 设置kube-controller-manager相关证书：
cd  /etc/kubernetes/ssl/
openssl genrsa -out cs_client.key 2048
openssl req -new -key cs_client.key -subj "/CN=$hostname" -out cs_client.csr     # CN指定主机名
openssl x509 -req -in cs_client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out cs_client.crt -days 5000

#7、启动服务：
echo -e "\033[44;37m-------7、启动服务-------\033[0m"

systemctl daemon-reload
sleep 1
systemctl enable kube-apiserver
systemctl start kube-apiserver

sleep 1
systemctl enable kube-controller-manager
systemctl start kube-controller-manager

sleep 1
systemctl enable kube-scheduler
systemctl start kube-scheduler

sleep 1
echo -e "\033[44;37m-------8、查看状态-------\033[0m"
systemctl status kube-apiserver
systemctl status kube-controller-manager
systemctl status kube-scheduler

echo -e "\033[44;37m-------9、Node部署-------\033[0m"
sleep 2
cat > /etc/sysctl.d/k8s.conf  <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
echo -e "\033[44;37m-------10, COPY node 的 bin 文件-------\033[0m" >&2
cd $workdir
cd kubernetes_bin
cp kubectl kubelet  kube-proxy  /usr/bin/

mkdir -p /var/lib/kubelet
mkdir -p /var/log/kubernetes
mkdir -p /etc/kubernetes

# 
echo -e "\033[44;37m-------11, 创建kubelet证书-------\033[0m" >&2
cd /etc/kubernetes/ssl/
openssl genrsa -out kubelet_client.key 2048
#  CN指定Node节点的IP , 同master的IP
openssl req -new -key kubelet_client.key -subj "/CN=$master_inip" -out kubelet_client.csr
openssl x509 -req -in kubelet_client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kubelet_client.crt -days 5000

echo -e "\033[44;37m-------12, kubelet.service 配置启动文件-------\033[0m" >&2
cat > /usr/lib/systemd/system/kubelet.service  <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://kubernetes.io/doc
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=/var/lib/kubelet
ExecStart=/usr/bin/kubelet --kubeconfig=/etc/kubernetes/kubeconfig.yaml --logtostderr=false --log-dir=/var/log/kubernetes --v=2 --cgroup-driver=systemd --runtime-cgroups=/systemd/system.slice --kubelet-cgroups=/systemd/system.slice
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo -e "\033[44;37m-------13, kubeconfig.yaml  配置文件-------\033[0m" >&2
cat > /etc/kubernetes/kubeconfig.yaml  <<EOF
apiVersion: v1
kind: Config
users:
- name: kubelet
  user:
    client-certificate: /etc/kubernetes/ssl/kubelet_client.crt
    client-key: /etc/kubernetes/ssl/kubelet_client.key
clusters:
- name: local
  cluster: 
    certificate-authority: /etc/kubernetes/ssl/ca.crt
    server: https://$master_inip:6443
contexts:
- context:
    cluster: local
    user: kubelet
  name: my-context
current-context: my-context
EOF


echo -e "\033[44;37m-------14, kube-proxy  启动文件-------\033[0m" >&2
cat > /usr/lib/systemd/system/kube-proxy.service  <<EOF
[Unit]
Description=Kubernetes kubelet agent 
Documentation=https://kubernetes.io/doc
After=network.service
Requires=network.service

[Service]
EnvironmentFile=/etc/kubernetes/proxy
ExecStart=/usr/bin/kube-proxy \$KUBE_PROXY_ARGS  
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo -e "\033[44;37m-------15, kube-proxy  启动参数-------\033[0m" >&2
cat > /etc/kubernetes/proxy  <<EOF
KUBE_PROXY_ARGS="--master=https://$master_inip:6443  --kubeconfig=/etc/kubernetes/kubeconfig.yaml"
EOF


echo -e "\033[44;37m-------16,关闭系统交换, 启动服务-------\033[0m" >&2
swapoff -a
systemctl daemon-reload
sleep 1
systemctl enable kubelet
systemctl enable kube-proxy
sleep 1
systemctl start kubelet
systemctl start kube-proxy
sleep 1
systemctl status kubelet
systemctl status kube-proxy


echo -e "\033[44;37m-------17,摘取阿里云的pause-amd64镜像-------\033[0m" >&2
#注意版本号
aliyun="registry.cn-shenzhen.aliyuncs.com/google_container_mirrors/pause-amd64:3.1"
docker pull $aliyun
docker tag $aliyun k8s.gcr.io/pause-amd64:3.1

echo -e "\033[44;37m-------ALL DONE-------\033[0m"
