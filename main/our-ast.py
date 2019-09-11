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

    def unique_name(self, name):
        return "name {}".format(self.unique_number)

    def unique_number(self):
        self.unique += 1
        return self.unique

    def visit_FunctionDef(self, node):
        node.name = 'bob'
        self.generic_visit(node)

        return node

    def visit_Assign(self, node):
        #sub_nodes = self.generic_visit(node)
        value_nodes = self.visit(node.value)
        #print(sub_nodes)
        #if isinstance(sub_nodes, ast.Assign):
        #    print("assign")
        if isinstance(value_nodes, [].__class__) and len(value_nodes) > 1:
            print("assign value did return list")
            new_node = ast.Assign(node.targets, value_nodes.pop(len(value_nodes - 1)))
            return value_nodes.append(ast.copy_location(new_node, node))
        else:
            print("assign value did not return list")
            new_node = ast.Assign(node.targets, value_nodes)
            return ast.copy_location(new_node, node)

    def visit_Attribute(self, node):
        sub_nodes = self.visit(node.value)
        if isinstance(sub_nodes, ast.Attribute):
            prev_name = ast.copy_location(ast.Name(self.unique_name("u"), sub_nodes.ctx), sub_nodes)
            prev_node = ast.Assign([prev_name], sub_nodes)
            new_attr = ast.Attribute(prev_name, node.attr, node.ctx)
            return [prev_node, new_attr]

        return node



ast_node = RewriteName().visit(ast_node)

graph = to_graph(gen_cfg("", ast_node=ast_node))

Source(graph).save()