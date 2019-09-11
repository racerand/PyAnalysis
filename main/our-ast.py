import ast
import inspect
import tests.fib
import os

from lib.fuzzingbook.ControlFlow import gen_cfg, to_graph
from graphviz import Source


def fib(n, ):
    l = [0, 1]
    for i in range(n - 2):
        l.append(l[-1] + l[-2])
    return l


f = open("../tests/fib.py", "r")
contents = f.read()

# ast_node = ast.parse(inspect.getsource(fib))
ast_node = ast.parse(contents)


class RewriteName(ast.NodeTransformer):
    def __init__(self) -> None:
        super().__init__()
        self.unique = 0
        self.new_stmts = []

    def unique_name(self):
        return "name{}".format(self.unique_number())

    def unique_number(self):
        self.unique += 1
        return self.unique

    def visit_Assign(self, node):
        new_node = self.generic_visit(node)
        if (len(self.new_stmts) > 0):
            return_list = self.new_stmts + [new_node]
            self.new_stmts.clear()
            return return_list
        else:
            return new_node

    def visit_Attribute(self, node):
        sub_node = self.visit(node.value)
        if isinstance(sub_node, ast.Name):
            return ast.copy_location(ast.Attribute(sub_node, node.attr, node.ctx), node)
        else:
            new_name = ast.copy_location(ast.Name(self.unique_name(), ast.Store), sub_node)
            self.new_stmts.append(ast.copy_location(ast.Assign([new_name], sub_node), sub_node))
            return ast.copy_location(ast.Attribute(new_name, node.attr, node.ctx), node)

    def generic_stmt_visit(self, node, func):
        new_node = self.generic_visit(node)
        if (len(self.new_stmts) > 0):
            return func(self, node)
        else:
            return new_node

    def visit_list(self, old_value):
        new_values = []
        for value in old_value:
            if isinstance(value, ast.AST):
                value = self.visit(value)
                if value is None:
                    continue
                elif not isinstance(value, ast.AST):
                    new_values.extend(value)
                    continue
            new_values.append(value)
        return new_values

    def if_exists(self, node, func):
        if node:
            return func(node)

    def visit_FunctionDef(self, node):
        new_body = self.if_exists(node.body, self.visit_list)
        new_return = self.if_exists(node.returns, self.visit)
        if new_body:
            new_body.extend(self.new_stmts)
        else:
            new_body = self.new_stmts
        self.new_stmts.clear()
        new_args = self.visit(node.args)
        new_decorator = self.if_exists(node.decorator_list, self.visit_list)
        return_list = self.new_stmts + [ast.copy_location(
            ast.FunctionDef(node.name, new_args, new_body, new_decorator, new_return), node)]
        self.new_stmts.clear()
        return return_list

    def visit_AsyncFunctionDef(self, node):
        self.visit_FunctionDef(node)

    def vist_ClassDef(self,node):



ast_node = RewriteName().visit(ast_node)

graph = to_graph(gen_cfg("", ast_node=ast_node))

Source(graph).save()
