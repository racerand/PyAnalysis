class Empt(object):
    def e(self):
        return

class Fib(object):
    def __init__(self, fst  , snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

    def foo(self, fooArg):
        fooVar = Empt()
        return fooVar
def identity(z):
        return z

def makeEmpt(z):
    return Empt()

makeEmpt = Fib.foo

x = makeEmpt(Fib(1,2),1)