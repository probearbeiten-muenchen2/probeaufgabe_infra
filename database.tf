// - Security groups

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds_sg"
  description = "Allow traffic to rds instance"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_ip_to_access_rds}"]
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.web.id}"]
  }

  tags {
    name = "RDS SG"
  }
}

// - Computing
resource "aws_db_instance" "default" {
  allocated_storage       = 5
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "5.6.34"
  identifier              = "${var.project_name}-rds"
  instance_class          = "${var.db_instance_class}"
  name                    = "${var.db_name}"
  username                = "${var.db_username}"
  password                = "${var.db_password}"
  publicly_accessible     = true
  vpc_security_group_ids  = ["${aws_security_group.rds.id}"]
  db_subnet_group_name    = "${aws_db_subnet_group.default.name}"
  apply_immediately       = true
  backup_retention_period = 7
  backup_window           = "04:00-05:00"
  multi_az                = true
}
