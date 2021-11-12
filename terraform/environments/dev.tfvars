# Example of a map of project ids
//project_ids = {
//  na = "na-dev-app-name-01"
//  au = "au-dev-app-name-01"
//}

environment = "dev"

project_ids = {
  na = "na-dev-usage-mediation-01"
}

regions = {
  na = "us-central1"
}

service_accounts = {
  na_na = "usage-mediation-repo@na-dev-usage-mediation-01.iam.gserviceaccount.com"
}

subscriptions = {
  na_na = {
    project = "na-dev-connect-eventbus-01",
    topic   = "connect.cdr.calllog",
    region  = "US"
  }
}