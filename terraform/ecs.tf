resource "aws_ecs_cluster" "main" {
  name = "tf-ecs-cluster"
  tags = merge(
    {
      "Name" = "alb-tg-${var.vpc_name}"
    },
    var.tags,
  )
}

resource "aws_ecs_task_definition" "quix_backend" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${var.quix_backend_image}",
    "memory": ${var.fargate_memory},
    "name": "quix_backend",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": ${var.backend_port},
        "hostPort": ${var.backend_port}
      }
    ]
  }
]
DEFINITION

}

resource "aws_ecs_service" "main" {
  name            = "tf-ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.quix_backend.arn
  desired_count   = "1"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets         = aws_subnet.private.*.id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name   = "quix_backend"
    container_port   = var.backend_port
  }

  depends_on = [aws_alb_listener.front_end]
}

# module "ecs_fargate" {
#   source                = "git::https://github.com/tmknom/terraform-aws-ecs-fargate.git?ref=tags/1.4.0"
#   name                  = "example"
#   container_name        = "nginx"
#   container_port        = "80"
#   cluster               = "${aws_ecs_cluster.ecs_cluster}"
#   subnets               = ["${aws_subnet.private.*.id}"]
#   target_group_arn      = "${aws_lb_target_group.default.arn}"
#   vpc_id                = "${aws_vpc.main.id}"
#   container_definitions = "${data.template_file.default.rendered}"
#   desired_count                      = 2
#   deployment_maximum_percent         = 200
#   deployment_minimum_healthy_percent = 100
#   deployment_controller_type         = "ECS"
#   assign_public_ip                   = true
#   health_check_grace_period_seconds  = 10
#   ingress_cidr_blocks                = ["0.0.0.0/0"]
#   cpu                                = 256
#   memory                             = 512
#   requires_compatibilities           = ["FARGATE"]
#   iam_path                           = "/service_role/"
#   iam_description                    = "example description"
#   enabled                            = true
#
#   create_ecs_task_execution_role = false
#   ecs_task_execution_role_arn    = "${aws_iam_role.default.arn}"
#
#   tags = {
#     Environment = "prod"
#   }
# }
#
#
# resource "aws_security_group" "default" {
#  # count = 0
#   name   = "${local.security_group_name}"
#   vpc_id = "${aws_vpc.main}"
#
#   tags = "${merge(map("Name", local.security_group_name), var.tags)}"
# }
#
#
# resource "aws_lb_target_group" "default" {
#   name     = "tf-example-lb-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = "${aws_vpc.main.id}"
# }
#
#
# resource "aws_iam_role" "default" {
#   name               = "ecs-task-execution-for-ecs-fargate"
#   assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
# }
#
# data "aws_iam_policy_document" "assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]
#
#     principals {
#       type        = "Service"
#       identifiers = ["ecs-tasks.amazonaws.com"]
#     }
#   }
# }
#
# resource "aws_iam_policy" "default" {
#   name   = "${aws_iam_role.default.name}"
#   policy = "${data.aws_iam_policy.ecs_task_execution.policy}"
# }
#
# resource "aws_iam_role_policy_attachment" "default" {
#   role       = "${aws_iam_role.default.name}"
#   policy_arn = "${aws_iam_policy.default.arn}"
# }
#
# data "aws_iam_policy" "ecs_task_execution" {
#   arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }
#
# data "template_file" "default" {
#   template = "${file("container_definitions.json")}"
#
# }
#
# locals {
#     security_group_name = "default"
#   container_name = "example"
#   container_port = "80"
# }
#
#
# # Simply specify the family to find the latest ACTIVE revision in that family.
# data "aws_ecs_task_definition" "mongo" {
#   task_definition = "${aws_ecs_task_definition.mongo.family}"
# }
# resource "aws_ecs_cluster" "ecs_cluster" {
#   name = "main-ecs-cluster"
# }
#
# resource "aws_ecs_task_definition" "mongo" {
#   family = "mongodb"
#
#   container_definitions = <<DEFINITION
# [
#   {
#     "cpu": 128,
#     "environment": [{
#       "name": "SECRET",
#       "value": "KEY"
#     }],
#     "essential": true,
#     "image": "mongo:latest",
#     "memory": 128,
#     "memoryReservation": 64,
#     "name": "mongodb"
#   }
# ]
# DEFINITION
# }
#
# resource "aws_ecs_service" "nginx" {
#   name          = "mongo"
#   cluster       = "${aws_ecs_cluster.foo.id}"
#   desired_count = 2
#
#   # Track the latest ACTIVE revision
#   task_definition = "${aws_ecs_task_definition.mongo.family}:${max("${aws_ecs_task_definition.mongo.revision}", "${data.aws_ecs_task_definition.mongo.revision}")}"
# }
