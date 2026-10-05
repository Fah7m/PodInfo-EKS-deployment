# EKS module with managed node groups

resource "aws_eks_cluster" "eks_cluster" {
  name = "${var.name_prefix}-eks-cluster"

  access_config {
    authentication_mode = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks_etcd_encryption.arn
    }
  }

  role_arn = aws_iam_role.cluster.arn
  version  = var.eks_version

  bootstrap_self_managed_addons = true

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
    subnet_ids              = var.private_subnet_ids
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.kms_policy_attachment
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-eks-cluster"
    }
  )
}

# EKS Security Group

resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.name_prefix}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-eks-cluster-sg"
    }
  )
}

# IAM Role for EKS Cluster

resource "aws_iam_role" "cluster" {
  name = "${var.name_prefix}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# KMS encryption for etcd

resource "aws_kms_key" "eks_etcd_encryption" {
  description             = "KMS key for EKS etcd encryption"
  deletion_window_in_days = 7
  enable_key_rotation       = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-eks-etcd-encryption-key"
    }
  )
}

resource "aws_kms_alias" "eks_etcd_encryption_alias" {
  name          = "alias/${var.name_prefix}-eks-etcd-encryption-key"
  target_key_id = aws_kms_key.eks_etcd_encryption.key_id
}

resource "aws_iam_policy" "kms_policy" {
  name        = "${var.name_prefix}-kms-policy"
  description = "IAM policy for EKS secrets encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = aws_kms_key.eks_etcd_encryption.arn
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-eks-secrets-policy"
    }
  )
}


resource "aws_iam_role_policy_attachment" "kms_policy_attachment" {
  policy_arn = aws_iam_policy.kms_policy.arn
  role       = aws_iam_role.cluster.name
}


# IAM Role for EKS Node Group

resource "aws_iam_role" "node" {
  name = "${var.name_prefix}-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy" "AmazonEKSWorkerNodePolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

data "aws_iam_policy" "AmazonEC2ContainerRegistryPullOnly" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

data "aws_iam_policy" "AmazonEKS_CNI_Policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = data.aws_iam_policy.AmazonEKS_CNI_Policy.arn
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = data.aws_iam_policy.AmazonEKSWorkerNodePolicy.arn
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryPullOnly" {
  policy_arn = data.aws_iam_policy.AmazonEC2ContainerRegistryPullOnly.arn
  role       = aws_iam_role.node.name
}


# EKS Managed Node Group

resource "aws_eks_node_group" "managed_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.name_prefix}-node-group"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  depends_on = [aws_eks_cluster.eks_cluster,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryPullOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy
  ]
  capacity_type  = "ON_DEMAND"
  instance_types = ["m7i-flex.large"]

  scaling_config {
    desired_size = 4
    max_size     = 6
    min_size     = 4
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    workload = "general"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-node-group"
    }
  )
}


data "tls_certificate" "eks_oidc_thumbprint" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [data.tls_certificate.eks_oidc_thumbprint.certificates[0].sha1_fingerprint]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-eks-oidc-provider"
    }
  )
}

# access entry via kubectl

resource "aws_eks_access_entry" "admin" {
  for_each      = var.cluster_admins
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  for_each      = var.cluster_admins
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
  depends_on    = [aws_eks_access_entry.admin]
}