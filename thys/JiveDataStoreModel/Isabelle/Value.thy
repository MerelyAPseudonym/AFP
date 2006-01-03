(*  Title:       Jive Data and Store Model
    ID:          $Id: Value.thy,v 1.3 2005-09-06 15:06:08 makarius Exp $
    Author:      Norbert Schirmer <schirmer@informatik.tu-muenchen.de>  and  
                 Nicole Rauch <rauch@informatik.uni-kl.de>, 2003
    Maintainer:  Nicole Rauch <rauch@informatik.uni-kl.de>
    License:     LGPL
*)
 
header {* Value *}

theory Value imports Subtype begin

text {* This theory contains our model of the values in the store. The store is untyped, therefore all
  types that exist in Java are wrapped into one type @{text Value}.

  In a first approach, the primitive Java types supported in this formalization are 
  mapped to similar Isabelle
  types. Later, we will have
  proper formalizations of the Java types in Isabelle, which will then be used here.
  *}
  
types JavaInt   = int
types JavaShort = int
types JavaByte  = int
types JavaBoolean  = bool

text {* The objects of each class are identified by a unique ID.
We use elements of type @{typ nat} here, but in general it is sufficient to use
an infinite type with a successor function and a comparison predicate.
*}

types ObjectId  = nat

text {* The definition of the datatype @{text Value}. Values can be of the Java types 
boolean, int, short and byte. Additionally, they can be an object reference,
an array reference or the value null. *}

datatype Value = boolV  JavaBoolean
               | intgV  JavaInt  
               | shortV JavaShort
               | byteV  JavaByte
               | objV   CTypeId ObjectId   --{*typed object reference *}
               | arrV   Arraytype ObjectId --{*typed array reference *}
               | nullV
               

text {* Arrays are modeled as references just like objects. So they
can be viewed as special kinds of objects, like in Java.  *}

subsection {* Discriminator Functions *}

text {* To test values, we define the following discriminator functions. *}

consts isBoolV  :: "Value \<Rightarrow> bool" 
       isIntgV  :: "Value \<Rightarrow> bool"
       isShortV :: "Value \<Rightarrow> bool"
       isByteV  :: "Value \<Rightarrow> bool"
       isRefV   :: "Value \<Rightarrow> bool"
       isObjV   :: "Value \<Rightarrow> bool"
       isArrV   :: "Value \<Rightarrow> bool"
       isNullV  :: "Value \<Rightarrow> bool"

defs isBoolV_def:
"isBoolV v \<equiv> (case v of
               boolV b  \<Rightarrow> True 
             | intgV i  \<Rightarrow> False
             | shortV s \<Rightarrow> False
             | byteV  by \<Rightarrow> False
             | objV C a \<Rightarrow> False
             | arrV T a \<Rightarrow> False
             | nullV    \<Rightarrow> False)"

lemma isBoolV_simps [simp]:
"isBoolV (boolV b)       = True" 
"isBoolV (intgV i)       = False"
"isBoolV (shortV s)      = False"
"isBoolV (byteV by)       = False"
"isBoolV (objV C a)      = False"
"isBoolV (arrV T a)      = False"
"isBoolV (nullV)         = False"
  by (simp_all add: isBoolV_def)
 
defs isIntgV_def:
"isIntgV v \<equiv> (case v of
               boolV b  \<Rightarrow> False 
             | intgV i  \<Rightarrow> True
             | shortV s \<Rightarrow> False
             | byteV by  \<Rightarrow> False
             | objV C a \<Rightarrow> False
             | arrV T a \<Rightarrow> False
             | nullV    \<Rightarrow> False)" 

lemma isIntgV_simps [simp]:
"isIntgV (boolV b)       = False" 
"isIntgV (intgV i)       = True"
"isIntgV (shortV s)       = False"
"isIntgV (byteV by)       = False"
"isIntgV (objV C a)      = False"
"isIntgV (arrV T a)      = False"
"isIntgV (nullV)         = False"
  by (simp_all add: isIntgV_def)



defs isShortV_def:
"isShortV v \<equiv> (case v of
               boolV b  \<Rightarrow> False 
             | intgV i  \<Rightarrow> False
             | shortV s \<Rightarrow> True
             | byteV by  \<Rightarrow> False
             | objV C a \<Rightarrow> False
             | arrV T a \<Rightarrow> False
             | nullV    \<Rightarrow> False)" 

lemma isShortV_simps [simp]:
"isShortV (boolV b)     = False" 
"isShortV (intgV i)     = False"
"isShortV (shortV s)    = True"
"isShortV (byteV by)     = False"
"isShortV (objV C a)    = False"
"isShortV (arrV T a)    = False"
"isShortV (nullV)       = False"
  by (simp_all add: isShortV_def)


defs isByteV_def:
"isByteV v \<equiv> (case v of
               boolV b  \<Rightarrow> False 
             | intgV i  \<Rightarrow> False
             | shortV s \<Rightarrow> False
             | byteV by  \<Rightarrow> True
             | objV C a \<Rightarrow> False
             | arrV T a \<Rightarrow> False
             | nullV    \<Rightarrow> False)" 

lemma isByteV_simps [simp]:
"isByteV (boolV b)      = False" 
"isByteV (intgV i)      = False"
"isByteV (shortV s)     = False"
"isByteV (byteV by)      = True"
"isByteV (objV C a)     = False"
"isByteV (arrV T a)     = False"
"isByteV (nullV)        = False"
  by (simp_all add: isByteV_def)

defs isRefV_def:
"isRefV v \<equiv>  (case v of
               boolV b  \<Rightarrow> False 
             | intgV i  \<Rightarrow> False
             | shortV s \<Rightarrow> False
             | byteV by \<Rightarrow> False
             | objV C a  \<Rightarrow> True
             | arrV T a  \<Rightarrow> True
             | nullV     \<Rightarrow> True)"

lemma isRefV_simps [simp]:
"isRefV (boolV b)       = False" 
"isRefV (intgV i)       = False"
"isRefV (shortV s)      = False"
"isRefV (byteV by)      = False"
"isRefV (objV C a)      = True"
"isRefV (arrV T a)      = True"
"isRefV (nullV)         = True"
  by (simp_all add: isRefV_def)


defs isObjV_def:
"isObjV v \<equiv>  (case v of
               boolV b  \<Rightarrow> False 
             | intgV i  \<Rightarrow> False
             | shortV s  \<Rightarrow> False
             | byteV by  \<Rightarrow> False
             | objV C a \<Rightarrow> True
             | arrV T a \<Rightarrow> False
             | nullV    \<Rightarrow> False)"

lemma isObjV_simps [simp]:
"isObjV (boolV b)  = False" 
"isObjV (intgV i)  = False"
"isObjV (shortV s)  = False"
"isObjV (byteV by)  = False"
"isObjV (objV c a) = True" 
"isObjV (arrV T a) = False"
"isObjV nullV      = False"
  by (simp_all add: isObjV_def)


defs isArrV_def:
"isArrV v \<equiv>  (case v of
               boolV b  \<Rightarrow> False 
             | intgV i  \<Rightarrow> False
             | shortV s  \<Rightarrow> False
             | byteV by  \<Rightarrow> False
             | objV C a \<Rightarrow> False
             | arrV T a \<Rightarrow> True
             | nullV    \<Rightarrow> False)"

lemma isArrV_simps [simp]:
"isArrV (boolV b)  = False" 
"isArrV (intgV i)  = False"
"isArrV (shortV s)  = False"
"isArrV (byteV by)  = False"
"isArrV (objV c a) = False" 
"isArrV (arrV T a) = True"
"isArrV nullV      = False"
  by (simp_all add: isArrV_def)


defs isNullV_def:
"isNullV v \<equiv>  (case v of
               boolV b  \<Rightarrow> False 
             | intgV i  \<Rightarrow> False
             | shortV s  \<Rightarrow> False
             | byteV by  \<Rightarrow> False
             | objV C a \<Rightarrow> False
             | arrV T a \<Rightarrow> False
             | nullV    \<Rightarrow> True)"

lemma isNullV_simps [simp]:
"isNullV (boolV b)   = False" 
"isNullV (intgV i)   = False"
"isNullV (shortV s)   = False"
"isNullV (byteV by)   = False"
"isNullV (objV c a) = False" 
"isNullV (arrV T a) = False"
"isNullV nullV      = True"
  by (simp_all add: isNullV_def)

subsection {* Selector Functions *}

consts
aI    :: "Value \<Rightarrow> JavaInt"
aB    :: "Value \<Rightarrow> JavaBoolean"
aSh   :: "Value \<Rightarrow> JavaShort"
aBy   :: "Value \<Rightarrow> JavaByte"
tid   :: "Value \<Rightarrow> CTypeId"
oid   :: "Value \<Rightarrow> ObjectId"
jt    :: "Value \<Rightarrow> Javatype"
aid   :: "Value \<Rightarrow> ObjectId"


defs aI_def:
"aI v \<equiv>  case v of  
            boolV  b   \<Rightarrow> arbitrary
          | intgV  i   \<Rightarrow> i
          | shortV sh  \<Rightarrow> arbitrary
          | byteV  by  \<Rightarrow> arbitrary
          | objV   C a \<Rightarrow> arbitrary
          | arrV  T a  \<Rightarrow> arbitrary
          | nullV      \<Rightarrow> arbitrary"
lemma aI_simps [simp]:
"aI (intgV i) = i"
by (simp add: aI_def)


defs aB_def:
"aB v \<equiv>  case v of  
            boolV  b   \<Rightarrow> b
          | intgV  i   \<Rightarrow> arbitrary
          | shortV sh  \<Rightarrow> arbitrary
          | byteV  by  \<Rightarrow> arbitrary
          | objV   C a \<Rightarrow> arbitrary
          | arrV  T a  \<Rightarrow> arbitrary
          | nullV      \<Rightarrow> arbitrary"
lemma aB_simps [simp]:
"aB (boolV b) = b"
by (simp add: aB_def)


defs aSh_def:
"aSh v \<equiv>  case v of  
            boolV  b   \<Rightarrow> arbitrary
          | intgV  i   \<Rightarrow> arbitrary
          | shortV sh  \<Rightarrow> sh
          | byteV  by  \<Rightarrow> arbitrary
          | objV   C a \<Rightarrow> arbitrary
          | arrV  T a  \<Rightarrow> arbitrary
          | nullV      \<Rightarrow> arbitrary"
lemma aSh_simps [simp]:
"aSh (shortV sh) = sh"
by (simp add: aSh_def)


defs aBy_def:
"aBy v \<equiv>  case v of  
            boolV  b   \<Rightarrow> arbitrary
          | intgV  i   \<Rightarrow> arbitrary
          | shortV s   \<Rightarrow> arbitrary
          | byteV  by  \<Rightarrow> by
          | objV   C a \<Rightarrow> arbitrary
          | arrV  T a  \<Rightarrow> arbitrary
          | nullV      \<Rightarrow> arbitrary"
lemma aBy_simps [simp]:
"aBy (byteV by) = by"
by (simp add: aBy_def)

defs tid_def:
"tid v \<equiv> case v of
            boolV  b   \<Rightarrow> arbitrary
          | intgV  i   \<Rightarrow> arbitrary
          | shortV s   \<Rightarrow> arbitrary
          | byteV  by  \<Rightarrow> arbitrary
          | objV   C a \<Rightarrow> C
          | arrV  T a  \<Rightarrow> arbitrary
          | nullV      \<Rightarrow> arbitrary"

lemma tid_simps [simp]:
"tid (objV C a) = C"
by (simp add: tid_def)


defs oid_def:
"oid v \<equiv> case v of
            boolV  b   \<Rightarrow> arbitrary
          | intgV  i   \<Rightarrow> arbitrary
          | shortV s   \<Rightarrow> arbitrary
          | byteV  by  \<Rightarrow> arbitrary
          | objV   C a \<Rightarrow> a
          | arrV  T a  \<Rightarrow> arbitrary
          | nullV      \<Rightarrow> arbitrary"

lemma oid_simps [simp]:
"oid (objV C a) = a"
by (simp add: oid_def)



defs jt_def:
"jt v \<equiv> case v of
            boolV  b   \<Rightarrow> arbitrary
          | intgV  i   \<Rightarrow> arbitrary
          | shortV s   \<Rightarrow> arbitrary
          | byteV  by  \<Rightarrow> arbitrary
          | objV   C a \<Rightarrow> arbitrary
          | arrV  T a  \<Rightarrow> at2jt T
          | nullV      \<Rightarrow> arbitrary"

lemma jt_simps [simp]:
"jt (arrV T a) = at2jt T"
by (simp add: jt_def)


defs aid_def:
"aid v \<equiv> case v of
            boolV  b   \<Rightarrow> arbitrary
          | intgV  i   \<Rightarrow> arbitrary
          | shortV s   \<Rightarrow> arbitrary
          | byteV  by  \<Rightarrow> arbitrary
          | objV   C a \<Rightarrow> arbitrary
          | arrV  T a  \<Rightarrow> a
          | nullV      \<Rightarrow> arbitrary"

lemma aid_simps [simp]:
"aid (arrV T a) = a"
by (simp add: aid_def)

subsection{* Determining the Type of a Value *}

text {* To determine the type of a value, we define the function
@{text "typeof"}. This function is
often written as $\tau$ in theoretical texts, therefore we add
the appropriate syntax support. *}

constdefs typeof :: "Value \<Rightarrow> Javatype"
"typeof v \<equiv> (case v of
               boolV b  \<Rightarrow> BoolT 
             | intgV i  \<Rightarrow> IntgT
             | shortV sh  \<Rightarrow> ShortT
             | byteV by  \<Rightarrow> ByteT
             | objV C a \<Rightarrow> CClassT C
             | arrV T a \<Rightarrow> ArrT T
             | nullV    \<Rightarrow> NullT)"

syntax
 "_tau" :: "Value \<Rightarrow> Javatype" ("\<tau> _")

translations
 "\<tau> v" == "typeof v"

lemma typeof_simps [simp]:
"(\<tau> (boolV b)) = BoolT"
"(\<tau> (intgV i)) = IntgT"
"(\<tau> (shortV sh)) = ShortT"
"(\<tau> (byteV by)) = ByteT"
"(\<tau> (objV c a)) = CClassT c"
"(\<tau> (arrV t a)) = ArrT t"
"(\<tau> (nullV))   = NullT"
  by (simp_all add: typeof_def)


subsection {* Default Initialization Values for Types *}

text {* The function @{text "init"} yields the default initialization values for each 
type. For boolean, the
default value is False, for the integral types, it is 0, and for the reference
types, it is nullV.
*}

constdefs init :: "Javatype \<Rightarrow> Value"
"init T \<equiv> (case T of
             BoolT        \<Rightarrow> boolV  False
           | IntgT        \<Rightarrow> intgV  0
           | ShortT        \<Rightarrow> shortV 0
           | ByteT        \<Rightarrow> byteV  0
           | NullT        \<Rightarrow> nullV
           | ArrT T       \<Rightarrow> nullV
           | CClassT C     \<Rightarrow> nullV
           | AClassT C     \<Rightarrow> nullV
           | InterfaceT I \<Rightarrow> nullV)" 

lemma init_simps [simp]:
"init BoolT          = boolV False"
"init IntgT          = intgV 0"
"init ShortT         = shortV 0"
"init ByteT          = byteV 0"
"init NullT          = nullV"
"init (ArrT T)       = nullV"
"init (CClassT c)     = nullV"
"init (AClassT a)     = nullV"
"init (InterfaceT i) = nullV"
  by (simp_all add: init_def)

lemma typeof_init_widen [simp,intro]: "typeof (init T) \<le> T"
proof (cases T)
  assume c: "T = BoolT"
  show "(\<tau> (init T)) \<le> T"
    using c by simp
next
  assume c: "T = IntgT"
  show "(\<tau> (init T)) \<le> T"
    using c by simp
next
  assume c: "T = ShortT"
  show "(\<tau> (init T)) \<le> T"
    using c by simp
next
  assume c: "T = ByteT"
  show "(\<tau> (init T)) \<le> T"
    using c by simp
next
  assume c: "T = NullT"
  show "(\<tau> (init T)) \<le> T"
    using c by simp
next
  fix x
  assume c: "T = CClassT x"
  show "(\<tau> (init T)) \<le> T"
    using c by (cases x, simp_all)
next
  fix x
  assume c: "T = AClassT x"
  show "(\<tau> (init T)) \<le> T"
    using c by (cases x, simp_all)
next
  fix x
  assume c: "T = InterfaceT x"
  show "(\<tau> (init T)) \<le> T"
    using c by (cases x, simp_all)
next
  fix x
  assume c: "T = ArrT x"
  show "(\<tau> (init T)) \<le> T"
    using c 
  proof (cases x)
    fix y
    assume c2: "x = CClassAT y"
    show "(\<tau> (init T)) \<le> T"
      using c c2 by (cases y, simp_all)
  next
    fix y
    assume c2: "x = AClassAT y"
    show "(\<tau> (init T)) \<le> T"
      using c c2 by (cases y, simp_all)
  next
    fix y
    assume c2: "x = InterfaceAT y"
    show "(\<tau> (init T)) \<le> T"
      using c c2 by (cases y, simp_all)
  next
    assume c2: "x = BoolAT"
    show "(\<tau> (init T)) \<le> T"
      using c c2 by simp
  next
    assume c2: "x = IntgAT"
    show "(\<tau> (init T)) \<le> T"
      using c c2 by simp
  next
    assume c2: "x = ShortAT"
    show "(\<tau> (init T)) \<le> T"
      using c c2 by simp
  next
    assume c2: "x = ByteAT"
    show "(\<tau> (init T)) \<le> T"
      using c c2 by simp
  qed
qed

end