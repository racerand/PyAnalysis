class Fib(object):
    def __init__(self, fst  , snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

x = Fib(1, 2)
y = Fib(x, 2)
x.fst = y
x.fst.snd = y.fst.fst.snd

def foo(x = y):
    return x.fst.snd

foo(x)

with open("our-ast.py", mode='r') as fib:
    x.fst.fst.snd = 0
