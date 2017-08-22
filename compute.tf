// - Security groups
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web"
  description = "Allow traffic to ec2 instances"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_ip_to_access_rds}"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "WEB"
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-load_balancer"
  description = "Allow traffic to alb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.web.id}"]
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["${aws_security_group.web.id}"]
  }

  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "WEB-ALB"
  }
}

// - Computing

resource "aws_alb" "web" {
  name            = "${var.project_name}-web-alb"
  internal        = false
  security_groups = ["${aws_security_group.alb.id}"]
  subnets         = ["${aws_subnet.eu-west-1-ec2.*.id}"]

  enable_deletion_protection = false

  tags {
    environment = "prod"
  }
}

resource "aws_alb_target_group" "web" {
  name     = "web-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.default.id}"

  health_check {
    interval            = "60"
    path                = "/"
    port                = 80
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = 200
  }
}

resource "aws_iam_instance_profile" "codedeploy" {
  name = "codedeploy-ec2-instance-profile"
  role = "${aws_iam_role.codedeploy_instance.name}"
}

resource "aws_iam_role" "codedeploy_instance" {
  name = "codedeploy"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "scale_policy" {
  name = "scale_policy"
  role = "${aws_iam_role.codedeploy_instance.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:RegisterTargets",
        "autoscaling:Describe*",
        "autoscaling:EnterStandby",
        "autoscaling:ExitStandby",
        "autoscaling:UpdateAutoScalingGroup"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_alb_listener" "web" {
  load_balancer_arn = "${aws_alb.web.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.web.arn}"
    type             = "forward"
  }
}

resource "aws_launch_configuration" "web" {
  # name   = "${var.project_name}-web_configuration"
  image_id          = "${var.ami}"
  instance_type     = "${var.instance_type}"
  security_groups   = ["${aws_security_group.web.id}"]
  key_name          = "${var.aws_key_name}"
  enable_monitoring = false

  iam_instance_profile = "${aws_iam_instance_profile.codedeploy.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name_prefix               = "web-site-"
  max_size                  = 7
  min_size                  = 2
  default_cooldown          = 60
  health_check_grace_period = 600
  health_check_type         = "ELB"

  # desired_capacity          = 1
  vpc_zone_identifier  = ["${aws_subnet.eu-west-1-ec2.*.id}"]
  launch_configuration = "${aws_launch_configuration.web.name}"
  target_group_arns    = ["${aws_alb_target_group.web.arn}"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "service"
    value               = "web"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web-scale-up" {
  name                   = "${var.project_name}-web-scale-up"
  autoscaling_group_name = "${aws_autoscaling_group.web.name}"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  scaling_adjustment     = 2
}

resource "aws_autoscaling_policy" "web-scale-down" {
  name                   = "${var.project_name}-web-scale-down"
  autoscaling_group_name = "${aws_autoscaling_group.web.name}"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  scaling_adjustment     = -1
}

resource "aws_cloudwatch_metric_alarm" "high_CPU" {
  alarm_name          = "${var.project_name}-high_CPU-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.web.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.web-scale-up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "low_CPU" {
  alarm_name          = "${var.project_name}-low_CPU-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "240"
  statistic           = "Average"
  threshold           = "50"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.web.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.web-scale-down.arn}"]
}
