environment = "alpha"

project_ids = {
  na = "na-alpha-usage-mediation-01"
}

regions = {
  na = "us-central1"
}

service_accounts = {
  na_na = "usage-mediation-repo@na-alpha-usage-mediation-01.iam.gserviceaccount.com"
}

subscriptions = {
  na_na = {
    project = "na-alpha-connect-eventbus-01",
    topic   = "connect.cdr.calllog",
    region  = "US"
  }
}