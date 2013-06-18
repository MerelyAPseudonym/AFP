header {* Coercion Operator *}

theory Coerce
imports HOLCF
begin

subsection {* Coerce *}

text {* The @{text domain} type class, which is the default type class
in HOLCF, fixes two overloaded functions: @{text "emb::'a \<rightarrow> udom"} and
@{text "prj::udom \<rightarrow> 'a"}. By composing the @{text prj} and @{text emb}
functions together, we can coerce values between any two types in
class @{text domain}. \medskip *}

definition coerce :: "'a \<rightarrow> 'b"
  where "coerce \<equiv> prj oo emb"

text {* When working with proofs involving @{text emb}, @{text prj},
and @{text coerce}, it is often difficult to tell at which types those
constants are being used. To alleviate this problem, we define special
input and output syntax to indicate the types. \medskip *}

syntax
  "_emb" :: "type \<Rightarrow> logic" ("(1EMB/(1'(_')))")
  "_prj" :: "type \<Rightarrow> logic" ("(1PRJ/(1'(_')))")
  "_coerce" :: "type \<Rightarrow> type \<Rightarrow> logic" ("(1COERCE/(1'(_,/ _')))")

translations
  "EMB('a)" \<rightharpoonup> "CONST emb :: 'a \<rightarrow> udom"
  "PRJ('a)" \<rightharpoonup> "CONST prj :: udom \<rightarrow> 'a"
  "COERCE('a,'b)" \<rightharpoonup> "CONST coerce :: 'a \<rightarrow> 'b"

typed_print_translation {*
let
  fun emb_tr' (ctxt : Proof.context) (Type(_, [T, _])) [] =
    Syntax.const @{syntax_const "_emb"} $ Syntax_Phases.term_of_typ ctxt T
  fun prj_tr' ctxt (Type(_, [_, T])) [] =
    Syntax.const @{syntax_const "_prj"} $ Syntax_Phases.term_of_typ ctxt T
  fun coerce_tr' ctxt (Type(_, [T, U])) [] =
    Syntax.const @{syntax_const "_coerce"} $
      Syntax_Phases.term_of_typ ctxt T $ Syntax_Phases.term_of_typ ctxt U
in
  [(@{const_syntax emb}, emb_tr'),
   (@{const_syntax prj}, prj_tr'),
   (@{const_syntax coerce}, coerce_tr')]
end
*}

lemma beta_coerce: "coerce\<cdot>x = prj\<cdot>(emb\<cdot>x)"
by (simp add: coerce_def)

lemma prj_emb: "prj\<cdot>(emb\<cdot>x) = coerce\<cdot>x"
by (simp add: coerce_def)

lemma coerce_strict [simp]: "coerce\<cdot>\<bottom> = \<bottom>"
by (simp add: coerce_def)

text {* Certain type instances of @{text coerce} may reduce to the
identity function, @{text emb}, or @{text prj}. \medskip *}

lemma coerce_eq_ID [simp]: "COERCE('a, 'a) = ID"
by (rule cfun_eqI, simp add: beta_coerce)

lemma coerce_eq_emb [simp]: "COERCE('a, udom) = EMB('a)"
by (rule cfun_eqI, simp add: beta_coerce)

lemma coerce_eq_prj [simp]: "COERCE(udom, 'a) = PRJ('a)"
by (rule cfun_eqI, simp add: beta_coerce)

text "Cancellation rules"

lemma emb_coerce:
  "DEFL('a) \<sqsubseteq> DEFL('b)
   \<Longrightarrow> EMB('b)\<cdot>(COERCE('a,'b)\<cdot>x) = EMB('a)\<cdot>x"
by (simp add: beta_coerce emb_prj_emb)

lemma coerce_prj:
  "DEFL('a) \<sqsubseteq> DEFL('b)
   \<Longrightarrow> COERCE('b,'a)\<cdot>(PRJ('b)\<cdot>x) = PRJ('a)\<cdot>x"
by (simp add: beta_coerce prj_emb_prj)

lemma coerce_idem [simp]:
  "DEFL('a) \<sqsubseteq> DEFL('b)
   \<Longrightarrow> COERCE('b,'c)\<cdot>(COERCE('a,'b)\<cdot>x) = COERCE('a,'c)\<cdot>x"
by (simp add: beta_coerce emb_prj_emb)

subsection {* More lemmas about emb and prj *}

lemma prj_cast_DEFL [simp]: "PRJ('a)\<cdot>(cast\<cdot>DEFL('a)\<cdot>x) = PRJ('a)\<cdot>x"
by (simp add: cast_DEFL)

lemma cast_DEFL_emb [simp]: "cast\<cdot>DEFL('a)\<cdot>(EMB('a)\<cdot>x) = EMB('a)\<cdot>x"
by (simp add: cast_DEFL)

text {* @{term "DEFL(udom)"} *}

lemma below_DEFL_udom [simp]: "A \<sqsubseteq> DEFL(udom)"
apply (rule cast_below_imp_below)
apply (rule cast.belowI)
apply (simp add: cast_DEFL)
done

subsection {* Coercing various datatypes *}

text {* Coercing from the strict product type @{typ "'a \<otimes> 'b"} to
another strict product type @{typ "'c \<otimes> 'd"} is equivalent to mapping
the @{text coerce} function separately over each component using
@{text "sprod_map :: ('a \<rightarrow> 'c) \<rightarrow> ('b \<rightarrow> 'd) \<rightarrow> 'a \<otimes> 'b \<rightarrow> 'c \<otimes> 'd"}. Each
of the several type constructors defined in HOLCF satisfies a similar
property, with respect to its own map combinator. \medskip *}

lemma coerce_u: "coerce = u_map\<cdot>coerce"
apply (rule cfun_eqI, simp add: coerce_def)
apply (simp add: emb_u_def prj_u_def liftemb_eq liftprj_eq)
apply (subst ep_pair.e_inverse [OF ep_pair_u])
apply (simp add: u_map_map cfcomp1)
done

lemma coerce_sfun: "coerce = sfun_map\<cdot>coerce\<cdot>coerce"
apply (rule cfun_eqI, simp add: coerce_def)
apply (simp add: emb_sfun_def prj_sfun_def)
apply (subst ep_pair.e_inverse [OF ep_pair_sfun])
apply (simp add: sfun_map_map cfcomp1)
done

lemma coerce_cfun': "coerce = cfun_map\<cdot>coerce\<cdot>coerce"
apply (rule cfun_eqI, simp add: prj_emb [symmetric])
apply (simp add: emb_cfun_def prj_cfun_def)
apply (simp add: prj_emb coerce_sfun coerce_u)
apply (simp add: encode_cfun_map [symmetric])
done

lemma coerce_ssum: "coerce = ssum_map\<cdot>coerce\<cdot>coerce"
apply (rule cfun_eqI, simp add: coerce_def)
apply (simp add: emb_ssum_def prj_ssum_def)
apply (subst ep_pair.e_inverse [OF ep_pair_ssum])
apply (simp add: ssum_map_map cfcomp1)
done

lemma coerce_sprod: "coerce = sprod_map\<cdot>coerce\<cdot>coerce"
apply (rule cfun_eqI, simp add: coerce_def)
apply (simp add: emb_sprod_def prj_sprod_def)
apply (subst ep_pair.e_inverse [OF ep_pair_sprod])
apply (simp add: sprod_map_map cfcomp1)
done

lemma coerce_prod: "coerce = prod_map\<cdot>coerce\<cdot>coerce"
apply (rule cfun_eqI, simp add: coerce_def)
apply (simp add: emb_prod_def prj_prod_def)
apply (subst ep_pair.e_inverse [OF ep_pair_prod])
apply (simp add: prod_map_map cfcomp1)
done

subsection {* Simplifying coercions *}

text {* When simplifying applications of the @{text coerce} function,
rewrite rules are always oriented to replace @{text coerce} at complex
types with other applications of @{text coerce} at simpler types. *}

text {* The safest rewrite rules for @{text coerce} are given the
@{text "[simp]"} attribute. For other rules that do not belong in the
global simpset, we use the @{text Named_Thms} facility to set up a
dynamic theorem list called @{text coerce_simp}, which will collect
additional rules for simplifying coercions. \medskip *}

ML {*
structure CoerceSimpData = Named_Thms
(
  val name = @{binding coerce_simp}
  val description = "rule for simplifying coercions"
)
*}

setup CoerceSimpData.setup

text {* The @{text coerce} function commutes with data constructors
for various HOLCF datatypes. \medskip *}

lemma coerce_up [simp]: "coerce\<cdot>(up\<cdot>x) = up\<cdot>(coerce\<cdot>x)"
by (simp add: coerce_u)

lemma coerce_sinl [simp]: "coerce\<cdot>(sinl\<cdot>x) = sinl\<cdot>(coerce\<cdot>x)"
by (simp add: coerce_ssum ssum_map_sinl')

lemma coerce_sinr [simp]: "coerce\<cdot>(sinr\<cdot>x) = sinr\<cdot>(coerce\<cdot>x)"
by (simp add: coerce_ssum ssum_map_sinr')

lemma coerce_spair [simp]: "coerce\<cdot>(:x, y:) = (:coerce\<cdot>x, coerce\<cdot>y:)"
by (simp add: coerce_sprod sprod_map_spair')

lemma coerce_Pair [simp]: "coerce\<cdot>(x, y) = (coerce\<cdot>x, coerce\<cdot>y)"
by (simp add: coerce_prod)

lemma beta_coerce_cfun [simp]: "coerce\<cdot>f\<cdot>x = coerce\<cdot>(f\<cdot>(coerce\<cdot>x))"
by (simp add: coerce_cfun')

lemma coerce_cfun: "coerce\<cdot>f = coerce oo f oo coerce"
by (simp add: cfun_eqI)

lemma coerce_cfun_app [coerce_simp]:
  "coerce\<cdot>f = (\<Lambda> x. coerce\<cdot>(f\<cdot>(coerce\<cdot>x)))"
by (simp add: cfun_eqI)

end
