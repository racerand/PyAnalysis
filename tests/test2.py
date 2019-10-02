class Empt(object):
    def e(self):
        return

class Fib(object):
    def __init__(self, fst  , snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

    def foo(self, fooArg):
        fooVar = 3
        return fooVar
def identity(z):
    if 1 > 0:
        return Empt()
    else:
        return z
y = Fib(1,2)
x = identity(y)