provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/24"
}


resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Main"
  }
}


resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http traffic"
  vpc_id     = aws_vpc.main.id

  ingress = [
    {
      description      = "http allow"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]
  egress = [
    {
      description      = "http allow"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]
  tags = {
    Name = "allow_http"
  }
}



resource "aws_security_group" "nginx-2-alb" {
  name        = "allow_http"
  description = "Allow http traffic"
  vpc_id     = aws_vpc.main.id

  ingress = [
    {
      description      = "nginx-2-alb"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = [aws_vpc.main.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }

  ingress = [
    {
      description      = "nginx-2-alb"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = [aws_vpc.main.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }


  ]
  egress = [
    {
      description      = "nginx-2-alb"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = [aws_vpc.main.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]
  tags = {
    Name = "nginx-2-alb"
  }
}


resource "aws_instance" "nginx-srv1" {
  ami = "ami-00399ec92321828f5"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.main.id
  user_data = user_data = "${file("install_nginx1.sh")}"
  vpc_security_group_ids = [aws_security_group.nginx-2-alb.id]
  tags = {
    Name = "nginx-srv1"
  }
}


resource "aws_instance" "nginx-srv2" {
  ami = "ami-00399ec92321828f5"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.main.id
  user_data = user_data = "${file("install_nginx2.sh")}"
  vpc_security_group_ids = [aws_security_group.nginx-2-alb.id ]
  tags = {
    Name = "nginx-srv2"
  }
}


resource "aws_lb_target_group" "nginx" {
  name     = "nginx-instances"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}



resource "aws_lb_target_group_attachment" "website-app" {
  target_group_arn = aws_lb_target_group.nginx.arn
  target_id        = aws_instance.nginx-srv1.id, aws_instance.nginx-srv2.id
  port             = 80
}


resource "aws_lb" "my-web-app" {
  name               = "my-web-app"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nginx-2-alb.id, aws_security_group.allow_http.id]
  subnets            = aws_subnet.public.*.id

  enable_deletion_protection = true

}



resource "aws_lb_listener" "driivz" {
  load_balancer_arn = aws_lb.my-web-app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

