class Pair(object):
    def __init__(self, fst, snd):
        self.fst = fst
        self.snd = snd

    def __new__(cls, *args, **kwargs):
        return object.__new__(cls)
class Tripple(object):
    def __new__(cls, *args, **kwargs):
        if kwargs.get("isPair"):
            return object.__new__(Pair)
        else:
            return super().__new__(cls)
b = Tripple(isPair=True)
y = Tripple()