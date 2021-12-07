import { TypescriptCompiler } from '@poppinss/chokidar-ts'
import { iocTransformer } from '@adonisjs/ioc-transformer'
import { exit } from 'process'

//Use custom Typescript Compiler
const compiler = new TypescriptCompiler(
  __dirname,
  'tsconfig.json',
  require('typescript/lib/typescript')
)

//Use custom Typescript transformer to transform import statements to IoC container use calls - for AdonisJS IoC
//Convert from: __importDefault(require("@ioc:Adonis/Core/Env")) to __importDefault(global[Symbol.for('ioc.use')]("Adonis/Core/Env"))
compiler.use(() => {
        return iocTransformer(require('typescript/lib/typescript'), require('./.adonisrc.json'))
    }, 'after')

//Parse tsconfig.json
const { error, config } = compiler.configParser().parse()
if (error || !config) {
  console.log(error)
  exit;
}

if (config!.errors.length) {
  console.log(config!.errors)
  exit;
}

//For experiment AdonisJS: Replace default tsconfig outDir
//config!.options.outDir = '';

/* const buffer = fs.readFileSync("configfile.json");
const fileContent = buffer.toString();
const config = JSON.parse(fileContent); */

const { diagnostics, skipped } = compiler.builder(config!).build()

if (diagnostics.length) {
  console.log('Built with few errors')
  console.log(diagnostics)
  console.log(skipped)
} else {
  console.log('Built successfully')
}

/*
tsc builder.ts --target "ES2020" --lib "ES2020" --module "commonjs" --noUnusedLocals true --skipLibCheck true --noUnusedParameters false --removeComments true --declaration false --moduleResolution node --strictNullChecks true --allowSyntheticDefaultImports true --emitDecoratorMetadata true --experimentalDecorators true --esModuleInterop true --sourceMap true --allowUnreachableCode true --strictNullChecks false --noUnusedLocals false --rootDir "./" --baseUrl "./"
*/