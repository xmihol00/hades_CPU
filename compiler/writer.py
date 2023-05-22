from io import TextIOWrapper
import sys

class Writer():
    def __init__(self, in_file: bool = True, in_memory: bool = False, output_file: TextIOWrapper|None = sys.stdout, indent: str = "   "):
        self.indent = indent
        self.output_file = output_file
        self.additional_indent = ""
        self.memory = []

        if self.output_file == None and in_file:
            raise ValueError("Cannot write to file if no file is provided.")
        elif in_file and in_memory:
            self.instruction_write_function = lambda instruction, comment="": (self._write_in_file_instruction(instruction, comment), self._write_in_memory_instruction(instruction, comment))
            self.label_write_function = lambda label, comment="": (self._write_in_file_label(label, comment), self._write_in_memory_label(label, comment))
            self.raw_write_function = lambda text, comment="": (self._write_in_file_raw(text, comment), self._write_in_memory_raw(text, comment))
            self.comment_write_function = lambda comment: (self._write_in_file_comment(comment), self._write_in_memory_comment(comment))
        elif in_memory:
            self.instruction_write_function = self._write_in_memory_instruction
            self.label_write_function = self._write_in_memory_label
            self.raw_write_function = self._write_in_memory_raw
            self.comment_write_function = self._write_in_memory_comment
        elif in_file:
            self.instruction_write_function = self._write_in_file_instruction
            self.label_write_function = self._write_in_file_label
            self.raw_write_function = self._write_in_file_raw
            self.comment_write_function = self._write_in_file_comment
        else:
            print("Warning: No output will be generated.", file=sys.stderr)
            self.instruction_write_function = lambda instruction, comment="": None
            self.label_write_function = lambda label, comment="": None
            self.raw_write_function = lambda text, comment="": None
            self.comment_write_function = lambda comment: None
    
    def increase_indent(self):
        self.additional_indent += self.indent
    
    def decrease_indent(self):
        self.additional_indent = self.additional_indent[:-len(self.indent)]
    
    def comment(self, comment: str):
        self.comment_write_function(comment)
    
    def instruction(self, instruction: str, comment: str = ""):
        self.instruction_write_function(instruction, comment)

    def label(self, label: str, comment: str = ""):
        self.label_write_function(label, comment)
    
    def new_line(self):
        if self.output_file != None:
            print(file=self.output_file)
    
    def raw(self, text: str, comment: str = ""):
        self.raw_write_function(text, comment)

    def retrieve_memory(self) -> list[str]:
        return self.memory
    
    def clear_memory(self):
        self.memory = []
    
    def _write_in_memory_instruction(self, instruction: str, comment: str):
        self.memory.append(f"{instruction} {'; ' + comment if comment else ''}")

    def _write_in_file_instruction(self, instruction: str, comment: str):
        if not isinstance(comment, str):
            comment = ""
        padding = " " * ((40 - len(instruction + self.indent + self.additional_indent)) * (len(comment) > 0))
        print(f"{self.additional_indent}{self.indent}{instruction}{padding}{'; ' + comment if comment else ''}", file=self.output_file)
    
    def _write_in_memory_label(self, label: str, comment: str):
        self.memory.append(f"{label}: {'; ' + comment if comment else ''}")
    
    def _write_in_file_label(self, label: str, comment: str):
        if not isinstance(comment, str):
            comment = ""
        padding = " " * ((40 - len(label + self.additional_indent) - 1) * (len(comment) > 0))
        print(f"{self.additional_indent}{label}:{padding}{'; ' + comment if comment else ''}", file=self.output_file)
    
    def _write_in_memory_raw(self, text: str, comment: str):
        self.memory.append(f"{text} {'; ' + comment if comment else ''}")
    
    def _write_in_file_raw(self, text: str, comment: str):
        if not isinstance(comment, str):
            comment = ""
        padding = " " * ((40 - len(text)) * (len(comment) > 0))
        print(f"{text}{padding}{'; ' + comment if comment else ''}", file=self.output_file)
    
    def _write_in_memory_comment(self, comment: str):
        if isinstance(comment, str) and len(comment) > 0:
            self.memory.append(f"; {comment}")
    
    def _write_in_file_comment(self, comment: str):
        if isinstance(comment, str) and len(comment) > 0:
            print(f"; {comment}", file=self.output_file)
    