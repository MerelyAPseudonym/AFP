(*  Title:      HOL/MicroJava/BV/Typing_Framework.thy
    ID:         $Id: Typing_Framework.thy,v 1.4 2008-07-25 15:07:17 fhaftmann Exp $
    Author:     Tobias Nipkow
    Copyright   2000 TUM
*)

header {* \isaheader{Typing and Dataflow Analysis Framework} *}

theory Typing_Framework imports Semilattices begin

text {* 
  The relationship between dataflow analysis and a welltyped-instruction predicate. 
*}
types
  's step_type = "nat \<Rightarrow> 's \<Rightarrow> (nat \<times> 's) list"

definition stable :: "'s ord \<Rightarrow> 's step_type \<Rightarrow> 's list \<Rightarrow> nat \<Rightarrow> bool"
where
  "stable r step \<tau>s p \<equiv> \<forall>(q,\<tau>) \<in> set (step p (\<tau>s!p)). \<tau> \<sqsubseteq>\<^sub>r \<tau>s!q"

definition stables :: "'s ord \<Rightarrow> 's step_type \<Rightarrow> 's list \<Rightarrow> bool"
where
  "stables r step \<tau>s \<equiv> \<forall>p < size \<tau>s. stable r step \<tau>s p"

definition wt_step :: "'s ord \<Rightarrow> 's \<Rightarrow> 's step_type \<Rightarrow> 's list \<Rightarrow> bool"
where
  "wt_step r T step \<tau>s \<equiv> \<forall>p<size \<tau>s. \<tau>s!p \<noteq> T \<and> stable r step \<tau>s p"

definition is_bcv :: "'s ord \<Rightarrow> 's \<Rightarrow> 's step_type \<Rightarrow> nat \<Rightarrow> 's set \<Rightarrow> ('s list \<Rightarrow> 's list) \<Rightarrow> bool"
where
  "is_bcv r T step n A bcv \<equiv> \<forall>\<tau>s\<^isub>0 \<in> list n A.
  (\<forall>p<n. (bcv \<tau>s\<^isub>0)!p \<noteq> T) = (\<exists>\<tau>s \<in> list n A. \<tau>s\<^isub>0 [\<sqsubseteq>\<^sub>r] \<tau>s \<and> wt_step r T step \<tau>s)"

end
