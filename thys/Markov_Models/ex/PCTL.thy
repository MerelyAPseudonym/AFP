(* Author: Johannes Hölzl <hoelzl@in.tum.de> 
   Author: Tobias Nipkow <nipkow@in.tum.de> *)
theory PCTL
imports 
  "../Discrete_Time_Markov_Chain"
  "../../Gauss-Jordan-Elim-Fun/Gauss_Jordan_Elim_Fun"
  "~~/src/HOL/Library/While_Combinator"
  "~~/src/HOL/Library/Monad_Syntax"
begin

section {* Adapt Gauss-Jordan elimination to DTMCs *}

lemma split_option_bind:
  fixes x :: "'a option" and f :: "'a \<Rightarrow> 'b option" and P :: "'b option \<Rightarrow> bool"
  shows "P (x \<guillemotright>= f) \<longleftrightarrow> (x = None \<longrightarrow> P None) \<and> (\<forall>a. x = Some a \<longrightarrow> P (f a))"
  by (cases x) auto

lemma split_option_bind_asm:
  fixes x :: "'a option" and f :: "'a \<Rightarrow> 'b option" and P :: "'b option \<Rightarrow> bool"
  shows "P (x \<guillemotright>= f) \<longleftrightarrow> \<not> ((x = None \<and> \<not> P None) \<or> (\<exists>a. x = Some a \<and> \<not> P (f a)))"
  by (simp split: split_option_bind)

context Discrete_Time_Markov_Chain
begin

lemma single_l:
  fixes s and x :: real assumes "s \<in> S"
  shows "(\<Sum>s'\<in>S. (if s' = s then 1 else 0) * l s') = x \<longleftrightarrow> l s = x"
proof -
  have "(\<Sum>s'\<in>S. (if s' = s then 1 else 0) * l s') = (\<Sum>s'\<in>S. (if s' = s then l s' else 0))"
    using `s \<in> S` by (auto intro!: setsum.cong)
  with `s \<in> S` show ?thesis
    using finite_S by (auto simp add: setsum.If_cases)
qed

definition "order = (SOME f. bij_betw f {..< card S} S)"

lemma
  shows bij_order[simp]: "bij_betw order {..< card S} S"
    and inj_order[simp]: "inj_on order {..<card S}"
    and image_order[simp]: "order ` {..<card S} = S"
    and order_S[simp, intro]: "\<And>i. i < card S \<Longrightarrow> order i \<in> S"
proof -
  from finite_same_card_bij[OF _ finite_S] show "bij_betw order {..< card S} S"
    unfolding order_def by (rule someI_ex) auto
  then show "inj_on order {..<card S}" "order ` {..<card S} = S"
    unfolding bij_betw_def by auto
  then show "\<And>i. i < card S \<Longrightarrow> order i \<in> S"
    by auto
qed

lemma order_Ex:
  assumes "s \<in> S" obtains i where "i < card S" "s = order i"
proof -
  from `s \<in> S` have "s \<in> order ` {..<card S}"
    by simp
  with that show thesis
    by (auto simp del: image_order)
qed

definition "iorder = the_inv_into {..<card S} order"

lemma bij_iorder: "bij_betw iorder S {..<card S}"
  unfolding iorder_def by (rule bij_betw_the_inv_into bij_order)+

lemma iorder_image_eq: "iorder ` S = {..<card S}"
  and inj_iorder: "inj_on iorder S"
  using bij_iorder  unfolding bij_betw_def by auto

lemma order_iorder: "\<And>s. s \<in> S \<Longrightarrow> order (iorder s) = s"
  unfolding iorder_def using bij_order
  by (intro f_the_inv_into_f) (auto simp: bij_betw_def)

definition gauss_jordan' :: "('s \<Rightarrow> 's \<Rightarrow> real) \<Rightarrow> ('s \<Rightarrow> real) \<Rightarrow> ('s \<Rightarrow> real) option" where
  "gauss_jordan' M a = do {
     let M' = (\<lambda>i j. if j = card S then a (order i) else M (order i) (order j)) ;
     sol \<leftarrow> gauss_jordan M' (card S) ;
     Some (\<lambda>i. sol (iorder i) (card S))
  }"

lemma gauss_jordan'_correct:
  assumes "gauss_jordan' M a = Some f"
  shows "\<forall>s\<in>S. (\<Sum>s'\<in>S. M s s' * f s') = a s"
proof -
  note `gauss_jordan' M a = Some f`
  moreover def M' \<equiv> "\<lambda>i j. if j = card S then 
    a (order i) else M (order i) (order j)"
  ultimately obtain sol where sol: "gauss_jordan M' (card S) = Some sol"
    and f: "f = (\<lambda>i. sol (iorder i) (card S))"
    by (auto simp: gauss_jordan'_def Let_def split: split_option_bind_asm)

  from gauss_jordan_correct[OF sol]
  have "\<forall>i\<in>{..<card S}. (\<Sum>j<card S. M (order i) (order j) * sol j (card S)) = a (order i)"
    unfolding solution_def M'_def by (simp add: atLeast0LessThan)
  then show ?thesis
    unfolding iorder_image_eq[symmetric] f using inj_iorder
    by (subst (asm) setsum.reindex) (auto simp: order_iorder)
qed

lemma gauss_jordan'_complete:
  assumes exists: "\<forall>s\<in>S. (\<Sum>s'\<in>S. M s s' * x s') = a s"
  assumes unique: "\<And>y. \<forall>s\<in>S. (\<Sum>s'\<in>S. M s s' * y s') = a s \<Longrightarrow> \<forall>s\<in>S. y s = x s"
  shows "\<exists>y. gauss_jordan' M a = Some y"
proof -
  def M' \<equiv> "\<lambda>i j. if j = card S then 
    a (order i) else M (order i) (order j)"

  { fix x
    have iorder_neq_card_S: "\<And>s. s \<in> S \<Longrightarrow> iorder s \<noteq> card S"
      using iorder_image_eq by (auto simp: set_eq_iff less_le)
    have "solution2 M' (card S) (card S) x \<longleftrightarrow>
      (\<forall>s\<in>{..<card S}. (\<Sum>s'\<in>{..<card S}. M' s s' * x s') = M' s (card S))"
      unfolding solution2_def by (auto simp: atLeast0LessThan)
    also have "\<dots> \<longleftrightarrow> (\<forall>s\<in>S. (\<Sum>s'\<in>S. M s s' * x (iorder s')) = a s)"
      unfolding iorder_image_eq[symmetric] M'_def
      using inj_iorder iorder_neq_card_S
      by (simp add: setsum.reindex order_iorder)
    finally have "solution2 M' (card S) (card S) x \<longleftrightarrow>
      (\<forall>s\<in>S. (\<Sum>s'\<in>S. M s s' * x (iorder s')) = a s)" . }
  note sol2_eq = this
  have "usolution M' (card S) (card S) (\<lambda>i. x (order i))"
    unfolding usolution_def
  proof safe
    from exists show "solution2 M' (card S) (card S) (\<lambda>i. x (order i))"
      by (simp add: sol2_eq order_iorder)
  next
    fix y j assume y: "solution2 M' (card S) (card S) y" and "j < card S"
    then have "\<forall>s\<in>S. (\<Sum>s'\<in>S. M s s' * y (iorder s')) = a s"
      by (simp add: sol2_eq)
    from unique[OF this]
    have "\<forall>i\<in>{..<card S}. y i = x (order i)"
      unfolding iorder_image_eq[symmetric]
      by (simp add: order_iorder)
    with `j < card S` show "y j = x (order j)" by simp
  qed
  from gauss_jordan_complete[OF _ this]
  show ?thesis
    by (auto simp: gauss_jordan'_def simp: M'_def)
qed

end

section {* pCTL model checking*}

subsection {* Syntax *}

datatype realrel = LessEqual | Less | Greater | GreaterEqual | Equal

primrec inrealrel where
"inrealrel LessEqual r q    \<longleftrightarrow> q \<le> r" |
"inrealrel Less r q         \<longleftrightarrow> q < r" |
"inrealrel Greater r q      \<longleftrightarrow> q > r" |
"inrealrel GreaterEqual r q \<longleftrightarrow> q \<ge> r" |
"inrealrel Equal r q        \<longleftrightarrow> q = r"

datatype 's sform = "true"
                  | "Label" "'s set"
                  | "Neg" "'s sform"
                  | "And" "'s sform" "'s sform"
                  | "Prob" "realrel" "real" "'s pform"
                  | "Exp" "realrel" "real" "'s eform"
     and 's pform = "X" "'s sform"
                  | "U" "nat" "'s sform" "'s sform"
                  | "UInfinity" "'s sform" "'s sform" ("U\<^sup>\<infinity>")
     and 's eform = "Cumm" "nat" ("C\<^sup>\<le>")
                  | "State" "nat" ("I\<^sup>=")
                  | "Future" "'s sform"

context Rewarded_DTMC
begin

subsection {* Semantics *}

fun svalid :: "'s sform \<Rightarrow> 's set"
and pvalid :: "'s \<Rightarrow> 's pform \<Rightarrow> (nat \<Rightarrow> 's) set"
and reward :: "'s eform \<Rightarrow> (nat \<Rightarrow> 's) \<Rightarrow> ereal" where
"svalid true           = S" |
"svalid (Label L)      = {s \<in> S. s \<in> L}" |
"svalid (Neg F)        = S - svalid F" |
"svalid (And F1 F2)    = svalid F1 \<inter> svalid F2" |
"svalid (Prob rel r F) = {s \<in> S. inrealrel rel r (prob s (pvalid s F)) }" |
"svalid (Exp rel r F)  = {s \<in> S. inrealrel rel r (\<integral>\<^sup>+ \<omega>. reward F (case_nat s \<omega>) \<partial>paths s) }" |

"pvalid s (X F)        = {w \<in> UNIV \<rightarrow> S. w 0 \<in> svalid F}" |
"pvalid s (U k F1 F2)  =
  {w \<in> UNIV \<rightarrow> S. s \<in> svalid F2 \<or>
    (\<exists>i<k. w i \<in> svalid F2 \<and> (\<forall>j<i. w j \<in> svalid F1) \<and> s \<in> svalid F1)}" |
"pvalid s (U\<^sup>\<infinity> F1 F2)   =
  {w \<in> UNIV \<rightarrow> S. s \<in> svalid F2 \<or>
    (\<exists>i. w i \<in> svalid F2 \<and> (\<forall>j<i. w j \<in> svalid F1) \<and> s \<in> svalid F1)}" |

"reward (C\<^sup>\<le> k)         = (\<lambda>\<omega>. (\<Sum>i<k. \<rho> (\<omega> i) + \<iota> (\<omega> i) (\<omega> (Suc i))))" |
"reward (I\<^sup>= k)         = (\<lambda>\<omega>. \<rho> (\<omega> k))" |
"reward (Future F)     =
    (\<lambda>\<omega>. if \<exists>i. \<omega> i \<in> svalid F then \<Sum>i<(LEAST i. \<omega> i \<in> svalid F). \<rho> (\<omega> i) + \<iota> (\<omega> i) (\<omega> (Suc i)) else \<infinity>)"

lemma svalid_subset_S: "svalid F \<subseteq> S"
  by (induct F) auto

lemma finite_svalid[simp, intro]: "finite (svalid F)"
  using svalid_subset_S finite_S by (blast intro: finite_subset)

lemma svalid_sets[measurable]: "svalid F \<in> sets (count_space S)"
  using svalid_subset_S by auto

lemma pvalid_sets[measurable]: "pvalid q F \<in> sets S_seq"
  by (cases F) (auto intro!: svalid_sets)

lemma reward_measurable[measurable]: "reward F \<in> borel_measurable S_seq"
  by (cases F) simp_all

lemma reward_nonneg: "\<omega> \<in> UNIV \<rightarrow> S \<Longrightarrow> 0 \<le> reward F \<omega>"
  by (cases F) (auto intro!: setsum_nonneg add_nonneg_nonneg)

lemma pvalid_eq_until:
  "s \<in> S \<Longrightarrow> pvalid s (U\<^sup>\<infinity> F1 F2) = case_nat s -` until (svalid F1) (svalid F2) \<inter> (UNIV\<rightarrow>S)"
  apply (simp add: until_def)
  apply (subst (2) Ex_case_nat_eq)
  apply (auto simp add: all_less_Suc_split space_PiM)
  done

subsection {* Implementation of @{text Sat} *}

subsubsection {* @{text Prob0}  *}

definition Prob0 where
  "Prob0 \<Phi> \<Psi> = S - while (\<lambda>R. \<exists>s\<in>\<Phi>. R \<inter> E s \<noteq> {} \<and> s \<notin> R) (\<lambda>R. R \<union> {s\<in>\<Phi>. R \<inter> E s \<noteq> {}}) \<Psi>"

lemma Prob0_subset_S: "Prob0 \<Phi> \<Psi> \<subseteq> S"
  unfolding Prob0_def by auto

lemma Prob0_iff_reachable:
  assumes "\<Phi> \<subseteq> S" "\<Psi> \<subseteq> S"
  shows "Prob0 \<Phi> \<Psi> = (S - (\<Phi> \<union> \<Psi>)) \<union> {s \<in> S. (reachable (\<Phi> - \<Psi>) s \<union> {s}) \<inter> \<Psi> = {}}" (is "_ = ?U")
  unfolding Prob0_def
proof (intro while_rule[where Q="\<lambda>R. S - R = ?U" and P="\<lambda>R. \<Psi> \<subseteq> R \<and> R \<subseteq> S - ?U"] conjI)
  show "wf {(B, A). A \<subset> B \<and> B \<subseteq> S}"
    by (rule wf_bounded_set[where ub="\<lambda>_. S" and f="\<lambda>x. x"]) auto
  show "\<Psi> \<subseteq> S - ?U"
    using assms by auto

  let ?\<Delta> = "\<lambda>R. {s\<in>\<Phi>. R \<inter> E s \<noteq> {}}"
  { fix R assume R: "\<Psi> \<subseteq> R \<and> R \<subseteq> S - ?U" "\<exists>s\<in>\<Phi>. R \<inter> E s \<noteq> {} \<and> s \<notin> R"
    with assms show "(R \<union> ?\<Delta> R, R) \<in> {(B, A). A \<subset> B \<and> B \<subseteq> S}" "\<Psi> \<subseteq> R \<union> ?\<Delta> R"
      by auto

    from R have "R \<subseteq> S" by auto
    have "?\<Delta> R \<subseteq> S - ?U"
    proof safe
      fix s s' assume "s \<in> \<Phi>" "s' \<in> R" "s' \<in> E s" and r: "(reachable (\<Phi> - \<Psi>) s \<union> {s}) \<inter> \<Psi> = {}"
      show "s' \<in> {}"
      proof cases
        assume "s' \<in> \<Psi>"
        with reachable.start[OF `s' \<in> E s`] r `\<Psi> \<subseteq> S` show ?thesis by auto
      next
        assume "s' \<notin> \<Psi>"
        with `s' \<in> R` R obtain s'' where s'': "s'' \<in> reachable (\<Phi> - \<Psi>) s'" "s'' \<in> \<Psi>" by auto
        have "s' \<in> \<Phi> - \<Psi>" using `s' \<notin> \<Psi>` `s' \<in> R` R(1) by auto
        from reachable_step_rev[OF s''(1) `s' \<in> E s` this] r `s'' \<in> \<Psi>`
        show ?thesis by auto
      qed
    qed (insert `\<Phi> \<subseteq> S`, auto)
    with R show "R \<union> ?\<Delta> R \<subseteq> S - ?U" by auto }

  { fix R assume R: "\<Psi> \<subseteq> R \<and> R \<subseteq> S - ?U" and dR: "\<not> (\<exists>s\<in>\<Phi>. R \<inter> E s \<noteq> {} \<and> s \<notin> R)"
    { fix s
      assume s: "s \<in> S - R" "s \<in> \<Phi>"
      from s(1) have "reachable (\<Phi> - \<Psi>) s \<subseteq> S - R"
        apply (rule reachable_closed)
        apply (insert assms R dR s(2))
        apply auto
        done }
    with R show "S - R = ?U" by auto }
qed auto

lemma Prob0_iff:
  assumes "\<Phi> \<subseteq> S" "\<Psi> \<subseteq> S"
  shows "Prob0 \<Phi> \<Psi> = {s\<in>S. AE \<omega> in paths s. case_nat s \<omega> \<notin> until \<Phi> \<Psi>}" (is "_ = ?U")
  unfolding Prob0_iff_reachable[OF assms]
  by (auto simp add: AE_nuntil_iff_not_reachable simp del: case_nat_until_iff cong: conj_cong)

subsubsection {* @{text Prob1} *}

definition Prob1 where
  "Prob1 Y \<Phi> \<Psi> = Prob0 (\<Phi> - \<Psi>) Y"

lemma Prob1_iff:
  assumes "\<Phi> \<subseteq> S" "\<Psi> \<subseteq> S"
  shows "Prob1 (Prob0 \<Phi> \<Psi>) \<Phi> \<Psi> = {s\<in>S. AE \<omega> in paths s. case_nat s \<omega> \<in> until \<Phi> \<Psi>}"
    (is "Prob1 ?P0 _ _ = {s\<in>S. ?pU s}")
proof -
  let ?\<Delta> = "\<lambda>R. {s\<in>\<Phi>-\<Psi>. R \<inter> E s \<noteq> {}}" and ?C = "\<lambda>R. \<exists>s\<in>\<Phi> - \<Psi>. R \<inter> E s \<noteq> {} \<and> s \<notin> R"
  have "while ?C (\<lambda>R. R \<union> (?\<Delta> R)) ?P0 = S - {s\<in>S. ?pU s}"
  proof (rule while_rule[where Q="\<lambda>R. R = S - {s\<in>S. ?pU s}" and
                               P="\<lambda>R. ?P0 \<subseteq> R \<and> R \<subseteq> S - {s\<in>S. ?pU s}"])
    show "wf {(B, A). A \<subset> B \<and> B \<subseteq> S}"
      by (rule wf_bounded_set[where ub="\<lambda>_. S" and f="\<lambda>x. x"]) auto
  next
    fix R assume "?P0 \<subseteq> R \<and> R \<subseteq> S - {s\<in>S. ?pU s}" "?C R"
    with assms show "(R \<union> ?\<Delta> R, R) \<in> {(B, A). A \<subset> B \<and> B \<subseteq> S}"
      by auto
  next
    show "?P0 \<subseteq> ?P0 \<and> ?P0 \<subseteq> S - {s\<in>S. ?pU s}"
      unfolding Prob0_iff[OF assms] by (auto dest: AE_contr)
  next
    fix R assume R: "?P0 \<subseteq> R \<and> R \<subseteq> S - {s\<in>S. ?pU s}"
    moreover have "?\<Delta> R \<subseteq> S - {s\<in>S. ?pU s}"
    proof safe
      fix s s' assume "?pU s" and s: "s \<in> \<Phi>" "s \<notin> \<Psi>" "s' \<in> R" "s' \<in> E s"
      with assms have [simp]: "s \<in> S" by auto
      from `s' \<in> R` R(1) have [simp]: "s' \<in> S" by (auto simp: subset_eq)
      have "\<not> ?pU s'"
        using `s' \<in> R` R(1) by (auto simp add: subset_eq)
      with assms s have "\<not> ?pU s"
        by (subst AE_iterate) (auto simp: AE_K_iff)
      then show "s' \<in> {}" using `?pU s` by auto
    qed (insert assms, auto)
    ultimately show "?P0 \<subseteq> R \<union> ?\<Delta> R \<and> R \<union> ?\<Delta> R \<subseteq> S - {s\<in>S. ?pU s}" by auto
  next
    fix R assume R: "?P0 \<subseteq> R \<and> R \<subseteq> S - {s\<in>S. ?pU s}" and dR: "\<not> ?C R"
    have "finite (\<Phi> - \<Psi>)"
      using `\<Phi> \<subseteq> S` finite_S by (auto dest: finite_subset)
    { fix s assume s: "s \<in> S" "s \<in> \<Phi>" "s \<notin> \<Psi>" "s \<notin> R"
      with R have "s \<notin> ?P0" by auto
      have "AE \<omega> in paths s. case_nat s \<omega> \<in> until \<Phi> \<Psi>"
      proof (rule AE_until)
        show "s \<in> \<Phi>" by fact
        show "s \<in> S" by fact
        show "reachable (\<Phi> - \<Psi>) s \<subseteq> \<Phi> \<union> \<Psi>"
        proof (rule ccontr)
          assume "\<not> reachable (\<Phi> - \<Psi>) s \<subseteq> \<Phi> \<union> \<Psi>"
          then obtain t where t: "t \<in> reachable (\<Phi> - \<Psi>) s" "t \<notin> \<Phi> \<union> \<Psi>"
            by auto
          from t have "t \<in> S" by auto
          with t(2) have "t \<in> ?P0"
            unfolding Prob0_iff[OF assms] by simp
          with R have "t \<in> R" by auto
          with R dR s reachable_closed_rev[OF t(1) `t \<in> R`] `s \<notin> R`
          show False by auto
        qed
        show "\<forall>t\<in>reachable (\<Phi> - \<Psi>) s \<union> {s} - \<Psi>. reachable (\<Phi> - \<Psi>) t \<inter> \<Psi> \<noteq> {}"
        proof (intro ballI notI)
          fix t assume in_s: "t \<in> reachable (\<Phi> - \<Psi>) s \<union> {s} - \<Psi>"
            and t: "reachable (\<Phi> - \<Psi>) t \<inter> \<Psi> = {}"
          from in_s `s \<in> S` have "t \<in> S" by auto
   
          from t in_s have "t \<notin> \<Psi> \<and> (t \<in> \<Phi> \<longrightarrow> reachable (\<Phi> - \<Psi>) t \<inter> \<Psi> = {})"
            by auto
          with `t \<in> S` assms
          have "AE \<omega> in paths t. case_nat t \<omega> \<notin> until \<Phi> \<Psi>"
            by (auto simp: AE_nuntil_iff_not_reachable simp del: case_nat_until_iff)
          then have "t \<in> ?P0"
            using `t \<in> S` assms by (simp add: Prob0_iff)
          then have "t \<in> R" using R by auto
          show False
          proof cases
            assume "t = s" with `t \<in> R` `s \<notin> R` show False by auto
          next
            assume "t \<noteq> s"
            with in_s have "t \<in> reachable (\<Phi> - \<Psi>) s" by auto
            from reachable_closed_rev[OF this `t \<in> R`] dR s R `s \<notin> R`
            show False by auto
          qed
        qed
      qed fact
      with `s \<in> S` assms have "s \<in> {s\<in>S. ?pU s}" by simp }
    note after_s = this

    { fix s assume s: "s \<in> S" "s \<notin> R"
      have "s \<in> {s\<in>S. ?pU s}"
      proof cases
        assume "s \<in> \<Psi>" with `s \<in> S` assms show ?thesis by simp
      next
        assume "s \<notin> \<Psi>"
        show "s \<in> {s\<in>S. ?pU s}"
        proof (rule after_s)
          show "s \<in> \<Phi>"
          proof (rule ccontr)
            assume "s \<notin> \<Phi>"
            with `s \<notin> \<Psi>` `s \<in> S` assms have "s \<in> ?P0" by (simp add: Prob0_iff)
            with `s \<notin> R` R show False by auto
          qed
        qed fact+
      qed }
    with R show "R = S - {s\<in>S. ?pU s}" by auto
  qed
  then show ?thesis
    unfolding Prob1_def Prob0_def by auto
qed

lemma Prob0_I:
  assumes "\<Phi> \<subseteq> S" "\<Psi> \<subseteq> S" "s \<in> S"
  assumes *: "\<forall>n \<omega>. \<omega> : UNIV \<rightarrow> S \<and> case_nat s \<omega> n \<in> \<Psi> \<and> (\<forall>i<n. case_nat s \<omega> i \<in> \<Phi>) \<longrightarrow> (\<exists>i<n. \<omega> i \<notin> E (case_nat s \<omega> i))"
  shows "s \<in> Prob0 \<Phi> \<Psi>"
proof -
  have "AE \<omega> in paths s. case_nat s \<omega> \<notin> until \<Phi> \<Psi>"
    using AE_all_enabled[OF `s \<in> S`] AE_space
    apply eventually_elim
  proof rule
    fix \<omega> assume E: "\<forall>i. \<omega> i \<in> E (case_nat s \<omega> i)" and "case_nat s \<omega> \<in> until \<Phi> \<Psi>"
      and \<omega>: "\<omega> \<in> space (paths s)"
    then obtain n where "case_nat s \<omega> n \<in> \<Psi>" "\<forall>i<n. case_nat s \<omega> i \<in> \<Phi>"
      unfolding until_def by auto
    with * \<omega> have "\<exists>i<n. \<omega> i \<notin> E (case_nat s \<omega> i)" by (auto simp: space_PiM)
    with E show False by auto
  qed
  with assms show ?thesis by (simp add: Prob0_iff)
qed

subsubsection {* Unique solution of a LES *}

lemma unique:
  assumes in_S: "\<Phi> \<subseteq> S" "\<Psi> \<subseteq> S" "N \<subseteq> S" "Prob0 \<Phi> \<Psi> \<subseteq> N" "\<Psi> \<subseteq> N"
  assumes l1: "\<And>s. s \<in> S \<Longrightarrow> s \<notin> N \<Longrightarrow> l1 s - c s = (\<Sum>s'\<in>S. \<tau> s s' * l1 s')"
  assumes l2: "\<And>s. s \<in> S \<Longrightarrow> s \<notin> N \<Longrightarrow> l2 s - c s = (\<Sum>s'\<in>S. \<tau> s s' * l2 s')"
  assumes eq: "\<And>s. s \<in> N \<Longrightarrow> l1 s = l2 s"
  shows "\<forall>s\<in>S. l1 s = l2 s"
proof -
  def \<Delta> \<equiv> "\<lambda>s. l1 s - l2 s"
  then have 1: "\<forall>s\<in>S - N. \<Delta> s = (\<Sum>s'\<in>S. \<tau> s s' * \<Delta> s')" and 2: "\<forall>s\<in>N. \<Delta> s = 0"
    using l1 l2 eq by (auto simp: setsum_subtractf field_simps)

  def M \<equiv> "{s\<in>S. \<bar>\<Delta> s\<bar> = Max ((\<lambda>s. \<bar>\<Delta> s\<bar>) ` S)}"
  then have M: "\<And>s' s. s \<in> M \<Longrightarrow> s' \<in> S \<Longrightarrow> \<bar>\<Delta> s'\<bar> \<le> \<bar>\<Delta> s\<bar>" 
    using s0 finite_S by auto

  { fix s s' assume s: "s \<in> M" "s \<in> S" and s': "s' \<notin> M" "s' \<in> S" and "\<bar>\<Delta> s\<bar> \<noteq> 0"
    then have s_in: "s \<in> S - N"
      using 2 by auto
    have "\<bar>\<Delta> s'\<bar> \<noteq> \<bar>\<Delta> s\<bar>"
      using `s \<in> M` `s' \<in> S` `s' \<notin> M` by (simp add: M_def)
    with M[OF `s \<in> M` `s' \<in> S`]
    have s'_less: "\<bar>\<Delta> s'\<bar> < \<bar>\<Delta> s\<bar>" by simp

    have "\<tau> s s' = 0"
    proof (rule ccontr)
      assume "\<tau> s s' \<noteq> 0"
      with \<tau>_nneg[OF `s \<in> S` `s' \<in> S`]
      have "0 < \<tau> s s'" by auto
      from 1[THEN bspec] s_in s
      have "\<bar>\<Delta> s\<bar> = \<bar>\<Sum>s'\<in>S. \<tau> s s' * \<Delta> s'\<bar>"
        by auto
      also have "\<dots> \<le> (\<Sum>s'\<in>S. \<bar>\<tau> s s' * \<Delta> s'\<bar>)"
        by simp
      also have "\<dots> = (\<Sum>s'\<in>S. \<tau> s s' * \<bar>\<Delta> s'\<bar>)"
        using \<tau>_nneg `s \<in> S` by (simp add: abs_mult)
      also have "\<dots> < (\<Sum>s'\<in>S. \<tau> s s' * \<bar>\<Delta> s\<bar>)"
        using finite_S `0 < \<tau> s s'` \<tau>_nneg s' s M[OF `s \<in> M`] s'_less
        by (intro setsum_strict_mono_single mult_strict_left_mono mult_left_mono)
           auto
      also have "\<dots> = \<bar>\<Delta> s\<bar>"
        using \<tau>_distr `s \<in> S`
        by (simp add: setsum_left_distrib[symmetric])
      finally show False ..
    qed }
  note M_closed = this

  { fix s assume s: "s \<in> M" "0 < \<bar>\<Delta> s\<bar>"
    then have "s \<notin> N" using 2 by auto
    moreover
    have "s \<in> S" using s unfolding M_def by auto
    have "s \<in> Prob0 \<Phi> \<Psi>"
    proof (safe intro!: Prob0_I[OF in_S(1,2) `s \<in> S`])
      fix n \<omega> assume \<omega>: "case_nat s \<omega> n \<in> \<Psi>" "\<forall>i<n. case_nat s \<omega> i \<in> \<Phi>" "\<omega> \<in> UNIV \<rightarrow> S"
      have "\<bar>\<Delta> (case_nat s \<omega> n)\<bar> = 0" using s `case_nat s \<omega> n \<in> \<Psi>` in_S 2 by auto
      with `0 < \<bar>\<Delta> s\<bar>` `s \<in> M` have "case_nat s \<omega> n \<notin> M" by (auto simp: M_def)
      moreover with `s \<in> M` have "n \<noteq> 0" by (intro notI) auto
      ultimately have "\<omega> (n - 1) \<notin> M" by (auto simp: gr0_conv_Suc)
      from smallest[where P="\<lambda>i. \<omega> i \<notin> M", OF this]
      guess i . note \<omega>_i = this

      have "\<exists>i<n. \<tau> (case_nat s \<omega> i) (\<omega> i) = 0"
      proof (rule exI[of _ i], rule)
        show "i < n" using \<omega>_i `n \<noteq> 0` by simp
        show "\<tau> (case_nat s \<omega> i) (\<omega> i) = 0"
        proof (rule M_closed)
          show "case_nat s \<omega> i \<in> S" using \<omega>(2) `i < n` in_S by auto
          show "\<omega> i \<in> S"
            using \<omega>(1) \<omega>(2) `i < n` in_S
            by (cases "Suc i < n") (auto simp: not_less le_Suc_eq)
          show "case_nat s \<omega> i \<in> M"
          proof (cases i)
            case 0 with `s \<in> M` show ?thesis by simp
          next
            case (Suc i') with \<omega>_i(2)[of i'] show ?thesis by simp
          qed
          with s show "\<bar>\<Delta> (case_nat s \<omega> i)\<bar> \<noteq> 0" by (auto simp: M_def)
        qed fact
      qed
      then guess i ..
      with \<omega>(3) `s\<in>S` have "\<omega> i \<notin> E (case_nat s \<omega> i)" "i < n"
         by (auto simp: Pi_iff E_iff)
      then show "\<exists>i<n. \<omega> i \<notin> E (case_nat s \<omega> i)" by auto
    qed
    ultimately have False using in_S by auto }
  moreover
  have "Max ((\<lambda>s. \<bar>\<Delta> s\<bar>) ` S) \<in> (\<lambda>s. \<bar>\<Delta> s\<bar>) ` S"
    using s0 finite_S by (auto intro: Max_in)
  then have "M \<noteq> {}"
    unfolding M_def by auto
  then obtain s where "s \<in> M" by blast
  ultimately have "\<bar>\<Delta> s\<bar> = 0" by auto
  with `s \<in> M`[THEN M] have "\<forall>s'\<in>S. \<bar>\<Delta> s'\<bar> = 0" by simp
  then show ?thesis
    unfolding \<Delta>_def by simp
qed

subsubsection {* @{text ProbU},  @{text ExpCumm}, and @{text ExpState}  *}

fun ProbU :: "'s \<Rightarrow> nat \<Rightarrow> 's set \<Rightarrow> 's set \<Rightarrow> real" where
"ProbU q 0 S1 S2       = (if q \<in> S2 then 1 else 0)" |
"ProbU q (Suc k) S1 S2 =
  (if q \<in> S1 - S2 then (\<Sum>q'\<in>S. \<tau> q q' * ProbU q' k S1 S2)
                  else if q \<in> S2 then 1 else 0)"

fun ExpCumm :: "'s \<Rightarrow> nat \<Rightarrow> ereal" where
"ExpCumm s 0       = 0" |
"ExpCumm s (Suc k) = \<rho> s + (\<Sum>s'\<in>S. \<tau> s s' * (\<iota> s s' + ExpCumm s' k))"

fun ExpState :: "'s \<Rightarrow> nat \<Rightarrow> ereal" where
"ExpState s 0       = \<rho> s" |
"ExpState s (Suc k) = (\<Sum>s'\<in>S. \<tau> s s' * ExpState s' k)"

subsubsection {* @{text LES} *}

definition LES :: "'s set \<Rightarrow> 's \<Rightarrow> 's \<Rightarrow> real" where
  "LES F r c =
       (if r \<in> F then (if c = r then 1 else 0)
                 else (if c = r then \<tau> r c - 1 else \<tau> r c ))"


subsubsection {* @{text ProbUinfty}, compute unbounded until *}

definition ProbUinfty :: "'s set \<Rightarrow> 's set \<Rightarrow> ('s \<Rightarrow> real) option" where
  "ProbUinfty S1 S2 = gauss_jordan' (LES (Prob0 S1 S2 \<union> S2))
                                    (\<lambda>i. if i \<in> S2 then 1 else 0)"

subsubsection {* @{text ExpFuture}, compute unbounded reward *}

definition ExpFuture :: "'s set \<Rightarrow> ('s \<Rightarrow> ereal) option" where
  "ExpFuture F = do {
      let N = Prob0 S F ;
      let Y = Prob1 N S F ;
      sol \<leftarrow> gauss_jordan' (LES (S - Y \<union> F))
        (\<lambda>i. if i \<in> Y \<and> i \<notin> F then - \<rho> i - (\<Sum>s'\<in>S. \<tau> i s' * \<iota> i s') else 0) ;
      Some (\<lambda>s. if s \<in> Y then ereal (sol s) else \<infinity>)
    }"

subsubsection {* @{text Sat} *}

fun Sat :: "'s sform \<Rightarrow> 's set option" where
"Sat true                   = Some S" |
"Sat (Label L)              = Some {s \<in> S. s \<in> L}" |
"Sat (Neg F)                = do { F \<leftarrow> Sat F ; Some (S - F) }" |
"Sat (And F1 F2)            = do { F1 \<leftarrow> Sat F1 ; F2 \<leftarrow> Sat F2 ; Some (F1 \<inter> F2) }" |

"Sat (Prob rel r (X F))        = do { F \<leftarrow> Sat F ; Some {q \<in> S. inrealrel rel r (\<Sum>q'\<in>F. \<tau> q q')} }" |
"Sat (Prob rel r (U k F1 F2))  = do { F1 \<leftarrow> Sat F1 ; F2 \<leftarrow> Sat F2 ; Some {q \<in> S. inrealrel rel r (ProbU q k F1 F2) } }" |
"Sat (Prob rel r (U\<^sup>\<infinity> F1 F2))   = do { F1 \<leftarrow> Sat F1 ; F2 \<leftarrow> Sat F2 ; P \<leftarrow> ProbUinfty F1 F2 ; Some {q \<in> S. inrealrel rel r (P q) } }" |

"Sat (Exp rel r (Cumm k))      = Some {s \<in> S. inrealrel rel r (ExpCumm s k) }" |
"Sat (Exp rel r (State k))     = Some {s \<in> S. inrealrel rel r (ExpState s k) }" |
"Sat (Exp rel r (Future F))    = do { F \<leftarrow> Sat F ; E \<leftarrow> ExpFuture F ; Some {q \<in> S. inrealrel rel (ereal r) (E q) } }"

lemma ProbU: 
  "q \<in> S \<Longrightarrow> ProbU q k (svalid F1) (svalid F2) = prob q (pvalid q (U k F1 F2))"
proof (induct k arbitrary: q)
  case 0 then show ?case by simp
next
  case (Suc k)
  { fix A B q' assume "A \<subseteq> S" "B \<subseteq> S" "q' \<in> S"
    then have "{w \<in> UNIV \<rightarrow> S. q' \<in> B \<or> (\<exists>i<k. w i \<in> B \<and> (\<forall>j<i. w j \<in> A) \<and> q' \<in> A)} =
      case_nat q' -` {w \<in> UNIV \<rightarrow> S. \<exists>i<Suc k. w i \<in> B \<and> (\<forall>j<i. w j \<in> A)} \<inter> (UNIV \<rightarrow> S)"
      by (auto split: nat.split simp: Pi_iff gr0_conv_Suc all_conj_distrib) blast }
  note eq = this
  note `q\<in>S`[simp]
  with Suc show ?case
    by (simp add: prob_eq_sum[of q] eq svalid_subset_S space_PiM case_nat_in_funcset \<tau>_distr)
qed

lemma Prob0_imp_not_Psi:
  assumes "\<Phi> \<subseteq> S" "\<Psi> \<subseteq> S" "s \<in> Prob0 \<Phi> \<Psi>" shows "s \<notin> \<Psi>"
proof -
  have "s \<in> S" using `s \<in> Prob0 \<Phi> \<Psi>` Prob0_subset_S by auto
  with assms show ?thesis by (auto simp add: Prob0_iff)
qed

lemma Psi_imp_not_Prob0:
  assumes "\<Phi> \<subseteq> S" "\<Psi> \<subseteq> S" shows "s \<in> \<Psi> \<Longrightarrow> s \<notin> Prob0 \<Phi> \<Psi>"
  using Prob0_imp_not_Psi[OF assms] by metis

subsubsection {* Finite expected reward *}

lemma nn_integral_reward_finite:
  assumes "s \<in> S"
  assumes until: "AE \<omega> in paths s. case_nat s \<omega> \<in> until S (svalid F)"
  shows "(\<integral>\<^sup>+ \<omega>. reward (Future F) (case_nat s \<omega>) \<partial>paths s) \<noteq> \<infinity>"
proof -
  let ?F = "svalid F"

  def Mr \<equiv> "Max ((\<lambda>(s, s'). \<rho> s + \<iota> s s') ` (S\<times>S))"
  then have Mr: "\<And>s s'. s \<in> S \<Longrightarrow> s' \<in> S \<Longrightarrow> \<rho> s + \<iota> s s' \<le> Mr"
    using s0 by (auto intro!: Max_ge)
  from \<rho>_nneg[OF s0_in_S] \<iota>_nneg[OF s0_in_S s0_in_S] have "0 \<le> \<rho> s0 + \<iota> s0 s0" by simp
  also have "\<dots> \<le> Mr"
    using s0_in_S s0_in_S by (rule Mr)
  finally have "0 \<le> Mr" .

  let "?t \<omega>" = "hitting_time ?F (case_nat s \<omega>)"
  have "(\<integral>\<^sup>+\<omega>. reward (Future F) (case_nat s \<omega>) \<partial>paths s)
    \<le> (\<integral>\<^sup>+\<omega>. ereal Mr * ereal (((of_nat \<circ> hitting_time ?F) \<circ> case_nat s) \<omega>) \<partial>paths s)"
    using until
  proof (intro nn_integral_mono_AE, elim AE_mp, intro AE_I2 impI)
    fix \<omega> assume \<omega>: "\<omega> \<in> space (paths s)" "case_nat s \<omega> \<in> until S ?F"
    from untilE[OF \<omega>(2)] guess n . note n = this
        
    from n have "reward (Future F) (case_nat s \<omega>) =
      (\<Sum>i<?t \<omega>. \<rho>  (case_nat s \<omega> i) + \<iota>  (case_nat s \<omega> i) (\<omega> i))"
      by (auto simp add: hitting_time_def)
    also have "\<dots> \<le> (\<Sum>i<?t \<omega>. Mr)" 
      unfolding ereal_less_eq using \<omega> `s \<in> S`
      by (intro setsum_mono Mr) (auto simp: space_PiM)
    also have "\<dots> = Mr * ereal (of_nat (?t \<omega>))"
      by (simp add: field_simps)
    finally show "reward (Future F) (case_nat s \<omega>) \<le> Mr * ereal ((real_of_nat \<circ> hitting_time ?F \<circ> case_nat s) \<omega>)"
      by simp
  qed
  also have "\<dots> = Mr * (\<integral>\<^sup>+\<omega>. ereal (((of_nat \<circ> hitting_time ?F) \<circ> case_nat s) \<omega>) \<partial>paths s)"
    using measurable_hitting_time `0 \<le> Mr` `s \<in> S`
    apply (subst nn_integral_cmult)
    apply (rule borel_measurable_ereal)
    using measurable_comp[OF measurable_case_nat measurable_hitting_time]
    apply (auto simp: comp_def cong: measurable_cong_sets)
    done
  also have "\<dots> < \<infinity>"
    using nn_integral_hitting_time_finite[OF `s \<in> S` _ until] `0 \<le> Mr`
    by (simp add: real_eq_of_nat)
  finally show ?thesis
    by simp
qed

lemma uniqueness_of_ProbU:
  assumes sol:
    "\<forall>s\<in>S. (\<Sum>s'\<in>S. LES (Prob0 (svalid F1) (svalid F2) \<union> svalid F2) s s' * l s') =
      (if s \<in> svalid F2 then 1 else 0)"
  shows "\<forall>s\<in>S. l s = (prob s (pvalid s (U\<^sup>\<infinity> F1 F2)))"
proof (rule unique)
  show "svalid F1 \<subseteq> S" "svalid F2 \<subseteq> S"
    "Prob0 (svalid F1) (svalid F2) \<subseteq> Prob0 (svalid F1) (svalid F2) \<union> svalid F2"
    "svalid F2 \<subseteq> Prob0 (svalid F1) (svalid F2) \<union> svalid F2"
    "Prob0 (svalid F1) (svalid F2) \<union> svalid F2 \<subseteq> S"
    using svalid_subset_S by (auto simp: Prob0_def)
next
  fix s assume s: "s \<in> S" "s \<notin> Prob0 (svalid F1) (svalid F2) \<union> svalid F2"
  have "(\<Sum>s'\<in>S. (if s' = s then \<tau> s s' - 1 else \<tau> s s') * l s') = 
    (\<Sum>s'\<in>S. \<tau> s s' * l s' - (if s' = s then 1 else 0) * l s')"
    by (auto intro!: setsum.cong simp: field_simps)
  also have "\<dots> = (\<Sum>s'\<in>S. \<tau> s s' * l s') - l s"
    using `s \<in> S` by (simp add: setsum_subtractf single_l)
  finally show "l s - 0 = (\<Sum>s'\<in>S. \<tau> s s' * l s')"
    using sol[THEN bspec, of s] s by (simp add: LES_def)
next
  fix s assume s: "s \<in> S" "s \<notin> Prob0 (svalid F1) (svalid F2) \<union> svalid F2"
  { fix s' assume "s' \<in> S"
    from s `s \<in> S` svalid_subset_S have "s \<in> svalid F1"
      by (rule_tac ccontr) (auto simp: Prob0_iff)
    with `s' \<in> S` s
    have "pvalid s' (U\<^sup>\<infinity> F1 F2) = case_nat s' -` pvalid s (U\<^sup>\<infinity> F1 F2) \<inter> (UNIV \<rightarrow> S)"
      by (cases "s' \<in> svalid F2" "s' \<in> svalid F1" rule: bool.exhaust[case_product bool.exhaust])
         (auto split: nat.split simp: Pi_iff gr0_conv_Suc space_PiM) }
  with prob_eq_sum[OF `s \<in> S` pvalid_sets, of _ "U\<^sup>\<infinity> F1 F2"]
  show "prob s (pvalid s (U\<^sup>\<infinity> F1 F2)) - 0 = (\<Sum>s'\<in>S. \<tau> s s' * prob s' (pvalid s' (U\<^sup>\<infinity> F1 F2)))"
    by simp
next
  fix s assume "s \<in> Prob0 (svalid F1) (svalid F2) \<union> svalid F2"
  then show "l s = prob s (pvalid s (U\<^sup>\<infinity> F1 F2))"
  proof
    assume P0: "s \<in> Prob0 (svalid F1) (svalid F2)"
    then have "s \<in> S" unfolding Prob0_def by auto
    with P0 sol[THEN bspec, of s] Prob0_subset_S
      Prob0_imp_not_Psi[OF svalid_subset_S svalid_subset_S P0]
    have "l s = 0"
      by (auto simp: LES_def single_l split: split_if_asm)
    moreover have "prob s (pvalid s (U\<^sup>\<infinity> F1 F2)) = prob s {}"
      using P0 `s \<in> S` pvalid_eq_until[of s F1 F2]
      unfolding Prob0_iff[OF svalid_subset_S svalid_subset_S] 
      by (intro finite_measure_eq_AE) auto
    ultimately show "l s = prob s (pvalid s (U\<^sup>\<infinity> F1 F2))" by simp
  next
    assume s: "s \<in> svalid F2"
    moreover with svalid_subset_S have "s \<in> S" by auto
    moreover note Psi_imp_not_Prob0[OF svalid_subset_S svalid_subset_S s]
    ultimately have "l s = 1"
      using sol[THEN bspec, of s]
      by (auto simp: LES_def single_l dest: Psi_imp_not_Prob0[OF svalid_subset_S svalid_subset_S])
    moreover have "prob s (pvalid s (U\<^sup>\<infinity> F1 F2)) = 1"
      using `s \<in> S` s pvalid_eq_until[of s F1 F2] AE_all_S by (simp add: prob_eq_1)
    ultimately show "l s = prob s (pvalid s (U\<^sup>\<infinity> F1 F2))" by simp
  qed
qed

lemma infinite_reward:
  fixes s F
  defines "N \<equiv> Prob0 S (svalid F)" (is "_ \<equiv> Prob0 S ?F")
  defines "Y \<equiv> Prob1 N S (svalid F)"
  assumes s: "s \<in> S" "s \<notin> Y"
  shows "(\<integral>\<^sup>+\<omega>. reward (Future F) (case_nat s \<omega>) \<partial>paths s) = \<infinity>"
proof -
  from s have "prob s (case_nat s -` until S ?F \<inter> space (paths s)) \<noteq> 1" "s \<in> S"
    unfolding Y_def N_def using svalid_subset_S
    by (auto simp add: Prob1_iff space_PiM PiE_def AE_in_set_eq_1[symmetric])
  then have not_until: "\<not> (AE \<omega> in paths s. \<omega> \<in> case_nat s -` until S ?F \<inter> space (paths s))"
    by (subst AE_in_set_eq_1) (auto intro!: measurable_sets measurable_case_nat)
  let ?R = "reward (Future F)"
  show ?thesis
  proof (rule ccontr)
    assume "\<not> ?thesis"
    from nn_integral_PInf_AE[OF _ this] `s\<in>S`
    have "AE x in paths s. reward (Future F) (case_nat s x) \<noteq> \<infinity>"
      by (simp del: reward.simps)
    then have "AE \<omega> in paths s. \<omega> \<in> case_nat s -` until S ?F \<inter> space (paths s)"
    proof (rule AE_mp, intro AE_I2 impI IntI)
      fix \<omega> assume "\<omega> \<in> space (paths s)"
      moreover assume "reward (Future F) (case_nat s \<omega>) \<noteq> \<infinity>"
      then obtain i where "case_nat s \<omega> i \<in> ?F"
        by (auto split: split_if_asm)
      ultimately show "\<omega> \<in> case_nat s -` until S ?F"
        using `s \<in> S` by (auto intro!: untilI[where n=i] simp: space_PiM simp del: case_nat_until_iff)
    qed
    with not_until show False ..
  qed
qed

subsubsection {* The expected reward implies a unique LES *}

lemma existence_of_ExpFuture:
  fixes s F
  assumes N_def: "N \<equiv> Prob0 S (svalid F)" (is "_ \<equiv> Prob0 S ?F")
  assumes Y_def: "Y \<equiv> Prob1 N S (svalid F)"
  assumes s: "s \<in> S" "s \<notin> S - (Y - ?F)"
  shows "real (\<integral>\<^sup>+\<omega>. reward (Future F) (case_nat s \<omega>) \<partial>paths s)
    - (\<rho> s + (\<Sum>s'\<in>S. \<tau> s s' * \<iota> s s')) =
    (\<Sum>s'\<in>S. \<tau> s s' * real(\<integral>\<^sup>+\<omega>. reward (Future F) (case_nat s' \<omega>) \<partial>paths s'))"
proof -
  let ?R = "reward (Future F)"

  from s have "s \<in> Prob1 (Prob0 S ?F) S ?F"
    unfolding Y_def N_def by auto
  then have AE_until: "AE \<omega> in paths s. case_nat s \<omega> \<in> until S (svalid F)"
    using Prob1_iff[of S ?F] svalid_subset_S by auto

  from s have "s \<notin> ?F" by auto

  let ?E = "\<lambda>s'. \<integral>\<^sup>+ \<omega>. reward (Future F) (case_nat s' \<omega>) \<partial>paths s'"
  have *: "(\<Sum>s'\<in>S. \<tau> s s' * ?E s') = (\<Sum>s'\<in>S. ereal (\<tau> s s' * real (?E s')))"
  proof (rule setsum.cong)
    fix s' assume "s' \<in> S"
    show "\<tau> s s' * ?E s' = ereal (\<tau> s s' * real (?E s'))"
    proof cases
      assume "\<tau> s s' \<noteq> 0"
      with `s \<in> S` `s' \<in> S` have "s' \<in> E s" by (simp add: E_iff)
      from `s \<notin> ?F` AE_until have "AE \<omega> in paths s. \<omega> \<in> until S ?F"
        using svalid_subset_S `s \<in> S` by simp
      with nn_integral_reward_finite[OF `s' \<in> S`, of F] `s \<in> S` `s' \<in> E s`
      have "\<bar>?E s'\<bar> \<noteq> \<infinity>"
        by (simp add: nn_integral_nonneg AE_iterate[of s] AE_K_iff)
      then show ?thesis by (cases "?E s'") auto
    qed (simp add: zero_ereal_def[symmetric])
  qed simp

  from AE_until
  have "AE \<omega> in paths s. ?R (case_nat s \<omega>) = \<rho> s + \<iota> s (\<omega> 0) + ?R \<omega>"
  proof eventually_elim
    fix \<omega> assume "case_nat s \<omega> \<in> until S ?F"
    with `s \<notin> ?F` `s \<in> S` svalid_subset_S
    have "\<omega> \<in> until S ?F"
      by simp
    from untilE[OF this] guess n . note n = this
    then have n_eq: "(LEAST i. \<omega> i \<in> ?F) = n"
      by (intro Least_equality) (auto simp: not_less[symmetric])
    moreover have "(LEAST i. case_nat s \<omega> i \<in> ?F) =
      Suc (LEAST i. case_nat s \<omega> (Suc i) \<in> ?F)"
      using n `s \<notin> ?F` by (intro Least_Suc[of _ "Suc n"]) auto
    then have Suc_n_eq: "(LEAST i. case_nat s \<omega> i \<in> ?F) = Suc n"
      using n_eq by simp
    
    have "(\<exists>i. \<omega> i \<in> svalid F)"
      using n by auto
    moreover have "\<exists>i. case_nat s \<omega> i \<in> svalid F"
      using n by (auto intro!: exI[of _ "Suc n"])
    ultimately show "?R (case_nat s \<omega>) = (\<rho> s + \<iota> s (\<omega> 0)) + ?R \<omega>"
      by (simp add: Suc_n_eq n_eq lessThan_Suc_eq_insert_0 setsum.reindex zero_notin_Suc_image
               del: setsum_lessThan_Suc)
  qed
  then have "(\<integral>\<^sup>+\<omega>. ?R (case_nat s \<omega>) \<partial>paths s)
    = (\<integral>\<^sup>+\<omega>. (\<rho> s + \<iota> s (\<omega> 0)) + ?R \<omega> \<partial>paths s)"
    by (rule nn_integral_cong_AE)
  also have "\<dots> = (\<integral>\<^sup>+\<omega>. \<rho> s + \<iota> s (\<omega> 0)\<partial>paths s) +
    (\<integral>\<^sup>+\<omega>. ?R \<omega> \<partial>paths s)"
    using `s \<in> S`
    by (subst nn_integral_add)
       (auto simp add: space_PiM PiE_iff reward_nonneg simp del: reward.simps)
  also have "\<dots> = ereal (\<rho> s + (\<Sum>s'\<in>S. \<tau> s s' * \<iota> s s')) +
    (\<integral>\<^sup>+\<omega>. ?R \<omega> \<partial>paths s)"
    using `s \<in> S`
    by (subst nn_integral_paths_0)
       (auto simp: field_simps setsum.distrib \<tau>_distr nn_integral_K
                   setsum_right_distrib[symmetric])
  finally show "real (\<integral>\<^sup>+\<omega>. ?R (case_nat s \<omega>) \<partial>paths s)
    - (\<rho> s + (\<Sum>s'\<in>S. \<tau> s s' * \<iota> s s')) =
    (\<Sum>s'\<in>S. \<tau> s s' * real(\<integral>\<^sup>+\<omega>. ?R (case_nat s' \<omega>) \<partial>paths s'))"
    apply (simp del: reward.simps)
    apply (subst nn_integral_eq_sum[OF `s \<in> S` reward_measurable])
    apply (simp del: reward.simps add: *)
    done
qed

lemma uniqueness_of_ExpFuture:
  fixes F
  assumes N_def: "N \<equiv> Prob0 S (svalid F)" (is "_ \<equiv> Prob0 S ?F")
  assumes Y_def: "Y \<equiv> Prob1 N S (svalid F)"
  assumes const_def: "const \<equiv> \<lambda>s. if s \<in> Y \<and> s \<notin> svalid F then - \<rho> s - (\<Sum>s'\<in>S. \<tau> s s' * \<iota> s s') else 0"
  assumes sol: "\<And>s. s\<in>S \<Longrightarrow> (\<Sum>s'\<in>S. LES (S - Y \<union> ?F) s s' * l s') = const s"
  shows "\<forall>s\<in>S. l s = real(\<integral>\<^sup>+\<omega>. reward (Future F) (case_nat s \<omega>) \<partial>paths s)"
    (is "\<forall>s\<in>S. l s = real(\<integral>\<^sup>+\<omega>. ?R (case_nat s \<omega>) \<partial>paths s)")
proof (rule unique)
  show "S \<subseteq> S" "?F \<subseteq> S" using svalid_subset_S by auto
  show "S - (Y - ?F) \<subseteq> S" "Prob0 S ?F \<subseteq> S - (Y - ?F)" "?F \<subseteq> S - (Y - ?F)"
    using svalid_subset_S
    by (auto simp add: Y_def N_def Prob1_iff)
       (auto simp add: Prob0_iff dest!: AE_contr)
next
  fix s assume "s \<in> S" "s \<notin> S - (Y - ?F)"
  then show "real (\<integral>\<^sup>+\<omega>. ?R (case_nat s \<omega>) \<partial>paths s)
    - (\<rho> s + (\<Sum>s'\<in>S. \<tau> s s' * \<iota> s s')) =
    (\<Sum>s'\<in>S. \<tau> s s' * real(\<integral>\<^sup>+\<omega>. ?R (case_nat s' \<omega>) \<partial>paths s'))"
    by (rule existence_of_ExpFuture[OF N_def Y_def])
next
  fix s assume "s \<in> S" "s \<notin> S - (Y - ?F)"
  then have "s \<in> Y" "s \<notin> ?F" by auto
  have "(\<Sum>s'\<in>S. (if s' = s then \<tau> s s' - 1 else \<tau> s s') * l s') = 
    (\<Sum>s'\<in>S. \<tau> s s' * l s' - (if s' = s then 1 else 0) * l s')"
    by (auto intro!: setsum.cong simp: field_simps)
  also have "\<dots> = (\<Sum>s'\<in>S. \<tau> s s' * l s') - l s"
    using `s \<in> S` by (simp add: setsum_subtractf single_l)
  finally have "l s = (\<Sum>s'\<in>S. \<tau> s s' * l s') - (\<Sum>s'\<in>S. (if s' = s then \<tau> s s' - 1 else \<tau> s s') * l s')"
    by (simp add: field_simps)
  then show "l s - (\<rho> s + (\<Sum>s'\<in>S. \<tau> s s' * \<iota> s s')) = (\<Sum>s'\<in>S. \<tau> s s' * l s')"
    using sol[OF `s \<in> S`] `s \<in> Y` `s \<notin> ?F` by (simp add: const_def LES_def)
next
  fix s assume s: "s \<in> S - (Y - ?F)"
  with sol[of s] have "l s = 0"
    by (cases "s \<in> ?F") (simp_all add: const_def LES_def single_l)
  also have "0 = real (\<integral>\<^sup>+\<omega>. reward (Future F) (case_nat s \<omega>) \<partial>paths s)"
  proof cases
    assume "s \<in> ?F"
    with s svalid_subset_S have s: "s \<in> ?F" "s \<in> S" by auto
    then have "\<And>\<omega>. (LEAST i. case_nat s \<omega> i \<in> ?F) = 0" "\<And>\<omega>. \<exists>i. case_nat s \<omega> i \<in> ?F"
      by (auto intro!: Least_equality exI[of _ 0])
    then show ?thesis by simp
  next
    assume "s \<notin> ?F"
    with s have "s \<in> S - Y" by auto
    with infinite_reward[of s F] show ?thesis
      by (simp add: Y_def N_def del: reward.simps)
  qed
  finally show "l s = real (\<integral>\<^sup>+\<omega>. ?R (case_nat s \<omega>) \<partial>paths s)" .
qed

subsection {* Soundness of @{const Sat} *}

theorem Sat_sound:
  "Sat F \<noteq> None \<Longrightarrow> Sat F = Some (svalid F)"
proof (induct F rule: Sat.induct)
  case (5 rel r F)
  { fix q assume "q \<in> S" 
    with svalid_subset_S have "setsum (\<tau> q) (svalid F) = \<P>(\<omega> in paths q. \<omega> 0 \<in> svalid F)"
      by (subst prob_paths_0[OF `q\<in>S`]) (auto simp add: prob_K simp del: space_eq_S intro!: setsum.cong) }
  with 5 show ?case
    by (auto simp: space_PiM PiE_def split: split_option_bind_asm)

next
  case (6 rel r k F1 F2)
  then show ?case
    by (simp add: ProbU cong: conj_cong split: split_option_bind_asm)

next
  case (7 rel r F1 F2)
  moreover def constants \<equiv> "\<lambda>s::'s. if s \<in> (svalid F2) then 1 else (0::real)"
  moreover def distr \<equiv> "LES (Prob0 (svalid F1) (svalid F2) \<union> svalid F2)"
  ultimately obtain l where eq: "Sat F1 = Some (svalid F1)" "Sat F2 = Some (svalid F2)"
    and l: "gauss_jordan' distr constants = Some l"
    by atomize_elim (simp add: ProbUinfty_def split: split_option_bind_asm)
    
  from l have P: "ProbUinfty (svalid F1) (svalid F2) = Some l"
    unfolding ProbUinfty_def constants_def distr_def by simp

  have "\<forall>s\<in>S. l s = (prob s (pvalid s (U\<^sup>\<infinity> F1 F2)))"
  proof (rule uniqueness_of_ProbU)
    show "\<forall>s\<in>S. (\<Sum>s'\<in>S. LES (Prob0 (svalid F1) (svalid F2) \<union> svalid F2) s s' * l s') =
                   (if s \<in> svalid F2 then 1 else 0)"
      using gauss_jordan'_correct[OF l]
      unfolding distr_def constants_def by simp
  qed
  then show ?case
    by (auto simp add: eq P)
next
  case (8 rel r k)
  { fix s assume "s \<in> S"
    then have "ExpCumm s k = (\<integral>\<^sup>+ x. ereal (\<Sum>i<k. \<rho> (case_nat s x i) + \<iota> (case_nat s x i) (x i)) \<partial>paths s)"
    proof (induct k arbitrary: s)
      case 0 then show ?case by simp
    next
      case (Suc k) 
      have "(\<integral>\<^sup>+\<omega>. ereal (\<Sum>i<Suc k. \<rho> (case_nat s \<omega> i) + \<iota> (case_nat s \<omega> i) (\<omega> i)) \<partial>paths s)
        = (\<integral>\<^sup>+\<omega>. ereal (\<rho> s + \<iota> s (\<omega> 0)) + ereal (\<Sum>i<k. \<rho> (\<omega> i) + \<iota> (\<omega> i) (\<omega> (Suc i))) \<partial>paths s)"
        by (auto intro!: nn_integral_cong
                 simp: setsum.reindex lessThan_Suc_eq_insert_0 zero_notin_Suc_image)
      also have "\<dots> = (\<integral>\<^sup>+\<omega>. \<rho> s + \<iota> s (\<omega> 0) \<partial>paths s) + 
          (\<integral>\<^sup>+\<omega>. (\<Sum>i<k. \<rho> (\<omega> i) + \<iota> (\<omega> i) (\<omega> (Suc i))) \<partial>paths s)"
        using `s \<in> S`
        by (intro nn_integral_add AE_I2)
           (auto intro!: setsum_nonneg add_nonneg_nonneg simp: space_PiM)
      also have "\<dots> = (\<Sum>s'\<in>S. \<tau> s s' * (\<rho> s + \<iota> s s')) + 
        (\<integral>\<^sup>+\<omega>. (\<Sum>i<k. \<rho> (\<omega> i) + \<iota> (\<omega> i) (\<omega> (Suc i))) \<partial>paths s)"
        using `s \<in> S` by (subst nn_integral_paths_0) (auto simp: nn_integral_K)
      also have "\<dots> = (\<Sum>s'\<in>S. \<tau> s s' * (\<rho> s + \<iota> s s')) + 
        (\<Sum>s'\<in>S. \<tau> s s' * ExpCumm s' k)"
        using `s \<in> S` by (subst nn_integral_eq_sum) (auto simp: Suc)
      also have "\<dots> = ExpCumm s (Suc k)"
        using `s \<in> S`
        by (simp add: field_simps setsum.distrib setsum_right_distrib[symmetric] \<tau>_distr setsum_ereal[symmetric]
                    del: setsum_ereal)
           (simp add: ereal_pos_distrib setsum.distrib ac_simps add_assoc[symmetric])
      finally show ?case by simp
    qed }
  then show ?case by auto

next
  case (9 rel r k)
  { fix s assume "s \<in> S"
    then have "ExpState s k = (\<integral>\<^sup>+ x. ereal (\<rho> (case_nat s x k)) \<partial>paths s)"
    proof (induct k arbitrary: s)
      case 0 with emeasure_space_1 show ?case by simp
    next
      case (Suc k) then show ?case by (simp add: nn_integral_eq_sum[of s])
    qed }
  then show ?case by auto

next
  case (10 rel r F)
  moreover
  let ?F = "svalid F"
  def N \<equiv> "Prob0 S ?F"
  moreover def Y \<equiv> "Prob1 N S ?F"
  moreover def const \<equiv> "\<lambda>s. if s \<in> Y \<and> s \<notin> ?F then - \<rho> s - (\<Sum>s'\<in>S. \<tau> s s' * \<iota> s s') else 0"
  ultimately obtain l
    where l: "gauss_jordan' (LES (S - Y \<union> ?F)) const = Some l"
    and F: "Sat F = Some ?F"
    by (auto simp: ExpFuture_def Let_def split: split_option_bind_asm)
  
  from l have EF: "ExpFuture ?F =
    Some (\<lambda>s. if s \<in> Y then ereal (l s) else \<infinity>)"
    unfolding ExpFuture_def N_def Y_def const_def by auto

  let "?R \<omega>" = "reward (Future F) \<omega>"
  have l_eq: "\<forall>s\<in>S. l s = real(\<integral>\<^sup>+\<omega>. ?R (case_nat s \<omega>) \<partial>paths s)"
  proof (rule uniqueness_of_ExpFuture[OF N_def Y_def const_def])
    fix s assume "s \<in> S"
    show "\<And>s. s\<in>S \<Longrightarrow> (\<Sum>s'\<in>S. LES (S - Y \<union> ?F) s s' * l s') = const s"
      using gauss_jordan'_correct[OF l] by auto
  qed

  { fix s assume [simp]: "s \<in> S" "s \<in> Y"
    then have "s \<in> Prob1 (Prob0 S ?F) S ?F"
      unfolding Y_def N_def by auto
    then have "AE \<omega> in paths s. case_nat s \<omega> \<in> until S ?F"
      using svalid_subset_S by (auto simp add: Prob1_iff)
    from nn_integral_reward_finite[OF `s \<in> S`] this nn_integral_nonneg
    have "\<bar>\<integral>\<^sup>+\<omega>. reward (Future F) (case_nat s \<omega>) \<partial>paths s\<bar> \<noteq> \<infinity>"
      by (simp add: nn_integral_nonneg)
    with l_eq `s \<in> S` have "ereal (l s) = (\<integral>\<^sup>+\<omega>. reward (Future F) (case_nat s \<omega>) \<partial>paths s)"
      by auto }
  moreover
  { fix s assume "s \<in> S" "s \<notin> Y"
    with infinite_reward[of s F]
    have "\<infinity> = (\<integral>\<^sup>+\<omega>. reward (Future F) (case_nat s \<omega>) \<partial>paths s)"
      by (simp add: Y_def N_def) }
  ultimately show ?case
    apply (auto simp add: EF F simp del: reward.simps)
    apply (case_tac "x \<in> Y")
    apply auto
    done
qed (auto split: split_option_bind_asm)

subsection {* Completeness of @{const Sat} *}

theorem Sat_complete:
  "Sat F \<noteq> None"
proof (induct F rule: Sat.induct)
  case (7 r rel \<Phi> \<Psi>)
  then have F: "Sat \<Phi> = Some (svalid \<Phi>)" "Sat \<Psi> = Some (svalid \<Psi>)"
    by (auto intro!: Sat_sound)

  def constants \<equiv> "\<lambda>s::'s. if s \<in> svalid \<Psi> then 1 else (0::real)"
  def distr \<equiv> "LES (Prob0 (svalid \<Phi>) (svalid \<Psi>) \<union> svalid \<Psi>)" 
  have "\<exists>l. gauss_jordan' distr constants = Some l"
  proof (rule gauss_jordan'_complete[OF _ uniqueness_of_ProbU])
    show "\<forall>s\<in>S. (\<Sum>s'\<in>S. distr s s' * prob s' (pvalid s' (U\<^sup>\<infinity> \<Phi> \<Psi>))) = constants s"
      apply (simp add: distr_def constants_def LES_def del: pvalid.simps)
    proof safe
      fix s assume "s \<in> svalid \<Psi>" "s \<in> S"
      then show "(\<Sum>s'\<in>S. (if s' = s then 1 else 0) * prob s' (pvalid s' (U\<^sup>\<infinity> \<Phi> \<Psi>))) = 1"
        by (simp add: single_l)
    next
      fix s assume s: "s \<notin> svalid \<Psi>" "s \<in> S"
      let ?x = "\<lambda>s'. prob s' (pvalid s' (U\<^sup>\<infinity> \<Phi> \<Psi>))"
      show "(\<Sum>s'\<in>S. (if s \<in> Prob0 (svalid \<Phi>) (svalid \<Psi>) then if s' = s then 1 else 0 else if s' = s then \<tau> s s' - 1 else \<tau> s s') * ?x s') = 0"
      proof cases
        assume "s \<in> Prob0 (svalid \<Phi>) (svalid \<Psi>)"
        with s show ?thesis
          by (simp del: pvalid.simps
                   add: emeasure_eq_measure single_l Prob0_iff svalid_subset_S pvalid_eq_until
                        AE_iff_measurable[OF _ refl] space_PiM PiE_def Int_def conj_commute)
      next
        assume s_not_0: "s \<notin> Prob0 (svalid \<Phi>) (svalid \<Psi>)"
        { fix s' assume "s' \<in> S"
          from s s_not_0 `s \<in> S` svalid_subset_S have "s \<in> svalid \<Phi>"
            by (rule_tac ccontr) (auto simp: Prob0_iff)
          with `s' \<in> S` s
          have "pvalid s' (U\<^sup>\<infinity> \<Phi> \<Psi>) = case_nat s' -` pvalid s (U\<^sup>\<infinity> \<Phi> \<Psi>) \<inter> (UNIV \<rightarrow> S)"
            by (cases "s' \<in> svalid \<Phi>" "s' \<in> svalid \<Psi>" rule: bool.exhaust[case_product bool.exhaust])
          (auto split: nat.split simp: Pi_iff gr0_conv_Suc) }
        note * = this
        
        have "(\<Sum>s'\<in>S. (if s' = s then \<tau> s s' - 1 else \<tau> s s') * ?x s') =
          (\<Sum>s'\<in>S. \<tau> s s' * ?x s' - (if s' = s then 1 else 0) * ?x s')"
          by (auto intro!: setsum.cong simp: field_simps)
        also have "\<dots> = (\<Sum>s'\<in>S. \<tau> s s' * ?x s') - ?x s"
          using s by (simp add: single_l setsum_subtractf)
        finally show ?thesis
          using s_not_0 * prob_eq_sum[OF `s \<in> S` pvalid_sets, of _ "U\<^sup>\<infinity> \<Phi> \<Psi>"] s_not_0
          by (simp del: pvalid.simps)
      qed
    qed
  qed (simp add: distr_def constants_def)
  then have P: "\<exists>l. ProbUinfty (svalid \<Phi>) (svalid \<Psi>) = Some l"
    unfolding ProbUinfty_def constants_def distr_def by simp
  with F show ?case
    by auto
next
  case (10 rel r \<Phi>)
  then have F: "Sat \<Phi> = Some (svalid \<Phi>)"
    by (auto intro!: Sat_sound)

  let ?F = "svalid \<Phi>"
  def N \<equiv> "Prob0 S ?F"
  def Y \<equiv> "Prob1 N S ?F"
  def const \<equiv> "\<lambda>s. if s \<in> Y \<and> s \<notin> ?F then - \<rho> s - (\<Sum>s'\<in>S. \<tau> s s' * \<iota> s s') else 0"
  let "?E s'" = "\<integral>\<^sup>+ \<omega>. reward (Future \<Phi>) (case_nat s' \<omega>) \<partial>paths s'"
  have "\<exists>l. gauss_jordan' (LES (S - Y \<union> ?F)) const = Some l"
  proof (rule gauss_jordan'_complete[OF _ uniqueness_of_ExpFuture[OF N_def Y_def const_def]])
    show "\<forall>s\<in>S. (\<Sum>s'\<in>S. LES (S - Y \<union> svalid \<Phi>) s s' * real (?E s')) = const s"
    proof
      fix s assume "s \<in> S"
      show "(\<Sum>s'\<in>S. LES (S - Y \<union> svalid \<Phi>) s s' * real (?E s')) = const s"
      proof cases
        assume s: "s \<in> S - (Y - svalid \<Phi>)"
        show ?thesis
        proof cases
          assume "s \<in> Y"
          with s have "\<And>\<omega>. \<exists>i. case_nat s \<omega> i \<in> svalid \<Phi>" "\<And>\<omega>. (LEAST i. case_nat s \<omega> i \<in> svalid \<Phi>) = 0"
            by (auto intro!: exI[of _ 0] Least_equality)
          with `s \<in> S` s `s \<in> Y` show ?thesis
            by (simp add: LES_def const_def single_l)
        next
          assume "s \<notin> Y"
          with infinite_reward[of s \<Phi>] Y_def N_def s `s \<in> S`
          show ?thesis by (simp add: const_def LES_def single_l del: reward.simps)
        qed
      next
        assume s: "s \<notin> S - (Y - svalid \<Phi>)"

        have "(\<Sum>s'\<in>S. (if s' = s then \<tau> s s' - 1 else \<tau> s s') * real (?E s')) =
          (\<Sum>s'\<in>S. \<tau> s s' * real (?E s') - (if s' = s then 1 else 0) * real (?E s'))"
          by (auto intro!: setsum.cong simp: field_simps)
        also have "\<dots> = (\<Sum>s'\<in>S. \<tau> s s' * real (?E s')) - real (?E s)"
          using `s \<in> S` by (simp add: setsum_subtractf single_l)
        finally show ?thesis
          using s `s \<in> S` existence_of_ExpFuture[OF N_def Y_def `s \<in> S` s]
          by (simp add: LES_def const_def del: reward.simps)
      qed
    qed
  qed simp
  then have P: "\<exists>l. ExpFuture (svalid \<Phi>) = Some l"
    unfolding ExpFuture_def const_def N_def Y_def by auto
  with F show ?case
    by auto
qed (force split: split_option_bind)+

subsection {* Completeness and Soundness @{const Sat} *}

corollary Sat: "Sat \<Phi> = Some (svalid \<Phi>)"
  using Sat_sound Sat_complete by auto

end

end
