#! /bin/bash
echo -e "\033[44;37m创建DEMO应用...\033[0m" >&2
cd demo
kubectl create -f nginx.yaml
kubectl create -f nginx-service.yaml
echo -e "\033[44;37m等待一下\033[0m" >&2
sleep 1
watch -n 2 'kubectl get rc,pods,svc'