(* Title:     HOL/MiniML/Maybe.thy

   Author:    Wolfgang Naraschewski and Tobias Nipkow
   Copyright  1996 TU Muenchen
*)

header "Universal error monad"

theory Maybe
imports Main
begin

definition
  option_bind :: "['a option, 'a => 'b option] => 'b option" where
  "option_bind m f = (case m of None => None | Some r => f r)"

syntax "_option_bind" :: "[pttrns,'a option,'b] => 'c" ("(_ := _;//_)" 0)
translations "P := E; F" == "CONST option_bind E (%P. F)"


-- "constructor laws for @{text option_bind}"
lemma option_bind_Some: "option_bind (Some s) f = (f s)"
  by (simp add: option_bind_def)

lemma option_bind_None: "option_bind None f = None"
  by (simp add: option_bind_def)

declare option_bind_Some [simp] option_bind_None [simp]

-- "expansion of @{text option_bind}"
lemma split_option_bind: "P(option_bind res f) =  
          ((res = None --> P None) & (!s. res = Some s --> P(f s)))"
  unfolding option_bind_def
  by (rule option.split)

lemma option_bind_eq_None [simp]:
    "((option_bind m f) = None) = ((m=None) | (? p. m = Some p & f p = None))"
  by (simp split: split_option_bind)

lemma rotate_Some: "(y = Some x) = (Some x = y)"
  by (simp add: eq_sym_conv)

end
