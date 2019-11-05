class Pair():
    def getParent(self):
        return super()

class Tripple(Pair):
    def getParent(self):
        return super()

b = Tripple()
y = b.getParent()
print(y)