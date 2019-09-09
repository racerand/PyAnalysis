import ast
import inspect

from lib.fuzzingbook.ControlFlow import gen_cfg, to_graph
from graphviz import Source


def fib(n,):
    l = [0, 1]
    for i in range(n-2):
        l.append(l[-1]+l[-2])
    return l

ast_node = ast.parse(inspect.getsource(fib))

class RewriteName(ast.NodeTransformer):

    def visit_FunctionDef(self, node):
        node.name = 'bob'
        self.generic_visit(node)
        return node

ast_node = RewriteName().visit(ast_node)

graph = to_graph(gen_cfg("", ast_node=ast_node))

Source(graph).save()