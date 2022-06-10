resource "aws_dynamodb_table" "images" {
  name           = "images"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "file_path"
  range_key      = "sort_key"

  attribute {
    name = "file_path"
    type = "S"
  }

  ## Because we are combining different types of Attributes,
  ## we won't have a meaningful name to identify the sort key
  ## which could be either VERSIONS, ALBUM, or OTHER METADATA
  attribute {
    name = "sort_key"
    type = "S"
  }

  attribute {
    name = "album"
    type = "S"
  }

  global_secondary_index {
    name               = "album"
    hash_key           = "sort_key"
    range_key          = "album"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["file_path"]
  }
}
