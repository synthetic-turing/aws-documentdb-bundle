locals {
  name = var.md_metadata.name_prefix

  # Database properties
  instance_class      = var.database.instance_class
  instance_count      = var.database.num_instances
  deletion_protection = var.database.deletion_protection

  # Networking properties
  subnet_type = var.networking.subnet_type
  subnet_ids = {
    "internal" = toset([for subnet in var.vpc.data.infrastructure.internal_subnets : element(split("/", subnet["arn"]), 1)])
    "private"  = toset([for subnet in var.vpc.data.infrastructure.private_subnets : element(split("/", subnet["arn"]), 1)])
  }

  # Observability properties
  enabled_cloudwatch_logs_exports = lookup(var.observability, "enabled_cloudwatch_logs_exports", [])
  enable_performance_insights     = var.observability.enable_performance_insights

  # Backup properties
  retention_period    = var.backup.retention_period
  skip_final_snapshot = var.backup.skip_final_snapshot
}

resource "random_id" "username_suffix" {
  byte_length = 8
}

resource "random_password" "root_password" {
  length  = 10
  special = false
}

resource "aws_docdb_subnet_group" "main" {
  name       = "${local.name}-subnet-group"
  subnet_ids = local.subnet_ids[local.subnet_type]
}

resource "aws_docdb_cluster" "main_cluster" {
  cluster_identifier              = local.name
  engine                          = "docdb"
  enabled_cloudwatch_logs_exports = local.enabled_cloudwatch_logs_exports
  deletion_protection             = local.deletion_protection
  backup_retention_period         = local.retention_period
  master_username                 = "documentdb_root_${random_id.username_suffix.id}"
  master_password                 = random_password.root_password.result
  final_snapshot_identifier       = "${local.name}-final-snapshot"
  db_subnet_group_name            = aws_docdb_subnet_group.main.name
  skip_final_snapshot             = local.skip_final_snapshot
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count                       = local.instance_count
  identifier                  = "${local.name}-instance-${count.index}"
  enable_performance_insights = local.enable_performance_insights
  cluster_identifier          = aws_docdb_cluster.main_cluster.id
  instance_class              = local.instance_class
}
