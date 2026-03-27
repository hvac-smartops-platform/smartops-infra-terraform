provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web_server" {
  ami                         = "ami-05024c2628f651b80"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "smartops-web-server"
  }
}