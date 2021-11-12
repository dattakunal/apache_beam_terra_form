#!/bin/bash -ex
# This script creates a json keyfile from the GOOGLE_CREDENTIALS environment variable,
# which should be set as a secret repository variable in the Bitbucket Pipelines settings,
# then uses it to authenticate with GCP.
echo "${GOOGLE_CREDENTIALS}" > key.json
gcloud auth activate-service-account --key-file=./key.json
