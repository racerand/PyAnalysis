""""
In this example we utilize the fact that classes are objects in python. Here again it would look like flow sensitvity
should suffice, since we simply need to know what the Pair name points to at a given point. By running our current
analysis we see Pair pointing to 2 different class objects, by adding flow sensitivy we could narrow it down to 1 at
the isinstance call.
"""


class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd


class Tripple(object):
    def __init__(self, fst, snd, trd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd
        self.trd = trd


Pair = Tripple
x = Pair(1, 2, 3)
if isinstance(x, Tripple):
    print(x.trd)
