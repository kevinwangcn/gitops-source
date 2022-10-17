### Overview
This example uses GitOps and kcp to simulate a blue-green deployment of nginx.
It is done in two steps:
1. use GitOps to deliver customized nginx, as well as the scheduling decisions, to kcp;
2. use kcp to schedule the customized nginx to two kcp pclusters/SyncTargets by executing the scheduling decisions.

```text
             ┌─my-org workspace────┐  ┌─TMC─┐
             │                     │  │     │
             │ ┌─green ns────────┐ │  │     │   ┌─pcluster1───────┐
   gitops    │ │                 │ │  │     │   │                 │
  ┌──────────┼─┼─► green nginx ──┼─┼──┼─────┼───┼─► green nginx   │
  │          │ │                 │ │  │     │   │                 │
  │          │ └─────────────────┘ │  │     │   └─────────────────┘
  │          │                     │  │     │
nginx &      │                     │  │     │
scheduling   │                     │  │     │
decisions    │                     │  │     │
  │          │                     │  │     │
  │          │ ┌─blue  ns────────┐ │  │     │   ┌─pcluster2───────┐
  │gitops    │ │                 │ │  │     │   │                 │
  └──────────┼─┼─► blue  nginx ──┼─┼──┼─────┼───┼─► blue  nginx   │
             │ │                 │ │  │     │   │                 │
             │ └─────────────────┘ │  │     │   └─────────────────┘
             │                     │  │     │
             └─────────────────────┘  └─────┘
```

### Setup kcp and managed clusters
[kcp-skupper](https://github.com/ch007m/kcp-skupper) is used for quick setup of kcp.
[kind](https://kind.sigs.k8s.io/) is used to setup the pclusters/synctargets.

Kubernetes services are not synced by default, so it is necessary to explicitly tell kcp syncer to sync them. For example:
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

Label the synctargets:
```console
$ kubectl label synctarget cluster1 color=green
synctarget.workload.kcp.dev/cluster1 labeled
$ kubectl label synctarget cluster2 color=blue
synctarget.workload.kcp.dev/cluster2 labeled
```

### Using GitOps tools
First, use your favorite GitOps tools to deliver scheduling manifests in [scheduling/](scheduling/).

For example, with Argo CD:
```
argocd app create scheduling \
--repo https://github.com/edge-experiments/gitops-source.git \
--path kcp/nginx/scheduling/ \
--dest-server https://172.31.31.125:6443/clusters/root:my-org
```

Then, deliver workload (nginx) manifests in [deploy-green/](deploy-green/) and [deploy-blue/](deploy-blue/).

### Check the delivered workloads
#### Green workload
```console
$ docker exec -it cluster1-control-plane bash
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
