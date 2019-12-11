class Null():
    pass

def foo(x):
    return baz(x)

def baz(x):
    def inside():
        return Null()
    return inside()

z = foo(1)
print(z)
y = baz(z)
y2 = baz(z)

if z:
    def bar():
        return 2
else:
    def bar():
        return 1

def baz(x):
    return x

print(foo(1))

class Null():
    pass

