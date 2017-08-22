variable "aws_key_name" {
  default = "springer"
}

variable "aws_region" {
  description = "EC2 Region for the VPC"
  default     = "eu-west-1"
}

variable "ec2_az" {
  description = "Zones for ec2 instances"
  type        = "list"
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "ec2_subnet_cidr" {
  description = "CIDR for ec2 instances"
  type        = "list"
  default     = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

variable "project_name" {
  default = "probeaufgabe"
}

variable "ami" {
  description = "custom ami: ubuntu 16.04, nginx, codedeploy-agent"
  default     = "ami-49619e30"
}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  default     = "10.0.0.0/16"
}

variable "allowed_ip_to_access_rds" {
  type        = "list"
  description = "list of allowed ips to access to rds instance for backups, maintance, etc."
  default     = ["213.61.171.0/24"]
}

variable "instance_type" {
  description = "type of instances for launch configuration"
  default     = "t2.micro"
}

variable "instance_class" {
  description = "type of instances for rds"
  default     = "t2.micro"
}

variable "db_instance_class" {
  description = "type of instances for rds"
  default     = "db.t2.micro"
}

variable "db_name" {
  default = "probeaufgabe"
}

variable "db_username" {
  default = "springer"
}

variable "db_password" {
  default = "ProbeAufGabe-springer1"
}

variable "domain_name" {
  description = "domain names"
  default     = "probeaufgabe.com"
}
