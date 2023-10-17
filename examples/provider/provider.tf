terraform {
  required_providers {
    netcalc = {
      source = "geezyx/netcalc"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "vpc_id" {}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnets" "example" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnet" "example" {
  for_each = toset(data.aws_subnets.example.ids)
  id       = each.value
}

# IPv4 and IPv6 CIDR blocks can both be added to the pool.
# It is critical to inform the provider of the already allocated CIDR blocks, otherwise
# it has no way of knowing which blocks can be used (even if the blocks are allocated
# from netcalc resources).
provider "netcalc" {
  pool_cidr_blocks = coalesce(flatten([
    data.aws_vpc.selected.cidr_block,
    data.aws_vpc.selected.ipv6_cidr_block,
    [for a in data.aws_vpc.selected.cidr_block_associations : a.cidr_block]
  ]))
  claimed_cidr_blocks = coalesce(flatten([
    for s in data.aws_subnet.example : [s.cidr_block, s.ipv6_cidr_block]
  ]))
}
