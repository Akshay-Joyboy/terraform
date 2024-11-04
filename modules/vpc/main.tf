provider "aws" {
  region = "ap-south-2"
}

#custom vpc
resource "aws_vpc" "custom" {

  cidr_block = var.IPv4_VPC_CIDR_block
  instance_tenancy = var.instance_tenancy_value
  enable_dns_hostnames = var.enable_dns_hostnames_value

  tags = {
    Name = "main"
  }
}

#subnet 1
resource "aws_subnet" "public-2a" {
  vpc_id = aws_vpc.custom.id
  cidr_block = var.cidr_block_value_public_a
  map_public_ip_on_launch = true
  tags = {
    Name = "public-2a"
  }

}

#subnet 2
resource "aws_subnet" "public-2b" {
  vpc_id = aws_vpc.custom.id
  cidr_block = var.cidr_block_value_public_b
  map_public_ip_on_launch = true
  tags = {
    Name = "public-2b"
  }

}

#subnet 3
resource "aws_subnet" "private-2a" {
  vpc_id = aws_vpc.custom.id
  cidr_block = var.cidr_block_value_private_a

  tags = {
    Name = "private-2a"
  }

}

#subnet 4
resource "aws_subnet" "private-2b" {
  vpc_id = aws_vpc.custom.id
  cidr_block = var.cidr_block_value_private_b

  tags = {
    Name = "private-2b"
  }

}

#subnet 5
resource "aws_subnet" "db-2a" {
  vpc_id = aws_vpc.custom.id
  cidr_block = var.cidr_block_value_db_a

  tags = {
    Name = "db-2a"
  }

}

#subnet 6
resource "aws_subnet" "db-2b" {
  vpc_id = aws_vpc.custom.id
  cidr_block = var.cidr_block_value_db_b

  tags = {
    Name = "db-2b"
  }

}

#subnet 7 
resource "aws_subnet" "loadbal-2a" {
  vpc_id = aws_vpc.custom.id
  cidr_block = var.cidr_block_value_loadbal_a

  tags = {
    Name = "loadbal-2a"
  }

}

#subnet 8
resource "aws_subnet" "loadbal-2b" {
  vpc_id = aws_vpc.custom.id
  cidr_block = var.cidr_block_value_loadbal_b

  tags = {
    Name = "loadbal-2b"
  }

}


#######################
#public route table

resource "aws_route_table" "public-RT" {
  vpc_id = aws_vpc.custom.id

   tags = {
    Name = "public-route"
  }
}

#######################
#private route table

resource "aws_route_table" "private-RT" {
  vpc_id = aws_vpc.custom.id

   tags = {
    Name = "private-route"
  }
}

##############
#igw route for public

resource "aws_route" "routes-for-public" {
  route_table_id = aws_route_table.public-RT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

##############################3
#internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom.id

  tags = {
    Name = "custom-igw"
  }
}

#aws public route table association
resource "aws_route_table_association" "publicRT-a-association" {
  subnet_id = aws_subnet.public-2a.id
  route_table_id = aws_route_table.public-RT.id
}

#aws public route table association
resource "aws_route_table_association" "publicRT-b-association" {
  subnet_id = aws_subnet.public-2b.id
  route_table_id = aws_route_table.public-RT.id
}

#aws private route table association
resource "aws_route_table_association" "privateRT-a-association" {
  subnet_id = aws_subnet.private-2a.id
  route_table_id = aws_route_table.private-RT.id
}

#aws private route table association
resource "aws_route_table_association" "privateRT-b-association" {
  subnet_id = aws_subnet.private-2b.id
  route_table_id = aws_route_table.private-RT.id
}


#aws private route table association
resource "aws_route_table_association" "privateRT-db-a-association" {
  subnet_id = aws_subnet.db-2a.id
  route_table_id = aws_route_table.private-RT.id
}


#aws private route table association
resource "aws_route_table_association" "privateRT-db-b-association" {
  subnet_id = aws_subnet.db-2b.id
  route_table_id = aws_route_table.private-RT.id
}


#aws private route table association
resource "aws_route_table_association" "privateRT-lb-a-association" {
  subnet_id = aws_subnet.loadbal-2a.id
  route_table_id = aws_route_table.private-RT.id
}
#aws private route table association
resource "aws_route_table_association" "privateRT-lb-b-association" {
  subnet_id = aws_subnet.loadbal-2b.id
  route_table_id = aws_route_table.private-RT.id
}




#---------------------------------------------------------------------------------------------#
#flowlogs

#####
# CloudWatch Log Group for Flow Logs
resource "aws_cloudwatch_log_group" "clwLG_for_vpc_flowlogs" {
  name = "vpc-destination-flowlogs-group"
  retention_in_days = 0  # Adjust as needed
}

# IAM Policy Document for assuming the IAM Role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flowlogs_role" {
  name               = "vpc-flowlogs-role-custom"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# IAM Policy Document for logging actions
data "aws_iam_policy_document" "logging_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

# Inline IAM Policy for the role
resource "aws_iam_role_policy" "vpc_flowlogs_policy" {
  name   = "vpc-flowlogs-inline-policy"
  role   = aws_iam_role.vpc_flowlogs_role.id
  policy = data.aws_iam_policy_document.logging_policy.json
}

# Flow Log Configuration
resource "aws_flow_log" "for_custom" {
  iam_role_arn    = aws_iam_role.vpc_flowlogs_role.arn
  log_destination = aws_cloudwatch_log_group.clwLG_for_vpc_flowlogs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.custom.id  # Ensure this VPC resource is defined
}