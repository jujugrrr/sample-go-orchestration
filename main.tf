# Specify the provider and access details
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "eu-west-1"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "web" {
  name        = "web_sg"
  description = "used for web instances"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a key pair to connect to the instances
resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

# Our default security group to access
# the instances over go and SSH
resource "aws_security_group" "application" {
  name        = "application_sg"
  description = "used for application instances"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 8484
    to_port     = 8484
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our web proxy instance
# All our instances are in the same subnet, in production we would use a public subnet for
# the web instance and a private subnet for the application instances
resource "aws_instance" "web" {
  depends_on = ["aws_instance.application1", "aws_instance.application2"]
  connection {
    user = "ubuntu"
  }
  instance_type = "t2.micro"
  iam_instance_profile = "samplego"
  ami = "ami-f95ef58a"
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  subnet_id = "${aws_subnet.default.id}"
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install curl",
      "sudo curl -L https://www.opscode.com/chef/install.sh | sudo bash -s -- -v '12.8.1'",
      "sudo chef-solo -r ${var.chef_artifact} -o 'recipe['sample-go-cm::nginx']'"
    ]
  }
  tags {
    Name = "web"
  }
}

# Our application proxy instances
resource "aws_instance" "application1" {
  connection {
    user = "ubuntu"
  }
  instance_type = "t2.micro"
  ami = "ami-f95ef58a"
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.application.id}"]
  subnet_id = "${aws_subnet.default.id}"
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install curl",
      "sudo curl -L https://www.opscode.com/chef/install.sh | sudo bash -s -- -v '12.8.1'",
      "sudo chef-solo -r ${var.chef_artifact} -o 'recipe['sample-go-cm::default']'"
    ]
  }
  tags {
    app = "samplego"
    Name = "application1"
  }
}
resource "aws_instance" "application2" {
  connection {
    user = "ubuntu"
  }
  instance_type = "t2.micro"
  ami = "ami-f95ef58a"
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.application.id}"]
  subnet_id = "${aws_subnet.default.id}"
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install curl",
      "sudo curl -L https://www.opscode.com/chef/install.sh | sudo bash -s -- -v '12.8.1'",
      "sudo chef-solo -r ${var.chef_artifact} -o 'recipe['sample-go-cm::default']'"
    ]
  }
  tags {
    app = "samplego"
    Name = "application2"
  }
}

# Output the Web node IP so we can connect to it
output "webnode" {
  value = "${aws_instance.web.public_ip}"
}
