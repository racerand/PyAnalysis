# This is a simple example where classes are defined statically, simple flow sensitivity would suffice for this example
class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd
z = Pair
class Tripple(z):
    def __init__(self, fst, snd, trd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd
        self.trd = trd


x = Pair(1, 2)
x = Tripple(1, 2, 3)
if isinstance(x, Tripple):
    print(x.trd)
