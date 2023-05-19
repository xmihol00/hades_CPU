import argparse
from function_call_table import FunctionCallTable
from function_declaration_table import FunctionDeclarationTable
from variable_table import VariableTable
from scanner import Scanner
from parser import Parser

parser = argparse.ArgumentParser()
parser.add_argument("file_name", type=str, help="Name of a file to be compiled.")
args = parser.parse_args()

if "__main__" == __name__:
    with open(args.file_name, "r") as f:
        c_program = f.read()
    
    function_declaration_table = FunctionDeclarationTable()
    function_call_table = FunctionCallTable()
    variable_table = VariableTable()
    scanner = Scanner(program=c_program)
    parser = Parser(function_declaration_table=function_declaration_table, function_call_table=function_call_table, variable_table=variable_table)

    for expression in scanner.scan():
        parser.parse(*expression)
    
    print("Internal code representation:")
    print(function_declaration_table)

    print("\nVariable table:")
    print(variable_table)

    print("Function call table:")
    print(function_call_table)
