provider "aws" {
  region = "us-east-1"
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"


  name = "my-cluster-vpc"
  cidr = "10.10.0.0/16"


  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
  public_subnets  = ["10.10.101.0/24", "10.10.102.0/24"]


  enable_nat_gateway = true
  single_nat_gateway = true


#   enable_vpn_gateway = true




  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}



# EKS Module
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-terra-cluster"
  cluster_version = "1.31"
  subnet_ids         = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id
  


  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true


  eks_managed_node_groups  = {
    terra-eks = {
        min_size = 2
        max_size = 3
        desired_size = 2
        ami_type        = "ami-0453ec754f44f9a4a"
        instance_types = ["t3.small"]
        additional_security_group_ids = aws_security_group.lb_sg.id
        

    }


  # }
  # #Create security group
  # create_node_security_group= {
  #   lb_security = {
  #     ingress = {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  #     }
  #      egress = {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  #   }
  }


  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }


  authentication_mode = "API_AND_CONFIG_MAP"
}


# Output the cluster kubeconfig
output "kubeconfig" {
  value = module.eks.kubeconfig
}


# Output the cluster endpoint
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}


# Output the cluster kubeconfig command
output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-east-1"
}


# # Launch 3 EC2 Instances
# resource "aws_instance" "computers" {
#   count         = 3
#   ami           = "ami-0453ec754f44f9a4a" # Amazon Linux 2023 AMI 2023.6.20241121.0 x86_64 HVM kernel-6.1
#   instance_type = "t3.micro"
#   subnet_id     = module.vpc.private_subnets

#   tags = {
#     Name = "computer-instance-${count.index + 1}"
#   }
# }

# Security Group for Load Balancer
resource "aws_security_group" "lb_sg" {
  name_prefix = "lb-sg"
  vpc_id      = module.vpc.default_vpc_id
  ingress {
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

# Application Load Balancer
resource "aws_lb" "lb_cluster" {
  name               = "cluster-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.example_subnet.*.id
}

# Target Group for Instances
resource "aws_lb_target_group" "cluster-group" {
  name     = "cluster-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.default_vpc_id
}

# Attach Instances to Target Group
resource "aws_lb_target_group_attachment" "lb_group_attach" {
  count            = 3
  target_group_arn = aws_lb_target_group.cluster-group.arn
  target_id        = my-terra-cluster.aws_instance[count.index].id
  port             = 80
}

# Listener
resource "aws_lb_listener" "listen_lb" {
  load_balancer_arn = aws_lb.lb_cluster.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cluster-group.arn
  }
}
