(*  Title:      FMap.thy
    ID:         $Id: FMap.thy,v 1.1 2009/11/12 11:55:49 flokam Exp $
    Author:     Ludovic Henrio and Florian Kammuller
                2006

    Note:       Finite maps for Sigma-calculus
                Idea use axiomatic type classes to preserve
                usability of datatype afterwards, i.e. definition
                of an object as a finite map of labels to fields in
                a datatype.
*)

header {* Finite maps with axclasses *}

theory FMap imports ListPre begin

axclass fintype < type

finite_set: " finite (UNIV)"

types ('a, 'b) fmap = "('a :: fintype) ~=> 'b" (infixl "-~>" 50)

axclass inftype < type

infinite: "\<not>finite UNIV"

theorem fset_induct:
  "P {} \<Longrightarrow> (\<And>x (F::('a::fintype)set). x \<notin> F \<Longrightarrow> P F \<Longrightarrow> P (insert x F)) \<Longrightarrow> P F"
proof (rule_tac P=P and F=F in finite_induct)
  from finite_subset[OF subset_UNIV] finite_set show "finite F" by auto
next
  assume "P {}" thus "P {}" by simp
next
  fix x F 
  assume "\<And>x F. \<lbrakk> x \<notin> F; P F \<rbrakk> \<Longrightarrow> P (insert x F)" and "x \<notin> F" and "P F"
  thus "P (insert x F)" by simp
qed

theorem fmap_unique: "x = y \<Longrightarrow> (f::('a,'b)fmap) x = f y"
  by (erule ssubst, rule refl)

theorem fmap_case:
  "(F::('a -~> 'b)) = empty \<or> (\<exists>x y (F'::('a -~> 'b)). F = F'(x \<mapsto> y))"
proof (cases "F = empty")
  case True thus ?thesis by (rule disjI1)
next
  case False thus ?thesis
  proof (simp)
    from `F \<noteq> empty` have "\<exists>x. F x \<noteq> None"
    proof (rule contrapos_np)
      assume "\<not> (\<exists>x. F x \<noteq> None)"
      hence "\<forall>x. F x = None" by simp
      hence "\<And>x. F x = None" by simp
      thus "F = empty" by (rule ext)
    qed
    thus "\<exists>x y F'. F = F'(x \<mapsto> y)"
    proof
      fix x assume "F x \<noteq> None"
      hence "\<And>y. F y = (F(x \<mapsto> the (F x))) y" by auto
      hence "F = F(x \<mapsto> the (F x))" by (rule ext)
      thus ?thesis by auto
    qed
  qed
qed

(* define the witness as a constant function so it may be used in the proof of
the induction scheme below *)
constdefs  
  set_fmap :: "'a -~> 'b \<Rightarrow> ('a * 'b)set"
  "set_fmap F == {(x, y). x \<in> dom F \<and> F x = Some y}"

  pred_set_fmap :: "(('a -~> 'b) \<Rightarrow> bool) \<Rightarrow> (('a * 'b)set) \<Rightarrow> bool"
  "pred_set_fmap P == \<lambda>S. P (\<lambda>x. if x \<in> fst ` S 
                                  then (THE y. (\<exists>z. y = Some z \<and> (x, z) \<in> S)) 
                                  else None)" 

  fmap_minus_direct :: "[('a -~> 'b), ('a * 'b)] \<Rightarrow> ('a -~> 'b)" (infixl "--" 50)
  "F -- x == (\<lambda>z. if (fst x = z \<and> ((F (fst x)) = Some (snd x))) 
                   then None 
                   else (F z))"

lemma insert_lem : "insert x A = B \<Longrightarrow> x \<in> B"
  by auto

lemma fmap_minus_fmap: 
  fixes F x a b
  assumes "(F -- x) a = Some b"
  shows "F a = Some b"
proof (rule ccontr, cases "F a")
  case None hence "a \<notin> dom F" by auto
  hence "(F -- x) a = None" 
    unfolding fmap_minus_direct_def by auto
  with `(F -- x) a = Some b` show False by simp
next
  assume "F a \<noteq> Some b"
  case (Some y) thus False
  proof (cases "fst x = a")
    case True thus False
    proof (cases "snd x = y")
      case True with `F a = Some y` `fst x = a` 
      have "(F -- x) a = None" unfolding fmap_minus_direct_def by auto
      with `(F -- x) a = Some b` show False by simp
    next
      case False with `F a = Some y` `fst x = a` 
      have "F (fst x) \<noteq> Some (snd x)" by auto
      with `(F -- x) a = Some b` have "F a = Some b" 
	unfolding fmap_minus_direct_def by auto
      with `F a \<noteq> Some b` show False by simp
    qed
  next
    case False with `(F -- x) a = Some b` 
    have "F a = Some b" unfolding fmap_minus_direct_def by auto
    with `F a \<noteq> Some b` show False by simp
  qed
qed

lemma set_fmap_minus_iff: 
  "set_fmap ((F::(('a::fintype) -~> 'b)) -- x) = set_fmap F - {x}"
  unfolding set_fmap_def 
proof (auto)
  fix a b assume "(F -- x) a = Some b" from fmap_minus_fmap[OF this]
  show "\<exists>y. F a = Some y" by blast
next
  fix a b assume "(F -- x) a = Some b" from fmap_minus_fmap[OF this]
  show "F a = Some b" by assumption
next
  fix a b assume "(F -- (a, b)) a = Some b" 
  with fmap_minus_fmap[OF this] show False 
    unfolding fmap_minus_direct_def by auto
next
  fix a b assume "(a,b) \<noteq> x" and "F a = Some b"
  hence "fst x \<noteq> a \<or> F (fst x) \<noteq> Some (snd x)" by auto
  with `F a = Some b` show "\<exists>y. (F -- x) a = Some y" 
    unfolding fmap_minus_direct_def by (rule_tac x = b in exI, simp)
next
  fix a b assume "(a,b) \<noteq> x" and "F a = Some b"
  hence "fst x \<noteq> a \<or> F (fst x) \<noteq> Some (snd x)" by auto
  with `F a = Some b` show "(F -- x) a = Some b" 
    unfolding fmap_minus_direct_def by simp  
qed

lemma set_fmap_minus_insert:
  fixes F :: "('a::fintype * 'b)set" and  F':: "('a::fintype) -~> 'b" and x
  assumes "x \<notin> F" and "insert x F = set_fmap F'"
  shows "F = set_fmap (F' -- x)"
proof -
  from `x \<notin> F` sym[OF `insert x F = set_fmap F'`] set_fmap_minus_iff[of F' x] 
  show ?thesis by simp
qed

lemma notin_fmap_minus: "x \<notin> set_fmap ((F::(('a::fintype) -~> 'b)) -- x)"
  by (auto simp: set_fmap_minus_iff)

lemma fst_notin_fmap_minus_dom:
  fixes F x and F' :: "('a::fintype) -~> 'b"
  assumes "insert x F = set_fmap F'"
  shows "fst x \<notin> dom (F' -- x)"
proof (rule ccontr, auto)
  fix y assume "(F' -- x) (fst x) = Some y"
  with notin_fmap_minus[of x F'] 
  have "y \<noteq> snd x"
    unfolding set_fmap_def by auto
  moreover
  from insert_lem[OF `insert x F = set_fmap F'`] 
  have "F' (fst x) = Some (snd x)"
    unfolding set_fmap_def by auto
  ultimately show False 
    using fmap_minus_fmap[OF `(F' -- x) (fst x) = Some y`]
    by simp
qed

lemma  set_fmap_pair: 
  "x \<in> set_fmap F \<Longrightarrow> (fst x \<in> dom F \<and> snd x = the (F (fst x)))"
  by (simp add: set_fmap_def, auto)

lemma  set_fmap_inv1: 
  "\<lbrakk> fst x \<in> dom F; snd x = the (F (fst x)) \<rbrakk> \<Longrightarrow> (F -- x)(fst x \<mapsto> snd x) = F"
proof (rule ext)
  fix xa assume "fst x \<in> dom F" and "snd x = the (F (fst x))"
  thus "((F -- x)(fst x \<mapsto> snd x)) xa = F xa"
    unfolding fmap_minus_direct_def
    by (case_tac "xa = fst x", auto)
qed

lemma set_fmap_inv2: 
  "fst x \<notin> dom F \<Longrightarrow> insert x (set_fmap F) = set_fmap (F(fst x \<mapsto> snd x))"
  unfolding set_fmap_def
proof
  assume "fst x \<notin> dom F"
  thus
    "insert x {(x, y). x \<in> dom F \<and> F x = Some y} \<subseteq> 
    {(xa, y). xa \<in> dom (F(fst x \<mapsto> snd x)) \<and> (F(fst x \<mapsto> snd x)) xa = Some y}"
    by force
next
  have
    "\<And>z. z \<in> {(xa, y). xa \<in> dom (F(fst x \<mapsto> snd x)) 
                     \<and> (F(fst x \<mapsto> snd x)) xa = Some y}
    \<Longrightarrow> z \<in> insert x {(x, y). x \<in> dom F \<and> F x = Some y}"
    proof -
      fix z
      assume 
	"z \<in> {(xa, y). xa \<in> dom (F(fst x \<mapsto> snd x)) 
	             \<and> (F(fst x \<mapsto> snd x)) xa = Some y}"
      hence "z = x \<or> ((fst z) \<in> dom F \<and> F (fst z) = Some (snd z))"
      proof (cases "fst x = fst z")
	case True thus ?thesis using prems by fastsimp
      next
	case False thus ?thesis using prems by fastsimp
      qed
      thus "z \<in> insert x {(x, y). x \<in> dom F \<and> F x = Some y}" by fastsimp
    qed
  thus 
    "{(xa, y). xa \<in> dom (F(fst x \<mapsto> snd x)) \<and> (F(fst x \<mapsto> snd x)) xa = Some y} \<subseteq> 
    insert x {(x, y). x \<in> dom F \<and> F x = Some y}" by auto
qed

lemma rep_fmap_base: "P (F::('a  -~> 'b)) = (pred_set_fmap P)(set_fmap F)"
  unfolding pred_set_fmap_def set_fmap_def
proof (rule_tac f = P in arg_cong)
  have 
    "\<And>x. F x = 
         (\<lambda>x. if x \<in> fst ` {(x, y). x \<in> dom F \<and> F x = Some y}
               then THE y. \<exists>z. y = Some z 
                             \<and> (x, z) \<in> {(x, y). x \<in> dom F \<and> F x = Some y}
               else None) x"
  proof auto
    fix a b
    assume "F a = Some b"
    hence "\<exists>!x. x = Some b \<and> a \<in> dom F"
    proof (rule_tac a = "F a" in ex1I)
      assume "F a = Some b"
      thus "F a = Some b \<and> a \<in> dom F" 
	by (simp add: dom_def)
    next
      fix x assume "F a = Some b" and "x = Some b \<and> a \<in> dom F"
      thus "x = F a" by simp
    qed
    hence "(THE y. y = Some b \<and> a \<in> dom F) = Some b \<and> a \<in> dom F" 
      by (rule theI')
    thus "Some b = (THE y. y = Some b \<and> a \<in> dom F)" 
      by simp
  next
    fix x assume nin_x: "x \<notin> fst ` {(x, y). x \<in> dom F \<and> F x = Some y}"
    thus "F x = None"
    proof (cases "F x")
      case None thus ?thesis by assumption
    next
      case (Some a)
      hence "x \<in> fst ` {(x, y). x \<in> dom F \<and> F x = Some y}"
	by (simp add: image_def dom_def)
      with nin_x show ?thesis by simp
    qed
  qed
  thus 
    "F = (\<lambda>x. if x \<in> fst ` {(x, y). x \<in> dom F \<and> F x = Some y}
               then THE y. \<exists>z. y = Some z 
                             \<and> (x, z) \<in> {(x, y). x \<in> dom F \<and> F x = Some y}
               else None)"
    by (rule ext)
qed

lemma rep_fmap: 
  "\<exists>(Fp ::('a * 'b)set) (P'::('a * 'b)set \<Rightarrow> bool). P (F::('a -~> 'b)) = P' Fp"
proof -
  from rep_fmap_base show ?thesis by blast
qed

theorem finite_fsets: "finite (F::('a::fintype)set)"
proof -
  from finite_subset[OF subset_UNIV] finite_set show "finite F" by auto
qed

lemma finite_dom_fmap: "finite (dom (F::('a -~> 'b))::('a::fintype)set)"
  by (rule finite_fsets)

lemma finite_fmap_ran: "finite (ran (F::(('a::fintype) -~> 'b)))"
  unfolding ran_def
proof -
  from finite_dom_fmap finite_imageI 
  have "finite ((\<lambda>x. the (F x)) ` (dom F))" 
    by blast
  moreover
  have "{b. \<exists>a. F a = Some b} = (\<lambda>x. the (F x)) ` (dom F)"
    unfolding image_def dom_def by force
  ultimately
  show "finite {b. \<exists>a. F a = Some b}"  by simp
qed

lemma finite_fset_map: "finite (set_fmap (F::(('a::fintype) -~> 'b)))"
proof -
  from finite_cartesian_product finite_dom_fmap finite_fmap_ran
  have "finite (dom F \<times> ran F)" by auto
  moreover
  have "set_fmap F \<subseteq> dom F \<times> ran F"
    unfolding set_fmap_def dom_def ran_def by fastsimp
  ultimately
  show ?thesis using finite_subset by auto
qed

lemma rep_fmap_imp: 
  "\<forall>F x z. x \<notin> dom (F::('a -~> 'b)) \<longrightarrow> P F \<longrightarrow> P (F(x \<mapsto> z))
  \<Longrightarrow> (\<forall>F x z. x \<notin> fst ` (set_fmap F) \<longrightarrow> (pred_set_fmap P)(set_fmap F) 
        \<longrightarrow> (pred_set_fmap P) (insert (x,z) (set_fmap F)))"
proof (clarify)
  fix P F x z
  assume 
    "\<forall>F x z. x \<notin> dom (F::('a -~> 'b)) \<longrightarrow> P F \<longrightarrow> P (F(x \<mapsto> z))" and
    "x \<notin> fst ` set_fmap F" and "(pred_set_fmap P)(set_fmap F)"
  hence notin: "x \<notin> dom F"
    unfolding set_fmap_def image_def dom_def by simp
  moreover
  from `pred_set_fmap P (set_fmap F)` have "P F" by (simp add: rep_fmap_base)
  ultimately
  have "P (F(x \<mapsto> z))" using `\<forall>F x z. x \<notin> dom F \<longrightarrow> P F \<longrightarrow> P (F(x \<mapsto> z))` 
    by blast
  hence "(pred_set_fmap P) (set_fmap (F(x \<mapsto> z)))"
    by (simp add: rep_fmap_base)
  moreover
  from notin 
  have "(insert (x,z) (set_fmap F)) = (set_fmap (F(fst (x,z) \<mapsto> snd (x,z))))"
    by (simp add: set_fmap_inv2)
  ultimately
  show "(pred_set_fmap P) (insert (x,z) (set_fmap F))" by simp
qed

lemma empty_dom: 
  fixes g
  assumes "{} = dom g"
  shows "g = empty"
proof 
  fix x from assms show "g x = None" by auto
qed

theorem fmap_induct[rule_format, case_names empty insert]:
  fixes  P  :: "(('a :: fintype) -~> 'b) \<Rightarrow> bool" and  F' :: "('a  -~> 'b)"
  assumes 
  "P empty" and
  "\<forall>(F::('a -~> 'b)) x z. x \<notin> dom F \<longrightarrow> P F \<longrightarrow> P (F(x \<mapsto> z))"
  shows "P F'"
proof -
  {
    fix F :: "'a \<times> 'b \<Rightarrow> bool" assume "finite F"
    hence "\<forall>F'. F = set_fmap F' \<longrightarrow> pred_set_fmap P (set_fmap F')"
    proof (induct F)
      case empty thus ?case
      proof (intro strip)
	fix F' :: "'a -~> 'b" assume "{} = set_fmap F'"
	hence "\<And>a. F' a = None" unfolding set_fmap_def by auto
	hence "F' = empty" by (rule ext)
	with `P empty` rep_fmap_base[of P empty] 
	show "pred_set_fmap P (set_fmap F')" by simp
      qed
    next
      case (insert x Fa) thus ?case
      proof (intro strip)
	fix Fb :: "'a -~> 'b"
	assume "insert x Fa = set_fmap Fb"
	from 
	  set_fmap_minus_insert[OF `x \<notin> Fa` this]
	  `\<forall>F'. Fa = set_fmap F' \<longrightarrow> pred_set_fmap P (set_fmap F')` 
	  rep_fmap_base[of P "Fb -- x"]
	have "P (Fb -- x)" by blast
	with 
	  `\<forall>F x z. x \<notin> dom F \<longrightarrow> P F \<longrightarrow> P (F(x \<mapsto> z))` 
	  fst_notin_fmap_minus_dom[OF `insert x Fa = set_fmap Fb`]
	have "P ((Fb -- x)(fst x \<mapsto> snd x))" by blast
	moreover
	from 
	  insert_absorb[OF insert_lem[OF `insert x Fa = set_fmap Fb`]]
	  set_fmap_minus_iff[of Fb x]
	  set_fmap_inv2[OF 
	   fst_notin_fmap_minus_dom[OF `insert x Fa = set_fmap Fb`]] 
	have "set_fmap Fb = set_fmap ((Fb -- x)(fst x \<mapsto> snd x))"
	  by simp
	ultimately
	show "pred_set_fmap P (set_fmap Fb)" 
	  using rep_fmap_base[of P "(Fb -- x)(fst x \<mapsto> snd x)"]
	  by simp
      qed
    qed
  } 
  from this[OF finite_fset_map[of F']]
       rep_fmap_base[of P F']
  show "P F'" by blast
qed

lemma fmap_induct3[consumes 2, case_names empty insert]:
  "\<And>(F2::('a::fintype) -~> 'b) (F3::('a -~> 'b)).
   \<lbrakk> dom (F1::('a -~> 'b)) = dom F2; dom F3 = dom F1; 
     P empty empty empty;
     \<And>x a b c (F1::('a -~> 'b)) (F2::('a -~> 'b)) (F3::('a -~> 'b)).
     \<lbrakk> P F1 F2 F3; dom F1 = dom F2; dom F3 = dom F1; x \<notin> dom F1 \<rbrakk>
     \<Longrightarrow> P (F1(x \<mapsto> a)) (F2(x \<mapsto> b)) (F3(x \<mapsto> c)) \<rbrakk>
  \<Longrightarrow> P F1 F2 F3"
proof (induct F1 rule: fmap_induct)
  case empty
  from `dom empty = dom F2` have "F2 = empty" by (simp add: empty_dom)
  moreover
  from `dom F3 = dom empty` have "F3 = empty" by (simp add: empty_dom)
  ultimately
  show ?case using `P empty empty empty` by simp
next
  case (insert F x y) thus ?case
  proof (cases "F2 = empty")
    case True with `dom (F(x \<mapsto> y)) = dom F2` 
    have "dom (F(x \<mapsto> y)) = {}" by auto
    thus ?thesis by auto
  next
    case False thus ?thesis
    proof (cases "F3 = empty")
      case True with `dom F3 = dom (F(x \<mapsto> y))` 
      have "dom (F(x \<mapsto> y)) = {}" by simp
      thus ?thesis by simp
    next
      case False thus ?thesis
      proof -
	from `F2 \<noteq> Map.empty` 
	have "\<forall>l\<in>dom F2. \<exists>f'. F2 = f'(l \<mapsto> the (F2 l)) \<and> l \<notin> dom f'"
	  by (simp add: one_more_dom)
	moreover
	from `dom (F(x \<mapsto> y)) = dom F2` have "x \<in> dom F2" by force
	ultimately have "\<exists>f'. F2 = f'(x \<mapsto> the (F2 x)) \<and> x \<notin> dom f'" by blast
	then obtain F2' where "F2 = F2'(x \<mapsto> the (F2 x))" and "x \<notin> dom F2'" 
	  by auto

	from `F3 \<noteq> Map.empty` 
	have "\<forall>l\<in>dom F3. \<exists>f'. F3 = f'(l \<mapsto> the (F3 l)) \<and> l \<notin> dom f'"
	  by (simp add: one_more_dom)
	moreover from `dom F3 = dom (F(x \<mapsto> y))` have "x \<in> dom F3" by force
	ultimately have "\<exists>f'. F3 = f'(x \<mapsto> the (F3 x)) \<and> x \<notin> dom f'" by blast
	then obtain F3' where "F3 = F3'(x \<mapsto> the (F3 x))" and "x \<notin> dom F3'" 
	  by auto

	show ?thesis
	proof -
	  from `dom (F(x \<mapsto> y)) = dom F2` `F2 = F2'(x \<mapsto> the (F2 x))`
	  have "dom (F(x \<mapsto> y)) = dom (F2'(x \<mapsto> the (F2 x)))" by simp
	  with `x \<notin> dom F` `x \<notin> dom F2'` have "dom F = dom F2'" by auto
	  
	  moreover
	  from `dom F3 = dom (F(x \<mapsto> y))` `F3 = F3'(x \<mapsto> the (F3 x))`
	  have "dom (F(x \<mapsto> y)) = dom (F3'(x \<mapsto> the (F3 x)))" by simp
	  with `x \<notin> dom F` `x \<notin> dom F3'` have "dom F3' = dom F" by auto

	  ultimately have "P F F2' F3'" using prems by simp

	  with 
	    `\<And>F1 F2 F3 x a b c.
              \<lbrakk> P F1 F2 F3; dom F1 = dom F2; dom F3 = dom F1; x \<notin> dom F1 \<rbrakk>
              \<Longrightarrow> P (F1(x \<mapsto> a)) (F2(x \<mapsto> b)) (F3(x \<mapsto> c))`
	    `dom F = dom F2'`
	    `dom F3' = dom F`
	    `x \<notin> dom F`
	  have "P (F(x \<mapsto> y)) (F2'(x \<mapsto> the (F2 x))) (F3'(x \<mapsto> the (F3 x)))" 
	    by simp
	  with `F2 = F2'(x \<mapsto> the (F2 x))` `F3 = F3'(x \<mapsto> the (F3 x))`
	  show "P (F(x \<mapsto> y)) F2 F3" by simp
	qed
      qed
    qed
  qed
qed

lemma fmap_ex_cof2:
  "\<And>(P::'c \<Rightarrow> 'c \<Rightarrow> 'b option \<Rightarrow> 'b option \<Rightarrow> 'a \<Rightarrow> bool)
     (f'::('a::fintype) -~> 'b).
  \<lbrakk> dom f' = dom (f::('a -~> 'b)); 
    \<forall>l\<in>dom f. (\<exists>L. finite L 
                  \<and> (\<forall>s p. s \<notin> L \<and> p \<notin> L \<and> s \<noteq> p
                      \<longrightarrow> P s p (f l) (f' l) l)) \<rbrakk>
  \<Longrightarrow> \<exists>L. finite L \<and> (\<forall>l\<in>dom f. (\<forall>s p. s \<notin> L \<and> p \<notin> L \<and> s \<noteq> p 
                                   \<longrightarrow> P s p (f l) (f' l) l))"
proof (induct f rule: fmap_induct)
  case empty thus ?case by blast
next
  case (insert f l t P f') note imp = this(2) and pred = this(4)
  def pred_cof \<equiv> "\<lambda>L b b' l. \<forall>s p. s \<notin> L \<and> p \<notin> L \<and> s \<noteq> p \<longrightarrow> P s p b b' l"
  from 
    map_upd_nonempty[of f l t] `dom f' = dom (f(l \<mapsto> t))`
    one_more_dom[of l f']
  obtain f'a where 
    "f' = f'a(l \<mapsto> the(f' l))" and "l \<notin> dom f'a" and
    "dom (f'a(l \<mapsto> the(f' l))) = dom (f(l \<mapsto> t))"
    by auto
  from `l \<notin> dom f`
  have
    fla: "\<forall>la\<in>dom f. f la = (f(l \<mapsto> t)) la" and
    "\<forall>la\<in>dom f. f'a la = (f'a(l \<mapsto> the(f' l))) la"
    by auto
  with `f' = f'a(l \<mapsto> the(f' l))` 
  have f'ala: "\<forall>la\<in>dom f. f'a la = f' la" by simp
  have "\<exists>L. finite L \<and> (\<forall>la\<in>dom f. pred_cof L (f la) (f'a la) la)"
    unfolding pred_cof_def
  proof 
    (intro imp[OF insert_dom_less_eq[OF `l \<notin> dom f'a` `l \<notin> dom f` 
                                        `dom (f'a(l \<mapsto> the(f' l))) = dom (f(l \<mapsto> t))`]],
      intro strip)
    fix la assume "la \<in> dom f"
    with fla f'ala 
    have 
      "la \<in> dom (f(l \<mapsto> t))" and 
      "f la = (f(l \<mapsto> t)) la" and "f'a la = f' la"
      by auto
    with pred
    show "\<exists>L. finite L \<and> (\<forall>s p. s \<notin> L \<and> p \<notin> L \<and> s \<noteq> p \<longrightarrow> P s p (f la) (f'a la) la)"
      by (elim ssubst, blast)
  qed
  with fla f'ala obtain L where 
    "finite L" and predf: "\<forall>la\<in>dom f. pred_cof L ((f(l \<mapsto> t)) la) (f' la) la"
    by auto
  moreover
  have "l \<in> dom (f(l \<mapsto> t))" by simp
  with pred obtain L' where
    "finite L'" and predfl: "pred_cof L' ((f(l \<mapsto> t)) l) (f' l) l"
    unfolding pred_cof_def
    by blast
  ultimately show ?case
  proof (rule_tac x = "L \<union> L'" in exI, 
      intro conjI, simp, intro strip)
    fix s p la assume 
      sp: "s \<notin> L \<union> L' \<and> p \<notin> L \<union> L' \<and> s \<noteq> p" and indom: "la \<in> dom (f(l \<mapsto> t))"
    show "P s p ((f(l \<mapsto> t)) la) (f' la) la"
    proof (cases "la = l")
      case True with sp predfl show ?thesis 
	unfolding pred_cof_def
	by simp
    next
      case False with indom sp predf show ?thesis 
	unfolding pred_cof_def
	by force
    qed
  qed
qed

lemma fmap_ex_cof:
  fixes
  P :: "'c \<Rightarrow> 'c \<Rightarrow> 'b option \<Rightarrow> ('a::fintype) \<Rightarrow> bool"
  assumes
  "\<forall>l\<in>dom (f::('a -~> 'b)).
  (\<exists>L. finite L \<and> (\<forall>s p. s \<notin> L \<and> p \<notin> L \<and> s \<noteq> p \<longrightarrow> P s p (f l) l))"
  shows
  "\<exists>L. finite L \<and> (\<forall>l\<in>dom f. (\<forall>s p. s \<notin> L \<and> p \<notin> L \<and> s \<noteq> p \<longrightarrow> P s p (f l) l))"
  using assms fmap_ex_cof2[of f f  "\<lambda>s p b b' l. P s p b l"] by auto

lemma fmap_ball_all2:
  fixes 
  Px :: "'c \<Rightarrow> 'd \<Rightarrow> bool" and 
  P :: "'c \<Rightarrow> 'd \<Rightarrow> 'b option \<Rightarrow> bool"
  assumes
  "\<forall>l\<in>dom (f::('a::fintype) -~> 'b). \<forall>(x::'c) (y::'d). Px x y \<longrightarrow> P x y (f l)"
  shows
  "\<forall>x y. Px x y \<longrightarrow> (\<forall>l\<in>dom f. P x y (f l))"
proof (intro strip)
  fix x y l assume "Px x y" and "l \<in> dom f"
  with assms show "P x y (f l)" by blast
qed

lemma fmap_ball_all2':
  fixes 
  Px :: "'c \<Rightarrow> 'd \<Rightarrow> bool" and 
  P :: "'c \<Rightarrow> 'd \<Rightarrow> 'b option \<Rightarrow> ('a::fintype) \<Rightarrow> bool"
  assumes
  "\<forall>l\<in>dom (f::('a -~> 'b)). \<forall>(x::'c) (y::'d). Px x y \<longrightarrow> P x y (f l) l"
  shows
  "\<forall>x y. Px x y \<longrightarrow> (\<forall>l\<in>dom f. P x y (f l) l)"
proof (intro strip)
  fix x y l assume "Px x y" and "l \<in> dom f"
  with assms show "P x y (f l) l" by blast
qed

lemma fmap_ball_all3:
  fixes 
  Px :: "'c \<Rightarrow> 'd \<Rightarrow> 'e \<Rightarrow> bool" and 
  P :: "'c \<Rightarrow> 'd \<Rightarrow> 'e \<Rightarrow> 'b option \<Rightarrow> 'b option \<Rightarrow> bool" and
  f :: "('a::fintype) -~> 'b" and f' :: "'a -~> 'b"
  assumes
  "dom f' = dom f" and
  "\<forall>l\<in>dom f.
     \<forall>(x::'c) (y::'d) (z::'e). Px x y z \<longrightarrow> P x y z (f l) (f' l)"
  shows
  "\<forall>x y z. Px x y z \<longrightarrow> (\<forall>l\<in>dom f. P x y z (f l) (f' l))"
proof (intro strip)
  fix x y z l assume "Px x y z" and "l \<in> dom f"
  with assms show "P x y z (f l) (f' l)" by blast
qed

lemma fmap_ball_all4':
  fixes 
  Px :: "'c \<Rightarrow> 'd \<Rightarrow> 'e \<Rightarrow> 'f \<Rightarrow> bool" and 
  P :: "'c \<Rightarrow> 'd \<Rightarrow> 'e \<Rightarrow> 'f \<Rightarrow> 'b option \<Rightarrow> ('a::fintype) \<Rightarrow> bool"
  assumes
  "\<forall>l\<in>dom (f::('a -~> 'b)). 
    \<forall>(x::'c) (y::'d) (z::'e) (a::'f). Px x y z a \<longrightarrow> P x y z a (f l) l"
  shows
  "\<forall>x y z a. Px x y z a \<longrightarrow> (\<forall>l\<in>dom f. P x y z a (f l) l)"
proof (intro strip)
  fix x y z a l assume "Px x y z a" and "l \<in> dom f"
  with assms show "P x y z a (f l) l" by blast
qed

end