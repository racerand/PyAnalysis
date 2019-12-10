class Foo(object):
    def __new__(cls):
        return object.__new__(cls)

class Bar(Pair):
    def __new__(cls):
        return super().__new__(cls)

y = Foo()
x = Foo()