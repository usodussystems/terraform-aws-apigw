variable "project" {
  description = "Name to be used on all the resources as identifier"
  type        = string
}

variable "environment" {
  description = "The environment, and also used as a identifier"
  type        = string
  validation {
    condition     = try(length(regex("dev|prd|hml", var.environment)) > 0,false)
    error_message = "Define envrionment as one that follows: dev, hml or prd."
  }
}

variable "region" {
  description = "Region AWS where deploy occurs"
  type        = string
  default     = "us-east-1"
}

variable "application" {
  type = string
  description = "Name application"
}

########################################

variable "api_gw_name"{
  type = string
  description = "API Gateway name for reference"
}


variable "microservice_path_part" {
  type        = string
  description = "This should represent the path from the root api where the microservice will be found"
  validation {
    condition     = length(split("/", var.microservice_path_part)) > 0
    error_message = "This should not contain '/', please if this is a compost path contact admin."
  }
}

variable "allow_headers" {
  type        = string
  description = "String Command separeated with all headers to be allowed in cors"
  default     = "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token"
  validation {
    condition     = var.allow_headers != "*" || length(split(",", var.allow_headers)) > 0
    error_message = "Please try to be more specific '*' should not be considered to do this.\n OR Add more then one header."
  }
}

variable "allow_methods" {
  type        = string
  description = "Allow methods to be filtered by cors"
  default     = "DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT"
  validation {
    condition     = length(regex("DELETE", var.allow_methods)) + length(regex("GET", var.allow_methods)) + length(regex("HEAD", var.allow_methods)) + length(regex("OPTIONS", var.allow_methods)) + length(regex("PATCH", var.allow_methods)) + length(regex("PUT", var.allow_methods)) + length(regex("POST", var.allow_methods)) > 0
    error_message = "This should contain at least one of the following methods:DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT."
  }
}

variable "allow_origins" {
  type        = string
  description = "This should be set to restric origins from where the requests follows"
  default     = "*"
}

variable "stage_variable_name" {
  type        = string
  description = "The name to be used as a varible"
}
