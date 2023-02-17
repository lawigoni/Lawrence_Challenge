# Define AWS provider and region
provider "aws" {
  region = "us-east-1"
}

# Create a new VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a public subnet in the VPC
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Create a security group to allow traffic on HTTP and HTTPS ports
resource "aws_security_group" "web_server_sg" {
  name_prefix = "web_server_sg_"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance to host the web server
resource "aws_instance" "web_server" {
  ami = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  key_name = "sre_key"
  # public_key = file("~/.ssh/sre_key.pub")
  subnet_id = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.web_server_sg.id]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/sre_key.pub")
    host        = self.public_ip
  }

  # User data script to configure web server on launch
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    # apt-get install openssh-server
    # systemctl enable ssh
    # sudo systemctl enable ssh --now
    # sudo systemctl start ssh
    apt-get install -y nginx
    echo "<html><head><title>Hello World</title></head><body><h1>Hello World!</h1></body></html>" > /var/www/html/index.html
  EOF
}

# Create a self-signed SSL certificate for the web server
resource "tls_private_key" "web_server_key" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "tls_self_signed_cert" "web_server_cert" {
  # key_algorithm = tls_private_key.web_server_key.algorithm
  private_key_pem = tls_private_key.web_server_key.private_key_pem
  # subject_alternative_names = [aws_instance.web.public_ip]
  validity_period_hours = 24
  allowed_uses = ["server_auth"]
  subject {
    common_name = "disys.test.com"
  }
}

# Configure Nginx to use the SSL certificate and redirect HTTP to HTTPS
resource "null_resource" "nginx_config" {
  depends_on = [
    aws_instance.web_server,
    tls_self_signed_cert.web_server_cert,
  ]

  provisioner "local-exec" {
    command = <<-EOF
      ssh -o StrictHostKeyChecking=no ubuntu@${aws_instance.web_server.public_ip} 'sudo sed -i "s/80 default_server;/80 default_server;\n\treturn 301 https:\/\/\$host\$request_uri;/" /etc/nginx/sites-available/default'
      ssh -o StrictHostKeyChecking=no ubuntu@${aws_instance.web_server.public_ip} 'sudo sed -i "s/# listen 443 ssl default_server;/listen 443 ssl default_server;/" /etc/nginx/sites-available/default'
      ssh -o StrictHostKeyChecking=no ubuntu@${aws_instance.web_server.public_ip} 'sudo sed -i "s/# ssl_certificate \/etc\/ssl\/certs\/ssl-cert-snakeoil.pem;/ssl_certificate \/etc\/ssl\/certs\/web_server.crt;/" /etc/nginx/sites-available/default'
      ssh -o StrictHostKeyChecking=no ubuntu@${aws_instance.web_server.public_ip} 'sudo sed -i "s/# ssl_certificate_key \/etc\/ssl\/private\/ssl-cert-snakeoil.key;/ssl_certificate_key \/etc\/ssl\/private\/web_server.key;/" /etc/nginx/sites-available/default'
      ssh -o StrictHostKeyChecking=no ubuntu@${aws_instance.web_server.public_ip} 'sudo service nginx restart'
    EOF
  }
  provisioner "remote-exec" {
  inline = [
    "sudo chmod +x ${var.test_script}",
    "${var.test_script} ${aws_instance.web_server.public_ip}"
    ]
  }
    # connection {
    #   type        = "ssh"
    #   host        = aws_instance.web_server.public_ip
    #   user        = "ubuntu"
    #   private_key = file(var.private_key_path)
    # }
  }
  
