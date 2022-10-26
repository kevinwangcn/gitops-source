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
