class Pair():
    def __new__(cls, *args, **kwargs):
        return object.__new__(cls)

    def foo(self):
        print(self)


class Tripple(Pair):
    def __new__(cls, *args, **kwargs):
        return object.__new__(cls)


b = Pair()
y = Tripple()
