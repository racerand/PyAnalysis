class Fib(object):
    def __init__(self, fst  , snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

x = Fib(1, 2)
y = Fib(x, 2)
x.fst = y
x.fst.snd = y.fst.fst.snd

x = y
y = x


def foo(x = y):
    if 4 > 2:
        z = 1
    return z

print(foo(x))

#x.fst.fst.snd = NameError

#with open("our-ast.py", mode='r') as fib:
#    x.fst.fst.snd = 0


#try:
#    ast = open("our-ast.py", mode='r')
#    ast.read()
#except NameError: #x.fst.fst.snd:
#    print("hey")
