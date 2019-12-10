# Example of pythons ability to delete fields on both object and class level
# If we want to analyse this we need some kind of flow sensitivity, else it won't contribute anything since we won't
# know at which points the fields are actually deleted.

class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd
    def print_fst(self):
        print(self.fst)
x = Pair(1, 2)
x.print_fst()
del Pair.print_fst
try:
    x.print_fst()
except:
    print("failed as expected")
