data "aws_availability_zones" "available" {
  state  = "available"
  region = var.region
}