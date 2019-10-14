""""
"""

class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

class StupidPair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = snd
        self.snd = fst


class Tripple(Pair):
    def __init__(self, fst, snd, trd) -> None:
        super().__init__(fst, snd)
        self.trd = trd

y = Tripple(1,2,3)
Tripple.__bases__ = (StupidPair,)
x = Tripple(1,2,3)
print(Tripple.__bases__)
print(x.fst)
print(x.snd)
print(x.trd)
print(y.fst)
print(y.snd)
print(y.trd)