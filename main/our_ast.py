import ast
import inspect
import tests.fib
import tests.test2
import os

from lib.fuzzingbook.ControlFlow import gen_cfg, to_graph
from graphviz import Source


def fib(n, ):
    l = [0, 1]
    for i in range(n - 2):
        l.append(l[-1] + l[-2])
    return l


ast_node = ast.parse(inspect.getsource(tests.test2))


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
        new_nodes = self.generic_stmt_visit(node)
        last_node = None
        if isinstance(new_nodes, list):
            # We have a list, which means that the last element is the Assign node
            last_node = new_nodes.pop()
        else:
            last_node = new_nodes

        changed_nodes = last_node
        if all([isinstance(node, ast.Name) for node in last_node.targets]):
            pass
        elif not isinstance(last_node.value, ast.Name) \
                and len(last_node.targets) == 1 \
                and isinstance(last_node.targets[0], ast.Attribute):
            print("has not name")
            new_name = self.unique_name()
            new_load = ast.copy_location(ast.Name(new_name, ast.Load), node)
            new_store = ast.copy_location(ast.Name(new_name, ast.Store), node)
            extra_assign = ast.copy_location(ast.Assign([new_store], last_node.value), node)
            new_assign = ast.copy_location(ast.Assign(last_node.targets, new_load), node)
            new_nodes.extend([extra_assign, new_assign])
            return new_nodes

        if isinstance(new_nodes, list):
            if isinstance(changed_nodes, list):
                new_nodes.extend(changed_nodes)
            else:
                new_nodes.append(changed_nodes)
            return new_nodes
        else:
            return changed_nodes

    def vist_Delete(self, node):
        return self.generic_stmt_visit(node)

    def visit_AugAssign(self, node):
        return self.generic_stmt_visit(node)

    def visit_AnnAssign(self, node):
        return self.generic_stmt_visit(node)

    def visit_For(self, node):
        new_body = self.if_exists(node.body, self.visit_list)
        new_orelse = self.if_exists(node.orelse, self.visit_list)
        new_target = self.visit(node.target)
        new_iter = self.visit(node.iter)
        return_list = self.new_stmts + [ast.copy_location(
            ast.For(new_target, new_iter, new_body, new_orelse), node)]
        self.new_stmts.clear()
        return return_list

    def visit_AsyncFor(self, node):
        new_body = self.if_exists(node.body, self.visit_list)
        new_orelse = self.if_exists(node.orelse, self.visit_list)
        new_target = self.visit(node.target)
        new_iter = self.visit(node.iter)
        return_list = self.new_stmts + [ast.copy_location(
            ast.AsyncFor(new_target, new_iter, new_body, new_orelse), node)]
        self.new_stmts.clear()
        return return_list

    def visit_While(self, node):
        new_body = self.if_exists(node.body, self.visit_list)
        new_orelse = self.if_exists(node.orelse, self.visit_list)
        new_test = self.visit(node.test)
        return_list = self.new_stmts + [ast.copy_location(
            ast.While(new_test, new_body, new_orelse), node)]
        self.new_stmts.clear()
        return return_list

    def visit_If(self, node):
        new_body = self.if_exists(node.body, self.visit_list)
        new_orelse = self.if_exists(node.orelse, self.visit_list)
        new_test = self.visit(node.test)
        return_list = self.new_stmts + [ast.copy_location(
            ast.If(new_test, new_body, new_orelse), node)]
        self.new_stmts.clear()
        return return_list

    def visit_With(self, node):
        new_body = self.if_exists(node.body, self.visit_list)
        new_with_items = self.if_exists(node.items, self.visit_list)
        return_list = self.new_stmts + [ast.copy_location(ast.With(new_with_items, new_body), node)]
        self.new_stmts.clear()
        return return_list

    def visit_AsyncWith(self, node):
        new_body = self.if_exists(node.body, self.visit_list)
        new_with_items = self.if_exists(node.items, self.visit_list)
        return_list = self.new_stmts + [ast.copy_location(ast.AsyncWith(new_with_items, new_body), node)]
        self.new_stmts.clear()
        return return_list

    def visit_Raise(self, node):
        return self.generic_stmt_visit(node)

    # Excepthandler might be a bit tricky
    def visit_Try(self, node):
        pre_nodes = []
        expt_handlers = []
        for expt_handler in node.handlers:
            new_body = self.if_exists(expt_handler.body, self.visit_list)
            new_type = self.if_exists(expt_handler.type, self.visit)
            pre_nodes += self.new_stmts
            self.new_stmts.clear()
            new_handler = ast.copy_location(ast.excepthandler(type=new_type, name=expt_handler.name, body=new_body),
                                            expt_handler)
            expt_handlers.append(new_handler)
        new_body = self.if_exists(node.body, self.visit_list)
        new_orelse = self.if_exists(node.orelse, self.visit_list)
        new_final_body = self.if_exists(node.finalbody, self.visit_list)
        new_try = ast.copy_location(ast.Try(new_body, expt_handlers, new_orelse, new_final_body), node)
        # return the new nodes before the try, since these should not be run inside the try where they could be skipped
        return pre_nodes + [new_try]

    def visit_Assert(self, node):
        return self.generic_stmt_visit(node)

    # Import and ImportFrom only contains non stmt and expr

    def visit_Expr(self, node):
        return self.generic_stmt_visit(node)

    def visit_Attribute(self, node):
        sub_node = self.visit(node.value)
        if isinstance(sub_node, ast.Name):
            return ast.copy_location(ast.Attribute(sub_node, node.attr, node.ctx), node)
        else:
            new_name = ast.copy_location(ast.Name(self.unique_name(), ast.Store), sub_node)
            self.new_stmts.append(ast.copy_location(ast.Assign([new_name], sub_node), sub_node))
            return ast.copy_location(ast.Attribute(new_name, node.attr, node.ctx), node)

    def visit_Call(self, node):
        new_nodes = self.generic_visit(node)
        for arg in node.args:
            if not (is_constant_value(arg)):
                new_name = self.unique_name()
                load_name = ast.copy_location(ast.Name(new_name, ast.Load), arg)
                store_name = ast.copy_location(ast.Name(new_name, ast.Store), arg)

    def generic_stmt_visit(self, node):
        new_node = self.generic_visit(node)
        if (len(self.new_stmts) > 0):
            return_list = self.new_stmts + [new_node]
            self.new_stmts.clear()
            return return_list
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

    ## Stmt

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

    def vist_ClassDef(self, node):
        new_body = self.if_exists(node.body, self.visit_list)
        new_bases = self.if_exists(node.bases, self.visit_list)
        new_keywords = self.if_exists(node.keywords, self.visit_list)
        new_decorator_list = self.if_exists(node.decorator_list, self.visit_list)
        return_list = self.new_stmts + [ast.copy_location(
            ast.ClassDef(node.name, new_bases, new_keywords, new_body, new_decorator_list), node)]
        self.new_stmts.clear()
        return return_list

    def visit_Return(self, node):
        if node.value:
            new_value = self.visit(node.value)
            new_node = ast.copy_location(ast.Return(new_value), node)
            if len(self.new_stmts) > 0:
                return_list = self.new_stmts + [new_node]
                self.new_stmts.clear()
                return return_list
            return new_node

        return node


def is_constant_value(node):
    isinstance(node, ast.Name) or isinstance(node, ast.Num) or isinstance(node, ast.Str) \
    or isinstance(ast.Bytes) or isinstance(node, ast.NameConstant) or isinstance(node, ast.Constant)

ast_node = RewriteName().visit(ast_node)

graph = to_graph(gen_cfg("", ast_node=ast_node))

# to_graph does not like Try and error names

Source(graph).save()
