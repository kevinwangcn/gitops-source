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
--dest-server https://172.31.31.125:6443/clusters/root:my-org:edge \
--sync-policy automated
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
--dest-server https://172.31.31.125:6443/clusters/root:my-org:edge \
--sync-policy automated
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
--dest-server https://172.31.31.125:6443/clusters/root:my-org:edge \
--sync-policy automated
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
NAMESPACE          NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kcp-1guc3h85a3b0   service/green-nginx   ClusterIP   10.96.144.90    <none>        80/TCP    6d23h

NAMESPACE          NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
kcp-1guc3h85a3b0   deployment.apps/green-nginx   3/3     3            3           6d23h

NAMESPACE          NAME                              READY   STATUS    RESTARTS   AGE
kcp-1guc3h85a3b0   pod/green-nginx-7b86884c4-5mcz4   1/1     Running   0          6d23h
kcp-1guc3h85a3b0   pod/green-nginx-7b86884c4-p2zgf   1/1     Running   0          6d23h
kcp-1guc3h85a3b0   pod/green-nginx-7b86884c4-q5x7t   1/1     Running   0          6d23h
root@cluster1-control-plane:/# curl 10.96.144.90
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
NAMESPACE          NAME                 TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
kcp-35774k02n7jg   service/blue-nginx   ClusterIP   10.96.10.43   <none>        80/TCP    7d

NAMESPACE          NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
kcp-35774k02n7jg   deployment.apps/blue-nginx   3/3     3            3           7d

NAMESPACE          NAME                              READY   STATUS    RESTARTS   AGE
kcp-35774k02n7jg   pod/blue-nginx-65bd57bccb-6fbkf   1/1     Running   0          6d18h
kcp-35774k02n7jg   pod/blue-nginx-65bd57bccb-7h4b2   1/1     Running   0          6d18h
kcp-35774k02n7jg   pod/blue-nginx-65bd57bccb-d4zwm   1/1     Running   0          6d18h
root@cluster2-control-plane:/# curl 10.96.10.43
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
