resource "aws_iam_role" "github_actions_oidc" {
  name = "GitHubActionsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::702865854817:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub": "repo:asutosh/repo-1-ec2:*"

          },
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })


  tags = {
    Creator = "asutosh"
  }
}

# Attach AdministratorAccess (for full control - restrict later)
resource "aws_iam_role_policy_attachment" "github_actions_full_access" {
  role       = aws_iam_role.github_actions_oidc.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
