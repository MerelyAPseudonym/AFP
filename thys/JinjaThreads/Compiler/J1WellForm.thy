(*  Title:      JinjaThreads/Compiler/WellType1.thy
    Author:     Andreas Lochbihler, Tobias Nipkow
*)

header {* \isaheader{Well-Formedness of Intermediate Language} *}

theory J1WellForm
imports "../J/JWellForm" J1
begin

subsection "Well-Typedness"

types 
  env1  = "ty list"   --"type environment indexed by variable number"

inductive WT1 :: "J1_prog \<Rightarrow> env1 \<Rightarrow> expr1 \<Rightarrow> ty \<Rightarrow> bool" ("_,_ \<turnstile>1 _ :: _"   [51,0,0,51] 50)
  and WTs1 :: "J1_prog \<Rightarrow> env1 \<Rightarrow> expr1 list \<Rightarrow> ty list \<Rightarrow> bool" ("_,_ \<turnstile>1 _ [::] _"   [51,0,0,51]50)
  for P :: J1_prog
  where

  WT1New:
  "is_class P C  \<Longrightarrow>
  P,E \<turnstile>1 new C :: Class C"

| WT1NewArray:
  "\<lbrakk> P,E \<turnstile>1 e :: Integer; is_type P T \<rbrakk> \<Longrightarrow>
  P,E \<turnstile>1 newA T\<lfloor>e\<rceil> :: T\<lfloor>\<rceil>"

| WT1Cast:
  "\<lbrakk> P,E \<turnstile>1 e :: T; P \<turnstile> U \<le> T \<or> P \<turnstile> T \<le> U; is_type P U \<rbrakk>
  \<Longrightarrow> P,E \<turnstile>1 Cast U e :: U"

| WT1Val:
  "typeof v = Some T \<Longrightarrow>
  P,E \<turnstile>1 Val v :: T"

| WT1Var:
  "\<lbrakk> E!V = T; V < size E \<rbrakk> \<Longrightarrow>
  P,E \<turnstile>1 Var V :: T"

| WT1BinOpEq:
  "\<lbrakk> P,E \<turnstile>1 e1 :: T1;  P,E \<turnstile>1 e2 :: T2; P \<turnstile> T1 \<le> T2 \<or> P \<turnstile> T2 \<le> T1 \<rbrakk>
  \<Longrightarrow> P,E \<turnstile>1 e1 \<guillemotleft>Eq\<guillemotright> e2 :: Boolean"

| WT1BinOpAdd:
  "\<lbrakk> P,E \<turnstile>1 e1 :: Integer;  P,E \<turnstile>1 e2 :: Integer \<rbrakk>
  \<Longrightarrow> P,E \<turnstile>1 e1 \<guillemotleft>Add\<guillemotright> e2 :: Integer"

| WT1LAss:
  "\<lbrakk> E!i = T;  i < size E; P,E \<turnstile>1 e :: T';  P \<turnstile> T' \<le> T \<rbrakk>
  \<Longrightarrow> P,E \<turnstile>1 i:=e :: Void"

| WT1AAcc:
  "\<lbrakk> P,E \<turnstile>1 a :: T\<lfloor>\<rceil>; P,E \<turnstile>1 i :: Integer \<rbrakk>
  \<Longrightarrow> P,E \<turnstile>1 a\<lfloor>i\<rceil> :: T"

| WT1AAss:
  "\<lbrakk> P,E \<turnstile>1 a :: T\<lfloor>\<rceil>; P,E \<turnstile>1 i :: Integer; P,E \<turnstile>1 e :: T'; P \<turnstile> T' \<le> T \<rbrakk>
  \<Longrightarrow> P,E \<turnstile>1 a\<lfloor>i\<rceil> := e :: Void"

| WT1ALength:
  "P,E \<turnstile>1 a :: T\<lfloor>\<rceil> \<Longrightarrow> P,E \<turnstile>1 a\<bullet>length :: Integer"

| WTFAcc1:
  "\<lbrakk> P,E \<turnstile>1 e :: Class C;  P \<turnstile> C sees F:T in D \<rbrakk>
  \<Longrightarrow> P,E \<turnstile>1 e\<bullet>F{D} :: T"

| WTFAss1:
  "\<lbrakk> P,E \<turnstile>1 e1 :: Class C;  P \<turnstile> C sees F:T in D;  P,E \<turnstile>1 e2 :: T';  P \<turnstile> T' \<le> T \<rbrakk>
  \<Longrightarrow> P,E \<turnstile>1 e1\<bullet>F{D} := e2 :: Void"

| WT1Call:
  "\<lbrakk> P,E \<turnstile>1 e :: Class C; \<not> is_external_call P (Class C) M (length es); P \<turnstile> C sees M:Ts \<rightarrow> T = m in D;
     P,E \<turnstile>1 es [::] Ts'; P \<turnstile> Ts' [\<le>] Ts \<rbrakk>
  \<Longrightarrow> P,E \<turnstile>1 e\<bullet>M(es) :: T"

| WT1External:
  "\<lbrakk> P,E \<turnstile>1 e :: T; P,E \<turnstile>1 es [::] Ts; P \<turnstile> T\<bullet>M(Ts) :: U \<rbrakk>
  \<Longrightarrow> P,E \<turnstile>1 e\<bullet>M(es) :: U"

| WT1Block:
  "\<lbrakk> is_type P T;  P,E@[T] \<turnstile>1 e :: T'; case vo of None \<Rightarrow> True | \<lfloor>v\<rfloor> \<Rightarrow> \<exists>T'. typeof v = \<lfloor>T'\<rfloor> \<and> P \<turnstile> T' \<le> T \<rbrakk>
  \<Longrightarrow>  P,E \<turnstile>1 {V:T=vo; e}\<^bsub>False\<^esub> :: T'"

| WT1Synchronized:
  "\<lbrakk> P,E \<turnstile>1 o' :: T; is_refT T; T \<noteq> NT; P,E@[Class Object] \<turnstile>1 e :: T' \<rbrakk>
  \<Longrightarrow> P,E \<turnstile>1 sync\<^bsub>V\<^esub> (o') e :: T'"

| WT1Seq:
  "\<lbrakk> P,E \<turnstile>1 e\<^isub>1::T\<^isub>1;  P,E \<turnstile>1 e\<^isub>2::T\<^isub>2 \<rbrakk>
  \<Longrightarrow>  P,E \<turnstile>1 e\<^isub>1;;e\<^isub>2 :: T\<^isub>2"
| WT1Cond:
  "\<lbrakk> P,E \<turnstile>1 e :: Boolean;  P,E \<turnstile>1 e\<^isub>1::T\<^isub>1;  P,E \<turnstile>1 e\<^isub>2::T\<^isub>2;
     P \<turnstile> T\<^isub>1 \<le> T\<^isub>2 \<or> P \<turnstile> T\<^isub>2 \<le> T\<^isub>1;  P \<turnstile> T\<^isub>1 \<le> T\<^isub>2 \<longrightarrow> T = T\<^isub>2;  P \<turnstile> T\<^isub>2 \<le> T\<^isub>1 \<longrightarrow> T = T\<^isub>1 \<rbrakk>
  \<Longrightarrow> P,E \<turnstile>1 if (e) e\<^isub>1 else e\<^isub>2 :: T"

| WT1While:
  "\<lbrakk> P,E \<turnstile>1 e :: Boolean;  P,E \<turnstile>1 c::T \<rbrakk>
  \<Longrightarrow> P,E \<turnstile>1 while (e) c :: Void"

| WT1Throw:
  "\<lbrakk> P,E \<turnstile>1 e :: Class C; P \<turnstile> C \<preceq>\<^sup>* Throwable \<rbrakk> \<Longrightarrow> 
  P,E \<turnstile>1 throw e :: Void"

| WT1Try:
  "\<lbrakk> P,E \<turnstile>1 e\<^isub>1 :: T;  P,E@[Class C] \<turnstile>1 e\<^isub>2 :: T; is_class P C \<rbrakk>
  \<Longrightarrow> P,E \<turnstile>1 try e\<^isub>1 catch(C V) e\<^isub>2 :: T"

| WT1Nil: "P,E \<turnstile>1 [] [::] []"

| WT1Cons: "\<lbrakk> P,E \<turnstile>1 e :: T; P,E \<turnstile>1 es [::] Ts \<rbrakk> \<Longrightarrow> P,E \<turnstile>1 e#es [::] T#Ts"

declare  WT1_WTs1.intros[intro!]
declare WT1Nil[iff]
declare WT1Call[rule del, intro]
declare WT1External[rule del, intro]

inductive_cases WT1_WTs1_cases[elim!]:
  "P,E \<turnstile>1 Val v :: T"
  "P,E \<turnstile>1 Var i :: T"
  "P,E \<turnstile>1 Cast D e :: T"
  "P,E \<turnstile>1 i:=e :: T"
  "P,E \<turnstile>1 {i:U=vo; e}\<^bsub>cr\<^esub> :: T"
  "P,E \<turnstile>1 e1;;e2 :: T"
  "P,E \<turnstile>1 if (e) e1 else e2 :: T"
  "P,E \<turnstile>1 while (e) c :: T"
  "P,E \<turnstile>1 throw e :: T"
  "P,E \<turnstile>1 try e1 catch(C i) e2 :: T"
  "P,E \<turnstile>1 e\<bullet>F{D} :: T"
  "P,E \<turnstile>1 e1\<bullet>F{D}:=e2 :: T"
  "P,E \<turnstile>1 e1 \<guillemotleft>bop\<guillemotright> e2 :: T"
  "P,E \<turnstile>1 new C :: T"
  "P,E \<turnstile>1 newA T'\<lfloor>e\<rceil> :: T"
  "P,E \<turnstile>1 a\<lfloor>i\<rceil> := e :: T"
  "P,E \<turnstile>1 a\<lfloor>i\<rceil> :: T"
  "P,E \<turnstile>1 a\<bullet>length :: T"
  "P,E \<turnstile>1 e\<bullet>M(es) :: T"
  "P,E \<turnstile>1 sync\<^bsub>V\<^esub> (o') e :: T"
  "P,E \<turnstile>1 insync\<^bsub>V\<^esub> (a) e :: T"
  "P,E \<turnstile>1 [] [::] Ts"
  "P,E \<turnstile>1 e#es [::] Ts"

lemma WTs1_same_size: "P,E \<turnstile>1 es [::] Ts \<Longrightarrow> size es = size Ts"
by (induct es arbitrary: Ts) auto

lemma assumes wf: "wf_prog wfmd P"
  shows WT1_unique: "P,E \<turnstile>1 e :: T1 \<Longrightarrow> P,E \<turnstile>1 e :: T2 \<Longrightarrow> T1 = T2" 
  and WTs1_unique: "P,E \<turnstile>1 es [::] Ts1 \<Longrightarrow> P,E \<turnstile>1 es [::] Ts2 \<Longrightarrow> Ts1 = Ts2"
apply(induct arbitrary: T2 and Ts2 rule:WT1_WTs1.inducts)
apply blast
apply blast
apply blast
apply clarsimp
apply blast
apply blast
apply blast
apply blast
apply blast
apply blast
apply blast
apply (blast dest:sees_field_idemp sees_field_fun)
apply blast

apply(erule WT1_WTs1_cases)
 apply (blast dest:sees_method_idemp sees_method_fun)
apply(fastsimp dest: external_WT_is_external_call list_all2_lengthD WTs1_same_size)

apply(fastsimp dest: external_WT_is_external_call list_all2_lengthD WTs1_same_size external_WT_determ)
apply blast
apply blast
apply blast
apply blast
apply blast
apply blast
apply blast
apply blast
apply blast
done



lemma assumes wf: "wf_prog p P"
  shows WT1_is_type: "P,E \<turnstile>1 e :: T \<Longrightarrow> set E \<subseteq> is_type P \<Longrightarrow> is_type P T"
  and "P,E \<turnstile>1 es [::] Ts \<Longrightarrow> set E \<subseteq> is_type P \<Longrightarrow> set Ts \<subseteq> is_type P"
apply(induct rule:WT1_WTs1.inducts)
apply simp
apply simp
apply simp
apply (simp add:typeof_lit_is_type)
apply (fastsimp intro:nth_mem simp add: mem_def)
apply(simp)
apply(simp)
apply(simp)
apply(simp)
apply(simp)
apply(simp)
apply (simp add:sees_field_is_type[OF _ wf])
apply simp
apply(fastsimp dest!: sees_wf_mdecl[OF wf] simp:wf_mdecl_def)
apply(fastsimp dest: WT_external_is_type)
apply(simp add: mem_def)
apply(simp add: is_class_Object[OF wf] mem_def)
apply simp
apply blast
apply simp
apply simp
apply simp
apply simp
apply(simp add: mem_def)
done

lemma WT1_noRetBlock: "P,E \<turnstile>1 e :: T \<Longrightarrow> noRetBlock e"
  and WTs1_noRetBlocks: "P,E \<turnstile>1 es [::] Ts \<Longrightarrow> noRetBlocks es"
by(induct rule: WT1_WTs1.inducts) auto

subsection{* Well-formedness*}

--"Indices in blocks increase by 1"

consts
  \<B> :: "expr1 \<Rightarrow> nat \<Rightarrow> bool"
  \<B>s :: "expr1 list \<Rightarrow> nat \<Rightarrow> bool"
primrec
"\<B> (new C) i = True"
"\<B> (newA T\<lfloor>e\<rceil>) i = \<B> e i"
"\<B> (Cast C e) i = \<B> e i"
"\<B> (Val v) i = True"
"\<B> (e1 \<guillemotleft>bop\<guillemotright> e2) i = (\<B> e1 i \<and> \<B> e2 i)"
"\<B> (Var j) i = True"
"\<B> (j:=e) i = \<B> e i"
"\<B> (a\<lfloor>j\<rceil>) i = (\<B> a i \<and> \<B> j i)"
"\<B> (a\<lfloor>j\<rceil>:=e) i = (\<B> a i \<and> \<B> j i \<and> \<B> e i)"
"\<B> (a\<bullet>length) i = \<B> a i"
"\<B> (e\<bullet>F{D}) i = \<B> e i"
"\<B> (e1\<bullet>F{D} := e2) i = (\<B> e1 i \<and> \<B> e2 i)"
"\<B> (e\<bullet>M(es)) i = (\<B> e i \<and> \<B>s es i)"
"\<B> ({j:T=vo; e}\<^bsub>cr\<^esub>) i = (i = j \<and> \<B> e (i+1))"
"\<B> (sync\<^bsub>V\<^esub> (o') e) i = (i = V \<and> \<B> o' i \<and> \<B> e (i+1))"
"\<B> (insync\<^bsub>V\<^esub> (a) e) i = (i = V \<and> \<B> e (i+1))"
"\<B> (e1;;e2) i = (\<B> e1 i \<and> \<B> e2 i)"
"\<B> (if (e) e1 else e2) i = (\<B> e i \<and> \<B> e1 i \<and> \<B> e2 i)"
"\<B> (throw e) i = \<B> e i"
"\<B> (while (e) c) i = (\<B> e i \<and> \<B> c i)"
"\<B> (try e1 catch(C j) e2) i = (\<B> e1 i \<and> i=j \<and> \<B> e2 (i+1))"

"\<B>s [] i = True"
"\<B>s (e#es) i = (\<B> e i \<and> \<B>s es i)"

lemma Bs_append [simp]: "\<B>s (es @ es') n \<longleftrightarrow> \<B>s es n \<and> \<B>s es' n"
by(induct es) auto

lemma Bs_map_Val [simp]: "\<B>s (map Val vs) n"
by(induct vs) auto

primrec syncvars :: "('a, 'a) exp \<Rightarrow> bool"
  and syncvarss :: "('a, 'a) exp list \<Rightarrow> bool"
where
  "syncvars (new C) = True"
| "syncvars (newA T\<lfloor>e\<rceil>) = syncvars e"
| "syncvars (Cast T e) = syncvars e"
| "syncvars (Val v) = True"
| "syncvars (e1 \<guillemotleft>bop\<guillemotright> e2) = (syncvars e1 \<and> syncvars e2)"
| "syncvars (Var V) = True"
| "syncvars (V:=e) = syncvars e"
| "syncvars (a\<lfloor>i\<rceil>) = (syncvars a \<and> syncvars i)"
| "syncvars (a\<lfloor>i\<rceil> := e) = (syncvars a \<and> syncvars i \<and> syncvars e)"
| "syncvars (a\<bullet>length) = syncvars a"
| "syncvars (e\<bullet>F{D}) = syncvars e"
| "syncvars (e\<bullet>F{D} := e2) = (syncvars e \<and> syncvars e2)"
| "syncvars (e\<bullet>M(es)) = (syncvars e \<and> syncvarss es)"
| "syncvars {V:T=vo;e}\<^bsub>cr\<^esub> = syncvars e"
| "syncvars (sync\<^bsub>V\<^esub> (e1) e2) = (syncvars e1 \<and> syncvars e2 \<and> V \<notin> fv e2)"
| "syncvars (insync\<^bsub>V\<^esub> (a) e) = (syncvars e \<and> V \<notin> fv e)"
| "syncvars (e1;;e2) = (syncvars e1 \<and> syncvars e2)"
| "syncvars (if (b) e1 else e2) = (syncvars b \<and> syncvars e1 \<and> syncvars e2)"
| "syncvars (while (b) c) = (syncvars b \<and> syncvars c)"
| "syncvars (throw e) = syncvars e"
| "syncvars (try e1 catch(C V) e2) = (syncvars e1 \<and> syncvars e2)"

| "syncvarss [] = True"
| "syncvarss (e#es) = (syncvars e \<and> syncvarss es)"

lemma syncvarss_append [simp]: "syncvarss (es @ es') \<longleftrightarrow> syncvarss es \<and> syncvarss es'"
by(induct es) auto

lemma noRetBlock_blocks1 [simp]: "noRetBlock (blocks1 n Ts e) = noRetBlock e"
by(induct Ts arbitrary: n e) auto


definition bsok :: "expr1 \<Rightarrow> nat \<Rightarrow> bool"
where "bsok e n \<equiv> \<B> e n \<and> expr_locks e = (\<lambda>ad. 0) \<and> noRetBlock e"

definition bsoks :: "expr1 list \<Rightarrow> nat \<Rightarrow> bool"
where "bsoks es n \<equiv> \<B>s es n \<and> expr_lockss es = (\<lambda>ad. 0) \<and> noRetBlocks es"

lemma bsok_simps [simp]:
  "bsok (new C) n = True"
  "bsok (newA T\<lfloor>e\<rceil>) n = bsok e n"
  "bsok (Cast T e) n = bsok e n"
  "bsok (e1 \<guillemotleft>bop\<guillemotright> e2) n = (bsok e1 n \<and> bsok e2 n)"
  "bsok (Var V) n = True"
  "bsok (Val v) n = True"
  "bsok (V := e) n = bsok e n"
  "bsok (a\<lfloor>i\<rceil>) n = (bsok a n \<and> bsok i n)"
  "bsok (a\<lfloor>i\<rceil> := e) n = (bsok a n \<and> bsok i n \<and> bsok e n)"
  "bsok (a\<bullet>length) n = bsok a n"
  "bsok (e\<bullet>F{D}) n = bsok e n"
  "bsok (e\<bullet>F{D} := e') n = (bsok e n \<and> bsok e' n)"
  "bsok (e\<bullet>M(ps)) n = (bsok e n \<and> bsoks ps n)"
  "bsok {V:T=vo; e}\<^bsub>cr\<^esub> n = (bsok e (Suc n) \<and> V = n \<and> \<not> cr)"
  "bsok (sync\<^bsub>V\<^esub> (e) e') n = (bsok e n \<and> bsok e' (Suc n) \<and> V = n)"
  "bsok (insync\<^bsub>V\<^esub> (ad) e) n = False"
  "bsok (e;; e') n = (bsok e n \<and> bsok e' n)"
  "bsok (if (e) e1 else e2) n = (bsok e n \<and> bsok e1 n \<and> bsok e2 n)"
  "bsok (while (b) c) n = (bsok b n \<and> bsok c n)"
  "bsok (throw e) n = bsok e n"
  "bsok (try e catch(C V) e') n = (bsok e n \<and> bsok e' (Suc n) \<and> V = n)"
  and bsoks_simps [simp]:
  "bsoks [] n = True"
  "bsoks (e # es) n = (bsok e n \<and> bsoks es n)"
by(auto simp add: bsok_def bsoks_def expand_fun_eq)



constdefs
  wf_J1_mdecl :: "J1_prog \<Rightarrow> cname \<Rightarrow> expr1 mdecl \<Rightarrow> bool"
  "wf_J1_mdecl P C  \<equiv>  \<lambda>(M,Ts,T,body).
    (\<exists>T'. P,Class C#Ts \<turnstile>1 body :: T' \<and> P \<turnstile> T' \<le> T) \<and>
    \<D> body \<lfloor>{..size Ts}\<rfloor> \<and> \<B> body (size Ts + 1) \<and> syncvars body"

lemma wf_J1_mdecl[simp]:
  "wf_J1_mdecl P C (M,Ts,T,body) \<equiv>
    ((\<exists>T'. P,Class C#Ts \<turnstile>1 body :: T' \<and> P \<turnstile> T' \<le> T) \<and>
     \<D> body \<lfloor>{..size Ts}\<rfloor> \<and> \<B> body (size Ts + 1)) \<and> syncvars body"
by (simp add:wf_J1_mdecl_def)

syntax
  wf_J1_prog :: "J1_prog \<Rightarrow> bool"

translations
  "wf_J1_prog"  ==  "wf_prog wf_J1_mdecl"

inductive WTrt1 :: "J1_prog \<Rightarrow> heap \<Rightarrow> env1 \<Rightarrow> expr1 \<Rightarrow> ty \<Rightarrow> bool"
  and WTrts1 :: "J1_prog \<Rightarrow> heap \<Rightarrow> env1 \<Rightarrow> expr1 list \<Rightarrow> ty list \<Rightarrow> bool"
  and WTrt1_syntax :: "J1_prog \<Rightarrow> env1 \<Rightarrow> heap \<Rightarrow> expr1 \<Rightarrow> ty \<Rightarrow> bool" ("_,_,_ \<turnstile>1 _ : _"   [51,0,0,0,51] 50)
  and WTrts1_syntax :: "J1_prog \<Rightarrow> env1 \<Rightarrow> heap \<Rightarrow> expr1 list \<Rightarrow> ty list \<Rightarrow> bool" ("_,_,_ \<turnstile>1 _ [:] _"   [51,0,0,0,51] 50)
  for P :: J1_prog and h :: heap
  where

  "P,E,h \<turnstile>1 e : T \<equiv> WTrt1 P h E e T"
| "P,E,h \<turnstile>1 es [:] Ts \<equiv> WTrts1 P h E es Ts"

|  WTrt1New:
  "is_class P C  \<Longrightarrow>
  P,E,h \<turnstile>1 new C : Class C"

| WTrt1NewArray:
  "\<lbrakk> P,E,h \<turnstile>1 e : Integer; is_type P T \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 newA T\<lfloor>e\<rceil> : T\<lfloor>\<rceil>"

| WTrt1Cast:
  "\<lbrakk> P,E,h \<turnstile>1 e : T; is_type P U \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 Cast U e : U"

| WTrt1Val:
  "typeof\<^bsub>h\<^esub> v = Some T \<Longrightarrow>
  P,E,h \<turnstile>1 Val v : T"

| WTrt1Var:
  "\<lbrakk> E!V = T; V < size E \<rbrakk> \<Longrightarrow>
  P,E,h \<turnstile>1 Var V : T"

| WTrt1BinOpEq:
  "\<lbrakk> P,E,h \<turnstile>1 e1 : T1;  P,E,h \<turnstile>1 e2 : T2 \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 e1 \<guillemotleft>Eq\<guillemotright> e2 : Boolean"

| WTrt1BinOpAdd:
  "\<lbrakk> P,E,h \<turnstile>1 e1 : Integer;  P,E,h \<turnstile>1 e2 : Integer \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 e1 \<guillemotleft>Add\<guillemotright> e2 : Integer"

| WTrt1LAss:
  "\<lbrakk> E!i = T; i < size E; P,E,h \<turnstile>1 e : T';  P \<turnstile> T' \<le> T \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 i:=e : Void"

| WTrt1AAcc:
  "\<lbrakk> P,E,h \<turnstile>1 a : T\<lfloor>\<rceil>; P,E,h \<turnstile>1 i : Integer \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 a\<lfloor>i\<rceil> : T"

| WTrt1AAccNT:
  "\<lbrakk> P,E,h \<turnstile>1 a : NT; P,E,h \<turnstile>1 i : Integer \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 a\<lfloor>i\<rceil> : T"

| WTrt1AAss:
  "\<lbrakk> P,E,h \<turnstile>1 a : T\<lfloor>\<rceil>; P,E,h \<turnstile>1 i : Integer; P,E,h \<turnstile>1 e : T' \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 a\<lfloor>i\<rceil> := e : Void"

| WTrt1AAssNT:
  "\<lbrakk> P,E,h \<turnstile>1 a : NT; P,E,h \<turnstile>1 i : Integer; P,E,h \<turnstile>1 e : T' \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 a\<lfloor>i\<rceil> := e : Void"

| WTrt1ALength:
  "P,E,h \<turnstile>1 a : T\<lfloor>\<rceil> \<Longrightarrow> P,E,h \<turnstile>1 a\<bullet>length : Integer"

| WTrt1ALengthNT:
  "P,E,h \<turnstile>1 a : NT \<Longrightarrow> P,E,h \<turnstile>1 a\<bullet>length : T"

| WTrt1FAcc:
  "\<lbrakk> P,E,h \<turnstile>1 e : Class C; P \<turnstile> C has F:T in D \<rbrakk> \<Longrightarrow>
  P,E,h \<turnstile>1 e\<bullet>F{D} : T"

| WTrt1FAccNT:
    "P,E,h \<turnstile>1 e : NT \<Longrightarrow> P,E,h \<turnstile>1 e\<bullet>F{D} : T"

| WTrt1FAss:
  "\<lbrakk> P,E,h \<turnstile>1 e1 : Class C; P \<turnstile> C has F:T in D; P,E,h \<turnstile>1 e2 : T2;  P \<turnstile> T2 \<le> T \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 e1\<bullet>F{D}:=e2 : Void"

| WTrt1FAssNT:
  "\<lbrakk> P,E,h \<turnstile>1 e1 : NT; P,E,h \<turnstile>1 e2 : T2 \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 e1\<bullet>F{D}:=e2 : Void"

| WTrt1Call:
  "\<lbrakk> P,E,h \<turnstile>1 e : Class C; \<not> is_external_call P (Class C) M (length es); P \<turnstile> C sees M:Ts' \<rightarrow> T = m in D;
    P,E,h \<turnstile>1 es [:] Ts;  P \<turnstile> Ts [\<le>] Ts' \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 e\<bullet>M(es) : T"

| WTrt1CallNT:
  "\<lbrakk> P,E,h \<turnstile>1 e : NT; P,E,h \<turnstile>1 es [:] Ts \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 e\<bullet>M(es) : T"

| WTrt1CallExternal:
    "\<lbrakk> P,E,h \<turnstile>1 e : T; P,E,h \<turnstile>1 es [:] Ts; P \<turnstile> T\<bullet>M(Ts) :: U \<rbrakk>
    \<Longrightarrow> P,E,h \<turnstile>1 e\<bullet>M(es) : U"

| WTrt1Block:
  "\<lbrakk> P,(E@[T]),h \<turnstile>1 e : T'; case vo of None \<Rightarrow> True | \<lfloor>v\<rfloor> \<Rightarrow> \<exists>T'. typeof\<^bsub>h\<^esub> v = \<lfloor>T'\<rfloor> \<and> P \<turnstile> T' \<le> T \<rbrakk>
  \<Longrightarrow>  P,E,h \<turnstile>1 {V:T=vo; e}\<^bsub>cr\<^esub> : T'"

| WTrt1Synchronized:
  "\<lbrakk> P,E,h \<turnstile>1 o' : T; is_refT T; T \<noteq> NT; P,(E@[Class Object]),h \<turnstile>1 e : T' \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 sync\<^bsub>V\<^esub> (o') e : T'"

| WTrt1SynchronizedNT:
  "\<lbrakk> P,E,h \<turnstile>1 o' : NT; P,(E@[Class Object]),h \<turnstile>1 e : T' \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 sync\<^bsub>V\<^esub> (o') e : T"

| WTrt1InSynchronized:
  "\<lbrakk> P,E,h \<turnstile>1 addr a : T; P,(E@[Class Object]),h \<turnstile>1 e : T' \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 insync\<^bsub>V\<^esub> (a) e : T'"

| WTrt1Seq:
  "\<lbrakk> P,E,h \<turnstile>1 e1 : T1; P,E,h \<turnstile>1 e2 : T2 \<rbrakk>
  \<Longrightarrow>  P,E,h \<turnstile>1 e1;;e2 : T2"

| WTrt1Cond:
  "\<lbrakk> P,E,h \<turnstile>1 e : Boolean;  P,E,h \<turnstile>1 e1 : T1;  P,E,h \<turnstile>1 e2 : T2;
     P \<turnstile> T1 \<le> T2 \<or> P \<turnstile> T2 \<le> T1;  P \<turnstile> T1 \<le> T2 \<longrightarrow> T = T2; P \<turnstile> T2 \<le> T1 \<longrightarrow> T = T1 \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 if (e) e1 else e2 : T"

| WTrt1While:
  "\<lbrakk> P,E,h \<turnstile>1 e : Boolean;  P,E,h \<turnstile>1 c : T \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 while (e) c : Void"

| WTrt1Throw:
  "\<lbrakk> P,E,h \<turnstile>1 e : T'; P \<turnstile> T' \<le> Class Throwable \<rbrakk> \<Longrightarrow> 
  P,E,h \<turnstile>1 throw e : T"

| WTrt1Try:
  "\<lbrakk> P,E,h \<turnstile>1 e1 : T1;  P,(E@[Class C]),h \<turnstile>1 e2 : T2; P \<turnstile> T1 \<le> T2 \<rbrakk>
  \<Longrightarrow> P,E,h \<turnstile>1 try e1 catch(C V) e2 : T2"

| WTrt1Nil: "P,E,h \<turnstile>1 [] [:] []"

| WTrt1Cons: "\<lbrakk> P,E,h \<turnstile>1 e : T; P,E,h \<turnstile>1 es [:] Ts \<rbrakk> \<Longrightarrow> P,E,h \<turnstile>1 e#es [:] T#Ts"

declare WTrt1_WTrts1.intros[intro!]
declare WT1Nil[iff]

declare 
  WTrt1AAcc[rule del, intro] WTrt1AAccNT[rule del, intro]
  WTrt1AAss[rule del, intro] WTrt1AAssNT[rule del, intro]
  WTrt1ALength[rule del, intro] WTrt1ALengthNT[rule del, intro]  
  WTrt1FAcc[rule del, intro] WTrt1FAccNT[rule del, intro]
  WTrt1FAss[rule del, intro] WTrt1FAssNT[rule del, intro]
  WTrt1Call[rule del, intro] WTrt1CallNT[rule del, intro]
  WTrt1CallExternal[rule del, intro]
  WTrt1Synchronized[rule del, intro]
  WTrt1SynchronizedNT[rule del, intro]

inductive_cases WTrt1_WTrts1_cases[elim!]:
  "P,E,h \<turnstile>1 Val v : T"
  "P,E,h \<turnstile>1 Var i : T"
  "P,E,h \<turnstile>1 i:=e : T"
  "P,E,h \<turnstile>1 {i:U=vo; e}\<^bsub>cr\<^esub> : T"
  "P,E,h \<turnstile>1 e1;;e2 : T"
  "P,E,h \<turnstile>1 if (e) e1 else e2 : T"
  "P,E,h \<turnstile>1 while (e) c : T"
  "P,E,h \<turnstile>1 throw e : T"
  "P,E,h \<turnstile>1 try e1 catch(C i) e2 : T"
  "P,E,h \<turnstile>1 e1 \<guillemotleft>bop\<guillemotright> e2 : T"
  "P,E,h \<turnstile>1 new C : T"
  "P,E,h \<turnstile>1 e\<bullet>M(es) : T"
  "P,E,h \<turnstile>1 sync\<^bsub>V\<^esub> (o') e : T"
  "P,E,h \<turnstile>1 insync\<^bsub>V\<^esub> (a) e : T"
  "P,E,h \<turnstile>1 Cast U e : T"
  "P,E,h \<turnstile>1 newA T\<lfloor>e\<rceil> : T'"
  "P,E,h \<turnstile>1 a\<lfloor>i\<rceil> : T"
  "P,E,h \<turnstile>1 a\<lfloor>i\<rceil> := e : T"
  "P,E,h \<turnstile>1 a\<bullet>length : T"
  "P,E,h \<turnstile>1 e\<bullet>F{D} : T"
  "P,E,h \<turnstile>1 e\<bullet>F{D} := e' : T"
  "P,E,h \<turnstile>1 [] [:] Ts"
  "P,E,h \<turnstile>1 e#es [:] Ts"

lemma WTrts1_same_size: "P,E,h \<turnstile>1 es [:] Ts \<Longrightarrow> size es = size Ts"
apply (induct es arbitrary: Ts) 
apply auto
done

lemma WTrts1_Val[simp]:
 "P,E,h \<turnstile>1 map Val vs [:] Ts \<longleftrightarrow> map (typeof\<^bsub>h\<^esub>) vs = map Some Ts"
by(induct vs arbitrary: Ts) auto

lemma WTrts1_append [simp]:
  "P,E,h \<turnstile>1 es @ es' [:] Ts \<longleftrightarrow> P,E,h \<turnstile>1 es [:] take (length es) Ts \<and> P,E,h \<turnstile>1 es' [:] drop (length es) Ts"
apply(induct es arbitrary: Ts)
apply auto
apply(case_tac Ts)
apply(auto)
done


lemma WT1_imp_WTrt1: "P,E \<turnstile>1 e :: T \<Longrightarrow> P,E,h \<turnstile>1 e : T"
  and WTs1_imp_WTrts1: "P,E \<turnstile>1 es [::] Ts \<Longrightarrow> P,E,h \<turnstile>1 es [:] Ts"
apply(induct rule: WT1_WTs1.inducts)
apply(auto intro: typeof_lit_typeof has_visible_field)
apply(blast intro: typeof_lit_typeof)
done

lemma WTrt1_hext_mono: "\<lbrakk> P,E,h \<turnstile>1 e : T; hext h h' \<rbrakk> \<Longrightarrow> P,E,h' \<turnstile>1 e : T"
  and WTrts1_hext_mono: "\<lbrakk> P,E,h \<turnstile>1 es [:] Ts; hext h h' \<rbrakk> \<Longrightarrow> P,E,h' \<turnstile>1 es [:] Ts"
apply(induct rule: WTrt1_WTrts1.inducts)
apply(auto elim!: hext_typeof_mono)
done



end