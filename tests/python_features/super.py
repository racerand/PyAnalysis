""""
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

x = Tripple(1, 2, 3)
