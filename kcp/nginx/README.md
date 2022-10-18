### Overview
This example uses GitOps and [kcp](https://github.com/kcp-dev/kcp) to simulate a blue-green deployment of nginx.
It is done in two steps:
1. use GitOps to deliver customized nginx, as well as the scheduling decisions (described by kcp Placements and Locations), to kcp;
2. let kcp's [TMC](https://github.com/kcp-dev/kcp/blob/main/docs/locations-and-scheduling.md) schedule the customized nginx to two kcp pclusters/SyncTargets, by executing the scheduling decisions.

```text
                      ┌─my-org workspace──────┐  ┌─TMC─┐
                      │                       │  │     │
                      │  ┌─green ns────────┐  │  │     │   ┌─pcluster1───────┐
          gitops      │  │                 │  │  │     │   │                 │
       ┌──────────────┼──┼─► green nginx ──┼──┼──┼──┬──┼───┼─► green nginx   │
       │              │  │                 │  │  │  ▲  │   │                 │
┌─git──┴─────┐        │  └─────────────────┘  │  │  │  │   └─────────────────┘
│            │        │                       │  │  │  │
│ nginx &    │ gitops │                       │  │  │  │
│ scheduling ├────────┼─placements, locations─┼──┼──┤  │
│ decisions  │        │                       │  │  │  │
│            │        │                       │  │  │  │
└──────┬─────┘        │  ┌─blue  ns────────┐  │  │  │  │   ┌─pcluster2───────┐
       │  gitops      │  │                 │  │  │  ▼  │   │                 │
       └──────────────┼──┼─► blue  nginx ──┼──┼──┼──┴──┼───┼─► blue  nginx   │
                      │  │                 │  │  │     │   │                 │
                      │  └─────────────────┘  │  │     │   └─────────────────┘
                      │                       │  │     │
                      └───────────────────────┘  └─────┘
```

### Setup kcp and kcp pclusters/SyncTargets
[kcp-skupper](https://github.com/ch007m/kcp-skupper) is used for quick setup of kcp.
[kind](https://kind.sigs.k8s.io/) is used to setup the kcp pclusters/SyncTargets.

By default, Kubernetes Services are not synced by a kcp syncer, so it is necessary to explicitly tell a syncer to sync them. For example:
```console
$ ../kcp.sh syncer -w my-org -c cluster1 -r services
```

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
$ kubectl label synctarget cluster1 color=green
synctarget.workload.kcp.dev/cluster1 labeled
$ kubectl label synctarget cluster2 color=blue
synctarget.workload.kcp.dev/cluster2 labeled
```

### Use GitOps tools
First, use your favorite GitOps tools to deliver scheduling manifests in [scheduling/](scheduling/).

For example, with Argo CD:
```console
argocd app create scheduling \
--repo https://github.com/edge-experiments/gitops-source.git \
--path kcp/nginx/scheduling/ \
--dest-server https://172.31.31.125:6443/clusters/root:my-org:edge
```
Sync the Argo CD Application:
```console
argocd app sync scheduling
```

Then, deliver workload (nginx) manifests in [deploy-green/](deploy-green/) and [deploy-blue/](deploy-blue/).

For green nginx, with Argo CD:
```console
argocd app create deploy-green \
--repo https://github.com/edge-experiments/gitops-source.git \
--path kcp/nginx/deploy-green/ \
--dest-server https://172.31.31.125:6443/clusters/root:my-org:edge
```
Sync the Argo CD Application:
```console
argocd app sync deploy-green
```

For blue nginx, with Argo CD:
```console
argocd app create deploy-blue \
--repo https://github.com/edge-experiments/gitops-source.git \
--path kcp/nginx/deploy-blue/ \
--dest-server https://172.31.31.125:6443/clusters/root:my-org:edge
```
Sync the Argo CD Application:
```console
argocd app sync deploy-blue
```

### Check the delivered workloads
#### Green workload
```console
$ docker exec -it cluster1-control-plane bash
root@cluster1-control-plane:/# kubectl get svc,deploy,po -l app=nginx -A
NAMESPACE          NAME                  TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
kcp-bzj3fcbq6cqj   service/green-nginx   NodePort   10.96.72.227   <none>        80:32064/TCP   12m

NAMESPACE          NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
kcp-bzj3fcbq6cqj   deployment.apps/green-nginx   3/3     3            3           12m

NAMESPACE          NAME                               READY   STATUS    RESTARTS   AGE
kcp-bzj3fcbq6cqj   pod/green-nginx-7d89cdb996-f9wnn   1/1     Running   0          12m
kcp-bzj3fcbq6cqj   pod/green-nginx-7d89cdb996-ptcjn   1/1     Running   0          12m
kcp-bzj3fcbq6cqj   pod/green-nginx-7d89cdb996-pxhc7   1/1     Running   0          12m
root@cluster1-control-plane:/# curl localhost:32064
<!DOCTYPE html>
<html>
<head>
<title>Welcome to GREEN nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to GREEN nginx!</h1>
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

#### Blue workload
```console
$ docker exec -it cluster2-control-plane bash
root@cluster2-control-plane:/# kubectl get svc,deploy,po -l app=nginx -A
NAMESPACE          NAME                 TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
kcp-mdjud4pr2yfy   service/blue-nginx   NodePort   10.96.198.78   <none>        80:32064/TCP   16m

NAMESPACE          NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
kcp-mdjud4pr2yfy   deployment.apps/blue-nginx   3/3     3            3           16m

NAMESPACE          NAME                              READY   STATUS    RESTARTS   AGE
kcp-mdjud4pr2yfy   pod/blue-nginx-6b57bb798c-4g6z5   1/1     Running   0          16m
kcp-mdjud4pr2yfy   pod/blue-nginx-6b57bb798c-69kmc   1/1     Running   0          16m
kcp-mdjud4pr2yfy   pod/blue-nginx-6b57bb798c-wgf74   1/1     Running   0          16m
root@cluster2-control-plane:/# curl localhost:32064
<!DOCTYPE html>
<html>
<head>
<title>Welcome to BLUE nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to BLUE nginx!</h1>
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
