(*  Title:      JinjaThreads/Execute/Scheduler.thy
    Author:     Andreas Lochbihler
*)

header {* \isaheader{Abstract scheduler} *}

theory Scheduler imports
  State_Refinement
  "../Framework/FWProgressAux"
  "../../Collections/SetSpec"
  "../../Collections/MapSpec"
  "../../Collections/ListSpec"
  "../../Coinductive/TLList"
begin

types
  ('l,'t,'x,'m,'w,'o,'m_t,'m_w,'s) scheduler = 
    "'s \<Rightarrow> ('l,'t,'m,'m_t,'m_w) state_refine \<Rightarrow> ('t \<times> (('l,'t,'x,'m,'w,'o list) thread_action \<times> 'x \<times> 'm) option \<times> 's) option"

locale scheduler_spec_base =
  state_refine_base
    final r convert_RA
    thr_\<alpha> thr_invar
    ws_\<alpha> ws_invar 
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t,'x,'m,'w,'o list) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and schedule :: "('l,'t,'x,'m,'w,'o,'m_t,'m_w,'s) scheduler"
  and \<sigma>_invar :: "'s \<Rightarrow> 't set \<Rightarrow> bool"
  and thr_\<alpha> :: "'m_t \<Rightarrow> ('l,'t,'x) thread_info"
  and thr_invar :: "'m_t \<Rightarrow> bool"
  and ws_\<alpha> :: "'m_w \<Rightarrow> ('w,'t) wait_sets"
  and ws_invar :: "'m_w \<Rightarrow> bool"

locale scheduler_spec = 
  scheduler_spec_base
    final r convert_RA
    schedule \<sigma>_invar
    thr_\<alpha> thr_invar
    ws_\<alpha> ws_invar 
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t,'x,'m,'w,'o list) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and schedule :: "('l,'t,'x,'m,'w,'o,'m_t,'m_w,'s) scheduler"
  and \<sigma>_invar :: "'s \<Rightarrow> 't set \<Rightarrow> bool"
  and thr_\<alpha> :: "'m_t \<Rightarrow> ('l,'t,'x) thread_info"
  and thr_invar :: "'m_t \<Rightarrow> bool"
  and ws_\<alpha> :: "'m_w \<Rightarrow> ('w,'t) wait_sets"
  and ws_invar :: "'m_w \<Rightarrow> bool"
  +
  assumes schedule_NoneD:
  "\<lbrakk> schedule \<sigma> s = None; state_invar s; \<sigma>_invar \<sigma> (dom (thr_\<alpha> (thr s))) \<rbrakk> \<Longrightarrow> \<alpha>.active_threads (state_\<alpha> s) = {}"
  and schedule_Some_NoneD:
  "\<lbrakk> schedule \<sigma> s = \<lfloor>(t, None, \<sigma>')\<rfloor>; state_invar s; \<sigma>_invar \<sigma> (dom (thr_\<alpha> (thr s))) \<rbrakk> 
  \<Longrightarrow> \<exists>x ln n. thr_\<alpha> (thr s) t = \<lfloor>(x, ln)\<rfloor> \<and> ln\<^sub>f n > 0 \<and> \<not> waiting (ws_\<alpha> (wset s) t) \<and> may_acquire_all (locks s) t ln"
  and schedule_Some_SomeD:
  "\<lbrakk> schedule \<sigma> s = \<lfloor>(t, \<lfloor>(ta, x', m')\<rfloor>, \<sigma>')\<rfloor>; state_invar s; \<sigma>_invar \<sigma> (dom (thr_\<alpha> (thr s))) \<rbrakk> 
  \<Longrightarrow> \<exists>x. thr_\<alpha> (thr s) t = \<lfloor>(x, no_wait_locks)\<rfloor> \<and> Predicate.eval (r t (x, shr s)) (ta, x', m') \<and> 
         \<alpha>.actions_ok (state_\<alpha> s) t ta"
  and schedule_invar_None:
  "\<lbrakk> schedule \<sigma> s = \<lfloor>(t, None, \<sigma>')\<rfloor>; state_invar s; \<sigma>_invar \<sigma> (dom (thr_\<alpha> (thr s))) \<rbrakk>
  \<Longrightarrow> \<sigma>_invar \<sigma>' (dom (thr_\<alpha> (thr s)))"
  and schedule_invar_Some:
  "\<lbrakk> schedule \<sigma> s = \<lfloor>(t, \<lfloor>(ta, x', m')\<rfloor>, \<sigma>')\<rfloor>; state_invar s; \<sigma>_invar \<sigma> (dom (thr_\<alpha> (thr s))) \<rbrakk>
  \<Longrightarrow> \<sigma>_invar \<sigma>' (dom (thr_\<alpha> (thr s)) \<union> {t. \<exists>x m. NewThread t x m \<in> set \<lbrace>ta\<rbrace>\<^bsub>t\<^esub>})"

locale pick_wakeup_spec_base =
  state_refine_base
    final r convert_RA
    thr_\<alpha> thr_invar
    ws_\<alpha> ws_invar 
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t,'x,'m,'w,'o list) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and pick_wakeup :: "'s \<Rightarrow> 't \<Rightarrow> 'w \<Rightarrow> 'm_w \<Rightarrow> 't option"
  and \<sigma>_invar :: "'s \<Rightarrow> 't set \<Rightarrow> bool"
  and thr_\<alpha> :: "'m_t \<Rightarrow> ('l,'t,'x) thread_info"
  and thr_invar :: "'m_t \<Rightarrow> bool"
  and ws_\<alpha> :: "'m_w \<Rightarrow> ('w,'t) wait_sets"
  and ws_invar :: "'m_w \<Rightarrow> bool"

locale pick_wakeup_spec =
  pick_wakeup_spec_base 
    final r convert_RA
    pick_wakeup \<sigma>_invar
    thr_\<alpha> thr_invar
    ws_\<alpha> ws_invar 
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t,'x,'m,'w,'o list) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and pick_wakeup :: "'s \<Rightarrow> 't \<Rightarrow> 'w \<Rightarrow> 'm_w \<Rightarrow> 't option"
  and \<sigma>_invar :: "'s \<Rightarrow> 't set \<Rightarrow> bool"
  and thr_\<alpha> :: "'m_t \<Rightarrow> ('l,'t,'x) thread_info"
  and thr_invar :: "'m_t \<Rightarrow> bool"
  and ws_\<alpha> :: "'m_w \<Rightarrow> ('w,'t) wait_sets"
  and ws_invar :: "'m_w \<Rightarrow> bool"
  +
  assumes pick_wakeup_NoneD:
  "\<lbrakk> pick_wakeup \<sigma> t w ws = None; ws_invar ws; \<sigma>_invar \<sigma> T; dom (ws_\<alpha> ws) \<subseteq> T; t \<in> T \<rbrakk> 
  \<Longrightarrow> InWS w \<notin> ran (ws_\<alpha> ws)"
  and pick_wakeup_SomeD:
  "\<lbrakk> pick_wakeup \<sigma> t w ws = \<lfloor>t'\<rfloor>; ws_invar ws; \<sigma>_invar \<sigma> T; dom (ws_\<alpha> ws) \<subseteq> T; t \<in> T \<rbrakk>
  \<Longrightarrow> ws_\<alpha> ws t' = \<lfloor>InWS w\<rfloor>"

locale scheduler_base_aux =
  state_refine_base
    final r convert_RA
    thr_\<alpha> thr_invar
    ws_\<alpha> ws_invar 
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t,'x,'m,'w,'o list) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and thr_\<alpha> :: "'m_t \<Rightarrow> ('l,'t,'x) thread_info"
  and thr_invar :: "'m_t \<Rightarrow> bool"
  and thr_empty :: "'m_t"
  and thr_lookup :: "'t \<Rightarrow> 'm_t \<rightharpoonup> ('x \<times> 'l released_locks)"
  and thr_update :: "'t \<Rightarrow> 'x \<times> 'l released_locks \<Rightarrow> 'm_t \<Rightarrow> 'm_t"
  and ws_\<alpha> :: "'m_w \<Rightarrow> ('w,'t) wait_sets"
  and ws_invar :: "'m_w \<Rightarrow> bool"
  and ws_empty :: "'m_w"
  and ws_lookup :: "'t \<Rightarrow> 'm_w \<rightharpoonup> 'w wait_set_status"
begin

definition free_thread_id :: "'m_t \<Rightarrow> 't \<Rightarrow> bool"
where "free_thread_id ts t \<longleftrightarrow> thr_lookup t ts = None"

fun redT_updT :: "'m_t \<Rightarrow> ('t,'x,'m) new_thread_action \<Rightarrow> 'm_t"
where
  "redT_updT ts (NewThread t' x m) = thr_update t' (x, no_wait_locks) ts"
| "redT_updT ts _ = ts"

definition redT_updTs :: "'m_t \<Rightarrow> ('t,'x,'m) new_thread_action list \<Rightarrow> 'm_t"
where "redT_updTs = foldl redT_updT"

primrec thread_ok :: "'m_t \<Rightarrow> ('t,'x,'m) new_thread_action \<Rightarrow> bool"
where
  "thread_ok ts (NewThread t x m) = free_thread_id ts t"
| "thread_ok ts (ThreadExists t) = (\<not> free_thread_id ts t)"

text {*
  We use @{term "redT_updT"} in @{text "thread_ok"} instead of @{term "redT_updT'"} like in theory @{theory FWThread}.
  This fixes @{typ "'x"} in the @{typ "('t,'x,'m) new_thread_action list"} type, but avoids @{term "undefined"},
  which raises an exception during execution in the generated code.
*}

primrec thread_oks :: "'m_t \<Rightarrow> ('t,'x,'m) new_thread_action list \<Rightarrow> bool"
where
  "thread_oks ts [] = True"
| "thread_oks ts (ta#tas) = (thread_ok ts ta \<and> thread_oks (redT_updT ts ta) tas)"

definition wset_actions_ok :: "'m_w \<Rightarrow> 't \<Rightarrow> ('t,'w) wait_set_action list \<Rightarrow> bool"
where
  "wset_actions_ok ws t was \<longleftrightarrow>
   ws_lookup t ws = 
   (if Notified \<in> set was then \<lfloor>WokenUp WSNotified\<rfloor>
    else if Interrupted \<in> set was then \<lfloor>WokenUp WSInterrupted\<rfloor>
    else None)"

primrec cond_action_ok :: "('l,'t,'m,'m_t,'m_w) state_refine \<Rightarrow> 't \<Rightarrow> 't conditional_action \<Rightarrow> bool" 
where
  "cond_action_ok s t (Join T) = 
   (case thr_lookup T (thr s)
      of None \<Rightarrow> True 
    | \<lfloor>(x, ln)\<rfloor> \<Rightarrow> t \<noteq> T \<and> final x \<and> ln = no_wait_locks \<and> ws_lookup T (wset s) = None)"

definition cond_action_oks :: "('l,'t,'m,'m_t,'m_w) state_refine \<Rightarrow> 't \<Rightarrow> 't conditional_action list \<Rightarrow> bool" 
where
  "cond_action_oks s t cts = list_all (cond_action_ok s t) cts"

definition actions_ok :: "('l,'t,'m,'m_t,'m_w) state_refine \<Rightarrow> 't \<Rightarrow> ('l,'t,'x,'m,'w,'o') thread_action \<Rightarrow> bool"
where
  "actions_ok s t ta \<longleftrightarrow>
   lock_ok_las (locks s) t \<lbrace>ta\<rbrace>\<^bsub>l\<^esub> \<and> 
   thread_oks (thr s) \<lbrace>ta\<rbrace>\<^bsub>t\<^esub> \<and>
   cond_action_oks s t \<lbrace>ta\<rbrace>\<^bsub>c\<^esub> \<and>
   wset_actions_ok (wset s) t \<lbrace>ta\<rbrace>\<^bsub>w\<^esub>"

end

datatype 'a diverge =
  Diverge
| Final 'a

locale scheduler_base =
  scheduler_base_aux
    final r convert_RA
    thr_\<alpha> thr_invar thr_empty thr_lookup thr_update
    ws_\<alpha> ws_invar ws_empty ws_lookup
  +
  scheduler_spec_base
    final r convert_RA
    schedule \<sigma>_invar
    thr_\<alpha> thr_invar
    ws_\<alpha> ws_invar 
  +
  pick_wakeup_spec_base
    final r convert_RA
    pick_wakeup \<sigma>_invar
    thr_\<alpha> thr_invar
    ws_\<alpha> ws_invar 
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t,'x,'m,'w,'o list) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and schedule :: "('l,'t,'x,'m,'w,'o,'m_t,'m_w,'s) scheduler"
  and "output" :: "'s \<Rightarrow> 't \<Rightarrow> ('l,'t,'x,'m,'w,'o list) thread_action \<Rightarrow> 'q option"
  and pick_wakeup :: "'s \<Rightarrow> 't \<Rightarrow> 'w \<Rightarrow> 'm_w \<Rightarrow> 't option"
  and \<sigma>_invar :: "'s \<Rightarrow> 't set \<Rightarrow> bool"
  and thr_\<alpha> :: "'m_t \<Rightarrow> ('l,'t,'x) thread_info"
  and thr_invar :: "'m_t \<Rightarrow> bool"
  and thr_empty :: "'m_t"
  and thr_lookup :: "'t \<Rightarrow> 'm_t \<rightharpoonup> ('x \<times> 'l released_locks)"
  and thr_update :: "'t \<Rightarrow> 'x \<times> 'l released_locks \<Rightarrow> 'm_t \<Rightarrow> 'm_t"
  and ws_\<alpha> :: "'m_w \<Rightarrow> ('w,'t) wait_sets"
  and ws_invar :: "'m_w \<Rightarrow> bool"
  and ws_empty :: "'m_w"
  and ws_lookup :: "'t \<Rightarrow> 'm_w \<rightharpoonup> 'w wait_set_status"
  and ws_update :: "'t \<Rightarrow> 'w wait_set_status \<Rightarrow> 'm_w \<Rightarrow> 'm_w"
  and ws_delete :: "'t \<Rightarrow> 'm_w \<Rightarrow> 'm_w"
  and ws_iterate :: "('m_w, 't, 'w wait_set_status, 'm_w) map_iterator"
begin

primrec exec_updW :: "'s \<Rightarrow> 't \<Rightarrow> 'm_w \<Rightarrow> ('t,'w) wait_set_action \<Rightarrow> 'm_w"
where
  "exec_updW \<sigma> t ws (Notify w) = 
   (case pick_wakeup \<sigma> t w ws
    of None  \<Rightarrow> ws
    | Some t \<Rightarrow> ws_update t (WokenUp WSNotified) ws)"
| "exec_updW \<sigma> t ws (NotifyAll w) =
   ws_iterate (\<lambda>t w' ws'. if w' = InWS w then ws_update t (WokenUp WSNotified) ws' else ws') 
              ws ws"
| "exec_updW \<sigma> t ws (Suspend w) = ws_update t (InWS w) ws"
| "exec_updW \<sigma> t ws (Interrupt t') =
   (case ws_lookup t' ws of \<lfloor>InWS w\<rfloor> \<Rightarrow> ws_update t' (WokenUp WSInterrupted) ws | _ \<Rightarrow> ws)"
| "exec_updW \<sigma> t ws Notified = ws_delete t ws"
| "exec_updW \<sigma> t ws Interrupted = ws_delete t ws"

definition exec_updWs :: "'s \<Rightarrow> 't \<Rightarrow> 'm_w \<Rightarrow> ('t,'w) wait_set_action list \<Rightarrow> 'm_w"
where "exec_updWs \<sigma> t = foldl (exec_updW \<sigma> t)"

definition exec_upd :: "'s \<Rightarrow> ('l,'t,'m,'m_t,'m_w) state_refine \<Rightarrow> 't \<Rightarrow> ('l,'t,'x,'m,'w,'o list) thread_action \<Rightarrow> 'x \<Rightarrow> 'm \<Rightarrow> ('l,'t,'m,'m_t,'m_w) state_refine"
where [simp]:
  "exec_upd \<sigma> s t ta x' m' =
   (redT_updLs (locks s) t \<lbrace>ta\<rbrace>\<^bsub>l\<^esub>,
    (thr_update t (x', redT_updLns (locks s) t (snd (the (thr_lookup t (thr s)))) \<lbrace>ta\<rbrace>\<^bsub>l\<^esub>) (redT_updTs (thr s) \<lbrace>ta\<rbrace>\<^bsub>t\<^esub>), m'),
    exec_updWs \<sigma> t (wset s) \<lbrace>ta\<rbrace>\<^bsub>w\<^esub>)"

definition execT :: "'s \<Rightarrow> ('l,'t,'m,'m_t,'m_w) state_refine \<Rightarrow> ('s \<times> 't \<times> ('l,'t,'x,'m,'w,'o list) thread_action \<times> ('l,'t,'m,'m_t,'m_w) state_refine) option"
where 
  "execT \<sigma> s =
  (do {
     (t, tax'm', \<sigma>') \<leftarrow> schedule \<sigma> s;
     case tax'm' of
       None \<Rightarrow> 
       (let (x, ln) = the (thr_lookup t (thr s));
            ta = (\<lambda>\<^isup>f [], [], [], [], convert_RA ln);
            s' = (acquire_all (locks s) t ln, (thr_update t (x, no_wait_locks) (thr s), shr s), wset s)
        in \<lfloor>(\<sigma>', t, ta, s')\<rfloor>)
     | \<lfloor>(ta, x', m')\<rfloor> \<Rightarrow> \<lfloor>(\<sigma>', t, ta, exec_upd \<sigma> s t ta x' m')\<rfloor>
   })"

primrec exec_step :: 
  "'s \<times> ('l,'t,'m,'m_t,'m_w) state_refine \<Rightarrow> 
   'q option \<times> 's \<times> ('l,'t,'m,'m_t,'m_w) state_refine + ('l,'t,'m,'m_t,'m_w) state_refine"
where
  "exec_step (\<sigma>, s) =
   (case execT \<sigma> s of 
      None \<Rightarrow> Inr s
    | Some (\<sigma>', t, ta, s') \<Rightarrow> Inl (output \<sigma> t ta, \<sigma>', s'))"

declare exec_step.simps [simp del]

definition exec_aux :: "'s \<times> ('l,'t,'m,'m_t,'m_w) state_refine \<Rightarrow> ('q option, ('l,'t,'m,'m_t,'m_w) state_refine) tllist"
where
  "exec_aux \<sigma>s = tllist_corec \<sigma>s exec_step"

definition exec :: "'s \<Rightarrow> ('l,'t,'m,'m_t,'m_w) state_refine \<Rightarrow> ('q, ('l,'t,'m,'m_t,'m_w) state_refine diverge) tllist"
where 
  "exec \<sigma> s = tmap the id (tfilter Diverge (\<lambda>q. q \<noteq> None) (tmap id Final (exec_aux (\<sigma>, s))))"

end

text {*
  Implement @{text "pick_wakeup"} by @{text "map_sel'"}
*}

definition pick_wakeup_via_sel :: 
  "('m_w \<Rightarrow> ('t \<Rightarrow> 'w wait_set_status \<Rightarrow> bool) \<rightharpoonup> 't \<times> 'w wait_set_status) 
  \<Rightarrow> 's \<Rightarrow> 't \<Rightarrow> 'w \<Rightarrow> 'm_w \<Rightarrow> 't option"
where "pick_wakeup_via_sel ws_sel \<sigma> t w ws = Option.map fst (ws_sel ws (\<lambda>t w'. w' = InWS w))"

lemma pick_wakeup_spec_via_sel:
  assumes sel: "map_sel' ws_\<alpha> ws_invar ws_sel"
  shows "pick_wakeup_spec (pick_wakeup_via_sel ws_sel) \<sigma>_invar ws_\<alpha> ws_invar"
proof -
  interpret ws!: map_sel' ws_\<alpha> ws_invar ws_sel by(rule sel)
  show ?thesis
    by(unfold_locales)(auto simp add: pick_wakeup_via_sel_def ran_def dest: ws.sel'_noneD ws.sel'_SomeD)
qed

locale scheduler_ext_base =
  scheduler_base
    final r convert_RA
    schedule "output" "pick_wakeup_via_sel ws_sel" \<sigma>_invar
    thr_\<alpha> thr_invar thr_empty thr_lookup thr_update
    ws_\<alpha> ws_invar ws_empty ws_lookup ws_update ws_delete ws_iterate
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t,'x,'m,'w,'o list) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and schedule :: "('l,'t,'x,'m,'w,'o,'m_t,'m_w,'s) scheduler"
  and "output" :: "'s \<Rightarrow> 't \<Rightarrow> ('l,'t,'x,'m,'w,'o list) thread_action \<Rightarrow> 'q option"
  and \<sigma>_invar :: "'s \<Rightarrow> 't set \<Rightarrow> bool"
  and thr_\<alpha> :: "'m_t \<Rightarrow> ('l,'t,'x) thread_info"
  and thr_invar :: "'m_t \<Rightarrow> bool"
  and thr_empty :: "'m_t"
  and thr_lookup :: "'t \<Rightarrow> 'm_t \<rightharpoonup> ('x \<times> 'l released_locks)"
  and thr_update :: "'t \<Rightarrow> 'x \<times> 'l released_locks \<Rightarrow> 'm_t \<Rightarrow> 'm_t"
  and thr_iterate :: "('m_t, 't, 'x \<times> 'l released_locks, 's_t) map_iterator"
  and ws_\<alpha> :: "'m_w \<Rightarrow> ('w,'t) wait_sets"
  and ws_invar :: "'m_w \<Rightarrow> bool"
  and ws_empty :: "'m_w"
  and ws_lookup :: "'t \<Rightarrow> 'm_w \<rightharpoonup> 'w wait_set_status"
  and ws_update :: "'t \<Rightarrow> 'w wait_set_status \<Rightarrow> 'm_w \<Rightarrow> 'm_w"
  and ws_delete :: "'t \<Rightarrow> 'm_w \<Rightarrow> 'm_w"
  and ws_iterate :: "('m_w, 't, 'w wait_set_status, 'm_w) map_iterator"
  and ws_sel :: "'m_w \<Rightarrow> ('t \<Rightarrow> 'w wait_set_status \<Rightarrow> bool) \<rightharpoonup> ('t \<times> 'w wait_set_status)"
  +
  fixes thr'_\<alpha> :: "'s_t \<Rightarrow> 't set"
  and thr'_invar :: "'s_t \<Rightarrow> bool"
  and thr'_empty :: "'s_t"
  and thr'_ins_dj :: "'t \<Rightarrow> 's_t \<Rightarrow> 's_t"
begin

abbreviation pick_wakeup :: "'s \<Rightarrow> 't \<Rightarrow> 'w \<Rightarrow> 'm_w \<Rightarrow> 't option"
where "pick_wakeup \<equiv> pick_wakeup_via_sel ws_sel"

fun active_threads :: "('l,'t,'m,'m_t,'m_w) state_refine \<Rightarrow> 's_t"
where
  "active_threads (ls, (ts, m), ws) =
   thr_iterate
      (\<lambda>t (x, ln) ts'. if ln = no_wait_locks
                       then if Predicate.holds 
                               (do {
                                  (ta, _) \<leftarrow> r t (x, m);
                                  Predicate.if_pred (actions_ok (ls, (ts, m), ws) t ta)
                                })
                            then thr'_ins_dj t ts'
                            else ts'
                       else if \<not> waiting (ws_lookup t ws) \<and> may_acquire_all ls t ln then thr'_ins_dj t ts' else ts')
      ts thr'_empty"

end

locale scheduler_aux =
  scheduler_base_aux
    final r convert_RA
    thr_\<alpha> thr_invar thr_empty thr_lookup thr_update
    ws_\<alpha> ws_invar ws_empty ws_lookup
  +
  thr!: finite_map thr_\<alpha> thr_invar +
  thr!: map_empty thr_\<alpha> thr_invar thr_empty +
  thr!: map_lookup thr_\<alpha> thr_invar thr_lookup +
  thr!: map_update thr_\<alpha> thr_invar thr_update +
  ws!: map ws_\<alpha> ws_invar +
  ws!: map_empty ws_\<alpha> ws_invar ws_empty +
  ws!: map_lookup ws_\<alpha> ws_invar ws_lookup 
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t,'x,'m,'w,'o list) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and thr_\<alpha> :: "'m_t \<Rightarrow> ('l,'t,'x) thread_info"
  and thr_invar :: "'m_t \<Rightarrow> bool"
  and thr_empty :: "'m_t"
  and thr_lookup :: "'t \<Rightarrow> 'm_t \<rightharpoonup> ('x \<times> 'l released_locks)"
  and thr_update :: "'t \<Rightarrow> 'x \<times> 'l released_locks \<Rightarrow> 'm_t \<Rightarrow> 'm_t"
  and ws_\<alpha> :: "'m_w \<Rightarrow> ('w,'t) wait_sets"
  and ws_invar :: "'m_w \<Rightarrow> bool"
  and ws_empty :: "'m_w"
  and ws_lookup :: "'t \<Rightarrow> 'm_w \<rightharpoonup> 'w wait_set_status"
begin

lemma free_thread_id_correct [simp]:
  "thr_invar ts \<Longrightarrow> free_thread_id ts = FWThread.free_thread_id (thr_\<alpha> ts)"
by(auto simp add: free_thread_id_def fun_eq_iff thr.lookup_correct intro: free_thread_id.intros)

lemma redT_updT_correct [simp]:
  assumes "thr_invar ts"
  shows "thr_\<alpha> (redT_updT ts nta) = FWThread.redT_updT (thr_\<alpha> ts) nta"
  and "thr_invar (redT_updT ts nta)"
by(case_tac [!] nta)(simp_all add: thr.update_correct assms)

lemma redT_updTs_correct [simp]:
  assumes  "thr_invar ts"
  shows "thr_\<alpha> (redT_updTs ts ntas) = FWThread.redT_updTs (thr_\<alpha> ts) ntas"
  and "thr_invar (redT_updTs ts ntas)"
using assms
by(induct ntas arbitrary: ts)(simp_all add: redT_updTs_def)

lemma thread_ok_correct [simp]:
  "thr_invar ts \<Longrightarrow> thread_ok ts nta \<longleftrightarrow> FWThread.thread_ok (thr_\<alpha> ts) nta"
by(cases nta) simp_all

lemma thread_oks_correct [simp]:
  "thr_invar ts \<Longrightarrow> thread_oks ts ntas \<longleftrightarrow> FWThread.thread_oks (thr_\<alpha> ts) ntas"
by(induct ntas arbitrary: ts) simp_all

lemma wset_actions_ok_correct [simp]:
  "ws_invar ws \<Longrightarrow> wset_actions_ok ws t was \<longleftrightarrow> FWWait.wset_actions_ok (ws_\<alpha> ws) t was"
by(simp add: wset_actions_ok_def FWWait.wset_actions_ok_def ws.lookup_correct)

lemma cond_action_ok_correct [simp]:
  "state_invar s \<Longrightarrow> cond_action_ok s t cta \<longleftrightarrow> \<alpha>.cond_action_ok (state_\<alpha> s) t cta"
by(cases s)(cases cta, auto simp add: thr.lookup_correct ws.lookup_correct)

lemma cond_action_oks_correct [simp]:
  assumes "state_invar s"
  shows "cond_action_oks s t ctas \<longleftrightarrow> \<alpha>.cond_action_oks (state_\<alpha> s) t ctas"
by(induct ctas)(simp_all add: cond_action_oks_def assms)

lemma actions_ok_correct [simp]:
  "state_invar s \<Longrightarrow> actions_ok s t ta \<longleftrightarrow> \<alpha>.actions_ok (state_\<alpha> s) t ta"
by(auto simp add: actions_ok_def)

end

locale scheduler =
  scheduler_base 
    final r convert_RA
    schedule "output" pick_wakeup \<sigma>_invar
    thr_\<alpha> thr_invar thr_empty thr_lookup thr_update
    ws_\<alpha> ws_invar ws_empty ws_lookup ws_update ws_delete ws_iterate
  +
  scheduler_aux
    final r convert_RA
    thr_\<alpha> thr_invar thr_empty thr_lookup thr_update
    ws_\<alpha> ws_invar ws_empty ws_lookup
  +
  scheduler_spec
    final r convert_RA
    schedule \<sigma>_invar
    thr_\<alpha> thr_invar
    ws_\<alpha> ws_invar 
  +
  pick_wakeup_spec
    final r convert_RA
    pick_wakeup \<sigma>_invar
    thr_\<alpha> thr_invar
    ws_\<alpha> ws_invar 
  +
  ws!: map_update ws_\<alpha> ws_invar ws_update +
  ws!: map_delete ws_\<alpha> ws_invar ws_delete +
  ws!: map_iterate ws_\<alpha> ws_invar ws_iterate 
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t,'x,'m,'w,'o list) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and schedule :: "('l,'t,'x,'m,'w,'o,'m_t,'m_w,'s) scheduler"
  and "output" :: "'s \<Rightarrow> 't \<Rightarrow> ('l,'t,'x,'m,'w,'o list) thread_action \<Rightarrow> 'q option"
  and pick_wakeup :: "'s \<Rightarrow> 't \<Rightarrow> 'w \<Rightarrow> 'm_w \<Rightarrow> 't option"
  and \<sigma>_invar :: "'s \<Rightarrow> 't set \<Rightarrow> bool"
  and thr_\<alpha> :: "'m_t \<Rightarrow> ('l,'t,'x) thread_info"
  and thr_invar :: "'m_t \<Rightarrow> bool"
  and thr_empty :: "'m_t"
  and thr_lookup :: "'t \<Rightarrow> 'm_t \<rightharpoonup> ('x \<times> 'l released_locks)"
  and thr_update :: "'t \<Rightarrow> 'x \<times> 'l released_locks \<Rightarrow> 'm_t \<Rightarrow> 'm_t"
  and ws_\<alpha> :: "'m_w \<Rightarrow> ('w,'t) wait_sets"
  and ws_invar :: "'m_w \<Rightarrow> bool"
  and ws_empty :: "'m_w"
  and ws_lookup :: "'t \<Rightarrow> 'm_w \<rightharpoonup> 'w wait_set_status"
  and ws_update :: "'t \<Rightarrow> 'w wait_set_status \<Rightarrow> 'm_w \<Rightarrow> 'm_w"
  and ws_delete :: "'t \<Rightarrow> 'm_w \<Rightarrow> 'm_w"
  and ws_iterate :: "('m_w, 't, 'w wait_set_status, 'm_w) map_iterator"
begin

lemma exec_updW_correct:
  assumes invar: "ws_invar ws" "\<sigma>_invar \<sigma> T" "dom (ws_\<alpha> ws) \<subseteq> T" "t \<in> T"
  shows "redT_updW t (ws_\<alpha> ws) wa (ws_\<alpha> (exec_updW \<sigma> t ws wa))" (is "?thesis1")
  and "ws_invar (exec_updW \<sigma> t ws wa)" (is "?thesis2")
proof -
  from invar have "?thesis1 \<and> ?thesis2"
  proof(cases wa)
    case (Notify w)[simp]
    show ?thesis
    proof(cases "pick_wakeup \<sigma> t w ws")
      case (Some t')
      hence "ws_\<alpha> ws t' = \<lfloor>InWS w\<rfloor>" using invar by(rule pick_wakeup_SomeD)
      with Some show ?thesis using invar by(auto simp add: ws.update_correct)
    next
      case None
      hence "InWS w \<notin> ran (ws_\<alpha> ws)" using invar by(rule pick_wakeup_NoneD)
      with None show ?thesis using invar by(auto simp add: ran_def)
    qed
  next
    case (NotifyAll w)[simp]
    let ?f = "\<lambda>t w' ws'. if w' = InWS w then ws_update t (WokenUp WSNotified) ws' else ws'"
    let ?I = "\<lambda>T ws'. (\<forall>k. if k\<notin>T \<and> ws_\<alpha> ws k = \<lfloor>InWS w\<rfloor> then ws_\<alpha> ws' k = \<lfloor>WokenUp WSNotified\<rfloor> else ws_\<alpha> ws' k = ws_\<alpha> ws k) \<and> ws_invar ws'"
    from invar have "?I (dom (ws_\<alpha> ws)) ws" by(auto simp add: ws.lookup_correct)
    with `ws_invar ws` have "?I {} (ws_iterate ?f ws ws)"
    proof(rule ws.iterate_rule)
      fix t w' T ws'
      assume t: "t \<in> T" and w': "ws_\<alpha> ws t = \<lfloor>w'\<rfloor>"
        and T: "T \<subseteq> dom (ws_\<alpha> ws)" and I: "?I T ws'"
      { fix t'
        assume "t' \<notin> T - {t}" "ws_\<alpha> ws t' = \<lfloor>InWS w\<rfloor>"
        with t I w' invar have "ws_\<alpha> (?f t w' ws') t' = \<lfloor>WokenUp WSNotified\<rfloor>"
          by(auto)(simp_all add: ws.update_correct) }
      moreover {
        fix t'
        assume "t' \<in> T - {t} \<or> ws_\<alpha> ws t' \<noteq> \<lfloor>InWS w\<rfloor>"
        with t I w' invar have "ws_\<alpha> (?f t w' ws') t' = ws_\<alpha> ws t'"
          by(auto simp add: ws.update_correct) }
      moreover
      have "ws_invar (?f t w' ws')" using I by(simp add: ws.update_correct)
      ultimately show "?I (T - {t}) (?f t w' ws')" by safe simp
    qed
    hence "ws_\<alpha> (ws_iterate ?f ws ws) = (\<lambda>t. if ws_\<alpha> ws t = \<lfloor>InWS w\<rfloor> then \<lfloor>WokenUp WSNotified\<rfloor> else ws_\<alpha> ws t)"
      and "ws_invar (ws_iterate ?f ws ws)" by(simp_all add: fun_eq_iff)
    thus ?thesis by simp
  next
    case Interrupt thus ?thesis using assms
      by(auto simp add: ws.lookup_correct ws.update_correct split: wait_set_status.split)
  qed(simp_all add: ws.update_correct ws.delete_correct)
  thus ?thesis1 ?thesis2 by simp_all
qed

lemma exec_updWs_correct:
  assumes "ws_invar ws" "\<sigma>_invar \<sigma> T" "dom (ws_\<alpha> ws) \<subseteq> T" "t \<in> T"
  shows "redT_updWs t (ws_\<alpha> ws) was (ws_\<alpha> (exec_updWs \<sigma> t ws was))" (is "?thesis1")
  and "ws_invar (exec_updWs \<sigma> t ws was)" (is "?thesis2")
proof -
  from `ws_invar ws` `dom (ws_\<alpha> ws) \<subseteq> T` 
  have "?thesis1 \<and> ?thesis2"
  proof(induct was arbitrary: ws)
    case Nil thus ?case by(auto simp add: exec_updWs_def redT_updWs_def)
  next
    case (Cons wa was)
    let ?ws' = "exec_updW \<sigma> t ws wa"
    from `ws_invar ws` `\<sigma>_invar \<sigma> T` `dom (ws_\<alpha> ws) \<subseteq> T` `t \<in> T`
    have invar': "ws_invar ?ws'" and red: "redT_updW t (ws_\<alpha> ws) wa (ws_\<alpha> ?ws')"
      by(rule exec_updW_correct)+
    have "dom (ws_\<alpha> ?ws') \<subseteq> T"
    proof
      fix t' assume "t' \<in> dom (ws_\<alpha> ?ws')"
      with red have "t' \<in> dom (ws_\<alpha> ws) \<or> t = t'"
        by(auto dest!: redT_updW_Some_otherD split: wait_set_status.split_asm)
      with `dom (ws_\<alpha> ws) \<subseteq> T` `t \<in> T` show "t' \<in> T" by auto
    qed
    with invar' have "redT_updWs t (ws_\<alpha> ?ws') was (ws_\<alpha> (exec_updWs \<sigma> t ?ws' was)) \<and> ws_invar (exec_updWs \<sigma> t ?ws' was)"
      by(rule Cons.hyps)
    thus ?case using red
      by(auto simp add: exec_updWs_def redT_updWs_def intro: rtrancl3p_step_converse)
  qed
  thus ?thesis1 ?thesis2 by simp_all
qed

lemma exec_upd_correct:
  assumes "state_invar s" "\<sigma>_invar \<sigma> (dom (thr_\<alpha> (thr s)))" "t \<in> (dom (thr_\<alpha> (thr s)))"
  and "wset_thread_ok (ws_\<alpha> (wset s)) (thr_\<alpha> (thr s))"
  shows "redT_upd (state_\<alpha> s) t ta x' m' (state_\<alpha> (exec_upd \<sigma> s t ta x' m'))"
  and "state_invar (exec_upd \<sigma> s t ta x' m')"
using assms unfolding wset_thread_ok_conv_dom
by(auto simp add: thr.update_correct thr.lookup_correct intro: exec_updWs_correct)

lemma execT_None:
  assumes invar: "state_invar s" "\<sigma>_invar \<sigma> (dom (thr_\<alpha> (thr s)))"
  and exec: "execT \<sigma> s = None"
  shows "\<alpha>.active_threads (state_\<alpha> s) = {}"
using assms
by(cases "schedule \<sigma> s")(fastsimp simp add: execT_def thr.lookup_correct dest: schedule_Some_NoneD schedule_NoneD)+

lemma execT_Some:
  assumes invar: "state_invar s" "\<sigma>_invar \<sigma> (dom (thr_\<alpha> (thr s)))"
  and wstok: "wset_thread_ok (ws_\<alpha> (wset s)) (thr_\<alpha> (thr s))"
  and exec: "execT \<sigma> s = \<lfloor>(\<sigma>', t, ta, s')\<rfloor>"
  shows "\<alpha>.redT (state_\<alpha> s) (t, ta) (state_\<alpha> s')" (is "?thesis1")
  and "state_invar s'" (is "?thesis2")
  and "\<sigma>_invar \<sigma>' (dom (thr_\<alpha> (thr s')))" (is "?thesis3")
proof -
  note [simp del] = redT_upd_simps exec_upd_def

  have "?thesis1 \<and> ?thesis2 \<and> ?thesis3"
  proof(cases "fst (snd (the (schedule \<sigma> s)))")
    case None
    with exec invar have schedule: "schedule \<sigma> s = \<lfloor>(t, None, \<sigma>')\<rfloor>"
      and ta: "ta = (\<lambda>\<^isup>f [], [], [], [], convert_RA (snd (the (thr_\<alpha> (thr s) t))))"
      and s': "s' = (acquire_all (locks s) t (snd (the (thr_\<alpha> (thr s) t))), (thr_update t (fst (the (thr_\<alpha> (thr s) t)), no_wait_locks) (thr s), shr s), wset s)"
      by(auto simp add: execT_def Option_bind_eq_Some_conv thr.lookup_correct split_beta split del: option.split_asm)
    from schedule_Some_NoneD[OF schedule invar]
    obtain x ln n where t: "thr_\<alpha> (thr s) t = \<lfloor>(x, ln)\<rfloor>"
      and "0 < ln\<^sub>f n" "\<not> waiting (ws_\<alpha> (wset s) t)" "may_acquire_all (locks s) t ln" by blast
    hence ?thesis1 using ta s' invar by(auto intro: \<alpha>.redT.redT_acquire simp add: thr.update_correct)
    moreover from invar s' have "?thesis2" by(simp add: thr.update_correct)
    moreover from t s' invar have "dom (thr_\<alpha> (thr s')) = dom (thr_\<alpha> (thr s))" by(auto simp add: thr.update_correct)
    hence "?thesis3" using invar schedule by(auto intro: schedule_invar_None)
    ultimately show ?thesis by simp
  next
    case (Some taxm)
    with exec invar obtain x' m' 
      where schedule: "schedule \<sigma> s = \<lfloor>(t, \<lfloor>(ta, x', m')\<rfloor>, \<sigma>')\<rfloor>"
      and s': "s' = exec_upd \<sigma> s t ta x' m'"
      by(cases taxm)(fastsimp simp add: execT_def Option_bind_eq_Some_conv split del: option.split_asm)
    from schedule_Some_SomeD[OF schedule invar]
    obtain x where t: "thr_\<alpha> (thr s) t = \<lfloor>(x, no_wait_locks)\<rfloor>" 
      and "Predicate.eval (r t (x, shr s)) (ta, x', m')" 
      and aok: "\<alpha>.actions_ok (state_\<alpha> s) t ta" by blast
    with s' have ?thesis1 using invar wstok
      by(fastsimp intro: \<alpha>.redT.intros exec_upd_correct)
    moreover from invar s' t wstok have ?thesis2 by(auto intro: exec_upd_correct)
    moreover {
      from schedule invar
      have "\<sigma>_invar \<sigma>' (dom (thr_\<alpha> (thr s)) \<union> {t. \<exists>x m. NewThread t x m \<in> set \<lbrace>ta\<rbrace>\<^bsub>t\<^esub>})"
        by(rule schedule_invar_Some)
      also have "dom (thr_\<alpha> (thr s)) \<union> {t. \<exists>x m. NewThread t x m \<in> set \<lbrace>ta\<rbrace>\<^bsub>t\<^esub>} = dom (thr_\<alpha> (thr s'))"
        using invar s' aok t
        by(auto simp add: exec_upd_def thr.lookup_correct thr.update_correct simp del: split_paired_Ex)(fastsimp dest: redT_updTs_new_thread intro: redT_updTs_Some1 redT_updTs_new_thread_ts simp del: split_paired_Ex)+
      finally have "\<sigma>_invar \<sigma>' (dom (thr_\<alpha> (thr s')))" . }
    ultimately show ?thesis by simp
  qed
  thus ?thesis1 ?thesis2 ?thesis3 by simp_all
qed

lemma exec_step_into_redT:
  assumes invar: "state_invar s" "\<sigma>_invar \<sigma> (dom (thr_\<alpha> (thr s)))" 
  and wstok: "wset_thread_ok (ws_\<alpha> (wset s)) (thr_\<alpha> (thr s))"
  and exec: "exec_step (\<sigma>, s) = Inl (q, \<sigma>', s')"
  obtains t ta
  where "\<alpha>.redT (state_\<alpha> s) (t, ta) (state_\<alpha> s')" "q = output \<sigma> t ta"
  and "state_invar s'" "\<sigma>_invar \<sigma>' (dom (thr_\<alpha> (thr s')))"
proof -
  from exec obtain t ta where execT: "execT \<sigma> s = \<lfloor>(\<sigma>', t, ta, s')\<rfloor>" 
    and q: "q = output \<sigma> t ta"
    by(fastsimp simp add: exec_step.simps split_beta)
  from invar wstok execT have red: "\<alpha>.redT (state_\<alpha> s) (t, ta) (state_\<alpha> s')" 
    and invar': "state_invar s'" "\<sigma>_invar \<sigma>' (dom (thr_\<alpha> (thr s')))"
    by(rule execT_Some)+
  with q show thesis by -(rule that)
qed

end

locale scheduler_ext =
  scheduler_ext_base
    final r convert_RA
    schedule "output" \<sigma>_invar
    thr_\<alpha> thr_invar thr_empty thr_lookup thr_update thr_iterate
    ws_\<alpha> ws_invar ws_empty ws_lookup ws_update ws_delete ws_iterate ws_sel
    thr'_\<alpha> thr'_invar thr'_empty thr'_ins_dj
  +
  scheduler_spec
    final r convert_RA
    schedule \<sigma>_invar
    thr_\<alpha> thr_invar
    ws_\<alpha> ws_invar 
  +
  thr!: finite_map thr_\<alpha> thr_invar +
  thr!: map_empty thr_\<alpha> thr_invar thr_empty +
  thr!: map_lookup thr_\<alpha> thr_invar thr_lookup +
  thr!: map_update thr_\<alpha> thr_invar thr_update +
  thr!: map_iterate thr_\<alpha> thr_invar thr_iterate +
  ws!: map ws_\<alpha> ws_invar +
  ws!: map_empty ws_\<alpha> ws_invar ws_empty +
  ws!: map_lookup ws_\<alpha> ws_invar ws_lookup +
  ws!: map_update ws_\<alpha> ws_invar ws_update +
  ws!: map_delete ws_\<alpha> ws_invar ws_delete +
  ws!: map_iterate ws_\<alpha> ws_invar ws_iterate +
  ws!: map_sel' ws_\<alpha> ws_invar ws_sel +
  thr'!: finite_set thr'_\<alpha> thr'_invar +
  thr'!: set_empty thr'_\<alpha> thr'_invar thr'_empty +
  thr'!: set_ins_dj thr'_\<alpha> thr'_invar thr'_ins_dj  
  for final :: "'x \<Rightarrow> bool"
  and r :: "'t \<Rightarrow> ('x \<times> 'm) \<Rightarrow> (('l,'t,'x,'m,'w,'o list) thread_action \<times> 'x \<times> 'm) Predicate.pred"
  and convert_RA :: "'l released_locks \<Rightarrow> 'o list"
  and schedule :: "('l,'t,'x,'m,'w,'o,'m_t,'m_w,'s) scheduler"
  and "output" :: "'s \<Rightarrow> 't \<Rightarrow> ('l,'t,'x,'m,'w,'o list) thread_action \<Rightarrow> 'q option"
  and \<sigma>_invar :: "'s \<Rightarrow> 't set \<Rightarrow> bool"
  and thr_\<alpha> :: "'m_t \<Rightarrow> ('l,'t,'x) thread_info"
  and thr_invar :: "'m_t \<Rightarrow> bool"
  and thr_empty :: "'m_t"
  and thr_lookup :: "'t \<Rightarrow> 'm_t \<rightharpoonup> ('x \<times> 'l released_locks)"
  and thr_update :: "'t \<Rightarrow> 'x \<times> 'l released_locks \<Rightarrow> 'm_t \<Rightarrow> 'm_t"
  and thr_iterate :: "('m_t, 't, 'x \<times> 'l released_locks, 's_t) map_iterator"
  and ws_\<alpha> :: "'m_w \<Rightarrow> ('w,'t) wait_sets"
  and ws_invar :: "'m_w \<Rightarrow> bool"
  and ws_empty :: "'m_w"
  and ws_lookup :: "'t \<Rightarrow> 'm_w \<rightharpoonup> 'w wait_set_status"
  and ws_update :: "'t \<Rightarrow> 'w wait_set_status \<Rightarrow> 'm_w \<Rightarrow> 'm_w"
  and ws_delete :: "'t \<Rightarrow> 'm_w \<Rightarrow> 'm_w"
  and ws_iterate :: "('m_w, 't, 'w wait_set_status, 'm_w) map_iterator"
  and ws_sel :: "'m_w \<Rightarrow> ('t \<Rightarrow> 'w wait_set_status \<Rightarrow> bool) \<rightharpoonup> ('t \<times> 'w wait_set_status)"
  and thr'_\<alpha> :: "'s_t \<Rightarrow> 't set"
  and thr'_invar :: "'s_t \<Rightarrow> bool"
  and thr'_empty :: "'s_t"
  and thr'_ins_dj :: "'t \<Rightarrow> 's_t \<Rightarrow> 's_t"

sublocale scheduler_ext < 
  pick_wakeup_spec
    final r convert_RA
    pick_wakeup \<sigma>_invar
    thr_\<alpha> thr_invar
    ws_\<alpha> ws_invar
by(rule pick_wakeup_spec_via_sel)(unfold_locales)

sublocale scheduler_ext < 
  scheduler
    final r convert_RA
    schedule "output" "pick_wakeup" \<sigma>_invar
    thr_\<alpha> thr_invar thr_empty thr_lookup thr_update
    ws_\<alpha> ws_invar ws_empty ws_lookup ws_update ws_delete ws_iterate
by(unfold_locales)

context scheduler_ext begin

lemma active_threads_correct [simp]:
  assumes "state_invar s"
  shows "thr'_\<alpha> (active_threads s) = \<alpha>.active_threads (state_\<alpha> s)" (is "?thesis1")
  and "thr'_invar (active_threads s)" (is "?thesis2")
proof -
  obtain ls ts m ws where s: "s = (ls, (ts, m), ws)" by(cases s) auto
  let ?f = "\<lambda>t (x, ln) TS. if ln = no_wait_locks
           then if Predicate.holds (do { (ta, _) \<leftarrow> r t (x, m); Predicate.if_pred (actions_ok (ls, (ts, m), ws) t ta) })
                then thr'_ins_dj t TS else TS
           else if \<not> waiting (ws_lookup t ws) \<and> may_acquire_all ls t ln then thr'_ins_dj t TS else TS"
  let ?I = "\<lambda>T TS. thr'_invar TS \<and> thr'_\<alpha> TS \<subseteq> dom (thr_\<alpha> ts) - T \<and> (\<forall>t. t \<notin> T \<longrightarrow> t \<in> thr'_\<alpha> TS \<longleftrightarrow> t \<in> \<alpha>.active_threads (state_\<alpha> s))"

  from assms s have "thr_invar ts" by simp
  moreover have "?I (dom (thr_\<alpha> ts)) thr'_empty"
    by(auto simp add: thr'.empty_correct s elim: \<alpha>.active_threads.cases)
  ultimately have "?I {} (thr_iterate ?f ts thr'_empty)"
  proof(rule thr.iterate_rule)
    fix t xln T TS
    assume tT: "t \<in> T" 
      and tst: "thr_\<alpha> ts t = \<lfloor>xln\<rfloor>"
      and Tdom: "T \<subseteq> dom (thr_\<alpha> ts)"
      and I: "?I T TS"
    obtain x ln where xln: "xln = (x, ln)" by(cases xln)
    from tT I have t: "t \<notin> thr'_\<alpha> TS" by blast

    from I have invar: "thr'_invar TS" ..
    hence "thr'_invar (?f t xln TS)" using t
      unfolding xln by(auto simp add: thr'.ins_dj_correct)
    moreover from I have "thr'_\<alpha> TS \<subseteq> dom (thr_\<alpha> ts) - T" by blast
    hence "thr'_\<alpha> (?f t xln TS) \<subseteq> dom (thr_\<alpha> ts) - (T - {t})"
      using invar tst t by(auto simp add: xln thr'.ins_dj_correct)
    moreover
    {
      fix t'
      assume t': "t' \<notin> T - {t}"
      have "t' \<in> thr'_\<alpha> (?f t xln TS) \<longleftrightarrow> t' \<in> \<alpha>.active_threads (state_\<alpha> s)" (is "?lhs \<longleftrightarrow> ?rhs")
      proof(cases "t' = t")
        case True
        show ?thesis
        proof
          assume ?lhs
          with True xln invar tst `state_invar s` t show ?rhs
            by(fastsimp simp add: holds_eq thr'.ins_dj_correct s split_beta ws.lookup_correct split: split_if_asm elim!: bindE if_predE intro: \<alpha>.active_threads.intros)
        next
          assume ?rhs
          with True xln invar tst `state_invar s` t show ?lhs
            by(fastsimp elim!: \<alpha>.active_threads.cases simp add: holds_eq s thr'.ins_dj_correct ws.lookup_correct elim!: bindE if_predE intro: bindI if_predI)
        qed
      next
        case False
        with t' have "t' \<notin> T" by simp
        with I have "t' \<in> thr'_\<alpha> TS \<longleftrightarrow> t' \<in> \<alpha>.active_threads (state_\<alpha> s)" by blast
        thus ?thesis using xln False invar t by(auto simp add: thr'.ins_dj_correct)
      qed
    }
    ultimately show "?I (T - {t}) (?f t xln TS)" by blast
  qed
  thus "?thesis1" "?thesis2" by(auto simp add: s)
qed

end


subsection {* Code Generator setup *}

lemmas [code] =
  scheduler_base_aux.free_thread_id_def
  scheduler_base_aux.redT_updT.simps
  scheduler_base_aux.redT_updTs_def
  scheduler_base_aux.thread_ok.simps
  scheduler_base_aux.thread_oks.simps
  scheduler_base_aux.wset_actions_ok_def
  scheduler_base_aux.cond_action_ok.simps
  scheduler_base_aux.cond_action_oks_def
  scheduler_base_aux.actions_ok_def

lemmas [code] =
  scheduler_base.exec_updW.simps
  scheduler_base.exec_updWs_def
  scheduler_base.exec_upd_def
  scheduler_base.execT_def
  scheduler_base.exec_step.simps
  scheduler_base.exec_aux_def
  scheduler_base.exec_def

lemmas [code] =
  scheduler_ext_base.active_threads.simps



end