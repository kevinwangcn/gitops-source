#### Connect kubeturbo to Turbonomic
The `topology-processor` service of Turbonomic needs to be modified:
```console
👉 gitops-source $ kc -n turbonomic patch svc topology-processor --patch-file turbonomic/svc_topology-processor_patch.yaml 
service/topology-processor patched
```
The log of kubeturbo should show something similar to
```console
I1010 16:27:11.004260       1 k8s_discovery_client.go:273] Successfully discovered kubernetes cluster in 6.190 seconds
```
And the Turbonomic UI will show a new Target `Kubernetes-Turbonomic`.
