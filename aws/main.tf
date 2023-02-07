provider "aws" {
  region  = "us-east-1"
}

resource "aws_ecr_repository" "rearc_repo" {
  name = "rearc"
}

resource "aws_ecs_cluster" "rearc_cluster" {
  name = "rearc"
}

resource "aws_iam_role" "rearcrole" {
  name               = "rearcrole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_subnet_ids" "default" {
  vpc_id = "vpc-088db2c12fc112df6"
}

data "aws_subnet" "default" {
  for_each = data.aws_subnet_ids.default.ids
  id       = each.value
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "rearcpolicyattach" {
  role       = aws_iam_role.rearcrole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_ecs_task_definition" "rearc" {
  family                   = "rearc" 
  requires_compatibilities = ["FARGATE"] 
  network_mode             = "awsvpc"    
  memory                   = 512         
  cpu                      = 256   
  execution_role_arn       = aws_iam_role.rearcrole.arn
  container_definitions    = <<DEFINITION
  [
    {
      "name": "rearc",
      "image": "165547459139.dkr.ecr.us-east-1.amazonaws.com/rearc:1",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
}

resource "aws_alb" "rearclb" {
  name               = "rearclb"
  load_balancer_type = "application"
  subnets = [ for s in data.aws_subnet.default : s.id ]
  security_groups = ["${aws_security_group.rearclcsecgroup.id}"]
}

resource "aws_security_group" "rearclcsecgroup" {
  vpc_id = "vpc-088db2c12fc112df6"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rearcservicesecgroup" {
  vpc_id = "vpc-088db2c12fc112df6"
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    security_groups = ["${aws_security_group.rearclcsecgroup.id}"]
  }
}

  resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "vpc-088db2c12fc112df6"
  health_check {
    matcher = "200,301,302"
    path = "/usr/src/app"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.rearclb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_ecs_service" "rearcservice" {
  name            = "rearcservice"               
  cluster         = aws_ecs_cluster.rearc_cluster.id  
  task_definition = aws_ecs_task_definition.rearc.arn 
  launch_type     = "FARGATE"
  desired_count   = 3

network_configuration {
    subnets          =  [for s in data.aws_subnet.default : s.id]
    assign_public_ip = true
    security_groups = [aws_security_group.rearcservicesecgroup.id]
}

load_balancer {
  target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our target group
  container_name   = "${aws_ecs_task_definition.rearc.family}"
  container_port   = 3000 
}
}
