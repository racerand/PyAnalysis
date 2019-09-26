class Fib(object):
    def __init__(self, fst  , snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

    def bar(self):
        print("bar")

    def foo(self):
        fooVar = 1
        return fooVar
one = 1
two = 2

x = Fib(1 + 0, two)
y = 3
x.snd = y
q = Fib(1,2)
q.snd = x
q2 = q.snd
q = x
w = x.foo()