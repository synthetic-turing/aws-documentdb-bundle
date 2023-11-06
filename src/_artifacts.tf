locals {
  data_infrastructure = {
    project_id = aws_docdb_cluster.main_cluster.id
    cluster_id = aws_docdb_cluster.main_cluster.id
  }
  data_authentication = {
    username = aws_docdb_cluster.main_cluster.master_username
    password = aws_docdb_cluster.main_cluster.master_password
    hostname = aws_docdb_cluster.main_cluster.endpoint
    port     = 27017
  }
}

resource "massdriver_artifact" "mongodb" {
  field                = "mongodb"
  provider_resource_id = aws_docdb_cluster.main_cluster.arn
  name                 = "AWS DocumentDB Cluster ${aws_docdb_cluster.main_cluster.cluster_identifier}"
  artifact = jsonencode(
    {
      data = {
        infrastructure = local.data_infrastructure
        authentication = local.data_authentication
      }
      specs = {
        mongo = {
          version = aws_docdb_cluster.main_cluster.engine_version 
        }
      }
    }
  )
}