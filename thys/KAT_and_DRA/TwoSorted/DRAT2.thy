(* Title:      Demonic refinement algebra
   Author:     Alasdair Armstrong, Victor B. F. Gomes, Georg Struth
   Maintainer: Georg Struth <g.struth at sheffield.ac.uk>
*)

header {* Two sorted Demonic Refinement Algebras *}

theory DRAT2
  imports "../DRA"
begin

text {*
  As an alternative to the one-sorted implementation of demonic refinement algebra with tests, 
  we provide a two-sorted, more conventional one.
  This alternative can be developed further along the lines of the one-sorted implementation.
*}

syntax "_dra" :: "'a \<Rightarrow> 'a" ("`_`")

named_theorems kat_hom "KAT test homomorphism rules"

ML {*
val dra_test_vars = ["p","q","r","s","t","p'","q'","r'","s'","t'","p''","q''","r''","s''","t''"]

fun map_ast_variables ast =
  case ast of
    (Ast.Variable v) =>
      if exists (fn tv => tv = v) dra_test_vars
      then Ast.Appl [Ast.Variable "test", Ast.Variable v]
      else Ast.Variable v
  | (Ast.Constant c) => Ast.Constant c
  | (Ast.Appl []) => Ast.Appl []
  | (Ast.Appl (f :: xs)) => Ast.Appl (f :: map map_ast_variables xs)

fun dra_hom_tac ctxt n =
  let
    val rev_rules =
      map (fn thm => thm RS @{thm sym}) (Named_Theorems.get ctxt @{named_theorems kat_hom})
  in
    asm_full_simp_tac (put_simpset HOL_basic_ss ctxt addsimps rev_rules) n
  end
*}

method_setup kat_hom = {*
  Scan.succeed (fn ctxt => SIMPLE_METHOD (CHANGED (dra_hom_tac ctxt 1)))
*}

parse_ast_translation {*
let
  fun dra_tr ctxt [t] = map_ast_variables t
in [(@{syntax_const "_dra"}, dra_tr)] end
*}

named_theorems vcg "verification condition generator rules"

ML {*
fun vcg_tac ctxt n =
  let
    fun vcg' [] = no_tac
      | vcg' (r :: rs) = rtac r n ORELSE vcg' rs;
  in REPEAT (CHANGED
       (dra_hom_tac ctxt n
        THEN REPEAT (vcg' (rev (Named_Theorems.get ctxt @{named_theorems vcg})))
        THEN dra_hom_tac ctxt n
        THEN TRY (rtac @{thm order_refl} n ORELSE asm_full_simp_tac (put_simpset HOL_basic_ss ctxt) n)))
  end
*}

method_setup vcg = {*
  Scan.succeed (fn ctxt => SIMPLE_METHOD (CHANGED (vcg_tac ctxt 1)))
*}

locale drat =
  fixes test :: "'a::boolean_algebra \<Rightarrow> 'b::dra"
  and not :: "'b::dra \<Rightarrow> 'b::dra" ("!")
  assumes test_sup [simp,kat_hom]: "test (sup p q) = `p + q`"
  and test_inf [simp,kat_hom]: "test (inf p q) = `p \<cdot> q`"
  and test_top [simp,kat_hom]: "test top = 1"
  and test_bot [simp,kat_hom]: "test bot = 0"
  and test_not [simp,kat_hom]: "test (- p) = `!p`"
  and test_iso_eq [kat_hom]: "p \<le> q \<longleftrightarrow> `p \<le> q`"

begin

notation test ("\<iota>")

lemma test_eq [kat_hom]: "p = q \<longleftrightarrow> `p = q`"
  by (metis eq_iff test_iso_eq)

lemma test_iso: "p \<le> q \<Longrightarrow> `p \<le> q`"
  by (simp add: test_iso_eq)

lemma test_meet_comm: "`p \<cdot> q = q \<cdot> p`"
  by kat_hom (fact inf_commute)

lemmas test_one_top[simp] = test_iso[OF top_greatest, simplified]

lemma test_star [simp]: "`p\<^sup>\<star> = 1`"
  by (metis star_subid test_iso test_top top_greatest)

lemmas [kat_hom] = test_star[symmetric]

lemma test_comp_add1 [simp]: "`!p + p = 1`"
  by kat_hom (metis compl_sup_top)

lemma test_comp_add2 [simp]: "`p + !p = 1`"
  by kat_hom (metis sup_compl_top)

lemma test_comp_mult1 [simp]: "`!p \<cdot> p = 0`"
  by (metis inf.commute inf_compl_bot test_bot test_inf test_not)

lemma test_comp_mult2 [simp]: "`p \<cdot> !p = 0`"
  by (metis inf_compl_bot test_bot test_inf test_not)

lemma test_eq1: "`y \<le> x` \<longleftrightarrow> `p\<cdot>y \<le> x` \<and> `!p\<cdot>y \<le> x`"
  apply default
  apply (metis mult_isol_var mult_onel test_not test_one_top)
  apply (subgoal_tac "`(p + !p)\<cdot>y \<le> x`")
  apply (metis mult_onel sup_compl_top test_not test_sup test_top)
  by (metis add_lub distrib_right')

lemma "`p\<cdot>x = p\<cdot>x\<cdot>q` \<Longrightarrow> `p\<cdot>x\<cdot>!q = 0`"
  nitpick oops

lemma test1: "`p\<cdot>x\<cdot>!q = 0` \<Longrightarrow> `p\<cdot>x = p\<cdot>x\<cdot>q`"
  by (metis add_0_left distrib_left mult_oner test_comp_add1)

lemma test2: "`p\<cdot>q\<cdot>p = p\<cdot>q`"
  by (metis inf.commute inf.left_idem test_inf)

lemma test3: "`p\<cdot>q\<cdot>!p = 0`"
  by (metis inf.assoc inf.idem inf.left_commute inf_compl_bot test_bot test_inf test_not)

lemma test4: "`!p\<cdot>q\<cdot>p = 0`"
  by (metis double_compl test3 test_not)

lemma total_correctness: "`p\<cdot>x\<cdot>!q = 0` \<longleftrightarrow> `x\<cdot>!q \<le> !p\<cdot>\<top>`"
  apply default
  apply (metis mult.assoc test_eq1 top_elim zero_least)
  by (metis annil test_comp_mult2 zero_unique mult.assoc mult_isol)

lemma test_iteration_sim: "`p\<cdot>x \<le> x\<cdot>p` \<Longrightarrow> `p\<cdot>x\<^sup>\<infinity> \<le> x\<^sup>\<infinity>\<cdot>p`"
  by (metis iteration_sim)

lemma test_iteration_annir: "`!p\<cdot>(p\<cdot>x)\<^sup>\<infinity> = !p`"
  by (metis (no_types) comm_monoid_add_class.add.left_neutral double_compl iteration_idep monoid_mult_class.mult.right_neutral test_comp_add2 test_inf test_not top_elim total_correctness)

end

end
