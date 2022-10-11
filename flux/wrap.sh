docker run \
--rm \
-v $(pwd)/kubernetes/guestbook:/guestbook \
-w /guestbook/deploy-flux \
junatibm/wrap4kyst:latest \
/wrap4kyst
