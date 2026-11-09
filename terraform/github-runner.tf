# IAM role for GitHub Actions EC2 runner
resource "aws_iam_role" "github_runner" {
  name = "devops-github-runner-role"

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

# Allow secure management through AWS Systems Manager
resource "aws_iam_role_policy_attachment" "runner_ssm" {
  role       = aws_iam_role.github_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allow the runner to discover our EKS cluster
resource "aws_iam_role_policy" "runner_eks" {
  name = "github-runner-eks-describe"
  role = aws_iam_role.github_runner.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = aws_eks_cluster.main.arn
      }
    ]
  })
}

# Attach IAM role to EC2
resource "aws_iam_instance_profile" "github_runner" {
  name = "devops-github-runner-profile"
  role = aws_iam_role.github_runner.name
}



# Security group for our GitHub Actions runner
resource "aws_security_group" "github_runner" {
  name        = "devops-github-runner-sg"
  description = "Security group for GitHub Actions runner"
  vpc_id      = aws_vpc.main.id

  # Allow outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-github-runner-sg"
  }
}

# EC2 instance for GitHub Actions runner
resource "aws_instance" "github_runner" {
  ami           = "ami-0c230065b91270bc6"
  instance_type = "t3.small"

  # Place EC2 in our private subnet
  subnet_id = aws_subnet.private_1.id

  # Attach our security group
  vpc_security_group_ids = [
    aws_security_group.github_runner.id
  ]

  # Give EC2 its IAM role
  iam_instance_profile = aws_iam_instance_profile.github_runner.name

  # No public IP address
  associate_public_ip_address = false

  # Require IMDSv2 for temporary AWS credentials
  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "devops-github-actions-runner"
  }
}


resource "aws_vpc_security_group_ingress_rule" "runner_to_eks" {
  security_group_id            = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = aws_security_group.github_runner.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "Allow GitHub Actions runner to access EKS API"
}


resource "aws_eks_access_entry" "github_runner" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.github_runner.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_runner_deploy" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.github_runner.arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["default"]
  }

  depends_on = [aws_eks_access_entry.github_runner]
}
