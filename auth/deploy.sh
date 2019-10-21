#!env bash

if [[ -z $SKIP_CERTS ]]; then
  echo "=> create ca and certs"
  rm -rf tls/internal
  mkdir -p tls/internal
  go get -u github.com/google/easypki/cmd/easypki
  export PKI_ROOT=$(pwd)/tls/internal
  export PKI_ORGANIZATION="fld.systems"
  export PKI_ORGANIZATIONAL_UNIT="internal"
  export PKI_COUNTRY=GB
  export PKI_LOCALITY="London"
  export PKI_PROVINCE="Greater London"
  easypki create --filename ca.incident-response.fld.systems --ca ca.incident-response.fld.systems
  easypki create authn.incident-response.svc.cluster.local --ca-name ca.incident-response.fld.systems
  easypki create authz.incident-response.svc.cluster.local --ca-name ca.incident-response.fld.systems
  easypki create proxy.incident-response.svc.cluster.local --ca-name ca.incident-response.fld.systems
  echo "=> create tls secrets"
  kubectl -n incident-response create secret tls authn-tls \
    --cert=tls/internal/ca.incident-response.fld.systems/certs/authn.incident-response.svc.cluster.local.crt \
    --key=tls/internal/ca.incident-response.fld.systems/keys/authn.incident-response.svc.cluster.local.key --dry-run -o yaml >k8s/secret-authn-tls.yaml
  kubectl -n incident-response create secret tls authz-tls \
    --cert=tls/internal/ca.incident-response.fld.systems/certs/authz.incident-response.svc.cluster.local.crt \
    --key=tls/internal/ca.incident-response.fld.systems/keys/authz.incident-response.svc.cluster.local.key --dry-run -o yaml >k8s/secret-authz-tls.yaml
  kubectl -n incident-response create secret tls proxy-tls \
    --cert=tls/internal/ca.incident-response.fld.systems/certs/proxy.incident-response.svc.cluster.local.crt \
    --key=tls/internal/ca.incident-response.fld.systems/keys/proxy.incident-response.svc.cluster.local.key --dry-run -o yaml >k8s/secret-proxy-tls.yaml
  kubectl -n incident-response create secret generic ca-tls \
    --from-file="ca.crt"="tls/internal/ca.incident-response.fld.systems/certs/ca.incident-response.fld.systems.crt" --dry-run -o yaml >k8s/secret-ca-tls.yaml
fi

echo "=> clone response-secrets"
git clone git@github.com:Feeld/response-secrets.git _response-secrets

echo "=> decrypt response-secrets repo"
(
  cd _response-secrets
  git-crypt unlock
)

echo "=> copy secret.yaml"
cp _response-secrets/k8s/secret.yaml k8s/

echo "=> remove cloned repo"
rm -rf _response-secrets

echo "=> create incident-response namespace"
kubectl create namespace incident-response

echo "=> delete old ingress"
kubectl -n incident-response delete ingress response

echo "=> delete old nodeport service"
kubectl -n incident-response delete service response

echo "=> deploy manifests"
kubectl apply -n incident-response -f k8s
