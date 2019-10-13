""""
Wheter or not it makes sense to consider this feature in a flow and context insensitive setting is questionable. But
in this case we can simply desugar "for i in x" to "i = x.init().next()"
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
