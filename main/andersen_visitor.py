import ast
from pyDatalog import pyDatalog
import inspect
import tests.test2
from our_ast import RewriteName
from util import if_exists

ast_node = ast.parse(inspect.getsource(tests.test2))

pyDatalog.create_terms('VAR,HEAP,METH, TO, FROM, BASE, BASEH, FLD, Alloc, Move, Load, Store, VCall, FormalArg,'
                       ' TOMETH, INVO, BASE, SIG, INMETH, HEAPT, ActualArg, FormalReturn, ActualReturn,'
                       'ThisVar, HeapType, LookUp, VarType, InMethod, SubType, VarPointsTo, CallGraph, FldPointsTo, '
                       'InterProcAssign, Reachable')

class AndersenAnalysis(ast.NodeVisitor):
    def __init__(self) -> None:
        super().__init__()
        self.current_meth = 'root'
        self.unique = 0
        self.stmt_map = {}
        self.current_stmt = ""
        self.current_class = ""

    def unique_name(self, type):
        return "{}{}".format(type, self.unique_number())

    def unique_number(self):
        self.unique += 1
        return self.unique

    def visit_FunctionDef(self, node):
        if_exists(node.args, self.visit_list)
        if_exists(node.decorator_list, self.visit_list)

        stmt_name = self.unique_name("stmt")
        self.stmt_map[stmt_name] = node

        if_exists(node.body, self.visit_list)
        if_exists(node.returns, self.visit)

    def visit_Delete(self, node):
        stmt_name = self.unique_name("stmt")
        self.stmt_map[stmt_name] = node

        self.generic_visit(node)

    def visit_Assert(self, node):
        stmt_name = self.unique_name("stmt")
        self.stmt_map[stmt_name] = node

        self.generic_visit(node)

    def visit_Expr(self, node):
        stmt_name = self.unique_name("stmt")
        self.stmt_map[stmt_name] = node

        self.generic_visit(node)


    def visit_Assign(self, node):
        stmt_name = self.unique_name("stmt")
        self.stmt_map[stmt_name] = node
        if isinstance(node.targets[0], ast.Name) and isinstance(node.value, ast.Name):
            + Move(node.targets[0].id, node.value.id)
        if isinstance(node.targets[0], ast.Name) and isinstance(node.value, ast.Attribute):
            + Load(node.targets[0].id, node.value.value.id, node.value.attr)
        if isinstance(node.targets[0], ast.Attribute) and isinstance(node.value, ast.Name):
            + Store(node.targets[0].value.id, node.targets[0].attr, node.value.id)
        if isinstance(node.targets[0], ast.Name) and isinstance(node.value, ast.Call):
            if isinstance(node.value.func, ast.Name):
                if node.value.args:
                    for i, arg in enumerate(node.value.args, start=0):
                        + ActualArg(self.current_stmt, i, arg.id)
                if node.value.func.id[0].isupper():
                    heap_name = self.unique_name("H")
                    + Alloc(node.targets[0].id, heap_name, self.current_meth)
                    + HeapType(heap_name, "Type_" + node.value.func.id)
            + ActualArg(self.current_stmt, node.targets[0].id)
            + ActualReturn(self.current_stmt, node.targets[0].id)
        self.generic_visit(node)

    def visit_Call(self, node):
        if isinstance(node.func, ast.Attribute):
            + VCall(node.func.value.id, node.func.attr, self.current_stmt, self.current_meth)
        self.generic_visit(node)

    def visit_list(self, nodes):
        for node in nodes:
            self.visit(node)

    def visit_FunctionDef(self, node):
        method_name = self.unique_name("M")
        + LookUp("Type_" + self.current_class, node.name, method_name)
        if node.args:
            for i, arg in enumerate(node.args.args):
                + FormalArg(method_name, i, arg.arg)
        temp = self.current_meth
        self.visit(node.args)
        if_exists(node.decorator_list, self.visit_list)
        self.current_meth = method_name
        if_exists(node.body, self.visit_list)
        if_exists(node.returns, self.visit)
        self.current_meth = temp

    def visit_Return(self, node):
        + FormalReturn(self.current_meth, node.value.id)

    def visit_ClassDef(self, node):
        tmp = self.current_class
        self.current_class = node.name
        self.generic_visit(node)
        self.current_class = tmp

+ Reachable("root")

VarPointsTo(VAR, HEAP) <= Reachable(METH) & Alloc(VAR, HEAP, METH)
VarPointsTo(TO, HEAP) <= Move(TO, FROM) & VarPointsTo(FROM, HEAP)
FldPointsTo(BASEH, FLD, HEAP) <= Store(BASE, FLD, FROM) & VarPointsTo(FROM, HEAP) & VarPointsTo(BASE, BASEH)
VarPointsTo(TO, HEAP) <= Load(TO, BASE, FLD) & VarPointsTo(BASE, BASEH) & FldPointsTo(BASEH, FLD, HEAP)
Reachable(TOMETH) <= VCall(BASE, SIG, INVO, INMETH) & Reachable(INMETH) & VarPointsTo(BASE, HEAP) & HeapType(HEAP, HEAPT) & LookUp(HEAPT, SIG, TOMETH)
CallGraph(INVO, TOMETH) <= VCall(BASE, SIG, INVO, INMETH) & Reachable(INMETH) & VarPointsTo(BASE, HEAP) & HeapType(HEAP, HEAPT) & LookUp(HEAPT, SIG, TOMETH)
InterProcAssign(TO, FROM) <= CallGraph(INVO, METH) & FormalReturn(METH, FROM) & ActualReturn(INVO, TO)

AndersenAnalysis().visit(RewriteName().visit(ast_node))
print(VarPointsTo(VAR,HEAP))
print(ActualReturn(INVO, TO))