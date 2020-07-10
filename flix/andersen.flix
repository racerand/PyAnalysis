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
rel IsClassFor[octx](instanceObject: Str, instanceOCtx: octx, classObject: Str)
rel IsParentFor(object: Str, parentObject: Str)
rel IsParentTrans(child: Str, parent: Str)

rel VarPointsTo[octx, ctx](var: Str, ctx: ctx, object: Str, octx: octx)
rel CallGraph[ctx](invo: Str, callerCtx: ctx, meth: Str, calleeCtx: ctx)
rel AttrPointsTo[octx](baseO: Str, baseOCtx: octx, attr: Str, object: Str, octx: octx)
rel InterProcAssign[ctx](to: Str, toCtx: ctx, from: Str, fromCtx: ctx)
rel Reachable[ctx](meth: Str, ctx: ctx)

def strMerge(_object: Str, _octx: Str, invo: Str, _ctx: Str) : Str = invo
def _functionMerge(invo: Str, _ctx: Str) : Str = invo
def strRecord(_object: Str, ctx: Str) : Str = ctx
def _listMerge(_object: Str, _octx: List[Str], invo: Str, _ctx: List[Str]) : List[Str] = invo::Nil
def _listRecord(_object: Str, ctx: List[Str]) : List[Str] = ctx

type alias AllTypes[octx, ctx] = #{Move, Alloc, Load,
    Store, VCall, SCall, ObjectIsFunction, PotentialAllocationSite, ObjectIsClass, IsClassFor[octx], SelfVar, ClsVar,
    IsBaseFor, IsParentFor, IsNewFor, IsParentTrans, FormalArg, ActualArg, FormalReturn,
    ActualReturn, VarPointsTo[octx, ctx], CallGraph[ctx], AttrPointsTo[octx],
    InterProcAssign[ctx], Reachable[ctx], OutOfScopeIn}

def getRules(merge: (Str, octx, Str, ctx) -> ctx, record : (Str, ctx) -> octx, empty_ctx : ctx) : #{Move, Alloc, Load,
  Store, VCall, SCall, ObjectIsFunction, PotentialAllocationSite, ObjectIsClass, IsClassFor[Str], SelfVar, ClsVar,
  IsBaseFor, IsParentFor, IsNewFor, IsParentTrans, FormalArg, ActualArg, FormalReturn,
  ActualReturn, VarPointsTo[Str, Str], CallGraph[Str], AttrPointsTo[Str],
   InterProcAssign[Str], Reachable[Str], OutOfScopeIn} =  #{
    //Standard relations present in all programs
        // using the empty context as the global starting context (here the empty string)
        Reachable("root", empty_ctx).
        ObjectIsClass("OObject").
        VarPointsTo("object", empty_ctx, "OObject", record("OObject", empty_ctx)).
        AttrPointsTo("OObject", record("OObject", empty_ctx), "__new__", "ObjectNew", record("ObjectNew", empty_ctx)).
        ObjectIsFunction("OSuper").
        VarPointsTo("super", empty_ctx, "OSuper", record("OSuper", empty_ctx)).
        VarPointsTo("str", empty_ctx, "String", record("String", empty_ctx)).
        ObjectIsClass("String").
        IsParentFor("String", "OObject").

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
            VCall(base, attr, invo, inMeth), Reachable(inMeth, callerCtx),
            VarPointsTo(base, callerCtx, baseObject, baseOCtx),
            AttrPointsTo(baseObject, baseOCtx, attr, attrObject, octx),
            ObjectIsFunction(attrObject),
            Reachable(inMeth, callerCtx).
        VarPointsTo(self, merge(baseObject, baseOCtx, invo, callerCtx), baseObject, baseOCtx):-
            VCall(base, attr, invo, inMeth), Reachable(inMeth, callerCtx),
            VarPointsTo(base, callerCtx, baseObject, baseOCtx),
            AttrPointsTo(baseObject, baseOCtx, attr, attrObject, octx),
            ObjectIsFunction(attrObject),
            Reachable(inMeth, callerCtx),
            SelfVar(self, attrObject).

        // VCall for a base not defined in the local scope
        Reachable(attrObject, merge(baseObject, baseOCtx, invo, callerCtx)) :-
            VCall(base, attr, invo, inMeth), Reachable(inMeth, callerCtx),
            VarPointsTo(base, _, baseObject, baseOCtx),
            OutOfScopeIn(base, inMeth),
            AttrPointsTo(baseObject, baseOCtx, attr, attrObject, octx),
            ObjectIsFunction(attrObject),
            Reachable(inMeth, callerCtx).
        CallGraph(invo, callerCtx, attrObject, merge(baseObject, baseOCtx, invo, callerCtx)) :-
            VCall(base, attr, invo, inMeth), Reachable(inMeth, callerCtx),
            VarPointsTo(base, _, baseObject, baseOCtx),
            OutOfScopeIn(base, inMeth),
            AttrPointsTo(baseObject, baseOCtx, attr, attrObject, octx),
            ObjectIsFunction(attrObject),
            Reachable(inMeth, callerCtx).
        VarPointsTo(self, merge(baseObject, baseOCtx, invo, callerCtx), baseObject, baseOCtx):-
            VCall(base, attr, invo, inMeth), Reachable(inMeth, callerCtx),
            VarPointsTo(base, _, baseObject, baseOCtx),
            OutOfScopeIn(base, inMeth),
            AttrPointsTo(baseObject, baseOCtx, attr, attrObject, octx),
            ObjectIsFunction(attrObject),
            Reachable(inMeth, callerCtx),
            SelfVar(self, attrObject).

        /* We must call all inherited functions.
        CallGraph(invo, callerCtx, method, merge(childObject, childOCtx, invo, callerCtx)),
        Reachable(method, merge(childObject, childOCtx, invo, callerCtx)),
        VarPointsTo(self, merge(childObject, childOCtx, invo, callerCtx), childObject, childOCtx):-
            VCall(childVar, attr, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(childVar, callerCtx, childObject, childOCtx),
            IsClassFor(childObject, childOCtx, classObject),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, parentOCtx, attr, method, methodCtx),
            ObjectIsFunction(method),
            SelfVar(self, method).
        */
        CallGraph(invo, callerCtx, method, merge(childObject, childOCtx, invo, callerCtx)) :-
            VCall(childVar, attr, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(childVar, callerCtx, childObject, childOCtx),
            IsClassFor(childObject, childOCtx, classObject),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, parentOCtx, attr, method, methodCtx),
            ObjectIsFunction(method),
            SelfVar(self, method).

        Reachable(method, merge(childObject, childOCtx, invo, callerCtx)) :-
            VCall(childVar, attr, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(childVar, callerCtx, childObject, childOCtx),
            IsClassFor(childObject, childOCtx, classObject),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, parentOCtx, attr, method, methodCtx),
            ObjectIsFunction(method),
            SelfVar(self, method).

        VarPointsTo(self, merge(childObject, childOCtx, invo, callerCtx), childObject, childOCtx):-
            VCall(childVar, attr, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(childVar, callerCtx, childObject, childOCtx),
            IsClassFor(childObject, childOCtx, classObject),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, parentOCtx, attr, method, methodCtx),
            ObjectIsFunction(method),
            SelfVar(self, method).

        /* We must call all inherited methods. When childVar is not defined in the local scope
        CallGraph(invo, callerCtx, method, merge(childObject, childOCtx, invo, callerCtx)),
        Reachable(method, merge(childObject, childOCtx, invo, callerCtx)),
        VarPointsTo(self, merge(childObject, childOCtx, invo, callerCtx), childObject, childOCtx):-
            VCall(childVar, attr, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(childVar, _, childObject, childOCtx),
            OutOfScopeIn(childVar, inMeth),
            IsClassFor(childObject, childOCtx, classObject),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, parentOCtx, attr, method, methodCtx),
            ObjectIsFunction(method),
            SelfVar(self, method).
        */
        CallGraph(invo, callerCtx, method, merge(childObject, childOCtx, invo, callerCtx)) :-
            VCall(childVar, attr, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(childVar, _, childObject, childOCtx),
            OutOfScopeIn(childVar, inMeth),
            IsClassFor(childObject, childOCtx, classObject),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, parentOCtx, attr, method, methodCtx),
            ObjectIsFunction(method),
            SelfVar(self, method).

        Reachable(method, merge(childObject, childOCtx, invo, callerCtx)) :-
            VCall(childVar, attr, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(childVar, _, childObject, childOCtx),
            OutOfScopeIn(childVar, inMeth),
            IsClassFor(childObject, childOCtx, classObject),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, parentOCtx, attr, method, methodCtx),
            ObjectIsFunction(method),
            SelfVar(self, method).

        VarPointsTo(self, merge(childObject, childOCtx, invo, callerCtx), childObject, childOCtx):-
            VCall(childVar, attr, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(childVar, _, childObject, childOCtx),
            OutOfScopeIn(childVar, inMeth),
            IsClassFor(childObject, childOCtx, classObject),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, parentOCtx, attr, method, methodCtx),
            ObjectIsFunction(method),
            SelfVar(self, method).


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

        // SCall. Where var does not point to anything in the local scope
        Reachable(object, merge(object, objectCtx, invo, callerCtx)) :-
            SCall(var, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, _, object, objectCtx),
            OutOfScopeIn(var, inMeth),
            ObjectIsFunction(object).
        CallGraph(invo, callerCtx, object, merge(object, objectCtx, invo, callerCtx)) :-
            SCall(var, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, _, object, objectCtx),
            OutOfScopeIn(var, inMeth),
            ObjectIsFunction(object).

        //Allocate an object with the right class if we encounter a static call to ObjectNew
        // First for SCall
        IsClassFor(object, record(object, methCtx), classObject) :-
            SCall(var, invo, inMeth),
            VarPointsTo(var, methCtx, "ObjectNew", _),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).
        Alloc(storeVar, object, inMeth) :-
            SCall(var, invo, inMeth),
            VarPointsTo(var, methCtx, "ObjectNew", _),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).

        // First for SCall where var is not in the local scope
        IsClassFor(object, record(object, methCtx), classObject) :-
            SCall(var, invo, inMeth),
            VarPointsTo(var, _, "ObjectNew", _),
            OutOfScopeIn(var, inMeth),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).
        Alloc(storeVar, object, inMeth) :-
            SCall(var, invo, inMeth),
            VarPointsTo(var, _, "ObjectNew", _),
            OutOfScopeIn(var, inMeth),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).


        // Then for VCall
        IsClassFor(object, record(object, methCtx), classObject) :-
            VCall(base, attr, invo, inMeth),
            VarPointsTo(base, methCtx, baseObject, baseOCtx),
            AttrPointsTo(baseObject, baseOCtx, attr, "ObjectNew", _),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).
        Alloc(storeVar, object, inMeth) :-
            VCall(base, attr, invo, inMeth),
            VarPointsTo(base, methCtx, baseObject, baseOCtx),
            AttrPointsTo(baseObject, baseOCtx, attr, "ObjectNew", _),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).
        // Then for VCall when the call is on a class and we need to look up the transitive and reflective closure
        // of inheritance.
        IsClassFor(object, record(object, methCtx), classObject) :-
            VCall(base, attr, invo, inMeth),
            VarPointsTo(base, methCtx, baseObject, _),
            ObjectIsClass(baseObject),
            IsParentTrans(baseObject, parentObject),
            AttrPointsTo(parentObject, _, attr, "ObjectNew", _),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).
        Alloc(storeVar, object, inMeth) :-
            VCall(base, attr, invo, inMeth),
            VarPointsTo(base, methCtx, baseObject, _),
            ObjectIsClass(baseObject),
            IsParentTrans(baseObject, parentObject),
            AttrPointsTo(parentObject, _, attr, "ObjectNew", _),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).

        // Then for VCall when we look up the transitive and reflective closure of inheritance when the base object is
        //an instance
        IsClassFor(object, record(object, methCtx), classObject) :-
            VCall(base, attr, invo, inMeth),
            VarPointsTo(base, methCtx, baseObject, baseOCtx),
            IsClassFor(baseObject, basOCtx, classForObject),
            IsParentTrans(classForObject, parentObject),
            AttrPointsTo(parentObject, _, attr, "ObjectNew", _),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).
        Alloc(storeVar, object, inMeth) :-
            VCall(base, attr, invo, inMeth),
            VarPointsTo(base, methCtx, baseObject, baseOCtx),
            IsClassFor(baseObject, basOCtx, classForObject),
            IsParentTrans(classForObject, parentObject),
            AttrPointsTo(parentObject, _, attr, "ObjectNew", _),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).

        // Then for VCall. When base does not point to anything in the current context
        IsClassFor(object, record(object, methCtx), classObject) :-
            VCall(base, attr, invo, inMeth),
            VarPointsTo(base, _, baseObject, baseOCtx),
            OutOfScopeIn(base, inMeth),
            AttrPointsTo(baseObject, baseOCtx, attr, "ObjectNew", objectNewCtx),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).
        Alloc(storeVar, object, inMeth) :-
            VCall(base, attr, invo, inMeth),
            VarPointsTo(base, _, baseObject, baseOCtx),
            OutOfScopeIn(base, inMeth),
            AttrPointsTo(baseObject, baseOCtx, attr, "ObjectNew", objectNewCtx),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).

    // Then for VCall. When base does not point to anything in the current context, and it refers to a class
        IsClassFor(object, record(object, methCtx), classObject) :-
            VCall(base, attr, invo, inMeth),
            VarPointsTo(base, _, baseObject, baseOCtx),
            OutOfScopeIn(base, inMeth),
            ObjectIsClass(baseObject),
            IsParentTrans(baseObject, parentObject),
            AttrPointsTo(parentObject, _, attr, "ObjectNew", _),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).
        Alloc(storeVar, object, inMeth) :-
            VCall(base, attr, invo, inMeth),
            VarPointsTo(base, _, baseObject, baseOCtx),
            OutOfScopeIn(base, inMeth),
            ObjectIsClass(baseObject),
            IsParentTrans(baseObject, parentObject),
            AttrPointsTo(parentObject, _, attr, "ObjectNew", _),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).
        // Then for VCall. When base does not point to anything in the current context, and we look at the inherited
        // functions
        IsClassFor(object, record(object, methCtx), classObject) :-
            VCall(base, attr, invo, inMeth),
            VarPointsTo(base, _, baseObject, baseOCtx),
            OutOfScopeIn(base, inMeth),
            IsClassFor(baseObject, _, classForObject),
            IsParentTrans(classForObject, parentObject),
            AttrPointsTo(parentObject, _, attr, "ObjectNew", objectNewCtx),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).
        Alloc(storeVar, object, inMeth) :-
            VCall(base, attr, invo, inMeth),
            VarPointsTo(base, _, baseObject, baseOCtx),
            OutOfScopeIn(base, inMeth),
            IsClassFor(baseObject, _, classForObject),
            IsParentTrans(classForObject, parentObject),
            AttrPointsTo(parentObject, _, attr, "ObjectNew", objectNewCtx),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            ActualArg(invo, "0", clsVar),
            VarPointsTo(clsVar, methCtx, classObject, _),
            // Use Reachable to get the context in which it is allocated
            Reachable(inMeth, methCtx).

        /* Call the __new__ method of a class if there exist a SCall on the class,
        the next 3 have the same right side */
        // TODO: should do the same for all parent definitions of __new__
        Reachable(object, merge(classObject, empty_ctx, invo, callerCtx)) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, _),
            ObjectIsClass(classObject),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, _, "__new__", object, objectCtx),
            ObjectIsFunction(object),
            ClsVar(cls, object).

        CallGraph(invo, callerCtx, object, merge(classObject, empty_ctx, invo, callerCtx)) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, _),
            ObjectIsClass(classObject),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, _, "__new__", object, objectCtx),
            ObjectIsFunction(object),
            ClsVar(cls, object).

        VarPointsTo(cls, merge(classObject, empty_ctx, invo, callerCtx), classObject, empty_ctx) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, _),
            ObjectIsClass(classObject),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, _, "__new__", object, objectCtx),
            ObjectIsFunction(object),
            ClsVar(cls, object).

        /* Call the __new__ method of a class if there exist a SCall on the class,
        the next 3 have the same right side */
        // This time for when var in out of scope in the caller context
        Reachable(object, merge(classObject, empty_ctx, invo, callerCtx)) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, _, classObject, _),
            OutOfScopeIn(var, inMeth),
            ObjectIsClass(classObject),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, _, "__new__", object, objectCtx),
            ObjectIsFunction(object),
            ClsVar(cls, object).

        CallGraph(invo, callerCtx, object, merge(classObject, empty_ctx, invo, callerCtx)) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, _, classObject, _),
            OutOfScopeIn(var, inMeth),
            ObjectIsClass(classObject),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, _, "__new__", object, objectCtx),
            ObjectIsFunction(object),
            ClsVar(cls, object).

        VarPointsTo(cls, merge(classObject, empty_ctx, invo, callerCtx), classObject, empty_ctx) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, _, classObject, _),
            OutOfScopeIn(var, inMeth),
            ObjectIsClass(classObject),
            IsParentTrans(classObject, parentObject),
            AttrPointsTo(parentObject, _, "__new__", object, objectCtx),
            ObjectIsFunction(object),
            ClsVar(cls, object).

        // Infer call to __init__ on what is returned from __new__
        /* TODO: the calleeCtx not being the exact callee context of this call might be bad
        CallGraph(invo, callerCtx, initMeth, merge(classObject, empty_ctx, invo, callerCtx)),
        VarPointsTo(self, merge(classObject, empty_ctx, invo, callerCtx), returnObject, returnOCtx),
        Reachable(initMeth, merge(classObject, empty_ctx, invo, callerCtx)) :-
            SCall(var,invo,inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, callerCtx, classObject, _),
            SelfVar(self, initMeth),
            AttrPointsTo(classObject, _, "__init__", initMeth, initMethCtx),
            AttrPointsTo(classObject, _, "__init__", newMeth, newMethCtx),
            ClsVar(cls,newMeth),
            FormalReturn(newMeth, ret),
            VarPointsTo(ret, calleeCtx, returnObject, returnOCtx),
            VarPointsTo(cls, calleeCtx, clsObject, clsOCtx),
            IsClassFor(returnObject, returnOCtx, clsObject, callerCtx).
        */
        CallGraph(invo, callerCtx, initMeth, merge(classObject, empty_ctx, invo, callerCtx)) :-
            SCall(var,invo,inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, callerCtx, classObject, _),
            SelfVar(self, initMeth),
            AttrPointsTo(classObject, _, "__init__", initMeth, initMethCtx),
            AttrPointsTo(classObject, _, "__init__", newMeth, newMethCtx),
            ClsVar(cls,newMeth),
            FormalReturn(newMeth, ret),
            VarPointsTo(ret, calleeCtx, returnObject, returnOCtx),
            VarPointsTo(cls, calleeCtx, clsObject, clsOCtx),
            IsClassFor(returnObject, returnOCtx, clsObject).

        VarPointsTo(self, merge(classObject, empty_ctx, invo, callerCtx), returnObject, returnOCtx) :-
            SCall(var,invo,inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, callerCtx, classObject, _),
            SelfVar(self, initMeth),
            AttrPointsTo(classObject, _, "__init__", initMeth, initMethCtx),
            AttrPointsTo(classObject, _, "__init__", newMeth, newMethCtx),
            ClsVar(cls,newMeth),
            FormalReturn(newMeth, ret),
            VarPointsTo(ret, calleeCtx, returnObject, returnOCtx),
            VarPointsTo(cls, calleeCtx, clsObject, clsOCtx),
            IsClassFor(returnObject, returnOCtx, clsObject).

        Reachable(initMeth, merge(classObject, empty_ctx, invo, callerCtx)) :-
            SCall(var,invo,inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, callerCtx, classObject, _),
            SelfVar(self, initMeth),
            AttrPointsTo(classObject, _, "__init__", initMeth, initMethCtx),
            AttrPointsTo(classObject, _, "__init__", newMeth, newMethCtx),
            ClsVar(cls,newMeth),
            FormalReturn(newMeth, ret),
            VarPointsTo(ret, calleeCtx, returnObject, returnOCtx),
            VarPointsTo(cls, calleeCtx, clsObject, clsOCtx),
            IsClassFor(returnObject, returnOCtx, clsObject).

        // Infer call to __init__ on what is returned from __new__
        /* TODO: the calleeCtx not being the exact callee context of this call might be bad
        This one for when var is defined out of scope
        CallGraph(invo, callerCtx, initMeth, merge(classObject, empty_ctx, invo, callerCtx)),
        VarPointsTo(self, merge(classObject, empty_ctx, invo, callerCtx), returnObject, returnOCtx),
        Reachable(initMeth, merge(classObject, empty_ctx, invo, callerCtx)) :-
            SCall(var,invo,inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, _, classObject, _),
            OutOfScopeIn(var, inMeth),
            SelfVar(self, initMeth),
            AttrPointsTo(classObject, _, "__init__", initMeth, initMethCtx),
            AttrPointsTo(classObject, _, "__init__", newMeth, newMethCtx),
            ClsVar(cls,newMeth),
            FormalReturn(newMeth, ret),
            VarPointsTo(ret, calleeCtx, returnObject, returnOCtx),
            VarPointsTo(cls, calleeCtx, clsObject, clsOCtx),
            IsClassFor(returnObject, returnOCtx, clsObject).
        */
        CallGraph(invo, callerCtx, initMeth, merge(classObject, empty_ctx, invo, callerCtx)) :-
            SCall(var,invo,inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, _, classObject, _),
            OutOfScopeIn(var, inMeth),
            SelfVar(self, initMeth),
            AttrPointsTo(classObject, _, "__init__", initMeth, initMethCtx),
            AttrPointsTo(classObject, _, "__init__", newMeth, newMethCtx),
            ClsVar(cls,newMeth),
            FormalReturn(newMeth, ret),
            VarPointsTo(ret, calleeCtx, returnObject, returnOCtx),
            VarPointsTo(cls, calleeCtx, clsObject, clsOCtx),
            IsClassFor(returnObject, returnOCtx, clsObject).

        VarPointsTo(self, merge(classObject, empty_ctx, invo, callerCtx), returnObject, returnOCtx) :-
            SCall(var,invo,inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, _, classObject, _),
            OutOfScopeIn(var, inMeth),
            SelfVar(self, initMeth),
            AttrPointsTo(classObject, _, "__init__", initMeth, initMethCtx),
            AttrPointsTo(classObject, _, "__init__", newMeth, newMethCtx),
            ClsVar(cls,newMeth),
            FormalReturn(newMeth, ret),
            VarPointsTo(ret, calleeCtx, returnObject, returnOCtx),
            VarPointsTo(cls, calleeCtx, clsObject, clsOCtx),
            IsClassFor(returnObject, returnOCtx, clsObject).

        Reachable(initMeth, merge(classObject, empty_ctx, invo, callerCtx)) :-
            SCall(var,invo,inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, _, classObject, _),
            OutOfScopeIn(var, inMeth),
            SelfVar(self, initMeth),
            AttrPointsTo(classObject, _, "__init__", initMeth, initMethCtx),
            AttrPointsTo(classObject, _, "__init__", newMeth, newMethCtx),
            ClsVar(cls,newMeth),
            FormalReturn(newMeth, ret),
            VarPointsTo(ret, calleeCtx, returnObject, returnOCtx),
            VarPointsTo(cls, calleeCtx, clsObject, clsOCtx),
            IsClassFor(returnObject, returnOCtx, clsObject).

        /* We always make an allocation, as if object.new was called
        Alloc(storeVar, object, inMeth),
        IsClassFor(object, record(object, callerCtx), classObject) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, _),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth).
        */
        Alloc(storeVar, object, inMeth) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, _),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth).

        IsClassFor(object, record(object, callerCtx), classObject) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, _),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth).

        /* We always make an allocation, as if object.new was called
            This one for when var only points to something out of scope
        Alloc(storeVar, object, inMeth),
        IsClassFor(object, record(object, callerCtx), classObject) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, _, classObject, _),
            OutOfScopeIn(var, inMeth),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth).
        */
        Alloc(storeVar, object, inMeth) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, _, classObject, _),
            OutOfScopeIn(var, inMeth),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth).

        IsClassFor(object, record(object, callerCtx), classObject) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, _, classObject, _),
            OutOfScopeIn(var, inMeth),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth).

        /* And we need to always infer a call to init on this newly allocated object
            Added a VarPointsTo requirement to get the context of the newly allocated object
        CallGraph(invo, callerCtx, initMethod, merge(initMethod, initMCtx, invo, callerCtx)),
        Reachable(initMethod, merge(initMethod, initMCtx, invo, callerCtx)),
        VarPointsTo(self, merge(initMethod, initMCtx, invo, callerCtx), object, objectCtx):-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, _),
            IsParentTrans(classObject, parentObject),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            VarPointsTo(storeVar, callerCtx, object, objectCtx),
            AttrPointsTo(parentObject, _, "__init__", initMethod, initMCtx),
            ObjectIsFunction(initMethod),
            SelfVar(self, initMethod).
        */
        CallGraph(invo, callerCtx, initMethod, merge(initMethod, initMCtx, invo, callerCtx)) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, _),
            IsParentTrans(classObject, parentObject),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            VarPointsTo(storeVar, callerCtx, object, objectCtx),
            AttrPointsTo(parentObject, _, "__init__", initMethod, initMCtx),
            ObjectIsFunction(initMethod),
            SelfVar(self, initMethod).

        Reachable(initMethod, merge(initMethod, initMCtx, invo, callerCtx)) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, _),
            IsParentTrans(classObject, parentObject),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            VarPointsTo(storeVar, callerCtx, object, objectCtx),
            AttrPointsTo(parentObject, _, "__init__", initMethod, initMCtx),
            ObjectIsFunction(initMethod),
            SelfVar(self, initMethod).

        VarPointsTo(self, merge(initMethod, initMCtx, invo, callerCtx), object, objectCtx):-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, callerCtx, classObject, _),
            IsParentTrans(classObject, parentObject),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            VarPointsTo(storeVar, callerCtx, object, objectCtx),
            AttrPointsTo(parentObject, _, "__init__", initMethod, initMCtx),
            ObjectIsFunction(initMethod),
            SelfVar(self, initMethod).

        /* And we need to always infer a call to init on this newly allocated object
            Added a VarPointsTo requirement to get the context of the newly allocated object
            For when var points to something out of scope
        CallGraph(invo, callerCtx, initMethod, merge(initMethod, initMCtx, invo, callerCtx)),
        Reachable(initMethod, merge(initMethod, initMCtx, invo, callerCtx)),
        VarPointsTo(self, merge(initMethod, initMCtx, invo, callerCtx), object, objectCtx):-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, _, classObject, _),
            OutOfScopeIn(var, inMeth
            IsParentTrans(classObject, parentObject),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            VarPointsTo(storeVar, callerCtx, object, objectCtx),
            AttrPointsTo(parentObject, _, "__init__", initMethod, initMCtx),
            ObjectIsFunction(initMethod),
            SelfVar(self, initMethod).
        */
        CallGraph(invo, callerCtx, initMethod, merge(initMethod, initMCtx, invo, callerCtx)) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, _, classObject, _),
            OutOfScopeIn(var, inMeth),
            IsParentTrans(classObject, parentObject),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            VarPointsTo(storeVar, callerCtx, object, objectCtx),
            AttrPointsTo(parentObject, _, "__init__", initMethod, initMCtx),
            ObjectIsFunction(initMethod),
            SelfVar(self, initMethod).

        Reachable(initMethod, merge(initMethod, initMCtx, invo, callerCtx)) :-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, _, classObject, _),
            OutOfScopeIn(var, inMeth),
            IsParentTrans(classObject, parentObject),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            VarPointsTo(storeVar, callerCtx, object, objectCtx),
            AttrPointsTo(parentObject, _, "__init__", initMethod, initMCtx),
            ObjectIsFunction(initMethod),
            SelfVar(self, initMethod).

        VarPointsTo(self, merge(initMethod, initMCtx, invo, callerCtx), object, objectCtx):-
            Reachable(inMeth, callerCtx),
            SCall(var, invo, inMeth),
            VarPointsTo(var, _, classObject, _),
            OutOfScopeIn(var, inMeth),
            IsParentTrans(classObject, parentObject),
            ObjectIsClass(classObject),
            PotentialAllocationSite(invo, storeVar, object, inMeth),
            VarPointsTo(storeVar, callerCtx, object, objectCtx),
            AttrPointsTo(parentObject, _, "__init__", initMethod, initMCtx),
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


        //Derive actual parents from the names given statically in the constructors
        IsParentFor(object, parentObject) :-
            IsBaseFor(object , var),
            VarPointsTo(var, _, parentObject, _),
            ObjectIsClass(parentObject).

        /* Handle super. We do not care about in which context it happens, since if super is bound
            to another variable the call will not work as usual */
        VarPointsTo(storeVar, callerCtx, parentObject, parentOCtx) :-
            ActualReturn(invo, storeVar),
            SCall(var, invo, inMeth),
            Reachable(inMeth, callerCtx),
            VarPointsTo(var, _, "OSuper", superCtx),
            ObjectIsClass(classObject),
            IsParentFor(classObject, parentObject),
            VarPointsTo(_,_,parentObject,parentOCtx),
            AttrPointsTo(classObject, _, attr, inMeth, _).


    }

def getFact(s: Str): #{Move, Alloc, Load,
  Store, VCall, SCall, ObjectIsFunction, PotentialAllocationSite, ObjectIsClass, IsClassFor[Str], SelfVar, ClsVar,
  IsBaseFor, IsParentFor, IsNewFor, IsParentTrans, FormalArg, ActualArg, FormalReturn,
  ActualReturn, VarPointsTo[Str, Str], CallGraph[Str], AttrPointsTo[Str],
   InterProcAssign[Str], Reachable[Str], OutOfScopeIn} =
    let parts = String.split(s, ", ");
    match (parts[0]) with {
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

def getFacts(l: List[Str]): #{Move, Alloc, Load,
  Store, VCall, SCall, ObjectIsFunction, PotentialAllocationSite, ObjectIsClass, IsClassFor[Str], SelfVar, ClsVar,
  IsBaseFor, IsParentFor, IsNewFor, IsParentTrans, FormalArg, ActualArg, FormalReturn,
  ActualReturn, VarPointsTo[Str, Str], CallGraph[Str], AttrPointsTo[Str],
   InterProcAssign[Str], Reachable[Str], OutOfScopeIn} =
    match l with {
        case Nil => #{ }
        case x :: xs => getFact(x) <+> getFacts(xs)
    }

def readMoveFacts(file: File): Result[#{Move, Alloc, Load,
  Store, VCall, SCall, ObjectIsFunction, PotentialAllocationSite, ObjectIsClass, IsClassFor[Str], SelfVar, ClsVar,
  IsBaseFor, IsParentFor, IsNewFor, IsParentTrans, FormalArg, ActualArg, FormalReturn,
  ActualReturn, VarPointsTo[Str, Str], CallGraph[Str], AttrPointsTo[Str],
   InterProcAssign[Str], Reachable[Str], OutOfScopeIn},
                                  IOError] =
    Result.map(getFacts, File.readLines(file))

def main(): #{ Move, Alloc, Load,
  Store, VCall, SCall, ObjectIsFunction, PotentialAllocationSite, ObjectIsClass, IsClassFor[Str], SelfVar, ClsVar,
  IsBaseFor, IsParentFor, IsNewFor, IsParentTrans, FormalArg, ActualArg, FormalReturn,
  ActualReturn, VarPointsTo[Str, Str], CallGraph[Str], AttrPointsTo[Str],
   InterProcAssign[Str], Reachable[Str], OutOfScopeIn} =
    let moveFile = File.new("output.csv");
    let rules = getRules(strMerge, strRecord, "");
    match readMoveFacts(moveFile) with {
        case Ok(facts) =>
            let result = solve (facts <+> rules);
            project VarPointsTo result
        case Err(_) => ??? // implement proper error handling.
    }