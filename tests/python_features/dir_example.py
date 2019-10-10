# This example showcases the builtin dir function, which returns the set of attributes for a heap object.
# It does not have any side effects, but we might be able to estimate what the function evaluates to, witch might
# Be interesting in a flow-sensitive analysis. We will just need to consider attributes containing non-heap values
# in our current analysis, which shouldn't be much work.
class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd


def print_fst(self):
    print(self.fst)


def switch_func(self):
    tmp = self.snd
    self.snd = self.fst
    self.fst = tmp


print(dir(Pair))
x = Pair(1, 2)
print(dir(x))
Pair.switch = switch_func
x.print_fst = print_fst
print(dir(Pair))
print(dir(x))
