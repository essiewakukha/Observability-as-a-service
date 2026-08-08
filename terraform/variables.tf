variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used on all resource names/tags"
  type        = string
  default     = "observability-as-a-service"
}
variable "short_name" {
  description = "Short prefix for resources with strict AWS length limits (ALB name <= 32 chars, target group name <= 32 chars)"
  type        = string
  default     = "oaas"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.10.0/24", "10.20.11.0/24"]
}

# ---- Web tier ----

variable "web_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "web_min_size" {
  type    = number
  default = 2
}

variable "web_max_size" {
  type    = number
  default = 4
}

variable "web_desired_capacity" {
  type    = number
  default = 2
}

# ---- App tier (ECS Fargate) ----

variable "container_image" {
  description = "App container image URI. Placeholder httpd image lets the stack deploy end-to-end before your real app image exists."
  type        = string
  default     = "public.ecr.aws/docker/library/httpd:latest"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "task_cpu" {
  type    = string
  default = "256"
}

variable "task_memory" {
  type    = string
  default = "512"
}

variable "app_desired_count" {
  type    = number
  default = 2
}

# ---- Data tier (RDS) ----

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_master_username" {
  type    = string
  default = "admin"
}

variable "db_master_password" {
  description = "RDS master password. Pass via TF_VAR_db_master_password env var or a .tfvars file that is NOT committed to git."
  type        = string
  sensitive   = true
}
variable "notification_email" {
  description = "Email address for on-call SNS alerts. Leave empty to skip creating an email subscription."
  type        = string
  default     = ""
}
