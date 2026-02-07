resource "google_artifact_registry_repository" "chat_app" {
  location      = var.region
  repository_id = var.repository_name
  format        = "DOCKER"

  depends_on = [google_project_service.apis]
}
