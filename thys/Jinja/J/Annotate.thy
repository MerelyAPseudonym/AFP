(*  Title:      Jinja/J/Annotate.thy
    ID:         $Id: Annotate.thy,v 1.2 2005-09-06 15:06:08 makarius Exp $
    Author:     Tobias Nipkow
    Copyright   2003 Technische Universitaet Muenchen
*)

header {* \isaheader{Program annotation} *}

theory Annotate imports WellType begin

(*<*)
syntax (output)
  unanFAcc :: "expr \<Rightarrow> vname \<Rightarrow> expr" ("(_\<bullet>_)" [10,10] 90)
  unanFAss :: "expr \<Rightarrow> vname \<Rightarrow> expr \<Rightarrow> expr" ("(_\<bullet>_ := _)" [10,0,90] 90)

translations
  "unanFAcc e F" == "FAcc e F []"
  "unanFAss e F e'" == "FAss e F [] e'"
(*>*)

consts
  Anno :: "J_prog \<Rightarrow> (env \<times> expr      \<times> expr) set"
  Annos:: "J_prog \<Rightarrow> (env \<times> expr list \<times> expr list) set"

(*<*)
syntax (xsymbols)
  Anno :: "[J_prog,env, expr     , expr] \<Rightarrow> bool"
         ("_,_ \<turnstile> _ \<leadsto> _"   [51,0,0,51]50)
  Annos:: "[J_prog,env, expr list, expr list] \<Rightarrow> bool"
         ("_,_ \<turnstile> _ [\<leadsto>] _" [51,0,0,51]50)
(*>*)

translations
  "P,E \<turnstile> e \<leadsto> e'" == "(E,e,e') \<in> Anno P"
  "P,E \<turnstile> es [\<leadsto>] es'" == "(E,es,es') \<in> Annos P"

inductive "Anno P" "Annos P"
intros
  
AnnoNew: "P,E \<turnstile> new C \<leadsto> new C"
AnnoCast: "P,E \<turnstile> e \<leadsto> e' \<Longrightarrow> P,E \<turnstile> Cast C e \<leadsto> Cast C e'"
AnnoVal: "P,E \<turnstile> Val v \<leadsto> Val v"
AnnoVarVar: "E V = \<lfloor>T\<rfloor> \<Longrightarrow> P,E \<turnstile> Var V \<leadsto> Var V"
AnnoVarField: "\<lbrakk> E V = None; E this = \<lfloor>Class C\<rfloor>; P \<turnstile> C sees V:T in D \<rbrakk>
               \<Longrightarrow> P,E \<turnstile> Var V \<leadsto> Var this\<bullet>V{D}"
AnnoBinOp:
  "\<lbrakk> P,E \<turnstile> e1 \<leadsto> e1';  P,E \<turnstile> e2 \<leadsto> e2' \<rbrakk>
   \<Longrightarrow> P,E \<turnstile> e1 \<guillemotleft>bop\<guillemotright> e2 \<leadsto> e1' \<guillemotleft>bop\<guillemotright> e2'"
AnnoLAssVar:
  "\<lbrakk> E V = \<lfloor>T\<rfloor>; P,E \<turnstile> e \<leadsto> e' \<rbrakk> \<Longrightarrow> P,E \<turnstile> V:=e \<leadsto> V:=e'"
AnnoLAssField:
  "\<lbrakk> E V = None; E this = \<lfloor>Class C\<rfloor>; P \<turnstile> C sees V:T in D; P,E \<turnstile> e \<leadsto> e' \<rbrakk>
   \<Longrightarrow> P,E \<turnstile> V:=e \<leadsto> Var this\<bullet>V{D} := e'"
AnnoFAcc:
  "\<lbrakk> P,E \<turnstile> e \<leadsto> e';  P,E \<turnstile> e' :: Class C;  P \<turnstile> C sees F:T in D \<rbrakk>
   \<Longrightarrow> P,E \<turnstile> e\<bullet>F{[]} \<leadsto> e'\<bullet>F{D}"
AnnoFAss: "\<lbrakk> P,E \<turnstile> e1 \<leadsto> e1';  P,E \<turnstile> e2 \<leadsto> e2';
             P,E \<turnstile> e1' :: Class C; P \<turnstile> C sees F:T in D \<rbrakk>
          \<Longrightarrow> P,E \<turnstile> e1\<bullet>F{[]} := e2 \<leadsto> e1'\<bullet>F{D} := e2'"
AnnoCall:
  "\<lbrakk> P,E \<turnstile> e \<leadsto> e';  P,E \<turnstile> es [\<leadsto>] es' \<rbrakk>
   \<Longrightarrow> P,E \<turnstile> Call e M es \<leadsto> Call e' M es'"
AnnoBlock:
  "P,E(V \<mapsto> T) \<turnstile> e \<leadsto> e'  \<Longrightarrow>  P,E \<turnstile> {V:T; e} \<leadsto> {V:T; e'}"
AnnoComp: "\<lbrakk> P,E \<turnstile> e1 \<leadsto> e1';  P,E \<turnstile> e2 \<leadsto> e2' \<rbrakk>
           \<Longrightarrow>  P,E \<turnstile> e1;;e2 \<leadsto> e1';;e2'"
AnnoCond: "\<lbrakk> P,E \<turnstile> e \<leadsto> e'; P,E \<turnstile> e1 \<leadsto> e1';  P,E \<turnstile> e2 \<leadsto> e2' \<rbrakk>
          \<Longrightarrow> P,E \<turnstile> if (e) e1 else e2 \<leadsto> if (e') e1' else e2'"
AnnoLoop: "\<lbrakk> P,E \<turnstile> e \<leadsto> e';  P,E \<turnstile> c \<leadsto> c' \<rbrakk>
          \<Longrightarrow> P,E \<turnstile> while (e) c \<leadsto> while (e') c'"
AnnoThrow: "P,E \<turnstile> e \<leadsto> e'  \<Longrightarrow>  P,E \<turnstile> throw e \<leadsto> throw e'"
AnnoTry: "\<lbrakk> P,E \<turnstile> e1 \<leadsto> e1';  P,E(V \<mapsto> Class C) \<turnstile> e2 \<leadsto> e2' \<rbrakk>
         \<Longrightarrow> P,E \<turnstile> try e1 catch(C V) e2 \<leadsto> try e1' catch(C V) e2'"

AnnoNil: "P,E \<turnstile> [] [\<leadsto>] []"
AnnoCons: "\<lbrakk> P,E \<turnstile> e \<leadsto> e';  P,E \<turnstile> es [\<leadsto>] es' \<rbrakk>
           \<Longrightarrow>  P,E \<turnstile> e#es [\<leadsto>] e'#es'"

end