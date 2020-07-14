// Provide Credentials
provider "aws" {
  region = "ap-south-1"
  access_key = "your_access_key"
  secret_key = "your_secret_key"
  profile = "sachin"
}


//Creating VPC
resource "aws_vpc" "skvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "skvpc"
  }
}

//Creating Subnets
resource "aws_subnet" "sksubnet1-1a" {
  vpc_id     = aws_vpc.skvpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "sksubnet1-1a"
  }
}

resource "aws_subnet" "sksubnet2-1b" {
  vpc_id     = aws_vpc.skvpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "sksubnet2-1b"
  }
}

//Creating Internet Gateway
resource "aws_internet_gateway" "sk-internet-gateway" {
  vpc_id = aws_vpc.skvpc.id

  tags = {
    Name = "sk-internet-gateway"
  }
}

//Creating Route Table
resource "aws_route_table" "sk-route" {
  vpc_id = aws_vpc.skvpc.id

  route {
    
gateway_id = aws_internet_gateway.sk-internet-gateway.id
    cidr_block = "0.0.0.0/0"
  }

    tags = {
    Name = "sk-route"
  }
}

//Route Table Association
resource "aws_route_table_association" "sk-route-table" {
  subnet_id      = aws_subnet.sksubnet1-1a.id
  route_table_id = aws_route_table.sk-route.id
}

// Wordpress Security Group
resource "aws_security_group" "sg1" {
  depends_on = [ aws_vpc.skvpc ]
  name        = "wpos_sg"
  vpc_id      = aws_vpc.skvpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wpos_sg"
  }
}

// MYSQL Security Group

resource "aws_security_group" "sg2" {
  depends_on = [ aws_vpc.skvpc ]
  name        = "mysql_sg"
  vpc_id      = aws_vpc.skvpc.id

  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [ aws_security_group.sg1.id ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql_sg"
  }
}

  resource "aws_instance" "wordpress_os" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.sksubnet1-1a.id
  vpc_security_group_ids = [ aws_security_group.sg1.id ]
  key_name = "eks"

  tags = {
    Name = "wordpress"
    }

}

resource "aws_instance" "database" {
  ami           = "ami-0019ac6129392a0f2"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.sksubnet2-1b.id
  vpc_security_group_ids = [ aws_security_group.sg2.id ]
  key_name = "eks"

  tags = {
    Name = "database"
    }

}


