data "aws_iam_policy_document" "aws_baseline_kms_document" {

  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "kms:*",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${var.tags.region}.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey*"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]
    resources = [
      "*"
    ]
  }
}

module "aws_baseline_kms" {
    source      = "clouddrove/kms/aws"
    version     = "0.15.0"
    
  deletion_window_in_days = var.aws_baseline_kms.deletion_window_in_days
  description             = var.aws_baseline_kms.description
  enable_key_rotation     = var.aws_baseline_kms.enable_key_rotation
  enabled                 = var.aws_baseline_kms.enabled
  is_enabled              = var.aws_baseline_kms.is_enabled
  key_usage               = var.aws_baseline_kms.key_usage
  name                    = var.aws_baseline_kms.name
  policy                  = data.aws_iam_policy_document.aws_baseline_kms_document.json
  tags                    = var.tags
}