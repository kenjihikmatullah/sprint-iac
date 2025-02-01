resource "aws_iam_policy" "ecs_restrictions" {
  name        = "projectsprint-ecs-restrictions"
  description = "Enforces ECS resource limits and configuration standards for ProjectSprint developers"

  # https://docs.aws.amazon.com/service-authorization/latest/reference/reference_policies_actions-resources-contextkeys.html
  # https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition_operators.html
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LimitALB"
        Effect = "Deny"
        Action = [
          # https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_CreateLoadBalancer.html
          "elasticloadbalancing:CreateLoadBalancer"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "elasticloadbalancing:Scheme"        = "internal"
            "elasticloadbalancing:IpAddressType" = "ipv4"
            "elasticloadbalancing:Type"          = "application"
            "elasticloadbalancing:SubnetMappings:SubnetId" : [
              "subnet-0bfa16281c4e9df40",
              "subnet-0d749e9461f70bf86"
            ]
          },
        }
      },
      {
        Sid    = "LimitCloudWatchLogRetention"
        Effect = "Deny"
        Action = [
          # https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutRetentionPolicy.html
          "logs:PutRetentionPolicy"
        ]
        Resource = "*"
        Condition = {
          NumericGreaterThan = {
            "logs:retentionInDays" = "7"
          }
        }
      },
      #{
      #  Sid    = "LimitMaximumAutoScaling"
      #  Effect = "Deny"
      #  Action = [
      #    # https://docs.aws.amazon.com/autoscaling/application/APIReference/API_RegisterScalableTarget.html
      #    "application-autoscaling:RegisterScalableTarget"
      #  ]
      #  Resource = "*"
      #  Condition = {
      #    NumericGreaterThan = {
      #      "application-autoscaling:MaxCapacity" = "6"
      #    }
      #  }
      #},
      #{
      #  Sid    = "LimitECSTaskDefinitionResources"
      #  Effect = "Deny"
      #  Action = [
      #    # https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_RegisterTaskDefinition.html
      #    "ecs:RegisterTaskDefinition"
      #  ]
      #  Resource = "*"
      #  Condition = {
      #    NumericGreaterThan = {
      #      "ecs:cpu"    = "257"
      #      "ecs:memory" = "513"
      #    },
      #    StringNotEquals = {
      #      "ecs:runtimePlatform:cpuArchitecture"       = "ARM64"
      #      "ecs:runtimePlatform:operatingSystemFamily" = "LINUX"
      #    }
      #  }
      #},
      {
        Sid    = "PreventVpcAndSubnetCreation"
        Effect = "Deny"
        Action = [
          "ec2:CreateVpc",
          "ec2:CreateSubnet"
        ]
        Resource = "*"
      },
    ]
  })
}

# Attach to developers group
resource "aws_iam_group_policy_attachment" "projectsprint_ecs_restrictions" {
  group      = aws_iam_group.projectsprint_developers.name
  policy_arn = aws_iam_policy.ecs_restrictions.arn
}

# Attach to the CloudFormation execution role
resource "aws_iam_role_policy_attachment" "cfn_ecs_restrictions" {
  role       = "example-app-staging-CFNExecutionRole"
  policy_arn = aws_iam_policy.ecs_restrictions.arn
}
