#!/usr/bin/env groovy

// There seems to ba a problem with quotes in the way Groovy strings are called
//tree = "/Users/casianorodriguezleon/LEyapp/examples/yaml/Calc.pm -t -i -c a=2 2>&1".execute().text;
tree = "/Users/casianorodriguezleon/LEyapp/examples/yaml/Calc.pm -t -i -f entrada 2>&1".execute().text;
println "Salida: $tree"

