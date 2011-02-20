theory Test
imports "~~/src/HOL/Library/Efficient_Nat" BinomialHeap SkewBinomialHeap
begin
  text {*
    This theory is included into teh session, in order to
    catch problems with code generation.
    *}


definition
  sh_empty :: "unit \<Rightarrow> ('a,nat) SkewBinomialHeap"
  where "sh_empty u \<equiv> SkewBinomialHeap.empty"
definition
  sh_findMin :: "('a,nat) SkewBinomialHeap \<Rightarrow> _"
  where "sh_findMin \<equiv> SkewBinomialHeap.findMin"
definition
  sh_deleteMin :: "('a,nat) SkewBinomialHeap \<Rightarrow> ('a,nat) SkewBinomialHeap"
  where "sh_deleteMin \<equiv> SkewBinomialHeap.deleteMin"
definition
  sh_insert :: "_ \<Rightarrow> nat \<Rightarrow> _ \<Rightarrow> _"
  where "sh_insert \<equiv> SkewBinomialHeap.insert"
definition
  sh_meld :: "('a,nat) SkewBinomialHeap \<Rightarrow> _"
  where "sh_meld \<equiv> SkewBinomialHeap.meld"

definition
  bh_empty :: "unit \<Rightarrow> ('a,nat) BinomialHeap"
  where "bh_empty u \<equiv> BinomialHeap.empty"
definition
  bh_findMin :: "('a,nat) BinomialHeap \<Rightarrow> _"
  where "bh_findMin \<equiv> BinomialHeap.findMin"
definition
  bh_deleteMin :: "('a,nat) BinomialHeap \<Rightarrow> ('a,nat) BinomialHeap"
  where "bh_deleteMin \<equiv> BinomialHeap.deleteMin"
definition
  bh_insert :: "_ \<Rightarrow> nat \<Rightarrow> _ \<Rightarrow> _"
  where "bh_insert \<equiv> BinomialHeap.insert"
definition
  bh_meld :: "('a,nat) BinomialHeap \<Rightarrow> _"
  where "bh_meld \<equiv> BinomialHeap.meld"

export_code 
  sh_empty
  sh_findMin
  sh_deleteMin
  sh_insert
  sh_meld

  bh_empty
  bh_findMin
  bh_deleteMin
  bh_insert
  bh_meld
  in Haskell file -
  in OCaml file -
  in SML file -

ML {*
  (* ** Binomial Heaps ** *)

  val q1 = @{code bh_insert} "a" 1 (@{code bh_insert} "b" 2 (@{code bh_empty} ()));
  val q2 = @{code bh_insert} "c" 3 (@{code bh_insert} "d" 4 (@{code bh_empty} ()));

  val q = @{code bh_meld} q1 q2;
  @{code bh_findMin} q;

  val q = @{code bh_deleteMin} q;
  @{code bh_findMin} q;


  (* ** Skew Binomial Heaps ** *)
  val q1 = @{code sh_insert} "a" 1 (@{code sh_insert} "b" 2 (@{code sh_empty} ()));
  val q2 = @{code sh_insert} "c" 3 (@{code sh_insert} "d" 4 (@{code sh_empty} ()));

  val q = @{code sh_meld} q1 q2;
  @{code sh_findMin} q;

  val q = @{code sh_deleteMin} q;
  @{code sh_findMin} q;
*}

end
