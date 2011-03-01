(*  Title:      HOL/MicroJava/J/Decl.thy
    ID:         $Id: Decl.thy,v 1.7 2008-06-24 22:23:29 makarius Exp $
    Author:     David von Oheimb
    Copyright   1999 Technische Universitaet Muenchen
*)

header {* \isaheader{Class Declarations and Programs} *}

theory Decl imports Type begin

type_synonym 
  fdecl    = "vname \<times> ty"        -- "field declaration"
type_synonym
  'm mdecl = "mname \<times> ty list \<times> ty \<times> 'm"     -- {* method = name, arg.\ types, return type, body *}
type_synonym
  'm "class" = "cname \<times> fdecl list \<times> 'm mdecl list"       -- "class = superclass, fields, methods"
type_synonym
  'm cdecl = "cname \<times> 'm class"  -- "class declaration"
type_synonym
  'm prog  = "'m cdecl list"     -- "program"

(*<*)
translations
  (type) "fdecl"   <= (type) "vname \<times> ty"
  (type) "'c mdecl" <= (type) "mname \<times> ty list \<times> ty \<times> 'c"
  (type) "'c class" <= (type) "cname \<times> fdecl list \<times> ('c mdecl) list"
  (type) "'c cdecl" <= (type) "cname \<times> ('c class)"
  (type) "'c prog" <= (type) "('c cdecl) list"
(*>*)

definition "class" :: "'m prog \<Rightarrow> cname \<rightharpoonup> 'm class"
where
  "class  \<equiv>  map_of"

definition is_class :: "'m prog \<Rightarrow> cname \<Rightarrow> bool"
where
  "is_class P C  \<equiv>  class P C \<noteq> None"

lemma finite_is_class: "finite {C. is_class P C}"

(*<*)
apply (unfold is_class_def class_def)
apply (fold dom_def)
apply (rule finite_dom_map_of)
done
(*>*)

definition is_type :: "'m prog \<Rightarrow> ty \<Rightarrow> bool"
where
  "is_type P T  \<equiv>
  (case T of Void \<Rightarrow> True | Boolean \<Rightarrow> True | Integer \<Rightarrow> True | NT \<Rightarrow> True
   | Class C \<Rightarrow> is_class P C)"

lemma is_type_simps [simp]:
  "is_type P Void \<and> is_type P Boolean \<and> is_type P Integer \<and>
  is_type P NT \<and> is_type P (Class C) = is_class P C"
(*<*)by(simp add:is_type_def)(*>*)


abbreviation
  "types P == Collect (is_type P)"

end
