(*  Title:      LList2.thy
    ID:         $Id: LList2.thy,v 1.2 2004-05-25 14:18:34 lsf37 Exp $
    Author:     Stefan Friedrich
    Maintainer: Stefan Friedrich
    License:    LGPL

More on llists.
Llists over an alphabet.
Common operations on LLists (ltake, ldrop, lnth).
The prefix order of llists.
Safety and liveness.

*)

header{*\isaheader{LList2}*}

theory LList2 = LList:

section{*Preliminaries*}

syntax
  LCons :: "'a \<Rightarrow> 'a llist \<Rightarrow> 'a llist" (infixr "##" 65)
  lappend :: "['a llist, 'a llist] => 'a llist" (infixr "@@" 65)

lemmas lappend_assoc = lappend_assoc'

lemmas llistE [case_names LNil LCons, cases type: llist]

lemma llist_split: "P (llist_case f1 f2 x) =
  ((x = LNil \<longrightarrow> P f1) \<and> (\<forall> a xs. x = a ## xs \<longrightarrow> P (f2 a xs)))"
  by (cases "x") auto

lemma llist_split_asm:
"P (llist_case f1 f2 x) =
  (\<not> (x = LNil \<and> \<not> P f1 \<or> (\<exists>a llist. x = a ## llist \<and> \<not> P (f2 a llist))))"
  by (cases "x") auto


section{*Finite and infinite llists over an alphabet*}

consts
  alllsts :: "'a set \<Rightarrow> 'a llist set"
  finlsts :: "'a set \<Rightarrow> 'a llist set"
  inflsts :: "'a set \<Rightarrow> 'a llist set"
  fpslsts :: "'a set \<Rightarrow> 'a llist set"
  poslsts :: "'a set \<Rightarrow> 'a llist set"

syntax (xsymbols)
  alllsts :: "'a set \<Rightarrow> 'a llist set" ("(_\\<^sup>\<infinity>)" [1000] 999)
  finlsts :: "'a set \<Rightarrow> 'a llist set" ("(_\\<^sup>\<star>)" [1000] 999)
  inflsts :: "'a set \<Rightarrow> 'a llist set" ("(_\\<^sup>\<omega>)" [1000] 999)
  fpslsts :: "'a set \<Rightarrow> 'a llist set" ("(_\\<^sup>\<clubsuit>)" [1000] 999)
  poslsts :: "'a set \<Rightarrow> 'a llist set" ("(_\\<^sup>\<spadesuit>)" [1000] 999)

inductive "A\<^sup>\<star>"
  intros
  LNil_fin [iff]: "LNil \<in>  A\<^sup>\<star>"
  LCons_fin [intro!]: "\<lbrakk> l \<in> A\<^sup>\<star>; a \<in> A \<rbrakk> \<Longrightarrow>  a ## l \<in> A\<^sup>\<star>"

coinductive "A\<^sup>\<infinity>"
  intros
  LNil_all [iff]: "LNil \<in> A\<^sup>\<infinity>"
  LCons_all [intro!]: "\<lbrakk> l \<in> A\<^sup>\<infinity>; a \<in> A \<rbrakk> \<Longrightarrow>  a ## l \<in> A\<^sup>\<infinity>"

declare alllsts.cases [case_names LNil LCons, cases set: alllsts]

defs
  inflsts_def: "A\<^sup>\<omega> \<equiv>  A\<^sup>\<infinity> - UNIV\<^sup>\<star>"

  poslsts_def: "A\<^sup>\<spadesuit> \<equiv> A\<^sup>\<infinity> - {LNil}"

  fpslsts_def: "A\<^sup>\<clubsuit> \<equiv> A\<^sup>\<star> - {LNil}"


subsection{*Facts about all llists*}

lemma neq_LNil_conv: "(xs \<noteq> LNil) = (\<exists>y ys. xs = y ## ys)"
  by (cases xs) auto

lemma alllsts_UNIV [iff]:
  "s \<in> UNIV\<^sup>\<infinity>"
proof (rule alllsts.coinduct [of _ "UNIV"], simp)
  fix z :: "'a llist" assume "z \<in> UNIV"
  thus "z = LNil \<or> (\<exists>a l. z = a ## l \<and> l \<in> UNIV \<union> UNIV\<^sup>\<infinity> \<and> a \<in> UNIV)"
    by (cases "z") auto
qed

lemma alllsts_empty [simp]: "{}\<^sup>\<infinity> = {LNil}"
  by (auto elim: alllsts.cases)

lemma alllsts_mono [mono]:
  assumes asubb: "A \<subseteq> B"
  shows "A\<^sup>\<infinity> \<subseteq> B\<^sup>\<infinity>"
proof
  fix x assume "x \<in> A\<^sup>\<infinity>" thus "x \<in> B\<^sup>\<infinity>"
  proof (elim alllsts.coinduct [of _ "A\<^sup>\<infinity>"])
    fix z assume "z \<in> A\<^sup>\<infinity>"
    thus "z = LNil \<or> (\<exists>a l. z = a ## l \<and> l \<in> A\<^sup>\<infinity> \<union> B\<^sup>\<infinity> \<and> a \<in> B)"
      using asubb by (cases "z") auto
  qed
qed

lemma LConsE [iff]: "x##xs \<in> A\<^sup>\<infinity> = (x\<in>A \<and> xs \<in> A\<^sup>\<infinity>)"
  by (auto elim: alllsts.cases)


subsection{*Facts about non-empty (positive) llists*}

lemma poslsts_iff [iff]:
  "(s \<in> A\<^sup>\<spadesuit>) = (s \<in> A\<^sup>\<infinity> \<and> s \<noteq> LNil)"
  by (auto simp: poslsts_def)

lemma poslsts_UNIV [iff]:
  "s \<in> UNIV\<^sup>\<spadesuit> = (s \<noteq> LNil)"
  by auto

lemma poslsts_empty [simp]: "{}\<^sup>\<spadesuit> = {}"
  by auto

lemma poslsts_mono [mono]:
  "A \<subseteq> B \<Longrightarrow> A\<^sup>\<spadesuit> \<subseteq> B\<^sup>\<spadesuit>"
  by (auto dest: alllsts_mono)

subsection{*Facts about finite llists*}

lemma finlsts_empty [simp]: "{}\<^sup>\<star> = {LNil}"
  by (auto elim: finlsts.cases)

lemma finsubsetall: "x \<in> A\<^sup>\<star> \<Longrightarrow> x \<in> A\<^sup>\<infinity>"
  by (induct rule: finlsts.induct) auto

lemma finlsts_mono [mono]:
"A\<subseteq>B \<Longrightarrow> A\<^sup>\<star> \<subseteq> B\<^sup>\<star>"
  by (auto, erule finlsts.induct) auto

lemma finlsts_induct
  [case_names LNil_fin LCons_fin, induct set: finlsts, consumes 1]:
  assumes xA: "x \<in> A\<^sup>\<star>"
  and lnil: "\<And>l. l = LNil \<Longrightarrow> P l"
  and lcons: "\<And>a l. \<lbrakk>l \<in> A\<^sup>\<star>; P l; a \<in> A\<rbrakk> \<Longrightarrow> P (a ## l)"
  shows "P x"
  using xA by (induct "x") (auto intro: lnil lcons)
(*
lemma LCons_finite:
  "a##xs \<in> A\<^sup>\<star> \<Longrightarrow> xs \<in> A\<^sup>\<star>"
  by (erule finlsts.cases) auto
*)

lemma finite_lemma [rule_format]:
  "x \<in> A\<^sup>\<star> \<Longrightarrow> x \<in> B\<^sup>\<infinity> \<longrightarrow> x \<in> B\<^sup>\<star>"
proof (induct rule: finlsts.induct)
  case LNil_fin show ?case by auto
next
  case (LCons_fin a l)
  show ?case
  proof
    assume "a##l \<in> B\<^sup>\<infinity>" thus "a##l \<in> B\<^sup>\<star>" using LCons_fin
      by (cases "a##l") auto
  qed
qed

lemma fin_finite [dest]:
assumes "r \<in> A\<^sup>\<star>" "r \<notin> UNIV\<^sup>\<star>"
  shows "False"
proof-
  have "A \<subseteq> UNIV" by auto
  hence "A\<^sup>\<star> \<subseteq> UNIV\<^sup>\<star>" by (rule finlsts_mono)
  thus ?thesis using prems by auto
qed

lemma finT_simp [simp]:
  "r \<in> A\<^sup>\<star> \<Longrightarrow> r\<in>UNIV\<^sup>\<star>"
  by auto


subsubsection{*A recursion operator for finite llists*}

constdefs
  finlsts_pred :: "('a llist \<times> 'a llist) set"
  "finlsts_pred \<equiv> {(r,s). r \<in> UNIV\<^sup>\<star> \<and> (\<exists>a. a##r = s)}"

  finlsts_rec :: "['b, ['a, 'a llist, 'b] \<Rightarrow> 'b] \<Rightarrow> 'a llist \<Rightarrow> 'b"
  "finlsts_rec c d r \<equiv> if r \<in> UNIV\<^sup>\<star>
  then (wfrec finlsts_pred (%f. llist_case c (%a r. d a r (f r))) r)
  else arbitrary"

lemma finlsts_predI: "r \<in> A\<^sup>\<star> \<Longrightarrow> (r, a##r) \<in> finlsts_pred"
  by (auto simp: finlsts_pred_def)

lemma wf_finlsts_pred: "wf finlsts_pred"
proof (rule wfI [of _ "UNIV\<^sup>\<star>"])
  show "finlsts_pred \<subseteq> UNIV\<^sup>\<star> \<times> UNIV\<^sup>\<star>"
    by (auto simp: finlsts_pred_def elim: finlsts.cases)
next
  fix x::"'a llist" and P::"'a llist \<Rightarrow> bool"
  assume xfin: "x \<in> UNIV\<^sup>\<star>" and H [unfolded finlsts_pred_def]:
    "(\<forall>x. (\<forall>y. (y, x) \<in> finlsts_pred \<longrightarrow> P y) \<longrightarrow> P x)"
  from  xfin show "P x"
  proof(induct x)
    case LNil_fin with H show ?case by blast
  next
    case (LCons_fin a l) with H show ?case by blast
  qed
qed

lemma finlsts_rec_LNil: "finlsts_rec c d LNil = c"
  by (auto simp: wf_finlsts_pred finlsts_rec_def wfrec)

lemma finlsts_rec_LCons:
 "r \<in> A\<^sup>\<star> \<Longrightarrow> finlsts_rec c d (a ## r) = d a r (finlsts_rec c d r)"
  by (auto simp: wf_finlsts_pred finlsts_rec_def wfrec cut_def intro: finlsts_predI)

lemma finlsts_rec_LNil_def:
  "f \<equiv> finlsts_rec c d \<Longrightarrow> f LNil = c"
  by (auto simp: finlsts_rec_LNil)

lemma finlsts_rec_LCons_def:
  "\<lbrakk> f \<equiv> finlsts_rec c d; r \<in> A\<^sup>\<star> \<rbrakk> \<Longrightarrow> f (a ## r) = d a r (f r)"
  by (auto simp: finlsts_rec_LCons)


subsection{*Facts about non-empty (positive) finite llists*}

lemma fpslsts_iff [iff]:
  "(s \<in> A\<^sup>\<clubsuit>) = (s \<in> A\<^sup>\<star> \<and> s \<noteq> LNil)"
  by (auto simp: fpslsts_def)

lemma fpslsts_empty [simp]: "{}\<^sup>\<clubsuit> = {}"
  by auto

lemma fpslsts_mono [mono]:
  "A \<subseteq> B \<Longrightarrow> A\<^sup>\<clubsuit> \<subseteq> B\<^sup>\<clubsuit>"
  by (auto dest: finlsts_mono)

lemma fpslsts_cases [case_names LCons, cases set: fpslsts]:
assumes rfps: "r \<in> A\<^sup>\<clubsuit>"
  and H: "\<And> a rs. \<lbrakk> r = a ## rs; a\<in>A; rs \<in> A\<^sup>\<star> \<rbrakk> \<Longrightarrow> R"
  shows "R"
proof-
  from rfps have "r \<in> A\<^sup>\<star>" and "r \<noteq> LNil" by auto
  thus ?thesis
    by (cases r, simp) (blast intro!: H)
qed


subsection{*Facts about infinite llists*}

lemma inflstsI [intro]:
  "\<lbrakk> x \<in> A\<^sup>\<infinity>; x \<in> UNIV\<^sup>\<star> \<Longrightarrow> False \<rbrakk> \<Longrightarrow> x \<in> A\<^sup>\<omega>"
  by (unfold inflsts_def) auto

lemma inflstsE [elim]:
  "\<lbrakk> x \<in> A\<^sup>\<omega>; \<lbrakk> x \<in> A\<^sup>\<infinity>; x \<notin> UNIV\<^sup>\<star> \<rbrakk> \<Longrightarrow> R \<rbrakk> \<Longrightarrow> R"
  by (unfold inflsts_def) auto

lemma inflsts_empty [simp]: "{}\<^sup>\<omega> = {}"
  by auto

lemma infsubsetall: "x \<in> A\<^sup>\<omega> \<Longrightarrow> x \<in> A\<^sup>\<infinity>"
  by (auto intro: finite_lemma finsubsetall)

lemma inflsts_mono [mono]:
  "A \<subseteq> B \<Longrightarrow> A\<^sup>\<omega> \<subseteq> B\<^sup>\<omega>"
  by (blast dest: alllsts_mono infsubsetall)

lemma inflsts_cases [case_names LCons, cases set: inflsts, consumes 1]:
  assumes sinf: "s \<in> A\<^sup>\<omega>"
  and R: "\<And>a l. \<lbrakk> l \<in> A\<^sup>\<omega>; a \<in> A; s = a ## l \<rbrakk> \<Longrightarrow> R"
  shows "R"
proof -
  from sinf have "s \<in> A\<^sup>\<infinity>" "s \<notin> UNIV\<^sup>\<star>"
    by auto
  then obtain a l where "l \<in> A\<^sup>\<omega>" and "a\<in>A" and "s = a ## l"
    by (cases "s") auto
  thus ?thesis by (rule R)
qed

lemma inflstsI2: "\<lbrakk>a \<in> A; t \<in> A\<^sup>\<omega>\<rbrakk> \<Longrightarrow> a ## t \<in> A\<^sup>\<omega>"
  by  (auto elim: finlsts.cases)

lemma infT_simp [simp]:
  "r \<in> A\<^sup>\<omega> \<Longrightarrow> r\<in>UNIV\<^sup>\<omega>"
  by auto

lemma  alllstsE [consumes 1, case_names finite infinite]:
  "\<lbrakk> x\<in>A\<^sup>\<infinity>; x \<in> A\<^sup>\<star> \<Longrightarrow> P; x \<in> A\<^sup>\<omega> \<Longrightarrow> P \<rbrakk> \<Longrightarrow> P"
  by (auto intro: finite_lemma simp: inflsts_def)


lemma fin_inf_cases [case_names finite infinite]:
  "\<lbrakk> r\<in>UNIV\<^sup>\<star> \<Longrightarrow> P; r \<in> UNIV\<^sup>\<omega> \<Longrightarrow> P \<rbrakk> \<Longrightarrow> P"
  by auto

lemma  fin_Int_inf: "A\<^sup>\<star> \<inter> A\<^sup>\<omega> = {}"
  and   fin_Un_inf: "A\<^sup>\<star> \<union> A\<^sup>\<omega> = A\<^sup>\<infinity>"
  by (auto intro: finite_lemma finsubsetall)

lemma notfin_inf [iff]: "(x \<notin> UNIV\<^sup>\<star>) = (x \<in> UNIV\<^sup>\<omega>)"
  by auto

lemma notinf_fin [iff]: "(x \<notin> UNIV\<^sup>\<omega>) = (x \<in> UNIV\<^sup>\<star>)"
  by auto


section{*Lappend*}

subsection{*Simplification*}

lemma lapp_inf [simp]:
  "s \<in> A\<^sup>\<omega> \<Longrightarrow> s @@ t = s"
  by (rule llist_equalityI [of _ _ " (\<lambda>u. (u@@t, u))`A\<^sup>\<omega>"], auto)
     (erule_tac s = "u" in  inflsts_cases, auto)

lemma LNil_is_lappend_conv [iff]:
"(LNil = s @@ t) = (s = LNil \<and> t = LNil)"
  by (cases "s") auto

lemma lappend_is_LNil_conv [iff]:
  "(s @@ t = LNil) = (s = LNil \<and> t = LNil)"
  by (cases "s") auto

lemma same_lappend_eq [iff]:
 "r \<in> A\<^sup>\<star> \<Longrightarrow> (r @@ s = r @@ t) = (s = t)"
  by (erule finlsts.induct) simp+
(*
lemma lappend_same_eq [iff]:
assumes rA: "r \<in> A\<^sup>\<star>"
  shows "(s @@ r = t @@ r) = (s = t)"
oops
*)

subsection{*Typing rules*}

lemma lappT: 
  assumes sllist: "s \<in> A\<^sup>\<infinity>"
  and tllist: "t \<in> A\<^sup>\<infinity>"
  shows "s@@t \<in> A\<^sup>\<infinity>"
proof (rule alllsts.coinduct [of _ "\<Union> u\<in>A\<^sup>\<infinity>. \<Union>v\<in>A\<^sup>\<infinity>. {u@@v}"])
  from sllist tllist show "s @@ t \<in> (\<Union>u\<in>A\<^sup>\<infinity>. \<Union>v\<in>A\<^sup>\<infinity>. {u @@ v})"
    by fast
next fix z assume "z \<in> (\<Union>u\<in>A\<^sup>\<infinity>. \<Union>v\<in>A\<^sup>\<infinity>. {u @@ v})"
  then obtain u v where ullist: "u\<in>A\<^sup>\<infinity>" and vllist: "v\<in>A\<^sup>\<infinity>" and zapp: "z=u @@ v"
    by auto
  thus "z = LNil \<or> (\<exists>a l. z = a ## l \<and> l \<in> (\<Union>u\<in>A\<^sup>\<infinity>. \<Union>v\<in>A\<^sup>\<infinity>. {u @@ v}) \<union> A\<^sup>\<infinity> \<and> a \<in> A)"
    by (cases "u") (auto elim: alllsts.cases)
qed

lemma lappfin_finT: "\<lbrakk> s \<in> A\<^sup>\<star>; t \<in> A\<^sup>\<star> \<rbrakk> \<Longrightarrow> s@@t \<in> A\<^sup>\<star>"
  by (induct rule: finlsts.induct) auto

lemma lapp_fin_fin_lemma:
  assumes rsA: "r @@ s \<in> A\<^sup>\<star>"
  shows "r \<in> A\<^sup>\<star>"
proof-
  have "\<forall>l \<in> A\<^sup>\<star>. \<forall>r. l = r @@ s \<longrightarrow> r \<in> A\<^sup>\<star>"
  proof rule
    fix l assume "l\<in>A\<^sup>\<star>"
    thus "\<forall>r. l = r @@ s \<longrightarrow> r \<in> A\<^sup>\<star>"
    proof (induct "l")
      case LNil_fin thus ?case by auto
    next
      case (LCons_fin a l') show ?case 
      proof (clarify)
	fix r assume al'rs: "a##l' = r @@ s"
	show "r \<in> A\<^sup>\<star>"
	proof (cases "r")
	  case LNil thus ?thesis by auto
	next
	  case (LCons x xs) with al'rs
	  have "a = x" and "l' = xs @@ s"
	    by auto
	  with LCons_fin LCons show ?thesis 
	    by auto
	qed
      qed
    qed
  qed
  with rsA show ?thesis by blast
qed

lemma lapp_fin_fin_iff [iff]: "(r @@ s \<in> A\<^sup>\<star>) = (r \<in> A\<^sup>\<star> \<and> s \<in> A\<^sup>\<star>)"
proof (auto intro: lappfin_finT lapp_fin_fin_lemma)
  assume rsA: "r @@ s \<in> A\<^sup>\<star>"
  hence "r \<in> A\<^sup>\<star>" by (rule lapp_fin_fin_lemma)
  hence "r @@ s \<in> A\<^sup>\<star> \<longrightarrow> s \<in> A\<^sup>\<star>"
    by (induct "r", simp) (auto elim: finlsts.cases)
  with rsA show "s \<in> A\<^sup>\<star>" by auto
qed

lemma lapp_all_invT:
assumes rs: "r@@s \<in> A\<^sup>\<infinity>"
  shows "r \<in> A\<^sup>\<infinity>"
proof (cases "r \<in> UNIV\<^sup>\<star>")
  case False
  with rs show ?thesis by simp
next
  case True
  hence "r @@ s \<in> A\<^sup>\<infinity> \<longrightarrow> r \<in> A\<^sup>\<infinity>"
  by (induct "r") auto
  with rs show ?thesis by auto
qed

(*
lemma lapp_infT:
 "s \<in> A\<^sup>\<omega> \<Longrightarrow> s @@ t \<in> A\<^sup>\<omega>"
  by simp
*)
lemma lapp_fin_infT: "\<lbrakk>s \<in> A\<^sup>\<star>; t \<in> A\<^sup>\<omega>\<rbrakk> \<Longrightarrow> s @@ t \<in> A\<^sup>\<omega>"
  by (induct rule: finlsts.induct)
     (auto intro: inflstsI2)

lemma app_invT [rule_format]:
  "r \<in> A\<^sup>\<star> \<Longrightarrow> \<forall>s. r @@ s \<in> A\<^sup>\<omega> \<longrightarrow> s \<in> A\<^sup>\<omega>"
proof (induct rule: finlsts.induct)
  case LNil_fin thus ?case by simp
next case (LCons_fin a l) show ?case
  proof clarify
    fix s assume "(a ## l) @@ s \<in> A\<^sup>\<omega>"
    hence "a ## (l @@ s) \<in> A\<^sup>\<omega>" by simp
    hence "l @@ s \<in> A\<^sup>\<omega>" by (auto elim: inflsts_cases)
    with LCons_fin show "s \<in> A\<^sup>\<omega>" by blast
  qed
qed

lemma lapp_inv2T:
  assumes rsinf: "r @@ s \<in> A\<^sup>\<omega>"
  shows "r \<in> A\<^sup>\<star> \<and> s \<in> A\<^sup>\<omega> \<or> r \<in> A\<^sup>\<omega>"
proof (rule disjCI)
  assume rnotinf: "r \<notin> A\<^sup>\<omega>"
  moreover from rsinf have rsall: "r@@s \<in> A\<^sup>\<infinity>"
    by auto
  hence "r \<in> A\<^sup>\<infinity>" by (rule lapp_all_invT)
  hence "r \<in> A\<^sup>\<star>" using rnotinf by (auto elim: alllstsE)
  ultimately show "r \<in> A\<^sup>\<star> \<and> s \<in> A\<^sup>\<omega>" using rsinf
    by (auto  intro: app_invT)
qed

lemma lapp_infT:
  "(r @@ s \<in> A\<^sup>\<omega>) = (r \<in> A\<^sup>\<star> \<and> s \<in> A\<^sup>\<omega> \<or> r \<in> A\<^sup>\<omega>)"
  by (auto dest: lapp_inv2T intro: lapp_fin_infT)

lemma lapp_allT_iff:
  "(r @@ s \<in> A\<^sup>\<infinity>) = (r \<in> A\<^sup>\<star> \<and> s \<in> A\<^sup>\<infinity> \<or> r \<in> A\<^sup>\<omega>)"
  (is "?L = ?R")
proof
  assume ?L thus ?R by (cases rule: alllstsE) (auto simp: lapp_infT intro: finsubsetall)
next
  assume ?R thus ?L by (auto dest: finsubsetall intro: lappT)
qed

section{*Length, indexing, prefixes, and suffixes of llists*}

consts
  ll2f :: "'a llist \<Rightarrow> nat \<Rightarrow> 'a option" (infix "!!" 100)
  ltake :: "'a llist \<Rightarrow> nat \<Rightarrow> 'a llist"
  ldrop :: "'a llist \<Rightarrow> nat \<Rightarrow> 'a llist"
  
syntax (xsymbols)
  ltake  :: "'a llist \<Rightarrow> nat \<Rightarrow> 'a llist" (infixl "\<down>" 110)
  ldrop  :: "'a llist \<Rightarrow> nat \<Rightarrow> 'a llist" (infixl "\<up>" 110)

primrec
  "l!!0 = (case l of LNil \<Rightarrow> None | LCons x xs \<Rightarrow> Some x)"
  "l!!(Suc i) = (case l of LNil \<Rightarrow> None | x ## xs \<Rightarrow> xs!!i)"

primrec
  "l \<down> 0     = LNil"
  "l \<down> Suc i = (case l of LNil \<Rightarrow> LNil | x ## xs \<Rightarrow> x ## xs \<down> i)"

primrec
  "l \<up> 0     = l"
  "l \<up> Suc i = (case l of LNil \<Rightarrow> LNil | x ## xs \<Rightarrow> xs \<up> i)"

constdefs
  lset :: "'a llist \<Rightarrow> 'a set"
  "lset l \<equiv> ran (ll2f l)"

  llength :: "'a llist \<Rightarrow> nat"
  "llength \<equiv> finlsts_rec 0 (\<lambda> a r n. Suc n)"

  llast :: "'a llist \<Rightarrow> 'a"
  "llast \<equiv> finlsts_rec arbitrary (\<lambda> x xs l. if xs = LNil then x else l)"

  lbutlast :: "'a llist \<Rightarrow> 'a llist"
  "lbutlast \<equiv> finlsts_rec LNil (\<lambda> x xs l. if xs = LNil then LNil else x##l)"

  lrev :: "'a llist \<Rightarrow> 'a llist"
  "lrev \<equiv> finlsts_rec LNil (\<lambda> x xs l. l @@ x ## LNil)"

lemmas llength_LNil  = llength_def [THEN finlsts_rec_LNil_def, standard]
  and  llength_LCons = llength_def [THEN finlsts_rec_LCons_def, standard]
  and  llength_simps [simp] = llength_LNil llength_LCons

lemmas llast_LNil  = llast_def [THEN finlsts_rec_LNil_def, standard]
  and  llast_LCons = llast_def [THEN finlsts_rec_LCons_def, standard]
  and llast_simps [simp] = llast_LNil llast_LCons

lemmas lbutlast_LNil = lbutlast_def [THEN finlsts_rec_LNil_def, standard]
  and lbutlast_LCons = lbutlast_def [THEN finlsts_rec_LCons_def, standard]
  and lbutlast_simps [simp] = lbutlast_LNil lbutlast_LCons

lemmas lrev_LNil = lrev_def [THEN finlsts_rec_LNil_def, standard]
  and lrev_LCons = lrev_def [THEN finlsts_rec_LCons_def, standard]
  and lrev_simps [simp] = lrev_LNil lrev_LCons

lemma lrevT [simp, intro!]:
  "xs \<in> A\<^sup>\<star> \<Longrightarrow> lrev xs \<in> A\<^sup>\<star>"
  by (induct rule: finlsts.induct) auto

lemma lrev_lappend [simp]:
  assumes fin: "xs \<in> UNIV\<^sup>\<star>" "ys \<in> UNIV\<^sup>\<star>"
  shows "lrev (xs @@ ys) = (lrev ys) @@ (lrev xs)"
  using fin
  by induct (auto simp: lrev_LCons [of _ UNIV] lappend_assoc)

lemma lrev_lrev_ident [simp]:
  assumes fin: "xs \<in> UNIV\<^sup>\<star>"
  shows "lrev (lrev xs) = xs"
  using fin
proof (induct, simp)
  case (LCons_fin a l)
  have "a ## LNil \<in> UNIV\<^sup>\<star>" by auto
  thus ?case using LCons_fin
    by auto
qed

lemma lrev_is_LNil_conv [iff]:
  "xs \<in> UNIV\<^sup>\<star> \<Longrightarrow> (lrev xs = LNil) = (xs = LNil)"
  by (induct rule: finlsts.induct) auto

lemma LNil_is_lrev_conv [iff]: 
"xs \<in> UNIV\<^sup>\<star> \<Longrightarrow> (LNil = lrev xs) = (xs = LNil)"
by (induct rule: finlsts.induct) auto

lemma lrev_is_lrev_conv [iff]:
assumes fin: "xs \<in> UNIV\<^sup>\<star>" "ys \<in> UNIV\<^sup>\<star>"
  shows "(lrev xs = lrev ys) = (xs = ys)"
  (is "?L = ?R")
proof
  assume L: ?L
  hence "lrev (lrev xs) = lrev (lrev ys)" by simp
  thus ?R using fin by simp
qed simp

lemma lrev_induct [case_names LNil snocl, consumes 1]:
  assumes fin: "xs \<in> A\<^sup>\<star>"
  and init: "P LNil"
  and step: "\<And>x xs. \<lbrakk> xs \<in> A\<^sup>\<star>; P xs; x \<in> A \<rbrakk> \<Longrightarrow> P (xs @@ x##LNil)"
  shows "P xs"
proof-
  from fin have "lrev xs \<in> A\<^sup>\<star>" by simp
  hence "P (lrev (lrev xs))"
  proof (induct "lrev xs")
    case (LNil_fin l) with init show "P (lrev l)" by simp
  next
    case (LCons_fin a l) thus ?case by (auto intro: step)
  qed
  thus ?thesis using fin by simp
qed

lemma finlsts_rev_cases [case_names LNil snocl, consumes 1]:
  assumes tfin: "t \<in> A\<^sup>\<star>"
  and     lnil: "t = LNil \<Longrightarrow> P"
  and    lcons: "\<And> a l. \<lbrakk> l \<in> A\<^sup>\<star>; a \<in> A; t = l @@ a ## LNil \<rbrakk> \<Longrightarrow> P"
  shows  "P"
  using prems
  by (induct rule: lrev_induct) auto

(*lemma fps_lrev_cases [case_names snocl, consumes 1]:
  "\<lbrakk>t \<in> UNIV\<^sup>\<clubsuit>;
    \<And> a s. t = s @@ a ## LNil \<Longrightarrow> R \<rbrakk>
  \<Longrightarrow> R"
  by (auto elim!: finlsts_rev_cases)

*)
lemma ll2f_LNil [simp]: "LNil!!x = None"
  by (cases "x") auto

lemma None_lfinite [rule_format]: "\<forall>t. t!!i = None \<longrightarrow> t \<in> UNIV\<^sup>\<star>"
proof (induct "i")
  case 0 show ?case
  proof
    fix t show "t !! 0 = None \<longrightarrow> t \<in> UNIV\<^sup>\<star>"
      by (rule llistE [of "t"]) auto
  qed
next case (Suc n)
  show ?case
  proof clarify
    fix t assume tsuc: "(t::'a llist)!!Suc n = None"
    show  "t \<in> UNIV\<^sup>\<star>"
    proof  (rule llistE [of "t"], clarify)
      fix x l' assume "t = x ## l'"
      with Suc tsuc show "t \<in> UNIV\<^sup>\<star>"
	by auto
    qed
  qed
qed

lemma infinite_Some: "t \<in> A\<^sup>\<omega> \<Longrightarrow> \<exists>a. t!!i = Some a"
  by (rule ccontr) (auto dest: None_lfinite)

lemmas infinite_idx_SomeE = exE [OF infinite_Some, standard]

lemma Least_True [simp]:
  "(LEAST (n::nat). True) = 0"
  by (auto simp: Least_def)

lemma  ll2f_llength [simp]: "r \<in> A\<^sup>\<star> \<Longrightarrow> r!!(llength r) = None"
  by (erule finlsts.induct) auto

lemma llength_least_None:
  assumes rA: "r \<in> A\<^sup>\<star>"
  shows "llength r = (LEAST i. r!!i = None)"
proof-
  from rA show ?thesis
  proof (induct "r")
    case LNil_fin thus ?case by simp
  next
    case (LCons_fin a l)
    hence "(LEAST i. (a ## l) !! i = None) = llength (a ## l)"
      by (auto intro!: ll2f_llength Least_Suc2)
    thus ?case by rule
  qed
qed

lemma ll2f_lem1:
 "\<And>x t. t !! (Suc i) = Some x \<Longrightarrow> \<exists> y. t !! i = Some y"
proof (induct i)
  case 0 thus ?case by (auto split: llist_split llist_split_asm)
next
  case (Suc k) thus ?case
    by (cases t) auto
qed

lemmas ll2f_Suc_Some = ll2f_lem1 [THEN exE, standard]

lemma ll2f_None_Suc: "\<And> t. t !! i = None \<Longrightarrow> t !! Suc i = None"
proof (induct i)
  case 0 thus ?case by (auto split: llist_split)
next
  case (Suc k) thus ?case by (cases t) auto
qed

lemma ll2f_None_le:
  "\<And>t j. \<lbrakk> t!!j = None; j \<le> i \<rbrakk> \<Longrightarrow> t!!i = None"
proof (induct i)
  case 0 thus ?case by simp
next
  case (Suc k) thus ?case by (cases j) (auto split: llist_split)
qed

lemma ll2f_Some_le:
  assumes jlei: "j \<le> i"
  and tisome: "t !! i = Some x"
  and H: "\<And> y. t !! j = Some y \<Longrightarrow> Q"
  shows "Q"
proof -
  have  "\<exists> y. t !! j = Some y" (is "?R")
  proof (rule ccontr)
    assume "\<not> ?R"
    hence "t !! j = None" by simp 
    with tisome jlei show False
      by (auto dest:  ll2f_None_le)
  qed
  thus ?thesis using H by auto
qed

lemma ltake_LNil [simp]: "LNil \<down> i = LNil"
  by (cases "i") auto

lemma ltake_LCons_Suc: "(a ## l) \<down> (Suc i) = a ## l \<down> i"
  by simp

lemma take_fin [iff]: "\<And>t. t \<in> A\<^sup>\<infinity> \<Longrightarrow> t\<down>i \<in> A\<^sup>\<star>"
proof (induct i)
  case 0 show ?case by auto
next
  case (Suc j) thus ?case
    by (cases "t") auto
qed

lemma ltake_fin [iff]:
  "r \<down> i \<in> UNIV\<^sup>\<star>"
  by simp
(*
lemma take_fin [iff]: "\<And>t. t\<down>i \<in> UNIV\<^sup>\<star>"
proof (induct i)
  case 0 show ?case by auto
next
  case (Suc j) thus ?case
    by (cases "t") auto
qed
*)

lemma llength_take [rule_format, simp]: "\<forall> t \<in> A\<^sup>\<omega>. llength (t\<down>i) = i"
proof (induct "i")
  case 0 thus ?case by simp
next
  case (Suc j) show ?case
  proof
    fix t assume tinf: "t \<in> A\<^sup>\<omega>"
    thus  "llength (t \<down> Suc j) = Suc j" using Suc
      by (cases "t") (auto simp: llength_LCons [of _ UNIV])
  qed 
qed

lemma ltake_ldrop_id: "\<And>x. (x \<down> i) @@ (x \<up> i) = x"
proof (induct "i")
  case 0 thus ?case by simp
next
  case (Suc j) thus ?case
    by (cases x) auto
qed

lemma ltake_ldrop: 
  "\<And>xs. (xs \<up> m) \<down> n =(xs \<down> (n + m)) \<up> m"
proof (induct "m")
  case 0 show ?case by simp
next
  case (Suc l) thus ?case
    by (cases "xs") auto
qed

lemma ldrop_LNil [simp]: "LNil \<up> i = LNil"
  by (cases "i") auto

lemma ldrop_add: "\<And>t. t \<up> (i + k) = t \<up> i \<up> k"
proof (induct "i", simp)
  case (Suc j) thus ?case
    by (cases "t") auto
qed

lemma ldrop_fun: "\<And>t. t \<up> i !! j = t!!(i + j)"
proof (induct "i", simp)
  case (Suc k) show ?case
    by (cases "t") auto
qed

lemma ldropT[simp]: "\<And>t. t \<in> A\<^sup>\<infinity> \<Longrightarrow> t \<up> i \<in> A\<^sup>\<infinity>"
proof (induct i)
  case 0 thus ?case by simp
next case (Suc j)
  thus ?case by (cases "t") auto
qed

lemma ldrop_finT[simp]: "\<And>t. t \<in> A\<^sup>\<star> \<Longrightarrow> t \<up> i \<in> A\<^sup>\<star>"
proof (induct i)
  case 0 thus ?case by simp
next
  fix n t assume "t \<in> A\<^sup>\<star>" and 
    "\<And>t::'a llist. t \<in> A\<^sup>\<star> \<Longrightarrow> t \<up> n \<in> A\<^sup>\<star>"
  thus "t \<up> Suc n \<in> A\<^sup>\<star>"
    by (cases "t") auto
qed

lemma ldrop_infT[simp]: "\<And>t. t \<in> A\<^sup>\<omega> \<Longrightarrow> t \<up> i \<in> A\<^sup>\<omega>"
proof (induct i)
  case 0 thus ?case by simp
next
  fix n t assume "t \<in> A\<^sup>\<omega>" and 
    "\<And>t::'a llist. t \<in> A\<^sup>\<omega> \<Longrightarrow> t \<up> n \<in> A\<^sup>\<omega>"
  thus "t \<up> Suc n \<in> A\<^sup>\<omega>"
    by (cases "t") auto
qed

lemma lapp_suff_llength: "r \<in> A\<^sup>\<star> \<Longrightarrow> (r@@s) \<up> llength r = s"
  by (erule finlsts.induct) auto

lemma ltake_lappend_llength [simp]:
  "r \<in> A\<^sup>\<star> \<Longrightarrow> (r @@ s) \<down> llength r = r"
  by (erule finlsts.induct) auto

lemma ldrop_LNil_less:
  "\<And>j t. \<lbrakk>j \<le> i; t \<up> j = LNil\<rbrakk> \<Longrightarrow> t \<up> i = LNil"
proof (induct i)
  case 0 thus ?case by auto
next case (Suc n) thus ?case
    by (cases j, simp) (cases t, simp_all)
qed

lemma ldrop_inf_iffT [iff]: "(t \<up> i \<in> UNIV\<^sup>\<omega>)  =  (t \<in> UNIV\<^sup>\<omega>)"
proof (auto)
    show "t\<up>i \<in> UNIV\<^sup>\<omega> \<Longrightarrow> t \<in> UNIV\<^sup>\<omega>"
    by (rule ccontr) (auto dest: ldrop_finT)
qed

lemma ldrop_fin_iffT [iff]: "(t \<up> i \<in> UNIV\<^sup>\<star>) = (t \<in> UNIV\<^sup>\<star>)"
  by auto

lemma drop_nonLNil: "t\<up>i \<noteq> LNil \<Longrightarrow> t \<noteq> LNil"
    by (auto)

lemma llength_drop_take:
  "\<And>t. t\<up>i \<noteq> LNil \<Longrightarrow> llength (t\<down>i) = i"
proof (induct i)
  case 0 show ?case by simp
next
  case (Suc j) thus ?case by (cases t) (auto simp: llength_LCons [of _ UNIV])
qed

lemma fps_induct [case_names LNil LCons, induct set: fpslsts, consumes 1]:
  assumes fps: "l \<in> A\<^sup>\<clubsuit>"
  and    init: "\<And>a. a \<in> A \<Longrightarrow> P (a##LNil)"
  and    step: "\<And>a l. \<lbrakk> l \<in> A\<^sup>\<clubsuit>; P l; a \<in> A \<rbrakk> \<Longrightarrow> P (a ## l)"
  shows "P l"
proof-
  from fps have "l \<in> A\<^sup>\<star>" and "l \<noteq> LNil" by auto
  thus ?thesis
    by (induct, simp) (cases, auto intro: init step)
qed

lemma lbutlast_lapp_llast:
assumes "l \<in> A\<^sup>\<clubsuit>"
  shows "l = lbutlast l @@ (llast l ## LNil)"
  using prems by induct auto

lemma llast_snoc [simp]:
  assumes fin: "xs \<in> A\<^sup>\<star>"
  shows "llast (xs @@ x ## LNil) = x"
  using fin
proof induct
  case LNil_fin thus ?case by simp
next
  case (LCons_fin a l) 
  have "x ## LNil \<in> UNIV\<^sup>\<star>" by auto
  with LCons_fin show ?case
    by (auto simp: llast_LCons [of _ UNIV])
qed

lemma lbutlast_snoc [simp]:
  assumes fin: "xs \<in> A\<^sup>\<star>"
  shows "lbutlast (xs @@ x ## LNil) = xs"
  using fin
proof induct
  case LNil_fin thus ?case by simp
next
  case (LCons_fin a l)
  have "x ## LNil \<in> UNIV\<^sup>\<star>" by auto
  with LCons_fin show ?case
    by (auto simp: lbutlast_LCons [of _ UNIV])
qed

lemma llast_lappend [simp]:
"\<lbrakk> x \<in> UNIV\<^sup>\<star>; y \<in> UNIV\<^sup>\<star> \<rbrakk> \<Longrightarrow> llast (x @@ a ## y) = llast (a ## y)"
proof (induct rule: finlsts.induct)
  case LNil_fin thus ?case by simp
next case (LCons_fin b l)
  hence "l @@ a ## y \<in> UNIV\<^sup>\<star>" by auto 
  thus ?case using LCons_fin 
    by (auto simp: llast_LCons [of _ UNIV])
qed

lemma llast_llength:
  assumes tfin: "t \<in> UNIV\<^sup>\<star>"
  shows "t \<noteq> LNil \<Longrightarrow> t !! (llength t - (Suc 0)) = Some (llast t)"
  using tfin
proof induct
  case (LNil_fin l) thus ?case by auto
next
  case (LCons_fin a l) note consal = this thus ?case
  proof (cases l)
    case LNil_fin thus ?thesis using consal by simp
  next
    case (LCons_fin aa la) 
    thus ?thesis using consal by simp
  qed
qed


section{*The constant llist *}

constdefs
  lconst :: "'a \<Rightarrow> 'a llist"
  "lconst a \<equiv> iterates (\<lambda>x. x) a"

lemma lconst_unfold: "lconst a = a ## lconst a"
  by (auto simp: lconst_def intro: iterates)

lemma lconst_LNil [iff]: "lconst a \<noteq> LNil"
  by (clarify,frule subst [OF lconst_unfold]) simp

lemma lconstT:
  assumes aA: "a \<in> A"
  shows "lconst a \<in> A\<^sup>\<omega>"
proof (rule inflstsI)
  show "lconst a \<in> A\<^sup>\<infinity>"
  proof (rule alllsts.coinduct [of _ "{lconst a}"], simp_all)
    have "lconst a = a ## lconst a"
      by (rule lconst_unfold)
    with aA
    show "\<exists>aa l. lconst a = aa ## l \<and> (l = lconst a \<or> l \<in> A\<^sup>\<infinity>) \<and> aa \<in> A"
      by blast
  qed
next assume lconst: "lconst a \<in> UNIV\<^sup>\<star>"
  moreover have "\<And>l. l \<in> UNIV\<^sup>\<star> \<Longrightarrow> lconst a \<noteq> l"
  proof-
    fix l::"'a llist" assume "l\<in>UNIV\<^sup>\<star>"
    thus "lconst a \<noteq> l"
    proof (rule finlsts_induct, simp_all)
      fix a' l' assume 
	al': "lconst a \<noteq> l'" and
	l'A: "l' \<in> UNIV\<^sup>\<star>"
      from al' show  "lconst a \<noteq> a' ## l'"
      proof (rule contrapos_np)
	assume notal: "\<not> lconst a \<noteq> a' ## l'"
	hence "lconst a = a' ## l'" by simp
	hence "a ## lconst a = a' ## l'"
	  by (rule subst [OF lconst_unfold])
	thus "lconst a = l'" by auto
      qed
    qed
  qed
  ultimately show "False" using aA by auto
qed


section{*The prefix order of llists*}

instance llist :: (type)ord ..

defs (overloaded)
llist_le_def: "(s :: 'a llist) \<le> t \<equiv> \<exists>d. t = s @@ d"
llist_less_def: "(s :: 'a llist) < t \<equiv> s \<le> t \<and> s \<noteq> t"

lemma not_LCons_le_LNil [iff]:
  "\<not> (a##l) \<le> LNil"
  by (unfold llist_le_def) auto

lemma LNil_le [iff]:"LNil \<le> s"
  by (auto simp: llist_le_def)

lemma le_LNil [iff]: "(s \<le> LNil) = (s = LNil)"
  by (auto simp: llist_le_def)

lemma llist_inf_le:
  "s \<in> A\<^sup>\<omega>  \<Longrightarrow> (s\<le>t) = (s=t)"
  by (unfold llist_le_def) auto

lemma le_LCons [iff]: "(x ## xs \<le> y ## ys) = (x = y \<and> xs \<le> ys)"
  by (unfold llist_le_def) auto

lemma llist_le_refl [iff]:
  "(s:: 'a llist) \<le> s"
  by (unfold llist_le_def) (rule exI [of _ "LNil"], simp)

lemma llist_le_trans [trans]:
  fixes r:: "'a llist"
  shows "r \<le> s \<Longrightarrow> s \<le> t \<Longrightarrow> r \<le> t"
  by (auto simp: llist_le_def lappend_assoc)

lemma llist_le_anti_sym:
  fixes s:: "'a llist"
  assumes st: "s \<le> t"
  and ts: "t \<le> s"
  shows "s = t"
proof-
  have "s \<in> UNIV\<^sup>\<infinity>" by auto
  thus ?thesis
  proof (cases rule: alllstsE)
    case finite
    hence "\<forall> t.  s \<le> t \<and> t \<le> s \<longrightarrow> s = t"
    proof (induct rule: finlsts.induct)
      case LNil_fin thus ?case by auto
    next      
      case (LCons_fin a l) show ?case
      proof
	fix t from LCons_fin show  "a ## l \<le> t \<and> t \<le> a ## l \<longrightarrow> a ## l = t"
	  by (cases "t") blast+
      qed
    qed
    thus ?thesis using st ts by blast
  next case infinite thus ?thesis using st by (simp add: llist_inf_le)
  qed
qed

lemma llist_less_le:
  fixes s :: "'a llist"
  shows "(s < t) = (s \<le> t \<and> s \<noteq> t)"
  by (unfold llist_less_def) auto

instance llist :: (type) order
  by (intro_classes,
  (assumption | rule llist_le_refl
    llist_le_trans llist_le_anti_sym llist_less_le)+)


subsection{*Typing rules*}

lemma llist_le_finT [rule_format, simp]:
 "r\<le>s \<Longrightarrow> s \<in> A\<^sup>\<star> \<Longrightarrow> r \<in> A\<^sup>\<star>"
proof-
  assume rs: "r\<le>s" and sfin: "s \<in> A\<^sup>\<star>"
  from sfin have "\<forall>r. r\<le>s \<longrightarrow> r\<in>A\<^sup>\<star>"
  proof (induct "s")
    case LNil_fin thus ?case by auto
  next
    case (LCons_fin a l) show  ?case
    proof (clarify)
      fix r assume ral: "r \<le> a ## l"
      thus "r \<in> A\<^sup>\<star>" using LCons_fin
	by (cases r) auto
    qed
  qed
  with rs show ?thesis by auto
qed

lemma llist_less_finT [rule_format, iff]:
 "r<s \<Longrightarrow> s \<in> A\<^sup>\<star> \<Longrightarrow> r \<in> A\<^sup>\<star>"
  by (auto simp: llist_less_le)


subsection{*More simplification rules*}

lemma LNil_less_LCons [iff]: "LNil < a ## t"
  by (simp add: llist_less_le)

lemma not_less_LNil [iff]:
  "\<not> r < LNil"
  by (auto simp: llist_less_le)

lemma less_LCons [iff]:
  " (a ## r < b ## t) = (a = b \<and> r < t)"
  by (auto simp: llist_less_le)

lemma llength_mono [rule_format, iff]:
  assumes"r \<in> A\<^sup>\<star>"
  shows "\<forall>s. s<r \<longrightarrow> llength s < llength r"
  using prems
proof(induct "r")
  case LNil_fin thus ?case by simp
next
  case (LCons_fin a l) show ?case
  proof (clarify)
    fix s assume sless: "s < a ## l"
    with LCons_fin show "llength s < llength (a ## l)"
      by (cases s) (auto simp: llength_LCons [of _ UNIV])
  qed
qed

lemma le_lappend [iff]: "r \<le> r @@ s"
  by (auto simp: llist_le_def)

lemma take_inf_less:
  "\<And>t. t \<in> UNIV\<^sup>\<omega> \<Longrightarrow> t \<down> i < t"
proof (induct i)
  case 0 thus ?case by (auto elim: inflsts_cases)
next
  case (Suc i) assume "t \<in> UNIV\<^sup>\<omega>"
  thus ?case
  proof (cases "t")
    case (LCons a l) with Suc show ?thesis
      by auto
  qed
qed

lemma lapp_take_less:
  assumes iless: "i < llength r"
  shows "(r @@ s) \<down> i < r"
proof (cases "r \<in> UNIV\<^sup>\<star>")
  case True 
  have "\<forall>r \<in> UNIV\<^sup>\<star>. i < llength r \<longrightarrow> (r @@ s) \<down> i < r"
  proof(induct i)
    case 0 thus ?case
    proof clarify
      fix r::"'a llist" assume "0 < llength r"
      thus "(r @@ s) \<down> 0 < r"
	by (cases "r") auto
    qed
  next
    case (Suc j) show ?case
    proof clarify
      fix r :: "'a llist" assume "r \<in> UNIV\<^sup>\<star>" "Suc j < llength r"
      thus "(r @@ s) \<down> Suc j < r" using Suc
	by (cases r) auto
    qed
  qed
  with iless True show ?thesis by auto
next case False thus ?thesis by (simp add: take_inf_less)
qed


subsection{*Finite prefixes and infinite suffixes*}

constdefs
  finpref :: "'a set \<Rightarrow> 'a llist \<Rightarrow> 'a llist set"
  "finpref A s \<equiv> {r. r \<in> A\<^sup>\<star> \<and> r \<le> s}"

  suff :: "'a set \<Rightarrow> 'a llist \<Rightarrow> 'a llist set"
  "suff A s \<equiv> {r. r \<in> A\<^sup>\<infinity> \<and> s \<le> r}"

  infsuff :: "'a set \<Rightarrow> 'a llist \<Rightarrow> 'a llist set"
  "infsuff A s \<equiv> {r. r \<in> A\<^sup>\<omega> \<and> s \<le> r}"

  prefix_closed :: "'a llist set \<Rightarrow> bool"
  "prefix_closed A \<equiv> \<forall> t \<in> A. \<forall> s \<le> t. s \<in> A"

  pprefix_closed :: "'a llist set \<Rightarrow> bool"
  "pprefix_closed A \<equiv> \<forall> t \<in> A. \<forall> s. s \<le> t \<and> s \<noteq> LNil \<longrightarrow> s \<in> A"

  suffix_closed :: "'a llist set \<Rightarrow> bool"
  "suffix_closed A \<equiv> \<forall> t \<in> A. \<forall> s. t \<le> s \<longrightarrow> s \<in> A"

lemma finpref_LNil [simp]:
  "finpref A LNil = {LNil}"
  by (auto simp: finpref_def)

lemma finpref_fin: "x \<in> finpref A s \<Longrightarrow> x \<in> A\<^sup>\<star>"
  by (auto simp: finpref_def)

lemma finpref_mono2: "s \<le> t \<Longrightarrow> finpref A s \<subseteq> finpref A t"
  by (unfold finpref_def) (auto dest: llist_le_trans)

lemma suff_LNil [simp]:
  "suff A LNil = A\<^sup>\<infinity>"
  by (simp add: suff_def)

lemma suff_all: "x \<in> suff A s \<Longrightarrow> x \<in> A\<^sup>\<infinity>"
  by (auto simp: suff_def)

lemma suff_mono2: "s \<le> t \<Longrightarrow> suff A t \<subseteq> suff A s"
  by (unfold suff_def) (auto dest: llist_le_trans)

lemma suff_appE:
  assumes rA: "r \<in> A\<^sup>\<star>"
  and  tsuff: "t \<in> suff A r"
  and      H:  "\<And>s. \<lbrakk> s \<in> A\<^sup>\<infinity>; t = r@@s \<rbrakk> \<Longrightarrow> R"
  shows "R"
proof-
  from tsuff obtain s where
    tA: "t \<in> A\<^sup>\<infinity>" and trs: "t = r @@ s"
    by (auto simp: suff_def llist_le_def)
  from rA trs tA have "s \<in> A\<^sup>\<infinity>"
    by (auto simp: lapp_allT_iff)
  thus ?thesis using trs
    by (rule H)
qed

lemma LNil_suff [iff]: "(LNil \<in> suff A s) = (s = LNil)"
  by (auto simp: suff_def)

lemma finpref_suff [dest]:
  "\<lbrakk> r \<in> finpref A t; t\<in>A\<^sup>\<infinity> \<rbrakk> \<Longrightarrow> t \<in> suff A r"
  by (auto simp: finpref_def suff_def)

lemma suff_finpref:
  "\<lbrakk> t \<in> suff A r; r\<in>A\<^sup>\<star> \<rbrakk> \<Longrightarrow> r \<in> finpref A t"
  by (auto simp: finpref_def suff_def)

lemma suff_finpref_iff:
  "\<lbrakk> r\<in>A\<^sup>\<star>; t\<in>A\<^sup>\<infinity> \<rbrakk> \<Longrightarrow> (r \<in> finpref A t) = (t \<in> suff A r)"
  by (auto simp: finpref_def suff_def)

lemma infsuff_LNil [simp]:
  "infsuff A LNil = A\<^sup>\<omega>"
  by (simp add: infsuff_def)

lemma infsuff_inf: "x \<in> infsuff A s \<Longrightarrow> x \<in> A\<^sup>\<omega>"
  by (auto simp: infsuff_def)

lemma infsuff_mono2: "s \<le> t \<Longrightarrow> infsuff A t \<subseteq> infsuff A s"
  by (unfold infsuff_def) (auto dest: llist_le_trans)

lemma infsuff_appE:
  assumes   rA: "r \<in> A\<^sup>\<star>"
  and tinfsuff: "t \<in> infsuff A r"
  and        H:  "\<And>s. \<lbrakk> s \<in> A\<^sup>\<omega>; t = r@@s \<rbrakk> \<Longrightarrow> R"
  shows "R"
proof-
  from tinfsuff obtain s where
    tA: "t \<in> A\<^sup>\<omega>" and trs: "t = r @@ s"
    by (auto simp: infsuff_def llist_le_def)
  from rA trs tA have "s \<in> A\<^sup>\<omega>"
    by (auto dest: app_invT)
  thus ?thesis using trs
    by (rule H)
qed

lemma finpref_infsuff [dest]:
  "\<lbrakk> r \<in> finpref A t; t\<in>A\<^sup>\<omega> \<rbrakk> \<Longrightarrow> t \<in> infsuff A r"
  by (auto simp: finpref_def infsuff_def)

lemma infsuff_finpref:
  "\<lbrakk> t \<in> infsuff A r; r\<in>A\<^sup>\<star> \<rbrakk> \<Longrightarrow> r \<in> finpref A t"
  by (auto simp: finpref_def infsuff_def)

lemma infsuff_finpref_iff [iff]:
  "\<lbrakk> r\<in>A\<^sup>\<star>; t\<in>A\<^sup>\<omega> \<rbrakk> \<Longrightarrow> (t \<in> finpref A r) = (r \<in> infsuff A t)"
  by (auto simp: finpref_def infsuff_def)

lemma prefix_lemma:
  assumes xinf: "x \<in> A\<^sup>\<omega>"
  and yinf: "y \<in> A\<^sup>\<omega>"
  and R: "\<And> s. \<lbrakk> s \<in> A\<^sup>\<star>; s \<le> x\<rbrakk> \<Longrightarrow> s \<le> y"
  shows "x = y"
proof-
  let ?r = "{(x, y). x\<in>A\<^sup>\<omega> \<and> y\<in>A\<^sup>\<omega> \<and> finpref A x \<subseteq> finpref A y}"
  show ?thesis
  proof (rule llist_equalityI [of _ _ ?r])
    show "(x, y) \<in> ?r" using xinf yinf
      by (auto simp: finpref_def intro: R)
  next show "?r \<subseteq> llistD_Fun (?r \<union> range (\<lambda>x. (x, x)))"
    proof clarify
      fix a b assume ainf: "a \<in> A\<^sup>\<omega>" and binf: "b \<in> A\<^sup>\<omega>" and
	pref: "finpref A a \<subseteq> finpref A b"
      thus "(a, b) \<in> llistD_Fun (?r \<union> range (\<lambda>x. (x, x)))"
      proof (cases a)
	case (LCons a' l') note acons = this with binf show ?thesis
	proof (cases b)
	  case (LCons b' l'')
	  with acons pref have "a' = b'" "finpref A l' \<subseteq> finpref A l''"
	    by (auto simp: finpref_def)
	  thus  ?thesis using acons LCons
	    by auto 
	qed
      qed
    qed
  qed
qed

lemma inf_neqE:
"\<lbrakk> x \<in>  A\<^sup>\<omega>; y \<in> A\<^sup>\<omega>; x \<noteq> y;
  \<And>s. \<lbrakk> s\<in>A\<^sup>\<star>; s \<le> x; \<not> s \<le> y\<rbrakk> \<Longrightarrow> R \<rbrakk> \<Longrightarrow> R"
  by (auto intro!: prefix_lemma)

lemma pref_locally_linear:
  fixes s::"'a llist"
  assumes sx: "s \<le> x"
  and   tx: "t \<le> x"
  shows "s \<le> t \<or> t \<le> s"
proof-
  have "s \<in> UNIV\<^sup>\<infinity>" by auto
  thus ?thesis
  proof (cases rule: alllstsE)
    case infinite with sx tx show ?thesis
      by (auto simp: llist_inf_le)
  next
    case finite hence "\<forall>x t. s \<le> x \<and> t \<le> x \<longrightarrow> s \<le> t \<or> t \<le> s"
    proof (induct "s")
      case LNil_fin thus ?case by simp
    next
      case (LCons_fin a l) show ?case
      proof clarify
	fix x t assume alx: "a ## l \<le> x"
	  and tx: "t \<le> x" and tal: "\<not> t \<le> a ## l"
	show " a ## l \<le> t"
	proof (cases t)
	  case LNil thus ?thesis using tal by auto
	next case (LCons b ts) note tcons = this show ?thesis
	  proof (cases x)
	    case LNil thus ?thesis using alx by auto
	  next
	    case (LCons c xs)
	    from alx  LCons have ac: "a = c" and lxs: "l \<le> xs"
	      by auto
	    from tx tcons LCons have bc: "b = c" and tsxs: "ts \<le> xs"
	      by auto
	    from tcons tal ac bc have tsl: "\<not> ts \<le> l"
	      by auto
	    from LCons_fin lxs tsxs tsl have "l \<le> ts"
	      by auto
	    with tcons ac bc show ?thesis
	      by auto
	  qed
	qed
      qed
    qed
    thus ?thesis using sx tx by auto
  qed
qed

constdefs
  pfinpref :: "'a set \<Rightarrow> 'a llist \<Rightarrow> 'a llist set"
  "pfinpref A s \<equiv> finpref A s - {LNil}"

lemma pfinpref_iff [iff]:
  "(x \<in> pfinpref A s) = (x \<in> finpref A s \<and> x \<noteq> LNil)"
  by (auto simp: pfinpref_def)


section{* Safety and Liveness *}

constdefs
  infsafety :: "'a set \<Rightarrow> 'a llist set \<Rightarrow> bool"
  "infsafety A P \<equiv> \<forall> t \<in> A\<^sup>\<omega>. (\<forall> r \<in> finpref A t. \<exists> s \<in> A\<^sup>\<omega>. r @@ s \<in> P) \<longrightarrow> t \<in> P"

  infliveness :: "'a set \<Rightarrow> 'a llist set \<Rightarrow> bool"
  "infliveness A P \<equiv> \<forall> t \<in> A\<^sup>\<star>. \<exists> s \<in> A\<^sup>\<omega>. t @@ s \<in> P"

  possafety :: "'a set \<Rightarrow> 'a llist set \<Rightarrow> bool"
  "possafety A P \<equiv> \<forall> t \<in> A\<^sup>\<spadesuit>. (\<forall> r \<in> pfinpref A t. \<exists> s \<in> A\<^sup>\<infinity>. r @@ s \<in> P) \<longrightarrow> t \<in> P"

  posliveness :: "'a set \<Rightarrow> 'a llist set \<Rightarrow> bool"
  "posliveness A P \<equiv> \<forall> t \<in> A\<^sup>\<clubsuit>. \<exists> s \<in> A\<^sup>\<infinity>. t @@ s \<in> P"

  safety :: "'a set \<Rightarrow> 'a llist set \<Rightarrow> bool"
  "safety A P \<equiv> \<forall> t \<in> A\<^sup>\<infinity>. (\<forall> r \<in> finpref A t. \<exists> s \<in> A\<^sup>\<infinity>. r @@ s \<in> P) \<longrightarrow> t \<in> P"

  liveness :: "'a set \<Rightarrow> 'a llist set \<Rightarrow> bool"
  "liveness A P \<equiv> \<forall> t \<in> A\<^sup>\<star>. \<exists> s \<in> A\<^sup>\<infinity>. t @@ s \<in> P"

lemma safetyI:
  "(\<And>t. \<lbrakk>t \<in>  A\<^sup>\<infinity>; \<forall> r \<in> finpref A t. \<exists> s \<in> A\<^sup>\<infinity>. r @@ s \<in> P\<rbrakk> \<Longrightarrow> t \<in> P)
  \<Longrightarrow> safety A P"
  by (unfold safety_def) blast

lemma safetyD:
  "\<lbrakk> safety A P;  t \<in> A\<^sup>\<infinity>;
    \<And>r. r \<in> finpref A t \<Longrightarrow> \<exists> s \<in> A\<^sup>\<infinity>. r @@ s \<in> P
  \<rbrakk> \<Longrightarrow> t \<in> P"
  by (unfold safety_def) blast

lemma safetyE:
  "\<lbrakk> safety A P;
    \<forall> t \<in> A\<^sup>\<infinity>. (\<forall> r \<in> finpref A t. \<exists> s \<in> A\<^sup>\<infinity>. r @@ s \<in> P) \<longrightarrow> t \<in> P \<Longrightarrow> R
   \<rbrakk> \<Longrightarrow> R"
  by (unfold safety_def) blast

lemma safety_prefix_closed:
  "safety UNIV P \<Longrightarrow> prefix_closed P"
  by (auto dest!: safetyD
       simp: prefix_closed_def finpref_def llist_le_def lappend_assoc)
    blast

lemma livenessI:
  "(\<And>s. s\<in> A\<^sup>\<star> \<Longrightarrow> \<exists> t \<in> A\<^sup>\<infinity>. s @@ t \<in> P) \<Longrightarrow> liveness A P"
  by (auto simp: liveness_def)

lemma livenessE:
  "\<lbrakk> liveness A P; \<And>t. \<lbrakk>  t \<in> A\<^sup>\<infinity>; s @@ t \<in> P\<rbrakk> \<Longrightarrow> R; s \<notin> A\<^sup>\<star> \<Longrightarrow> R\<rbrakk> \<Longrightarrow> R"
  by (auto simp: liveness_def)

lemma possafetyI:
  "(\<And>t. \<lbrakk>t \<in>  A\<^sup>\<spadesuit>; \<forall> r \<in> pfinpref A t. \<exists> s \<in> A\<^sup>\<infinity>. r @@ s \<in> P\<rbrakk> \<Longrightarrow> t \<in> P)
  \<Longrightarrow> possafety A P"
  by (unfold possafety_def) blast

lemma possafetyD:
  "\<lbrakk> possafety A P;  t \<in> A\<^sup>\<spadesuit>;
    \<And>r. r \<in> pfinpref A t \<Longrightarrow> \<exists> s \<in> A\<^sup>\<infinity>. r @@ s \<in> P
  \<rbrakk> \<Longrightarrow> t \<in> P"
  by (unfold possafety_def) blast

lemma possafetyE:
  "\<lbrakk> possafety A P;
    \<forall> t \<in> A\<^sup>\<spadesuit>. (\<forall> r \<in> pfinpref A t. \<exists> s \<in> A\<^sup>\<infinity>. r @@ s \<in> P) \<longrightarrow> t \<in> P \<Longrightarrow> R
   \<rbrakk> \<Longrightarrow> R"
  by (unfold possafety_def) blast

lemma possafety_pprefix_closed:
  assumes psafety: "possafety UNIV P"
  shows "pprefix_closed P"
proof (unfold pprefix_closed_def, clarify)
  fix t s assume tP: "t \<in> P" and st: "s \<le> t" and spos: "s \<noteq> LNil"
  from psafety show "s \<in> P"
  proof (rule possafetyD)
    from spos show  "s \<in> UNIV\<^sup>\<spadesuit>" by auto
  next fix r assume "r \<in> pfinpref UNIV s"
    then obtain u where scons: "s = r @@ u"
      by (auto simp: pfinpref_def finpref_def llist_le_def)
    with st obtain v where "t = r @@ u @@ v"
      by (auto simp: lappend_assoc llist_le_def)
    with tP show "\<exists>s\<in>UNIV\<^sup>\<infinity>. r @@ s \<in> P" by auto
  qed
qed

lemma poslivenessI:
  "(\<And>s. s\<in> A\<^sup>\<clubsuit> \<Longrightarrow> \<exists> t \<in> A\<^sup>\<infinity>. s @@ t \<in> P) \<Longrightarrow> posliveness A P"
  by (auto simp: posliveness_def)

lemma poslivenessE:
  "\<lbrakk> posliveness A P; \<And>t. \<lbrakk>  t \<in> A\<^sup>\<infinity>; s @@ t \<in> P\<rbrakk> \<Longrightarrow> R; s \<notin> A\<^sup>\<clubsuit> \<Longrightarrow> R\<rbrakk> \<Longrightarrow> R"
  by (auto simp: posliveness_def)

end