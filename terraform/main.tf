provider "aws" {

  region = "us-east-1"

}

resource "aws_vpc" "main" {

  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true

  tags = {
    Name = "devops-lifecycle-vpc"

  }

}

resource "aws_subnet" "public_1" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "devops-public-1"
  }

}

resource "aws_subnet" "public_2" {

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "devops-public-2"
  }

}


resource "aws_subnet" "private_1" {

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "devops-private-1"
  }

}

resource "aws_subnet" "private_2" {

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"

  tags = {

    Name = "devops-private-2"

  }

}

resource "aws_eip" "nat" {

  domain = "vpc"

}

resource "aws_nat_gateway" "main" {

  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id
}



resource "aws_internet_gateway" "main" {

  vpc_id = aws_vpc.main.id

}

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.main.id
  }

}

resource "aws_route_table_association" "public" {

  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {

  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id

}

resource "aws_route_table" "private" {

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id

  }


}

resource "aws_route_table_association" "private_1" {

  subnet_id = aws_subnet.private_1.id

  route_table_id = aws_route_table.private.id


}


resource "aws_route_table_association" "private_2" {

  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id

}




resource "aws_iam_role" "eks_cluster" {
  name = "devops-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

}


resource "aws_eks_cluster" "main" {

  name = "devops-lifecycle-eks"

  role_arn = aws_iam_role.eks_cluster.arn

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.private_1.id,

      aws_subnet.private_2.id

    ]

    endpoint_public_access  = true
    endpoint_private_access = true

    public_access_cidrs = ["76.100.45.96/32"]

  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster

  ]

}

# IAM Role for EKS Worker Nodes
resource "aws_iam_role" "eks_node_role" {
  name = "devops-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {

  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

# Allow the VPC CNI plugin to manage Pod networking
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "devops-lifecycle-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy,
    aws_iam_role_policy_attachment.eks_cni_policy
  ]
}
