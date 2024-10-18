# Create a Cloud Run Job
resource "google_cloud_run_v2_job" "test" {
  name     = "test"
  location = var.region

  template {
    template {
      containers {
        image = var.container_image

        # Command and arguments for the container
        command = ["java"]
        args    = ["-jar", "/app/*.jar"]

        # Resource limits: memory and CPU
        resources {
          limits = {
            memory = "5Gi"
            cpu    = "2000m"
          }
        }

        # Environment variables
        env {
          name  = "export.templates.path.s3"
          value = "..."
        }
      }
    }
  }

  # Set the timeout for the job execution
  execution_timeout {
    seconds = 6000  # Convert "6000s" to integer value in seconds
  }
}

# Optionally, add IAM permissions for invokers (if needed)
resource "google_cloud_run_v2_job_iam_member" "job_invoker" {
  job_name = google_cloud_run_v2_job.test.name
  role     = "roles/run.invoker"
  member   = ""
}
