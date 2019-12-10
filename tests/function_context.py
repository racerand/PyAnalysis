class Null():
    pass

def foo(x):
    return Null()

def baz(x):
    return foo(x)

z = foo(1)
y = baz(z)
y2 = baz(z)