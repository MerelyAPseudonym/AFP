(*  Title:       Executable Matrix Operations on Matrices of Arbitrary Dimensions
    Author:      Christian Sternagel <christian.sternagel@uibk.ac.at>
                 René Thiemann       <rene.thiemann@uibk.ac.at>
    Maintainer:  Christian Sternagel and René Thiemann
    License:     LGPL
*)

(*
Copyright 2010 Christian Sternagel, René Thiemann

This file is part of IsaFoR/CeTA.

IsaFoR/CeTA is free software: you can redistribute it and/or modify it under the
terms of the GNU Lesser General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

IsaFoR/CeTA is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along
with IsaFoR/CeTA. If not, see <http://www.gnu.org/licenses/>.
*)

header {* Utility Functions and Lemmas *}

theory Utility
imports Main
begin

subsection {* Miscellaneous *}

lemma infinite_imp_elem: "\<not> finite A \<Longrightarrow> \<exists> x. x \<in> A"
  by (cases "A = {}", auto)

lemma inf_pigeonhole_principle:
  assumes "\<forall>k::nat. \<exists>i<n::nat. f k i"
  shows "\<exists>i<n. \<forall>k. \<exists>k'\<ge>k. f k' i"
proof -
  have nfin: "~ finite (UNIV :: nat set)" by auto
  have fin: "finite ({i. i < n})" by auto
  from pigeonhole_infinite_rel[OF nfin fin] assms
  obtain i where i: "i < n" and nfin: "\<not> finite {a. f a i}" by auto
  show ?thesis 
  proof (intro exI conjI, rule i, intro allI)
    fix k
    have "finite {a. f a i \<and> a < k}" by auto
    with nfin have "\<not> finite ({a. f a i} - {a. f a i \<and> a < k})" by auto
    from infinite_imp_elem[OF this]
    obtain a where "f a i" and "a \<ge> k" by auto
    thus "\<exists> k' \<ge> k. f k' i" by force
  qed
qed

lemma map_nth_Suc: "map f [0 ..< Suc n] = f 0 # map (\<lambda> i. f (Suc i)) [0 ..< n]"
  by (induct n arbitrary: f, auto)

lemma all_Suc_conv:
  "(\<forall>i<Suc n. P i) \<longleftrightarrow> P 0 \<and> (\<forall>i<n. P (Suc i))" (is "?l = ?r")
proof
  assume ?l thus ?r by auto
next
  assume ?r show ?l
  proof (intro allI impI)
    fix i
    assume "i < Suc n"
    with `?r` show "P i" by (cases i, auto)
  qed
qed

lemma ex_Suc_conv:
  "(\<exists>i<Suc n. P i) \<longleftrightarrow> P 0 \<or> (\<exists>i<n. P (Suc i))" (is "?l = ?r")
  using all_Suc_conv[of n "\<lambda>i. \<not> P i"] by blast

fun sorted_list_subset :: "'a :: linorder list \<Rightarrow> 'a list \<Rightarrow> 'a option" where
  "sorted_list_subset (a # as) (b # bs) = 
    (if a = b then sorted_list_subset as (b # bs)
     else if a > b then sorted_list_subset (a # as) bs
     else Some a)"
| "sorted_list_subset [] _ = None"
| "sorted_list_subset (a # _) [] = Some a"
   
lemma sorted_list_subset:
  assumes "sorted as" and "sorted bs"
  shows "(sorted_list_subset as bs = None) = (set as \<subseteq> set bs)"
using assms 
proof (induct rule: sorted_list_subset.induct)
  case (2 bs)
  thus ?case by auto
next
  case (3 a as)
  thus ?case by auto
next
  case (1 a as b bs)
  from 1(3) have sas: "sorted as" and a: "\<And> a'. a' \<in> set as \<Longrightarrow> a \<le> a'" unfolding linorder_class.sorted.simps[of "a # as"] by auto
  from 1(4) have sbs: "sorted bs" and b: "\<And> b'. b' \<in> set bs \<Longrightarrow> b \<le> b'" unfolding linorder_class.sorted.simps[of "b # bs"] by auto
  show ?case
  proof (cases "a = b")
    case True
    from 1(1)[OF this sas 1(4)] True show ?thesis by auto
  next
    case False note oFalse = this
    show ?thesis 
    proof (cases "a > b")
      case True
      with a b have "b \<notin> set as" by force
      with 1(2)[OF False True 1(3) sbs] False True show ?thesis by auto
    next
      case False
      with oFalse have "a < b" by auto
      with a b have "a \<notin> set bs" by force
      with oFalse False show ?thesis by auto
    qed
  qed
qed

lemma zip_nth_conv: "length xs = length ys \<Longrightarrow> zip xs ys = map (\<lambda> i. (xs ! i, ys ! i)) [0 ..< length ys]"
proof (induct xs arbitrary: ys, simp)
  case (Cons x xs)
  then obtain y yys where ys: "ys = y # yys" by (cases ys, auto)
  with Cons have len: "length xs = length yys" by simp
  show ?case unfolding ys 
    by (simp del: upt_Suc add: map_nth_Suc, unfold Cons(1)[OF len], simp) 
qed

lemma nth_map_conv:
  assumes "length xs = length ys"
    and "\<forall>i<length xs. f (xs ! i) = g (ys ! i)"
  shows "map f xs = map g ys"
using assms
proof (induct xs arbitrary: ys)
  case (Cons x xs) thus ?case
  proof (induct ys)
    case (Cons y ys)
    have "\<forall>i<length xs. f (xs ! i) = g (ys ! i)"
    proof (intro allI impI)
      fix i assume "i < length xs" thus "f (xs ! i) = g (ys ! i)" using Cons(4) by force
    qed
    with Cons show ?case by auto
  qed simp
qed simp

lemma listsum_0: "\<lbrakk>\<And> x. x \<in> set xs \<Longrightarrow> x = 0\<rbrakk> \<Longrightarrow> listsum xs = 0"
  by (induct xs, auto)

lemma foldr_foldr_concat: "foldr (foldr f) m a = foldr f (concat m) a"
proof (induct m arbitrary: a)
  case Nil show ?case by simp
next
  case (Cons v m a)
  show ?case
    unfolding concat.simps foldr_Cons o_def Cons
    unfolding foldr_append by simp
qed

lemma listsum_double_concat: 
  fixes f :: "'b \<Rightarrow> 'c \<Rightarrow> 'a :: comm_monoid_add" and g as bs
  shows "listsum (concat (map (\<lambda> i. map (\<lambda> j. f i j + g i j) as) bs))
      = listsum (concat (map (\<lambda> i. map (\<lambda> j. f i j) as) bs)) + 
        listsum (concat (map (\<lambda> i. map (\<lambda> j. g i j) as) bs))"
proof (induct bs)
  case Nil thus ?case by simp
next
  case (Cons b bs)
  have id: "(\<Sum>j\<leftarrow>as. f b j + g b j) = listsum (map (f b) as) + listsum (map (g b) as)"
    by (induct as, auto simp: ac_simps)
  show ?case unfolding map.simps concat.simps listsum_append
    unfolding Cons
    unfolding id 
    by (simp add: ac_simps)
qed


end