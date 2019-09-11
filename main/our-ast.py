import ast
import inspect

from lib.fuzzingbook.ControlFlow import gen_cfg, to_graph
from graphviz import Source

from tests import test


def fib(n,):
    l = [0, 1]
    for i in range(n-2):
        l.append(l[-1]+l[-2])
    return l

ast_node = ast.parse(inspect.getsource(test))

class RewriteName(ast.NodeTransformer):

    def visit_Assign(self, node):
        prev = None
        for target in node.targets:
            if isinstance(target, ast.Attribute) and isinstance(node.value, ast.Attribute) and prev is None:
                newName = node.value.attr + "1"
                prev = ast.Assign([ast.Name(newName, ast.Store)], node.value)
        self.generic_visit(node)
        if prev is None:
            return node
        else:
            node.value = ast.Name(newName, ast.Load)
            return [prev, node]

ast_node = RewriteName().visit(ast_node)

graph = to_graph(gen_cfg("", ast_node=ast_node))

Source(graph).save()

(x.r).r

y = x
y.r
