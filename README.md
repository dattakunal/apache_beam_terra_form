# Terraform and apache beam code

**Check the terraform and source folder**

This code contains terraform and apache beam.
The terraform code(main.tf) code is doing below things:
* Create temporary bucket in GCP that is used by Apache Beam.
* Create a bucket for apache beam template.
* Create a subscription for a pubsub that is in different project.
* Create Big Query table in GCP using schema json files.
* Create the apache beam template using python code.
* Create the dataflow using the template.

The apache beam code is doing below things:
* Create a pipelines as below:
  * Read the subscription to get the data.
  * Choose the table from the mapping in a JSON file
  * Parse the data and based on the type of the data insert the data in different big query table

![image](https://user-images.githubusercontent.com/47130122/141496680-12240c88-68d6-4a03-9232-e7f679fc18e5.png)
