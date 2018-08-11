init:
	kubectl create -f namespace.yaml
	kubectl label namespace istio-test istio-injection=enabled --overwrite=true
	kubectl create -f helloworld.yaml -n istio-test
	kubectl create -f gateway.yaml -n istio-test
	kubectl create -f destination-rule-all.yaml -n istio-test
clean:
	kubectl delete -f helloworld.yaml -n istio-test
	kubectl delete -f gateway.yaml -n istio-test
	kubectl delete -f destination-rule-all.yaml -n istio-test
	kubectl label namespace istio-test istio-injection=disabled --overwrite=true
	kubectl delete -f namespace.yaml