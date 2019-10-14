""""
As of writing we treat init by creating a IsInitFor(class,method) relation during ast-pass. We know an allocation
happens just by the fact that we are calling a class-object, the reason why we need init is that we need to point
the self-variable of the init function to the heap that is being allocated. To handle dynamic assignment we must take a
new approach and handle init just like any other attribute. But derive the CallGraph and VarPointsTo relations from
the FldPointsTo relation alone.
"""

class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

def stupidInit(self, fst, snd):
    self.snd = fst
    self.fst = snd

z = Pair
z.__init__ = stupidInit
x = Pair(1,2)
print(x.fst)
print(x.snd)

