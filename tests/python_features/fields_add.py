# Example of pythons ability to add fields on both object and class level.
# Since we consider classes and functions to be like any other kind of heap-object, our analysis should already cover this

class Empt(object):
    def __init__(self) -> None:
        super().__init__()


class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd


def switch_func(self):
    tmp = self.snd
    self.snd = self.fst
    self.fst = tmp


x = Pair(Empt(), Empt())
Pair.switch = switch_func
x.switch()
Pair.trd = 3
print(x.trd)
x.frd = 4
y = Pair(1, 2)
print(y.trd)
try:
    print(y.frd)
except:
    print("failed as expected")
