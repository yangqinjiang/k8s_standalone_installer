init_istio:
	kubectl create -f crds.yaml
	kubectl create -f istio-demo-nodeport.yaml

clean_istio:
	kubectl delete -f crds.yaml
	kubectl delete -f istio-demo-nodeport.yaml