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
        self.scopes['_'.join(str(self.scope_ids[:self.current_scope_index]))] = self.current_scope
    
    def decrease_scope(self):
        pass

    def add(self, variable: Variable):
        if variable.name in self.current_scope:
            raise Exception(f"Variable {variable.name} already exists.")
        self.current_scope[variable.name] = variable
    
    def find(self, name: str) -> Variable:
        for i in range(self.current_scope_index, -1, -1):
            scope_id = '_'.join(self.scope_ids[:i])
            if name in self.scopes[scope_id]:
                return self.scopes[scope_id][name]
            
        raise Exception(f"Variable {name} does not exist.")
    