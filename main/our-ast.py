import ast
import inspect
import tests.fib
import os

from lib.fuzzingbook.ControlFlow import gen_cfg, to_graph
from graphviz import Source


def fib(n,):
    l = [0, 1]
    for i in range(n-2):
        l.append(l[-1]+l[-2])
    return l

f = open("../tests/fib.py", "r")
contents = f.read()

#ast_node = ast.parse(inspect.getsource(fib))
ast_node = ast.parse(contents)

class RewriteName(ast.NodeTransformer):
    def __init__(self) -> None:
        super().__init__()
        self.unique = 0
        self.new_stmts = []

    def unique_name(self):
        return "name{}".format(self.unique_number())BoolOp

    def unique_number(self):
        self.unique += 1
        return self.unique

    def visit_Assign(self, node):
        value_nodes = self.visit(node.value)
        if isinstance(value_nodes, [].__class__) and len(value_nodes) > 1:
            new_node = ast.Assign(node.targets, value_nodes.pop())
            value_nodes.append(ast.copy_location(new_node, node))
            return value_nodes
        else:
            new_node = ast.Assign(node.targets, value_nodes)
            return ast.copy_location(new_node, node)

    def visit_Attribute(self, node):
        sub_node = self.visit(node.value)
        if isinstance(sub_node, ast.Name):
            return ast.copy_location(ast.Attribute(sub_node, node.attr, node.ctx), node)
        else:
            new_name = ast.copy_location(ast.Name(self.unique_name(), ast.Store), sub_node)
            self.new_stmts.append(ast.copy_location(ast.Assign([new_name],sub_node),sub_node))
            return ast.copy_location(ast.Attribute(new_name,node.attr, node.ctx), node)



ast_node = RewriteName().visit(ast_node)

graph = to_graph(gen_cfg("", ast_node=ast_node))

Source(graph).save()