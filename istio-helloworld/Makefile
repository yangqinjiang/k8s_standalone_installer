init:
	kubectl create -f helloworld.yaml
	kubectl create -f gateway.yaml
	kubectl create -f destination-rule-all.yaml
clean:
	kubectl delete -f helloworld.yaml
	kubectl delete -f gateway.yaml
	kubectl delete -f destination-rule-all.yaml