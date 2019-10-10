class Empt(object):
    def e(self):
        return


class Fib(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

    def __call__(self, *args, **kwargs):
        print("foo")

    def foo(self, fooArg):
        fooVar = Empt()
        return fooVar


def identity(z):
    return z


def makeEmpt(z):
    return Empt()


x = Fib(1, 2)

y = x.foo(2)
