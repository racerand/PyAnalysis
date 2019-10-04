import ast
import inspect

import astor

import tests.fib
import tests.fldPointsToClassAsHeap
import tests.testScopedNames
import os

from lib.fuzzingbook.ControlFlow import gen_cfg, to_graph
from graphviz import Source


def fib(n, ):
    l = [0, 1]
    for i in range(n - 2):
        l.append(l[-1] + l[-2])
    return l


ast_node = ast.parse(inspect.getsource(tests.testScopedNames))


class RewriteName(ast.NodeTransformer):
    def __init__(self) -> None:
        super().__init__()
        self.unique = 0
        self.new_stmts = []
        self.namespace_list = ["root"]
        self.namespace_map = {"root": {}}
        self.current_scope_is_class = False

    def unique_scoped_name(self, name):
        new_name = self.scoped_name(name)
        if not self.current_scope_is_class:
            new_name += self.unique_number().__str__()
        return new_name

    def scoped_name(self, name):
        if self.current_scope_is_class:
            return name
        else:
            return "{}{}".format("".join(self.namespace_list), name)

    def new_unique_scoped_name(self):
        return self.scoped_name("new_var{}".format(self.unique_number()))

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
            new_store, new_load = self.generate_unique_Name(node)
            extra_assign = ast.copy_location(ast.Assign([new_store], last_node.value), node)
            new_assign = ast.copy_location(ast.Assign(last_node.targets, new_load), node)
            changed_nodes = [extra_assign, new_assign]

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
            sub_node.id = self.lookup_name(sub_node.id)
            return ast.copy_location(ast.Attribute(sub_node, node.attr, node.ctx), node)
        else:
            new_store, new_load = self.generate_unique_Name(sub_node)
            self.new_stmts.append(ast.copy_location(ast.Assign([new_store], sub_node), sub_node))
            return ast.copy_location(ast.Attribute(new_load, node.attr, node.ctx), node)

    def visit_Call(self, node):
        new_node = self.generic_visit(node)
        """
        formal_name = None
        actual_name = None
        name_to_change = None
        if isinstance(new_node.func, ast.Name):
            name_to_change = new_node.func
            formal_name = new_node.func.id
            actual_name = self.lookup_name(formal_name)
        elif isinstance(new_node.func, ast.Attribute) and isinstance(new_node.func.value, ast.Name):
            name_to_change = new_node.func.value
            formal_name = new_node.func.value.id
            actual_name = self.lookup_name(formal_name)
        else:
            print("Not supported call func " + node.func.__class__.__name__)

        if actual_name is None and formal_name is not None:
            actual_name = formal_name
            if formal_name != "super":
                print("Lookup of: " + formal_name + " unknown in environment: " + "".join(self.namespace_list))

        if name_to_change is not None:
            name_to_change.id = actual_name
        """
        if new_node.args is None:
            return new_node

        new_args = []
        for arg in new_node.args:
            if not (isinstance(arg, ast.Name)):
                store_name, load_name = self.generate_unique_Name(arg)
                new_assign = ast.copy_location(ast.Assign([store_name], arg), arg)
                self.new_stmts.append(new_assign)
                new_args.append(load_name)
            else:
                new_args.append(arg)
        return ast.copy_location(ast.Call(new_node.func, new_args, new_node.keywords), new_node)

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
        if self.current_scope_is_class:
            unique_func_name = node.name
        else:
            unique_func_name = self.unique_scoped_name(node.name)
        self.namespace_map[self.namespace_list[-1]][node.name] = unique_func_name
        self.namespace_list.append(node.name)
        self.namespace_map[node.name] = {}

        tmp_scope = self.current_scope_is_class
        self.current_scope_is_class = False

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

        self.namespace_list.pop()
        self.current_scope_is_class = tmp_scope

        return return_list

    def visit_AsyncFunctionDef(self, node):
        self.visit_FunctionDef(node)

    def visit_ClassDef(self, node):
        unique_class_name = self.unique_scoped_name(node.name)
        self.namespace_map[self.namespace_list[-1]][node.name] = unique_class_name
        self.namespace_list.append(node.name)
        self.namespace_map[node.name] = {}
        tmp_scope = self.current_scope_is_class
        self.current_scope_is_class = True

        new_body = self.if_exists(node.body, self.visit_list)
        new_bases = self.if_exists(node.bases, self.visit_list)
        new_keywords = self.if_exists(node.keywords, self.visit_list)
        new_decorator_list = self.if_exists(node.decorator_list, self.visit_list)
        return_list = self.new_stmts + [ast.copy_location(
            ast.ClassDef(unique_class_name, new_bases, new_keywords, new_body, new_decorator_list), node)]
        self.new_stmts.clear()

        self.namespace_list.pop()
        del self.namespace_map[node.name]

        self.current_scope_is_class = tmp_scope
        return return_list

    def visit_Return(self, node):
        new_value = self.if_exists(node.value, self.visit)
        return_list = []
        return_list.extend(self.new_stmts)
        self.new_stmts.clear()

        if not isinstance(new_value, ast.Name):

            actual_value = new_value

            if not new_value:
                actual_value = ast.copy_location(ast.NameConstant(None), node)

            store_name, load_name = self.generate_unique_Name(actual_value)

            new_assign = ast.copy_location(ast.Assign([store_name], actual_value), actual_value)

            node.value = load_name

            return_list.append(new_assign)
        else:
            node.value = new_value

        return_list.append(node)

        return return_list

    def visit_Name(self, node):
        new_name = self.lookup_name(node.id)
        if isinstance(node.ctx, ast.Store) and new_name is None:
            new_name = self.unique_scoped_name(node.id)
            this_scope = self.namespace_list[-1]
            self.namespace_map[this_scope][node.id] = new_name

        if new_name is not None:
            node.id = new_name
        else:
            print("We're trying to load " + node.id + ", which is not in the environment "
                  + "".join(self.namespace_list))
        return node

    def lookup_name(self, formal_name):
        return_name = None
        i = len(self.namespace_list) - 1
        while return_name is None and 0 <= i:
            scope = self.namespace_list[i]
            if formal_name in self.namespace_map[scope]:
                return_name = self.namespace_map[scope][formal_name]
            i -= 1
        return return_name

    def generate_unique_Name(self, location_name):
        new_name = self.new_unique_scoped_name()
        this_scope = self.namespace_list[-1]
        self.namespace_map[this_scope][new_name] = new_name
        new_load = ast.copy_location(ast.Name(new_name, ast.Load), location_name)
        new_store = ast.copy_location(ast.Name(new_name, ast.Store), location_name)
        return new_store, new_load

def is_constant_value(node):
    return isinstance(node, ast.Name) or isinstance(node, ast.Num) or isinstance(node, ast.Str) \
           or isinstance(node, ast.Bytes) or isinstance(node, ast.NameConstant) or isinstance(node, ast.Constant)


rn = RewriteName()
ast_node = rn.visit(ast_node)

graph = to_graph(gen_cfg("", ast_node=ast_node))

# to_graph does not like Try and error names

Source(graph).save()
