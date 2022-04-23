/**
 * Available zones
 */

data "aws_availability_zones" "available" {
  state = "available"
}


data "aws_api_gateway_rest_api" "microservices_api" {
  name = var.api_gw_name
}