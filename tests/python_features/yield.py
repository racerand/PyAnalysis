""""
 We can handle yield in the flow and context insensitive case, by maintaining wether or not we have established a
 generator function in the current node when doing the anderesen_visitor. When the first yield is observed we generate
 a new instance-object with a next-method field defined, along with a return statement returning the object. We maintain this info in our context.
 Whenever we encounter a yield expression we can add a FormalReturn relation to the next-method of the generator object.
 This approach is compatable with the de-sugaring of For used for handling __iter__
"""
class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd
        self.index = 0

    def __iter__(self):
        yield self.fst
        yield self.snd


def foo(bar):
    pass


x = Pair(1,2)
for i in x:
    print(i)
for i in x:
    print(i)
