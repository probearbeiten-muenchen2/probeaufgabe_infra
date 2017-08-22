resource "aws_cloudwatch_metric_alarm" "500x-alarm" {
  alarm_name                = "${var.project_name}-500x-errors-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "60"
  metric_name               = "HTTPCode_Backend_5XX"
  namespace                 = "AWS/ELB"
  period                    = "120"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "Notify about 500x-errors on LB"
  alarm_actions             = [] // some SNS
  dimensions {
    LoadBalancerName = "${aws_alb.web.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_CPU_alarm" {
  alarm_name                = "${var.project_name}-high-CPU-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "95"
  alarm_description         = "Notify about high-CPU usage on EC2"
  alarm_actions             = [] // some SNS
  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.web.name}"
  }
}
