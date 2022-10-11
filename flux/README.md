#### How to use `wrap4kyst` with GitHub Actions
See [this example](../.github/workflows/use-wrap4kyst.yml). In the example:
- The owner of the 'guestbook' application makes changes to corresponding standard k8s object(s);
- The owner pushes the changes to a branch named `update`;
- GitHub Actions automatically uses `wrap4kyst` to 'translate' the changed object(s) into latest kyst CRs;
- GitHub Actions automatically makes a commit for the latest kyst CRs;
- GitHub Actions automatically opens a PR for the owner's changes and the latest kyst CRs;
- Once approved and merged, the latest kyst CRs are ready to be delivered by flux.

#### How to deliver the 'guestbook' application as kyst CRs
Use flux:
```shell
flux create source git guestbook \
  --url=https://github.com/edge-experiments/gitops-source \
  --branch=main \
  --interval=1m
```

```shell
flux create kustomization guestbook-default \
  --source=guestbook \
  --path="./kubernetes/guestbook/deploy-flux" \
  --prune=true \
  --validation=client \
  --interval=1m
```

The output should be similar to:
```console
👉 gitops-source $ kc get gitrepo,ks
NAME                                               URL                                                       AGE   READY   STATUS
gitrepository.source.toolkit.fluxcd.io/guestbook   https://github.com/edge-experiments/gitops-source   29s   True    stored artifact for revision 'main/c8df4e9df49792a7442463ef10c7b8d0119eeac9'

NAME                                                          AGE   READY   STATUS
kustomization.kustomize.toolkit.fluxcd.io/guestbook-default   17s   True    Applied revision: main/c8df4e9df49792a7442463ef10c7b8d0119eeac9
```

Check the delivered kyst CRs:
```console
👉 gitops-source $ kubectl get configspec,devicegroup -n default
NAME                                  AGE
configspec.edge.kyst.kube/guestbook   36s

NAME                                    AGE
devicegroup.edge.kyst.kube/guestbook1   36s
```
