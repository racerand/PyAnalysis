""""
If setattr is defined it called instead of assignments. Since we are non-flow-sensitive we just want to overapproximate.
So whenever we have strore of a heap and the baseheap is a child of a classheap which have a FldPointsTo and the fld
"setattr" and the fld-heap is a function. We want to call the function with the arguments self, item and value.
For these function to make sense in real world examples, we will need to handle dataflow of strings. And have special
case for dealing with object.__setattr__
"""
class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd
    z = object.__setattr__
def setattr(self, item, value):
    self.z(item, 4)

y = Pair(1,2)
Pair.__setattr__ = setattr
x = Pair(1,2)
print(x.fst)
print(y.fst)