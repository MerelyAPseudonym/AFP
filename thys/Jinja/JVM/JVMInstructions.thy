(*  Title:      HOL/MicroJava/JVM/JVMInstructions.thy
    ID:         $Id: JVMInstructions.thy,v 1.1 2005-05-31 23:21:04 lsf37 Exp $
    Author:     Gerwin Klein
    Copyright   2000 Technische Universitaet Muenchen
*)

header {* \isaheader{Instructions of the JVM} *}


theory JVMInstructions = JVMState:


datatype 
  instr = Load nat                  -- "load from local variable"
        | Store nat                 -- "store into local variable"
        | Push val                  -- "push a value (constant)"
        | New cname                 -- "create object"
        | Getfield vname cname      -- "Fetch field from object"
        | Putfield vname cname      -- "Set field in object    "
        | Checkcast cname           -- "Check whether object is of given type"
        | Invoke mname nat          -- "inv. instance meth of an object"
        | Return                    -- "return from method"
        | Pop                       -- "pop top element from opstack"
        | IAdd                      -- "integer addition"
        | Goto int                  -- "goto relative address"
        | CmpEq                     -- "equality comparison"
        | IfFalse int               -- "branch if top of stack false"
        | Throw                     -- "throw top of stack as exception"

types
  bytecode = "instr list"

  ex_entry = "pc \<times> pc \<times> cname \<times> pc \<times> nat" 
  -- "start-pc, end-pc, exception type, handler-pc, remaining stack depth"

  ex_table = "ex_entry list"

  jvm_method = "nat \<times> nat \<times> bytecode \<times> ex_table"
   -- "max stacksize"
   -- "number of local variables. Add 1 + no. of parameters to get no. of registers"
   -- "instruction sequence"
   -- "exception handler table"

  jvm_prog = "jvm_method prog" 

end
