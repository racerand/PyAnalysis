class FooFactory(object):
    def getFoo(self):
        return Foo()
c = FooFactory()
d = FooFactory()

class Foo(object):
    def bar(self):
        pass #Do nothing

a = c.getFoo()
b = d.getFoo()
a.bar()
b.bar()