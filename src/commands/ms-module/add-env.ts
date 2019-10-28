import {Command, flags} from '@oclif/command'
import cli from 'cli-ux'
const fs = require('fs-extra')
const chalk  = require('chalk')

export class AddEnvToMsModule extends Command {

  static description = 'add environment aws infrastructure to the microservice module'

  static examples = [
    `$ mssk ms-module:add-env environment_name`,
  ]

  static args = [{
    name: 'env',
    required: true, 
    description: 'environment name', // help description
  }]

  static flags = {
    help: flags.help({char: 'h'})
  }

  async run() {
    const {args, flags} = this.parse(AddEnvToMsModule)

    const env = args.env

    const baseModuleInitiated = fs.pathExistsSync(`./mssk-properties.json`)
    if(!baseModuleInitiated) {
      return this.log(chalk.red(`Base microservice module is not initiated in this directory! Please first run "mssk ms-module:init", or switch to a directory where base microservice module is already initiated!`))
    }


    let baseMsProperties: any;
    try {
      baseMsProperties = fs.readJsonSync('./mssk-properties.json')
    } catch (err) {
      return this.log("There was a problem while reading mssk properties file: " + chalk.red(err))
    }
    const msName = baseMsProperties.msName
    const baseAppName = baseMsProperties.baseAppName
    const region = baseMsProperties.region
    const profile = baseMsProperties.profile
    const baseAppEnvironments = baseMsProperties.environments

    
    const environmentExists = fs.pathExistsSync(this.envDir(env))    
    if(environmentExists) {
      this.log(chalk.red(`environment "${env}" already exists in this directory!`))

      // yes/no confirmation
      const overwrite = await cli.confirm('Overwrite existing environment? (yes/no)')
      if (!overwrite) {
        return;
      }
    }

    this.log(`Environment "${env}" will be added...`)  

    // create directory for enviroment
    this.mkdirp(this.envDir(env), () => { 
      if(!baseMsProperties.environments) {
        baseMsProperties.environments = []
      }
      baseMsProperties.environments.push(env)

      // write the updated mssk properties file
      fs.writeJson(`./mssk-properties.json`, baseMsProperties, (err) => {
         if(err) {
            return this.log("There was a problem while updating mssk properties file: " + chalk.red(err))
          }

          this.log(chalk.green("mssk properties file updated!"))
      })

      const envMainFile = `${this.envDir(env)}/main.tf`
      // create terraform main file
      fs.writeFile(`${envMainFile}`, this.envModuleContent(msName, baseAppName, region, profile, env), (err) => {
        if(err) { 
          return this.log(`There was a problem creating the environment file "${envMainFile}" : ` + chalk.red(err.toString()))
        }
        this.log("Main class file - " + chalk.bold(envMainFile) + " -  " + chalk.green(`created with default configs! Please update the customizable configs in it as desired!`))
      })
    })
  }

  envDir(env: string) {
    return `./env-${env}`
  }

  envModuleContent(msName: string, baseAppName: string, region: string, profile: string, env: string) {
    return `
#############################################################################################################################
#
# Note: infrastructure metadata files (spring properties, generated ssh keys, readme, redis address...etc.) will be generated into ./meta_outputs #
#
#############################################################################################################################

# Configure the AWS Provider as needed
provider "aws" {
  region = "${region}"
  profile = "${profile}"
}

module "microservice" {
  source = "../base_terraform_module"

  ##################
  ## AUTO Generated by MSSK! Do not configure manually!
  ##################
  # general configurations
  base_app_name = "${baseAppName}"
  ms_name = "${msName}"
  environment = "${env}" # this would match a Spring profile in the Spring Java project (an "application-${env}.propertoes" will be automatically generated in "./meta_outputs" after running "terraform apply")
  ##################

  #####################
  # Customizable configurations (edit manually as desired)
  #####################

  url_base_path = "/${msName}" # will be used in the main load balancer to forward traffic to this microservice. (Note: must match "server.servlet.context-path" configs in the Spring Java project)
  log_group_retention_in_days = 7

  ## ECS & asg (auto scaling group) configs
  ec2_instance_type = "t2.micro"
  asg_min_size = 1 # minmum running servers (cannot automatically scale down below that)
  asg_max_size = 2 # maximum running servers (cannot automatically scale up above that)
  asg_desired_capacity = 2 # desired running servers.
  asg_health_check_grace_period = 300 # sefconds

  # minumum running tasks during a deployment (calculated as: percent * asg_desired_capacity, rounded up). 
  ecs_service_deployment_minimum_healthy_percent = 20 # ***Note***: if the result is equal to asg_min_size, the force deployment is ignored, so deployment might be pending until it can go through.
  ecs_task_deregistration_delay = 60 # in seconds. Grace period after before killing the task after it was taken off from the pool. (i.e. to finish the current requests it had)
  task_def_soft_memory = 256 # in MiB
  container_port = 8080 # should match what's exposed in the DockerFile in the Spring Java project
  health_check_path = "/health" # the health check api path, which will be used as: <url_base_path><health_check_path>
  health_check_interval = 60  # interval betweeen checks
  health_check_timeout = 30 # request timeout. After that request will be considered as failed. Must be less health_check_interval
  health_check_healthy_threshold = 3 # number of successful requests to consider the container healthy
  health_check_unhealthy_threshold = 3 # number of failed requests to consider the container healthy
  health_check_success_http_code = "200-299" # http code (or code range) to expect from a request to mark it as successful
  ec2_ssh_inbound_cidr_blocks = ["0.0.0.0/0"]  # public SSH access! Must be [] or specific IPs in production.

  ## DB configs
  # Initial master password can be found in  "meta_outputs_path/README.md" after infrastructure is created. 
  # It must be changed directly on AWS console or CLI. Not changing it means the DB password is not secure!!!
  db_engine = "mysql"
  db_engine_version_major = "8.0" # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  db_engine_version_minor = "16"
  db_instance_class =  "db.t2.micro" # All available types: https://aws.amazon.com/rds/instance-types/
  db_allocated_storage = 5    # in GiB
  db_username = "master_user"
  db_deletion_protection = false # Should be true for production! (when set to true, terraform won't be able to delete the instance)
  db_storage_encrypted = false
  db_port = 3306
  db_maintenance_window = "Mon:00:00-Mon:03:00"
  db_backup_window = "03:00-06:00"
  db_backup_retention_period_in_days = 7
  db_log_types = ["error", "general", "slowquery"] # this depends on the engine and engine_version! check mysql documentation for the specific version to see supported log types
  db_apply_immediately = false # can be set to true when needed, but generally the changes should be applied in the maintenance window, not immediately
  db_replicas_count = 1
  db_replica_instance_class = "db.t2.micro"

  ## Redis cache configs
  redis_instance_class = "cache.t2.micro" # All available types: https://aws.amazon.com/elasticache/pricing/
  redis_port = 6379
  redis_engine_version = "5.0.5" # All available versions:: https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/supported-engine-versions.html
  redis_maintenance_window = "Mon:00:00-Mon:03:00"
}

`

  }

  mkdirp(path: string, successHandler = () => {}) {
    fs.mkdirp(path, (err) => {
      if(err) { 
        return this.log(`There was a problem creating folder "${path}": ` + chalk.red(err.toString()))
      }
      this.log("Folder - " + chalk.bold(path) + " -  " + chalk.green(`created!`))

      successHandler();
    })
  }
}