theory SINVAR_ACLnotCommunicateWith_impl
imports SINVAR_ACLnotCommunicateWith "../TopoS_Interface_impl"
begin

code_identifier code_module SINVAR_ACLnotCommunicateWith_impl => (Scala) SINVAR_ACLnotCommunicateWith


subsubsection {* SecurityInvariant ACLnotCommunicateWith List Implementation *}


fun sinvar :: "'v list_graph \<Rightarrow> ('v \<Rightarrow> 'v set) \<Rightarrow> bool" where
  "sinvar G nP = (\<forall> v \<in> set (nodesL G). \<forall> a \<in> set (succ_tran G v). a \<notin> (nP v))"

fun verify_globals :: "'v list_graph \<Rightarrow> ('v \<Rightarrow> 'v set) \<Rightarrow> unit \<Rightarrow> bool" where
  "verify_globals _ _ _ = True"


definition "NetModel_node_props (P::('v::vertex, 'v set, 'b) TopoS_Params) = 
  (\<lambda> i. (case (node_properties P) i of Some property \<Rightarrow> property | None \<Rightarrow> SINVAR_ACLnotCommunicateWith.default_node_properties))"
lemma[code_unfold]: "SecurityInvariant.node_props SINVAR_ACLnotCommunicateWith.default_node_properties P = NetModel_node_props P"
apply(simp add: NetModel_node_props_def)
done

definition "ACLnotCommunicateWith_offending_list = Generic_offending_list sinvar"

definition "ACLnotCommunicateWith_eval G P = (valid_list_graph G \<and> 
  verify_globals G (SecurityInvariant.node_props SINVAR_ACLnotCommunicateWith.default_node_properties P) (model_global_properties P) \<and> 
  sinvar G (SecurityInvariant.node_props SINVAR_ACLnotCommunicateWith.default_node_properties P))"


lemma sinvar_correct: "valid_list_graph G \<Longrightarrow> SINVAR_ACLnotCommunicateWith.sinvar (list_graph_to_graph G) nP = sinvar G nP"
by (metis SINVAR_ACLnotCommunicateWith.sinvar.simps SINVAR_ACLnotCommunicateWith_impl.sinvar.simps graph.select_convs(1) list_graph_to_graph_def succ_tran_correct)


interpretation ACLnotCommunicateWith_impl:TopoS_List_Impl 
  where default_node_properties=SINVAR_ACLnotCommunicateWith.default_node_properties
  and sinvar_spec=SINVAR_ACLnotCommunicateWith.sinvar
  and sinvar_impl=sinvar
  and verify_globals_spec=SINVAR_ACLnotCommunicateWith.verify_globals
  and verify_globals_impl=verify_globals
  and receiver_violation=SINVAR_ACLnotCommunicateWith.receiver_violation
  and offending_flows_impl=ACLnotCommunicateWith_offending_list
  and node_props_impl=NetModel_node_props
  and eval_impl=ACLnotCommunicateWith_eval
 apply(unfold TopoS_List_Impl_def)
 apply(rule conjI)
  apply(rule conjI)
   apply(simp add: TopoS_ACLnotCommunicateWith)
  apply(rule conjI)
   apply(intro allI impI)
   apply(fact sinvar_correct)
  apply(simp)
 apply(rule conjI)
  apply(unfold ACLnotCommunicateWith_offending_list_def)
  apply(intro allI impI)
  apply(rule Generic_offending_list_correct)
   apply(assumption)
  apply(simp only: sinvar_correct)
 apply(rule conjI)
  apply(intro allI)
  apply(simp only: NetModel_node_props_def)
  apply(metis ACLnotCommunicateWith.node_props.simps ACLnotCommunicateWith.node_props_eq_node_props_formaldef)
 apply(simp only: ACLnotCommunicateWith_eval_def)
 apply(intro allI impI)
 apply(rule TopoS_eval_impl_proofrule[OF TopoS_ACLnotCommunicateWith])
  apply(simp only: sinvar_correct)
 apply(simp)
done

subsubsection {* packing *}
  definition SINVAR_LIB_ACLnotCommunicateWith:: "('v::vertex, 'v set, unit) TopoS_packed" where
    "SINVAR_LIB_ACLnotCommunicateWith \<equiv> 
    \<lparr> nm_name = ''ACLnotCommunicateWith'', 
      nm_receiver_violation = SINVAR_ACLnotCommunicateWith.receiver_violation,
      nm_default = SINVAR_ACLnotCommunicateWith.default_node_properties, 
      nm_sinvar = sinvar,
      nm_verify_globals = verify_globals,
      nm_offending_flows = ACLnotCommunicateWith_offending_list, 
      nm_node_props = NetModel_node_props,
      nm_eval = ACLnotCommunicateWith_eval
      \<rparr>"
  interpretation SINVAR_LIB_ACLnotCommunicateWith_interpretation: TopoS_modelLibrary SINVAR_LIB_ACLnotCommunicateWith
      SINVAR_ACLnotCommunicateWith.sinvar SINVAR_ACLnotCommunicateWith.verify_globals
    apply(unfold TopoS_modelLibrary_def SINVAR_LIB_ACLnotCommunicateWith_def)
    apply(rule conjI)
     apply(simp)
    apply(simp)
    by(unfold_locales)



text {* Examples*}



hide_const (open) NetModel_node_props
hide_const (open) sinvar verify_globals

end
