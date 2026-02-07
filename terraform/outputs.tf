output "cloud_run_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.chat_app.uri
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository path"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_name}"
}

output "agent_service_url" {
  description = "Agent Service Cloud Run URL"
  value       = google_cloud_run_v2_service.agent_service.uri
}
