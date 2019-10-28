import {Command, flags} from '@oclif/command'
import cli from 'cli-ux'
const fs = require('fs-extra')
const chalk  = require('chalk')
const BASE_MODULE_RESOURCES = __dirname + '/../../resources/microservice-module'

export class InitMicroserviceModule extends Command {

  static description = 'init microservice aws infrastructure module'

  static examples = [
    `
    $ mssk ms-module:init my_microservice_name --baseAppPropertiesFile=path_to_base_app_mssk_properties_file

    OR
    
    $ mssk ms-module:init my_microservice_name --baseAppName=my_base_app_name --region=us-east-1 --profile=default
    `,
  ]

  static args = [{
    name: 'msName',
    required: true, 
    description: 'microservice name', // help description
  }]

  static flags = {
    help: flags.help({char: 'h'}),

    // flag with a value (-n, --name=VALUE)
    baseAppPropertiesFile: flags.string({char: 'f', description: 'base app mssk properties file'}),
    baseAppName: flags.string({char: 'a', description: 'base app name'}),
    region: flags.string({char: 'r', description: 'aws region'}),
    profile: flags.string({char: 'p', description: 'aws profile'}),
  }

  async run() {
    const {args, flags} = this.parse(InitMicroserviceModule)

    const msName = args.msName

    const baseAppPropertiesFile = flags.baseAppPropertiesFile
    let baseAppName = flags.baseAppName
    let region = flags.region || 'us-east-1'
    let profile = flags.profile || 'default'

    if(baseAppPropertiesFile) {
      this.log(`MSSK properties file for base app is provided.. other flags will be ignored`)  

      // read MSSK properties file
      let baseAppProperties: any;
      try {
        baseAppProperties = fs.readJsonSync(baseAppPropertiesFile)
      } catch (err) {
        return this.log("There was a problem while reading the provided mssk properties file: " + chalk.red(err))
      }

      baseAppName = baseAppProperties.appName
      region = baseAppProperties.region
      profile = baseAppProperties.profile
    } else if (!baseAppName){
      return this.log(chalk.red(`You must provide either a name or an MSSK properties file for the base app`))
    }

    const alreadyExists = fs.pathExistsSync(`${this.baseDir(msName)}/base_terraform_module`)
    if(alreadyExists) {
      this.log(chalk.red(`Base module already initiated in this directory!`))

      // yes/no confirmation
      const overwrite = await cli.confirm('Overwrite existing module? (yes/no)')
      if (!overwrite) {
        return;
      }
    }

    this.log(`Base module for "${msName}" will be created...`)  
    this.initModuleTemplate(msName, baseAppName!, region, profile);
  }

  baseDir(msName: string) {
    return '.'
  }

  
  // copy the terraform files into the current folder and create mssk propertoes file
  initModuleTemplate(msName: string, baseAppName: string, region: string, profile: string) {
    const baseDir = this.baseDir(msName)
    const baseModuleDir = `${baseDir}/base_terraform_module`

    const msProperties = {
      msName: msName,
      baseAppName: baseAppName,
      region: region,
      profile: profile
    }
    
    // create mssk properties file
    fs.writeJson(`${baseDir}/mssk-properties.json`, msProperties, (err) => {
       if(err) {
          return this.log("There was a problem while creating mssk properties file: " + chalk.red(err))
        }

        this.log(chalk.green("mssk properties file created!"))
    })

    // create base terraform module directory
    this.mkdirp(baseModuleDir, () => {
      fs.copy(BASE_MODULE_RESOURCES, baseModuleDir, (err) => {
          if(err) {
            return this.log("There was a problem while copying base module terraform files: " + chalk.red(err))
          }

          this.log(chalk.green("Base module terraform files copied!"))
        })
    })
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
