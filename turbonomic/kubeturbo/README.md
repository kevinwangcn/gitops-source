#### Connect kubeturbo to turbonomic
The `topology-processor` service of turbonomic needs to be modified:
```console
👉 gitops-source $ kc -n turbonomic patch svc topology-processor --patch-file turbonomic/svc_topology-processor_patch.yaml 
service/topology-processor patched
```