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

#### Distribute kubeturbo via Argo CD in pull mode
The installation of kubeturbo doesn't really rely on the control plane's cross-cluster scheduling capability.
Because, as an agent, it is going to be installed on every cluster.
What really relies on the control plane's cross-cluster scheduling capability is the users' workloads.

Therefore, a reasonable design is to
- use kcp to schedule users' workloads, with the inputs from Turbonomic's analysis;
- use Argo CD (only, no kcp) to distribute and maintain the agent, kubeturbo.

By doing this
- we are using kcp in the currently 'expected/designed' way ("the syncer is specialiized on workload APIs");
- we don't lose the benefit to manage the lifecycle of kubeturbo in the GitOps way.

Meanwhile, it looks like the resource consumption of a fresh Argo CD is pretty low:
```console
$ kubectl -n argocd top pods
NAME                                                CPU(cores)   MEMORY(bytes)   
argocd-application-controller-0                     2m           40Mi            
argocd-applicationset-controller-74558d8789-c2vn8   1m           19Mi            
argocd-dex-server-5bf8b66b55-92dpk                  1m           16Mi            
argocd-notifications-controller-dc5d7dd6-dvb47      1m           17Mi            
argocd-redis-6fd7cbd95d-s2pbh                       1m           2Mi             
argocd-repo-server-7c57dc5975-ggng8                 1m           44Mi            
argocd-server-7c85877d9d-cg2p6                      2m           28Mi
```
Thus it is viable to use the pull mode to install and maintain kubeturbo.
Pull mode also makes more sense from the security and scalability points of view.

First, install Argo CD on a cluster. Then:
```console
ubuntu@ip-172-31-31-125:~$ kubectl config current-context
kind-cluster1
ubuntu@ip-172-31-31-125:~$ cat <<EOF | kubectl apply -f -
> apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kubeturbo
  namespace: argocd
spec:
  destination:
    namespace: turbonomic
    server: https://kubernetes.default.svc
  project: default
  source:
    path: turbonomic/kubeturbo/manifests/
    repoURL: https://github.com/edge-experiments/gitops-source.git
    targetRevision: main
  syncPolicy:
    automated:
      prune: true
> EOF
application.argoproj.io/kubeturbo created
ubuntu@ip-172-31-31-125:~$ kubectl -n turbonomic get all
NAME                             READY   STATUS    RESTARTS   AGE
pod/kubeturbo-7866f446cb-5v2gc   1/1     Running   0          6m14s

NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/kubeturbo   1/1     1            1           6m14s

NAME                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/kubeturbo-7866f446cb   1         1         1       6m14s
```
A new Target shows up in Turbonomic UI.

#### Customization for multiple clusters
With Argo CD installed:
```shell
kubectl -n argocd apply -f turbonomic/kubeturbo/argocd-app-cluster1.yaml
```

A Target named `Kubernetes-Turbonomic-Cluster1` will appear in Turbonomic UI.
In the UI, go to "SETTINGS" -> "Target Configuration", check the Target, click "VALIDATE".
Then the log of kubeturbo should show something similar to:
```
I1013 17:07:36.089183       1 turbo_probe.go:126] Validate Target: [key:"targetIdentifier" stringValue:"Kubernetes-Turbonomic-Cluster1" key:"masterHost" stringValue:"https://10.96.0.1:443" key:"serverVersion" stringValue:"v1.25.2" key:"image" stringValue:"docker.io/turbonomic/kubeturbo:8.6.2" key:"imageID" stringValue:"sha256:1813c1df04d3e29fdb9fa6634cf82927ec64aae38c4bbc1d08a1771c3a1649fc" key:"probeVersion" stringValue:"8.6.2"]
I1013 17:07:36.089366       1 k8s_discovery_client.go:196] Validating Kubernetes target...
I1013 17:07:36.097257       1 cluster_processor.go:119] There are 1 nodes.
I1013 17:07:36.132793       1 cluster_processor.go:79] Successfully verified node cluster1-control-plane.
I1013 17:07:36.132823       1 cluster_processor.go:137] Successfully connected to at least some nodes.
I1013 17:07:36.132849       1 k8s_discovery_client.go:212] Successfully validated target.
```

#### Dummy workloads on clusters
Some dummy [workloads](turbonomic/workloads) can be used to simulate unbalanced workloads across the clusters.
For example, calculation of pi is CPU intensive:
```
$ kubectl top po
NAME                       CPU(cores)   MEMORY(bytes)   
pi-nf8gm                   1000m        12Mi
```
This imbalance should affect Turbonomic's scheduling decisions for incoming workloads.
