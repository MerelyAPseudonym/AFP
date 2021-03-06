(*  Title:      JinjaThreads/J/State.thy
    Author:     Tobias Nipkow, Andreas Lochbihler
*)

header {*
  \chapter{JinjaThreads source language}
  \isaheader{Program State} 
*}

theory State
imports
  "../Common/Heap"
begin


type_synonym
  'addr locals = "vname \<rightharpoonup> 'addr val"      -- "local vars, incl. params and ``this''"
type_synonym
  ('addr, 'heap) Jstate = "'heap \<times> 'addr locals"     -- "the heap and the local vars"

definition hp :: "'heap \<times> 'x \<Rightarrow> 'heap" where "hp \<equiv> fst"

definition lcl :: "'heap \<times> 'x \<Rightarrow> 'x" where "lcl \<equiv> snd"

lemma hp_conv [simp]: "hp (h, l) = h"
by(simp add: hp_def)

lemma lcl_conv [simp]: "lcl (h, l) = l"
by(simp add: lcl_def)

end
