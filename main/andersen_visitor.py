import ast
from pyDatalog import pyDatalog
import inspect
import tests.test2
from our_ast import RewriteName
from util import if_exists

ast_node = ast.parse(inspect.getsource(tests.test2))

pyDatalog.create_terms('X,Y,Z,Q, Alloc, Move, Load, Store, VCall, FormalArg, ActualArg, FormalReturn, ActualReturn,'
                       'ThisVar, HeapType, LookUp, VarType, InMethod, SubType')

class AndersenAnalysis(ast.NodeVisitor):
    def __init__(self) -> None:
        super().__init__()
        self.current_meth = 'root'
        self.unique = 0

    def unique_name(self, type):
        return "{}{}".format(type, self.unique_number())

    def unique_number(self):
        self.unique += 1
        return self.unique

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
                    + Alloc(node.targets[0].id, self.unique_name("H"), self.current_meth)
        self.generic_visit(node)

    def visit_Call(self, node):
        if isinstance(node.func, ast.Attribute):
            + VCall(node.func.value.id, node.func.attr, node.lineno, self.current_meth)
        if node.args:
            for i, arg in enumerate(node.args, start=0):
                + ActualArg(node.lineno, i, arg.id)
        self.generic_visit(node)

    def visit_list(self, nodes):
        for node in nodes:
            self.visit(node)

    def visit_FunctionDef(self, node):
        temp = self.current_meth
        self.visit(node.args)
        if_exists(node.decorator_list, self.visit_list)
        self.current_meth = node.name
        if_exists(node.body, self.visit_list)
        if_exists(node.returns, self.visit)
        self.current_meth = temp

AndersenAnalysis().visit(RewriteName().visit(ast_node))

print(ActualArg(Q,X,Y))