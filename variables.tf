variable "az_projname" {
#  default = "proja"

  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^[a-zA-Z0-9]+$", var.az_projname))
    error_message = "The project name must not be empty and only contain alphanumeric characters."
  }

}
