""""
We need to keep track of subscripts in our datalog relations. Whenever we see a subscript where the value is a var
that points to a class. We need to call the getitem of the class and all parent classes. The argument is not important
unless we start to do dataflow analysis.
"""

class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd



class Tripple(Pair):
    def __init__(self, fst, snd, trd) -> None:
        super().__init__(fst, snd)
        self.trd = trd

def get_item(self, item):
    if item == 0:
        return self.fst
    elif item == 1:
        return self.snd
    else:
        raise IndexError

x = Pair(1,1)
Pair.__getitem__ = get_item
print(x[0])