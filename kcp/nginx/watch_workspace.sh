#!/bin/bash

echo "In 'root:my-org:edge' workspace:\n" &&
kubectl get namespace,placement,location
yes '' | sed 5q

echo "In 'green' namespace:\n" &&
kubectl -n green get deployment,svc
yes '' | sed 5q

echo "In 'blue' namespace:\n" &&
kubectl -n blue get deployment,svc
yes '' | sed 5q
