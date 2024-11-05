provider "google" {
  project = var.project_name
  region  = var.region
}

# Artifact Registry for Docker images
resource "google_artifact_registry_repository" "artifact_repo" {
  location     = var.region
  repository_id = var.artifact_registry_name
  format       = "DOCKER"
  description  = "Artifact Registry for Cloud Run service images"
}

# Secret Manager for storing secrets
resource "google_secret_manager_secret" "my_secret" {
  secret_id = var.secret_id
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "my_secret_version" {
  secret      = google_secret_manager_secret.my_secret.id
  secret_data = "<YOUR_SECRET_VALUE>"
}

# MemoryStore (Redis) for caching
resource "google_redis_instance" "redis_instance" {
  name           = var.redis_instance_name
  tier           = "STANDARD_HA"
  memory_size_gb = 1
  location_id    = var.region
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
  name        = var.cloud_armor_policy_name
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

# Global IP for Load Balancer
resource "google_compute_global_address" "lb_ip" {
  name = "hpoll-quest-lb-ip"
}

# Backend Service for Cloud Run
resource "google_compute_backend_service" "cloud_run_backend" {
  name                  = "cloud-run-backend"
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 60

  backend {
    group = google_cloud_run_service.cloud_run_service.id
  }

  health_checks = [google_compute_health_check.cloud_run_health_check.self_link]
}

# Health Check for Cloud Run
resource "google_compute_health_check" "cloud_run_health_check" {
  name               = "cloud-run-health-check"
  check_interval_sec = 10
  timeout_sec        = 5
  http_health_check {
    port_specification = "USE_SERVING_PORT"
    request_path       = "/"
  }
}

# URL Map
resource "google_compute_url_map" "url_map" {
  name            = var.url_map_name
  default_service = google_compute_backend_service.cloud_run_backend.self_link
}

# Target HTTP Proxy for the URL map
resource "google_compute_target_http_proxy" "http_proxy" {
  name   = "http-proxy"
  url_map = google_compute_url_map.url_map.self_link
}

# Forwarding Rule for Load Balancer
resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name        = "http-forwarding-rule"
  target      = google_compute_target_http_proxy.http_proxy.self_link
  port_range  = "80"
  load_balancing_scheme = "EXTERNAL"
  ip_address  = google_compute_global_address.lb_ip.address
}

# Optional: HTTPS Target Proxy and SSL Certificate
# Uncomment and set up if HTTPS is required

# resource "google_compute_ssl_certificate" "ssl_cert" {
#   name        = "ssl-cert"
#   private_key = file("path/to/private_key.pem")
#   certificate = file("path/to/certificate.pem")
# }

# resource "google_compute_target_https_proxy" "https_proxy" {
#   name        = "https-proxy"
#   url_map     = google_compute_url_map.url_map.self_link
#   ssl_certificates = [google_compute_ssl_certificate.ssl_cert.self_link]
# }

# resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
#   name        = "https-forwarding-rule"
#   target      = google_compute_target_https_proxy.https_proxy.self_link
#   port_range  = "443"
#   load_balancing_scheme = "EXTERNAL"
#   ip_address  = google_compute_global_address.lb_ip.address
# }
