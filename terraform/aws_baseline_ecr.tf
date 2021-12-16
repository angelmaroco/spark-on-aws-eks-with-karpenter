resource "aws_ecr_repository" "spark-custom" {
  name                 = var.aws_baseline_ecr.name
  image_tag_mutability = var.aws_baseline_ecr.image_tag_mutability
}

resource "aws_ecr_repository_policy" "spark-custom-policy" {
  repository = aws_ecr_repository.spark-custom.name
  policy     = <<EOF
  {
    "Version": "2008-10-17",
    "Statement": [
      {
        "Sid": "adds full ecr access to the demo repository",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  }
  EOF
}
