locals {
  environment = var.environment != null ? var.environment : "multi-runner"
  aws_region  = "eu-west-1"
  #aws_region  = "us-east-1"

  # Load runner configurations from Yaml files
  multi_runner_config = { for c in fileset("${path.module}/templates/runner-configs", "*.yaml") : trimsuffix(c, ".yaml") => yamldecode(file("${path.module}/templates/runner-configs/${c}")) }
}

resource "random_id" "random" {
  byte_length = 20
}

module "multi-runner" {
  source              = "../../modules/multi-runner"
  multi_runner_config = local.multi_runner_config
  #  Alternative to loading runner configuration from Yaml files is using static configuration:
  #  multi_runner_config = {
  #    "linux-x64" = {
  #      matcherConfig : {
  #        labelMatchers = [["self-hosted", "linux", "x64", "amazon"]]
  #        exactMatch    = false
  #      }
  #      fifo                = true
  #      delay_webhook_event = 0
  #      runner_config = {
  #        runner_os                       = "linux"
  #        runner_architecture             = "x64"
  #        runner_name_prefix              = "amazon-x64_"
  #        create_service_linked_role_spot = true
  #        enable_ssm_on_runners           = true
  #        instance_types                  = ["m5ad.large", "m5a.large"]
  #        runner_extra_labels             = "amazon"
  #        runners_maximum_count           = 1
  #        enable_ephemeral_runners        = true
  #        scale_down_schedule_expression  = "cron(* * * * ? *)"
  #      }
  #    }
  #  }
  aws_region                        = local.aws_region
  vpc_id                            = module.vpc.vpc_id
  subnet_ids                        = module.vpc.private_subnets
  runners_scale_up_lambda_timeout   = 60
  runners_scale_down_lambda_timeout = 60
  prefix                            = local.environment
  tags = {
    Project = "ProjectX"
  }
  github_app = {
    key_base64     = var.github_app.key_base64
    id             = var.github_app.id
    webhook_secret = random_id.random.hex
  }

  # Assuming local build lambda's to use pre build ones, uncomment the lines below and download the
  # lambda zip files lambda_download
  webhook_lambda_zip                = "../lambdas-download/webhook.zip"
  runner_binaries_syncer_lambda_zip = "../lambdas-download/runner-binaries-syncer.zip"
  runners_lambda_zip                = "../lambdas-download/runners.zip"

  # enable_workflow_job_events_queue = true
  # override delay of events in seconds

  # Enable debug logging for the lambda functions
  log_level = "debug"

}
