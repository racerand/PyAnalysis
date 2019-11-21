class Pair(object):
    def getParent(self):
        return super()
class Tripple(Pair):
    pass
Tripple.getParent = Pair.getParent
x = Tripple()
y = Pair()
x.getParent()
y.getParent()