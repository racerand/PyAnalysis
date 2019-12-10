class Null():
    pass

def foo(x):
    return Null()

def baz(x):
    def foo():
        return x
    return foo()

z = Null()
y = baz(z)
y2 = baz(z)