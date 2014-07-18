header {* \isaheader{Lemmas for the control dependences} *}

theory AdditionalLemmas imports WellFormed
begin

subsection {* Paths to @{term "(_Exit_)"} and from @{term "(_Entry_)"} exist *}

abbreviation path :: "cmd \<Rightarrow> w_node \<Rightarrow> w_edge list \<Rightarrow> w_node \<Rightarrow> bool" 
("_ \<turnstile> _ -_\<rightarrow>* _")
  where "prog \<turnstile> n -as\<rightarrow>* n' \<equiv> CFG.path sourcenode targetnode (valid_edge prog) 
    n as n'"

definition label_incrs :: "w_edge list \<Rightarrow> nat \<Rightarrow> w_edge list" ("_ \<oplus>s _" 60)
  where "as \<oplus>s i \<equiv> map (\<lambda>(n,et,n'). (n \<oplus> i,et,n' \<oplus> i)) as"


lemma path_SeqFirst:
  "prog \<turnstile> n -as\<rightarrow>* (_ l _) \<Longrightarrow> prog;;c\<^sub>2 \<turnstile> n -as\<rightarrow>* (_ l _)"
proof(induct n as "(_ l _)" arbitrary:l rule:While_CFG.path.induct)
  case empty_path
  from `CFG.valid_node sourcenode targetnode (valid_edge prog) (_ l _)`
  show ?case
    apply -
    apply(rule While_CFG.empty_path)
    apply(auto simp:While_CFG.valid_node_def valid_edge_def)
    by(case_tac b,auto dest:WCFG_SeqFirst WCFG_SeqConnect)
next
  case (Cons_path n'' as a n)
  note IH = `prog;; c\<^sub>2 \<turnstile> n'' -as\<rightarrow>* (_ l _)`
  from `prog \<turnstile> n'' -as\<rightarrow>* (_ l _)` have "n'' \<noteq> (_Exit_)"
    by fastforce
  with `valid_edge prog a` `sourcenode a = n` `targetnode a = n''`
  have "prog;;c\<^sub>2 \<turnstile> n -kind a\<rightarrow> n''" by(simp add:valid_edge_def WCFG_SeqFirst)
  with IH `prog;;c\<^sub>2 \<turnstile> n -kind a\<rightarrow> n''` `sourcenode a = n` `targetnode a = n''` show ?case
    by(fastforce intro:While_CFG.Cons_path simp:valid_edge_def)
qed


lemma path_SeqSecond:
  "\<lbrakk>prog \<turnstile> n -as\<rightarrow>* n'; n \<noteq> (_Entry_); as \<noteq> []\<rbrakk> 
  \<Longrightarrow> c\<^sub>1;;prog \<turnstile> n \<oplus> #:c\<^sub>1 -as \<oplus>s #:c\<^sub>1\<rightarrow>* n' \<oplus> #:c\<^sub>1"
proof(induct rule:While_CFG.path.induct)
  case (Cons_path n'' as n' a n)
  note IH = ` \<lbrakk>n'' \<noteq> (_Entry_); as \<noteq> []\<rbrakk> 
    \<Longrightarrow> c\<^sub>1;;prog \<turnstile> n'' \<oplus> #:c\<^sub>1 -as \<oplus>s #:c\<^sub>1\<rightarrow>* n' \<oplus> #:c\<^sub>1`
  from `valid_edge prog a` `sourcenode a = n` `targetnode a = n''` `n \<noteq> (_Entry_)`
  have "c\<^sub>1;;prog \<turnstile> n \<oplus> #:c\<^sub>1 -kind a\<rightarrow> n'' \<oplus> #:c\<^sub>1"
    by(simp add:valid_edge_def WCFG_SeqSecond)
  from `sourcenode a = n` `targetnode a = n''` `valid_edge prog a`
  have "[(n,kind a,n'')] \<oplus>s #:c\<^sub>1 = [a] \<oplus>s #:c\<^sub>1"
    by(cases a,simp add:label_incrs_def valid_edge_def)
  show ?case
  proof(cases "as = []")
    case True
    with `prog \<turnstile> n'' -as\<rightarrow>* n'` have [simp]:"n'' = n'" by(auto elim:While_CFG.cases)
    with `c\<^sub>1;;prog \<turnstile> n \<oplus> #:c\<^sub>1 -kind a\<rightarrow> n'' \<oplus> #:c\<^sub>1`
    have "c\<^sub>1;;prog \<turnstile> n \<oplus> #:c\<^sub>1 -[(n,kind a,n')] \<oplus>s #:c\<^sub>1\<rightarrow>* n' \<oplus> #:c\<^sub>1"
      by(fastforce intro:While_CFG.Cons_path While_CFG.empty_path
                  simp:label_incrs_def While_CFG.valid_node_def valid_edge_def)
    with True `[(n,kind a,n'')] \<oplus>s #:c\<^sub>1 = [a] \<oplus>s #:c\<^sub>1` show ?thesis by simp
  next
    case False
    from `valid_edge prog a` `targetnode a = n''` have "n'' \<noteq> (_Entry_)"
      by(cases n'',auto simp:valid_edge_def)
    from IH[OF this False] 
    have "c\<^sub>1;;prog \<turnstile> n'' \<oplus> #:c\<^sub>1 -as \<oplus>s #:c\<^sub>1\<rightarrow>* n' \<oplus> #:c\<^sub>1" .
    with `c\<^sub>1;;prog \<turnstile> n \<oplus> #:c\<^sub>1 -kind a\<rightarrow> n'' \<oplus> #:c\<^sub>1` `sourcenode a = n`
      `targetnode a = n''` `[(n,kind a,n'')] \<oplus>s #:c\<^sub>1 = [a] \<oplus>s #:c\<^sub>1` show ?thesis
      apply(cases a)
      apply(simp add:label_incrs_def)
      by(fastforce intro:While_CFG.Cons_path simp:valid_edge_def)
  qed
qed simp


lemma path_CondTrue:
  "prog \<turnstile> (_ l _) -as\<rightarrow>* n' 
  \<Longrightarrow> if (b) prog else c\<^sub>2 \<turnstile> (_ l _) \<oplus> 1 -as \<oplus>s 1\<rightarrow>* n' \<oplus> 1"
proof(induct "(_ l _)" as n' arbitrary:l rule:While_CFG.path.induct)
  case empty_path
  from `CFG.valid_node sourcenode targetnode (valid_edge prog) (_ l _)` 
    WCFG_CondTrue[of b prog c\<^sub>2]
  have "CFG.valid_node sourcenode targetnode (valid_edge (if (b) prog else c\<^sub>2)) 
    ((_ l _) \<oplus> 1)"
    apply(auto simp:While_CFG.valid_node_def valid_edge_def)
    apply(rotate_tac 1,drule WCFG_CondThen,simp,fastforce)
    apply(case_tac a) apply auto
     apply(rotate_tac 1,drule WCFG_CondThen,simp,fastforce)
    by(rotate_tac 1,drule WCFG_EntryD,auto)
  then show ?case
    by(fastforce intro:While_CFG.empty_path simp:label_incrs_def)
next
  case (Cons_path n'' as n' a)
  note IH = `\<And>l. n'' = (_ l _) 
    \<Longrightarrow> if (b) prog else c\<^sub>2 \<turnstile> (_ l _) \<oplus> 1 -as \<oplus>s 1\<rightarrow>* n' \<oplus> 1`
  from `valid_edge prog a` `sourcenode a = (_ l _)`  `targetnode a = n''`
  have "if (b) prog else c\<^sub>2 \<turnstile> (_ l _) \<oplus> 1 -kind a\<rightarrow> n'' \<oplus> 1"
    by -(rule WCFG_CondThen,simp_all add:valid_edge_def)
  from `sourcenode a = (_ l _)` `targetnode a = n''` `valid_edge prog a`
  have "[((_ l _),kind a,n'')] \<oplus>s 1 = [a] \<oplus>s 1"
    by(cases a,simp add:label_incrs_def valid_edge_def)
  show ?case
  proof(cases n'')
    case (Node l')
    from IH[OF this] have "if (b) prog else c\<^sub>2 \<turnstile> (_ l' _) \<oplus> 1 -as \<oplus>s 1\<rightarrow>* n' \<oplus> 1" .
    with `if (b) prog else c\<^sub>2 \<turnstile> (_ l _) \<oplus> 1 -kind a\<rightarrow> n'' \<oplus> 1` Node
    have "if (b) prog else c\<^sub>2 \<turnstile> (_ l _) \<oplus> 1 -((_ l _) \<oplus> 1,kind a,n'' \<oplus> 1)#(as \<oplus>s 1)\<rightarrow>* n' \<oplus> 1"
      by(fastforce intro:While_CFG.Cons_path simp:valid_edge_def valid_node_def)
    with `[((_ l _),kind a,n'')] \<oplus>s 1 = [a] \<oplus>s 1` 
    have "if (b) prog else c\<^sub>2 \<turnstile> (_ l _) \<oplus> 1 -a#as \<oplus>s 1\<rightarrow>* n' \<oplus> 1"
      by(simp add:label_incrs_def)
    thus ?thesis by simp
  next
    case Entry
    with `valid_edge prog a` `targetnode a = n''` have False by fastforce
    thus ?thesis by simp
  next
    case Exit
    with `prog \<turnstile> n'' -as\<rightarrow>* n'` have "n' = (_Exit_)" and "as = []"
      by(auto dest:While_CFGExit.path_Exit_source)
    from `if (b) prog else c\<^sub>2 \<turnstile> (_ l _) \<oplus> 1 -kind a\<rightarrow> n'' \<oplus> 1` 
    have "if (b) prog else c\<^sub>2 \<turnstile> (_ l _) \<oplus> 1 -[((_ l _) \<oplus> 1,kind a,n'' \<oplus> 1)]\<rightarrow>* n'' \<oplus> 1"
      by(fastforce intro:While_CFG.Cons_path While_CFG.empty_path 
                  simp:While_CFG.valid_node_def valid_edge_def)
    with Exit `[((_ l _),kind a,n'')] \<oplus>s 1 = [a] \<oplus>s 1`  `n' = (_Exit_)` `as = []`
    show ?thesis by(fastforce simp:label_incrs_def)
  qed
qed


lemma path_CondFalse:
  "prog \<turnstile> (_ l _) -as\<rightarrow>* n'
  \<Longrightarrow> if (b) c\<^sub>1 else prog \<turnstile> (_ l _) \<oplus> (#:c\<^sub>1 + 1) -as \<oplus>s (#:c\<^sub>1 + 1)\<rightarrow>* n' \<oplus> (#:c\<^sub>1 + 1)"
proof(induct "(_ l _)" as n' arbitrary:l rule:While_CFG.path.induct)
  case empty_path
  from `CFG.valid_node sourcenode targetnode (valid_edge prog) (_ l _)`
    WCFG_CondFalse[of b c\<^sub>1 prog]
  have "CFG.valid_node sourcenode targetnode (valid_edge (if (b) c\<^sub>1 else prog))
    ((_ l _) \<oplus> #:c\<^sub>1 + 1)"
    apply(auto simp:While_CFG.valid_node_def valid_edge_def)
    apply(rotate_tac 1,drule WCFG_CondElse,simp,fastforce)
    apply(case_tac a) apply auto
     apply(rotate_tac 1,drule WCFG_CondElse,simp,fastforce)
    by(rotate_tac 1,drule WCFG_EntryD,auto)
  thus ?case by(fastforce intro:While_CFG.empty_path simp:label_incrs_def)
next
  case (Cons_path n'' as n' a)
  note IH = `\<And>l. n'' = (_ l _) \<Longrightarrow> if (b) c\<^sub>1 else prog \<turnstile> (_ l _) \<oplus> (#:c\<^sub>1 + 1) 
                                               -as \<oplus>s (#:c\<^sub>1 + 1)\<rightarrow>* n' \<oplus> (#:c\<^sub>1 + 1)`
  from `valid_edge prog a` `sourcenode a = (_ l _)`  `targetnode a = n''`
  have "if (b) c\<^sub>1 else prog \<turnstile> (_ l _) \<oplus> (#:c\<^sub>1 + 1) -kind a\<rightarrow> n'' \<oplus> (#:c\<^sub>1 + 1)"
    by -(rule WCFG_CondElse,simp_all add:valid_edge_def)
  from `sourcenode a = (_ l _)` `targetnode a = n''` `valid_edge prog a`
  have "[((_ l _),kind a,n'')] \<oplus>s (#:c\<^sub>1 + 1) = [a] \<oplus>s (#:c\<^sub>1 + 1)"
    by(cases a,simp add:label_incrs_def valid_edge_def)
  show ?case
  proof(cases n'')
    case (Node l')
    from IH[OF this] have "if (b) c\<^sub>1 else prog \<turnstile> (_ l' _) \<oplus> (#:c\<^sub>1 + 1) 
                                             -as \<oplus>s (#:c\<^sub>1 + 1)\<rightarrow>* n' \<oplus> (#:c\<^sub>1 + 1)" .
    with `if (b) c\<^sub>1 else prog \<turnstile> (_ l _) \<oplus> (#:c\<^sub>1 + 1) -kind a\<rightarrow> n'' \<oplus> (#:c\<^sub>1 + 1)` Node
    have "if (b) c\<^sub>1 else prog \<turnstile> (_ l _) \<oplus> (#:c\<^sub>1 + 1) 
      -((_ l _) \<oplus> (#:c\<^sub>1 + 1),kind a,n'' \<oplus> (#:c\<^sub>1 + 1))#(as \<oplus>s (#:c\<^sub>1 + 1))\<rightarrow>* 
      n' \<oplus> (#:c\<^sub>1 + 1)"
      by(fastforce intro:While_CFG.Cons_path simp:valid_edge_def valid_node_def)
    with `[((_ l _),kind a,n'')] \<oplus>s (#:c\<^sub>1 + 1) = [a] \<oplus>s (#:c\<^sub>1 + 1)` Node
    have "if (b) c\<^sub>1 else prog \<turnstile> (_ l _) \<oplus> (#:c\<^sub>1 + 1) -a#as \<oplus>s (#:c\<^sub>1 + 1)\<rightarrow>* 
                                n' \<oplus> (#:c\<^sub>1 + 1)"
      by(simp add:label_incrs_def)
    thus ?thesis by simp
  next
    case Entry
    with `valid_edge prog a` `targetnode a = n''` have False by fastforce
    thus ?thesis by simp
  next
    case Exit
    with `prog \<turnstile> n'' -as\<rightarrow>* n'` have "n' = (_Exit_)" and "as = []"
      by(auto dest:While_CFGExit.path_Exit_source)
    from `if (b) c\<^sub>1 else prog \<turnstile> (_ l _) \<oplus> (#:c\<^sub>1 + 1) -kind a\<rightarrow> n'' \<oplus> (#:c\<^sub>1 + 1)`
    have "if (b) c\<^sub>1 else prog \<turnstile> (_ l _) \<oplus> (#:c\<^sub>1 + 1) 
          -[((_ l _) \<oplus> (#:c\<^sub>1 + 1),kind a,n'' \<oplus> (#:c\<^sub>1 + 1))]\<rightarrow>* n'' \<oplus> (#:c\<^sub>1 + 1)"
      by(fastforce intro:While_CFG.Cons_path While_CFG.empty_path 
                  simp:While_CFG.valid_node_def valid_edge_def)
    with Exit `[((_ l _),kind a,n'')] \<oplus>s (#:c\<^sub>1 + 1) = [a] \<oplus>s (#:c\<^sub>1 + 1)` `n' = (_Exit_)`
      `as = []` 
    show ?thesis by(fastforce simp:label_incrs_def)
  qed
qed

(*<*)declare add_2_eq_Suc' [simp del] One_nat_def [simp del](*>*)

lemma path_While:
  "prog \<turnstile> (_ l _) -as\<rightarrow>* (_ l' _) 
  \<Longrightarrow> while (b) prog \<turnstile> (_ l _) \<oplus> 2 -as \<oplus>s 2\<rightarrow>* (_ l' _) \<oplus> 2"
proof(induct "(_ l _)" as "(_ l' _)" arbitrary:l l' rule:While_CFG.path.induct)
  case empty_path
  from `CFG.valid_node sourcenode targetnode (valid_edge prog) (_ l _)`
    WCFG_WhileTrue[of b prog]
  have "CFG.valid_node sourcenode targetnode (valid_edge (while (b) prog)) ((_ l _) \<oplus> 2)"
    apply(auto simp:While_CFG.valid_node_def valid_edge_def)
     apply(case_tac ba) apply auto
      apply(rotate_tac 1,drule WCFG_WhileBody,auto)
     apply(rotate_tac 1,drule WCFG_WhileBodyExit,auto)
    apply(case_tac a) apply auto
     apply(rotate_tac 1,drule WCFG_WhileBody,auto)
    by(rotate_tac 1,drule WCFG_EntryD,auto)
  thus ?case by(fastforce intro:While_CFG.empty_path simp:label_incrs_def)
next
  case (Cons_path n'' as a)
  note IH = `\<And>l. n'' = (_ l _)
    \<Longrightarrow> while (b) prog \<turnstile> (_ l _) \<oplus> 2 -as \<oplus>s 2\<rightarrow>* (_ l' _) \<oplus> 2`
   from `sourcenode a = (_ l _)` `targetnode a = n''` `valid_edge prog a`
  have "[((_ l _),kind a,n'')] \<oplus>s 2 = [a] \<oplus>s 2"
    by(cases a,simp add:label_incrs_def valid_edge_def)
  show ?case
  proof(cases n'')
    case (Node l'')
    with `valid_edge prog a` `sourcenode a = (_ l _)`  `targetnode a = n''`
    have "while (b) prog \<turnstile> (_ l _) \<oplus> 2 -kind a\<rightarrow> n'' \<oplus> 2"
      by -(rule WCFG_WhileBody,simp_all add:valid_edge_def)
    from IH[OF Node]
    have "while (b) prog \<turnstile> (_ l'' _) \<oplus> 2 -as \<oplus>s 2\<rightarrow>* (_ l' _) \<oplus> 2" .
    with `while (b) prog \<turnstile> (_ l _) \<oplus> 2 -kind a\<rightarrow> n'' \<oplus> 2` Node
    have "while (b) prog \<turnstile> (_ l _) \<oplus> 2 -((_ l _) \<oplus> 2,kind a,n'' \<oplus> 2)#(as \<oplus>s 2)\<rightarrow>* (_ l' _) \<oplus> 2"
      by(fastforce intro:While_CFG.Cons_path simp:valid_edge_def)
    with `[((_ l _),kind a,n'')] \<oplus>s 2 = [a] \<oplus>s 2` show ?thesis by(simp add:label_incrs_def)
  next
    case Entry
    with `valid_edge prog a` `targetnode a = n''` have False by fastforce
    thus ?thesis by simp
  next
    case Exit
    with `prog \<turnstile> n'' -as\<rightarrow>* (_ l' _)` have "(_ l' _) = (_Exit_)" and "as = []"
      by(auto dest:While_CFGExit.path_Exit_source)
    then have False by simp
    thus ?thesis by simp
  qed
qed



lemma inner_node_Entry_Exit_path: 
  "l < #:prog \<Longrightarrow> (\<exists>as. prog \<turnstile> (_ l _) -as\<rightarrow>* (_Exit_)) \<and>
                 (\<exists>as. prog \<turnstile> (_Entry_) -as\<rightarrow>* (_ l _))"
proof(induct prog arbitrary:l)
  case Skip
  from `l < #:Skip` have [simp]:"l = 0" by simp
  hence "Skip \<turnstile> (_ l _) -\<Up>id\<rightarrow> (_Exit_)" by(simp add:WCFG_Skip)
  hence "Skip \<turnstile> (_ l _) -[((_ l _),\<Up>id,(_Exit_))]\<rightarrow>* (_Exit_)"
    by (fastforce intro: While_CFG.path.intros simp: valid_edge_def)
  have "Skip \<turnstile> (_Entry_) -(\<lambda>s. True)\<^sub>\<surd>\<rightarrow> (_ l _)" by(simp add:WCFG_Entry)
  hence "Skip \<turnstile> (_Entry_) -[((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_ l _))]\<rightarrow>* (_ l _)"
    by(fastforce intro:While_CFG.path.intros simp:valid_edge_def While_CFG.valid_node_def)
  with `Skip \<turnstile> (_ l _) -[((_ l _),\<Up>id,(_Exit_))]\<rightarrow>* (_Exit_)` show ?case by fastforce
next
  case (LAss V e)
  from `l < #:V:=e` have "l = 0 \<or> l = 1" by auto
  thus ?case
  proof
    assume [simp]:"l = 0"
    hence "V:=e \<turnstile> (_Entry_) -(\<lambda>s. True)\<^sub>\<surd>\<rightarrow> (_ l _)" by(simp add:WCFG_Entry)
    hence "V:=e \<turnstile> (_Entry_) -[((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_ l _))]\<rightarrow>* (_ l _)"
      by(fastforce intro:While_CFG.path.intros simp:valid_edge_def While_CFG.valid_node_def)
    have "V:=e \<turnstile> (_1_) -\<Up>id\<rightarrow> (_Exit_)" by(rule WCFG_LAssSkip)
    hence "V:=e \<turnstile> (_1_) -[((_1_),\<Up>id,(_Exit_))]\<rightarrow>* (_Exit_)"
      by(fastforce intro:While_CFG.path.intros simp:valid_edge_def)
    with WCFG_LAss have "V:=e \<turnstile> (_ l _) -
      [((_ l _),\<Up>(\<lambda>s. s(V:=(interpret e s))),(_1_)),((_1_),\<Up>id,(_Exit_))]\<rightarrow>*
      (_Exit_)"
      by(fastforce intro:While_CFG.path.intros simp:valid_edge_def)
    with `V:=e \<turnstile> (_Entry_) -[((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_ l _))]\<rightarrow>* (_ l _)`
    show ?case by fastforce
  next
    assume [simp]:"l = 1"
    hence "V:=e \<turnstile> (_ l _) -\<Up>id\<rightarrow> (_Exit_)" by(simp add:WCFG_LAssSkip)
    hence "V:=e \<turnstile> (_ l _) -[((_ l _),\<Up>id,(_Exit_))]\<rightarrow>* (_Exit_)"
      by(fastforce intro:While_CFG.path.intros simp:valid_edge_def)
    have "V:=e \<turnstile> (_0_) -\<Up>(\<lambda>s. s(V:=(interpret e s)))\<rightarrow> (_ l _)"
      by(simp add:WCFG_LAss)
    hence "V:=e \<turnstile> (_0_) -[((_0_),\<Up>(\<lambda>s. s(V:=(interpret e s))),(_ l _))]\<rightarrow>* (_ l _)"
      by(fastforce intro:While_CFG.path.intros simp:valid_edge_def While_CFG.valid_node_def)
    with WCFG_Entry[of "V:=e"] have "V:=e \<turnstile> (_Entry_) -[((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_0_))
      ,((_0_),\<Up>(\<lambda>s. s(V:=(interpret e s))),(_ l _))]\<rightarrow>* (_ l _)"
      by(fastforce intro:While_CFG.path.intros simp:valid_edge_def)
    with `V:=e \<turnstile> (_ l _) -[((_ l _),\<Up>id,(_Exit_))]\<rightarrow>* (_Exit_)` show ?case by fastforce
  qed
next
  case (Seq prog1 prog2)
  note IH1 = `\<And>l. l < #:prog1 \<Longrightarrow>
  (\<exists>as. prog1 \<turnstile> (_ l _) -as\<rightarrow>* (_Exit_)) \<and> (\<exists>as. prog1 \<turnstile> (_Entry_) -as\<rightarrow>* (_ l _))`
  note IH2 = `\<And>l. l < #:prog2 \<Longrightarrow>
  (\<exists>as. prog2 \<turnstile> (_ l _) -as\<rightarrow>* (_Exit_)) \<and> (\<exists>as. prog2 \<turnstile> (_Entry_) -as\<rightarrow>* (_ l _))`
  show ?case
  proof(cases "l < #:prog1")
    case True
    from IH1[OF True] obtain as as' where "prog1 \<turnstile> (_ l _) -as\<rightarrow>* (_Exit_)"
      and "prog1 \<turnstile> (_Entry_) -as'\<rightarrow>* (_ l _)" by blast
    from `prog1 \<turnstile> (_Entry_) -as'\<rightarrow>* (_ l _)`
    have "prog1;;prog2 \<turnstile> (_Entry_) -as'\<rightarrow>* (_ l _)"
      by(fastforce intro:path_SeqFirst)
    from `prog1 \<turnstile> (_ l _) -as\<rightarrow>* (_Exit_)`
    obtain asx ax where "prog1 \<turnstile> (_ l _) -asx@[ax]\<rightarrow>* (_Exit_)"
      by(induct rule:rev_induct,auto elim:While_CFG.path.cases)
    hence "prog1 \<turnstile> (_ l _) -asx\<rightarrow>* sourcenode ax"
      and "valid_edge prog1 ax" and "(_Exit_) = targetnode ax"
      by(auto intro:While_CFG.path_split_snoc)
    from `prog1 \<turnstile> (_ l _) -asx\<rightarrow>* sourcenode ax` `valid_edge prog1 ax`
    obtain lx where [simp]:"sourcenode ax = (_ lx _)"
      by(cases "sourcenode ax") auto
    with `prog1 \<turnstile> (_ l _) -asx\<rightarrow>* sourcenode ax` 
    have "prog1;;prog2 \<turnstile> (_ l _) -asx\<rightarrow>* sourcenode ax"
      by(fastforce intro:path_SeqFirst)
    from `valid_edge prog1 ax` `(_Exit_) = targetnode ax`
    have "prog1;;prog2 \<turnstile> sourcenode ax -kind ax\<rightarrow> (_0_) \<oplus> #:prog1"
      by(fastforce intro:WCFG_SeqConnect simp:valid_edge_def)
    hence "prog1;;prog2 \<turnstile> sourcenode ax -[(sourcenode ax,kind ax,(_0_) \<oplus> #:prog1)]\<rightarrow>*
                          (_0_) \<oplus> #:prog1"
      by(fastforce intro:While_CFG.Cons_path While_CFG.empty_path 
                  simp:While_CFG.valid_node_def valid_edge_def)
    with `prog1;;prog2 \<turnstile> (_ l _) -asx\<rightarrow>* sourcenode ax`
    have "prog1;;prog2 \<turnstile> (_ l _) -asx@[(sourcenode ax,kind ax,(_0_) \<oplus> #:prog1)]\<rightarrow>*
                         (_0_) \<oplus> #:prog1"
      by(fastforce intro:While_CFG.path_Append)
    from IH2[of "0"] obtain as'' where "prog2 \<turnstile> (_ 0 _) -as''\<rightarrow>* (_Exit_)" by blast
    hence "prog1;;prog2 \<turnstile> (_0_) \<oplus> #:prog1 -as'' \<oplus>s #:prog1\<rightarrow>* (_Exit_) \<oplus> #:prog1"
      by(fastforce intro!:path_SeqSecond elim:While_CFG.path.cases)
    hence "prog1;;prog2 \<turnstile> (_0_) \<oplus> #:prog1 -as'' \<oplus>s #:prog1\<rightarrow>* (_Exit_)"
      by simp
    with `prog1;;prog2 \<turnstile> (_ l _) -asx@[(sourcenode ax,kind ax,(_0_) \<oplus> #:prog1)]\<rightarrow>*
                         (_0_) \<oplus> #:prog1`
    have "prog1;;prog2 \<turnstile> (_ l _) -(asx@[(sourcenode ax,kind ax,(_0_) \<oplus> #:prog1)])@
                                  (as'' \<oplus>s #:prog1)\<rightarrow>* (_Exit_)"
      by(fastforce intro:While_CFG.path_Append)
    with `prog1;;prog2 \<turnstile> (_Entry_) -as'\<rightarrow>* (_ l _)` show ?thesis by blast
  next
    case False
    hence "#:prog1 \<le> l" by simp
    then obtain l' where [simp]:"l = l' + #:prog1" and "l' = l - #:prog1" by simp
    from `l < #:prog1;; prog2` have "l' < #:prog2" by simp
    from IH2[OF this] obtain as as' where "prog2 \<turnstile> (_ l' _) -as\<rightarrow>* (_Exit_)"
      and "prog2 \<turnstile> (_Entry_) -as'\<rightarrow>* (_ l' _)" by blast
    from `prog2 \<turnstile> (_ l' _) -as\<rightarrow>* (_Exit_)` 
    have "prog1;;prog2 \<turnstile> (_ l' _) \<oplus> #:prog1 -as \<oplus>s #:prog1\<rightarrow>* (_Exit_) \<oplus> #:prog1"
      by(fastforce intro!:path_SeqSecond elim:While_CFG.path.cases)
    hence "prog1;;prog2 \<turnstile> (_ l _) -as \<oplus>s #:prog1\<rightarrow>* (_Exit_)"
      by simp
    from IH1[of 0] obtain as'' where "prog1 \<turnstile> (_0_) -as''\<rightarrow>* (_Exit_)" by blast
    then obtain ax asx where "prog1 \<turnstile> (_0_) -asx@[ax]\<rightarrow>* (_Exit_)"
      by(induct rule:rev_induct,auto elim:While_CFG.path.cases)
    hence "prog1 \<turnstile> (_0_) -asx\<rightarrow>* sourcenode ax" and "valid_edge prog1 ax"
      and "(_Exit_) = targetnode ax" by(auto intro:While_CFG.path_split_snoc)
    from WCFG_Entry `prog1 \<turnstile> (_0_) -asx\<rightarrow>* sourcenode ax`
    have "prog1 \<turnstile> (_Entry_) -((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_0_))#asx\<rightarrow>* sourcenode ax"
      by(fastforce intro:While_CFG.Cons_path simp:valid_edge_def valid_node_def)
    from `prog1 \<turnstile> (_0_) -asx\<rightarrow>* sourcenode ax` `valid_edge prog1 ax`
    obtain lx where [simp]:"sourcenode ax = (_ lx _)"
      by(cases "sourcenode ax") auto
    with `prog1 \<turnstile> (_Entry_) -((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_0_))#asx\<rightarrow>* sourcenode ax`
    have "prog1;;prog2 \<turnstile> (_Entry_) -((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_0_))#asx\<rightarrow>* 
                         sourcenode ax"
      by(fastforce intro:path_SeqFirst)
    from `prog2 \<turnstile> (_Entry_) -as'\<rightarrow>* (_ l' _)` obtain ax' asx' 
      where "prog2 \<turnstile> (_Entry_) -ax'#asx'\<rightarrow>* (_ l' _)" 
      by(cases as',auto elim:While_CFG.path.cases)
    hence "(_Entry_) = sourcenode ax'" and "valid_edge prog2 ax'"
      and "prog2 \<turnstile> targetnode ax' -asx'\<rightarrow>* (_ l' _)"
      by(auto intro:While_CFG.path_split_Cons)
    hence "targetnode ax' = (_0_)" by(fastforce dest:WCFG_EntryD simp:valid_edge_def)
    from `valid_edge prog1 ax` `(_Exit_) = targetnode ax`
    have "prog1;;prog2 \<turnstile> sourcenode ax -kind ax\<rightarrow> (_0_) \<oplus> #:prog1"
      by(fastforce intro:WCFG_SeqConnect simp:valid_edge_def)
    have "\<exists>as. prog1;;prog2 \<turnstile> sourcenode ax -as\<rightarrow>* (_ l _)"
    proof(cases "asx' = []")
      case True
      with `prog2 \<turnstile> targetnode ax' -asx'\<rightarrow>* (_ l' _)` `targetnode ax' = (_0_)`
      have "l' = 0" by(auto elim:While_CFG.path.cases)
      with `prog1;;prog2 \<turnstile> sourcenode ax -kind ax\<rightarrow> (_0_) \<oplus> #:prog1`     
      have "prog1;;prog2 \<turnstile> sourcenode ax -[(sourcenode ax,kind ax,(_ l _))]\<rightarrow>* 
                           (_ l _)"
        by(auto intro!:While_CFG.path.intros 
                    simp:While_CFG.valid_node_def valid_edge_def,blast)
      thus ?thesis by blast
    next
      case False
      with `prog2 \<turnstile> targetnode ax' -asx'\<rightarrow>* (_ l' _)` `targetnode ax' = (_0_)`
      have "prog1;;prog2 \<turnstile> (_0_) \<oplus> #:prog1 -asx' \<oplus>s #:prog1\<rightarrow>* (_ l' _) \<oplus> #:prog1"
        by(fastforce intro:path_SeqSecond)
      hence "prog1;;prog2 \<turnstile> (_0_) \<oplus> #:prog1 -asx' \<oplus>s #:prog1\<rightarrow>* (_ l _)" by simp
      with `prog1;;prog2 \<turnstile> sourcenode ax -kind ax\<rightarrow> (_0_) \<oplus> #:prog1`
      have "prog1;;prog2 \<turnstile> sourcenode ax -(sourcenode ax,kind ax,(_0_) \<oplus> #:prog1)#
                                          (asx' \<oplus>s #:prog1)\<rightarrow>* (_ l _)"
        by(fastforce intro: While_CFG.Cons_path simp:valid_node_def valid_edge_def)
      thus ?thesis by blast
    qed
    then obtain asx'' where "prog1;;prog2 \<turnstile> sourcenode ax -asx''\<rightarrow>* (_ l _)" by blast
    with `prog1;;prog2 \<turnstile> (_Entry_) -((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_0_))#asx\<rightarrow>* 
                         sourcenode ax`
    have "prog1;;prog2 \<turnstile> (_Entry_) -(((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_0_))#asx)@asx''\<rightarrow>* 
                         (_ l _)"
      by(rule While_CFG.path_Append)
    with `prog1;;prog2 \<turnstile> (_ l _) -as \<oplus>s #:prog1\<rightarrow>* (_Exit_)`
    show ?thesis by blast
  qed
next
  case (Cond b prog1 prog2)
  note IH1 = `\<And>l. l < #:prog1 \<Longrightarrow>
  (\<exists>as. prog1 \<turnstile> (_ l _) -as\<rightarrow>* (_Exit_)) \<and> (\<exists>as. prog1 \<turnstile> (_Entry_) -as\<rightarrow>* (_ l _))`
  note IH2 = `\<And>l. l < #:prog2 \<Longrightarrow>
  (\<exists>as. prog2 \<turnstile> (_ l _) -as\<rightarrow>* (_Exit_)) \<and> (\<exists>as. prog2 \<turnstile> (_Entry_) -as\<rightarrow>* (_ l _))`
  show ?case
  proof(cases "l = 0")
    case True
    from IH1[of 0] obtain as where "prog1 \<turnstile> (_0_) -as\<rightarrow>* (_Exit_)" by blast
    hence "if (b) prog1 else prog2 \<turnstile> (_0_) \<oplus> 1 -as \<oplus>s 1\<rightarrow>* (_Exit_) \<oplus> 1"
      by(fastforce intro:path_CondTrue)
    with WCFG_CondTrue[of b prog1 prog2] have "if (b) prog1 else prog2 \<turnstile> 
      (_0_) -((_0_),(\<lambda>s. interpret b s = Some true)\<^sub>\<surd>,(_0_) \<oplus> 1)#(as \<oplus>s 1)\<rightarrow>* 
      (_Exit_) \<oplus> 1"
      by(fastforce intro:While_CFG.Cons_path simp:valid_edge_def valid_node_def)
    with True have "if (b) prog1 else prog2 \<turnstile> 
      (_ l _) -((_0_),(\<lambda>s. interpret b s = Some true)\<^sub>\<surd>,(_0_) \<oplus> 1)#(as \<oplus>s 1)\<rightarrow>*
      (_Exit_)" by simp
    moreover
    from WCFG_Entry[of "if (b) prog1 else prog2"] True
    have "if (b) prog1 else prog2 \<turnstile> (_Entry_) -[((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_0_))]\<rightarrow>* 
                                    (_ l _)"
      by(fastforce intro:While_CFG.Cons_path While_CFG.empty_path
                  simp:While_CFG.valid_node_def valid_edge_def)
    ultimately show ?thesis by blast
  next
    case False
    hence "0 < l" by simp
    then obtain l' where [simp]:"l = l' + 1" and "l' = l - 1" by simp
    show ?thesis
    proof(cases "l' < #:prog1")
      case True
      from IH1[OF this] obtain as as' where "prog1 \<turnstile> (_ l' _) -as\<rightarrow>* (_Exit_)"
        and "prog1 \<turnstile> (_Entry_) -as'\<rightarrow>* (_ l' _)" by blast
      from `prog1 \<turnstile> (_ l' _) -as\<rightarrow>* (_Exit_)`
      have "if (b) prog1 else prog2 \<turnstile> (_ l' _) \<oplus> 1 -as \<oplus>s 1\<rightarrow>* (_Exit_) \<oplus> 1"
        by(fastforce intro:path_CondTrue)
      hence "if (b) prog1 else prog2 \<turnstile> (_ l _) -as \<oplus>s 1\<rightarrow>* (_Exit_)"
        by simp
      from `prog1 \<turnstile> (_Entry_) -as'\<rightarrow>* (_ l' _)` obtain ax asx
        where "prog1 \<turnstile> (_Entry_) -ax#asx\<rightarrow>* (_ l' _)"
        by(cases as',auto elim:While_CFG.cases)
      hence "(_Entry_) = sourcenode ax" and "valid_edge prog1 ax"
        and "prog1 \<turnstile> targetnode ax -asx\<rightarrow>* (_ l' _)"
        by(auto intro:While_CFG.path_split_Cons)
      hence "targetnode ax = (_0_)" by(fastforce dest:WCFG_EntryD simp:valid_edge_def)
      with `prog1 \<turnstile> targetnode ax -asx\<rightarrow>* (_ l' _)`
      have "if (b) prog1 else prog2 \<turnstile> (_0_) \<oplus> 1 -asx \<oplus>s 1\<rightarrow>* (_ l' _) \<oplus> 1"
        by(fastforce intro:path_CondTrue)
      with WCFG_CondTrue[of b prog1 prog2]
      have "if (b) prog1 else prog2 \<turnstile> (_0_) 
        -((_0_),(\<lambda>s. interpret b s = Some true)\<^sub>\<surd>,(_0_) \<oplus> 1)#(asx \<oplus>s 1)\<rightarrow>* 
         (_ l' _) \<oplus> 1"
        by(fastforce intro:While_CFG.Cons_path simp:valid_edge_def)
      with WCFG_Entry[of "if (b) prog1 else prog2"]
      have "if (b) prog1 else prog2 \<turnstile> (_Entry_) -((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_0_))#
        ((_0_),(\<lambda>s. interpret b s = Some true)\<^sub>\<surd>,(_0_) \<oplus> 1)#(asx \<oplus>s 1)\<rightarrow>* 
         (_ l' _) \<oplus> 1"
        by(fastforce intro:While_CFG.Cons_path simp:valid_edge_def)
      with `if (b) prog1 else prog2 \<turnstile> (_ l _) -as \<oplus>s 1\<rightarrow>* (_Exit_)`
      show ?thesis by simp blast
    next
      case False
      hence "#:prog1 \<le> l'" by simp
      then obtain l'' where [simp]:"l' = l'' + #:prog1" and "l'' = l' - #:prog1"
        by simp
      from  `l < #:(if (b) prog1 else prog2)` 
      have "l'' < #:prog2" by simp
      from IH2[OF this] obtain as as' where "prog2 \<turnstile> (_ l'' _) -as\<rightarrow>* (_Exit_)"
        and "prog2 \<turnstile> (_Entry_) -as'\<rightarrow>* (_ l'' _)" by blast
      from `prog2 \<turnstile> (_ l'' _) -as\<rightarrow>* (_Exit_)`
      have "if (b) prog1 else prog2 \<turnstile> (_ l'' _) \<oplus> (#:prog1 + 1) 
        -as \<oplus>s (#:prog1 + 1)\<rightarrow>* (_Exit_) \<oplus> (#:prog1 + 1)"
        by(fastforce intro:path_CondFalse)
      hence "if (b) prog1 else prog2 \<turnstile> (_ l _) -as \<oplus>s (#:prog1 + 1)\<rightarrow>* (_Exit_)"
        by(simp add:add.assoc)
      from `prog2 \<turnstile> (_Entry_) -as'\<rightarrow>* (_ l'' _)` obtain ax asx
        where "prog2 \<turnstile> (_Entry_) -ax#asx\<rightarrow>* (_ l'' _)"
        by(cases as',auto elim:While_CFG.cases)
      hence "(_Entry_) = sourcenode ax" and "valid_edge prog2 ax"
        and "prog2 \<turnstile> targetnode ax -asx\<rightarrow>* (_ l'' _)"
        by(auto intro:While_CFG.path_split_Cons)
      hence "targetnode ax = (_0_)" by(fastforce dest:WCFG_EntryD simp:valid_edge_def)
      with `prog2 \<turnstile> targetnode ax -asx\<rightarrow>* (_ l'' _)`
      have "if (b) prog1 else prog2 \<turnstile> (_0_) \<oplus> (#:prog1 + 1) -asx \<oplus>s (#:prog1 + 1)\<rightarrow>*
        (_ l'' _) \<oplus> (#:prog1 + 1)"
        by(fastforce intro:path_CondFalse)
      with WCFG_CondFalse[of b prog1 prog2]
      have "if (b) prog1 else prog2 \<turnstile> (_0_) 
        -((_0_),(\<lambda>s. interpret b s = Some false)\<^sub>\<surd>,(_0_) \<oplus> (#:prog1 + 1))#
        (asx \<oplus>s  (#:prog1 + 1))\<rightarrow>* (_ l'' _) \<oplus>  (#:prog1 + 1)"
        by(fastforce intro:While_CFG.Cons_path simp:valid_edge_def)
      with WCFG_Entry[of "if (b) prog1 else prog2"]
      have "if (b) prog1 else prog2 \<turnstile> (_Entry_) -((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_0_))#
        ((_0_),(\<lambda>s. interpret b s = Some false)\<^sub>\<surd>,(_0_) \<oplus> (#:prog1 + 1))#
        (asx \<oplus>s (#:prog1 + 1))\<rightarrow>* (_ l'' _) \<oplus> (#:prog1 + 1)"
        by(fastforce intro:While_CFG.Cons_path simp:valid_edge_def)
      with 
        `if (b) prog1 else prog2 \<turnstile> (_ l _) -as \<oplus>s (#:prog1 + 1)\<rightarrow>* (_Exit_)`
      show ?thesis by(simp add:add.assoc,blast)
    qed
  qed
next
  case (While b prog')
  note IH = `\<And>l. l < #:prog' \<Longrightarrow>
   (\<exists>as. prog' \<turnstile> (_ l _) -as\<rightarrow>* (_Exit_)) \<and> (\<exists>as. prog' \<turnstile> (_Entry_) -as\<rightarrow>* (_ l _))`
  show ?case
  proof(cases "l < 1")
    case True
    from WCFG_Entry[of "while (b) prog'"]
    have "while (b) prog' \<turnstile> (_Entry_) -[((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_0_))]\<rightarrow>* (_0_)"
      by(fastforce intro:While_CFG.Cons_path While_CFG.empty_path
                  simp:While_CFG.valid_node_def valid_edge_def)
    from WCFG_WhileFalseSkip[of b prog']
    have "while (b) prog' \<turnstile> (_1_) -[((_1_),\<Up>id,(_Exit_))]\<rightarrow>* (_Exit_)"
      by(fastforce intro:While_CFG.Cons_path While_CFG.empty_path
                  simp:valid_node_def valid_edge_def)
    with WCFG_WhileFalse[of b prog']
    have "while (b) prog' \<turnstile> (_0_) -((_0_),(\<lambda>s. interpret b s = Some false)\<^sub>\<surd>,(_1_))#
      [((_1_),\<Up>id,(_Exit_))]\<rightarrow>* (_Exit_)"
      by(fastforce intro:While_CFG.Cons_path While_CFG.empty_path
                  simp:valid_node_def valid_edge_def)
    with `while (b) prog' \<turnstile> (_Entry_) -[((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_0_))]\<rightarrow>* (_0_)` True
    show ?thesis by simp blast
  next
    case False
    hence "1 \<le> l" by simp
    thus ?thesis
    proof(cases "l < 2")
      case True
      with `1 \<le> l` have [simp]:"l = 1" by simp
      from WCFG_WhileFalseSkip[of b prog']
      have "while (b) prog' \<turnstile> (_1_) -[((_1_),\<Up>id,(_Exit_))]\<rightarrow>* (_Exit_)"
        by(fastforce intro:While_CFG.Cons_path While_CFG.empty_path
                    simp:valid_node_def valid_edge_def)
      from WCFG_WhileFalse[of b prog']
      have "while (b) prog' \<turnstile> (_0_) 
        -[((_0_),(\<lambda>s. interpret b s = Some false)\<^sub>\<surd>,(_1_))]\<rightarrow>* (_1_)"
        by(fastforce intro:While_CFG.Cons_path While_CFG.empty_path
                    simp:While_CFG.valid_node_def valid_edge_def)
      with WCFG_Entry[of "while (b) prog'"]
      have "while (b) prog' \<turnstile> (_Entry_) -((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_0_))#
        [((_0_),(\<lambda>s. interpret b s = Some false)\<^sub>\<surd>,(_1_))]\<rightarrow>* (_1_)"
        by(fastforce intro:While_CFG.Cons_path simp:valid_node_def valid_edge_def)
      with `while (b) prog' \<turnstile> (_1_) -[((_1_),\<Up>id,(_Exit_))]\<rightarrow>* (_Exit_)` 
      show ?thesis by simp blast
    next
      case False
      with `1 \<le> l` have "2 \<le> l" by simp
      then obtain l' where [simp]:"l = l' + 2" and "l' = l - 2" 
        by(simp del:add_2_eq_Suc')
      from `l < #:while (b) prog'` have "l' < #:prog'" by simp
      from IH[OF this] obtain as as' where "prog' \<turnstile> (_ l' _) -as\<rightarrow>* (_Exit_)"
        and "prog' \<turnstile> (_Entry_) -as'\<rightarrow>* (_ l' _)" by blast
      from `prog' \<turnstile> (_ l' _) -as\<rightarrow>* (_Exit_)` obtain ax asx where
        "prog' \<turnstile> (_ l' _) -asx@[ax]\<rightarrow>* (_Exit_)"
        by(induct as rule:rev_induct,auto elim:While_CFG.cases)
      hence "prog' \<turnstile> (_ l' _) -asx\<rightarrow>* sourcenode ax" and "valid_edge prog' ax"
        and "(_Exit_) = targetnode ax"
        by(auto intro:While_CFG.path_split_snoc)
      then obtain lx where "sourcenode ax = (_ lx _)"
        by(cases "sourcenode ax") auto
      with `prog' \<turnstile> (_ l' _) -asx\<rightarrow>* sourcenode ax`
      have "while (b) prog' \<turnstile> (_ l' _) \<oplus> 2 -asx \<oplus>s 2\<rightarrow>* sourcenode ax \<oplus> 2"
        by(fastforce intro:path_While simp del:label_incr.simps)
      from WCFG_WhileFalseSkip[of b prog']
      have "while (b) prog' \<turnstile> (_1_) -[((_1_),\<Up>id,(_Exit_))]\<rightarrow>* (_Exit_)"
        by(fastforce intro:While_CFG.Cons_path While_CFG.empty_path
                    simp:valid_node_def valid_edge_def)
      with WCFG_WhileFalse[of b prog']
      have "while (b) prog' \<turnstile> (_0_) -((_0_),(\<lambda>s. interpret b s = Some false)\<^sub>\<surd>,(_1_))#
        [((_1_),\<Up>id,(_Exit_))]\<rightarrow>* (_Exit_)"
        by(fastforce intro:While_CFG.Cons_path simp:valid_node_def valid_edge_def)
      with `valid_edge prog' ax` `(_Exit_) = targetnode ax` `sourcenode ax = (_ lx _)`
      have "while (b) prog' \<turnstile> sourcenode ax \<oplus> 2 -(sourcenode ax \<oplus> 2,kind ax,(_0_))#
        ((_0_),(\<lambda>s. interpret b s = Some false)\<^sub>\<surd>,(_1_))#
        [((_1_),\<Up>id,(_Exit_))]\<rightarrow>* (_Exit_)"
        by(fastforce intro:While_CFG.Cons_path dest:WCFG_WhileBodyExit
                    simp:valid_node_def valid_edge_def)
      with `while (b) prog' \<turnstile> (_ l' _) \<oplus> 2 -asx \<oplus>s 2\<rightarrow>* sourcenode ax \<oplus> 2`
      have path:"while (b) prog' \<turnstile> (_ l' _) \<oplus> 2 -(asx \<oplus>s 2)@
        ((sourcenode ax \<oplus> 2,kind ax,(_0_))#
        ((_0_),(\<lambda>s. interpret b s = Some false)\<^sub>\<surd>,(_1_))#
        [((_1_),\<Up>id,(_Exit_))])\<rightarrow>* (_Exit_)"
        by(rule While_CFG.path_Append)
      from `prog' \<turnstile> (_Entry_) -as'\<rightarrow>* (_ l' _)` obtain ax' asx'
        where "prog' \<turnstile> (_Entry_) -ax'#asx'\<rightarrow>* (_ l' _)"
        by(cases as',auto elim:While_CFG.cases)
      hence "(_Entry_) = sourcenode ax'" and "valid_edge prog' ax'"
        and "prog' \<turnstile> targetnode ax' -asx'\<rightarrow>* (_ l' _)"
        by(auto intro:While_CFG.path_split_Cons)
      hence "targetnode ax' = (_0_)" by(fastforce dest:WCFG_EntryD simp:valid_edge_def)
      with `prog' \<turnstile> targetnode ax' -asx'\<rightarrow>* (_ l' _)`
      have "while (b) prog' \<turnstile> (_0_) \<oplus> 2 -asx' \<oplus>s 2\<rightarrow>* (_ l' _) \<oplus> 2"
        by(fastforce intro:path_While)
      with WCFG_WhileTrue[of b prog']
      have "while (b) prog' \<turnstile> (_0_) 
        -((_0_),(\<lambda>s. interpret b s = Some true)\<^sub>\<surd>,(_0_) \<oplus> 2)#(asx' \<oplus>s 2)\<rightarrow>* 
        (_ l' _) \<oplus> 2"
        by(fastforce intro:While_CFG.Cons_path simp:valid_node_def valid_edge_def)
      with WCFG_Entry[of "while (b) prog'"]
      have "while (b) prog' \<turnstile> (_Entry_) -((_Entry_),(\<lambda>s. True)\<^sub>\<surd>,(_0_))#
        ((_0_),(\<lambda>s. interpret b s = Some true)\<^sub>\<surd>,(_0_) \<oplus> 2)#(asx' \<oplus>s 2)\<rightarrow>* 
        (_ l' _) \<oplus> 2"
        by(fastforce intro:While_CFG.Cons_path simp:valid_node_def valid_edge_def)
      with path show ?thesis by simp blast
    qed
  qed
qed

(*<*)declare add_2_eq_Suc' [simp] One_nat_def [simp](*>*)


lemma valid_node_Exit_path:
  assumes "valid_node prog n" shows "\<exists>as. prog \<turnstile> n -as\<rightarrow>* (_Exit_)"
proof(cases n)
  case (Node l)
  with `valid_node prog n` have "l < #:prog"
    by(fastforce dest:WCFG_sourcelabel_less_num_nodes WCFG_targetlabel_less_num_nodes
                simp:valid_node_def valid_edge_def)
  with Node show ?thesis by(fastforce dest:inner_node_Entry_Exit_path)
next
  case Entry
  from WCFG_Entry_Exit[of prog]
  have "prog \<turnstile> (_Entry_) -[((_Entry_),(\<lambda>s. False)\<^sub>\<surd>,(_Exit_))]\<rightarrow>* (_Exit_)"
    by(fastforce intro:While_CFG.Cons_path While_CFG.empty_path
                simp:valid_node_def valid_edge_def)
  with Entry show ?thesis by blast
next
  case Exit
  with WCFG_Entry_Exit[of prog]
  have "prog \<turnstile> n -[]\<rightarrow>* (_Exit_)"
    by(fastforce intro:While_CFG.empty_path simp:valid_node_def valid_edge_def)
  thus ?thesis by blast
qed


lemma valid_node_Entry_path:
  assumes "valid_node prog n" shows "\<exists>as. prog \<turnstile> (_Entry_) -as\<rightarrow>* n"
proof(cases n)
  case (Node l)
  with `valid_node prog n` have "l < #:prog"
    by(fastforce dest:WCFG_sourcelabel_less_num_nodes WCFG_targetlabel_less_num_nodes
                simp:valid_node_def valid_edge_def)
  with Node show ?thesis by(fastforce dest:inner_node_Entry_Exit_path)
next
  case Entry
  with WCFG_Entry_Exit[of prog]
  have "prog \<turnstile> (_Entry_) -[]\<rightarrow>* n"
    by(fastforce intro:While_CFG.empty_path simp:valid_node_def valid_edge_def)
  thus ?thesis by blast
next
  case Exit
  from WCFG_Entry_Exit[of prog]
  have "prog \<turnstile> (_Entry_) -[((_Entry_),(\<lambda>s. False)\<^sub>\<surd>,(_Exit_))]\<rightarrow>* (_Exit_)"
    by(fastforce intro:While_CFG.Cons_path While_CFG.empty_path
                simp:valid_node_def valid_edge_def)
  with Exit show ?thesis by blast
qed


subsection {* Some finiteness considerations *}

lemma finite_labels:"finite {l. \<exists>c. labels prog l c}"
proof -
  have "finite {l::nat. l < #:prog}" by(fastforce intro:nat_seg_image_imp_finite)
  moreover have "{l. \<exists>c. labels prog l c} \<subseteq> {l::nat. l < #:prog}"
    by(fastforce intro:label_less_num_inner_nodes)
  ultimately show ?thesis by(auto intro:finite_subset)
qed


lemma finite_valid_nodes:"finite {n. valid_node prog n}"
proof -
  have "{n. \<exists>n' et. prog \<turnstile> n -et\<rightarrow> n'} \<subseteq> 
    insert (_Entry_) ((\<lambda>l'. (_ l' _)) ` {l. \<exists>c. labels prog l c})"
    apply clarsimp
    apply(case_tac x,auto)
    by(fastforce dest:WCFG_sourcelabel_less_num_nodes less_num_inner_nodes_label)
  hence "finite {n. \<exists>n' et. prog \<turnstile> n -et\<rightarrow> n'}"
    by(auto intro:finite_subset finite_imageI finite_labels)
  have "{n'. \<exists>n et. prog \<turnstile> n -et\<rightarrow> n'} \<subseteq> 
    insert (_Exit_) ((\<lambda>l'. (_ l' _)) ` {l. \<exists>c. labels prog l c})"
    apply clarsimp
    apply(case_tac x,auto)
    by(fastforce dest:WCFG_targetlabel_less_num_nodes less_num_inner_nodes_label)
  hence "finite {n'. \<exists>n et. prog \<turnstile> n -et\<rightarrow> n'}"
    by(auto intro:finite_subset finite_imageI finite_labels)
  have "{n. \<exists>nx et nx'. prog \<turnstile> nx -et\<rightarrow> nx' \<and> (n = nx \<or> n = nx')} =
    {n. \<exists>n' et. prog \<turnstile> n -et\<rightarrow> n'} Un {n'. \<exists>n et. prog \<turnstile> n -et\<rightarrow> n'}" by blast
  with `finite {n. \<exists>n' et. prog \<turnstile> n -et\<rightarrow> n'}` `finite {n'. \<exists>n et. prog \<turnstile> n -et\<rightarrow> n'}`
  have "finite {n. \<exists>nx et nx'. prog \<turnstile> nx -et\<rightarrow> nx' \<and> (n = nx \<or> n = nx')}"
    by fastforce
  thus ?thesis by(simp add:valid_node_def valid_edge_def)
qed

lemma finite_successors:
  "finite {n'. \<exists>a'. valid_edge prog a' \<and> sourcenode a' = n \<and> 
                    targetnode a' = n'}"
proof -
  have "{n'. \<exists>a'. valid_edge prog a' \<and> sourcenode a' = n \<and> 
                  targetnode a' = n'} \<subseteq> {n. valid_node prog n}"
    by(auto simp:valid_edge_def valid_node_def)
  thus ?thesis by(fastforce elim:finite_subset intro:finite_valid_nodes)
qed


end