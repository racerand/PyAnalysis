""""
Wheter or not it makes sense to consider this feature in a flow and context in an insensitive setting is questionable. But
in this case we can simply desugar "for i in x" to "i = x.init().next()"
"""
class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd
        self.index = 0

    def __iter__(self):
        return self

    def __next__(self):
        if self.index == 0:
            self.index += 1
            return self.fst
        elif self.index == 1:
            self.index += 1
            return self.snd
        else:
            self.index = 0
            raise StopIteration

def foo(bar):
    pass


x = Pair(1,2)
for i in x:
    print(i)
for i in x:
    print(i)
