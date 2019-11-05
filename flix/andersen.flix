rel Move(to: Str, from: Str)
rel Alloc(var: Str, heap: Str, inMeth: Str)
rel Load(to: Str, base: Str, fld: Str)
rel Store(base: Str, fld: Str, from: Str)
rel VCall(base: Str, var: Str, invo: Str, inMeth: Str)
rel SCall(var: Str, invo: Str, inMeth: Str)
rel HeapIsFunction(heap: Str)
rel PotentialAllocationSite(invo: Str, storeVar: Str, heap: Str, inMeth: Str)
rel HeapIsClass(heap: Str, class: Str)
rel IsClassFor(instanceHeap: Str, classHeap: Str)
rel SelfVar(self: Str, method: Str)
rel ClsVar(cls: Str, method: Str)
//rel IsInitFor(heap: Str, method:Str)
rel IsParentFor(heap: Str, parentHeap: Str)
rel IsBaseFor(heap: Str, var: Str)
rel IsNewFor(heap: Str, method: Str)
rel IsParentTrans(child: Str, parent: Str)

rel FormalArg(meth: Str, n: Str, arg: Str)
rel ActualArg(invo: Str, n: Str, arg: Str)
rel FormalReturn(meth: Str, ret: Str)
rel ActualReturn(invo: Str, var: Str)
rel VarPointsTo(var: Str, heap: Str)
rel CallGraph(invo: Str, meth: Str)
rel FldPointsTo(baseH: Str, fld: Str, heap: Str)
rel InterProcAssign(to: Str, from: Str)
rel Reachable(meth: Str)

def getRules() : #{Move, Alloc, Load, Store, VCall, SCall, HeapIsFunction, PotentialAllocationSite, HeapIsClass,
 IsClassFor, SelfVar, ClsVar, IsBaseFor, IsParentFor,  IsNewFor, FormalArg, ActualArg, FormalReturn, ActualReturn} =  #{
    //Standard relations present in all programs
        HeapIsClass("HObject", "HClass").
        VarPointsTo("object", "HObject").
        FldPointsTo("HObject", "__new__", "ObjectNew").
        HeapIsFunction("HSuper").
        VarPointsTo("super", "HSuper").

        // Declare some conStraints.
        VarPointsTo(var, heap) :- Reachable(meth), Alloc(var, heap, meth).
        VarPointsTo(to, heap) :- Move(to, from), VarPointsTo(from, heap).
        FldPointsTo(baseH, fld, heap) :- Store(base, fld, from), VarPointsTo(from, heap),
            VarPointsTo(base, baseH).
        VarPointsTo(to, heap) :- Load(to, base, fld), VarPointsTo(base, baseH), FldPointsTo(baseH,fld,heap).
        Reachable(fldHeap) :- VCall(base, fld, invo, inMeth), Reachable(inMeth), VarPointsTo(base, baseHeap),
            FldPointsTo(baseHeap, fld, fldHeap), HeapIsFunction(fldHeap).
        CallGraph(invo, fldHeap) :- VCall(base, fld, invo, inMeth), Reachable(inMeth), VarPointsTo(base, baseHeap),
            FldPointsTo(baseHeap, fld, fldHeap), HeapIsFunction(fldHeap).
        VarPointsTo(self, baseHeap):- VCall(base, fld, invo, inMeth), Reachable(inMeth), VarPointsTo(base, baseHeap),
            FldPointsTo(baseHeap, fld, fldHeap), HeapIsFunction(fldHeap), SelfVar(self, fldHeap).
        InterProcAssign(to,from) :- CallGraph(invo, meth), FormalArg(meth, n, to), ActualArg(invo, n, from).
        InterProcAssign(to,from) :- CallGraph(invo, meth), FormalReturn(meth, from), ActualReturn(invo, to).
        VarPointsTo(to, heap) :- InterProcAssign(to, from), VarPointsTo(from, heap).
        Reachable(heap) :- SCall(var, invo, inMeth), Reachable(inMeth), VarPointsTo(var, heap), HeapIsFunction(heap).
        CallGraph(invo, heap) :- SCall(var, invo, inMeth), Reachable(inMeth), VarPointsTo(var, heap), HeapIsFunction(heap).

        //Allocate an object with the right class if we encounter a static call to ObjectNew
        IsClassFor(heap, classHeap) :- SCall(var, invo, inMeth), VarPointsTo(var, "ObjectNew"), PotentialAllocationSite(invo, storeVar, heap, inMeth),
            ActualArg(invo, "0", clsVar), VarPointsTo(clsVar, classHeap).
        Alloc(storeVar, heap, inMeth) :- SCall(var, invo, inMeth), VarPointsTo(var, "ObjectNew"), PotentialAllocationSite(invo, storeVar, heap, inMeth).
        IsClassFor(heap, classHeap) :- VCall(base, fld, invo, inMeth), VarPointsTo(base, baseHeap), FldPointsTo(baseHeap, fld, "ObjectNew"), PotentialAllocationSite(invo, storeVar, heap, inMeth),
            ActualArg(invo, "0", clsVar), VarPointsTo(clsVar, classHeap).
        Alloc(storeVar, heap, inMeth) :- VCall(base, fld, invo, inMeth), VarPointsTo(base, baseHeap), FldPointsTo(baseHeap, fld, "ObjectNew"),
         PotentialAllocationSite(invo, storeVar, heap, inMeth).

        //Call the __new__ method of a class if there exist a SCall on the class, does the same for all parent definitions of __new__
        Reachable(toMeth) :- SCall(var, invo, inMeth), Reachable(inMeth), VarPointsTo(var, heap), HeapIsClass(heap, classHeap),
            IsParentTrans(heap, parentHeap), IsNewFor(parentHeap, toMeth).
        CallGraph(invo, toMeth) :- SCall(var, invo, inMeth), VarPointsTo(var, classHeap), HeapIsClass(classHeap, class),
         IsParentTrans(classHeap, parentHeap), IsNewFor(parentHeap, toMeth).
        VarPointsTo(cls, classHeap) :- SCall(var, invo, inMeth), VarPointsTo(var, classHeap), HeapIsClass(classHeap, class),
         IsParentTrans(classHeap, parentHeap), IsNewFor(parentHeap, toMeth), ClsVar(cls, toMeth).

        //Whenever we call on a class, we must call all inherited definitions of __new__, we know that we must always inherit from object.
        //Therefore we always create an alloc whenever we see a call of class
        Alloc(storeVar, heap, inMeth) :- SCall(var, invo, inMeth), VarPointsTo(var, classHeap),
         HeapIsClass(classHeap, class), PotentialAllocationSite(invo, storeVar, heap, inMeth).
        IsClassFor(heap, classHeap) :- SCall(var, invo, inMeth), VarPointsTo(var, classHeap), PotentialAllocationSite(invo, storeVar, heap, inMeth),
            HeapIsClass(classHeap, class).

        //Calculate IsParentTrans, which is the transitive and reflective closure of the IsParentFor relation.
        IsParentTrans(child, parent) :- IsParentFor(child, parent).
        IsParentTrans(classHeap, classHeap) :- HeapIsClass(classHeap, class).
        IsParentTrans(child, gparent) :- IsParentTrans(child, parent), IsParentTrans(parent, gparent).

        //We must call all inherited functions.
        CallGraph(invo, method) :- VCall(childVar, fld, invo, inMeth), Reachable(inMeth), VarPointsTo(childVar, childHeap),
            IsClassFor(childHeap, classHeap), IsParentTrans(classHeap, parentHeap), FldPointsTo(parentHeap, fld, method),
            HeapIsFunction(method).
        Reachable(method) :- VCall(childVar, fld, invo, inMeth), Reachable(inMeth), VarPointsTo(childVar, childHeap),
            IsClassFor(childHeap, classHeap), IsParentTrans(classHeap, parentHeap), FldPointsTo(parentHeap, fld, method),
            HeapIsFunction(method).
        VarPointsTo(self, childHeap):- VCall(childVar, fld, invo, inMeth), Reachable(inMeth), VarPointsTo(childVar, childHeap),
            IsClassFor(childHeap, classHeap), IsParentTrans(classHeap, parentHeap), FldPointsTo(parentHeap, fld, method),
            HeapIsFunction(method), SelfVar(self, method).

        //Derive actual parents from the names given statically in the constructors
        IsParentFor(heap, parentHeap) :- IsBaseFor(heap,var), VarPointsTo(var, parentHeap), HeapIsClass(parentHeap, class).

        //Handle super.
        VarPointsTo(storeVar, parentHeap) :- ActualReturn(invo, storeVar), SCall(var, invo, inMeth), Reachable(inMeth),
            VarPointsTo(var, "HSuper"), HeapIsClass(classHeap, class), IsParentFor(classHeap, parentHeap),
            FldPointsTo(classHeap, fld, inMeth).
    }

def getFact(s: Str): #{ Move, Alloc, Load, Store, VCall, SCall, HeapIsFunction, PotentialAllocationSite, HeapIsClass,
 SelfVar, ClsVar, IsBaseFor, IsNewFor, FormalArg, ActualArg, FormalReturn, ActualReturn} =
    let parts = String.split(s, ",");
     match parts[0] with {
        case "Move" => Move(parts[1], parts[2]).
        case "Alloc" => Alloc(parts[1], parts[2], parts[3]).
        case "Load" => Load(parts[1], parts[2], parts[3]).
        case "Store" => Store(parts[1], parts[2], parts[3]).
        case "VCall" => VCall(parts[1], parts[2], parts[3], parts[4]).
        case "SCall" => SCall(parts[1], parts[2], parts[3]).
        case "HeapIsFunction" => HeapIsFunction(parts[1]).
        case "PotentialAllocationSite" => PotentialAllocationSite(parts[1], parts[2], parts[3], parts[4]).
        case "HeapIsClass" => HeapIsClass(parts[1], parts[2]).
        case "SelfVar" => SelfVar(parts[1], parts[2]).
        case "ClsVar" => ClsVar(parts[1], parts[2]).
        case "IsBaseFor" => IsBaseFor(parts[1], parts[2]).
        case "IsNewFor" => IsNewFor(parts[1], parts[2]).

        case "FormalArg" => FormalArg(parts[1], parts[2], parts[3]).
        case "ActualArg" => ActualArg(parts[1], parts[2], parts[3]).
        case "FormalReturn" => FormalReturn(parts[1], parts[2]).
        case "ActualReturn" => ActualReturn(parts[1], parts[2]).

        case _ => ???
     }

def getFacts(l: List[Str]): #{  Move, Alloc, Load, Store, VCall, SCall, HeapIsFunction, PotentialAllocationSite, HeapIsClass,
 SelfVar, ClsVar, IsBaseFor, IsNewFor, FormalArg, ActualArg, FormalReturn, ActualReturn } =
    match l with {
        case Nil => #{ }
        case x :: xs => getFact(x) <+> getFacts(xs)
    }

def readMoveFacts(path: Path): Result[#{  Move, Alloc, Load, Store, VCall, SCall, HeapIsFunction, PotentialAllocationSite, HeapIsClass,
 SelfVar, ClsVar, IsBaseFor, IsNewFor, FormalArg, ActualArg, FormalReturn, ActualReturn },
                                  Path.IOError] =
    Result.map(getFacts, Path.readLines(path))

def main(): #{  Move, Alloc, Load, Store, VCall, SCall, HeapIsFunction, PotentialAllocationSite, HeapIsClass,
 SelfVar, ClsVar, IsBaseFor, IsNewFor, FormalArg, ActualArg, FormalReturn, ActualReturn } =

    let movePath = Path.new("output.csv");
    match readMoveFacts(movePath) with {
        case Ok(facts) =>
            solve (facts)
        case Err(_) => ??? // implement proper error handling.
    }