""""
    This is the most interesting inspection function. Right now we don't hande inheritance at all, however
    using the class definitions we should be able to maintain relations between children and parrents.
    We can then declare a rule specifying the transitivity of the relation. This way we should always be able to infer
    the return value of the issubclass function.
"""
class Pair(object):
    def __init__(self, fst, snd) -> None:
        super().__init__()
        self.fst = fst
        self.snd = snd
class Tripple(Pair):
    def __init__(self, fst, snd, trd) -> None:
        super().__init__(fst, snd)
        self.trd = trd

print(issubclass(Tripple, Pair))
