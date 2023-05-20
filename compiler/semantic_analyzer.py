from function_call_table import FunctionCallTable
from function_declaration_table import FunctionDeclarationTable
from variable_table import VariableTable

class SemanticAnalyzer():
    def __init__(self, function_declaration_table: FunctionDeclarationTable, function_call_table: FunctionCallTable,
                       variable_table: VariableTable) -> None:
        self.function_declaration_table = function_declaration_table
        self.function_call_table = function_call_table
        self.variable_table = variable_table
    
    def check_function_calls(self):
        for function_call in self.function_call_table.functions.values():
            if not self.function_declaration_table.exists(function_call.name, function_call.number_of_parameters):
                raise Exception(f"Function '{function_call.name}' with {function_call.number_of_parameters} parameter{'s' if function_call.number_of_parameters != 1 else ''} does not exist.")

    def analyze(self):
        self.check_function_calls()
        if not self.function_declaration_table.main_exists():
            raise Exception("Function 'main' must be declared and must not have any parameters.")
