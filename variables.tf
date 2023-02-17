variable "key_name" {
  description = "The name of the key pair to use for SSH access to the web server"
  default     = "sre_key"
}

variable "private_key_path" {
  description = "The path to the private key for SSH access to the web server"
  # default     = file("~/.ssh/sre_key.pub")
}

variable "test_script" {
  description = "Path to the automated test script"
  default = "test/test.sh"
}
