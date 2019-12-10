class Null:
    pass


x = Null()


def foo(n):
    x = Null()
    return n


def get_x():
    z = foo(x)
    return z


y = get_x()