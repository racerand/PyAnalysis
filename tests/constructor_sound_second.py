class Complex:
    def __new__(cls, *args, **kwargs):
        return object.__new__(cls)
    def __init__(self, realpart, imagpart):
        self.r = realpart
        self.i = imagpart


x = Complex(3.0, -4.5)
y = Complex(3.0, -4.5)