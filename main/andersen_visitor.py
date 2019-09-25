import ast
from pyDatalog import pyDatalog
import inspect
import tests.test2

ast_node = ast.parse(inspect.getsource(tests.test2))

pyDatalog.create_terms('X,Y,Z, Alloc, Move, Load, Store, VCall, FormalArg, ActualArg, FormalReturn, ActualReturn,'
                       'ThisVar, HeapType, LookUp, VarType, InMethod, SubType')

class AndersenAnalysis(ast.NodeVisitor):
    def __init__(self) -> None:
        super().__init__()
        self.current_meth = 'root'

    def visit_Assign(self, node):
        if isinstance(node.targets[0], ast.Name) and isinstance(node.value, ast.Name):
            + Move(node.targets[0].id, node.value.id)
        if isinstance(node.targets[0], ast.Name) and isinstance(node.value, ast.Attribute):
            + Load(node.targets[0].id, node.value.value.id, node.value.attr)
        if isinstance(node.targets[0], ast.Attribute) and isinstance(node.value, ast.Name):
            + Store(node.targets[0].value.id, node.targets[0].attr, node.value.id)
        if isinstance(node.targets[0], ast.Name) and isinstance(node.value, ast.Call):
            if isinstance(node.value.func, ast.Name):
                if node.value.func.id[0].isupper():
                    + Alloc()
        self.generic_visit(node)


AndersenAnalysis().visit(ast_node)