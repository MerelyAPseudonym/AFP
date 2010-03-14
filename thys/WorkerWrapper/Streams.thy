(*
 * The worker/wrapper transformation, following Gill and Hutton.
 * (C)opyright 2009, Peter Gammie, peteg42 at gmail.com.
 * License: BSD
 *)

(*<*)
theory Streams
imports HOLCF Nats WorkerWrapper
begin
(*>*)

section{* Memoisation using streams. *}

text {*
\label{sec:memoisation-example} *}

subsection{* Streams. *}

text{* The type of infinite streams. *}

domain 'a Stream = stcons (lazy sthead :: "'a") (lazy sttail :: "'a Stream") (infixr "&&" 65)

(*<*)
declare Stream.casedist[case_names bottom stcons, cases type: Stream]
declare Stream.ind[case_names adm bottom stcons, induct type: Stream]

lemma Stream_bisimI[intro]:
  "(\<And>xs ys. R xs ys
     \<Longrightarrow> (xs = \<bottom> \<and> ys = \<bottom>)
       \<or> (\<exists>h t t'. R t t' \<and> xs = h && t \<and> ys = h && t'))
  \<Longrightarrow> Stream_bisim R"
  unfolding Stream.bisim_def by blast
(*>*)

fixrec smap :: "('a \<rightarrow> 'b) \<rightarrow> 'a Stream \<rightarrow> 'b Stream"
where
  "smap\<cdot>f\<cdot>(x && xs) = f\<cdot>x && smap\<cdot>f\<cdot>xs"

(*<*)
lemma smap_strict[simp]: "smap\<cdot>f\<cdot>\<bottom> = \<bottom>"
by fixrec_simp
(*>*)

lemma smap_smap: "smap\<cdot>f\<cdot>(smap\<cdot>g\<cdot>xs) = smap\<cdot>(f oo g)\<cdot>xs"
(*<*) by (induct xs rule: Stream.ind, simp_all) (*>*)

fixrec i_th :: "'a Stream \<rightarrow> Nat \<rightarrow> 'a"
where
  "i_th\<cdot>(x && xs) = Nat_case\<cdot>x\<cdot>(i_th\<cdot>xs)"

abbreviation
  i_th_syn :: "'a Stream \<Rightarrow> Nat \<Rightarrow> 'a" (infixl "!!" 100) where
  "s !! i \<equiv> i_th\<cdot>s\<cdot>i"

(*<*)
lemma i_th_strict1[simp]: "\<bottom> !! i = \<bottom>"
by (fixrec_simp, simp)

lemma i_th_strict2[simp]: "s !! \<bottom> = \<bottom>" by (subst i_th.unfold, cases s, simp_all)
lemma i_th_0[simp]: "(s !! 0) = sthead\<cdot>s" by (subst i_th.unfold, cases s, simp_all)
lemma i_th_suc[simp]: "i \<noteq> \<bottom> \<Longrightarrow> (x && xs) !! (i + 1) = xs !! i" by (subst i_th.unfold, simp)
(*>*)

text{* The infinite stream of natural numbers. *}

fixrec nats :: "Nat Stream"
where
  "nats = 0 && smap\<cdot>(\<Lambda> x. 1 + x)\<cdot>nats"

(*<*)
declare nats.simps[simp del]
(*>*)

subsection{* The wrapper/unwrapper functions. *}

definition
  unwrapS' :: "(Nat \<rightarrow> 'a) \<rightarrow> 'a Stream" where
  "unwrapS' \<equiv> \<Lambda> f . smap\<cdot>f\<cdot>nats"

lemma unwrapS'_unfold: "unwrapS'\<cdot>f = f\<cdot>0 && smap\<cdot>(f oo (\<Lambda> x. 1 + x))\<cdot>nats"
(*<*)by (unfold unwrapS'_def, subst nats.unfold, simp add: smap_smap)(*>*)

fixrec unwrapS :: "(Nat \<rightarrow> 'a) \<rightarrow> 'a Stream"
where
  "unwrapS\<cdot>f = f\<cdot>0 && unwrapS\<cdot>(f oo (\<Lambda> x. 1 + x))"

(*<*)
declare unwrapS.simps[simp del]
(*>*)

text{* The two versions of @{term "unwrapS"} are equivalent. We could
try to fold some definitions here but it's easier if the stream
constructor is manifest. *}

lemma unwrapS_unwrapS'_eq: "unwrapS = unwrapS'" (is "?lhs = ?rhs")
proof(rule ext_cfun)
  fix f show "?lhs\<cdot>f = ?rhs\<cdot>f"
  proof(coinduct rule: Stream.coind)
    let ?R = "\<lambda>s s'. (\<exists>f. s = f\<cdot>0 && unwrapS\<cdot>(f oo (\<Lambda> x. 1 + x))
                        \<and> s' = f\<cdot>0 && smap\<cdot>(f oo (\<Lambda> x. 1 + x))\<cdot>nats)"
    show "Stream_bisim ?R"
    proof
      fix s s' assume "?R s s'"
      then obtain f where fs:  "s = f\<cdot>0 && unwrapS\<cdot>(f oo (\<Lambda> x. 1 + x))"
	              and fs': "s' = f\<cdot>0 && smap\<cdot>(f oo (\<Lambda> x. 1 + x))\<cdot>nats"
        by blast
      have "?R (unwrapS\<cdot>(f oo (\<Lambda> x. 1 + x))) (smap\<cdot>(f oo (\<Lambda> x. 1 + x))\<cdot>nats)"
	by ( rule exI[where x="f oo (\<Lambda> x. 1 + x)"]
           , subst unwrapS.unfold, subst nats.unfold, simp add: smap_smap)
      with fs fs'
      show "(s = \<bottom> \<and> s' = \<bottom>)
          \<or> (\<exists>h t t'.
              (\<exists>f. t = f\<cdot>0 && unwrapS\<cdot>(f oo (\<Lambda> x. 1 + x))
                 \<and> t' = f\<cdot>0 && smap\<cdot>(f oo (\<Lambda> x. 1 + x))\<cdot>nats)
                 \<and> s = h && t \<and> s' = h && t')" by best
    qed
    show "?R (?lhs\<cdot>f) (?rhs\<cdot>f)"
    proof -
      have lhs: "?lhs\<cdot>f = f\<cdot>0 && unwrapS\<cdot>(f oo (\<Lambda> x. 1 + x))" by (subst unwrapS.unfold, simp)
      have rhs: "?rhs\<cdot>f = f\<cdot>0 && smap\<cdot>(f oo (\<Lambda> x. 1 + x))\<cdot>nats" by (rule unwrapS'_unfold)
      from lhs rhs show ?thesis by best
    qed
  qed
qed

definition
  wrapS :: "'a Stream \<rightarrow> Nat \<rightarrow> 'a" where
  "wrapS \<equiv> \<Lambda> s i . s !! i"

text{* Note the identity requires that @{term "f"} be
strict. \citet[\S6.1]{GillHutton:2009} do not make this requirement,
an oversight on their part.

In practice all functions worth memoising are strict in the memoised
argument. *}

lemma wrapS_unwrapS_id':
  assumes strictF: "(f::Nat \<rightarrow> 'a)\<cdot>\<bottom> = \<bottom>"
  shows "unwrapS\<cdot>f !! n = f\<cdot>n"
using strictF
proof(induct n arbitrary: f rule: Nat_induct)
  case bottom with strictF show ?case by simp
next
  case zero thus ?case by (subst unwrapS.unfold, simp)
next
  case (Suc i f)
  have "unwrapS\<cdot>f !! (i + 1) = (f\<cdot>0 && unwrapS\<cdot>(f oo (\<Lambda> x. 1 + x))) !! (i + 1)"
    by (subst unwrapS.unfold, simp)
  also from Suc have "\<dots> = unwrapS\<cdot>(f oo (\<Lambda> x. 1 + x)) !! i" by simp
  also from Suc have "\<dots> = (f oo (\<Lambda> x. 1 + x))\<cdot>i" by simp
  also have "\<dots> = f\<cdot>(i + 1)" by (simp add: plus_commute)
  finally show ?case .
qed

lemma wrapS_unwrapS_id: "f\<cdot>\<bottom> = \<bottom> \<Longrightarrow> (wrapS oo unwrapS)\<cdot>f = f"
  by (rule ext_cfun, simp add: wrapS_unwrapS_id' wrapS_def)

subsection{* Fibonacci example. *}

definition
  fib_body :: "(Nat \<rightarrow> Nat) \<rightarrow> Nat \<rightarrow> Nat" where
  "fib_body \<equiv> \<Lambda> r. Nat_case\<cdot>1\<cdot>(Nat_case\<cdot>1\<cdot>(\<Lambda> n. r\<cdot>n + r\<cdot>(n + 1)))"

(*<*)
lemma fib_body_strict[simp]: "fib_body\<cdot>r\<cdot>\<bottom> = \<bottom>" by (simp add: fib_body_def)
(*>*)

definition
  fib :: "Nat \<rightarrow> Nat" where
  "fib \<equiv> fix\<cdot>fib_body"

(*<*)
lemma fib_strict[simp]: "fib\<cdot>\<bottom> = \<bottom>"
  by (unfold fib_def, subst fix_eq, fold fib_def, simp add: fib_body_def)
(*>*)

text{* Apply worker/wrapper. *}

definition
  fib_work :: "Nat Stream" where
  "fib_work \<equiv> fix\<cdot>(unwrapS oo fib_body oo wrapS)"

definition
  fib_wrap :: "Nat \<rightarrow> Nat" where
  "fib_wrap \<equiv> wrapS\<cdot>fib_work"

lemma wrapS_unwrapS_fib_body: "wrapS oo unwrapS oo fib_body = fib_body"
proof(rule ext_cfun)
  fix r show "(wrapS oo unwrapS oo fib_body)\<cdot>r = fib_body\<cdot>r"
    using wrapS_unwrapS_id[where f="fib_body\<cdot>r"] by simp
qed

lemma fib_ww_eq: "fib = fib_wrap"
  using worker_wrapper_body[OF wrapS_unwrapS_fib_body]
  by (simp add: fib_def fib_wrap_def fib_work_def)

text{* Optimise. *}

fixrec
  fib_work_final :: "Nat Stream"
and
  fib_f_final :: "Nat \<rightarrow> Nat"
where
  "fib_work_final = smap\<cdot>fib_f_final\<cdot>nats"
| "fib_f_final = Nat_case\<cdot>1\<cdot>(Nat_case\<cdot>1\<cdot>(\<Lambda> n'. fib_work_final !! n' + fib_work_final !! (n' + 1)))"

declare fib_f_final.simps[simp del] fib_work_final.simps[simp del]

definition
  fib_final :: "Nat \<rightarrow> Nat" where
  "fib_final \<equiv> \<Lambda> n. fib_work_final !! n"

text{* This proof is only fiddly due to the way mutual recursion is
encoded: we need to use Beki\'{c}'s Theorem
\citep{Bekic:1969}\footnote{The interested reader can find some
historical commentary in \citet{Harel:1980, Sangiorgi:2007}.} to
massage the definitions into their final form. *}

lemma fib_work_final_fib_work_eq: "fib_work_final = fib_work" (is "?lhs = ?rhs")
proof -
  let ?wb = "\<Lambda> r. Nat_case\<cdot>1\<cdot>(Nat_case\<cdot>1\<cdot>(\<Lambda> n'. r !! n' + r !! (n' + 1)))"
  let ?mr = "\<Lambda> \<langle>fwf :: Nat Stream, fff\<rangle>. \<langle>smap\<cdot>fff\<cdot>nats, ?wb\<cdot>fwf\<rangle>"
  have "?lhs = cfst\<cdot>(fix\<cdot>?mr)"
    by (simp add: fib_work_final_def split_def csplit_def cfst_def csnd_def cpair_def)
  also have "\<dots> = (\<mu> fwf. cfst\<cdot>(?mr\<cdot>\<langle>fwf, \<mu> fff. csnd\<cdot>(?mr\<cdot>\<langle>fwf, fff\<rangle>)\<rangle>))"
    using fix_cprod[where F="?mr"] by simp
  also have "\<dots> = (\<mu> fwf. smap\<cdot>(\<mu> fff. ?wb\<cdot>fwf)\<cdot>nats)" by simp
  also have "\<dots> = (\<mu> fwf. smap\<cdot>(?wb\<cdot>fwf)\<cdot>nats)" by (simp add: fix_const)
  also have "\<dots> = ?rhs"
    unfolding fib_body_def fib_work_def unwrapS_unwrapS'_eq unwrapS'_def wrapS_def
    by (simp add: cfcomp1)
  finally show ?thesis .
qed

lemma fib_final_fib_eq: "fib_final = fib" (is "?lhs = ?rhs")
proof -
  have "?lhs = (\<Lambda> n. fib_work_final !! n)" by (simp add: fib_final_def)
  also have "\<dots> = (\<Lambda> n. fib_work !! n)" by (simp only: fib_work_final_fib_work_eq)
  also have "\<dots> = fib_wrap" by (simp add: fib_wrap_def wrapS_def)
  also have "\<dots> = ?rhs" by (simp only: fib_ww_eq)
  finally show ?thesis .
qed

(*<*)
end
(*>*)
