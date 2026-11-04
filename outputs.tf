output "target_groups" {
  value = [
    for tg in aws_lb_target_group.service:
    {
      arn = tg.arn
      arn_suffix = tg.arn_suffix
    }
  ]
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.service.arn
}

output "task_role_arn" {
  value = try(aws_iam_role.service.0.arn, null)
}

output "scaling_target" {
  value = try(aws_appautoscaling_target.service.0, null)
}

output "service_name" {
  value = aws_ecs_service.service.name
}

output "execution_role_arn" {
  value = try(aws_iam_role.execution[0].arn, null)
}
