(*  Title:      Isomorphism Classes of Groups
    Author:     Jakob von Raumer, Karlsruhe Institute of Technology
    Maintainer: Jakob von Raumer <jakob.raumer@student.kit.edu>
*)

theory GroupIsoClasses
imports
  "Groups"
  "List"
  "Coset"
begin

section {* Isomorphism Classes of Groups *}

text {* We construct a quotient type for isomorphism classes of groups. *}

typedef 'a group = "{G :: 'a monoid. group G}"
proof
  show "\<And>a. \<lparr>carrier = {a}, mult = (\<lambda>x y. x), one = a\<rparr> \<in> {G. group G}"
  unfolding group_def group_axioms_def monoid_def Units_def by auto
qed

definition group_iso_rel :: "'a group \<Rightarrow> 'a group \<Rightarrow> bool"
  where "group_iso_rel G H = (\<exists>\<phi>. \<phi> \<in> Rep_group G \<cong> Rep_group H)"

quotient_type 'a group_iso_class = "'a group" / group_iso_rel
  morphisms Rep_group_iso Abs_group_iso
proof (rule equivpI)
  show "reflp group_iso_rel"
  proof (rule reflpI)
    fix G :: "'b group"
    show "group_iso_rel G G"
    unfolding group_iso_rel_def using Rep_group iso_refl by auto
  qed
next
  show "symp group_iso_rel"
  proof (rule sympI)
    fix G H :: "'b group"
    assume "group_iso_rel G H"
    then obtain \<phi> where "\<phi> \<in> Rep_group G \<cong> Rep_group H" unfolding group_iso_rel_def by auto
    then obtain \<phi>' where "\<phi>' \<in> Rep_group H \<cong> Rep_group G" using group.iso_sym Rep_group by fastforce
    thus "group_iso_rel H G" unfolding group_iso_rel_def by auto
  qed
next
  show "transp group_iso_rel" 
  proof (rule transpI)
    fix G H I :: "'b group"
    assume "group_iso_rel G H" "group_iso_rel H I"
    then obtain \<phi> \<psi> where "\<phi> \<in> Rep_group G \<cong> Rep_group H" "\<psi> \<in> Rep_group H \<cong> Rep_group I" unfolding group_iso_rel_def by auto
    then obtain \<pi> where "\<pi> \<in> Rep_group G \<cong> Rep_group I" using group.iso_trans Rep_group by fastforce
    thus "group_iso_rel G I" unfolding group_iso_rel_def by auto
  qed
qed

text {* This assigns to a given group the group isomorphism class *}

definition (in group) iso_class :: "'a group_iso_class"
  where "iso_class = Abs_group_iso (Abs_group (monoid.truncate G))"

text {* Two isomorphic groups do indeed have the same isomorphism class: *}

lemma iso_classes_iff:
  assumes "group G"
  assumes "group H"
  shows "(\<exists>\<phi>. \<phi> \<in> G \<cong> H) = (group.iso_class G = group.iso_class H)"
proof -
  from assms(1,2) have groups:"group (monoid.truncate G)" "group (monoid.truncate H)"
    unfolding monoid.truncate_def group_def group_axioms_def Units_def monoid_def by auto
  have "(\<exists>\<phi>. \<phi> \<in> G \<cong> H) = (\<exists>\<phi>. \<phi> \<in> (monoid.truncate G) \<cong> (monoid.truncate H))"
    unfolding iso_def hom_def monoid.truncate_def by auto
  also have "\<dots> = group_iso_rel (Abs_group (monoid.truncate G)) (Abs_group (monoid.truncate H))"
    unfolding group_iso_rel_def using groups group.Abs_group_inverse by (metis mem_Collect_eq)
  also have "\<dots> = (group.iso_class G = group.iso_class H)" using group.iso_class_def assms group_iso_class.abs_eq_iff by metis
  finally show ?thesis.
qed

end
