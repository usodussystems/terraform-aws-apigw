locals {
  tags = {
    ModificationDate = timestamp()
    # Console | Terraform | Ansible | Packer
    Builder = "Terraform"
    # Client Infos
    Applictation = var.application
    Project      = var.project
    Environment  = local.environment[var.environment]
  }
  environment = {
    dev = "Development"
    prd = "Production"
    hml = "Homolog"
  }
  # name_pattern = format("%s-%s-%s", var.project, var.environment, local.resource)
  
  path = "http://$${stageVariables.%s}/%s"
  path_health = format(local.path, var.stage_variable_name, "health")
  path_proxy  = format(local.path, var.stage_variable_name, "{proxy}")
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_api_gateway_resource" "microservice_resource" {
  rest_api_id = data.aws_api_gateway_rest_api.microservices_api.id
  parent_id   = data.aws_api_gateway_rest_api.microservices_api.root_resource_id
  path_part   = var.microservice_path_part
}

resource "aws_api_gateway_method" "microservice_method_any" {
  rest_api_id   = data.aws_api_gateway_rest_api.microservices_api.id
  resource_id   = aws_api_gateway_resource.microservice_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "microservice_integration_any" {
  rest_api_id             = data.aws_api_gateway_rest_api.microservices_api.id
  resource_id             = aws_api_gateway_resource.microservice_resource.id
  http_method             = aws_api_gateway_method.microservice_method_any.http_method
  type                    = "HTTP_PROXY"
  uri                     = "${local.path_health}"
  integration_http_method = "GET"

  # cache_key_parameters = ["method.request.path.proxy"]
  # request_parameters = {
  #   "integration.request.path.proxy" = "method.request.path.proxy"
  # }
}

resource "aws_api_gateway_method" "microservice_method_cors" {
  rest_api_id   = data.aws_api_gateway_rest_api.microservices_api.id
  resource_id   = aws_api_gateway_resource.microservice_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "microservice_method_response_cors" {
  rest_api_id = data.aws_api_gateway_rest_api.microservices_api.id
  resource_id = aws_api_gateway_resource.microservice_resource.id
  http_method = aws_api_gateway_method.microservice_method_cors.http_method

  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}


resource "aws_api_gateway_integration" "microservice_integration_cors" {
  rest_api_id = data.aws_api_gateway_rest_api.microservices_api.id
  resource_id = aws_api_gateway_resource.microservice_resource.id
  http_method = aws_api_gateway_method.microservice_method_cors.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}


resource "aws_api_gateway_integration_response" "microservice_integration_response_any_cors" {
  rest_api_id = data.aws_api_gateway_rest_api.microservices_api.id
  resource_id = aws_api_gateway_resource.microservice_resource.id
  http_method = aws_api_gateway_method.microservice_method_cors.http_method

  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'${var.allow_headers}'"
    "method.response.header.Access-Control-Allow-Methods" = "'${var.allow_methods}'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${var.allow_origins}'"
  }

  depends_on = [
    aws_api_gateway_method_response.microservice_method_response_cors,
    aws_api_gateway_integration.microservice_integration_cors
  ]
}


## Proxy path
resource "aws_api_gateway_resource" "microservice_resource_proxy" {
  rest_api_id = data.aws_api_gateway_rest_api.microservices_api.id
  parent_id   = aws_api_gateway_resource.microservice_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "microservice_method_proxy" {
  rest_api_id   = data.aws_api_gateway_rest_api.microservices_api.id
  resource_id   = aws_api_gateway_resource.microservice_resource_proxy.id
  http_method   = "ANY"
  authorization = "NONE"


  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "microservice_integration_proxy" {
  rest_api_id             = data.aws_api_gateway_rest_api.microservices_api.id
  resource_id             = aws_api_gateway_resource.microservice_resource_proxy.id
  http_method             = aws_api_gateway_method.microservice_method_proxy.http_method
  type                    = "HTTP_PROXY"
  uri                     = "${local.path_proxy}"
  integration_http_method = "ANY"

  cache_key_parameters = ["method.request.path.proxy"]
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_method" "microservice_method_proxy_cors" {
  rest_api_id   = data.aws_api_gateway_rest_api.microservices_api.id
  resource_id   = aws_api_gateway_resource.microservice_resource_proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "microservice_method_response_proxy_cors" {
  rest_api_id = data.aws_api_gateway_rest_api.microservices_api.id
  resource_id = aws_api_gateway_resource.microservice_resource_proxy.id
  http_method = aws_api_gateway_method.microservice_method_proxy_cors.http_method

  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "microservice_integration_proxy_cors" {
  rest_api_id = data.aws_api_gateway_rest_api.microservices_api.id
  resource_id = aws_api_gateway_resource.microservice_resource_proxy.id
  http_method = aws_api_gateway_method.microservice_method_proxy_cors.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }

}

resource "aws_api_gateway_integration_response" "microservice_integration_response_proxy_cors" {
  rest_api_id = data.aws_api_gateway_rest_api.microservices_api.id
  resource_id = aws_api_gateway_resource.microservice_resource_proxy.id
  http_method = aws_api_gateway_method.microservice_method_proxy_cors.http_method

  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'${var.allow_headers}'"
    "method.response.header.Access-Control-Allow-Methods" = "'${var.allow_methods}'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${var.allow_origins}'"
  }

  depends_on = [
    aws_api_gateway_method_response.microservice_method_response_proxy_cors,
    aws_api_gateway_integration.microservice_integration_proxy_cors
  ]
}


