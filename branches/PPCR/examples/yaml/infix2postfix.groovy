#!/usr/bin/env groovy

/* This example illustrates how to use 
   from Groovy the Perl parser
   generated by Eyapp 
*/

// require(url:'http://jyaml.sourceforge.net', jar:'jyaml-1.3.jar', version:'1.3')
import org.ho.yaml.Yaml
import java.lang.System

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

def buildast(String exp) {
  script = "./Calc.pm -y -i -c '$exp' 2>&1" 
  makeBashScript('buildast', script)
  process = './buildast'.execute()
  process.waitFor()
  err = process.exitValue()

  if (err) {
    println "There were errors for input '$exp'!"
    System.exit(1) 
  }
  tree = './buildast'.execute().text
  println "exitValue = $err\ntree = $tree"
  Yaml.load(tree)
}

def showtree(tree, input) {
  println "tree for input '$input'"
  println tree
  println "class: ${tree.getClass().name}"
}

compilegrammar();

tree = buildast("a = 2")
//--- !!perl/hash:ASSIGN
//children:
//  - !!perl/hash:VAR
//    attr: a
//    children: []
//    token: VAR
//  - !!perl/hash:NUM
//    attr: 2
//    children: []
//    token: NUM

assert(tree == [children:[[token:'VAR', children:[], attr:'a'], [token:'NUM', children:[], attr:2]]])

showtree(tree, "a = 2");

// Now let us try an erroneous input
tree = buildast("a = *2")
showtree(tree, "a = *2");

