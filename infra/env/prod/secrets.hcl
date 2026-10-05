locals {
  
  # Terragrunt feature to run commands and fetch secrets
    route53_zone_arn = run_cmd("--terragrunt-quiet", "aws", "ssm", "get-parameter", "--region", "eu-west-2", "--name",
    "/eks/prod/route53_zone_arn", "--query", "Parameter.Value", "--output", "text")

    domain = run_cmd("--terragrunt-quiet", "aws", "ssm", "get-parameter", "--region", "eu-west-2", "--name",
    "/eks/prod/domain", "--query", "Parameter.Value", "--output", "text")

        # ci role later
    cluster_admins = split(",", run_cmd("--terragrunt-quiet", "aws", "ssm", "get-parameter", "--region", "eu-west-2", 
    "--name", "/eks/prod/cluster_admins", "--query", "Parameter.Value", "--output", "text"))
}
