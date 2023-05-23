import argparse
import os
import sys
from target_assembly_generator import TargetAssemblyGenerator
from high_assembly_generator import HighAssemblyGenerator
from registers import RegisterFile
from semantic_analyzer import SemanticAnalyzer
from function_call_table import FunctionCallTable
from function_declaration_table import FunctionDeclarationTable
from variable_table import VariableTable
from scanner import Scanner
from parser import Parser
from global_expressions import GlobalExpressions
from writer import Writer

parser = argparse.ArgumentParser()
parser.add_argument("file_name", type=str, help="Name of a file to be compiled.")
parser.add_argument("-s", "--same", action="store_true", help="Use input file name for intermediate and output files.")
parser.add_argument("-i", "--intermediate", type=str, help="Name of a file to write compiled code to high level assembly.")
parser.add_argument("-o", "--output", type=str, help="Name of a file to write compiled code to HaDes assembly.")
parser.add_argument("-c", "--compile", action="store_true", help="Compile to binary.")
parser.add_argument("-d", "--debug", action="store_true", help="Print debug information to stderr.")
args = parser.parse_args()

if "__main__" == __name__:
    os.makedirs("build", exist_ok=True)
    with open(args.file_name, "r") as f:
        c_program = f.read()

    if args.same:
        if '/' in args.file_name:
            args.file_name = args.file_name[args.file_name.rfind('/') + 1:]
        args.same = args.file_name[:args.file_name.rfind('.')]
        args.intermediate = args.file_name[:args.file_name.rfind('.')] + ".asm"
        args.output = args.file_name[:args.file_name.rfind('.')] + ".has"
    
    if args.intermediate:
        args.intermediate = os.path.join("build", args.intermediate)
        high_assembly_file = open(args.intermediate, "w")
    else:
        high_assembly_file = None

    if args.output:
        args.output = os.path.join("build", args.output)
        target_assembly_file = open(args.output, "w")
    else:
        target_assembly_file = sys.stdout    
    
    function_declaration_table = FunctionDeclarationTable()
    function_call_table = FunctionCallTable()
    variable_table = VariableTable()
    global_expressions = GlobalExpressions()
    scanner = Scanner(program=c_program)
    parser = Parser(function_declaration_table=function_declaration_table, function_call_table=function_call_table, 
                    variable_table=variable_table, global_expressions=global_expressions)
    semantic_analyzer = SemanticAnalyzer(function_declaration_table=function_declaration_table, function_call_table=function_call_table,
                                         variable_table=variable_table)
    high_assembly_writer = Writer(in_file=args.intermediate, in_memory=True, output_file=high_assembly_file)
    register_file = RegisterFile(number_of_registers=7, writer=high_assembly_writer)
    high_assembly_generator = HighAssemblyGenerator(function_declaration_table=function_declaration_table, variable_table=variable_table, 
                                                    global_code=global_expressions, register_file=register_file, writer=high_assembly_writer)
    target_assembly_writer = Writer(in_file=True, in_memory=False, output_file=target_assembly_file)
    target_assembly_generator = TargetAssemblyGenerator(high_assembly_code=high_assembly_writer.retrieve_memory(), 
                                                        writer=target_assembly_writer)

    try:
        for expression in scanner.scan():
            parser.parse(*expression)
        
        semantic_analyzer.analyze()
        if args.debug:
            print("Internal global code representation:", file=sys.stderr)
            print(global_expressions, file=sys.stderr)
            print("Internal function code representation:", file=sys.stderr)
            print(function_declaration_table, file=sys.stderr)
            print("\nVariable table:", file=sys.stderr)
            print(variable_table, file=sys.stderr)
            print("Function call table:", file=sys.stderr)
            print(function_call_table, file=sys.stderr)

        variable_table.reset_scope_counter()
        high_assembly_generator.generate()
        target_assembly_generator.generate()

        if args.intermediate:
            high_assembly_file.close()
        if args.output:
            target_assembly_file.close()
        
        if args.compile and args.output:
            os.system(f"wine ../_bin/hoasm.exe -I ../_assembler/inc {args.output}")
            output_file_stripped = args.output[:args.output.rfind('.')]
            os.system(f"wine ../_bin/hlink.exe -L ../_assembler/inc -o {output_file_stripped}.hix {output_file_stripped}.ho")

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
        
