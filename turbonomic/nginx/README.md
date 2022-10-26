### Before using GitOps tools
Cleanup default scheduling:
```console
$ kubectl delete placement default
placement.scheduling.kcp.dev "default" deleted
$ kubectl delete location default
location.scheduling.kcp.dev "default" deleted
```

Label the SyncTargets:
```console
$ kubectl label synctarget cluster1 aisle="1"
synctarget.workload.kcp.dev/cluster1 labeled
$ kubectl label synctarget cluster2 aisle="2"
synctarget.workload.kcp.dev/cluster2 labeled
```

### Use GitOps tools
With Argo CD:
```console
argocd app create scheduling-optimized \
--repo https://github.com/edge-experiments/gitops-source.git \
--path turbonomic/nginx/scheduling/ \
--dest-server https://172.31.31.125:6443/clusters/root:my-org:edge \
--sync-policy automated
```

```console
argocd app create deploy-optimized \
--repo https://github.com/edge-experiments/gitops-source.git \
--path turbonomic/nginx/deploy/ \
--dest-server https://172.31.31.125:6443/clusters/root:my-org:edge \
--sync-policy automated
```
