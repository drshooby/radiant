variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_zone_id" {
  type = string
}

variable "s3_bucket_name" {
  type    = string
  default = "brutus.ettukube.com"
}
