(*  Title:      Jinja/J/JWellForm.thy
    ID:         $Id: JWellForm.thy,v 1.1 2005-05-31 23:21:04 lsf37 Exp $
    Author:     Tobias Nipkow
    Copyright   2003 Technische Universitaet Muenchen
*)

header {* \isaheader{Well-formedness Constraints} *}

theory JWellForm
imports "../Common/WellForm" WWellForm WellType DefAss
begin

constdefs
  wf_J_mdecl :: "J_prog \<Rightarrow> cname \<Rightarrow> J_mb mdecl \<Rightarrow> bool"
  "wf_J_mdecl P C  \<equiv>  \<lambda>(M,Ts,T,(pns,body)).
  length Ts = length pns \<and>
  distinct pns \<and>
  this \<notin> set pns \<and>
  (\<exists>T'. P,[this\<mapsto>Class C,pns[\<mapsto>]Ts] \<turnstile> body :: T' \<and> P \<turnstile> T' \<le> T) \<and>
  \<D> body \<lfloor>{this} \<union> set pns\<rfloor>"

lemma wf_J_mdecl[simp]:
  "wf_J_mdecl P C (M,Ts,T,pns,body) \<equiv>
  (length Ts = length pns \<and>
  distinct pns \<and>
  this \<notin> set pns \<and>
  (\<exists>T'. P,[this\<mapsto>Class C,pns[\<mapsto>]Ts] \<turnstile> body :: T' \<and> P \<turnstile> T' \<le> T) \<and>
  \<D> body \<lfloor>{this} \<union> set pns\<rfloor>)"
(*<*)by(simp add:wf_J_mdecl_def)(*>*)


syntax 
  wf_J_prog :: "J_prog \<Rightarrow> bool"
translations
  "wf_J_prog"  ==  "wf_prog wf_J_mdecl"

lemma wf_J_prog_wf_J_mdecl:
  "\<lbrakk> wf_J_prog P; (C, D, fds, mths) \<in> set P; jmdcl \<in> set mths \<rbrakk>
  \<Longrightarrow> wf_J_mdecl P C jmdcl"
(*<*)
apply (simp add: wf_prog_def)
apply (simp add: wf_cdecl_def)
apply (erule conjE)+
apply (drule bspec, assumption)
apply simp
apply (erule conjE)+
apply (drule bspec, assumption)
apply (simp add: wf_mdecl_def split_beta)
done
(*>*)


lemma wf_mdecl_wwf_mdecl: "wf_J_mdecl P C Md \<Longrightarrow> wwf_J_mdecl P C Md"
(*<*)by(fastsimp simp:wwf_J_mdecl_def dest!:WT_fv)(*>*)


lemma wf_prog_wwf_prog: "wf_J_prog P \<Longrightarrow> wwf_J_prog P"
(*<*)
apply(simp add:wf_prog_def wf_cdecl_def wf_mdecl_def)
apply(fast intro:wf_mdecl_wwf_mdecl)
done
(*>*)


end
