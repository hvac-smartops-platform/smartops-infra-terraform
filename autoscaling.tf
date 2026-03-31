resource "aws_launch_template" "web_lt" {
  name_prefix   = "smartops-web-lt-"
  image_id      = "ami-05024c2628f651b80"
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

user_data = base64encode(<<-EOF
            #!/bin/bash
            yum update -y
            amazon-linux-extras install docker -y
            systemctl start docker
            systemctl enable docker
            usermod -aG docker ec2-user
            docker pull adnan1978/smartops-flask-app:1.0
            docker run -d -p 5000:5000 --name smartops-flask-app adnan1978/smartops-flask-app:1.0
            EOF
)

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "smartops-asg-instance"
    }
  }
}
resource "aws_autoscaling_group" "web_asg" {
  name                = "smartops-web-asg"
  desired_capacity    = 2
  max_size            = 3
  min_size            = 2
  health_check_type   = "ELB"
  vpc_zone_identifier = [
    aws_subnet.public_subnet.id,
    aws_subnet.public_subnet_2.id
  ]

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "smartops-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "smartops-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "smartops-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "smartops-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  alarm_description = "Scale out when average CPU is above 70%"
  alarm_actions     = [aws_autoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "smartops-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  alarm_description = "Scale in when average CPU is below 20%"
  alarm_actions     = [aws_autoscaling_policy.scale_in.arn]
}

