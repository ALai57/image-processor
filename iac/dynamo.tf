resource "aws_dynamodb_table" "images" {
  name           = "images"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "photo_name"
  range_key      = "sort_key"

  attribute {
    name = "photo_name"
    type = "S"
  }

  ## Because we are combining different types of Attributes,
  ## we won't have a meaningful name to identify the sort key
  ## which could be either VERSIONS, etc
  attribute {
    name = "sort_key"
    type = "S"
  }

  global_secondary_index {
    name               = "sort_key_idx"
    hash_key           = "sort_key"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["photo_name"]
  }
}
