#!/usr/bin/env groovy

tree = '/Users/casianorodriguezleon/LEyapp/examples/yaml/Calc.pm -t -c \'a=2\''.execute().text;
println "Salida: $tree"

