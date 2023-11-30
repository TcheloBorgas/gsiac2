// create two ec2 with load balancer attached to them. The ec2s must have a apache server html page

resource "aws_vpc" "net" {
  cidr_block = "172.0.0.0/16"
}

resource "aws_subnet" "net-1" {
  vpc_id                  = aws_vpc.net.id
  cidr_block              = "172.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "net-2" {
  vpc_id                  = aws_vpc.net.id
  cidr_block              = "172.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}


resource "aws_internet_gateway" "net" {
  vpc_id = aws_vpc.net.id
}

resource "aws_route_table" "net" {
  vpc_id = aws_vpc.net.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.net.id
  }
}

resource "aws_route_table_association" "net-1" {
  subnet_id      = aws_subnet.net-1.id
  route_table_id = aws_route_table.net.id
}
resource "aws_route_table_association" "net-2" {
  subnet_id      = aws_subnet.net-2.id
  route_table_id = aws_route_table.net.id
}

resource "aws_security_group" "net-1" {
  name        = "net"
  description = "Allow net inbound traffic"
  vpc_id      = aws_vpc.net.id

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
resource "aws_security_group" "net-2" {
  name        = "netb"
  description = "Allow net inbound traffic"
  vpc_id      = aws_vpc.net.id

   egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["172.0.0.0/16"]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        description = "TCP/80 from All"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_instance" "net-1" {
  ami                         = "ami-0230bd60aa48260c6"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1a"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.net-1.id
  vpc_security_group_ids      = [aws_security_group.net-2.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo '<h1>Uga funciona</h1>' | tee /var/www/html/index.html
              EOF

  tags = {
    Name = "net"
  }
}

resource "aws_instance" "net-2" {
  ami                         = "ami-0230bd60aa48260c6"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1a"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.net-1.id
  vpc_security_group_ids      = [aws_security_group.net-2.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo '<h1>Uga,</h1>' | tee /var/www/html/index.html
              EOF

  tags = {
    Name = "net"
  }
}
resource "aws_instance" "net-3" {
  ami                         = "ami-0230bd60aa48260c6"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1b"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.net-2.id
  vpc_security_group_ids      = [aws_security_group.net-2.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo '<h1>Chega, por favor</h1>' | tee /var/www/html/index.html
              EOF

  tags = {
    Name = "net"
  }
}
resource "aws_instance" "net-4" {
  ami                         = "ami-0230bd60aa48260c6"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1b"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.net-2.id
  vpc_security_group_ids      = [aws_security_group.net-2.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo '<h1>Chega, por favor, ja deu de GS</h1>' | tee /var/www/html/index.html
              EOF

  tags = {
    Name = "net"
  }
}

resource "aws_lb" "lb" {
  name               = "lb-tchelo"
  load_balancer_type = "application"
  subnets            = [aws_subnet.net-1.id, aws_subnet.net-2.id]
  security_groups    = [aws_security_group.net-1.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "tg-tchelo"
  protocol = "HTTP"
  port     = "80"
  vpc_id   = aws_vpc.net.id
}

resource "aws_lb_listener" "ec2_lb_listener" {
  protocol          = "HTTP"
  port              = "80"
  load_balancer_arn = aws_lb.lb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
resource "aws_lb_target_group_attachment" "net-1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.net-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "net-2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.net-2.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "net-3" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.net-3.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "net-4" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.net-4.id
  port             = 80
}