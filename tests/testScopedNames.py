class Empt():
    def e(self):
        return


class Fib():
    x = 2

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
x = 2

def baz():
    x = 3
    return x