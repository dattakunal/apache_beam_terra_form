#!/bin/bash -ex

function check_namespace() {
  if ! kubectl get namespaces | grep -q "$1" ;
  then
    echo "$1 namespace does not exist!"
    exit 1
  else
    echo "$1 namespace exists."
  fi
}

# Make sure namespace exists before running any apply components
check_namespace "${NAMESPACE}"

crd_name="applications.app.k8s.io"
crd_template="$templates/app-crd.yaml"

if ! kubectl get customresourcedefinitions | grep -q "$crd_name" ;
then
  if [ -e "$crd_template" ];
  then
    echo "Applying CRD template..."
    kubectl apply -f "$crd_template"
  else
    echo "File $crd_template is not present."
  fi
else
  echo "CRD already applied..."
fi

arg_array=("$@")
for service_name in "${arg_array[@]}"
do
  echo "***************$service_name***************"
  templates="${BITBUCKET_CLONE_DIR}/kubernetes/templates/$service_name"
  shared_template="${BITBUCKET_CLONE_DIR}/kubernetes/templates/shared/${NAMESPACE}-configmap.yaml"
  net_policy_outboud="$templates/allow-outbound.yaml"
  net_policy_inbound="$templates/allow-inbound.yaml"

  if [ "$service_name" == "rabbitmq" ] ;
  then
    metadata_template="$templates/allow-outbound-metadata.yaml"
    manifest_template="$templates/manifest.yaml"
    rbac_template="$templates/rbac.yaml"

    template_list=("$net_policy_inbound" "$net_policy_outboud" "$metadata_template" "$rbac_template" "$manifest_template")
  elif [ "$service_name" == "cassandra" ] ;
  then
    manifest_template="$templates/manifest.yaml"
    template_list=("$net_policy_inbound" "$net_policy_outboud" "$manifest_template")
  else
    configmap_template="$templates/${NAMESPACE}-configmap.yaml"
    manifest_template="$templates/manifest.yaml"
    template_list=("$net_policy_inbound" "$net_policy_outboud" "$configmap_template" "$shared_template" "$manifest_template")
  fi

  # Apply the rest of the templates only if diff is present
  for template_file in "${template_list[@]}"
  do
    if [[ $(kubectl diff -f "$template_file" -n "${NAMESPACE}") ]];
    then
      echo "Applying $template_file..."
      kubectl apply -f "$template_file" -n "${NAMESPACE}" || echo "Apply unsuccessful for $template_file."
    else
      echo "No changes found, skipping $template_file apply..."
    fi
    echo "-----------------------------------------"
  done
  echo "*************************************"
done

