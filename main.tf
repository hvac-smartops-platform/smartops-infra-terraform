provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web_server" {
  ami                         = "ami-05024c2628f651b80"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Welcome to SmartOps Platform - Adnan Project</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "smartops-web-server"
  }
}

resource "aws_instance" "web_server_2" {
  ami                         = "ami-05024c2628f651b80"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Welcome to SmartOps Platform - Server 2</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "smartops-web-server-2"
  }
}

resource "aws_eip" "web_ip" {
  domain   = "vpc"
  instance = aws_instance.web_server.id

  tags = {
    Name = "smartops-web-eip"
  }
}