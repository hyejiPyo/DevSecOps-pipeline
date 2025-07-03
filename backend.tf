terraform {
    backend "s3" {
        bucket = "phj-devsecops-bucket"
        key = "cicd/devsecops/terraform.tfstate"
        region = "ap-northeast-2"
        dynamodb_table = "terraform-lock-table"
        encrypt = true
    }
}