class Pair():
    def __new__(cls, *args, **kwargs):
        return object.__new__(cls)
    def foo(self):
        print(self)

b = Pair()
y = Pair()
