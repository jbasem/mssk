import {Command, flags} from '@oclif/command'
import cli from 'cli-ux'
const fs = require('fs-extra')
const chalk  = require('chalk')
const BASE_MODULE_RESOURCES = __dirname + '/../../resources/base-app-module'

export class InitBaseAppModule extends Command {

  static description = 'init base app aws infrastructure module'

  static examples = [
    `$ mssk base-module:init my_base_app_name --region=us-east-1 --profile=default`,
  ]

  static args = [{
    name: 'appName',
    required: true, 
    description: 'base app name', // help description
  }]

  static flags = {
    help: flags.help({char: 'h'}),

    // flag with a value (-n, --name=VALUE)
    region: flags.string({char: 'r', description: 'aws region'}),
    profile: flags.string({char: 'p', description: 'aws profile'}),
  }

  async run() {
    const {args, flags} = this.parse(InitBaseAppModule)

    const appName = args.appName
    const region = flags.region || 'us-east-1'
    const profile = flags.profile || 'default'

    const alreadyExists = fs.pathExistsSync(`${this.baseDir(appName)}/base_terraform_module`)  
    if(alreadyExists) {
      this.log(chalk.red(`Base module already initiated in this directory!`))

      // yes/no confirmation
      const overwrite = await cli.confirm('Overwrite existing module? (yes/no)')
      if (!overwrite) {
        return;
      }
    }

    this.log(`Base module for "${appName}" will be created...`)  
    this.initBaseProjetModuleTemplate(appName, region, profile);
  }

  baseDir(appName: string) {
    return '.'
  }

  
  // copy the terraform files into the current folder and create mssk propertoes file
  initBaseProjetModuleTemplate(appName: string, region: string, profile: string) {
    const baseDir = this.baseDir(appName)
    const baseModuleDir = `${baseDir}/base_terraform_module`

    const baseAppProperties = {
      appName: appName,
      region: region,
      profile: profile
    }
    
    // create mssk properties file
    fs.writeJson(`${baseDir}/mssk-properties.json`, baseAppProperties, (err) => {
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
