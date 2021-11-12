terraform {
  backend "remote" {
    organization = "Mitel"
    workspaces {
      # Update this with the name of the repository including the trailing '-'
      prefix = "usage-mediation-"
    }
  }
}