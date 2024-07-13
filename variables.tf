variable "default_tags" {
  default     = {}
  description = "Key/value pairs for additional default tags to add to resources"
  type        = map(string)
}

variable "desired_number_of_availability_zones" {
  default     = 2
  description = "The number of availability zones to create subnets in"
  type        = number
}

variable "namespace" {
  default     = null
  description = "ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique."
  type        = string
}

variable "ipv4_primary_cidr_block" {
  default     = null
  description = "The primary IPv4 CIDR block for the VPC"
  type        = string
}
