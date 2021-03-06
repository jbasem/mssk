microservices-starter-kit
=========================

 A starter kit (aws infrastructure, project) to help programmers quickly kickoff their multi-microservices system..


[![oclif](https://img.shields.io/badge/cli-oclif-brightgreen.svg)](https://oclif.io)
[![Version](https://img.shields.io/npm/v/microservices-starter-kit.svg)](https://npmjs.org/package/microservices-starter-kit)
[![Downloads/week](https://img.shields.io/npm/dw/microservices-starter-kit.svg)](https://npmjs.org/package/microservices-starter-kit)
[![License](https://img.shields.io/npm/l/microservices-starter-kit.svg)](https://github.com/jihadbasem/microservices-starter-kit/blob/master/package.json)

<!-- toc -->
* [Introduction](#introduction)
* [Prerequisites](#prerequisites)
* [Usage](#usage)
* [Commands](#commands)
<!-- tocstop -->


# Introduction
<!-- introduction -->
This tool is the result of a dissertation project for an MSE degree. It aims to help the entrepreneur programmers to quickly start a multi-containerized-microservice system that is following the latest scalability trends and best practices recommended by the market experts and educational studies.

The tool provides a set of commands to generate: 
1) Terraform** modules to build an Amazon Web Services (AWS) scalable multi-containerized-microservice infrastructure that is designed to satisfy the best practices for infrastructure scalability.
2) a Java Spring Boot/Cloud application template that is already configured to address the best practices for a microservice software.

```
** Terraform: a tool to build Infrastructure as Code. For more information, see: https://www.terraform.io/
```

Using the tool, you can generate the infrastructure and the application for environment separately. In other words, you can create separate AWS infrastructures per environment (qa, staging,  prod…etc.) as well as a ready-to-deploy Java microservice application in each environment. 

The figure below shows a simplified high level overview of the generated microservice infrastructure:

![General Overview](https://jb-public-resources.s3.amazonaws.com/Generic+Design.jpg)

However, when we look at the actual AWS generated implementation, it’s a bit more complicated than that. The infrastructure is generated at 2 stages:

- Stage 1: The base system or application infrastructure. 

In this stage, we need to generate the base infrastructure that would consolidate all of our generated microservices and represents them as a single system to the end user. 

The generated AWS components of this stage are: Virtual Private Cloud (VPC) along with private and public subnets, Application Load Balancer (ALB), Elastic Container Service (ECS), and Auto-Scaling Group (ASG) for Elastic Compute Cloud (EC2) instances that run Consul** Servers. 

```
** Consul: A service networking solution that is used to coordinate internal communication between the microservices (Service Discovery) as well as to provide dynamic and secure configuration capabilities. For more information about Consul, see: https://www.consul.io/
```

- Stage 2: The individual microservice infrastructure. 

In this stage, we need to generate an infrastructure for each of our microservices. A new microservice infrastructure can be generated and added to the base infrastructure at any time. 

The generated AWS components of this stage are: Target Group (TG), Elastic Container Registry (ECR), ECS Service, ECS Task Definition, Auto-Scaling Groups (ASG) and EC2 instances that are automatically loaded with Consul Clients, Relational Data Base Service that is spread over multiple availability zones (Multi-AZ RDS), Read Replicas Data Bases (RDS Read Replica), and Elastic Cache – Redis.

In addition to the components mentioned in those 2 stages, some miscellaneous resources needed for this infrastructure to operate are generated in each stage, like Security Groups, Launch Configurations and IAM roles.  

The figure below shows a diagram of a generated infrastructure for 3 microservices (A, B, & C), each with different configuration for the number of running instances and database read replicas.

![Generated AWS Infrastructure](https://jb-public-resources.s3.amazonaws.com/AWS+Impl+new.jpg)


As mentioned before, all this infrastructure can be generated by a couple set of commands, and it can be replicated for as many environments as you want. 

<!-- introductionstop -->



# Prerequisites 
<!-- prerequisites -->

To use this tool, you should be familiar with:
- For the infrastructure part: Terraform, Amazon Web Services (AWS).
- For the software part: Java, Gradle, Spring Boot, Spring Cloud, Consul. 

<!-- prerequisitesstop -->



# Usage
<!-- usage -->
```sh-session
$ npm install -g microservices-starter-kit
$ mssk COMMAND
running command...
$ mssk (-v|--version|version)
microservices-starter-kit/0.0.1 darwin-x64 node-v10.16.0
$ mssk --help [COMMAND]
USAGE
  $ mssk COMMAND
...
```
<!-- usagestop -->


# Commands
<!-- commands -->

*NOTE*: This tool uses the AWS configs in your system (`~/.aws`). Make sure you have your credentials defined their. You can provide the credentials profile to use if you wish to use a custom AWs profile defined in `~/.aws/credentials`. Otherwise, the `default` profile will be used.

The commands can be categorized to 3 types:

- "base-module": This command is used to generate the resources for the base module (stage 1 as described in the introduction). You MUST first initiate the base module (`base-module:init`) in the current directory, then add an environment (`base-module:add-env`). Then if you go (`cd`) into the created environment directory, you would find a file named: `main.tf`. This file contains the main configuration for the infrastructure for that environment. You can update the customizable configs as descired, then run: `terraform init`, and `terraform apply`. Once all done, you will find all the base application resources created in your AWS account. Also, after applying terraform, you would find a folder named "meta_outputs" inside the generated environment folder, which contains the key pem file that is needed to ssh into the EC2 instances. 

- "ms-module": This command is used to generate the resources for the microservices module (stage 2 as described in the introduction). Before using this command, you should have initated the base infrastructure and configured and environment as described in the previous step. Then, to use this command, you MUST first initiate the microservice module (`ms-module:init`) in the current directory, then add an environment (`ms-module:add-env`). Then if you go (`cd`) into the created environment directory, you would find a file named: `main.tf`. This file contains the main configuration for the infrastructure for that environment. You can update the customizable configs as descired, then run: `terraform init`, and `terraform apply`. Once all done, you will find all the base application resources created in your AWS account. Also, after applying terraform, you would find a folder named "meta_outputs" inside the generated environment folder, which contains the key pem file that is needed to ssh into the EC2 instances, as well as a file named `application-{enviornment-name}.properties`, which is the properties file needed for the Spring configurations in the generated Java application.

- "ms-project": This command is used generate the microservice software application (Java, Gradle, Spring Boot/Cloud). The generated template is already configured with CI/CD on [CircleCI](https://circleci.com). However, you would need to configure a new project on CircleCI first, and add the required environment variables to it. You can find the environment variables that you need to setup on CircleCI in the circleci config file (/.circleci/config.yml) in the generated project template. Also, you would need to copy the generated properties file for the specific environments from the generated "meta_outputs" folder from the previous step. 


* [`mssk help [COMMAND]`](#mssk-help-command)
* [`mssk base-module:init APPNAME`](#mssk-base-moduleinit-appname)
* [`mssk base-module:add-env ENV`](#mssk-base-moduleadd-env-env)
* [`mssk ms-module:init MSNAME`](#mssk-ms-moduleinit-msname)
* [`mssk ms-module:add-env ENV`](#mssk-ms-moduleadd-env-env)
* [`mssk ms-project:init`](#mssk-ms-projectinit)


## `mssk help [COMMAND]`

display help for mssk

```
USAGE
  $ mssk help [COMMAND]

ARGUMENTS
  COMMAND  command to show help for

OPTIONS
  --all  see all commands in CLI
```

_See code: [@oclif/plugin-help](https://github.com/oclif/plugin-help/blob/v2.2.1/src/commands/help.ts)_


## `mssk base-module:init APPNAME`

Initialize the base application/system aws infrastructure module in the current directory.

```
USAGE
  $ mssk base-module:init APPNAME

ARGUMENTS
  APPNAME  base app name

OPTIONS
  -h, --help             show CLI help
  -p, --profile=profile  aws profile
  -r, --region=region    aws region

EXAMPLE
  $ mssk base-module:init my_base_app_name --region=us-east-1 --profile=default
```

_See code: [src/commands/base-module/init.ts](https://github.com/jihadbasem/microservices-starter-kit/blob/v0.0.1/src/commands/base-module/init.ts)_


## `mssk base-module:add-env ENV`

Adds aws infrastructure for the given ENV in the base app module (in the current directory). 

```
USAGE
  $ mssk base-module:add-env ENV

ARGUMENTS
  ENV  environment name

OPTIONS
  -h, --help  show CLI help

EXAMPLE
  $ mssk base-module:add-env environment_name
```

_See code: [src/commands/base-module/add-env.ts](https://github.com/jihadbasem/microservices-starter-kit/blob/v0.0.1/src/commands/base-module/add-env.ts)_


## `mssk ms-module:init MSNAME`

Initialize the microservice aws infrastructure module in the current directory.

```
USAGE
  $ mssk ms-module:init MSNAME

ARGUMENTS
  MSNAME  microservice name

OPTIONS
  -a, --baseAppName=baseAppName                      base app name
  -f, --baseAppPropertiesFile=baseAppPropertiesFile  base app mssk properties file
  -h, --help                                         show CLI help
  -p, --profile=profile                              aws profile
  -r, --region=region                                aws region

EXAMPLE

       $ mssk ms-module:init my_microservice_name --baseAppPropertiesFile=path_to_base_app_mssk_properties_file

       OR
    
       $ mssk ms-module:init my_microservice_name --baseAppName=my_base_app_name --region=us-east-1 --profile=default
```

_See code: [src/commands/ms-module/init.ts](https://github.com/jihadbasem/microservices-starter-kit/blob/v0.0.1/src/commands/ms-module/init.ts)_


## `mssk ms-module:add-env ENV`

Adds aws infrastructure for the given ENV in the microservice module (in the current directory). 

```
USAGE
  $ mssk ms-module:add-env ENV

ARGUMENTS
  ENV  environment name

OPTIONS
  -h, --help  show CLI help

EXAMPLE
  $ mssk ms-module:add-env environment_name
```

_See code: [src/commands/ms-module/add-env.ts](https://github.com/jihadbasem/microservices-starter-kit/blob/v0.0.1/src/commands/ms-module/add-env.ts)_


## `mssk ms-project:init`

Create a new Gradle/Java Spring Boot/Cloud project template in the current directory.

```
USAGE
  $ mssk ms-project:init

OPTIONS
  -f, --msPropertiesFile=msPropertiesFile  microservice mssk properties file
  -g, --group=group                        gradle artifact group
  -h, --help                               show CLI help

  -n, --msName=msName                      microservice name.. this must be EXACTLY the same as the ms-nmae used to
                                           generate the ms-module

  -v, --version=version                    gradle artifact version

EXAMPLE

       $ mssk ms-project:init --msPropertiesFile=path_to_microservice_mssk_properties_file

       OR
  
       $ mssk ms-project:init --name=my_mircoservice_name --group=com.mycom --version=0.0.1
```

_See code: [src/commands/ms-project/init.ts](https://github.com/jihadbasem/microservices-starter-kit/blob/v0.0.1/src/commands/ms-project/init.ts)_
<!-- commandsstop -->
