class Fib:

    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

x = Fib(1, 2)
y = Fib(x, 2)
x.fst = y
x.snd = y.fst.fst.snd

def foo(x = 12):
    return x
