#### How to use `wrap4kyst` with GitHub Actions
See [this example](../.github/workflows/use-wrap4kyst.yml). In the example:
- The owner of the 'guestbook' application makes changes to corresponding standard k8s object(s);
- The owner pushes the changes to a branch named `update`;
- GitHub Actions automatically uses `wrap4kyst` to 'translate' the changed object(s) into latest kyst CRs;
- GitHub Actions automatically makes a commit for the latest kyst CRs;
- GitHub Actions automatically opens a PR for the owner's changes and the latest kyst CRs;
- Once approved and merged, the latest kyst CRs are ready to be delivered by flux.

#### How to deliver the 'guestbook' application (as kyst CRs) with flux:
```console
$ flux create source git guestbook \
>   --url=https://github.com/edge-experiments/gitops-source \
>   --branch=main \
>   --interval=1m
✚ generating GitRepository source
► applying GitRepository source
✔ GitRepository source created
◎ waiting for GitRepository source reconciliation
✔ GitRepository source reconciliation completed
✔ fetched revision: main/20517fdfc0567dbefd7e7ea8e46eec099ffb7168
```

```console
$ flux create kustomization guestbook \
>   --source=guestbook \
>   --path="./kubernetes/guestbook/deploy-flux" \
>   --prune=true \
>   --validation=client \
>   --interval=10m
Flag --validation has been deprecated, this arg is no longer used, all resources are validated using server-side apply dry-run
✚ generating Kustomization
► applying Kustomization
✔ Kustomization created
◎ waiting for Kustomization reconciliation
✔ Kustomization guestbook is ready
✔ applied revision main/20517fdfc0567dbefd7e7ea8e46eec099ffb7168
```

```console
👉 gitops-source $ kubectl get gitrepo,ks -n flux-system
NAME                                                 URL                                                 AGE   READY   STATUS
gitrepository.source.toolkit.fluxcd.io/guestbook     https://github.com/edge-experiments/gitops-source   11m   True    stored artifact for revision 'main/20517fdfc0567dbefd7e7ea8e46eec099ffb7168'

NAME                                                    AGE   READY   STATUS
kustomization.kustomize.toolkit.fluxcd.io/guestbook     58s   True    Applied revision: main/20517fdfc0567dbefd7e7ea8e46eec099ffb7168
```

Check the delivered kyst CRs:
```console
👉 gitops-source $ kubectl get devicegroup,configspec
NAME                                            AGE
devicegroup.edge.kyst.kube/guestbook1           1m3s

NAME                                          AGE
configspec.edge.kyst.kube/guestbook           1m3s
```
