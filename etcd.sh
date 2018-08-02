#! /bin/bash

set -o errexit
set -o nounset
set -o pipefail

if [[ -e /usr/bin/etcd ]]; then
    echo "/usr/bin/已存在文件 etcd" >&2
    exit 1
fi

if [[ -e etcd-v3.2.20-linux-amd64.tar.gz ]];then
	echo "已存在etcd-v3.2.20-linux-amd64.tar.gz" >&2
	exit 1
fi
echo "正在下载etcd压缩包文件"
wget https://github.com/coreos/etcd/releases/download/v3.2.20/etcd-v3.2.20-linux-amd64.tar.gz
tar xf etcd-v3.2.20-linux-amd64.tar.gz
cd etcd-v3.2.20-linux-amd64
cp etcd etcdctl  /usr/bin/
mkdir -p /var/lib/etcd
mkdir -p /etc/etcd
echo "保存文件  etcd.service"
cat > /usr/lib/systemd/system/etcd.service <<EOF
[Unit]
Description=Etcd Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
ExecStart=/usr/bin/etcd

[Install]
WantedBy=multi-user.target
EOF
echo "启动服务..."
systemctl daemon-reload
systemctl start etcd
systemctl status etcd.service