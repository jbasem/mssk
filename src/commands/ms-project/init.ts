import {Command, flags} from '@oclif/command'
import cli from 'cli-ux'
const fs = require('fs-extra')
const { exec } = require('child_process')
const path = require('path');
const chalk  = require('chalk')
const camelCase = require('camelcase')
const prependFile = require('prepend-file')
const recursiveFileReader = require("recursive-readdir");

const BUILD_FILES = __dirname + '/../../resources/project_template/base_files'
const SPRING_RESOURCES = __dirname + '/../../resources/project_template/spring_resources'
const JAVA_CLASSES = __dirname + '/../../resources/project_template/java_classes'

export class InitMicroservicePorject extends Command {

  static description = 'Create a new Gradle/Java Spring Boot/Cloud project template'

  static examples = [
    `
    $ mssk ms-project:init --msPropertiesFile=path_to_microservice_mssk_properties_file

    OR
  
    $ mssk ms-project:init --name=my_mircoservice_name --group=com.mycom --version=0.0.1
    `,
  ]

  static args = []

  static flags = {
    help: flags.help({char: 'h'}),

    msPropertiesFile: flags.string({char: 'f', description: 'microservice mssk properties file'}),
    msName: flags.string({char: 'n', description: 'microservice name.. this must be EXACTLY the same as the ms-nmae used to generate the ms-module'}),
    group: flags.string({char: 'g', description: 'gradle artifact group'}),
    version: flags.string({char: 'v', description: 'gradle artifact version'}),
  }

  async run() {
    const {flags} = this.parse(InitMicroservicePorject)


    const msPropertiesFile = flags.msPropertiesFile
    let msName = flags.msName
    const group = flags.group || 'com.mycom'
    const version = flags.version || '0.0.1'

    if(msPropertiesFile) {
      this.log(`MSSK properties file for microservice is provided.. "--name" flag will be ignored`)  

      // read MSSK properties file
      let msProperties: any;
      try {
        msProperties = fs.readJsonSync(msPropertiesFile)
      } catch (err) {
        return this.log("There was a problem while reading the provided mssk properties file: " + chalk.red(err))
      }

      msName = msProperties.msName
    } else if (!msName){
      return this.log(chalk.red(`You must provide either a name ("--name") or an MSSK properties file for the microservice module`))
    }

    const alreadyExists = fs.pathExistsSync(`./mssk-properties.json`)  
    if(alreadyExists) {
      this.log(chalk.red(`Project already initiated in this directory!`))

      // yes/no confirmation
      const overwrite = await cli.confirm('Overwrite existing module? (yes/no)')
      if (!overwrite) {
        return;
      }
    }

    this.log(`microservice "${msName}"" will be created.. Gradle artifact: "${group}:${msName}:${version}"`)
    this.initMicroserviceProjectTemplate(msName!, group, version);
  }

  /*
  * Copies resources files into current directory
  */
  initMicroserviceProjectTemplate(msName: string, group: string, version: string) {
    let mainPackage = `${group}.${msName}`
    let mainPackagePath = mainPackage.replace(/\./gi, '/')

    const mainDir = `./src/main`
    const mainJavaDir = `${mainDir}/java`
    const appDir = `${mainJavaDir}/${mainPackagePath}`
    const testDir = `./src/test/java`
    const unitTestsDir = `${testDir}/${mainPackagePath}`

    // create unit tests directory
    this.mkdirp(`${unitTestsDir}`)

    // create main application directory, then create main class and copy java resources
    this.mkdirp(`${appDir}`, () => {

      // Copy java files
      fs.copy(JAVA_CLASSES, appDir, (err) => {
        if(err) {
          return this.log("There was a problem while copying java files: " + chalk.red(err))
        }

        // prepend the correct package to all classes
        recursiveFileReader(appDir, [`MainApplication.java`], (err, files) => {
          if(err) {
            return this.log("There was a problem while getting list of java classes: " + chalk.red(err))
          }

          files.forEach((classFile: string) => {
            const parentFolder = path.dirname(classFile).split(path.sep).pop()
            prependFile(classFile, `package ${mainPackage}.${parentFolder};`, (err) => {
              if (err) {
                return this.log(`There was a problem while prepending package to file "${classFile}": ` + chalk.red(err))
              }
           
              // Success
              this.log(chalk.green(`${classFile} updated!`))
            });
          })

          prependFile(`${appDir}/MainApplication.java`, `package ${mainPackage};`, (err) => {
            if (err) {
              return this.log("There was a problem while prepending package to MainApplication.java: " + chalk.red(err))
            }
         
            // Success
            this.log(chalk.green(`MainApplication.java updated!`))
          });
        });
      })
    })

    // create spring resources directory + copy resource files + generate bootstrap.properties
    const resources_dir = `${mainDir}/resources`
    this.mkdirp(resources_dir, () => {
      
      // Copy spring resources
      fs.copy(SPRING_RESOURCES, resources_dir, (err) => {
        if(err) {
          return this.log("There was a problem while copying spring files: " + chalk.red(err))
        }

        this.log(chalk.green("Spring resources copied!"))
      })

      // Generate bootstrap.properties
      fs.writeFile(`${resources_dir}/bootstrap.properties`, this.bootstrapPropertiesContent(msName), (err) => {
        if(err) {
          return this.log("There was a problem while creating bootstrap.properties: " + chalk.red(err))
        }

        this.log(chalk.green("bootstrap.properties created!"))
      })
    })

    // Copy build files
    fs.copy(BUILD_FILES, ".", (err) => {
      if(err) {
        return this.log("There was a problem while copying build files: " + chalk.red(err))
      }

      // append artifact settings to build.gradle
      const artifactSettings = this.artifactSettings(msName, group, version)
      fs.appendFile(`./build.gradle`, artifactSettings, (err) => {
        if(err) { 
          return this.log(`There was a problem updating gradle settings file: ` + chalk.red(err.toString()))
        }
        this.log(chalk.bold(`build.gradle`) + chalk.green(` updated!`))
      });

      // append docker entry point settings 
      const entryPoint = `ENTRYPOINT ["java","-cp","app:app/lib/*","${mainPackage}.MainApplication"]`
      fs.appendFile(`./Dockerfile`, entryPoint, (err) => {
        if(err) { 
          return this.log(`There was a problem updating DockerFile: ` + chalk.red(err.toString()))
        }
        this.log(chalk.bold(`DockerFile`) + chalk.green(` updated!`))
      });

      this.log(chalk.green("Build resources copied!"))
    }) 
  }

  artifactSettings(msName: string, group: string, version: string) {
    return `
group = '${group}'
version = '${version}'
description = '${msName}'

bootJar {
  baseName = '${msName}'
  version =  '${version}'
}

task unpack(type: Copy) {
    dependsOn bootJar
    from(zipTree(tasks.bootJar.outputs.files.singleFile))
    into 'build/dependency'
}

docker {
    // This name is the same as GRADLE_IMAGE_NAME in CircleCi config.yml, if changed here change it there too!
    name 'build-output-image'
    copySpec.from(tasks.unpack.outputs).into('dependency_path')
    buildArgs(['DEPENDENCY_PATH': "dependency_path"])
}
`
  }

  bootstrapPropertiesContent(msName: string) {
    return `
########################################
# SPRING Config
# Don't change configs in this files! They match MSSK AWS generated infrastructure
# for customization, edit the specific environment configs
########################################
spring.application.name=${msName}
spring.cloud.consul.host=localhost
spring.cloud.consul.port=8500
spring.cloud.consul.config.enabled=false
spring.cloud.consul.discovery.healthCheckInterval=20s
` + 
'spring.cloud.consul.discovery.healthCheckPath=${server.servlet.context-path}/health'

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
