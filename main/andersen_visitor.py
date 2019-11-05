import ast
import inspect
import tests.constructor_sound_first
import tests.test_simple_alloc
import tests.test_multiple_new_alloc
import tests.test_tripple_new_alloc
import tests.test_super
import tests.test_super_2
import tests.test_super_dynamic
import tests.test_super_3
import tests.constructorClassAsHeap
import tests.python_features.getitem
import tests.python_features.isinstance_example2
import astpretty
from our_ast import RewriteName
from util import if_exists

ast_node = ast.parse(inspect.getsource(tests.test_super_3))

f = open('output', 'w')
treeDumpFile = open('output_tree', 'w')
f.write("Reachable(\"root\").\n")


class AndersenAnalysis(ast.NodeVisitor):
    def __init__(self, unique_counter) -> None:
        super().__init__()
        self.current_meth = 'root'
        self.unique = unique_counter
        self.stmt_map = {}
        self.current_stmt = ""
        self.current_class = "root"
        self.current_class_heap = ""


    def unique_name(self, type):
        return "{}{}".format(type, self.unique_number())

    def unique_number(self):
        self.unique += 1
        return self.unique

    def visit_Delete(self, node):
        stmt_name = self.unique_name("stmt")
        self.stmt_map[stmt_name] = node
        self.current_stmt = stmt_name

        self.generic_visit(node)

    def visit_Assert(self, node):
        stmt_name = self.unique_name("stmt")
        self.stmt_map[stmt_name] = node
        self.current_stmt = stmt_name

        self.generic_visit(node)

    def visit_Expr(self, node):
        stmt_name = self.unique_name("stmt")
        self.stmt_map[stmt_name] = node
        self.current_stmt = stmt_name

        self.generic_visit(node)


    def visit_Assign(self, node):
        stmt_name = self.unique_name("stmt")
        self.stmt_map[stmt_name] = node
        self.current_stmt = stmt_name
        if isinstance(node.targets[0], ast.Name) and isinstance(node.value, ast.Name):
            f.write("Move(\"{}\",\"{}\"). \n".format(node.targets[0].id, node.value.id))
        if isinstance(node.targets[0], ast.Name) and isinstance(node.value, ast.Attribute):
            f.write("Load(\"{}\",\"{}\",\"{}\").\n".format(node.targets[0].id, node.value.value.id, node.value.attr))
        if isinstance(node.targets[0], ast.Attribute) and isinstance(node.value, ast.Name):
            f.write("Store(\"{}\",\"{}\",\"{}\").\n".format(node.targets[0].value.id, node.targets[0].attr, node.value.id))
        if isinstance(node.targets[0], ast.Name) and isinstance(node.value, ast.Call):
            f.write("PotentialAllocationSite(\"{}\",\"{}\",\"{}\",\"{}\").\n".format(
                self.current_stmt, node.targets[0].id, self.unique_name("H"), self.current_meth
            ))
            if isinstance(node.value.func, ast.Name):
                if node.value.func.id[0].isupper():
                    heap_name = self.unique_name("H")
                    #f.write("Alloc(\"{}\",\"{}\",\"{}\").\n".format(node.targets[0].id, heap_name, self.current_meth))
                    #f.write("HeapType(\"{}\",\"{}\").\n".format(heap_name, "Type_" + node.value.func.id))
            f.write("ActualReturn(\"{}\",\"{}\").\n".format(self.current_stmt, node.targets[0].id))
        self.generic_visit(node)

    def visit_Call(self, node):
        if isinstance(node.func, ast.Attribute):
            f.write("VCall(\"{}\",\"{}\",\"{}\",\"{}\").\n".format(node.func.value.id, node.func.attr, self.current_stmt, self.current_meth))
        if isinstance(node.func, ast.Name):
            f.write("SCall(\"{}\",\"{}\",\"{}\").\n".format(node.func.id, self.current_stmt, self.current_meth))
        for i, arg in enumerate(node.args):
            f.write("ActualArg(\"{}\",\"{}\",\"{}\").\n".format(self.current_stmt, i, arg.id))
        self.generic_visit(node)

    def visit_list(self, nodes):
        for node in nodes:
            self.visit(node)

    def visit_FunctionDef(self, node):
        stmt_name = self.unique_name("stmt")
        self.stmt_map[stmt_name] = node
        self.current_stmt = stmt_name
        heapName = self.unique_name("HM")
        if self.current_class != "root":
            tmpName = self.unique_name("name")
            f.write("Alloc(\"{}\",\"{}\",\"{}\"). \n".format(tmpName, heapName, self.current_meth))
            f.write("Store(\"{}\",\"{}\",\"{}\"). \n".format(self.current_class, node.name, tmpName))
            if node.name == "__new__":
                f.write("ClsVar(\"{}\",\"{}\").\n".format(node.args.args[0].arg, heapName))
            else:
                f.write("SelfVar(\"{}\",\"{}\").\n".format(node.args.args[0].arg, heapName))
            if node.args:
                for i, arg in enumerate(node.args.args):
                    if(i != 0):
                        f.write("FormalArg(\"{}\",\"{}\",\"{}\").\n".format(heapName, i -1, arg.arg))
            if node.name == "__init__":
                f.write("IsInitFor(\"{}\",\"{}\"). \n".format(self.current_class_heap, heapName))
            if node.name == "__new__":
                f.write("IsNewFor(\"{}\",\"{}\"). \n".format(self.current_class_heap, heapName))
        else:
            f.write("Alloc(\"{}\",\"{}\",\"{}\"). \n".format(node.name, heapName, self.current_meth))
            if node.args:
                for i, arg in enumerate(node.args.args):
                    f.write("FormalArg(\"{}\",\"{}\",\"{}\").\n".format(heapName, i, arg.arg))
        f.write("HeapIsFunction(\"{}\").\n".format(heapName))
        temp = self.current_meth
        self.visit(node.args)
        if_exists(node.decorator_list, self.visit_list)
        self.current_meth = heapName
        if_exists(node.body, self.visit_list)
        if_exists(node.returns, self.visit)
        self.current_meth = temp

    def visit_Return(self, node):
        f.write("FormalReturn(\"{}\",\"{}\").\n".format(self.current_meth, node.value.id))

    def visit_ClassDef(self, node):
        tmp = self.current_class
        self.current_class = node.name
        heapName = self.unique_name("HC")
        tmpHeap = self.current_class_heap
        self.current_class_heap = heapName
        f.write("Alloc(\"{}\",\"{}\",\"{}\").\n".format(node.name, heapName, self.current_meth))
        f.write("HeapIsClass(\"{}\",\"{}\").\n".format(heapName, self.unique_name("Class")))
        f.write("IsBaseFor(\"{}\",\"{}\").\n".format(heapName, node.bases[0].id))
        self.generic_visit(node)
        self.current_class_heap = tmpHeap
        self.current_class = tmp


rewriteVisitor = RewriteName()
normalizedAST = rewriteVisitor.visit(ast_node)
treeDumpFile.write(astpretty.pformat(normalizedAST, show_offsets=False))
AndersenAnalysis(rewriteVisitor.unique).visit(normalizedAST)
