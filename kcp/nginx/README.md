Examples of scheduling customized workloads to multiple clusters, using kcp as the control plane.

## Scenario 1
Scenario 1 simuates a simple blue-green deployment. Works great!
```text
             ┌─my-org workspace────┐  ┌─TMC─┐
             │                     │  │     │
             │ ┌─green ns────────┐ │  │     │   ┌─pcluster1───────┐
   kustomize │ │                 │ │  │     │   │                 │
  ┌──────────┼─┼─► green nginx ──┼─┼──┼─────┼───┼─► green nginx   │
  │          │ │                 │ │  │     │   │                 │
  │          │ └─────────────────┘ │  │     │   └─────────────────┘
  │          │                     │  │     │
  │          │                     │  │     │
nginx        │                     │  │     │
  │          │                     │  │     │
  │          │                     │  │     │
  │          │ ┌─blue  ns────────┐ │  │     │   ┌─pcluster2───────┐
  │kustomize │ │                 │ │  │     │   │                 │
  └──────────┼─┼─► blue  nginx ──┼─┼──┼─────┼───┼─► blue  nginx   │
             │ │                 │ │  │     │   │                 │
             │ └─────────────────┘ │  │     │   └─────────────────┘
             │                     │  │     │
             └─────────────────────┘  └─────┘
```

## Scenario 2
Scenario 2 tries to handle two blue clusters.
```text
             ┌─my-org workspace────┐  ┌─TMC─┐
             │                     │  │     │
             │ ┌─green ns────────┐ │  │     │   ┌─pcluster1───────┐
   kustomize │ │                 │ │  │     │   │                 │
  ┌──────────┼─┼─► green nginx ──┼─┼──┼─────┼───┼─► green nginx   │
  │          │ │                 │ │  │     │   │                 │
  │          │ └─────────────────┘ │  │     │   └─────────────────┘
  │          │                     │  │     │
  │          │                     │  │     │   ┌─pcluster2───────┐
nginx        │                     │  │     │   │                 │
  │          │                     │  │  ┌──┼───┼─► blue  nginx   │
  │          │ ┌─blue  ns────────┐ │  │  │  │   │                 │
  │kustomize │ │                 │ │  │  │  │   └─────────────────┘
  └──────────┼─┼─► blue  nginx ──┼─┼──┼─ ?  │
             │ │                 │ │  │  │  │   ┌─pcluster3───────┐
             │ └─────────────────┘ │  │  │  │   │                 │
             │                     │  │  └──┼───┼─► blue  nginx   │
             │                     │  │     │   │                 │
             └─────────────────────┘  └─────┘   └─────────────────┘
```

Observations/thoughts with Scenario 2:
- It is observed that blue nginx is scheduled to exactly one pcluster at any time, which is captured by the `internal.workload.kcp.dev/synctarget` annotation on blue placement;
```console
$ kubectl get placement blue -oyaml
apiVersion: scheduling.kcp.dev/v1alpha1
kind: Placement
metadata:
  annotations:
    internal.workload.kcp.dev/synctarget: 97C5IAVqAokfA7cdMAexezYCp3dsdEdSXQ4oQr
    kcp.dev/cluster: root:my-org
```
- It looks like TMC selects that one pcluster [randomly](https://github.com/kcp-dev/kcp/blob/e33522c3e45bd8292d0893512293d640fe526209/pkg/reconciler/workload/placement/placement_reconcile_scheduling.go#L82);
- It is observed that TMC has 'failover' behavior ---  if pcluster2 is killed, blue nginx gets scheduled to pcluster3;
- For edge scenarios we want a way to write one Placement-ish object for blue and get nginx scheduled and synced to _every_ blue pcluster.

## Scenario 1 - steps to reproduce
Steps to reproduce Scenario 1 are listed as follows.

Steps to reproduce Scenario 2 are quite similar to those of Scenario 1 --- omitted here.
### Setup kcp and managed clusters
[kcp-skupper](https://github.com/ch007m/kcp-skupper) is used for quick setup of kcp.
[kind](https://kind.sigs.k8s.io/) is used to setup the pclusters/synctargets.

Kubernetes services are not synced by default, so it is necessary to explicitly tell kcp syncer to sync them. For example:
```console
$ ../kcp.sh syncer -w my-org -c cluster1 -r services
```

### Setup scheduling
Green workloads are scheduled by kcp's [TMC](https://github.com/kcp-dev/kcp/blob/main/docs/locations-and-scheduling.md), from `color: green` namespaces to `color: green` synctargets.
The same is true for blue.

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

Apply other scheduling manifests:
```console
$ kubectl apply -f examples/kcp/nginx/scheduling/
location.scheduling.kcp.dev/green created
location.scheduling.kcp.dev/blue created
namespace/green created
namespace/blue created
placement.scheduling.kcp.dev/green created
placement.scheduling.kcp.dev/blue created
```

### Run customized workloads

#### Green workload
Deploy:
```console
$ kubectl apply -k examples/kcp/nginx/deploy-green/
serviceaccount/nginx created
configmap/green-index created
configmap/my-index created
configmap/nginx created
service/nginx created
deployment.apps/nginx created
```

Access:
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

Remove:
```console
$ kubectl delete -k examples/kcp/nginx/deploy-green/
serviceaccount "nginx" deleted
configmap "green-index" deleted
configmap "my-index" deleted
configmap "nginx" deleted
service "nginx" deleted
deployment.apps "nginx" deleted
```

#### Blue workload
Similar to green workload:
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
