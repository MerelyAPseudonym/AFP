(*  Title:      Well-Quasi-Orders
    Author:     Christian Sternagel <c-sterna@jaist.ac.jp>
    Maintainer: Christian Sternagel
    License:    LGPL
*)

header {* A Typeclass for Well-Quasi-Orders *}

theory Wqo_Class
imports Well_Quasi_Orders
begin

text {*In a well-quasi-order (wqo) every infinite sequence is good.*}
class wqo = preorder +
  assumes good: "goodp (op \<le>) f"

lemma wqo_on_UNIV_conv:
  "wqo_on P UNIV \<longleftrightarrow> class.wqo P (\<lambda>x y. P x y \<and> \<not> P y x)"
  unfolding wqo_on_def class.wqo_def class.preorder_def class.wqo_axioms_def
  by (auto simp: conversep_iff[abs_def] reflp_on_def transp_on_def)

subsection {* Pairs are Well-Quasi-Ordered *}

text {*If types @{typ "'a"} and @{typ "'b"} are well-quasi-ordered by @{text "P"}
and @{text "Q"}, then pairs of type @{typ "'a \<times> 'b"} are well-quasi-ordered by
the pointwise combination of @{text P} and @{text Q}.*}

instantiation prod :: (wqo, wqo) wqo
begin
definition "p \<le> q \<longleftrightarrow> fst p \<le> fst q \<and> snd p \<le> snd q"
definition "(p :: 'a \<times> 'b) < q \<longleftrightarrow> p \<le> q \<and> \<not> (q \<le> p)"

instance proof (rule wqo_class.intro)
  have 1: "wqo_on (op \<le>) (UNIV :: 'a set)"
    using order_trans and good
    by (auto simp: wqo_on_UNIV_conv class.wqo_def class.wqo_axioms_def class.preorder_def)
  have 2: "wqo_on (op \<le>) (UNIV :: 'b set)"
    using order_trans and good
    by (auto simp: wqo_on_UNIV_conv class.wqo_def class.wqo_axioms_def class.preorder_def)
  from wqo_on_Sigma[OF 1 2]
    have "wqo_on (op \<le>) (UNIV :: ('a \<times> 'b) set)"
      by (auto simp: less_eq_prod_def[abs_def] split_def prod_le_def)
  hence "class.wqo (op \<le> :: 'a \<times> 'b \<Rightarrow> 'a \<times> 'b \<Rightarrow> bool) (op <)"
    unfolding wqo_on_UNIV_conv less_prod_def[abs_def] .
  thus "class.wqo_axioms (op \<le> :: 'a \<times> 'b \<Rightarrow> 'a \<times> 'b \<Rightarrow> bool)" by (auto simp: class.wqo_def)
next
  show "OFCLASS ('a \<times> 'b, preorder_class)"
    by (intro_classes, auto simp: less_prod_def less_eq_prod_def)
       (blast intro: order_trans)+
qed
end


subsection {* Lists are Well-Quasi-Ordered *}

text {*If the type @{typ "'a"} is well-quasi-ordered by @{text "P"}, then
lists of type @{typ "'a list"} are well-quasi-ordered by
@{term "\<lambda>xs ys. set_le P (set xs) (set ys)"}.*}

instantiation list :: (wqo) wqo
begin
definition "xs \<le> ys \<longleftrightarrow> set_le (op \<le>) (set xs) (set ys)"
definition "(xs :: 'a list) < ys \<longleftrightarrow> xs \<le> ys \<and> \<not> (ys \<le> xs)"

instance proof (rule wqo_class.intro)
  let ?P = "op \<le> :: 'a \<Rightarrow> 'a \<Rightarrow> bool"
  let ?P' = "op \<le> :: 'a list \<Rightarrow> 'a list \<Rightarrow> bool"
  have "class.wqo ?P (op <)" ..
  hence wqo: "wqo_on ?P UNIV"
    unfolding wqo_on_UNIV_conv less_le_not_le[abs_def] .
  from wqo_on_finite_subsets[OF this]
    have "wqo_on (set_le ?P) {set xs | xs. True}"
    unfolding set_finite_conv by auto
  hence "wqo_on ?P' UNIV"
    using `wqo_on ?P UNIV`
    unfolding wqo_on_def
    unfolding less_eq_list_def[abs_def]
    unfolding reflp_on_set_conv transp_on_set_conv
    using goodp_set_le_set[of ?P]
    by auto
  hence "class.wqo ?P' (op <)"
    unfolding wqo_on_UNIV_conv less_list_def[abs_def] .
  thus "class.wqo_axioms ?P'" by (auto simp: class.wqo_def)

  from reflp_on_set_le_Pow[OF wqo_on_imp_reflp_on[OF wqo]]
    have "reflp_on (set_le ?P) {set xs | xs. True}"
    unfolding set_finite_conv unfolding reflp_on_def by auto
  hence refl: "reflp_on ?P' UNIV"
    unfolding reflp_on_def less_eq_list_def by auto

  from transp_on_set_le_Pow[OF wqo_on_imp_transp_on[OF wqo]]
    have "transp_on (set_le ?P) {set xs | xs. True}"
    unfolding set_finite_conv transp_on_def by blast
  hence trans: "transp_on ?P' UNIV"
    unfolding transp_on_def less_eq_list_def by blast
  show "OFCLASS ('a list, preorder_class)"
    by (intro_classes, simp add: less_list_def)
       (insert refl, unfold reflp_on_def, force,
        insert trans, unfold transp_on_def, blast)
qed
end

end
