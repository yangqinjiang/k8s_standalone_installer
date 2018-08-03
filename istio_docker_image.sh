#! /bin/bash
echo -e "\033[42;37m-------pull istio的images-------\033[0m"
echo -e "\033[42;37m-------1, istio/proxy_init:1.0.0-------\033[0m"
docker pull istio/proxy_init:1.0.0
docker tag istio/proxy_init:1.0.0 gcr.io/istio-release/proxy_init:1.0.0


echo -e "\033[42;37m-------2, istio/proxyv2:1.0.0-------\033[0m"
docker pull istio/proxyv2:1.0.0
docker tag istio/proxyv2:1.0.0 gcr.io/istio-release/proxyv2:1.0.0


echo -e "\033[42;37m-------3, istio/galley:1.0.0-------\033[0m"
docker pull istio/galley:1.0.0
docker tag istio/galley:1.0.0 gcr.io/istio-release/galley:1.0.0


echo -e "\033[42;37m-------4, istio/grafana:1.0.0-------\033[0m"
docker pull istio/grafana:1.0.0
docker tag istio/grafana:1.0.0 gcr.io/istio-release/grafana:1.0.0


echo -e "\033[42;37m-------5, istio/mixer:1.0.0-------\033[0m"
docker pull istio/mixer:1.0.0
docker tag istio/mixer:1.0.0 gcr.io/istio-release/mixer:1.0.0

echo -e "\033[42;37m-------6, istio/pilot:1.0.0-------\033[0m"
docker pull istio/pilot:1.0.0
docker tag istio/pilot:1.0.0 gcr.io/istio-release/pilot:1.0.0

echo -e "\033[42;37m-------7, istio/citadel:1.0.0-------\033[0m"
docker pull istio/citadel:1.0.0
docker tag istio/citadel:1.0.0 gcr.io/istio-release/citadel:1.0.0

echo -e "\033[42;37m-------8, istio/servicegraph:1.0.0-------\033[0m"
docker pull istio/servicegraph:1.0.0
docker tag istio/servicegraph:1.0.0 gcr.io/istio-release/servicegraph:1.0.0

echo -e "\033[42;37m-------9, istio/sidecar_injector:1.0.0-------\033[0m"
docker pull istio/sidecar_injector:1.0.0
docker tag istio/sidecar_injector:1.0.0 gcr.io/istio-release/sidecar_injector:1.0.0