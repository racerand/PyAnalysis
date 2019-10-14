""""
The __del__ method of instance-object is only called when there is no more references to the object. We can't keep
track of this without context or flow sensitivity. However, since only "del" can decrease the reference count of an
object we can overaproximate, and add a call to the appropriate__del__ whenever we observe a "del" statement.
"""

class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

    def __del__(self):
        print("Baz")

    def __new__(cls, *args, **kwargs):
        return super().__new__(cls)

x = Pair(1,2)
z = x
y = x
del z
print(y.fst)