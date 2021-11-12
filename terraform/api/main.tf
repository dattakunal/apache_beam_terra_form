locals {
  # Example of a map of project ids
  appname_project_ids = {
    dev = {
      na = "na-dev-usage-mediation-01"
    }
    alpha = {
      na = "na-alpha-usage-mediation-01"
    }
    prod = {
      na = "na-prod-usage-mediation-01"
    }
  }

  # Starter list for APIs to enable in GCP
  api_services = [
    "bigquery.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "dataflow.googleapis.com",
    "serviceusage.googleapis.com",
  ]

  project_services = flatten([
    for api in local.api_services : [
      for projects in local.appname_project_ids[var.environment] : {
        object_key = "${projects}_${api}"
        api        = api
        project    = projects
      }
    ]
  ])
}

# Certain services do not come enabled upon intital project creation, enable them for each project
# This can be created for each project environment
resource "google_project_service" "service_dev" {
  for_each                   = { for services in local.project_services : services.object_key => services }
  project                    = each.value.project
  service                    = each.value.api
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "service_alpha" {
  for_each                   = { for services in local.project_services : services.object_key => services }
  project                    = each.value.project
  service                    = each.value.api
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "service_prod" {
  for_each                   = { for services in local.project_services : services.object_key => services }
  project                    = each.value.project
  service                    = each.value.api
  disable_dependent_services = false
  disable_on_destroy         = false
}
