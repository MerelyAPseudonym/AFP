header {* \isaheader{Auxiliary lemmas} *}

theory AuxLemmas imports Main begin

text {* Lemma concerning maps and @{text @} *}

lemma map_append_append_maps:
  assumes map:"map f xs = ys@zs"
  obtains xs' xs'' where "map f xs' = ys" and "map f xs'' = zs" and "xs=xs'@xs''"
by (metis append_eq_conv_conj append_take_drop_id assms drop_map take_map that)


text {* Lemma concerning splitting of @{term list}s *}

lemma  path_split_general:
assumes all:"\<forall>zs. xs \<noteq> ys@zs"
obtains j zs where "xs = (take j ys)@zs" and "j < length ys"
  and "\<forall>k > j. \<forall>zs'. xs \<noteq> (take k ys)@zs'"
proof(atomize_elim)
  from `\<forall>zs. xs \<noteq> ys@zs`
  show "\<exists>j zs. xs = take j ys @ zs \<and> j < length ys \<and> 
               (\<forall>k>j. \<forall>zs'. xs \<noteq> take k ys @ zs')"
  proof(induct ys arbitrary:xs)
    case Nil thus ?case by auto
  next
    case (Cons y' ys')
    note IH = `\<And>xs. \<forall>zs. xs \<noteq> ys' @ zs \<Longrightarrow>
      \<exists>j zs. xs = take j ys' @ zs \<and> j < length ys' \<and> 
      (\<forall>k. j < k \<longrightarrow> (\<forall>zs'. xs \<noteq> take k ys' @ zs'))`
    show ?case
    proof(cases xs)
      case Nil thus ?thesis by simp
    next
      case (Cons x' xs')
      with `\<forall>zs. xs \<noteq> (y' # ys') @ zs` have "x' \<noteq> y' \<or> (\<forall>zs. xs' \<noteq> ys' @ zs)"
        by simp
      show ?thesis
      proof(cases "x' = y'")
        case True
        with `x' \<noteq> y' \<or> (\<forall>zs. xs' \<noteq> ys' @ zs)` have "\<forall>zs. xs' \<noteq> ys' @ zs" by simp
        from IH[OF this] have "\<exists>j zs. xs' = take j ys' @ zs \<and> j < length ys' \<and>
          (\<forall>k. j < k \<longrightarrow> (\<forall>zs'. xs' \<noteq> take k ys' @ zs'))" .
        then obtain j zs where "xs' = take j ys' @ zs"
          and "j < length ys'"
          and all_sub:"\<forall>k. j < k \<longrightarrow> (\<forall>zs'. xs' \<noteq> take k ys' @ zs')"
          by blast
        from `xs' = take j ys' @ zs` True
          have "(x'#xs') = take (Suc j) (y' # ys') @ zs"
          by simp
        from all_sub True have all_imp:"\<forall>k. j < k \<longrightarrow> 
          (\<forall>zs'. (x'#xs') \<noteq> take (Suc k) (y' # ys') @ zs')"
          by auto
        { fix l assume "(Suc j) < l"
          then obtain k where [simp]:"l = Suc k" by(cases l) auto
          with `(Suc j) < l` have "j < k" by simp
          with all_imp 
          have "\<forall>zs'. (x'#xs') \<noteq> take (Suc k) (y' # ys') @ zs'"
            by simp
          hence "\<forall>zs'. (x'#xs') \<noteq> take l (y' # ys') @ zs'"
            by simp }
        with `(x'#xs') = take (Suc j) (y' # ys') @ zs` `j < length ys'` Cons
        show ?thesis by (metis Suc_length_conv less_Suc_eq_0_disj)
      next
        case False
        with Cons have "\<forall>i zs'. i > 0 \<longrightarrow> xs \<noteq> take i (y' # ys') @ zs'"
          by auto(case_tac i,auto)
        moreover
        have "\<exists>zs. xs = take 0 (y' # ys') @ zs" by simp
        ultimately show ?thesis by(rule_tac x="0" in exI,auto)
      qed
    qed
  qed
qed


end
