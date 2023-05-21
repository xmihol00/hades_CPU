from enums import InternalAlphabet

class GlobalExpressions():
    def __init__(self) -> None:
        self.expressions = []
    
    def add(self, expression: list|InternalAlphabet):
        if isinstance(expression, list):
            self.expressions += expression
        else:
            self.expressions.append(expression)
    
    def __str__(self) -> str:
        return ' ' + ' '.join([str(expression) for expression in self.expressions])