(*  ID:         $Id: Cooper.thy,v 1.2 2008-01-11 15:22:14 lsf37 Exp $
    Author:     Tobias Nipkow, 2007
*)

theory Cooper
imports PresArith
begin

subsection{*Cooper*}

text{* This section formalizes Cooper's algorithm~\cite{Cooper72}. *}

lemma set_atoms0_iff:
 "qfree \<phi> \<Longrightarrow> a : set(Z.atoms\<^isub>0 \<phi>) \<longleftrightarrow> a : atoms \<phi> \<and> hd_coeff a \<noteq> 0"
by(induct \<phi>) (auto split:split_if_asm)

fun hd_coeff1 :: "int \<Rightarrow> atom \<Rightarrow> atom" where
"hd_coeff1 m (Le i (k#ks)) =
   (if k=0 then Le i (k#ks)
    else let m' = m div (abs k) in Le (m'*i) (sgn k # (m' *\<^sub>s ks)))" |
"hd_coeff1 m (Dvd d i (k#ks)) =
   (if k=0 then Dvd d i (k#ks)
    else let m' = m div k in Dvd (m'*d) (m'*i) (1 # (m' *\<^sub>s ks)))" |
"hd_coeff1 m (NDvd d i (k#ks)) =
   (if k=0 then NDvd d i (k#ks)
    else let m' = m div k in NDvd (m'*d) (m'*i) (1 # (m' *\<^sub>s ks)))" |
"hd_coeff1 _ a = a"

definition
"hd_coeffs1 \<phi> =
 (let m = zlcms(map hd_coeff (Z.atoms\<^isub>0 \<phi>))
  in And (Atom(Dvd m 0 [1])) (map\<^bsub>fm\<^esub> (hd_coeff1 m) \<phi>))"

lemma I_hd_coeff1_mult: assumes "m>0"
shows "qfree \<phi> \<Longrightarrow> \<forall> a \<in> set(Z.atoms\<^isub>0 \<phi>). hd_coeff a dvd m \<Longrightarrow>
 Z.I (map\<^bsub>fm\<^esub> (hd_coeff1 m) \<phi>) (m*x#xs) = Z.I \<phi> (x#xs)"
proof(induct \<phi>)
  case (Atom a)
  show ?case
  proof (cases a)
    case (Le i ks)[simp]
    show ?thesis
    proof(cases ks)
      case Nil thus ?thesis by simp
    next
      case (Cons k ks')[simp]
      show ?thesis
      proof cases
	assume "k=0" thus ?thesis by simp
      next
	assume "k\<noteq>0"
	with Atom have "\<bar>k\<bar> dvd m" by(simp add:IntDiv.zdvd_abs1)
	let ?m' = "m div \<bar>k\<bar>"
	have "?m' > 0" using `\<bar>k\<bar> dvd m` pos_imp_zdiv_pos_iff `m>0` `k\<noteq>0`
	  by(simp add:zdvd_imp_le)
	have 1: "k*(x*?m') = sgn k * x * m"
	proof -
	  have "k*(x*?m') = (sgn k * abs k) * (x * ?m')"
	    by(simp only: mult_sgn_abs)
	  also have "\<dots> = sgn k * x * (abs k * ?m')" by simp
	  also have "\<dots> = sgn k * x * m"
	    using zdvd_mult_div_cancel[OF `\<bar>k\<bar> dvd m`] by(simp add:ring_simps)
	  finally show ?thesis .
	qed
	have "I\<^isub>Z (hd_coeff1 m a) (m*x#xs) \<longleftrightarrow>
              (i*?m' \<le> sgn k * m*x + ?m' * \<langle>ks',xs\<rangle>)"
	  using `k\<noteq>0` by(simp add: ring_simps iprod_assoc)
	also have "\<dots> \<longleftrightarrow> ?m'*i \<le> ?m' * (k*x + \<langle>ks',xs\<rangle>)" using 1
	  by(simp (no_asm_simp) add:ring_simps)
	also have "\<dots> \<longleftrightarrow> i \<le> k*x + \<langle>ks',xs\<rangle>" using `?m'>0`
	  by(simp add: mult_compare_simps)
	finally show ?thesis by(simp)
      qed
    qed
  next
    case (Dvd d i ks)[simp]
    show ?thesis
    proof(cases ks)
      case Nil thus ?thesis by simp
    next
      case (Cons k ks')[simp]
      show ?thesis
      proof cases
	assume "k=0" thus ?thesis by simp
      next
	assume "k\<noteq>0"
	with Atom have "k dvd m" by simp
	let ?m' = "m div k"
	have "?m' \<noteq> 0" using `k dvd m` zdiv_eq_0_iff `m>0` `k\<noteq>0`
	  by(simp add:linorder_not_less zdvd_imp_le)
	have 1: "k*(x*?m') = x * m"
	proof -
	  have "k*(x*?m') = x*(k*?m')" by(simp add:ring_simps)
	  also have "\<dots> = x*m" using zdvd_mult_div_cancel[OF `k dvd m`]
	    by(simp add:ring_simps)
	  finally show ?thesis .
	qed
	have "I\<^isub>Z (hd_coeff1 m a) (m*x#xs) \<longleftrightarrow>
              (?m'*d dvd ?m'*i + m*x + ?m' * \<langle>ks',xs\<rangle>)"
	  using `k\<noteq>0` by(simp add: ring_simps iprod_assoc)
	also have "\<dots> \<longleftrightarrow> ?m'*d dvd ?m' * (i + k*x + \<langle>ks',xs\<rangle>)" using 1
	  by(simp (no_asm_simp) add:ring_simps)
	also have "\<dots> \<longleftrightarrow> d dvd i + k*x + \<langle>ks',xs\<rangle>" using `?m'\<noteq>0` by(simp)
	finally show ?thesis by(simp add:ring_simps)
      qed
    qed
  next
    case (NDvd d i ks)[simp]
    show ?thesis
    proof(cases ks)
      case Nil thus ?thesis by simp
    next
      case (Cons k ks')[simp]
      show ?thesis
      proof cases
	assume "k=0" thus ?thesis by simp
      next
	assume "k\<noteq>0"
	with Atom have "k dvd m" by simp
	let ?m' = "m div k"
	have "?m' \<noteq> 0" using `k dvd m` zdiv_eq_0_iff `m>0` `k\<noteq>0`
	  by(simp add:linorder_not_less zdvd_imp_le)
	have 1: "k*(x*?m') = x * m"
	proof -
	  have "k*(x*?m') = x*(k*?m')" by(simp add:ring_simps)
	  also have "\<dots> = x*m" using zdvd_mult_div_cancel[OF `k dvd m`]
	    by(simp add:ring_simps)
	  finally show ?thesis .
	qed
	have "I\<^isub>Z (hd_coeff1 m a) (m*x#xs) \<longleftrightarrow>
              \<not>(?m'*d dvd ?m'*i + m*x + ?m' * \<langle>ks',xs\<rangle>)"
	  using `k\<noteq>0` by(simp add: ring_simps iprod_assoc)
	also have "\<dots> \<longleftrightarrow> \<not> ?m'*d dvd ?m' * (i + k*x + \<langle>ks',xs\<rangle>)" using 1
	  by(simp (no_asm_simp) add:ring_simps)
	also have "\<dots> \<longleftrightarrow> \<not> d dvd i + k*x + \<langle>ks',xs\<rangle>" using `?m'\<noteq>0` by(simp)
	finally show ?thesis by(simp add:ring_simps)
      qed
    qed
  qed
qed simp_all

lemma I_hd_coeffs1:
assumes "qfree \<phi>"
shows "(\<exists>x. Z.I (hd_coeffs1 \<phi>) (x#xs)) = (\<exists>x. Z.I \<phi> (x#xs))" (is "?L = ?R")
proof -
  let ?l = "zlcms(map hd_coeff (Z.atoms\<^isub>0 \<phi>))"
  have "?l>0" by(simp add: zlcms_pos set_atoms0_iff[OF `qfree \<phi>`])
  have "?L = (\<exists>x. ?l dvd x+0 \<and> Z.I (map\<^bsub>fm\<^esub> (hd_coeff1 ?l) \<phi>) (x#xs))"
    by(simp add:hd_coeffs1_def)
  also have "\<dots> = (\<exists>x. Z.I (map\<^bsub>fm\<^esub> (hd_coeff1 ?l) \<phi>) (?l*x#xs))"
    by(rule unity_coeff_ex[THEN meta_eq_to_obj_eq,symmetric])
  also have "\<dots> = ?R"
    by(simp add: I_hd_coeff1_mult[OF `?l>0` `qfree \<phi>`] dvd_zlcms)
  finally show ?thesis .
qed


fun min_inf :: "atom fm \<Rightarrow> atom fm" ("inf\<^isub>-") where
"inf\<^isub>- (And \<phi>\<^isub>1 \<phi>\<^isub>2) = and (inf\<^isub>- \<phi>\<^isub>1) (inf\<^isub>- \<phi>\<^isub>2)" |
"inf\<^isub>- (Or \<phi>\<^isub>1 \<phi>\<^isub>2) = or (inf\<^isub>- \<phi>\<^isub>1) (inf\<^isub>- \<phi>\<^isub>2)" |
"inf\<^isub>- (Atom(Le i (k#ks))) =
  (if k<0 then TrueF else if k>0 then FalseF else Atom(Le i (0#ks)))" |
"inf\<^isub>- \<phi> = \<phi>"


definition
"cooper\<^isub>1 \<phi> =
 (let as = Z.atoms\<^isub>0 \<phi>; d = zlcms(map divisor as); ls = lbounds as
  in or (Disj [0..d - 1] (\<lambda>n. subst n [] (inf\<^isub>- \<phi>)))
        (Disj ls (\<lambda>(i,ks).
           Disj [0..d - 1] (\<lambda>n. subst (i + n) (-ks) \<phi>))))"


lemma min_inf:
  "nqfree f \<Longrightarrow> \<forall>a\<in>set(Z.atoms\<^isub>0 f). hd_coeff_is1 a
   \<Longrightarrow> \<exists>x.\<forall>y<x. Z.I (inf\<^isub>- f) (y # xs) = Z.I f (y # xs)"
  (is "_ \<Longrightarrow> _ \<Longrightarrow> \<exists>x. ?P f x")
proof(induct f rule: min_inf.induct)
  case (3 i k ks)
  { assume "k=0" hence ?case using 3 by simp }
  moreover
  { assume "k= -1"
    hence "?P (Atom(Le i (k#ks))) (-i + \<langle>ks,xs\<rangle> - 1)" using 3 by auto
    hence ?case .. }
  moreover
  { assume "k=1"
    hence "?P (Atom(Le i (k#ks))) (i - \<langle>ks,xs\<rangle> - 1)" using 3 by auto
    hence ?case .. }
  ultimately show ?case using 3 by auto
next
  case (1 f1 f2)
  then obtain x1 x2 where "?P f1 x1" "?P f2 x2" by fastsimp+
  hence "?P (And f1 f2) (min x1 x2)" by simp
  thus ?case ..
next
  case (2 f1 f2)
  then obtain x1 x2 where "?P f1 x1" "?P f2 x2" by fastsimp+
  hence "?P (Or f1 f2) (min x1 x2)" by simp
  thus ?case ..
qed simp_all


lemma min_inf_repeats:
  "nqfree \<phi> \<Longrightarrow> \<forall>a\<in>set(Z.atoms\<^isub>0 \<phi>). divisor a dvd d \<Longrightarrow>
  Z.I (inf\<^isub>- \<phi>) ((x - k*d)#xs) = Z.I (inf\<^isub>- \<phi>) (x#xs)"
proof(induct \<phi> rule:min_inf.induct)
  case ("4_4" da i ks)
  show ?case
  proof (cases ks)
    case Nil thus ?thesis by simp
  next
    case (Cons j js)
    show ?thesis
    proof cases
      assume "j=0" thus ?thesis using Cons by simp
    next
      assume "j\<noteq>0"
      hence "da dvd d" using Cons "4_4" by simp
      hence "da dvd i + (j * x - j * (k * d) + \<langle>js,xs\<rangle>) \<longleftrightarrow>
             da dvd i + (j * x + \<langle>js,xs\<rangle>)"
      proof -
	have "da dvd i + (j * x - j * (k * d) + \<langle>js,xs\<rangle>) \<longleftrightarrow>
              da dvd (i + j*x + \<langle>js,xs\<rangle>) - (j*k)*d"
	  by(simp add: ring_simps)
	also have "\<dots> \<longleftrightarrow> da dvd i + j*x + \<langle>js,xs\<rangle>" using `da dvd d`
	  by (metis zdvd_zdiff zdvd_zdiffD zdvd_zmult zmult_commute)
	also have "\<dots> \<longleftrightarrow> da dvd i + (j * x + \<langle>js,xs\<rangle>)"
	  by(simp add: ring_simps)
	finally show ?thesis .
      qed
      then show ?thesis using Cons by (simp add:ring_distribs)
    qed
  qed
next
  case ("4_5" da i ks)
  show ?case
  proof (cases ks)
    case Nil thus ?thesis by simp
  next
    case (Cons j js)
    show ?thesis
    proof cases
      assume "j=0" thus ?thesis using Cons by simp
    next
      assume "j\<noteq>0"
      hence "da dvd d" using Cons "4_5" by simp
      hence "da dvd i + (j * x - j * (k * d) + \<langle>js,xs\<rangle>) \<longleftrightarrow>
             da dvd i + (j * x + \<langle>js,xs\<rangle>)"
      proof -
	have "da dvd i + (j * x - j * (k * d) + \<langle>js,xs\<rangle>) \<longleftrightarrow>
              da dvd (i + j*x + \<langle>js,xs\<rangle>) - (j*k)*d"
	  by(simp add: ring_simps)
	also have "\<dots> \<longleftrightarrow> da dvd i + j*x + \<langle>js,xs\<rangle>" using `da dvd d`
	  by (metis zdvd_zdiff zdvd_zdiffD zdvd_zmult zmult_commute)
	also have "\<dots> \<longleftrightarrow> da dvd i + (j * x + \<langle>js,xs\<rangle>)"
	  by(simp add: ring_simps)
	finally show ?thesis .
      qed
      then show ?thesis using Cons by (simp add:ring_distribs)
    qed
  qed
qed simp_all


lemma atoms_subset: "qfree f \<Longrightarrow> set(Z.atoms\<^isub>0(f::atom fm)) \<le> atoms f"
by (induct f) auto

(* copied from Amine *)
lemma \<beta>:
  "\<lbrakk> nqfree \<phi>;  \<forall>a\<in>set(Z.atoms\<^isub>0 \<phi>). hd_coeff_is1 a;
     \<forall>a\<in>set(Z.atoms\<^isub>0 \<phi>). divisor a dvd d; d > 0;
     \<not>(\<exists>j\<in>{0 .. d - 1}. \<exists>(i,ks) \<in> set(lbounds(Z.atoms\<^isub>0 \<phi>)).
         x = i - \<langle>ks,xs\<rangle> + j); Z.I \<phi> (x#xs) \<rbrakk>
  \<Longrightarrow> Z.I \<phi> ((x-d)#xs)"
proof(induct \<phi>)
  case (Atom a)
  show ?case
  proof (cases a)
    case (Le i js)
    show ?thesis
    proof (cases js)
      case Nil thus ?thesis using Le Atom by simp
    next
      case (Cons k ks) thus ?thesis using Le Atom
	by (auto simp:lbounds_def Ball_def split:split_if_asm) arith
    qed
  next
    case (Dvd m i js)
    show ?thesis
    proof (cases js)
      case Nil thus ?thesis using Dvd Atom by simp
    next
      case (Cons k ks)
      show ?thesis
      proof cases
	assume "k=0" thus ?thesis using Cons Dvd Atom by simp
      next
	assume "k\<noteq>0"
	hence "m dvd d" using Cons Dvd Atom by auto
	have "m dvd i + (x + \<langle>ks,xs\<rangle>) \<Longrightarrow> m dvd i + (x - d + \<langle>ks,xs\<rangle>)"
	  (is "?L \<Longrightarrow> _")
	proof -
	  assume ?L
	  hence "m dvd i + (x + \<langle>ks,xs\<rangle>) - d"
	    by (metis `m dvd d` zdvd_zdiff)
	  thus ?thesis by(simp add:ring_simps)
	qed
	thus ?thesis using Atom Dvd Cons by(auto split:split_if_asm)
      qed
    qed
  next
    case (NDvd m i js)
    show ?thesis
    proof (cases js)
      case Nil thus ?thesis using NDvd Atom by simp
    next
      case (Cons k ks)
      show ?thesis
      proof cases
	assume "k=0" thus ?thesis using Cons NDvd Atom by simp
      next
	assume "k\<noteq>0"
	hence "m dvd d" using Cons NDvd Atom by auto
	have "m dvd i + (x - d + \<langle>ks,xs\<rangle>) \<Longrightarrow> m dvd i + (x + \<langle>ks,xs\<rangle>)"
	  (is "?L \<Longrightarrow> _")
	proof -
	  assume ?L
	  hence "m dvd i + (x + \<langle>ks,xs\<rangle>) - d" by(simp add:ring_simps)
	  thus ?thesis by (metis `m dvd d` zdvd_zdiffD)
	qed
	thus ?thesis using Atom NDvd Cons by(auto split:split_if_asm)
      qed
    qed
  qed
qed force+


lemma periodic_finite_ex:
  assumes dpos: "(0::int) < d" and modd: "\<forall>x k. P x = P(x - k*d)"
  shows "(\<exists>x. P x) = (\<exists>j\<in>{0..d - 1}. P j)"
  (is "?LHS = ?RHS")
proof
  assume ?LHS
  then obtain x where P: "P x" ..
  have "x mod d = x - (x div d)*d"
    by(simp add:zmod_zdiv_equality mult_ac eq_diff_eq)
  hence Pmod: "P x = P(x mod d)" using modd by simp
  have "P(x mod d)" using dpos P Pmod by(simp add:pos_mod_sign pos_mod_bound)
  moreover have "x mod d : {0..d - 1}" using dpos by(auto simp:pos_mod_sign)
  ultimately show ?RHS ..
qed auto

lemma cpmi_eq: "(0::int) < D \<Longrightarrow> (\<exists>z. \<forall>x. x < z \<longrightarrow> (P x = P1 x))
\<Longrightarrow> \<forall>x.\<not>(\<exists>j\<in>{0..D - 1}. \<exists>b\<in>B. P(b+j)) \<longrightarrow> P (x) \<longrightarrow> P (x - D) 
\<Longrightarrow> \<forall>x. \<forall>k. P1 x = P1(x-k*D)
\<Longrightarrow> (\<exists>x. P(x)) = ((\<exists>j\<in>{0..D - 1}. P1(j)) \<or> (\<exists>j\<in>{0..D - 1}. \<exists>b\<in>B. P(b+j)))"
apply(rule iffI)
prefer 2
apply(drule minusinfinity)
apply assumption+
apply(fastsimp)
apply clarsimp
apply(subgoal_tac "\<And>k. 0\<le>k \<Longrightarrow> \<forall>x. P x \<longrightarrow> P (x - k*D)")
apply(frule_tac x = x and z=z in decr_lemma)
apply(subgoal_tac "P1(x - (\<bar>x - z\<bar> + 1) * D)")
prefer 2
apply(subgoal_tac "0 \<le> (\<bar>x - z\<bar> + 1)")
prefer 2 apply arith
 apply fastsimp
apply(drule (1)  periodic_finite_ex)
apply blast
apply(blast dest:decr_mult_lemma)
done


theorem cp_thm:
  assumes nq: "nqfree \<phi>"
  and u: "\<forall>a\<in>set(Z.atoms\<^isub>0 \<phi>). hd_coeff_is1 a"
  and d: "\<forall>a\<in>set(Z.atoms\<^isub>0 \<phi>). divisor a dvd d"
  and dp: "d > 0"
  shows "(\<exists>x. Z.I \<phi> (x#xs)) =
   (\<exists>j\<in>{0..d - 1}. Z.I (inf\<^isub>- \<phi>) (j#xs) \<or>
   (\<exists>(i,ks) \<in> set(lbounds(Z.atoms\<^isub>0 \<phi>)). Z.I \<phi> ((i - \<langle>ks,xs\<rangle> + j) # xs)))"
  (is "(\<exists>x. ?P (x)) = (\<exists> j\<in> ?D. ?M j \<or> (\<exists>(i,ks)\<in> ?B. ?P (?I i ks + j)))")
proof-
  from min_inf[OF nq u] have th: "\<exists>z.\<forall>x<z. ?P x = ?M x" by blast
  let ?B' = "{?I i ks |i ks. (i,ks) \<in> ?B}"
  have BB': "(\<exists>j\<in>?D. \<exists>(i,ks)\<in> ?B. ?P (?I i ks + j)) = (\<exists>j \<in> ?D. \<exists>b \<in> ?B'. ?P (b + j))" by auto
  hence th2: "\<forall> x. \<not> (\<exists> j \<in> ?D. \<exists> b \<in> ?B'. ?P ((b + j))) \<longrightarrow> ?P (x) \<longrightarrow> ?P ((x - d))"
    using \<beta>[OF nq u d dp, of _ xs] by(simp add:Bex_def) metis
  from min_inf_repeats[OF nq d]
  have th3: "\<forall> x k. ?M x = ?M (x-k*d)" by simp
  from cpmi_eq[OF dp th th2 th3] BB' show ?thesis by simp blast
qed

(* end of Amine *)

lemma qfree_min_inf[simp]: "qfree \<phi> \<Longrightarrow> qfree (inf\<^isub>- \<phi>)"
by (induct \<phi> rule:min_inf.induct) simp_all

lemma I_cooper\<^isub>1:
assumes norm: "\<forall>a\<in>atoms \<phi>. divisor a \<noteq> 0"
and hd: "\<forall>a\<in>set(Z.atoms\<^isub>0 \<phi>). hd_coeff_is1 a" and "nqfree \<phi>"
shows "Z.I (cooper\<^isub>1 \<phi>) xs = (\<exists>x. Z.I \<phi> (x#xs))"
proof -
  let ?as = "Z.atoms\<^isub>0 \<phi>"
  let ?d = "zlcms(map divisor ?as)"
  have "?d > 0" using norm atoms_subset[of \<phi>] `nqfree \<phi>`
    by(fastsimp intro:zlcms_pos)
  have alld: "\<forall>a\<in>set(Z.atoms\<^isub>0 \<phi>). divisor a dvd ?d" by(simp add:dvd_zlcms)
  from cp_thm[OF `nqfree \<phi>` hd alld `?d>0`]
  show ?thesis using `nqfree \<phi>`
    by (simp add:cooper\<^isub>1_def I_subst[symmetric] split_def ring_simps) blast
qed

lemma divisor_hd_coeff1_neq0:
  "qfree \<phi> \<Longrightarrow> a \<in> atoms \<phi> \<Longrightarrow> divisor a \<noteq> 0 \<Longrightarrow>
   divisor (hd_coeff1 (zlcms (map hd_coeff (Z.atoms\<^isub>0 \<phi>))) a) \<noteq> 0"
apply (case_tac a)

apply simp
apply(case_tac list) apply simp apply(simp split:split_if_asm)

apply simp
apply(case_tac list) apply simp
apply(clarsimp split:split_if_asm)
apply(subgoal_tac "a : set(map hd_coeff (Z.atoms\<^isub>0 \<phi>))")
 apply(subgoal_tac "\<forall>i\<in>set(map hd_coeff (Z.atoms\<^isub>0 \<phi>)). i \<noteq> 0")
  apply (metis dvd_zlcms mult_eq_0_iff zdvd_mult_div_cancel zlcms0_iff)
 apply (simp add:set_atoms0_iff)
apply(fastsimp simp:image_def set_atoms0_iff Bex_def)

apply simp
apply(case_tac list) apply simp
apply(clarsimp split:split_if_asm)
apply(subgoal_tac "a : set(map hd_coeff (Z.atoms\<^isub>0 \<phi>))")
 apply(subgoal_tac "\<forall>i\<in>set(map hd_coeff (Z.atoms\<^isub>0 \<phi>)). i \<noteq> 0")
  apply (metis dvd_zlcms mult_eq_0_iff zdvd_mult_div_cancel zlcms0_iff)
 apply (simp add:set_atoms0_iff)
apply(fastsimp simp:image_def set_atoms0_iff Bex_def)
done

lemma hd_coeff_is1_hd_coeff1:
  "hd_coeff (hd_coeff1 m a) \<noteq> 0 \<longrightarrow> hd_coeff_is1 (hd_coeff1 m a)"
by (induct a rule: hd_coeff1.induct) (simp_all add:zsgn_def)

lemma I_cooper1_hd_coeffs1: "Z.normal \<phi> \<Longrightarrow> nqfree \<phi>
       \<Longrightarrow> Z.I (cooper\<^isub>1(hd_coeffs1 \<phi>)) xs = (\<exists>x. Z.I \<phi> (x # xs))"
apply(simp add:Z.normal_def)
apply(subst I_cooper\<^isub>1)
   apply(clarsimp simp:hd_coeffs1_def image_def set_atoms0_iff divisor_hd_coeff1_neq0)
  apply (clarsimp simp:hd_coeffs1_def qfree_map_fm set_atoms0_iff
                     hd_coeff_is1_hd_coeff1)
 apply(simp add:hd_coeffs1_def nqfree_map_fm)
apply(simp add: I_hd_coeffs1)
done

definition "cooper = Z.lift_nnf_qe (cooper\<^isub>1 \<circ> hd_coeffs1)"

lemma qfree_cooper1_hd_coeffs1: "qfree \<phi> \<Longrightarrow> qfree (cooper\<^isub>1 ( hd_coeffs1 \<phi>))"
by(auto simp:cooper\<^isub>1_def hd_coeffs1_def qfree_map_fm
        intro!: qfree_or qfree_and qfree_list_disj qfree_min_inf)


lemma normal_min_inf: "Z.normal \<phi> \<Longrightarrow> Z.normal(inf\<^isub>- \<phi>)"
by(induct \<phi> rule:min_inf.induct) simp_all

lemma normal_cooper1: "Z.normal \<phi> \<Longrightarrow> Z.normal(cooper\<^isub>1 \<phi>)"
by(simp add:cooper\<^isub>1_def Logic.or_def Z.normal_map_fm normal_min_inf split_def)

lemma normal_hd_coeffs1: "qfree \<phi> \<Longrightarrow> Z.normal \<phi> \<Longrightarrow> Z.normal(hd_coeffs1 \<phi>)"
by(auto simp: hd_coeffs1_def image_def set_atoms0_iff
              divisor_hd_coeff1_neq0 Z.normal_def)

theorem I_cooper: "Z.normal \<phi> \<Longrightarrow>  Z.I (cooper \<phi>) xs = Z.I \<phi> xs"
by(simp add:cooper_def Z.I_lift_nnf_qe_normal qfree_cooper1_hd_coeffs1 I_cooper1_hd_coeffs1 normal_cooper1 normal_hd_coeffs1)

theorem qfree_cooper: "qfree (cooper \<phi>)"
by(simp add:cooper_def Z.qfree_lift_nnf_qe qfree_cooper1_hd_coeffs1)

end