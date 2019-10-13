""""
"""
class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

def foo(bar):
    pass


x = Pair(1,2)
xDict = vars(x)
xDict["trd"] = 3
print(x.trd)
