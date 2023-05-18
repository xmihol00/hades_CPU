import argparse
from function_table import FunctionTable
from variable_table import VariableTable
from scanner import Scanner
from parser import Parser

parser = argparse.ArgumentParser()
parser.add_argument("file_name", type=str, help="Name of a file to be compiled.")
args = parser.parse_args()

if "__main__" == __name__:
    with open(args.file_name, "r") as f:
        c_program = f.read()
    
    function_table = FunctionTable()
    variable_table = VariableTable()
    scanner = Scanner(program=c_program)
    parser = Parser(function_table=function_table, variable_table=variable_table)

    for expression in scanner.scan():
        parser.parse(*expression)
    
    print("Internal code representation:")
    print(function_table)

    print("Variable table:")
    print(variable_table)

