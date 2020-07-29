#!/bin/sh

set -eu
VAMP_INSTALLER_VERSION=0.0.1-alpha-23
VAMP_INSTALLER_IMAGE=${DEFAULT_VAMP_INSTALLER_IMAGE:=vampio/k8s-installer:$VAMP_INSTALLER_VERSION}
VAMP_INSTALLER_BOOTSTRAP_YAML=${DEFAULT_VAMP_BOOTSTRAP_YAML:=https://raw.githubusercontent.com/magneticio/vamp-cloud-installer/master/bootstrap-policy.yaml}

# Apply policy required to be able to create the resources.
kubectl apply -f "$VAMP_INSTALLER_BOOTSTRAP_YAML"

# Run nats-setup container containing the latest set of manifests.
kubectl run vamp-cloud-installer --image-pull-policy=Always --serviceaccount=vamp-cloud-installer --image=$VAMP_INSTALLER_IMAGE --restart=Never

# Wait for the setup container to start or bail.
kubectl wait --for=condition=Ready pod/vamp-cloud-installer --timeout=30s

# Pass the custom parameters to the nats-setup container image.
kubectl exec vamp-cloud-installer -- vamp-installer.sh "$@"

# Remove the required policy for setup purposes.
kubectl delete -f "$VAMP_INSTALLER_BOOTSTRAP_YAML"

# Remove the setup pod.
kubectl delete pod vamp-cloud-installer --grace-period=0 --force