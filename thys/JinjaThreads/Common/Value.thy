(*  Title:      JinjaThreads/Common/Value.thy
    Author:     David von Oheimb, Tobias Nipkow, Andreas Lochbihler

    Based on the Jinja theory Common/Value.thy by David von Oheimb and Tobias Nipkow

*)

header {* \isaheader{Jinja Values} *}

theory Value imports TypeRel begin

types addr = nat
types thread_id = addr

datatype val
  = Unit        -- "dummy result value of void expressions"
  | Null        -- "null reference"
  | Bool bool   -- "Boolean value"
  | Intg int    -- "integer value" 
  | Addr addr   -- "addresses of objects, arrays and threads in the heap"

consts
  default_val :: "ty \<Rightarrow> val"   -- "default value for all types"

primrec
  "default_val Void      = Unit"
  "default_val Boolean   = Bool False"
  "default_val Integer   = Intg 0"
  "default_val NT        = Null"
  "default_val (Class C) = Null"
  "default_val (Array A) = Null"


consts
  the_Intg :: "val \<Rightarrow> int"
  the_Addr :: "val \<Rightarrow> addr"

primrec
  "the_Intg (Intg i) = i"

primrec
  "the_Addr (Addr a) = a"

fun is_Addr :: "val \<Rightarrow> bool"
where
  "is_Addr (Addr a) = True"
| "is_Addr v        = False"

lemma is_AddrE [elim!]:
  "\<lbrakk> is_Addr v; \<And>a. v = Addr a \<Longrightarrow> thesis \<rbrakk> \<Longrightarrow> thesis"
by(cases v, auto)

fun is_Intg :: "val \<Rightarrow> bool"
where
  "is_Intg (Intg i) = True"
| "is_Intg v        = False"


lemma is_IntgE [elim!]:
  "\<lbrakk> is_Intg v; \<And>i. v = Intg i \<Longrightarrow> thesis \<rbrakk> \<Longrightarrow> thesis"
by(cases v, auto)

fun is_Bool :: "val \<Rightarrow> bool"
where
  "is_Bool (Bool b) = True"
| "is_Bool v        = False"

lemma is_BoolE [elim!]:
  "\<lbrakk> is_Bool v; \<And>a. v = Bool a \<Longrightarrow> thesis \<rbrakk> \<Longrightarrow> thesis"
by(cases v, auto)

constdefs
  is_Ref :: "val \<Rightarrow> bool"
  "is_Ref v \<equiv> v = Null \<or> is_Addr v"

lemma is_Ref_def2:
  "is_Ref v = (v = Null \<or> (\<exists>a. v = Addr a))"
  by (cases v) (auto simp add: is_Ref_def)

lemma [iff]: "is_Ref Null" by (simp add: is_Ref_def2)

end


