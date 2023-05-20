from io import TextIOWrapper
import sys

class Writer():
    def __init__(self, in_memory: bool = False, output_file: TextIOWrapper|None = sys.stdout, indent: str = "   "):
        self.indent = indent
        self.output_file = output_file
        self.instruction_write_function = self._write_in_file_instruction
        self.label_write_function = self._write_in_file_instruction
        self.label_write_function = self._write_in_file_label
        if self.output_file == None or in_memory:
            self.memory = []
            self.instruction_write_function = self._write_in_memory_instruction
            self.label_write_function = self._write_in_memory_label
        

    def write_instruction(self, instruction: str, comment: str = ""):
        self.instruction_write_function(instruction, comment)

    def write_label(self, label: str):
        self.label_write_function(label)

    def retrieve_memory(self) -> list[str]:
        return self.memory
    
    def new_line(self):
        if self.output_file != None:
            print(file=self.output_file)
    
    def _write_in_memory_instruction(self, instruction: str, _):
        self.memory.append(instruction)

    def _write_in_file_instruction(self, instruction: str, comment: str = ""):
        padding = " " * ((30 - len(instruction)) * (len(comment) > 0))
        print(f"{self.indent}{instruction}{padding}{'# ' if comment else ''}{comment}", file=self.output_file)
    
    def _write_in_file_label(self, label: str):
        print(f"{label}:", file=self.output_file)
    
    def _write_in_memory_label(self, label: str):
        self.memory.append(f"{label}:")
    