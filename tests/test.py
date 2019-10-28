
d = object.__new__

class Complex:
    def __new__(cls, *args, **kwargs):
        return d(cls)
    def __init__(self, realpart, imagpart):
        self.r = realpart
        self.i = imagpart


x = Complex(3.0, -4.5)
y = Complex(1, 2)

x.c = y

a = x.c.r

print(x.r)