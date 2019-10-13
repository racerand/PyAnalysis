""""
Dict might actually be used when doing data-formating. For example when parsing generic formats such as .csv or .xml
There are several possible approaches to approximating the behaviour of dict. But in actual python what happens is
that every object has a relation to a dictionary. When fields are updated dicts is updated accordingly and vice-versa.
Maybe we should examnine ways to encapsualte these actual semantics in our analysis. This would require dataflow
analysis since we need a way to atleast represent strings.
"""
class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd

def foo(bar):
    pass


x = Pair(1,2)
x.__dict__[1] = 3
print(x.__dict__)

