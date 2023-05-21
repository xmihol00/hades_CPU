from io import TextIOWrapper
import sys

class Writer():
    def __init__(self, in_memory: bool = False, output_file: TextIOWrapper|None = sys.stdout, indent: str = "   "):
        self.indent = indent
        self.output_file = output_file
        self.additional_indent = ""
        self.instruction_write_function = self._write_in_file_instruction
        self.label_write_function = self._write_in_file_label
        self.raw_write_function = self._write_in_file_raw
        if self.output_file == None or in_memory:
            self.memory = []
            self.instruction_write_function = self._write_in_memory_instruction
            self.label_write_function = self._write_in_memory_label
            self.raw_write_function = self._write_in_memory_raw
    
    def increase_indent(self):
        self.additional_indent += self.indent
    
    def decrease_indent(self):
        self.additional_indent = self.additional_indent[:-len(self.indent)]
    
    def comment(self, comment: str):
        if self.output_file != None:
            print(f"; {comment}", file=self.output_file)

    def instruction(self, instruction: str, comment: str = ""):
        self.instruction_write_function(instruction, comment)

    def label(self, label: str, comment: str = ""):
        self.label_write_function(label, comment)

    def retrieve_memory(self) -> list[str]:
        return self.memory
    
    def new_line(self):
        if self.output_file != None:
            print(file=self.output_file)
    
    def raw(self, text: str, comment: str = ""):
        self.raw_write_function(text, comment)
    
    def _write_in_memory_instruction(self, instruction: str, _):
        self.memory.append(instruction)

    def _write_in_file_instruction(self, instruction: str, comment: str):
        padding = " " * ((40 - len(instruction + self.indent + self.additional_indent)) * (len(comment) > 0))
        print(f"{self.additional_indent}{self.indent}{instruction}{padding}{'; ' if comment else ''}{comment}", file=self.output_file)
    
    def _write_in_file_label(self, label: str, comment: str):
        padding = " " * ((40 - len(label + self.additional_indent) - 1) * (len(comment) > 0))
        print(f"{self.additional_indent}{label}:{padding}{'; ' if comment else ''}{comment}", file=self.output_file)
    
    def _write_in_memory_label(self, label: str, _):
        self.memory.append(f"{label}:")
    
    def _write_in_memory_raw(self, text: str, _):
        self.memory.append(text)
    
    def _write_in_file_raw(self, text: str, comment: str):
        padding = " " * ((40 - len(text)) * (len(comment) > 0))
        print(f"{text}{padding}{'; ' if comment else ''}{comment}", file=self.output_file)
    