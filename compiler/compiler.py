import argparse
import sys
from semantic_analyzer import SemanticAnalyzer
from function_call_table import FunctionCallTable
from function_declaration_table import FunctionDeclarationTable
from variable_table import VariableTable
from scanner import Scanner
from parser import Parser
from global_expressions import GlobalExpressions

parser = argparse.ArgumentParser()
parser.add_argument("file_name", type=str, help="Name of a file to be compiled.")
parser.add_argument("-d", "--debug", action="store_true", help="Print debug information (stack trace).")
args = parser.parse_args()

if "__main__" == __name__:
    with open(args.file_name, "r") as f:
        c_program = f.read()
    
    function_declaration_table = FunctionDeclarationTable()
    function_call_table = FunctionCallTable()
    variable_table = VariableTable()
    global_expressions = GlobalExpressions()
    scanner = Scanner(program=c_program)
    parser = Parser(function_declaration_table=function_declaration_table, function_call_table=function_call_table, 
                    variable_table=variable_table, global_expressions=global_expressions)
    semantic_analyzer = SemanticAnalyzer(function_declaration_table=function_declaration_table, function_call_table=function_call_table,
                                         variable_table=variable_table)

    try:
        for expression in scanner.scan():
            parser.parse(*expression)
        
        semantic_analyzer.analyze()
    except Exception as e:
        if args.debug:
            print("Currently defined function:", file=sys.stderr)
            print(parser.current_function, end="\n\n", file=sys.stderr)
            print("Current parser state:", file=sys.stderr)
            print(parser.state, end="\n\n", file=sys.stderr)
            print("Current expression parser state:", file=sys.stderr)
            print(parser.expression_parser.state, end="\n\n", file=sys.stderr)
            print("Current expression:", file=sys.stderr)
            print(parser.expression_parser.expression, end="\n\n", file=sys.stderr)

        if args.debug:
            raise e
        else:
            print("Error:", file=sys.stderr)
            print(e, file=sys.stderr)
            exit(1)
    
    print("Internal global code representation:")
    print(global_expressions)
    
    print("Internal function code representation:")
    print(function_declaration_table)

    print("\nVariable table:")
    print(variable_table)

    print("Function call table:")
    print(function_call_table)

