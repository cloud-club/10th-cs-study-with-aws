# ---------------------------------------------------------
# 1. Provider & VPC 인프라
# ---------------------------------------------------------
provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "main" {
  cidr_block           = "172.16.0.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "myiac-test-vpc" }
}
resource "aws_subnet" "subnet-pub-a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.16.0.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = { 
    Name = "myiac-public-a"
  }
}
resource "aws_subnet" "subnet-pub-c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.16.1.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true
  tags = { 
    Name = "myiac-public-c"
  }
}
resource "aws_subnet" "subnet-eks-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.16.2.0/24"
  availability_zone = "ap-northeast-2a"
  tags = { 
    Name = "myiac-eks-a"
  }
}
resource "aws_subnet" "subnet-eks-c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.16.3.0/24"
  availability_zone = "ap-northeast-2c"
  tags = { 
    Name = "myiac-eks-c"
  }
}
resource "aws_subnet" "subnet-ep-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.16.4.0/24"
  availability_zone = "ap-northeast-2a"
  tags = { 
    Name = "myiac-ep-a"
  }
}
resource "aws_subnet" "subnet-ep-c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.16.5.0/24"
  availability_zone = "ap-northeast-2c"
  tags = { 
    Name = "myiac-ep-c"
  }
}
resource "aws_subnet" "subnet-pri-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.16.6.0/24"
  availability_zone = "ap-northeast-2a"
  tags = { 
    Name = "myiac-pri-a"
  }
}
resource "aws_subnet" "subnet-pri-c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.16.7.0/24"
  availability_zone = "ap-northeast-2c"
  tags = { 
    Name = "myiac-pri-c"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "myiac-igw"
  }
}

resource "aws_eip" "nat-eip" {
  domain  = "vpc"
  tags = {
    Name = "myiac-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.subnet-pub-a.id

  tags = {
    Name = "myiac-nat"
  }
  depends_on = [aws_eip.nat-eip, aws_internet_gateway.igw]
}

resource "aws_route_table" "route_pub" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "myiac-route-pub-rt"
  }
  depends_on = [aws_nat_gateway.nat]
}
resource "aws_route_table" "route_eks" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }
  tags = {
    Name = "myiac-route-eks-rt"
  }
}
resource "aws_route_table" "route_ep" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }
  tags = {
    Name = "myiac-route-ep-rt"
  }
}
resource "aws_route_table" "route_pri" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "myiac-route-pri-rt"
  }
  depends_on = [aws_nat_gateway.nat]
}

resource "aws_route_table_association" "link_pub-a" {
  subnet_id      = aws_subnet.subnet-pub-a.id
  route_table_id = aws_route_table.route_pub.id
}
resource "aws_route_table_association" "link_pub-c" {
  subnet_id      = aws_subnet.subnet-pub-c.id
  route_table_id = aws_route_table.route_pub.id
}
resource "aws_route_table_association" "link_eks-a" {
  subnet_id      = aws_subnet.subnet-eks-a.id
  route_table_id = aws_route_table.route_eks.id
}
resource "aws_route_table_association" "link_eks-c" {
  subnet_id      = aws_subnet.subnet-eks-c.id
  route_table_id = aws_route_table.route_eks.id
}
resource "aws_route_table_association" "link_ep-a" {
  subnet_id      = aws_subnet.subnet-ep-a.id
  route_table_id = aws_route_table.route_ep.id
}
resource "aws_route_table_association" "link_ep-c" {
  subnet_id      = aws_subnet.subnet-ep-c.id
  route_table_id = aws_route_table.route_ep.id
}
resource "aws_route_table_association" "link_pri-a" {
  subnet_id      = aws_subnet.subnet-pri-a.id
  route_table_id = aws_route_table.route_pri.id
}
resource "aws_route_table_association" "link_pri-c" {
  subnet_id      = aws_subnet.subnet-pri-c.id
  route_table_id = aws_route_table.route_pri.id
}
# (이하 Public 2, Private 2, IGW, NAT GW, Route Table 생성 코드 100줄 이상 생략 없이 다 적어야 함...)

# ---------------------------------------------------------
# 2. VPC Endpoint (PrivateLink)
# ---------------------------------------------------------
resource "aws_security_group" "vpc_endpoint_sg" {
  name = "myiac-endpoint-sg"
  vpc_id      = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { 
    Name = "myiac-endpoint-sg"
  }
}
resource "aws_vpc_endpoint" "secret_manager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-secret-manager-a"
  }
}
resource "aws_vpc_endpoint" "api_gateway" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.apigateway"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-api-gateway-a"
  }
}
resource "aws_vpc_endpoint" "api_gateway_execute" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.execute-api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-api-execute-a"
  }
}
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-ecr-ep-a"
  }
}
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-ecr-dkr-a"
  }
}
resource "aws_vpc_endpoint" "eks" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.eks"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
    tags = { 
    Name = "myiac-eks-a"
  }
}
resource "aws_vpc_endpoint" "eks_auth" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.eks-auth"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-eks-auth-a"
  }
}
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-ec2-a"
  }
}
resource "aws_vpc_endpoint" "ec2-message" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-ec2-message-a"
  }
}
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-sts-a"
  }
}
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-ssm-a"
  }
}
resource "aws_vpc_endpoint" "ssm-message" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-ssm-message-a"
  }
}
resource "aws_vpc_endpoint" "signin" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.signin"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-signin-a"
  }
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-s3-a"
  }
}
resource "aws_vpc_endpoint" "s3files" {
  vpc_id              = aws_vpc.main.id
  service_name        = "aws.api.ap-northeast-2.s3files"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-s3files-a"
  }
}
resource "aws_vpc_endpoint" "s3-gateway" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type   = "Gateway"
  route_table_ids     = [aws_route_table.route_eks.id]
  tags = { 
    Name = "myiac-s3-gateway-a"
  }
}
resource "aws_vpc_endpoint" "iam" {
  region              = "ap-northeast-2"
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.iam"
  service_region      = "us-east-1"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-iam-a"
  }
}
resource "aws_vpc_endpoint" "route53" {
  region              = "ap-northeast-2"
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.route53"
  service_region      = "us-east-1"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-route53-a"
  }
}
resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-2.sqs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-ep-a.id] 
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
  tags = { 
    Name = "myiac-sqs-a"
  }
}

# ---------------------------------------------------------
# 3. EC2 Bastion (Jump Server)
# ---------------------------------------------------------
resource "aws_security_group" "myiac-squid-sg" {
  name   = "myiac-squid-sg"
  vpc_id = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "myiac-squid-sg" }
}
resource "aws_security_group" "myiac-cmd-sg" {
  name   = "myiac-cmd-sg"
  vpc_id = aws_vpc.main.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "myiac-cmd-sg" }
}
resource "aws_security_group_rule" "allow_command_ep" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.vpc_endpoint_sg.id
  source_security_group_id = aws_security_group.myiac-cmd-sg.id
}
resource "aws_security_group_rule" "allow_squid_ep" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.vpc_endpoint_sg.id
  source_security_group_id = aws_security_group.myiac-squid-sg.id
}
resource "aws_instance" "squid" {
  ami           = "ami-0903c0a0a5519f80c"
  instance_type = "t3.micro"
  iam_instance_profile = "myiac-ssm"
  subnet_id     = aws_subnet.subnet-pri-a.id
  private_ip    = "172.16.6.72"
  vpc_security_group_ids = [aws_security_group.myiac-squid-sg.id]
  user_data = <<-EOF
  #!/bin/bash
  dnf update -y
  dnf install squid -y
  echo "acl naver dstdomain .naver.com" >> /etc/squid/squid.conf
  echo "http_access allow naver" >> /etc/squid/squid.conf
  systemctl restart squid
  EOF
  tags = { Name = "myiac-squid" }
  depends_on = [aws_nat_gateway.nat]
}
resource "aws_instance" "bastion" {
  ami           = "ami-0903c0a0a5519f80c"
  instance_type = "t3.micro"
  iam_instance_profile = "myiac-ssm"
  subnet_id     = aws_subnet.subnet-pri-a.id
  vpc_security_group_ids = [aws_security_group.myiac-cmd-sg.id]
  tags = { Name = "myiac-command" }
  depends_on = [aws_instance.squid]
}
resource "aws_security_group" "myiac-eks-sg" {
  name   = "myiac-eks-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "myiac-eks-sg" }
}
resource "aws_security_group_rule" "allow_self_eks" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.myiac-eks-sg.id
  source_security_group_id = aws_security_group.myiac-eks-sg.id
}
/*
resource "aws_security_group_rule" "allow_eks_ep" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.vpc_endpoint_sg.id
  source_security_group_id = aws_security_group.myiac-eks-sg.id
}
*/
resource "aws_iam_role" "cluster" {
  name = "myiac-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role" "node" {
  name = "myiac-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryPullOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonElasticContainerRegistryPublicReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly"
  role       = aws_iam_role.node.name
}
resource "aws_eks_cluster" "myiac-eks" {
  name = "myiac-eks"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster.arn
  version  = "1.35"

  bootstrap_self_managed_addons = false

  

  vpc_config {

    security_group_ids = [aws_security_group.myiac-eks-sg.id]

    endpoint_private_access = true
    endpoint_public_access = true

    subnet_ids = [
      aws_subnet.subnet-eks-a.id,
      aws_subnet.subnet-eks-c.id
    ]    
  }
  upgrade_policy {
    support_type = "STANDARD"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]
}

resource "aws_eks_node_group" "system-node" {
  cluster_name    = aws_eks_cluster.myiac-eks.name
  node_group_name = "system-node"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = [
      aws_subnet.subnet-eks-a.id,
      aws_subnet.subnet-eks-c.id
  ]

  instance_types = ["t3.medium"]
  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }


  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly
  ]
}
resource "aws_security_group_rule" "allow_eks_cluster_ep" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.vpc_endpoint_sg.id
  source_security_group_id = aws_eks_cluster.myiac-eks.vpc_config[0].cluster_security_group_id
  depends_on = [
    aws_eks_cluster.myiac-eks
  ]
}
resource "aws_security_group_rule" "allow_eks_cluster_squid" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.myiac-squid-sg.id
  source_security_group_id = aws_eks_cluster.myiac-eks.vpc_config[0].cluster_security_group_id
  depends_on = [
    aws_eks_cluster.myiac-eks
  ]
}
resource "aws_security_group_rule" "allow_squid_eks_cluster" {
  type              = "egress"
  from_port         = 3128
  to_port           = 3128
  protocol          = "tcp"
  security_group_id = aws_eks_cluster.myiac-eks.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.myiac-squid-sg.id
  depends_on = [
    aws_eks_cluster.myiac-eks
  ]
}


resource "aws_eks_addon" "pod_identity" {
  cluster_name                = aws_eks_cluster.myiac-eks.name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = "v1.3.10-eksbuild.3"
  resolve_conflicts_on_update = "PRESERVE"
}
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.myiac-eks.name
  addon_name                  = "coredns"
  addon_version               = "v1.14.3-eksbuild.3"
  resolve_conflicts_on_update = "PRESERVE"
}
resource "aws_eks_addon" "kube-proxy" {
  cluster_name                = aws_eks_cluster.myiac-eks.name
  addon_name                  = "kube-proxy"
  addon_version               = "v1.35.3-eksbuild.17"
  resolve_conflicts_on_update = "PRESERVE"
}
resource "aws_eks_addon" "vpc-cni" {
  cluster_name                = aws_eks_cluster.myiac-eks.name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.22.4-eksbuild.3"
  resolve_conflicts_on_update = "PRESERVE"
  pod_identity_association {
    role_arn = "arn:aws:iam::어카운트ID:role/AmazonEKSPodIdentityAmazonVPCCNIRole"
    service_account = "aws-node"
  }
}                 
resource "aws_eks_access_entry" "myiac27" {
  cluster_name      = aws_eks_cluster.myiac-eks.name
  principal_arn     = "arn:aws:iam::어카운트ID:user/myiac27"
  type              = "STANDARD" 
}
resource "aws_eks_access_policy_association" "myiac27" {
  cluster_name    = aws_eks_cluster.myiac-eks.name
  policy_arn      = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn   = "arn:aws:iam::어카운트ID:user/myiac27"
  access_scope {
    type       = "cluster"
  }
}
resource "aws_s3_bucket" "myiac-s3" {
  bucket = "myiac-eks-files-test"
  tags ={
    Name = "myiac-eks-files-test"
  }
}
resource "aws_s3_bucket_versioning" "myiac-s3-versioning" {
  bucket = aws_s3_bucket.myiac-s3.id
  versioning_configuration {
    status = "Enabled"
  }
}
/*
resource "aws_s3files_file_system" "myiac-s3-files" {
  bucket    = aws_s3_bucket.myiac-s3.arn
  role_arn  = 
}
*/
