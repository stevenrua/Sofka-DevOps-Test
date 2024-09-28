resource "aws_vpc" "vpc_virginia" {
  cidr_block = var.time_off_virginia_cidr
  tags = {
    Name = "VPC_VIRGINIA-${local.sufix}"    
  }
}

resource "aws_subnet" "subnet_public_time_off" {
  vpc_id = aws_vpc.vpc_virginia.id
  cidr_block = var.list_cidr_subnets[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public subnet-${local.sufix}"    
  }
}

resource "aws_subnet" "subnet_private_time_off" {
  vpc_id = aws_vpc.vpc_virginia.id
  cidr_block =  var.list_cidr_subnets[1]  
  tags = {
    Name = "Private subnet-${local.sufix}"    
  }
  depends_on = [ 
      aws_subnet.subnet_public_time_off
    ]
}

resource "aws_internet_gateway" "igw_time_off" {
  vpc_id = aws_vpc.vpc_virginia.id

  tags = {
    Name = "igw_off vpc virginia-${local.sufix}"
  }
}

resource "aws_route_table" "public_crt_time_off" {
  vpc_id = aws_vpc.vpc_virginia.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_time_off.id
  }

  tags = {
    Name = "Route Table-${local.sufix}"
  }
}

resource "aws_route_table_association" "crt_association_public_subnet" {
  subnet_id      = aws_subnet.subnet_public_time_off.id
  route_table_id = aws_route_table.public_crt_time_off.id
}

resource "aws_security_group" "sg_public_instance" {
  name        = "public instance SG"
  description = "Allow SSH inbound traffic and all egress traffic"
  vpc_id      = aws_vpc.vpc_virginia.id

  dynamic "ingress" {
    for_each = var.ingress_port_list
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = [var.sg_ingress_cidr]
      
    }
  }

  tags = {
    Name = "public instance SG-${local.sufix}"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.sg_public_instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  tags = {
    Name = "ecsTaskExecutionRole-${local.sufix}"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_ecs_task_definition" "task_definition_fargate" {
  tags = {
    Name = "task_definition_fargate-${local.sufix}"
  }

  family                   = "task_definition_fargate"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = "256"  
  memory                  = "512"  

  container_definitions = jsonencode([
    {
      name      = "app-time-off"
      image     = "767398087527.dkr.ecr.us-east-1.amazonaws.com/time-off-repo"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        },
      ]
    }
  ])

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_ecs_cluster" "ecs_cluster_time_off" {

  name = "ecs_cluster_time_off"
  tags = {
    Name = "ecs_cluster_time_off-${local.sufix}"
  }  
}

resource "aws_ecs_service" "service_time_off" {
  tags = {
    Name = "service_time_off-${local.sufix}"
  }
  name            = "service_time_off"
  cluster         = aws_ecs_cluster.ecs_cluster_time_off.id
  task_definition = aws_ecs_task_definition.task_definition_fargate.id
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.subnet_public_time_off.id]
    security_groups  = [aws_security_group.sg_public_instance.id]
    assign_public_ip = true
  }
}