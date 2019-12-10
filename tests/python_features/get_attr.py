""""
Whenever an attribute is accessed but not defined for an instance object, the getattr method is called. The default
method is empty, but can be overriden with some default behaviour. In our analysis we need to consider the case where
we have a load relation and the fld doesnt exists on the baseheap, but the base heap is child of a class heap and the
class heap has a fld with the name "__getattr__" and the fld is a function. In this case we can to call that function
with the parameter self, and if we add dataflow, the string of attempted load fld. For this to work we need to maintain
invocation sites on load relations.
"""
class Pair(object):
    def __getattr__(self, item):
        if item == "fst":
            return 1
        elif item == "snd":
            return 2
x = Pair()
x.fst = 1
print(x.fst)
print(x.snd)