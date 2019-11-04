class Pair:
    def foo(self):
        return self
class Tripple(Pair):
    pass

x = Tripple()
y = x.foo()