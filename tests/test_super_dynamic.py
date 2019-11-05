class Pair():
    def getParent(self):
        return super()

class Tripple(Pair):
    pass

b = Tripple()
Tripple.getParent = Pair.getParent
y = b.getParent()