resource "aws_vpc" "vpc_virginia" {
  cidr_block = var.time_off_virginia_cidr
  tags = {
    Name = "VPC_VIRGINIA-${local.sufix}"    
  }
}