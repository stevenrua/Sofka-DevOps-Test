variable "time_off_virginia_cidr" {
    sensitive = true
    description = "CIDR vpc virginia"
    type = string  
}

variable "tags" {
  description = "tags generales"
  type = map(any)
}

variable "list_cidr_subnets" {
  description = "cidr subnets"
  type = list(string)
}

variable "sg_ingress_cidr" {
  description = "CIDR for ingress traffic"
  type = string
}

variable "ingress_port_list" {
  description = "Lista de puertos de ingress"
  type = list(number)
}