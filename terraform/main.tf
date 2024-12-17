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

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "My-Internet-Gateway"
  }
}

# Public Subnetex
resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "My-Public-Subnet"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

# Associate Subnet with Route Table
resource "aws_route_table_association" "my_route_table_assoc" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

  
resource "aws_instance" "jenkins-master" {
  ami           = "ami-0866a3c8686eaeeba"
  instance_type = "t2.micro"
  key_name      = "My-first-key"
  vpc_security_group_ids = [aws_security_group.allow_port_8080_and_22.id]
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
    instance                  = aws_instance.jenkins-master.id
     associate_with_private_ip = "10.0.0.79"

  # Explicit dependency on the Internet Gateway
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_security_group" "allow_port_8080_and_22" {
  name        = "allow-8080-22"
  description = "Allow incoming connections to port 8080 and 22"
  vpc_id      = aws_vpc.my_vpc.id  # Reference the VPC where this rule applies

  ingress {
    description      = "Allow inbound HTTP traffic on port 8080"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  # Allow traffic from any IP
  }
  ingress {
  description = "Allow inbound SSH traffic on port 22"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from any IP
}

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"  # Allow all protocols
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-8080-22"
  }
}
resource "local_sensitive_file" "EC2_ip" {
  filename   = "${path.module}/variables.yaml"
  content    = <<EOT
---
jenkins_master: "${aws_eip.my_eip.public_ip}"
EOT
  depends_on = [aws_instance.jenkins-master]
}


resource "local_sensitive_file" "EC2_ip" {
  filename   = "/home/vagrant/Documents/Devops/Major_Project/MajorProject/terraform/eks_cluster/variables.yaml"
  content    = <<EOT
---
jenkins_master: "${aws_eip.my_eip.public_ip}"
EOT
  depends_on = [aws_instance.jenkins-master]
}



resource "local_sensitive_file" "EC2_inv" {
  filename   = "/home/vagrant/Documents/Devops/Major_Project/MajorProject/terraform/tf_ec2_ansible/inventory.ini"
  content    = <<EOT
[web_servers]
${aws_eip.my_eip.public_ip} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=/home/vagrant/.aws/My-first-key.pem

EOT
  depends_on = [aws_instance.jenkins-master]
}


  resource "local_sensitive_file" "my_eip_ip" {
   content  = aws_eip.my_eip.public_ip
   filename = "${path.module}/../flask_cluster_app_mongo/my_eip_ip.txt"
   depends_on = [ aws_instance.jenkins-master ]
}