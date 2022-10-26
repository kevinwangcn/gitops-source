### Overview
This example is similar to the [blud-green deployment](/kcp/nginx/README.md).
The major difference is that, this example uses one single namespace and one single Placement.
In this example, nginx can be rescheduled from one edge cluster (i.e. kcp pcluster) to another,
by changing the `optimized` Placement and commit the change to git.

For example, one can change from `aisle: "2"` to `aisle: "1"`,
so that nginx is scheduled from some cluster located in aisle 1 to some cluster located in aisle 2.

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

### Check the delivered workloads
```console
$ docker exec -it cluster1-control-plane bash
root@cluster1-control-plane:/# kubectl get svc,deploy,po -l app=nginx -A
NAMESPACE          NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kcp-23yty2b3l41t   service/nginx         ClusterIP   10.96.201.207   <none>        80/TCP    30m

NAMESPACE          NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
kcp-23yty2b3l41t   deployment.apps/nginx         3/3     3            3           30m

NAMESPACE          NAME                              READY   STATUS    RESTARTS   AGE
kcp-23yty2b3l41t   pod/nginx-d57b684c4-8s4zh         1/1     Running   0          30m
kcp-23yty2b3l41t   pod/nginx-d57b684c4-nbmsp         1/1     Running   0          30m
kcp-23yty2b3l41t   pod/nginx-d57b684c4-wwng9         1/1     Running   0          30m
root@cluster1-control-plane:/# curl 10.96.201.207
<!DOCTYPE html>
<html>
<head>
<title>Welcome to MY nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to MY nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
