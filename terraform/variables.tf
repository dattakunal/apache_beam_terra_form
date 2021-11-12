//Example input variable
//variable "project_ids" {
//  description = "A map of project IDs for app name"
//  type        = map(string)
//}

variable "environment" {
  description = "Name of the current deployment environment."
  type        = string
}

variable "project_ids" {
  description = "A map of project IDs for mm-connect-monit"
  type        = map(string)
}

variable "regions" {
  description = "Name of the regions."
  type        = map(string)
}

variable "service_accounts" {
  description = "Name of the service accounts."
  type        = map(string)
}

variable "subscriptions" {
  description = "Name of subscriptions."
  type = map(object({
    project = string,
    topic   = string,
    region  = string
    }
  ))
}