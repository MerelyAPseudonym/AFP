(*  Title:       Conflict analysis/Acquisition histories
    Author:      Peter Lammich <peter.lammich@uni-muenster.de>
    Maintainer:  Peter Lammich <peter.lammich@uni-muenster.de>
*)
header "Acquisition Histories"
theory AcquisitionHistory
imports ConsInterleave
begin
text_raw {*\label{thy:AcquisitionHistory}*}

text {* The concept of {\em acquisition histories} was introduced by Kahlon, Ivancic, and Gupta \cite{KIG05} as a bounded size abstraction of executions that acquire and release locks that contains enough information
  to decide consistent interleavability. In this work, we use this concept for reentrant monitors.
  As in Section~\ref{thy:ConsInterleave}, we encode monitor usage information in pairs of sets of monitors, and regard lists of such pairs as (abstract) executions.
  An item @{term "(E,U)"} of such a list describes a sequence of steps of the concrete execution that first enters the monitors in @{term E} and then passes through the monitors in @{term U}. The monitors in @{term E} are
  never left by the execution. Note that due to the syntactic binding of monitors to the program structure, any execution of a single thread can be abstracted to a sequence of @{term "(E,U)"}-pairs. 
  Restricting the possible schedules (see Section \ref{thy:Normalization}) will allow us to also abstract executions reaching a single program point to a sequence of such pairs.

  We want to decide whether two executions are interleavable. The key observation of \cite{KIG05} is, that two executions @{term "e"} and @{term "e'"} are {\em not} interleavable if and only if 
  there is a conflicting pair @{term "(m,m')"} of monitors, such that @{term e} enters (and never leaves) @{term m} and then uses @{term m'} and @{term e'} enters (and never leaves) @{term m'} and then uses @{term m}.  

  An acquisition history is a map from monitors to set of monitors. The acquisition history of an execution maps a monitor @{term m} that is allocated at the end of the execution to all monitors that are used after or in the 
  same step that finally enters @{term m}. Monitors that are not allocated at the end of an execution are mapped to the empty set. Though originally used for a setting without reentrant monitors, acquisition histories also work
  for our setting with reentrant monitors. 

  This theory contains the definition of acquisition histories and acquisition history interleavability, an ordering on acquisition histories that reflects the blocking potential of acquisition histories, 
  and a mapping function from paths to acquisition histories that is shown to be compatible with monitor consistent interleaving.  *}

subsection "Definitions"
text {* Acquisition histories are modeled as functions from monitors to sets of monitors. Intuitively @{term "m'\<in>h m"} models that an execution finally is in @{term m}, and monitor @{term m'} has been used (i.e. passed or entered)
  after or at the same time @{term m} has been finally entered. By convention, we have @{term "m\<in>h m"} or @{term "h m = {}"}.
*}

  (* TODO: Make acquisition histories an own type, with access and update operator of sort order  *)
definition "ah == { (h::'m \<Rightarrow> 'm set) . \<forall> m. h m = {} \<or> m\<in>h m }"

lemma ah_cases[cases set]: "\<lbrakk>h\<in>ah; h m = {} \<Longrightarrow> P ; m \<in> h m \<Longrightarrow> P\<rbrakk> \<Longrightarrow> P"
  by (unfold ah_def) blast

subsection "Interleavability"
text {* Two acquisition histories @{term h1} and @{term h2} are considered interleavable, iff there is no conflicting pair of monitors @{term m1} and @{term m2}, 
  where a pair of monitors @{term m1} and @{term m2} is called {\em conflicting} iff @{term m1} is used in @{term h2} after entering @{term m2} and, vice versa, @{term m2} is used in @{term h1} after entering @{term m1}. *}  
definition
  ah_il :: "('m \<Rightarrow> 'm set) \<Rightarrow> ('m \<Rightarrow> 'm set) \<Rightarrow> bool" (infix "[*]" 65) 
  where
  "h1 [*] h2 == \<not>(\<exists>m1 m2. m1\<in>h2 m2 \<and> m2 \<in> h1 m1)"

text {* From our convention, it follows (as expected) that the sets of entered monitors (lock-sets) of two interleavable acquisition histories are disjoint *}
lemma ah_il_lockset_disjoint: 
  "\<lbrakk> h1\<in>ah; h2\<in>ah; h1 [*] h2 \<rbrakk> \<Longrightarrow> h1 m = {} \<or> h2 m = {}"
  by (unfold ah_il_def) (auto elim: ah_cases)    

text {* Of course, acquisition history interleavability is commutative *}
lemma ah_il_commute: "h1 [*] h2 \<Longrightarrow> h2 [*] h1"
  by (unfold ah_il_def) auto

subsection "Used monitors"
text {* Let's define the monitors of an acquisition history, as all monitors that occur in the acquisition history *}
definition 
  mon_ah :: "('m \<Rightarrow> 'm set) \<Rightarrow> 'm set"
  where
  "mon_ah h == \<Union>{ h(m) | m. True}"


subsection "Ordering"
text {* The element-wise subset-ordering on acquisition histories intuitively reflects the blocking potential: The bigger the acquisition history, the fewer acquisition histories are interleavable with it.*}
text {* Note that the Isabelle standard library automatically lifts the subset ordering to functions, so we need no explicit definition here. *}
  
-- {* The ordering is compatible with interleavability, i.e.\ smaller acquisition histories are more likely to be interleavable. *}
lemma ah_leq_il: "\<lbrakk> h1 [*] h2; h1' \<le> h1; h2' \<le> h2 \<rbrakk> \<Longrightarrow> h1' [*] h2'"
  by (unfold ah_il_def le_fun_def [where 'b="'a \<Rightarrow> bool"]) blast+
lemma ah_leq_il_left: "\<lbrakk> h1 [*] h2; h1' \<le> h1 \<rbrakk> \<Longrightarrow> h1' [*] h2" and 
      ah_leq_il_right: "\<lbrakk> h1 [*] h2; h2' \<le> h2 \<rbrakk> \<Longrightarrow> h1 [*] h2'"
  by (unfold ah_il_def le_fun_def [where 'b="'a \<Rightarrow> bool"]) blast+

subsection "Acquisition histories of executions"
text {* Next we define a function that abstracts from executions (lists of enter/use pairs) to acquisition histories *}
consts \<alpha>ah :: "('m set \<times> 'm set) list \<Rightarrow> 'm \<Rightarrow> 'm set"
primrec 
  "\<alpha>ah [] m = {}"
  "\<alpha>ah (e#w) m = (if m\<in>fst e then fst e \<union> snd e \<union> mon_pl w else \<alpha>ah w m)"

-- {* @{term \<alpha>ah} generates valid acquisition histories *}
lemma \<alpha>ah_ah: "\<alpha>ah w \<in> ah"
  apply (induct rule: \<alpha>ah.induct)
  apply (unfold ah_def)
  apply simp
  apply (fastsimp split: split_if_asm)
  done

lemma \<alpha>ah_hd: "\<lbrakk>m\<in>fst e; x\<in>fst e \<union> snd e \<union> mon_pl w\<rbrakk> \<Longrightarrow> x\<in>\<alpha>ah (e#w) m"
  by auto
lemma \<alpha>ah_tl: "\<lbrakk>m\<notin>fst e; x\<in>\<alpha>ah w m\<rbrakk> \<Longrightarrow> x\<in>\<alpha>ah (e#w) m"
  by auto

lemma \<alpha>ah_cases[cases set, case_names hd tl]: "\<lbrakk>
    x\<in>\<alpha>ah w m; 
    !!e w'. \<lbrakk>w=e#w'; m\<in>fst e; x\<in>fst e \<union> snd e \<union> mon_pl w'\<rbrakk> \<Longrightarrow> P; 
    !!e w'. \<lbrakk>w=e#w'; m\<notin>fst e; x\<in>\<alpha>ah w' m\<rbrakk> \<Longrightarrow> P
  \<rbrakk> \<Longrightarrow> P"
  by (cases w) (simp_all split: split_if_asm, blast+)

lemma \<alpha>ah_cons_cases[cases set, case_names hd tl]: "\<lbrakk>
    x\<in>\<alpha>ah (e#w') m;  
    \<lbrakk>m\<in>fst e; x\<in>fst e \<union> snd e \<union> mon_pl w'\<rbrakk> \<Longrightarrow> P; 
    \<lbrakk>m\<notin>fst e; x\<in>\<alpha>ah w' m\<rbrakk> \<Longrightarrow> P
  \<rbrakk> \<Longrightarrow> P"
  by (simp_all split: split_if_asm)

lemma mon_ah_subset: "mon_ah (\<alpha>ah w) \<subseteq> mon_pl w"
  by (induct w) (auto simp add: mon_ah_def)

-- {* Subwords generate smaller acquisition histories *}
lemma \<alpha>ah_ileq: "w1\<preceq>w2 \<Longrightarrow> \<alpha>ah w1 \<le> \<alpha>ah w2" 
proof (induct rule: less_eq_list.induct)
  case empty thus ?case by (unfold le_fun_def [where 'b="'a \<Rightarrow> bool"], simp)
next
  case (drop l' l a) show ?case
  proof (unfold le_fun_def  [where 'b="'a \<Rightarrow> bool"], intro allI subsetI)
    fix m x
    assume A: "x \<in> \<alpha>ah l' m"
    with drop(2) have "x\<in>\<alpha>ah l m" by (unfold le_fun_def  [where 'b="'a \<Rightarrow> bool"], auto)
    moreover hence "x\<in>mon_pl l" using mon_ah_subset[unfolded mon_ah_def] by fast
    ultimately show "x\<in>\<alpha>ah (a # l) m" by auto
  qed
next
  case (take l' l a) show ?case
  proof (unfold le_fun_def [where 'b="'a \<Rightarrow> bool"], intro allI subsetI)
    fix m x
    assume A: "x\<in>\<alpha>ah (a#l') m"
    thus "x \<in> \<alpha>ah (a # l) m" proof (cases rule: \<alpha>ah_cons_cases)
      case hd with mon_pl_ileq[OF take.hyps(1)] show ?thesis by auto
    next
      case tl with take.hyps(2)[unfolded le_fun_def [where 'b="'a \<Rightarrow> bool"]] show ?thesis by auto
    qed
  qed
qed
      
text {* We can now prove the relation of monitor consistent interleavability and interleavability of the acquisition histories. *}
lemma ah_interleavable1: 
  "w \<in> w1 \<otimes>\<^bsub>\<alpha>\<^esub> w2 \<Longrightarrow> \<alpha>ah (map \<alpha> w1) [*] \<alpha>ah (map \<alpha> w2)" 
  -- "The lemma is shown by induction on the structure of the monitor consistent interleaving operator"
proof (induct w \<alpha> w1 w2 rule: cil_set_induct_fix\<alpha>) 
  case empty show ?case by (simp add: ah_il_def) -- {* The base case is trivial by the definition of @{term "op [*]"} *}
next
  -- "Case: First step comes from the left word"
  case (left e w' w1' w2) show ?case 
  proof (rule ccontr) -- "We do a proof by contradiction"
    -- "Assume there is a conflicting pair in the acquisition histories"
    assume "\<not> \<alpha>ah (map \<alpha> (e # w1')) [*] \<alpha>ah (map \<alpha> w2)" 
    then obtain m1 m2 where CPAIR: "m1 \<in> \<alpha>ah (map \<alpha> (e#w1')) m2" "m2 \<in> \<alpha>ah (map \<alpha> w2) m1" by (unfold ah_il_def, blast) 
    -- "It comes either from the first step or not"
    from CPAIR(1) have "(m2\<in>fst (\<alpha> e) \<and> m1 \<in> fst (\<alpha> e) \<union> snd (\<alpha> e) \<union> mon_pl (map \<alpha> w1')) \<or> (m2\<notin>fst (\<alpha> e) \<and> m1 \<in> \<alpha>ah (map \<alpha> w1') m2)" (is "?CASE1 \<or> ?CASE2") 
      by (auto split: split_if_asm) 
    moreover {
      -- "Case: One monitor of the conflicting pair is entered in the first step of the left path"
      assume ?CASE1 hence C: "m2\<in>fst (\<alpha> e)" .. 
      -- "Because the paths are consistently interleavable, the monitors entered in the first step must not occur in the other path"
      from left(2) mon_ah_subset[of "map \<alpha> w2"] have "fst (\<alpha> e) \<inter> mon_ah (\<alpha>ah (map \<alpha> w2)) = {}" by auto 
      -- "But this is a contradiction to being a conflicting pair"
      with C CPAIR(2) have False by (unfold mon_ah_def, blast) 
    } moreover {
      -- "Case: The first monitor of the conflicting pair is entered after the first step of the left path"
      assume ?CASE2 hence C: "m1 \<in> \<alpha>ah (map \<alpha> w1') m2" .. 
      -- "But this is a contradiction to the induction hypothesis, that says that the acquisition histories of the tail of the left path and the 
        right path are interleavable"
      with left(3) CPAIR(2) have False by (unfold ah_il_def, blast) 
    } ultimately show False ..
  qed
next
  -- "Case: First step comes from the right word. This case is shown completely analogous"
  case (right e w' w2' w1) show ?case 
  proof (rule ccontr)
    assume "\<not> \<alpha>ah (map \<alpha> w1) [*] \<alpha>ah (map \<alpha> (e#w2'))" 
    then obtain m1 m2 where CPAIR: "m1 \<in> \<alpha>ah (map \<alpha> w1) m2" "m2 \<in> \<alpha>ah (map \<alpha> (e#w2')) m1" by (unfold ah_il_def, blast) 
    from CPAIR(2) have "(m1\<in>fst (\<alpha> e) \<and> m2 \<in> fst (\<alpha> e) \<union> snd (\<alpha> e) \<union> mon_pl (map \<alpha> w2')) \<or> (m1\<notin>fst (\<alpha> e) \<and> m2 \<in> \<alpha>ah (map \<alpha> w2') m1)" (is "?CASE1 \<or> ?CASE2") 
      by (auto split: split_if_asm)
    moreover {
      assume ?CASE1 hence C: "m1\<in>fst (\<alpha> e)" .. 
      from right(2) mon_ah_subset[of "map \<alpha> w1"] have "fst (\<alpha> e) \<inter> mon_ah (\<alpha>ah (map \<alpha> w1)) = {}" by auto 
      with C CPAIR(1) have False by (unfold mon_ah_def, blast) 
    } moreover {
      assume ?CASE2 hence C: "m2 \<in> \<alpha>ah (map \<alpha> w2') m1" .. 
      with right(3) CPAIR(1) have False by (unfold ah_il_def, blast) 
    } ultimately show False ..
  qed
qed


lemma ah_interleavable2: 
  assumes A: "\<alpha>ah (map \<alpha> w1) [*] \<alpha>ah (map \<alpha> w2)" 
  shows "w1 \<otimes>\<^bsub>\<alpha>\<^esub> w2 \<noteq> {}"
  -- "This lemma is shown by induction on the sum of the word lengths"
proof -
  -- "To apply this induction in Isabelle, we have to rewrite the lemma a bit"
  { fix n
    have "!!w1 w2. \<lbrakk>\<alpha>ah (map \<alpha> w1) [*] \<alpha>ah (map \<alpha> w2); n=length w1 + length w2\<rbrakk> \<Longrightarrow> w1 \<otimes>\<^bsub>\<alpha>\<^esub> w2 \<noteq> {}" 
    proof (induct n rule: nat_less_induct[case_names I])
      -- "We first rule out the cases that one of the words is empty"
      case (I n w1 w2) show ?case proof (cases w1) 
        -- "If the first word is empty, the lemma is trivial"
        case Nil with I.prems show ?thesis by simp 
      next
        case (Cons e1 w1') note CONS1=this show ?thesis proof (cases w2)
          -- "If the second word is empty, the lemma is also trivial"
          case Nil with I.prems show ?thesis by simp 
        next
          -- "The interesting case is if both words are not empty"
          case (Cons e2 w2') note CONS2=this 
          -- {* In this case, we check whether the first step of one of the words can safely be executed without blocking any steps of the other word *}
          show ?thesis proof (cases "fst (\<alpha> e1) \<inter> mon_pl (map \<alpha> w2) = {}")
            case True -- "The first step of the first word can safely be executed"
            -- "From the induction hypothesis, we get that there is a consistent interleaving of the rest of the first word and the second word"
            have "w1'\<otimes>\<^bsub>\<alpha>\<^esub>w2 \<noteq> {}" proof -
              from I.prems(1) CONS1 ah_leq_il_left[OF _ \<alpha>ah_ileq[OF le_list_map, OF less_eq_list.drop[OF order_refl]]] have "\<alpha>ah (map \<alpha> w1') [*] \<alpha>ah (map \<alpha> w2)" by fast
              moreover from CONS1 I.prems(2) have "length w1'+length w2 < n" by simp
              ultimately show ?thesis using I.hyps by blast
            qed
            -- "And because the first step of the first word can be safely executed, we can prepend it to that consistent interleaving"
            with cil_cons1[OF _ True] CONS1 show ?thesis by blast
          next
            case False note C1=this
            show ?thesis proof (cases "fst (\<alpha> e2) \<inter> mon_pl (map \<alpha> w1) = {}")
              case True -- "The first step of the second word can safely be executed"
              -- "This case is shown analogously to the latter one"
              have "w1\<otimes>\<^bsub>\<alpha>\<^esub>w2' \<noteq> {}" proof -
                from I.prems(1) CONS2 ah_leq_il_right[OF _ \<alpha>ah_ileq[OF le_list_map, OF less_eq_list.drop[OF order_refl]]] have "\<alpha>ah (map \<alpha> w1) [*] \<alpha>ah (map \<alpha> w2')" by fast
                moreover from CONS2 I.prems(2) have "length w1+length w2' < n" by simp
                ultimately show ?thesis using I.hyps by blast
              qed
              with cil_cons2[OF _ True] CONS2 show ?thesis by blast
            next
              case False note C2=this -- "Neither first step can safely be executed. This is exactly the situation from that we can extract a conflicting pair"
              from C1 C2 obtain m1 m2 where "m1\<in>fst (\<alpha> e1)" "m1\<in>mon_pl (map \<alpha> w2)" "m2\<in>fst (\<alpha> e2)" "m2\<in>mon_pl (map \<alpha> w1)" by blast
              with CONS1 CONS2 have "m2 \<in> \<alpha>ah (map \<alpha> w1) m1" "m1 \<in> \<alpha>ah (map \<alpha> w2) m2" by auto
              -- "But by assumption, there are no conflicting pairs, thus we get a contradiction"
              with I.prems(1) have False by (unfold ah_il_def) blast 
              thus ?thesis ..
            qed
          qed
        qed
      qed
    qed
  } with A show ?thesis by blast
qed
              
  
text {* Finally, we can state the relationship between monitor consistent interleaving and interleaving of acquisition histories *}
theorem ah_interleavable: 
  "(\<alpha>ah (map \<alpha> w1) [*] \<alpha>ah (map \<alpha> w2)) \<longleftrightarrow> (w1\<otimes>\<^bsub>\<alpha>\<^esub>w2\<noteq>{})" 
  using ah_interleavable1 ah_interleavable2 by blast

subsection "Acquisition history backward update"
text {* We define a function to update an acquisition history backwards. This function is useful for constructing acquisition histories in backward constraint systems. *}
definition
  ah_update :: "('m \<Rightarrow> 'm set) \<Rightarrow> ('m set * 'm set) \<Rightarrow> 'm set \<Rightarrow> ('m \<Rightarrow> 'm set)"
  where
  "ah_update h F M m == if m\<in>fst F then fst F \<union> snd F \<union> M else h m"

text {*
  Intuitively, @{term "ah_update h (E,U) M m"} means to prepend a step @{term "(E,U)"} to the acquisition history @{term h} of a path that uses monitors @{term M}. Note that we need the extra parameter @{term M}, since
  an acquisition history does not contain information about the monitors that are used on a path before the first monitor that will not be left has been entered. 
*}
lemma ah_update_cons: "\<alpha>ah (e#w) = ah_update (\<alpha>ah w) e (mon_pl w)"
  by (auto intro!: ext simp add: ah_update_def)

text {* The backward-update function is monotonic in the first and third argument as well as in the used monitors of the second argument. 
  Note that it is, in general, not monotonic in the entered monitors of the second argument. *}
lemma ah_update_mono: "\<lbrakk>h \<le> h'; F=F'; M\<subseteq>M'\<rbrakk> 
  \<Longrightarrow> ah_update h F M \<le> ah_update h' F' M'"
  by (auto simp add: ah_update_def le_fun_def [where 'b="'a \<Rightarrow> bool"])
lemma ah_update_mono2: "\<lbrakk>h \<le> h'; U\<subseteq>U'; M\<subseteq>M'\<rbrakk> 
  \<Longrightarrow> ah_update h (E,U) M \<le> ah_update h' (E,U') M'"
  by (auto simp add: ah_update_def le_fun_def [where 'b="'a \<Rightarrow> bool"])

end
