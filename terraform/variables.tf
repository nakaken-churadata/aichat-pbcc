variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-northeast1"
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "gemini-chat-app"
}

variable "repository_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "chat-app"
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

variable "agent_service_name" {
  description = "Cloud Run service name for the ADK agent"
  type        = string
  default     = "agent-service"
}
