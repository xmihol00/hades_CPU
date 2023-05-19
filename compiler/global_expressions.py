from enums import InnerAlphabet

class GlobalExpressions():
    def __init__(self) -> None:
        self.expressions = []
    
    def add(self, expression: list|InnerAlphabet):
        if isinstance(expression, InnerAlphabet):
            self.expressions.append(expression)
        else:
            self.expressions += expression
    
    def __str__(self) -> str:
        return ' ' + ' '.join([str(expression) for expression in self.expressions])