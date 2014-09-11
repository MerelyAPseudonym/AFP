theory SINVAR_SecGwExt
imports "../TopoS_Helper"
begin

subsection {* SecurityInvariant SecurityGatewayExtended*}
text {* Like SecurityGateway but SecurityGatewayIN and AccessibleMember are accessible from outside world *}

datatype_new secgw_member = SecurityGateway | SecurityGatewayIN | DomainMember  | AccessibleMember | Unassigned

definition default_node_properties :: "secgw_member"
  where  "default_node_properties \<equiv> Unassigned"


fun allowed_secgw_flow :: "secgw_member \<Rightarrow> secgw_member \<Rightarrow> bool" where
  "allowed_secgw_flow SecurityGateway _ = True" |
  "allowed_secgw_flow SecurityGatewayIN _ = True" |
  "allowed_secgw_flow DomainMember DomainMember = False" |
  "allowed_secgw_flow DomainMember _ = True" |
  "allowed_secgw_flow AccessibleMember DomainMember = False" |
  "allowed_secgw_flow AccessibleMember _ = True" |
  "allowed_secgw_flow Unassigned Unassigned = True" |
  "allowed_secgw_flow Unassigned SecurityGatewayIN = True" |
  "allowed_secgw_flow Unassigned AccessibleMember = True" |
  "allowed_secgw_flow Unassigned _ = False" 


fun sinvar :: "'v graph \<Rightarrow> ('v \<Rightarrow> secgw_member) \<Rightarrow> bool" where
  "sinvar G nP = (\<forall> (e1,e2) \<in> edges G. e1 \<noteq> e2 \<longrightarrow> allowed_secgw_flow (nP e1) (nP e2))"

fun verify_globals :: "'v graph \<Rightarrow> ('v \<Rightarrow> secgw_member) \<Rightarrow> 'b \<Rightarrow> bool" where
  "verify_globals _ _ _ = True"

definition receiver_violation :: "bool" where "receiver_violation = False"

subsubsection {*Preliminaries*}
  lemma sinvar_mono: "SecurityInvariant_withOffendingFlows.sinvar_mono sinvar"
    apply(simp only: SecurityInvariant_withOffendingFlows.sinvar_mono_def)
    apply(clarify)
    by auto
  
  interpretation SecurityInvariant_preliminaries
  where sinvar = sinvar
  and verify_globals = verify_globals
    apply unfold_locales
      apply(frule_tac finite_distinct_list[OF valid_graph.finiteE])
      apply(erule_tac exE)
      apply(rename_tac list_edges)
      apply(rule_tac ff="list_edges" in SecurityInvariant_withOffendingFlows.mono_imp_set_offending_flows_not_empty[OF sinvar_mono])
          apply(auto)[6]
     apply(auto simp add: SecurityInvariant_withOffendingFlows.is_offending_flows_def graph_ops)[1]
    apply(fact SecurityInvariant_withOffendingFlows.sinvar_mono_imp_is_offending_flows_mono[OF sinvar_mono])
   done

subsubsection{*ENF*}
  lemma SecurityGateway_ENFnr: "SecurityInvariant_withOffendingFlows.sinvar_all_edges_normal_form_not_refl sinvar allowed_secgw_flow"
    by(simp add: SecurityInvariant_withOffendingFlows.sinvar_all_edges_normal_form_not_refl_def)
  lemma Unassigned_botdefault: "\<forall> e1 e2. e2 \<noteq> Unassigned \<longrightarrow> \<not> allowed_secgw_flow e1 e2 \<longrightarrow> \<not> allowed_secgw_flow Unassigned e2"
    apply(rule allI)+
    apply(case_tac e2)
        apply(simp_all)
     apply(case_tac e1)
          apply(simp_all)
    apply(case_tac e1)
        apply(simp_all)
    done
  lemma Unassigned_not_to_Member: "\<not> allowed_secgw_flow Unassigned DomainMember"
    by(simp)
  lemma All_to_Unassigned: "\<forall> e1. allowed_secgw_flow e1 Unassigned"
    by (rule allI, case_tac e1, simp_all)

  definition SecurityGatewayExtended_offending_set:: "'v graph \<Rightarrow> ('v \<Rightarrow> secgw_member) \<Rightarrow> ('v \<times> 'v) set set" where
  "SecurityGatewayExtended_offending_set G nP = (if sinvar G nP then
      {}
     else 
      { {e \<in> edges G. case e of (e1,e2) \<Rightarrow> e1 \<noteq> e2 \<and> \<not> allowed_secgw_flow (nP e1) (nP e2)} })"
  lemma SecurityGatewayExtended_offending_set: "SecurityInvariant_withOffendingFlows.set_offending_flows sinvar = SecurityGatewayExtended_offending_set"
    apply(simp only: fun_eq_iff ENFnr_offending_set[OF SecurityGateway_ENFnr] SecurityGatewayExtended_offending_set_def)
    apply(rule allI)+
    apply(rename_tac G nP)
    apply(auto)
  done

interpretation SecurityGatewayExtended: SecurityInvariant_ACS
where default_node_properties = default_node_properties
and sinvar = sinvar
and verify_globals = verify_globals
where "SecurityInvariant_withOffendingFlows.set_offending_flows sinvar = SecurityGatewayExtended_offending_set"
  unfolding default_node_properties_def
  apply unfold_locales
    apply(rule ballI)
    apply (rule SecurityInvariant_withOffendingFlows.ENFnr_fsts_weakrefl_instance[OF SecurityGateway_ENFnr Unassigned_botdefault All_to_Unassigned])[1]
     apply(simp)
    apply(simp)
   apply(erule default_uniqueness_by_counterexample_ACS)
   apply (simp add: SecurityInvariant_withOffendingFlows.set_offending_flows_def
      SecurityInvariant_withOffendingFlows.is_offending_flows_min_set_def
      SecurityInvariant_withOffendingFlows.is_offending_flows_def)
   apply (simp add:graph_ops)
   apply (simp split: split_split_asm split_split)
   apply(rule_tac x="\<lparr> nodes={vertex_1,vertex_2}, edges = {(vertex_1,vertex_2)} \<rparr>" in exI, simp)
   apply(rule conjI)
    apply(simp add: valid_graph_def)
   apply(case_tac otherbot, simp_all)
      apply(rename_tac secgwcase)
      apply(rule_tac x="(\<lambda> x. Unassigned)(vertex_1 := Unassigned, vertex_2 := DomainMember)" in exI, simp)
      apply(rule_tac x="{(vertex_1,vertex_2)}" in exI, simp)
     apply(rename_tac secgwINcase)
     apply(rule_tac x="(\<lambda> x. Unassigned)(vertex_1 := Unassigned, vertex_2 := DomainMember)" in exI, simp)
     apply(rule_tac x="vertex_1" in exI, simp)
     apply(rule_tac x="{(vertex_1,vertex_2)}" in exI, simp)
    apply(rename_tac membercase)
    apply(rule_tac x="(\<lambda> x. Unassigned)(vertex_1 := Unassigned, vertex_2 := SecurityGateway)" in exI, simp)
    apply(rule_tac x="vertex_1" in exI, simp)
    apply(rule_tac x="{(vertex_1,vertex_2)}" in exI, simp)
   apply(rule_tac x="(\<lambda> x. Unassigned)(vertex_1 := Unassigned, vertex_2 := SecurityGateway)" in exI, simp)
   apply(rule_tac x="vertex_1" in exI, simp)
   apply(rule_tac x="{(vertex_1,vertex_2)}" in exI, simp)

  apply(fact SecurityGatewayExtended_offending_set)
 done



  lemma TopoS_SecurityGatewayExtended: "SecurityInvariant sinvar default_node_properties receiver_violation"
  unfolding receiver_violation_def by unfold_locales  

hide_const (open) sinvar verify_globals receiver_violation

end
