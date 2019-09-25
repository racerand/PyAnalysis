class Fib(object):
    def __init__(self, fst  , snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

x = Fib(1, 2)
z = x
y = z.fst
x.snd = y