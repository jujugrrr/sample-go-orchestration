variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ~/.ssh/terraform.pub
DESCRIPTION
}

variable "key_name" {
  default = "terraform"
  description = "Desired name of AWS key pair"
}

variable "access_key" {}
variable "secret_key" {}
variable "chef_artifact" {
  description = "Artifact with all the required Chef cookbooks, can be find on circle-ci https://circleci.com/gh/jujugrrr/sample-go-cm/"
  default = "https://circle-artifacts.com/gh/jujugrrr/sample-go-cm/26/artifacts/0/tmp/circle-artifacts.oY5qlhf/sample-go-cm.tar.gz"
}
