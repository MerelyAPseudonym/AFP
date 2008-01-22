(*  ID:         $Id: CertDlo.thy,v 1.2 2008-01-11 15:22:13 lsf37 Exp $
    Author:     Tobias Nipkow, 2007

A simple certificate based checker for q-free dlo formulae.
Certificate is cycle.
*)

theory CertDlo
imports QEdlo
begin

fun cyclerec :: "nat \<Rightarrow> nat \<Rightarrow> atom list \<Rightarrow> bool" where
"cyclerec i j [] = (i=j)" |
"cyclerec i j (Less m n # fs) = (j=m & cyclerec i n fs)" |
"cyclerec i j (Eq m n # fs) = (if j=m then cyclerec i n fs
                               else if j=n then cyclerec i m fs else False)" |
"cyclerec i j fs = False"

definition cycle :: "atom list \<Rightarrow> nat list \<Rightarrow> bool" where
"cycle fs is =
 ((\<forall>i\<in>set is. i < length fs) \<and>
  (case map (nth fs) is of Less i j # fs' \<Rightarrow> cyclerec i j fs' | _ \<Rightarrow> False))"

definition
"cyclic_dnf ass = (EX iss. list_all2 cycle ass iss)"

lemma refute_I:
  "~ Logic.interpret h (Neg f) e \<Longrightarrow> Logic.interpret h f e"
by simp

lemma cyclerecD: fixes xs :: "'a :: dlo list" shows
 "\<lbrakk> cyclerec i j as; xs!i < xs!j\<rbrakk> \<Longrightarrow> \<exists>a\<in>set as. \<not> I\<^isub>d\<^isub>l\<^isub>o a xs"
apply(induct as arbitrary: j)
 apply (simp)
apply(case_tac a)
apply(auto split:split_if_asm)
done

lemma cycleD: fixes xs :: "'a :: dlo list" shows
 "cycle as is \<Longrightarrow> \<not> DLO.I (list_conj (map Atom as)) xs"
apply rule
apply (simp add:cycle_def map_eq_Cons_conv split:list.splits atom.splits)
apply auto
apply(drule_tac xs = xs in cyclerecD)
apply(drule_tac x = "as!z" in bspec)
apply (erule nth_mem)
apply fastsimp
apply fastsimp
done

lemma cyclic_dnfD: "qfree f \<Longrightarrow> cyclic_dnf (dnf(DLO.nnf f)) \<Longrightarrow> ~DLO.I f xs"
apply(subst DLO.I_nnf[unfolded nnf_def, symmetric])
apply(subst DLO.I_dnf[symmetric])
apply(erule DLO.nqfree_nnf[unfolded nnf_def])
apply(auto simp add:cyclic_dnf_def list_all2_def in_set_conv_nth)
apply(drule_tac x="(dnf(DLO.nnf f) ! i, iss!i)" in bspec)
apply (auto simp:set_zip)
apply(drule_tac xs=xs in cycleD)
apply auto
done

end