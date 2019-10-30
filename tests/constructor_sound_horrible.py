class Complex:
    def __init__(self, realpart, imagpart):
        self.r = realpart
        self.i = imagpart

class Bar:
    def __init__(self, realpart, imagpart):
        self.r = realpart
        self.i = imagpart


class Foo(Complex):
    def __init__(self, r, c):
        super().__init__(r, c)
        print("lol")

Foo.__bases__ = {Bar}