locals {
  project_regions = flatten([
    for project_id in keys(var.project_ids) : [
      for region in keys(var.regions) : {
        object_key = "${project_id}_${region}"
        project    = var.project_ids[project_id]
        region     = var.regions[region]
        job_name   = replace("usage_mediation-${var.project_ids[project_id]}-${var.regions[region]}", "_", "-")
        data_set   = replace("usage_mediation_${var.project_ids[project_id]}_${var.regions[region]}", "-", "_")
      }
    ]
  ])

  template_file_name = "usage_mediation_template_${formatdate("YYYYMMDDhhmmss", timestamp())}"
}

// create temporary bucket 
resource "google_storage_bucket" "um_tmp_bucket" {
  for_each      = { for objects in local.project_regions : objects.object_key => objects }
  project       = each.value["project"]
  name          = "${each.value["project"]}_${each.value["region"]}_um_tmp_${var.environment}"
  force_destroy = false
}

// create template bucket 
resource "google_storage_bucket" "um_template_bucket" {
  for_each      = { for objects in local.project_regions : objects.object_key => objects }
  project       = each.value["project"]
  name          = "${each.value["project"]}_${each.value["region"]}_um_template_${var.environment}"
  force_destroy = false
}

// create subscriber on remote pubsub

resource "google_pubsub_subscription" "dataflow_subscription" {
  for_each                = { for objects in local.project_regions : objects.object_key => objects }
  project                 = each.value["project"]
  name                    = "subscription_${var.subscriptions[each.key].project}_${var.subscriptions[each.key].topic}"
  topic                   = "projects/${var.subscriptions[each.key].project}/topics/${var.subscriptions[each.key].topic}"
  enable_message_ordering = true
}

// create dataset and table
module "bigquery" {
  for_each                   = { for objects in local.project_regions : objects.object_key => objects }
  source                     = "terraform-google-modules/bigquery/google"
  dataset_id                 = each.value["data_set"]
  description                = "Usage mediation dataset for projrct ${each.value["project"]} and region ${each.value["region"]}"
  delete_contents_on_destroy = true
  project_id                 = each.value["project"]
  location                   = var.subscriptions[each.key].region
  access = [
    {
      "role" : "roles/bigquery.dataEditor",
      "special_group" : "projectWriters"
    },
    {
      "role" : "roles/bigquery.dataOwner",
      "special_group" : "projectOwners"
    },
    {
      "role" : "roles/bigquery.dataOwner",
      "user_by_email" : "${var.service_accounts[each.key]}"
    },
    {
      "role" : "roles/bigquery.dataViewer",
      "special_group" : "projectReaders"
    }
  ]
  tables = [
    {
      table_id           = "call"
      schema             = file("schema/call.json")
      time_partitioning  = null
      range_partitioning = null
      expiration_time    = null
      clustering         = null
      labels             = null
    },
    {
      table_id           = "connect"
      schema             = file("schema/connect.json")
      time_partitioning  = null
      range_partitioning = null
      expiration_time    = null
      clustering         = null
      labels             = null
    },
    {
      table_id           = "call_segment"
      schema             = file("schema/call_segment.json")
      time_partitioning  = null
      range_partitioning = null
      expiration_time    = null
      clustering         = null
      labels             = null
    }
  ]
}

// create the template using apache beam script
resource "null_resource" "usage_mediation_scripts" {
  for_each = { for objects in local.project_regions : objects.object_key => objects }
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    //command = "chmod 744 usage_mediation.sh; ./usage_mediation.sh"
    command = "pip3 install --upgrade pip; pip3 install -r requirements.txt; python3 main.py"

    working_dir = "../source/"

    environment = {
      JOB_NAME      = each.value["job_name"]
      PROJECT       = each.value["project"]
      REGION        = each.value["region"]
      TMP_LOCATION  = "${google_storage_bucket.um_tmp_bucket[each.key].url}/temp"
      TEMPLATE_FILE = "${google_storage_bucket.um_template_bucket[each.key].url}/template/${local.template_file_name}"
      SUBSCRIPTION  = "projects/${each.value["project"]}/subscriptions/${google_pubsub_subscription.dataflow_subscription[each.key].name}"
      DATA_SET      = each.value["data_set"]
    }
  }
}

// create the dataflow
resource "google_dataflow_job" "usage_mediation_job" {
  for_each          = { for objects in local.project_regions : objects.object_key => objects }
  name              = each.value["job_name"]
  project           = each.value["project"]
  region            = each.value["region"]
  template_gcs_path = "${google_storage_bucket.um_template_bucket[each.key].url}/template/${local.template_file_name}"
  temp_gcs_location = "${google_storage_bucket.um_tmp_bucket[each.key].url}/temp"
  depends_on        = [null_resource.usage_mediation_scripts]
}

//create default vpc for dataflow-bigquery communication
resource "google_compute_network" "default_network" {
  project                 = var.project_ids.na
  name                    = "default"
  auto_create_subnetworks = true
  mtu                     = 1460
}