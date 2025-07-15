output "ec2_role_arn" {
  value = aws_iam_role.ec2_s3_writer_role.arn
}
