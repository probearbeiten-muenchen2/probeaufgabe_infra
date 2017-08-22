resource "aws_vpc" "default" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "eu-west-1-ec2" {
  vpc_id                  = "${aws_vpc.default.id}"
  count                   = 3
  cidr_block              = "${element(var.ec2_subnet_cidr, count.index)}"
  availability_zone       = "${element(var.ec2_az, count.index)}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.project_name} web subnet"
  }
}

resource "aws_route_table" "eu-west-1-ec2" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "Web routes"
  }
}

resource "aws_route_table_association" "eu-west-1-ec2" {
  count          = 3
  subnet_id      = "${element("${aws_subnet.eu-west-1-ec2.*.id}", count.index)}"
  route_table_id = "${element("${aws_route_table.eu-west-1-ec2.*.id}", count.index)}"
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.project_name}-rds-vps"
  subnet_ids = ["${aws_subnet.eu-west-1-ec2.*.id}"]

  tags {
    Name = "${var.project_name} RDS subnet"
  }
}
