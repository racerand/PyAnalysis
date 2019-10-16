""""
This analysis will be ridiculous when done context-insensitive. The special attribute object.__new__ is the only way
to allocate a new instance of a class. We could analyse this by keeping a special relation for that method, and
handling super, inheritance and normalizing every class to have a __new__ method defined as calling super. However
all children will call the parrent new function untill we reach a direct child of object where the allocation happens
which means that not only will all instances of a class have the same allocation site, all children will have the same
allocation site as it's top-most parrent. In this example all allocations of Pair and Tripple will be allocated at line
26. So if we where to do something context-insensitive and meaningfull (and possibly unsound) we could try to estimate
the cases where __new__ is just a call to object.__new__ and replace it with the allocations we know. Alternatively
we could try to somehow combine the approach of potential-allocation site and the fact that only object.__new__ creates
new heaps. This would mean that the heap name made for the potential-allocation would be the actual name (allocation
site) used when we get to object.__new__
Needs context og heap sensitivity
The running time of the analysis becomes pretty long for real programs with a hierarchy taller than 2.
"""

class IntStr(str):
    def __new__(cls, number):
        return number.__str__()

class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

    def __new__(cls, *args, **kwargs):
        return super().__new__(cls)

class Foo(object):
    def bar(self):
        print("bar")

class Tripple(Pair):
    def __init__(self, fst, snd, trd) -> None:
        super().__init__(fst, snd)
        self.trd = trd

    def __new__(cls, *args, **kwargs):
        return super().__new__(cls)

x = Tripple(1,2,3)
print(x.fst)