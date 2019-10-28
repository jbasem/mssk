microservices-starter-kit
=========================

 A starter kit (project, aws infrastructure) to help programmers quickly kickoff their microservice project

[![oclif](https://img.shields.io/badge/cli-oclif-brightgreen.svg)](https://oclif.io)
[![Version](https://img.shields.io/npm/v/microservices-starter-kit.svg)](https://npmjs.org/package/microservices-starter-kit)
[![Downloads/week](https://img.shields.io/npm/dw/microservices-starter-kit.svg)](https://npmjs.org/package/microservices-starter-kit)
[![License](https://img.shields.io/npm/l/microservices-starter-kit.svg)](https://github.com/jihadbasem/microservices-starter-kit/blob/master/package.json)

<!-- toc -->
* [Usage](#usage)
* [Commands](#commands)
<!-- tocstop -->
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
* [`mssk base-module:add-env ENV`](#mssk-base-moduleadd-env-env)
* [`mssk base-module:init APPNAME`](#mssk-base-moduleinit-appname)
* [`mssk help [COMMAND]`](#mssk-help-command)
* [`mssk ms-module:add-env ENV`](#mssk-ms-moduleadd-env-env)
* [`mssk ms-module:init MSNAME`](#mssk-ms-moduleinit-msname)
* [`mssk ms-project:init`](#mssk-ms-projectinit)

## `mssk base-module:add-env ENV`

add environment aws infrastructure to the base app module

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

## `mssk base-module:init APPNAME`

init base app aws infrastructure module

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

## `mssk ms-module:add-env ENV`

add environment aws infrastructure to the microservice module

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

## `mssk ms-module:init MSNAME`

init microservice aws infrastructure module

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

## `mssk ms-project:init`

Create a new Gradle/Java Spring Boot/Cloud project template

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
