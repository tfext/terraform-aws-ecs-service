locals {
  role_count = var.role_policy != null || length(var.role_policy_arns) > 0 ? 1 : 0
  role_arn = try(
    concat(
      var.role_arn == null ? [] : [var.role_arn],
      aws_iam_role.service.*.arn
    )[0],
    null
  )
}

module "ecs_task_assume_role" {
  source = "github.com/tfext/terraform-aws-assume-role-policy"
  type   = "ecs_task"
}

resource "aws_iam_role" "service" {
  count              = local.role_count
  name               = var.name
  path               = "/service/"
  assume_role_policy = module.ecs_task_assume_role.policy.json
}

resource "aws_iam_policy" "service" {
  count  = var.role_policy == null ? 0 : 1
  name   = var.name
  policy = var.role_policy
}

resource "aws_iam_role_policy_attachment" "service" {
  count      = var.role_policy == null ? 0 : 1
  policy_arn = aws_iam_policy.service[0].arn
  role       = aws_iam_role.service[0].name
}

resource "aws_iam_role_policy_attachment" "service_managed" {
  count      = length(var.role_policy_arns)
  policy_arn = var.role_policy_arns[count.index]
  role       = aws_iam_role.service[0].name
}

# Execution role, so ECS can read the containers' secrets
locals {
  execution_role_count = anytrue([for c in var.containers : length(c.secret_arns) > 0]) ? 1 : 0
  secret_arns          = distinct(flatten(var.containers[*].secret_arns))
}

data "aws_partition" "current" {}

resource "aws_iam_role" "execution" {
  count              = local.execution_role_count
  name               = "${var.name}-execution"
  path               = "/service/"
  assume_role_policy = module.ecs_task_assume_role.policy.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  count      = local.execution_role_count
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.execution[0].name
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = local.execution_role_count
  name  = "secrets"
  role  = aws_iam_role.execution[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = local.secret_arns
    }]
  })
}
