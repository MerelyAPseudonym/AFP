theory Girth_Chromatic_Misc
imports
  "~~/src/HOL/Main"
  "~~/src/HOL/Library/Extended_Real"
  "~~/src/HOL/Number_Theory/Binomial"
begin

section {* Auxilliary lemmas and setup *}

text {*
  This section contains facts about general concepts which are not directly
  connected to the proof of the Chromatic-Girth theorem. At some point in time,
  most of them could be moved to the Isabelle base library.

  Also, a little bit of setup happens.
*}

text {*
  We employ filters and the @{term eventually} predicate to deal with the
  @{term "\<exists>N. \<forall>n\<ge>N. P n"} cases. To make this more convenient, introduce
  a shorter syntax.
*}

abbreviation evseq :: "(nat \<Rightarrow> bool) \<Rightarrow> bool" (binder "\<forall>\<^isup>\<infinity>" 10) where
  "evseq P \<equiv> eventually P sequentially"

text {* Remove non-standard induction rule for nat (installed by Cong (via Binomial)) *}
declare Cong.induct'_nat[induct del]

section {* Lemmas to be removed for post-Isabelle 2011 *}

lemmas enat2_cases = enat.exhaust[case_product enat.exhaust]

lemma ereal_of_enat_simps[simp]:
  "ereal_of_enat (enat n) = ereal n"
  "ereal_of_enat \<infinity> = \<infinity>"
  by (simp_all add: ereal_of_enat_def)

lemma ereal_of_enat_le_iff[simp]:
  "ereal_of_enat m \<le> ereal_of_enat n \<longleftrightarrow> m \<le> n"
by (cases m n rule: enat2_cases) auto
lemma ereal_of_enat_gt_zero_cancel_iff[simp]:
  "0 < ereal_of_enat n \<longleftrightarrow> 0 < n"
by (cases n) (auto simp: enat_0[symmetric])

lemma ereal_of_enat_mult:
  "ereal_of_enat (m * n) = ereal_of_enat m * ereal_of_enat n"
by (cases m n rule: enat2_cases) (auto simp: enat_0[symmetric])

lemma atLeastAtMost_insertL: "m \<le> n \<Longrightarrow> insert m {Suc m..n} = {m ..n}"
by auto

lemma Suc_diff_Suc: "n < m \<Longrightarrow> Suc (m - Suc n) = m - n"
by simp

lemma card_lists_distinct_length_eq:
  assumes "k < card A"
  shows "card {xs. length xs = k \<and> distinct xs \<and> set xs \<subseteq> A} = \<Prod>{card A - k + 1 .. card A}"
using assms
proof (induct k)
  case 0
  then have "{xs. length xs = 0 \<and> distinct xs \<and> set xs \<subseteq> A} = {[]}" by auto
  then show ?case by simp
next
  case (Suc k)
  let "?k_list" = "\<lambda>k xs. length xs = k \<and> distinct xs \<and> set xs \<subseteq> A"
  have inj_Cons: "\<And>A. inj_on (\<lambda>(xs, n). n # xs) A"  by (rule inj_onI) auto

  from Suc have "k < card A" by simp
  moreover have "finite A" using assms by (simp add: card_ge_0_finite)
  moreover have "finite {xs. ?k_list k xs}"
    using finite_lists_length_eq[OF `finite A`, of k]
    by - (rule finite_subset, auto)
  moreover have "\<And>i j. i \<noteq> j \<longrightarrow> {i} \<times> (A - set i) \<inter> {j} \<times> (A - set j) = {}"
    by auto
  moreover have "\<And>i. i \<in>Collect (?k_list k) \<Longrightarrow> card (A - set i) = card A - k"
    by (simp add: card_Diff_subset distinct_card)
  moreover have "{xs. ?k_list (Suc k) xs} =
      (\<lambda>(xs, n). n#xs) ` \<Union>(\<lambda>xs. {xs} \<times> (A - set xs)) ` {xs. ?k_list k xs}"
    by (auto simp: length_Suc_conv)
  moreover
  have "Suc (card A - Suc k) = card A - k" using Suc.prems by simp
  then have "(card A - k) * \<Prod>{Suc (card A - k)..card A} = \<Prod>{Suc (card A - Suc k)..card A}"
    by (subst setprod_insert[symmetric]) (simp add: atLeastAtMost_insertL)+
  ultimately show ?case
    by (simp add: card_image inj_Cons card_UN_disjoint Suc.hyps algebra_simps)
qed

lemma eventually_subst:
  assumes "eventually (\<lambda>n. P n = Q n) F"
  shows "eventually P F = eventually Q F" (is "?L = ?R")
proof -
  from assms have "eventually (\<lambda>x. P x \<longrightarrow> Q x) F"
      and "eventually (\<lambda>x. Q x \<longrightarrow> P x) F"
    by (auto elim: eventually_elim1)
  then show ?thesis by (auto elim: eventually_elim2)
qed

lemma eventually_sequentiallyI:
  assumes "\<And>x. c \<le> x \<Longrightarrow> P x"
  shows "eventually P sequentially"
using assms by (auto simp: eventually_sequentially)

lemma tendsto_zero_powrI:
  assumes "eventually (\<lambda>x. 0 < f x ) F" and "(f ---> 0) F"
  assumes "0 < d"
  shows "((\<lambda>x. f x powr d) ---> 0) F"
proof (rule tendstoI)
  fix e :: real assume "0 < e"
  def Z \<equiv> "e powr (1 / d)"
  with `0 < e` have "0 < Z" by simp
  with assms have "eventually (\<lambda>x. 0 < f x \<and> dist (f x) 0 < Z) F"
    by (intro eventually_conj tendstoD)
  moreover
  from assms have "\<And>x. 0 < x \<and> dist x 0 < Z \<Longrightarrow> x powr d < Z powr d"
    by (intro powr_less_mono2) (auto simp: dist_real_def)
  with assms `0 < e` have "\<And>x. 0 < x \<and> dist x 0 < Z \<Longrightarrow> dist (x powr d) 0 < e"
    unfolding dist_real_def Z_def by (auto simp: powr_powr)
  ultimately
  show "eventually (\<lambda>x. dist (f x powr d) 0 < e) F" by (rule eventually_elim1)
qed

definition real_tendsto_inf :: "('a \<Rightarrow> real) \<Rightarrow> 'a filter \<Rightarrow> bool" where
  "real_tendsto_inf f F \<equiv> \<forall>x. eventually (\<lambda>y. x < f y) F"

lemma real_tendsto_inf_real: "real_tendsto_inf real sequentially"
proof (unfold real_tendsto_inf_def, rule allI)
  fix x show "eventually (\<lambda>y. x < real y) sequentially"
    by (rule eventually_sequentiallyI[of "natceiling (x + 1)"])
        (simp add: natceiling_le_eq)
qed

lemma tendsto_neg_powr:
  assumes "s < 0" and "real_tendsto_inf f F"
  shows "((\<lambda>x. f x powr s) ---> 0) F"
proof (rule tendstoI)
  fix e :: real assume "0 < e"
  def Z \<equiv> "e powr (1 / s)"
  from assms have "eventually (\<lambda>x. Z < f x) F" by (simp add: real_tendsto_inf_def)
  moreover
  from assms have "\<And>x. Z < x \<Longrightarrow> x powr s < Z powr s"
    by (auto simp: Z_def intro!: powr_less_mono2_neg)
  with assms `0 < e` have "\<And>x. Z < x \<Longrightarrow> dist (x powr s) 0 < e"
    by (simp add: powr_powr Z_def dist_real_def)
  ultimately
  show "eventually (\<lambda>x. dist (f x powr s) 0 < e) F" by (rule eventually_elim1)
qed

lemma powr_mult_base:
  "0 < x \<Longrightarrow>x * x powr y = x powr (1 + y)"
using assms by (auto simp: powr_add)

lemma real_tendsto_sandwich:
  fixes f g h :: "'a \<Rightarrow> real"
  assumes ev: "eventually (\<lambda>n. f n \<le> g n) net" "eventually (\<lambda>n. g n \<le> h n) net"
  assumes lim: "(f ---> c) net" "(h ---> c) net"
  shows "(g ---> c) net"
proof -
  have "((\<lambda>n. g n - f n) ---> 0) net"
  proof (rule metric_tendsto_imp_tendsto)
    show "eventually (\<lambda>n. dist (g n - f n) 0 \<le> dist (h n - f n) 0) net"
      using ev by (rule eventually_elim2) (simp add: dist_real_def)
    show "((\<lambda>n. h n - f n) ---> 0) net"
      using tendsto_diff[OF lim(2,1)] by simp
  qed
  from tendsto_add[OF this lim(1)] show ?thesis by simp
qed


section {* Other Lemmas *}
subsection {* Numbers *}

lemma ereal_divide_right_mono:
  fixes a b c :: ereal
  assumes "a \<le> b" "0 < c"
  shows "a / c \<le> b / c"
using assms by (cases a b c rule: ereal3_cases) (auto intro: divide_right_mono)

lemma ereal_divide_left_mono:
  fixes a b c :: ereal
  assumes "b \<le> a" "0 < c" "0 < a * b"
  shows "c / a \<le> c / b"
using assms by (cases a b c rule: ereal3_cases)
  (auto intro: divide_left_mono simp: field_simps sign_simps split: split_if_asm)

thm ereal_of_enat_simps
lemma ereal_of_enat_less_iff: "ereal_of_enat a < ereal_of_enat b \<longleftrightarrow> a < b"
  by (cases a b rule: enat2_cases) auto


lemma ereal_of_enat_inf: "ereal_of_enat a = \<infinity> \<longleftrightarrow> a = \<infinity>"
  by (cases a) auto

lemma enat_in_Inf:
  fixes S :: "enat set"
  assumes "Inf S \<noteq> top"
  shows "Inf S \<in> S"
proof (rule ccontr)
  assume A: "~?thesis"

  obtain n where Inf_conv: "Inf S = enat n" using assms by (auto simp: top_enat_def)
  { fix s assume "s \<in> S"
    then have "Inf S \<le> s" by (rule complete_lattice_class.Inf_lower)
    moreover have "Inf S \<noteq> s" using A `s \<in> S` by auto
    ultimately have "Inf S < s" by simp
    with Inf_conv have "enat (Suc n) \<le> s" by (cases s) auto
  }
  then have "enat (Suc n) \<le> Inf S" by (simp add: le_Inf_iff)
  with Inf_conv show False by auto
qed

lemma enat_in_INF:
  fixes f :: "'a \<Rightarrow> enat"
  assumes "(INF x: S. f x) \<noteq> top"
  obtains x where "x \<in> S" and "(INF x: S. f x) = f x"
proof -
  from assms have "(INF x: S. f x) \<in> f ` S"
    unfolding INF_def using enat_in_Inf by auto
  then obtain x where "x \<in> S" "(INF x: S. f x) = f x" by auto
  then show ?thesis ..
qed

lemma enat_less_INF_I:
  fixes f :: "'a \<Rightarrow> enat"
  assumes not_inf: "x \<noteq> \<infinity>" and less: "\<And>y. y \<in> S \<Longrightarrow> x < f y"
  shows "x < (INF y:S. f y)"
proof (rule ccontr)
  assume A: "\<not>?thesis"
  then show False
  proof (cases "x = (INF y:S. f y)")
    case True
    with assms have "(INF y:S. f y) \<noteq> top" by (simp add: top_enat_def)
    then obtain z where "z \<in> S" "f z = x"
      by (rule enat_in_INF) (auto simp: True)
    then show False using less by auto
  next
    case False
    with A have "(INF y:S. f y) < x" by simp
    with less show False by (auto simp: INF_less_iff intro: order_less_asym)
  qed
qed

lemma enat_le_Sup_iff:
  "enat k \<le> Sup M \<longleftrightarrow> k = 0 \<or> (\<exists>m \<in> M. enat k \<le> m)" (is "?L \<longleftrightarrow> ?R")
proof cases
  assume "k = 0" then show ?thesis by (auto simp: enat_0)
next
  assume "k \<noteq> 0"
  show ?thesis
  proof
    assume ?L
    then have "\<lbrakk>enat k \<le> (if finite M then Big_Operators.Max M else \<infinity>); M \<noteq> {}\<rbrakk> \<Longrightarrow> \<exists>m\<in>M. enat k \<le> m"
      by (metis Max_in Sup_enat_def finite_enat_bounded linorder_linear)
    with `k \<noteq> 0` and `?L` show ?R
      unfolding Sup_enat_def
      by (cases "M={}") (auto simp add: enat_0[symmetric])
  next
    assume ?R then show ?L
      by (auto simp: enat_0 intro: complete_lattice_class.Sup_upper2)
  qed
qed

lemma enat_neq_zero_cancel_iff[simp]:
  "0 \<noteq> enat n \<longleftrightarrow> 0 \<noteq> n"
  "enat n \<noteq> 0 \<longleftrightarrow> n \<noteq> 0"
by (auto simp: enat_0[symmetric])


lemma natceiling_lessD:
  assumes "natceiling x < n" shows "x < real n"
proof -
  from assms have "natceiling x \<le> n - 1" and "0 < n" by auto
  then have "x \<le> real (n - 1)" by (simp add: natceiling_le_eq)
  then show ?thesis using `0 < n` by auto
qed

lemma le_natceiling_iff:
  fixes n :: nat and r :: real
  assumes "n \<le> r"
  shows "n \<le> natceiling r"
proof -
  from assms have "n \<le> ceiling r" by (simp add: le_ceiling_eq)
  then show ?thesis by (simp add: natceiling_def)
qed

lemma natceiling_le_iff:
  fixes n :: nat and r :: real
  assumes "r \<le> n"
  shows "natceiling r \<le> n"
proof -
  from assms have "ceiling r \<le> n" by (simp add: ceiling_le_eq)
  then show ?thesis by (simp add: natceiling_def)
qed

lemma dist_real_noabs_less:
  fixes a b c :: real assumes "dist a b < c" shows "a - b < c"
using assms by (simp add: dist_real_def)


lemma fact_div_fact_le_pow:
  assumes "r \<le> n" shows "fact n div fact (n - r) \<le> n ^ r"
proof -
  have "\<And>r. r \<le> n \<Longrightarrow> \<Prod>{n - r..n} = (n - r) * \<Prod>{Suc (n - r)..n}"
    by (subst setprod_insert[symmetric]) (auto simp: atLeastAtMost_insertL)
  with assms show ?thesis
    by (induct r rule: nat.induct) (auto simp add: fact_div_fact Suc_diff_Suc mult_le_mono)
qed

lemma choose_le_pow:
  assumes "r \<le> n" shows "n choose r \<le> n ^ r"
proof -
  have "n choose r \<le> fact n div fact (n - r)"
    using `r \<le> n` by (simp add: choose_altdef_nat div_le_mono2)
  with fact_div_fact_le_pow[OF assms] show ?thesis by auto
qed

lemma n_choose_2_nat:
  fixes n :: nat shows "(n choose 2) = (n * (n - 1)) div 2"
proof -
  show ?thesis
  proof (cases "2 \<le> n")
    case True
    then obtain m where "n = Suc (Suc m)"
      by (metis add_Suc le_Suc_ex numeral_2_eq_2)
    moreover have "(n choose 2) = (fact n div fact (n - 2)) div 2"
      using `2 \<le> n` by (simp add: choose_altdef_nat
        div_mult2_eq[symmetric] nat_mult_commute numeral_2_eq_2)
    ultimately show ?thesis by (simp add: algebra_simps)
  qed (auto simp: not_le)
qed

lemma powr_less_one:
  assumes "1 < x" "y < 0"
  shows "x powr y < 1"
using assms by (metis powr_less_cancel_iff powr_zero_eq_one)

lemma powr_le_one_le: "\<And>x y. 0 < x \<Longrightarrow> x \<le> 1 \<Longrightarrow> 1 \<le> y \<Longrightarrow> x powr y \<le> x"
proof -
  fix x y :: real
  assume "0 < x" "x \<le> 1" "1 \<le> y"
  have "x powr y = (1 / (1 / x)) powr y" using `0 < x` by (simp add: field_simps)
  also have "\<dots> = 1 / (1 / x) powr y" using `0 < x` by (simp add: powr_divide)
  also have "\<dots> \<le> 1 / (1 / x) powr 1" proof -
    have "1 \<le> 1 / x" using `0 < x` `x \<le> 1` by (auto simp: field_simps)
    then have "(1 / x) powr 1  \<le> (1 / x) powr y" using `0 < x`
      using `1 \<le> y` by ( simp only: powr_mono)
    then show ?thesis by (auto simp: field_simps)
  qed
  also have "\<dots> \<le> x" using `0 < x` by (auto simp: field_simps)
  finally show "?thesis x y" .
qed


subsection {* Lists and Sets *}

lemma list_set_tl: "x \<in> set (tl xs) \<Longrightarrow> x \<in> set xs"
by (cases xs) auto

lemma list_exhaust3:
  obtains "xs = []" | x where "xs = [x]" | x y ys where "xs = x # y # ys"
by (metis list.exhaust)

lemma card_Ex_subset:
  "k \<le> card M \<Longrightarrow> \<exists>N. N \<subseteq> M \<and> card N = k"
by (induct rule: inc_induct) (auto simp: card_Suc_eq)

lemma card_0_iff: "card A = 0 \<longleftrightarrow> A = {} \<or> \<not>finite A"
  by auto


subsection {* Limits and eventually *}

lemma eventually_le_le:
  fixes P :: "'a => ('b :: preorder)"
  assumes "eventually (\<lambda>x. P x \<le> Q x) net"
  assumes "eventually (\<lambda>x. Q x \<le> R  x) net"
  shows "eventually (\<lambda>x. P x \<le> R x) net"
using assms by (rule eventually_elim2) (rule order_trans)

lemma eventually_sequentially_lessI:
  assumes "\<And>x. c < x \<Longrightarrow> P x"
  shows "eventually P sequentially" 
unfolding eventually_sequentially
by (rule exI[where x="Suc c"]) (auto intro: assms)

lemma LIMSEQ_neg_powr:
  assumes s: "s < 0"
  shows "(%x. (real x) powr s) ----> 0"
by (rule tendsto_neg_powr[OF assms real_tendsto_inf_real])

lemma LIMSEQ_inv_powr:
  assumes "0 < c" "0 < d"
  shows "(\<lambda>n :: nat. (c / n) powr d) ----> 0"
proof (rule tendsto_zero_powrI)
  from `0 < c` have "\<And>x. 0 < x \<Longrightarrow> 0 < c / x" by (rule divide_pos_pos) 
  then show "eventually (\<lambda>x. 0 < c / real x) sequentially"
     by (rule eventually_sequentiallyI[of 1]) simp

  show "(\<lambda>x. c / real x) ----> 0"
  proof (rule tendstoI)
    fix e :: real assume "0 < e"
    then have "\<And>x. 0 < x \<Longrightarrow> c / x < e \<longleftrightarrow> c / e < x"
      by (auto simp: field_simps)
    then show "eventually (\<lambda>x. dist (c / real x) 0 < e) sequentially"
      using `0 < c` `0 < e`
      by (intro eventually_sequentially_lessI[of "natceiling (c/e)"])
         (auto simp: dist_real_def natceiling_lessD)
  qed
  show "0 < d" by (rule assms)
qed


end
