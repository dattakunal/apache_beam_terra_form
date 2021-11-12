#!/bin/bash -x

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

diff_out="diff_results.log"
touch "$diff_out"

arg_array=("$@")
for service_name in "${arg_array[@]}"
do
  echo "***************$service_name***************" >> "$diff_out"
  templates="${BITBUCKET_CLONE_DIR}/kubernetes/templates/$service_name"
  shared_template="${BITBUCKET_CLONE_DIR}/kubernetes/templates/shared/${NAMESPACE}-configmap.yaml"
  inbound="$templates/allow-inbound.yaml"
  outboud="$templates/allow-outbound.yaml"
  if [ "$service_name" == "rabbitmq" ] ;
  then
    metadata="$templates/allow-outbound-metadata.yaml"
    manifest="$templates/manifest.yaml"
    rbac="$templates/rbac.yaml"
    template_list=("$inbound" "$outboud" "$metadata" "$rbac" "$manifest")
  elif [ "$service_name" == "cassandra" ] ;
  then
    manifest_template="$templates/manifest.yaml"
    template_list=("$inbound" "$outboud" "$manifest_template")
  else
    configmap_template="$templates/${NAMESPACE}-configmap.yaml"
    manifest_template="$templates/manifest.yaml"
    template_list=("$inbound" "$outboud" "$configmap_template" "$shared_template" "$manifest_template")
  fi

  for template_file in ${template_list[*]}
  do
    echo "Diff check for $template_file" >> "$diff_out"
    kubectl diff -f "$template_file" -n "${NAMESPACE}" &>> "$diff_out" || echo "Diff found for $template_file"
    echo "---------------------------------------" >> "$diff_out"
  done
done

cat "$diff_out"
rm -f "$diff_out"
