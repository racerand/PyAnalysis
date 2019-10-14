""""
Desugaring eq and the like to the method calls of the intance-objects concerned shouldn't be difficult. However
the comparison method act as each others reflections. The algorithm determining which method to use is as follows:
if the right hand side is a subtype of the left we start by considering the method we need from the right hand to
perform the check. If this does not exist we consider the left hand. This would be difficult to embed in datalog
since datalog doesn't support branching. However we could over approximate by calling both possible methods.
"""

class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

    def __new__(cls, *args, **kwargs):
        return super().__new__(cls)

    def __le__(self, other):
        return self.fst <= other.fst

class Tripple(Pair):
    def __init__(self, fst, snd, trd) -> None:
        super().__init__(fst, snd)
        self.trd = trd

    def __le__(self, other):
        return self.trd <= other.trd


x = Pair(1,1)
y = Pair(2,2)
z = Tripple(3,3,3)

print(y <= z)