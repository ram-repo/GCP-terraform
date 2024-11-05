variable "project_name" {
  description = "The name of the GCP project"
  type        = string
  default     = "hpoll-quest-tqb-dev"
}

variable "region" {
  description = "The region for GCP resources"
  type        = string
  default     = "us-central1"
}

variable "artifact_registry_name" {
  description = "Name of the Artifact Registry repository"
  type        = string
  default     = "my-repo"
}

variable "secret_id" {
  description = "Secret ID for Secret Manager"
  type        = string
  default     = "my-secret"
}

variable "cloud_run_service_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "ai-langchain-service"
}

variable "redis_instance_name" {
  description = "MemoryStore Redis instance name"
  type        = string
  default     = "my-redis-instance"
}

variable "vpc_connector_name" {
  description = "Serverless VPC Connector name"
  type        = string
  default     = "serverless-vpc-connector"
}

variable "url_map_name" {
  description = "URL Map name for routing"
  type        = string
  default     = "hpoll-quest-dev-ai-url-map"
}

variable "cloud_armor_policy_name" {
  description = "Cloud Armor policy name"
  type        = string
  default     = "cloud-armor-policy"
}
