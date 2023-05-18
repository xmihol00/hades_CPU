from constructs import FunctionCall

class FunctionCallTable():
    def __init__(self):
        self.functions = {}
    
    def add(self, function: FunctionCall):
        id = f"{function.name}_{function.number_of_parameters}"
        self.functions[id] = function
            
    def __str__(self) -> str:
        return '\n'.join([ f"{function.name}({function.number_of_parameters})" for function in self.functions.values()])
