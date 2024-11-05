provider "google" {
  project = var.project_name
  region  = var.region
}

# Artifact Registry for Docker images
resource "google_artifact_registry_repository" "artifact_repo" {
  location = var.region
  repository_id = var.artifact_registry_name
  format = "DOCKER"
  description = "Artifact Registry for Cloud Run service images"
}

# Secret Manager for storing secrets
resource "google_secret_manager_secret" "my_secret" {
  secret_id = var.secret_id
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "my_secret_version" {
  secret = google_secret_manager_secret.my_secret.id
  secret_data = "<YOUR_SECRET_VALUE>"
}

# MemoryStore (Redis) for caching
resource "google_redis_instance" "redis_instance" {
  name = var.redis_instance_name
  tier = "STANDARD_HA"
  memory_size_gb = 1
  location_id = var.region
}

# VPC Network for serverless
resource "google_compute_network" "serverless_vpc" {
  name = "serverless-vpc"
  auto_create_subnetworks = true
}

# Serverless VPC Connector
resource "google_vpc_access_connector" "vpc_connector" {
  name       = var.vpc_connector_name
  network    = google_compute_network.serverless_vpc.name
  region     = var.region
  ip_cidr_range = "10.8.0.0/28"
}

# Cloud Run service for AI LangChain Service
resource "google_cloud_run_service" "cloud_run_service" {
  name     = var.cloud_run_service_name
  location = var.region
  template {
    spec {
      containers {
        image = "us-central1-docker.pkg.dev/${var.project_name}/${var.artifact_registry_name}/my-image:latest"
        env {
          name  = "REDIS_HOST"
          value = google_redis_instance.redis_instance.host
        }
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Cloud Armor security policy
resource "google_compute_security_policy" "cloud_armor_policy" {
  name = var.cloud_armor_policy_name
  description = "Security policy for Cloud Armor to protect the Cloud Run service"
  rule {
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["0.0.0.0/0"]
      }
    }
    action = "allow"
  }
}

# URL Map for routing
resource "google_compute_url_map" "url_map" {
  name           = var.url_map_name
  default_service = google_cloud_run_service.cloud_run_service.status[0].url
}
