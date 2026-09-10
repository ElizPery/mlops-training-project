data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "inference_service" {
  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = {
    Environment = "production"
    Project     = "mlops-training-project"
  }
}

resource "aws_ecr_repository_policy" "inference_service_policy" {
  repository = aws_ecr_repository.inference_service.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPushPull"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}

# Add lifecycle policy (clear old images)
resource "aws_ecr_lifecycle_policy" "inference_service_lifecycle_policy" {
  repository = aws_ecr_repository.inference_service.name

  policy = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Keep last 10 images",
        "selection": {
            "tagStatus": "any",
            "countType": "imageCountMoreThan",
            "countNumber": 10
        },
        "action": {
            "type": "expire"
        }
      }
    ]
  }
  EOF
}