resource "aws_ecr_repository" "spark-custom" {
  name                 = var.aws_baseline_ecr.name
  image_tag_mutability = var.aws_baseline_ecr.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.aws_baseline_ecr.image_scanning_configuration
  }

  encryption_configuration {
    encryption_type = var.aws_baseline_ecr.encryption_type
    kms_key         = module.aws_baseline_kms.key_arn
  }

  tags = var.tags
}

resource "aws_ecr_repository_policy" "spark-custom-policy" {
  repository = aws_ecr_repository.spark-custom.name
  policy     = data.aws_iam_policy_document.spark-custom-policy-document.json
}


data "aws_iam_policy_document" "spark-custom-policy-document" {
  statement {
    sid = "AllowPull"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings"
    ]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
  }
}


resource "null_resource" "build-and-push-ecr" {
  provisioner "local-exec" {
    command = "../build/ecr/build-spark-image.sh -a ${data.aws_caller_identity.current.account_id} -r ${data.aws_region.current.name}"
  }

  depends_on = [
    aws_ecr_repository.spark-custom
  ]
}
