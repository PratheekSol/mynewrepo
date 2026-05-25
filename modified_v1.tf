# Creates a new VPC with a single subnet and launches one EC2 instance in that subnet. AMI is discovered via data source (Amazon Linux 2023). Minimal setup with variable-driven configuration and basic tagging.
# Generated Terraform code for AWS in us-east-1

terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.25.0"
    }
  }
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name used for resource naming and tags."
  type        = string
  default     = "tf-ec2"

  validation {
    condition     = length(var.name) > 0
    error_message = "name must not be empty."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet (must be within vpc_cidr)."
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address to the instance ENI."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}

provider "aws" {
  {{block_to_replace_cred}}

  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  common_tags = merge(
    {
      ManagedBy = "terraform"
      Name      = var.name
    },
    var.tags
  )
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-vpc"
    }
  )
}

resource "aws_subnet" "main" {
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = var.associate_public_ip_address
  vpc_id                  = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-subnet"
    }
  )
}

resource "aws_security_group" "instance" {
  description = "Security group for ${var.name} EC2 instance"
  name        = "${var.name}-sg"
  vpc_id      = aws_vpc.main.id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-sg"
    }
  )
}

resource "aws_instance" "main" {
  ami                         = data.aws_ami.al2023.id
  associate_public_ip_address = var.associate_public_ip_address
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.instance.id]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-ec2"
    }
  )
}

output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the created subnet."
  value       = aws_subnet.main.id
}

output "security_group_id" {
  description = "ID of the instance security group."
  value       = aws_security_group.instance.id
}

output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.main.id
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance."
  value       = aws_instance.main.private_ip
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance (if assigned)."
  value       = aws_instance.main.public_ip
}