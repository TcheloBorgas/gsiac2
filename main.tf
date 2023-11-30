// create two ec2 with load balancer attached to them. The ec2s must have an Apache server HTML page

resource "aws_vpc" "web" {
  cidr_block = "172.0.0.0/16"
}

resource "aws_subnet" "web-1" {
  vpc_id                  = aws_vpc.web.id
  cidr_block              = "172.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    name = "subnet1"
  }
}

resource "aws_subnet" "web-2" {
  vpc_id                  = aws_vpc.web.id
  cidr_block              = "172.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    name = "subnet2"
  }
}

resource "aws_internet_gateway" "web" {
  vpc_id = aws_vpc.web.id
}

resource "aws_route_table" "web" {
  vpc_id = aws_vpc.web.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web.id
  }
}

resource "aws_route_table_association" "web-1" {
  subnet_id      = aws_subnet.web-1.id
  route_table_id = aws_route_table.web.id
}

resource "aws_route_table_association" "web-2" {
  subnet_id      = aws_subnet.web-2.id
  route_table_id = aws_route_table.web.id
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "SALLES GS SUB"
  vpc_id      = aws_vpc.web.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web-1" {
  ami                         = "ami-0230bd60aa48260c6"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1a"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.web-1.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  user_data                   = base64encode(data.template_file.user_data.rendered)
}

resource "aws_instance" "web-2" {
  ami                         = "ami-0230bd60aa48260c6"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1a"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.web-1.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  user_data                   = base64encode(data.template_file.user_data.rendered)
}

resource "aws_instance" "web-3" {
  ami                         = "ami-0230bd60aa48260c6"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1b"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.web-2.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  user_data                   = base64encode(data.template_file.user_data.rendered)
}

resource "aws_instance" "web-4" {
  ami                         = "ami-0230bd60aa48260c6"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1b"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.web-2.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  user_data                   = base64encode(data.template_file.user_data.rendered)
}

data "template_file" "user_data" {
  template = file("./script/user_data.sh")
}

resource "aws_lb" "lb" {
  name               = "lb-salles-gs-sub"
  load_balancer_type = "application"
  subnets            = [aws_subnet.web-1.id, aws_subnet.web-2.id]
  security_groups    = [aws_security_group.web.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "tg-salles-gs-sub"
  protocol = "HTTP"
  port     = 80
  vpc_id   = aws_vpc.web.id
}




resource "aws_lb_listener" "ec2_lb_listener" {
  protocol          = "HTTP"
  port              = 80
  load_balancer_arn = aws_lb.lb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "web-1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web-2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web-2.id
  port             = 80
}