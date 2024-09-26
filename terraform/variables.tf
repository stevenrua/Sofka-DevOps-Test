variable "time_off_virginia_cidr" {
    sensitive = true
    description = "CIDR vpc virginia"
    type = string  
}

variable "tags" {
  description = "tags generales"
  type = map(any)
}