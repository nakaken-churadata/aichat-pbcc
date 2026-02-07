resource "google_cloud_run_v2_service" "agent_service" {
  name     = var.agent_service_name
  location = var.region

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_name}/${var.agent_service_name}:${var.image_tag}"

      ports {
        container_port = 8080
      }

      env {
        name = "GOOGLE_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.gemini_api_key.secret_id
            version = "latest"
          }
        }
      }
    }

    service_account = google_service_account.agent_service.email
  }

  depends_on = [google_project_service.apis]
}

resource "google_service_account" "agent_service" {
  account_id   = "${var.agent_service_name}-sa"
  display_name = "Cloud Run Service Account for ${var.agent_service_name}"
}

# Allow the agent service account to access the Gemini API key secret
resource "google_secret_manager_secret_iam_member" "agent_secret_access" {
  secret_id = google_secret_manager_secret.gemini_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.agent_service.email}"
}

# Allow the chat-app service account to invoke the agent service
resource "google_cloud_run_v2_service_iam_member" "chat_app_invokes_agent" {
  name     = google_cloud_run_v2_service.agent_service.name
  location = google_cloud_run_v2_service.agent_service.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.cloud_run.email}"
}
