resource "aws_codedeploy_app" "web" {
  name = "${var.project_name}-web"
}

resource "aws_iam_role_policy" "deploy_policy" {
  name = "deploy_policy"
  role = "${aws_iam_role.deploy_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:CompleteLifecycleAction",
                "autoscaling:DeleteLifecycleHook",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeLifecycleHooks",
                "autoscaling:PutLifecycleHook",
                "autoscaling:RecordLifecycleActionHeartbeat",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "tag:GetTags",
                "tag:GetResources"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "deploy_role" {
  name = "deploy_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_codedeploy_deployment_config" "web" {
  deployment_config_name = "${var.project_name}-deployment-config"

  minimum_healthy_hosts {
    type  = "HOST_COUNT"
    value = 1
  }
}

resource "aws_codedeploy_deployment_group" "web" {
  app_name               = "${aws_codedeploy_app.web.name}"
  deployment_group_name  = "${var.project_name}"
  service_role_arn       = "${aws_iam_role.deploy_role.arn}"
  deployment_config_name = "${aws_codedeploy_deployment_config.web.id}"

  autoscaling_groups = ["${aws_autoscaling_group.web.id}"]

  //TODO: add trigger_configuration section
  auto_rollback_configuration {
    enabled = false
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
