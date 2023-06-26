
#S3 Bucket Config
resource "aws_s3_bucket" "s3bucket" {

  bucket        = "demobucket9908890"
  force_destroy = "false"


  lifecycle {
    prevent_destroy = false  # Optional: Prevent accidental deletion of the bucket
  }

}

resource "aws_s3_bucket_website_configuration" "static-website" {
  bucket = aws_s3_bucket.s3bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_versioning" "static-website-versioning" {
  bucket = aws_s3_bucket.s3bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "s3-object_ownership" {
  bucket = aws_s3_bucket.s3bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "static-website-public-access" {
  bucket = aws_s3_bucket.s3bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "static-website-acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.s3-object_ownership,
    aws_s3_bucket_public_access_block.static-website-public-access,
  ]

  bucket = aws_s3_bucket.s3bucket.id
  acl    = "public-read"
}

#S3 Bucket Policy

resource "aws_s3_bucket_policy" "cms2-aws_s3_bucket_policy" {
  bucket = aws_s3_bucket.s3bucket.id

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion"
      ],
      "Effect": "Allow",
      "Principal": "*",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.s3bucket.bucket}/*",
      "Sid": "PublicRead"
    }
  ],
  "Version": "2012-10-17"
}
POLICY

}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3-serverside-encryption" {
  bucket = aws_s3_bucket.s3bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

  depends_on = [ aws_s3_bucket.s3bucket ]
}

resource "aws_cloudfront_distribution" "s3_frontend_distribution" {  

enabled             = true
http_version        = "http2"
is_ipv6_enabled     = true
comment             = "demo-cloudfront"
price_class         = "PriceClass_All"
retain_on_delete    = true
default_root_object = "index.html"

origin {
    domain_name = aws_s3_bucket.s3bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.s3bucket.id

  }

  # Default cache behavior
  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.s3bucket.bucket
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true
    default_ttl            = 0
    max_ttl                = 0
    min_ttl                = 0
    smooth_streaming       = false
    viewer_protocol_policy = "redirect-to-https"
    

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

  }

  # Custom error responses
  custom_error_response {
    error_code           = 403
    response_code        = 200
    response_page_path   = "/index.html"
    error_caching_min_ttl = 60
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" #to be add only AU Region for UAT Prod (Consider the SL Region too)
    }
  }

#Temp Certficate Enable for CloudFront untill getting Certificate ARN

    viewer_certificate {
    cloudfront_default_certificate = true
  }

  depends_on = [ aws_s3_bucket.s3bucket ]

}