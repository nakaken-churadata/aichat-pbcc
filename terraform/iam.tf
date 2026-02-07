resource "google_cloud_run_v2_service_iam_member" "public_access" {
  name     = google_cloud_run_v2_service.chat_app.name
  location = google_cloud_run_v2_service.chat_app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
