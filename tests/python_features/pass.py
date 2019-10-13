""""
This feature seems a bit trivial for our analysis. We only export information to datalog when it might effect our
analysis. It doesn't seem like pass will effect our analysis and so it is already handeled.
"""
class BoringPair(object):
    pass

def pretty_boring(self, item, value):
    pass

y = BoringPair()
pretty_boring(1, 2, 3)
