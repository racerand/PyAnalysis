class Empt(object):
    def e(self):
        return

class Fib(object):
    def __init__(self, fst  , snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

    def __call__(self, *args, **kwargs):
        print("foo")
    def reinit(self, fst2, snd2):
        self.fst = fst2
        self.snd = snd2
def identity(z):
        return z

def makeEmpt(z):
    return Empt()

x = Fib(Empt(),Empt())