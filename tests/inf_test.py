from pyDatalog import pyDatalog

pyDatalog.create_terms('Path, Edge, X, Y, Z')
+ Edge('1', '2')
+Edge('2', '1')

Path(X, Y) <= Edge(X, Y)
Path(X, Z) <= Path(X, Y) & Edge(Y, Z)

print(Path(X, Y))
