#!/usr/bin/env groovy

// require(url:'http://jyaml.sourceforge.net', jar:'jyaml-1.3.jar', version:'1.3')
import org.ho.yaml.Yaml

def makeBashScript(String name, String bashscript) {
  bashscript = "#!/bin/bash\n"+bashscript

  new File(name).write(bashscript)

  "chmod a+x ./${name}".execute()
}

def compilegrammar() {
  script = "eyapp -b '' -B '' Calc.eyp"
  makeBashScript('compile', script)
  './compile'.execute().text
}

def buildast() {
  script = "./Calc.pm -y -i -c 'a = 2' 2>&1" 
  makeBashScript('buildast', script)
  './buildast'.execute().text
}

compilegrammar();

tree = buildast()
println tree

t = Yaml.load(tree)

println t
println "class: ${t.getClass().name}"


