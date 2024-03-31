variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}
variable "task_definition_name" {
  description = "The name of the ECS task definition"
  type        = string
}
variable "container_name" {
  description = "The name of the ECS container"
  type        = string
}
variable "container_image" {
  description = "The image of the ECS task definition"
  type        = string
}
variable "container_port" {
  description = "The port of the ECS task definition container"
  type        = number
}

variable "api_gateway_name" {
  description = "The name of the ECS task definition"
  type        = string
}
variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}
variable "lambda1_name" {
  description = "The name of the first lambda function"
  type        = string
}
variable "lambda2_name" {
  description = "The name of the second lambda function"
  type        = string
}
variable "lambda3_name" {
  description = "The name of the third lambda function"
  type        = string
}
variable "domain_name" {
  description = "The domain name for the ACM certificate"
  type        = string
}
variable "hosted_zone_name" {
  description = "The name of the hosted zone"
  type        = string
}