terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Artifact Registry Repository
resource "google_artifact_registry_repository" "chat_app" {
  location      = var.region
  repository_id = "chat-app"
  description   = "Docker repository for chat application"
  format        = "DOCKER"
}

# Cloud Run Service - Backend
resource "google_cloud_run_v2_service" "backend" {
  name     = "chat-backend"
  location = var.region

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/chat-app/backend:latest"

      ports {
        container_port = 8080
      }

      env {
        name = "NODE_ENV"
        value = "production"
      }

      env {
        name = "ALLOWED_ORIGINS"
        value = var.frontend_url != "" ? var.frontend_url : "https://chat-frontend-${random_id.suffix.hex}-${data.google_project.project.number}.${var.region}.run.app"
      }

      env {
        name = "GEMINI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.gemini_api_key.secret_id
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# Cloud Run Service - Frontend
resource "google_cloud_run_v2_service" "frontend" {
  name     = "chat-frontend"
  location = var.region

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/chat-app/frontend:latest"

      ports {
        container_port = 8080
      }

      env {
        name = "NODE_ENV"
        value = "production"
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "256Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [google_cloud_run_v2_service.backend]
}

# Secret Manager - GEMINI API Key
resource "google_secret_manager_secret" "gemini_api_key" {
  secret_id = "GEMINI_API_KEY"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "gemini_api_key_version" {
  secret      = google_secret_manager_secret.gemini_api_key.id
  secret_data = var.gemini_api_key
}

# IAM - Cloud Run Invoker (Public Access)
resource "google_cloud_run_v2_service_iam_member" "backend_public" {
  name   = google_cloud_run_v2_service.backend.name
  location = google_cloud_run_v2_service.backend.location
  role   = "roles/run.invoker"
  member = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "frontend_public" {
  name   = google_cloud_run_v2_service.frontend.name
  location = google_cloud_run_v2_service.frontend.location
  role   = "roles/run.invoker"
  member = "allUsers"
}

# IAM - Secret Manager Access for Backend
resource "google_secret_manager_secret_iam_member" "backend_secret_access" {
  secret_id = google_secret_manager_secret.gemini_api_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# Random suffix for unique names
resource "random_id" "suffix" {
  byte_length = 4
}

# Data source for project information
data "google_project" "project" {
  project_id = var.project_id
}
