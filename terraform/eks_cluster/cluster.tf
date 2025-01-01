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
    Project     = "eks-setup"
  }
}


# Security Group for EKS Control Plane
resource "aws_security_group" "eks_sg" {
  name        = "eks-cluster-sg"
  description = "Allow access to EKS control plane"
  vpc_id      = module.vpc.default_vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Allow access within VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EKS Control Plane SG"
  }
}

# EKS Module
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-terra-cluster"
  version          = "20.31.0"
  cluster_version = "1.31"
  subnet_ids         = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id
  enable_irsa      = true
  cluster_security_group_id = aws_security_group.eks_sg.id
  enable_cluster_creator_admin_permissions = true


  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true


  eks_managed_node_groups  = {
    terra-eks = {
        min_size = 1
        max_size = 2
        desired_size = 2
       
        instance_types = ["t3.medium"]
    }


  }


  # Cluster access entry
  # To add the current caller identity as an administrator
  
  access_entries = {
    # One access entry with a policy associated
    example = {
      principal_arn = "arn:aws:iam::047719660371:role/Admin_role"

      policy_associations = {
        eks_Admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      
      cluster_admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = {
          type       = "cluster"
        }
      }
    }
  }
  }
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }


  authentication_mode = "API_AND_CONFIG_MAP"
}

# resource "kubernetes_config_map" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapUsers = <<EOT
# - userarn: ${var.user_arn}
#   username: ${var.username}
#   groups:
#     - system:masters
# EOT
#   }
# }


# # Output the cluster kubeconfig
# output "kubeconfig" {
#   value = module.eks.kubeconfig
# }

# Security Group for Load Balancer
resource "aws_security_group" "lb_sg" {
  name_prefix = "lb-sg"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5052
    to_port     = 5052
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


resource "aws_eip" "lb_eip_1" {
  domain = "vpc"
}


# Output the cluster endpoint
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}


# Output the cluster kubeconfig command
output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-east-1"
}

resource "local_sensitive_file" "lb_id" {
  filename   = "${path.module}/variables.yaml"
  content    = <<EOT
---
eks_clstr_id: "${aws_eip.lb_eip_1.id}"
EOT
  depends_on = [aws_eip.lb_eip_1]
}

  resource "local_sensitive_file" "my_lb_ip" {
   content  = aws_eip.lb_eip_1.public_ip
   filename = "${path.module}/my_eip_ip.txt"
    depends_on = [aws_eip.lb_eip_1]
}