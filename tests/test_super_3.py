class Pair():
    def getParent(self):
        return super()

class Tripple(Pair):
    def getParent(self):
        return super()

x = Pair()
y = x
b = Tripple()
y = b.getParent()
print(y)