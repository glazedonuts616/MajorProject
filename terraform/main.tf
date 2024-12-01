provider "aws" {
  region = "us-east-1"
}


resource "aws_iam_user" "Ytech" {
  name = "Ytech"
  tags= {
    Name= "Ytech IAM"
  }
}

resource "aws_iam_group" "technition" {
  name = "tech_group"
}


resource "aws_iam_user_group_membership" "tech_group_membership" {
  user = aws_iam_user.Ytech.name

  groups = [
    aws_iam_group.technition.name,
  ]
}


resource "aws_iam_group_policy_attachment" "technition_policy" {
  group = aws_iam_group.technition.name
 policy_arn ="arn:aws:iam::aws:policy/AdministratorAccess"
}



resource "aws_iam_role" "ec2_role-admin" {
  name = "ec2-role-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Attach group policy
resource "aws_iam_role_policy_attachment" "group_policy" {
  role       = aws_iam_role.ec2_role-admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"  # Example policy
}


resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile-admin"
  role = aws_iam_role.ec2_role-admin.name
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
    tags = {
    Name = "My-Internet-Gateway"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_instance" "jenkins_master" {
  ami           = "ami-0866a3c8686eaeeba"
  instance_type = "t2.micro"
  key_name      = "My-first-key"
 
  private_ip = "10.0.0.79"
  subnet_id  = aws_subnet.my_subnet.id
 

  tags = {
    Name = "Jenkins-Master"
  }



  # Optional: Specify IAM instance profile if needed
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name 


  # Optional: Specify the boot mode if needed
  root_block_device {
    volume_size = 20 # specify the desired size if you are creating a new volume
    volume_type = "gp2"
  }
}

    resource "aws_eip" "my_eip" {
    domain           = "vpc"
    instance                  = aws_instance.jenkins_master.id
     associate_with_private_ip = "10.0.0.79"

  # Explicit dependency on the Internet Gateway
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_security_group" "allow_port_8080" {
  name        = "allow-8080"
  description = "Allow incoming connections to port 8080"
  vpc_id      = aws_vpc.my_vpc.id  # Reference the VPC where this rule applies

  ingress {
    description      = "Allow inbound HTTP traffic on port 8080"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  # Allow traffic from any IP
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"  # Allow all protocols
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-8080"
  }
}
resource "local_sensitive_file" "EC2_ip" {
  filename   = "C:\\Users\\admin\\Documents\\DevOps\\Major_Project\\terraform\\tf_ec2_ansible\\variables.tf"
  content    = <<EOT
variable "jenkins_master" {
  default = "${aws_instance.jenkins_master.id}"
}
EOT
  depends_on = [aws_instance.jenkins_master]
}

  resource "local_sensitive_file" "my_eip_ip" {
   content  = aws_eip.my_eip.customer_owned_ip
   filename = "${path.module}/my_eip_ip.txt"
   depends_on = [ aws_instance.jenkins_master ]
}