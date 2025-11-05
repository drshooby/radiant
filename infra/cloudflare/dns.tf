resource "cloudflare_record" "brutus" {
  zone_id = var.cloudflare_zone_id
  name    = "brutus"
  content = "${var.s3_bucket_name}.s3-website-us-east-1.amazonaws.com"
  type    = "CNAME"
  proxied = true
}
