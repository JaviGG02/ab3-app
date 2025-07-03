variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Project     = "AB3"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
