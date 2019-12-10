rel Move(to: Str, from: Str)
rel Alloc(var: Str, object: Str, inMeth: Str)
rel Load(to: Str, base: Str, attr: Str)
rel Store(base: Str, attr: Str, from: Str)
rel VCall(base: Str, var: Str, invo: Str, inMeth: Str)
rel SCall(var: Str, invo: Str, inMeth: Str)
rel ObjectIsFunction(object: Str)
rel PotentialAllocationSite(invo: Str, storeVar: Str, object: Str, inMeth: Str)
rel ObjectIsClass(object: Str)
rel SelfVar(self: Str, method: Str)
rel ClsVar(cls: Str, method: Str)
//rel IsInitFor(object: Str, method:Str)
rel IsBaseFor(object: Str, var: Str)
rel IsNewFor(object: Str, method: Str)
rel OutOfScopeIn(var: Str, method: Str)

rel FormalArg(meth: Str, n: Str, arg: Str)
rel ActualArg(invo: Str, n: Str, arg: Str)
rel FormalReturn(meth: Str, ret: Str)
rel ActualReturn(invo: Str, var: Str)

// Generated on runtime
rel IsClassFor(instanceObject: Str, instanceOCtx: Str, classObject: Str, classOCtx: Str)
rel IsParentFor(object: Str, parentObject: Str)
rel IsParentTrans(child: Str, parent: Str)

rel VarPointsTo(var: Str, ctx: Str, object: Str, octx: Str)
rel CallGraph(invo: Str, callerCtx: Str, meth: Str, calleeCtx: Str)
rel AttrPointsTo(baseO: Str, baseOCtx: Str, attr: Str, object: Str, octx: Str)
rel InterProcAssign(to: Str, toCtx: Str, from: Str, fromCtx: Str)
rel Reachable(meth: Str, ctx: Str)

def methodMerge(_object: Str, _octx: Str, invo: Str, _ctx: Str) : Str = invo
def _functionMerge(invo: Str, _ctx: Str) : Str = invo
def record(_object: Str, ctx: Str) : Str = ctx

def getRules(merge: (Str, Str, Str, Str) -> Str, record : (Str, Str) -> Str) : #{Move, Alloc, Load, Store, VCall, SCall, ObjectIsFunction, PotentialAllocationSite, ObjectIsClass,
 IsClassFor, SelfVar, ClsVar, IsBaseFor, IsParentFor, IsNewFor, IsParentTrans, FormalArg, ActualArg, FormalReturn,
  ActualReturn, VarPointsTo, CallGraph, AttrPointsTo, InterProcAssign, Reachable, OutOfScopeIn} =  #{
    //Standard relations present in all programs
        // using the empty context as the global starting context (here the empty string)
        Reachable("root", "").
        ObjectIsClass("OObject").
        VarPointsTo("object", "", "OObject", "").
        AttrPointsTo("OObject", "", "__new__", "ObjectNew", "").
        ObjectIsFunction("OSuper").
        VarPointsTo("super", "", "OSuper", "").

        // Declare some conStraints.
        VarPointsTo(var, ctx, object, record(object, ctx)) :-
            Reachable(meth, ctx), Alloc(var, object, meth).
        VarPointsTo(to, ctx, object, octx) :-
            Move(to, from), VarPointsTo(from, ctx, object, octx).
        AttrPointsTo(baseO, baseOCtx, attr, object, octx) :-
            Store(base, attr, from),
            VarPointsTo(from, ctx, object, octx),
            VarPointsTo(base, ctx, baseO, baseOCtx).
        VarPointsTo(to, ctx, object, octx) :-
            Load(to, base, attr),
            VarPointsTo(base, ctx, baseO, baseOCtx),
            AttrPointsTo(baseO, baseOCtx, attr, object, octx).

        // VCall
        Reachable(attrObject, merge(baseObject, baseOCtx, invo, callerCtx)) :-
            VCall(base, attr, invo, inMeth), Reachable(inMeth, callerCtx),
            VarPointsTo(base, callerCtx, baseObject, baseOCtx),
            AttrPointsTo(baseObject, baseOCtx, attr, attrObject, octx),
            ObjectIsFunction(attrObject),
            Reachable(inMeth, callerCtx).
        CallGraph(invo, callerCtx, attrObject, merge(baseObject, baseOCtx, invo, callerCtx)) :-
            VCall(base, attr, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(base, baseCtx, baseObject, baseOCtx),
            AttrPointsTo(baseObject, baseOCtx, attr, attrObject, attrOCtx),
            ObjectIsFunction(attrObject).
        VarPointsTo(self, merge(baseObject, baseOCtx, invo, callerCtx), baseObject, baseOCtx):-
            VCall(base, attr, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(base, callerCtx, baseObject, baseOCtx),
            AttrPointsTo(baseObject, baseOCtx, attr, attrObject, attrOCtx),
            ObjectIsFunction(attrObject),
            SelfVar(self, attrObject).

        // Argument transfer
        InterProcAssign(to, calleeCtx, from, callerCtx) :-
            CallGraph(invo, callerCtx, meth, calleeCtx),
            FormalArg(meth, n, to),
            ActualArg(invo, n, from).

        // Out of scope transfer
        InterProcAssign(var, calleeCtx, var, callerCtx) :-
            CallGraph(invo, callerCtx, meth, calleeCtx),
            OutOfScopeIn(var, meth).

        // Return value transfer
        InterProcAssign(to, callerCtx, from, calleeCtx) :-
            CallGraph(invo, callerCtx, meth, calleeCtx),
            FormalReturn(meth, from),
            ActualReturn(invo, to).

        // InterProc to VarPointsTo
        VarPointsTo(to, toCtx, object, objectCtx) :-
            InterProcAssign(to, toCtx, from, fromCtx),
            VarPointsTo(from, fromCtx, object, objectCtx).

        // SCall
        Reachable(object, merge(object, objectCtx, invo, callerCtx)) :-
            SCall(var, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, callerCtx, object, objectCtx),
            ObjectIsFunction(object).
        CallGraph(invo, callerCtx, object, merge(object, objectCtx, invo, callerCtx)) :-
            SCall(var, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, callerCtx, object, objectCtx),
            ObjectIsFunction(object).

        //Allocate an object with the right class if we encounter a static call to ObjectNew
        // First for SCall
        IsClassFor(object, record(object, methCtx), classObject, classOCtx) :-
            SCall(var, invo, inMeth),
            VarPointsTo(var, methCtx, "ObjectNew", _),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, clsVarCtx, classObject, classOCtx),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).
        Alloc(storeVar, object, inMeth) :-
            SCall(var, invo, inMeth),
            VarPointsTo(var, methCtx, "ObjectNew", objectNewCtx),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            Reachable(inMeth, methCtx).
        // Then for VCall
        IsClassFor(object, record(object, methCtx), classObject, classOCtx) :-
            VCall(base, attr, invo, inMeth),
            VarPointsTo(base, methCtx, baseObject, baseOCtx),
            AttrPointsTo(baseObject, baseOCtx, attr, "ObjectNew", objectNewCtx),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, clsVarCtx, classObject, classOCtx),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).
        Alloc(storeVar, object, inMeth) :-
            VCall(base, attr, invo, inMeth),
            VarPointsTo(base, methCtx, baseObject, baseOCtx),
            AttrPointsTo(baseObject, baseOCtx, attr, "ObjectNew", _),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            Reachable(inMeth, methCtx).

        /* Call the __new__ method of a class if there exist a SCall on the class,
        the next 3 have the same right side */
        // TODO: should do the same for all parent definitions of __new__
        Reachable(object, merge(classObject, classOCtx, invo, callerCtx)) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, classOCtx),
            ObjectIsClass(classObject),
            IsParentTrans(classObject, parentObject)
            AttrPointsTo(parentObject, callerCtx, "__new__", object, objectCtx),
            ObjectIsFunction(object),
            ClsVar(cls, object).

        CallGraph(invo, callerCtx, object, merge(classObject, classOCtx, invo, callerCtx)) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, classOCtx),
            ObjectIsClass(classObject),
            AttrPointsTo(classObject, classOCtx, "__new__", object, objectCtx),
            ObjectIsFunction(object),
            ClsVar(cls, object).

        VarPointsTo(cls, merge(classObject, classOCtx, invo, callerCtx), classObject, classOCtx) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, classOCtx),
            ObjectIsClass(classObject),
            AttrPointsTo(classObject, classOCtx, "__new__", object, objectCtx),
            ObjectIsFunction(object),
            ClsVar(cls, object).

        // Infer call to __init__ on what is returned from __new__
        /* TODO: the calleeCtx not being the exact callee context of this call might be bad
        CallGraph(invo, callerCtx, initMeth, merge(classObject, classOCtx, invo, callerCtx)),
        VarPointsTo(self, merge(classObject, classOCtx, invo, callerCtx), returnObject, returnOCtx),
        Reachable(initMeth, merge(classObject, classOCtx, invo, callerCtx)) :-
            SCall(var,invo,inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, callerCtx, classObject, classOCtx),
            SelfVar(self, initMeth),
            AttrPointsTo(classObject, classOCtx, "__init__", initMeth, initMethCtx),
            AttrPointsTo(classObject, classOCtx, "__init__", newMeth, newMethCtx),
            ClsVar(cls,newMeth),
            FormalReturn(newMeth, ret),
            VarPointsTo(ret, calleeCtx, returnObject, returnOCtx),
            VarPointsTo(cls, calleeCtx, clsObject, clsOCtx),
            IsClassFor(returnObject, returnOCtx, clsObject, callerCtx).
        */
        CallGraph(invo, callerCtx, initMeth, merge(classObject, classOCtx, invo, callerCtx)) :-
            SCall(var,invo,inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, callerCtx, classObject, classOCtx),
            SelfVar(self, initMeth),
            AttrPointsTo(classObject, classOCtx, "__init__", initMeth, initMethCtx),
            AttrPointsTo(classObject, classOCtx, "__new__", newMeth, newMethCtx),
            ClsVar(cls,newMeth),
            FormalReturn(newMeth, ret),
            VarPointsTo(ret, calleeCtx, returnObject, returnOCtx),
            VarPointsTo(cls, calleeCtx, clsObject, clsOCtx),
            IsClassFor(returnObject, returnOCtx, clsObject, callerCtx).

        VarPointsTo(self, merge(classObject, classOCtx, invo, callerCtx), returnObject, returnOCtx) :-
            SCall(var,invo,inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, callerCtx, classObject, classOCtx),
            SelfVar(self, initMeth),
            AttrPointsTo(classObject, classOCtx, "__init__", initMeth, initMethCtx),
            AttrPointsTo(classObject, classOCtx, "__init__", newMeth, newMethCtx),
            ClsVar(cls,newMeth),
            FormalReturn(newMeth, ret),
            VarPointsTo(ret, calleeCtx, returnObject, returnOCtx),
            VarPointsTo(cls, calleeCtx, clsObject, clsOCtx),
            IsClassFor(returnObject, returnOCtx, clsObject, callerCtx).

        Reachable(initMeth, merge(classObject, classOCtx, invo, callerCtx)) :-
            SCall(var,invo,inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, callerCtx, classObject, classOCtx),
            SelfVar(self, initMeth),
            AttrPointsTo(classObject, classOCtx, "__init__", initMeth, initMethCtx),
            AttrPointsTo(classObject, classOCtx, "__init__", newMeth, newMethCtx),
            ClsVar(cls,newMeth),
            FormalReturn(newMeth, ret),
            VarPointsTo(ret, calleeCtx, returnObject, returnOCtx),
            VarPointsTo(cls, calleeCtx, clsObject, clsOCtx),
            IsClassFor(returnObject, returnOCtx, clsObject, callerCtx).

        /* We always make an allocation, as if object.new was called
        Alloc(storeVar, object, inMeth),
        IsClassFor(object, record(object, callerCtx), classObject, classOCtx) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, _, classObject, classOCtx),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth).
        */
        Alloc(storeVar, object, inMeth) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, classOCtx),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth).

        IsClassFor(object, record(object, callerCtx), classObject, classOCtx) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, classOCtx),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth).

        /* And we need to always infer a call to init on this newly allocated object
            Added a VarPointsTo requirement to get the context of the newly allocated object
        CallGraph(invo, callerCtx, initMethod, methodMerge(initMethod, initMCtx, invo, callerCtx)),
        Reachable(initMethod, methodMerge(initMethod, initMCtx, invo, callerCtx)),
        VarPointsTo(self, methodMerge(initMethod, initMCtx, invo, callerCtx), object, objectCtx):-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, classOCtx),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            VarPointsTo(storeVar, callerCtx, object, objectCtx),
            AttrPointsTo(classObject, classOCtx, "__init__", initMethod, initMCtx),
            ObjectIsFunction(initMethod),
            SelfVar(self, initMethod).
        */
        CallGraph(invo, callerCtx, initMethod, methodMerge(initMethod, initMCtx, invo, callerCtx)) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, classOCtx),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            VarPointsTo(storeVar, callerCtx, object, objectCtx),
            AttrPointsTo(classObject, classOCtx, "__init__", initMethod, initMCtx),
            ObjectIsFunction(initMethod),
            SelfVar(self, initMethod).

        Reachable(initMethod, methodMerge(initMethod, initMCtx, invo, callerCtx)) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, classOCtx),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            VarPointsTo(storeVar, callerCtx, object, objectCtx),
            AttrPointsTo(classObject, classOCtx, "__init__", initMethod, initMCtx),
            ObjectIsFunction(initMethod),
            SelfVar(self, initMethod).

        VarPointsTo(self, methodMerge(initMethod, initMCtx, invo, callerCtx), object, objectCtx):-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, classOCtx),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            VarPointsTo(storeVar, callerCtx, object, objectCtx),
            AttrPointsTo(classObject, classOCtx, "__init__", initMethod, initMCtx),
            ObjectIsFunction(initMethod),
            SelfVar(self, initMethod).


        //Calculate IsParentTrans, which is the transitive and reflective closure of the IsParentFor relation.
        IsParentTrans(child, parent) :-
            IsParentFor(child, parent).
        IsParentTrans(classObject, classObject) :-
            ObjectIsClass(classObject).
        IsParentTrans(child, gparent) :-
            IsParentTrans(child, parent),
            IsParentTrans(parent, gparent).

        /* We must call all inherited functions.
        CallGraph(invo, callerCtx, method, merge(childObject, childOCtx, invo, callerCtx)),
        Reachable(method, merge(childObject, childOCtx, invo, callerCtx)),
        VarPointsTo(self, merge(childObject, childOCtx, invo, callerCtx), childObject, childOCtx):-
            VCall(childVar, attr, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(childVar, callerCtx, childObject, childOCtx),
            IsClassFor(childObject, childOCtx, classObject, classOCtx),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, parentOCtx, attr, method, methodCtx),
            ObjectIsFunction(method),
            SelfVar(self, method).
        */
        CallGraph(invo, callerCtx, method, merge(childObject, childOCtx, invo, callerCtx)) :-
            VCall(childVar, attr, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(childVar, callerCtx, childObject, childOCtx),
            IsClassFor(childObject, childOCtx, classObject, classOCtx),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, parentOCtx, attr, method, methodCtx),
            ObjectIsFunction(method),
            SelfVar(self, method).

        Reachable(method, merge(childObject, childOCtx, invo, callerCtx)) :-
            VCall(childVar, attr, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(childVar, callerCtx, childObject, childOCtx),
            IsClassFor(childObject, childOCtx, classObject, classOCtx),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, parentOCtx, attr, method, methodCtx),
            ObjectIsFunction(method),
            SelfVar(self, method).

        VarPointsTo(self, merge(childObject, childOCtx, invo, callerCtx), childObject, childOCtx):-
            VCall(childVar, attr, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(childVar, callerCtx, childObject, childOCtx),
            IsClassFor(childObject, childOCtx, classObject, classOCtx),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, parentOCtx, attr, method, methodCtx),
            ObjectIsFunction(method),
            SelfVar(self, method).


        //Derive actual parents from the names given statically in the constructors
        IsParentFor(object, parentObject) :-
            IsBaseFor(object , var),
            VarPointsTo(var, _, parentObject, _),
            ObjectIsClass(parentObject).

        // Handle super.
        VarPointsTo(storeVar, callerCtx, parentObject, "class") :-
            ActualReturn(invo, storeVar),
            SCall(var, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, callerCtx, "HSuper", superCtx),
            ObjectIsClass(classObject),
            IsParentFor(classObject, parentObject),
            AttrPointsTo(classObject, _, attr, inMeth, _).
            Alloc("rootNull1","HC12","root").
ObjectIsClass("HC12").
IsBaseFor("HC12","object").
Alloc("rootfoo2","HM14","root").
FormalArg("HM14","0","rootfoox3").
ObjectIsFunction("HM14").
PotentialAllocationSite("stmt15","rootfoonew_var4","H16","HM14").
ActualReturn("stmt15","rootfoonew_var4").
SCall("rootNull1","stmt15","HM14").
FormalReturn("HM14","rootfoonew_var4").
OutOfScopeIn("rootNull1","HM14").
Alloc("rootbaz5","HM19","root").
FormalArg("HM19","0","rootbazx6").
ObjectIsFunction("HM19").
Alloc("rootbazfoo7","HM21","HM19").
ObjectIsFunction("HM21").
FormalReturn("HM21","rootbazx6").
OutOfScopeIn("rootbazx6","HM21").
PotentialAllocationSite("stmt22","rootbaznew_var8","H23","HM19").
ActualReturn("stmt22","rootbaznew_var8").
SCall("rootbazfoo7","stmt22","HM19").
FormalReturn("HM19","rootbaznew_var8").
OutOfScopeIn("rootbazfoo7","HM19").
PotentialAllocationSite("stmt25","rootz9","H26","root").
ActualReturn("stmt25","rootz9").
SCall("rootNull1","stmt25","root").
PotentialAllocationSite("stmt28","rooty10","H29","root").
ActualReturn("stmt28","rooty10").
SCall("rootbaz5","stmt28","root").
ActualArg("stmt28","0","rootz9").
PotentialAllocationSite("stmt31","rooty211","H32","root").
ActualReturn("stmt31","rooty211").
SCall("rootbaz5","stmt31","root").
ActualArg("stmt31","0","rootz9").


    }

def getFact(s: Str): #{  Move, Alloc, Load, Store, VCall, SCall, ObjectIsFunction, PotentialAllocationSite, ObjectIsClass,
 IsClassFor, SelfVar, ClsVar, IsBaseFor, IsParentFor, IsNewFor, IsParentTrans, FormalArg, ActualArg, FormalReturn,
  ActualReturn, VarPointsTo, CallGraph, AttrPointsTo, InterProcAssign, Reachable, OutOfScopeIn} =
    let parts = String.split(s, ", ");
     match parts[0] with {
        case "Move" => Move(parts[1], parts[2]).
        case "Alloc" => Alloc(parts[1], parts[2], parts[3]).
        case "Load" => Load(parts[1], parts[2], parts[3]).
        case "Store" => Store(parts[1], parts[2], parts[3]).
        case "VCall" => VCall(parts[1], parts[2], parts[3], parts[4]).
        case "SCall" => SCall(parts[1], parts[2], parts[3]).
        case "ObjectIsFunction" => ObjectIsFunction(parts[1]).
        case "PotentialAllocationSite" => PotentialAllocationSite(parts[1], parts[2], parts[3], parts[4]).
        case "ObjectIsClass" => ObjectIsClass(parts[1]).
        case "SelfVar" => SelfVar(parts[1], parts[2]).
        case "ClsVar" => ClsVar(parts[1], parts[2]).
        case "IsBaseFor" => IsBaseFor(parts[1], parts[2]).
        case "IsNewFor" => IsNewFor(parts[1], parts[2]).

        case "FormalArg" => FormalArg(parts[1], parts[2], parts[3]).
        case "ActualArg" => ActualArg(parts[1], parts[2], parts[3]).
        case "FormalReturn" => FormalReturn(parts[1], parts[2]).
        case "ActualReturn" => ActualReturn(parts[1], parts[2]).
        case "OutOfScopeIn" => OutOfScopeIn(parts[1], parts[2]).

        case _ => ???
     }

def getFacts(l: List[Str]): #{  Move, Alloc, Load, Store, VCall, SCall, ObjectIsFunction, PotentialAllocationSite, ObjectIsClass,
 IsClassFor, SelfVar, ClsVar, IsBaseFor, IsParentFor, IsNewFor, IsParentTrans, FormalArg, ActualArg, FormalReturn,
  ActualReturn, VarPointsTo, CallGraph, AttrPointsTo, InterProcAssign, Reachable, OutOfScopeIn } =
    match l with {
        case Nil => #{ }
        case x :: xs => getFact(x) <+> getFacts(xs)
    }

def readMoveFacts(path: Path): Result[#{   Move, Alloc, Load, Store, VCall, SCall, ObjectIsFunction, PotentialAllocationSite, ObjectIsClass,
 IsClassFor, SelfVar, ClsVar, IsBaseFor, IsParentFor, IsNewFor, IsParentTrans, FormalArg, ActualArg, FormalReturn,
  ActualReturn, VarPointsTo, CallGraph, AttrPointsTo, InterProcAssign, Reachable,OutOfScopeIn},
                                  Path.IOError] =
    Result.map(getFacts, Path.readLines(path))

def main(): #{  Move, Alloc, Load, Store, VCall, SCall, ObjectIsFunction, PotentialAllocationSite, ObjectIsClass,
 IsClassFor, SelfVar, ClsVar, IsBaseFor, IsParentFor, IsNewFor, IsParentTrans, FormalArg, ActualArg, FormalReturn,
  ActualReturn, VarPointsTo, CallGraph, AttrPointsTo, InterProcAssign, Reachable, OutOfScopeIn} =
    let rules = getRules(methodMerge, record);
    let result = solve rules;
    project VarPointsTo result