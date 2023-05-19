from constructs import Variable

class VariableTable():
    def __init__(self):
        self.scopes = {}
        self.current_scope = None
        self.scope_ids = []
        self.current_scope_index = 0
    
    def increase_scope(self):
        if self.current_scope_index == len(self.scope_ids):
            self.scope_ids.append(0)
        else:
            self.scope_ids[self.current_scope_index] += 1
        self.current_scope_index += 1
        self.current_scope = {}
        self.scopes['_'.join(map(lambda x: str(x), self.scope_ids[:self.current_scope_index]))] = self.current_scope
    
    def decrease_scope(self):
        self.scopes['_'.join(map(lambda x: str(x), self.scope_ids[:self.current_scope_index]))] = self.current_scope
        self.current_scope_index -= 1
        self.current_scope = self.scopes['_'.join(map(lambda x: str(x), self.scope_ids[:self.current_scope_index]))]

    def add(self, variable: Variable):
        if variable.name in self.current_scope:
            raise Exception(f"Variable {variable.name} already exists.")
        self.current_scope[variable.name] = variable
    
    def find(self, name: str) -> Variable:
        for i in range(self.current_scope_index, 0, -1):
            scope_id = '_'.join(map(lambda x: str(x), self.scope_ids[:i]))
            if name in self.scopes[scope_id]:
                return self.scopes[scope_id][name]
            
        raise Exception(f"Variable {name} does not exist.")
    
    def exists(self, name: str) -> bool:
        for i in range(self.current_scope_index, 0, -1):
            scope_id = '_'.join(map(lambda x: str(x), self.scope_ids[:i]))
            if name in self.scopes[scope_id]:
                return True
        return False

    def __str__(self) -> str:
        summary_string = ""
        indent = ""
        for scope_id, scope in self.scopes.items():
            indent = ' ' * (scope_id.count('_') * 2)
            summary_string += f"{indent}{scope_id}:\n"
            for variable in scope.values():
                summary_string += f"{indent}{variable}\n"
        return summary_string
    