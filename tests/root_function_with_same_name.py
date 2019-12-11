class Null():
    pass

def foo(x):
    return baz(x)

def baz(x):
    return Null()

z = foo(1)
print(z)
y = baz(z)
y2 = baz(z)

def baz(x):
    return x

print(foo(1))

class Null():
    pass

