variable "desired_number_of_availability_zones" {
  description = "The number of availability zones to create subnets in"
  type        = number
}

variable "namespace" {
  description = "ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique."
  type        = string
}

variable "ipv4_primary_cidr_block" {
  description = "The primary IPv4 CIDR block for the VPC"
  type        = string
}

variable "tags" {
  description = "Key/value pairs for additional default tags to add to resources"
  default     = {}
  type        = map(string)
}
