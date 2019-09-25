class Fib(object):
    def __init__(self, fst  , snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

    def bar(self):
        bar2 = "bar"
        print(bar2)
one = 1
two = 2

x = Fib(one, two)
z = x
y = z.fst
x.snd = y
x.bar()