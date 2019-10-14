""""
Exactly the same as for getitem, except the second argument to set_item can be a heap and so we need to add it as
an argument to set_item in our analysis even though we don't consider dataflow.
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

def set_item(self, key, value):
    if key == 0:
        self.fst = value
    elif key == 1:
        self.snd = value
    else:
        raise IndexError

x = Pair(1,1)
Pair.__setitem__ = set_item
x[1] = 3
print(x.snd)