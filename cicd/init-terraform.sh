#!/bin/bash -ex
# This script creates a terraform workspace configuration file
# and sets the token from the TERRAFORM_CLOUD_TOKEN environment variable
# which should be set as a secret environment variable in the Bitbucket Pipelines settings.
cat <<EOF > "${HOME}/.terraformrc"
credentials "app.terraform.io" {
  token = "${TERRAFORM_CLOUD_TOKEN}"
}
EOF
