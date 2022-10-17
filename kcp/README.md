### Sync from Argo CD to kcp apiserver

Argo CD complains:
```console
ubuntu@ip-172-31-17-224:~$ argocd cluster list
SERVER                                           NAME                       VERSION  STATUS   MESSAGE                                                                                                                                                                                                                                                                                                                                                  PROJECT
https://172.31.31.125:6443/clusters/root:my-org  workspace.kcp.dev/current  1.24     Failed   failed to sync cluster https://172.31.31.125:6443/clusters/root:my-org: failed to load initial state of resource ClusterWorkspace.tenancy.kcp.dev: clusterworkspaces.tenancy.kcp.dev is forbidden: User "system:serviceaccount:kube-system:argocd-manager" cannot list resource "clusterworkspaces" in API group "tenancy.kcp.dev" at the cluster scope  
https://kubernetes.default.svc                   in-cluster                          Unknown  Cluster has no applications and is not being monitored.   
```

This can be solved by
```
kubectl -n argocd patch cm argocd-cm --patch-file examples/kcp/configmap-argocd-cm-patch.yaml
```

Argo CD's documentation mentions this feature as [Resource Exclusion/Inclusion](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#resource-exclusioninclusion).
