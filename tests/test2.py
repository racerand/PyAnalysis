class Fib(object):
    def __init__(self, fst  , snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

    def bar(self):
        print("bar")
one = 1
two = 2

x = Fib(1 + 0, 2)
z = x
y = z.fst
x.snd = y
x.bar()

x = None

def foo():
    if x:
        return
    else:
        pass
    return 1 + 2

foo()