resource "google_cloud_run_v2_service" "chat_app" {
  name     = var.service_name
  location = var.region

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_name}/${var.service_name}:${var.image_tag}"

      ports {
        container_port = 3000
      }

      env {
        name  = "AGENT_SERVICE_URL"
        value = google_cloud_run_v2_service.agent_service.uri
      }
    }

    service_account = google_service_account.cloud_run.email
  }

  depends_on = [google_project_service.apis]
}

resource "google_service_account" "cloud_run" {
  account_id   = "${var.service_name}-sa"
  display_name = "Cloud Run Service Account for ${var.service_name}"
}

