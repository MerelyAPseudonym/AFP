header {* General purpose definitions and lemmas *}

theory Misc imports 
  Main
begin

text {* A handy abbreviation when working with maps *}
abbreviation make_map :: "'a set \<Rightarrow> 'b \<Rightarrow> ('a \<rightharpoonup> 'b)" ("[ _ |=> _ ]")
where
  "[ks |=> v] \<equiv> \<lambda>k. if k \<in> ks then Some v else None"

text {* Projecting the components of a triple *}
definition "fst3 \<equiv> fst"
definition "snd3 \<equiv> fst \<circ> snd"
definition "thd3 \<equiv> snd \<circ> snd"

lemma fst3_simp [simp]: "fst3 (a,b,c) = a" by (simp add: fst3_def)
lemma snd3_simp [simp]: "snd3 (a,b,c) = b" by (simp add: snd3_def)
lemma thd3_simp [simp]: "thd3 (a,b,c) = c" by (simp add: thd3_def)

end
