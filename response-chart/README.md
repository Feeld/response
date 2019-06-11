# Response Helm chart

## Setup

- Install [Helm](https://github.com/helm/helm#install) on your machine
- Make sure you've your k8 context pointing to the right one: `kubectl config current-context`
- Have a posgres instance & DB accessible from your k8s cluster.
- Create the `.env` file on the response-chart folder.
   - Check the `env.example` file to see the variables needed on the `.env` one.
- Build & deploy the **response**, **cron** and **static** images to a registry accessible on your k8s cluster.

For example:
```sh
REPOSITORY=my-repository
VERSION=stable
RESPONSE_TAG=$REPOSITORY/response:$VERSION
CRON_TAG=$REPOSITORY/cron:$VERSION
STATIC_TAG=$REPOSITORY/static:$VERSION

docker build -f Dockerfile.response -t $RESPONSE_TAG . && docker push $RESPONSE_TAG
docker build -f Dockerfile.cron -t $CRON_TAG . && docker push $CRON_TAG
docker build -f Dockerfile.static -t $STATIC_TAG . && docker push $STATIC_TAG
```

## Installing the chart

The following will install the chart using `helm template` command.

```sh
RELEASE_NAME=response
RESPONSE_NAMESPACE=response
REPOSITORY=my-repository
VERSION=stable
RESPONSE_TAG=$REPOSITORY/response:$VERSION
CRON_TAG=$REPOSITORY/cron:$VERSION
STATIC_TAG=$REPOSITORY/static:$VERSION


# Create a k8s namespace for the response deployment
kubectl create ns $RESPONSE_NAMESPACE

# Deploy response on the cluster
helm template response-chart \
--name $RELEASE_NAME \
--namespace=$RESPONSE_NAMESPACE \
--set response.image.repository="$RESPONSE_TAG" \
--set responseStatic.image.repository="$STATIC_TAG" \
--set cron.image.repository="$CRON_TAG" \
| kubectl apply -f -
```

Check the `values.yaml` file to see the other values that can be overwritten.

## Tear down
```sh
RELEASE_NAME=response
kubectl delete all -l app.kubernetes.io/instance=$RELEASE_NAME
kubectl delete cm -l app.kubernetes.io/instance=$RELEASE_NAME
kubectl delete ingress -l app.kubernetes.io/instance=$RELEASE_NAME
kubectl delete pvc -l app.kubernetes.io/instance=$RELEASE_NAME
```
