theory GeneralTriangle
imports Complex_Main
begin

section {* Type definitions *}

text {* Since we are only considering acute-angled triangles, we define @{text
angles} as numbers from the real interval $[0\ldots 90]$. *}

abbreviation "angles \<equiv> { x::real . 0 \<le> x \<and> x \<le> 90 }"

text {* Triangles are represented as lists consisting of exactly three angles
which add up to 180\textdegree. As we consider triangles up to similarity, we
assume the angles to be given in ascending order.

Isabelle expects us to prove that the type is not empty, which we do by an example.

*}

definition
  "triangle =
    { l . l \<in> lists angles \<and> 
                    length l = 3 \<and>
                    listsum l = 180 \<and>
                    sorted l
                    }"

typedef (open) triangle = triangle
  unfolding triangle_def
  apply (rule_tac x = "[45,45,90]" in exI)
  apply auto
  done

text {* For convenience, the following lemma gives us easy access to the three angles
of a triangle and their properties. *}

lemma unfold_triangle:
  obtains a b c 
  where "Rep_triangle t = [a,b,c]"
    and "a \<in> angles"
    and "b \<in> angles"
    and "c \<in> angles"
    and "a + b + c = 180"
    and "a \<le> b"
    and "b \<le> c"
proof-
  obtain a b c where
  "a = Rep_triangle t ! 0" and "b = Rep_triangle t ! 1" and "c = Rep_triangle t ! 2"
    using Rep_triangle[of t]
    by (auto simp add:triangle_def)
  hence "Rep_triangle t = [a,b,c]"
    using Rep_triangle[of t]
    apply (auto simp add:triangle_def)
    apply (cases "Rep_triangle t", auto)
    apply (case_tac "list", auto)
    apply (case_tac "lista", auto)
    done
  with that show thesis
    using Rep_triangle[of t]
    by (auto simp add:triangle_def)
qed

section {* Property definitions *}

text {* Two angles can be considered too similar if they differ by less than
15\textdegree. This number is obtained heuristically by a field experiment with
an 11th grade class and was chosen that statistically, 99\% will consider the
angles as different. *}

definition similar_angle :: "real \<Rightarrow> real \<Rightarrow> bool"  (infix "\<sim>" 50)
  where "similar_angle x y = (abs (x - y) < 15)"

text {* The usual definitions of right-angled and isosceles, using the just
introduced similarity for comparison of angles. *}

definition right_angled
  where "right_angled l = (\<exists> x \<in> set (Rep_triangle l). x \<sim> 90)"

definition isosceles
  where "isosceles l = ((Rep_triangle l) ! 0 \<sim> (Rep_triangle l) ! 1 \<or>
                        (Rep_triangle l) ! 1 \<sim> (Rep_triangle l) ! (Suc 1))"

text {* A triangle is special if it is isosceles or right-angled, and general
if not. Equilateral triangle are isosceles and thus not mentioned on their own
here. *}

definition special
  where "special t = (isosceles t \<or> right_angled t)"

definition general
  where "general t = (\<not> special t)"

section {* The Theorem *}

theorem "\<exists>! t. general t"
txt {* The proof proceeds in two steps: There is a general triangle, and it is
       unique. For the first step we give the triangle (angles 45\textdegree,
       60\textdegree and 75\textdegree), show that it is a triangle and that it
       is general. *}
proof
  have is_t [simp]: "[45, 60, 75] \<in> triangle" by (auto simp add: triangle_def)
  show "general (Abs_triangle [45,60,75])" (is "general ?t")
  by (auto simp add:general_def special_def isosceles_def right_angled_def
                    Abs_triangle_inverse similar_angle_def)
next
  txt {* For the second step, we give names to the three angles and
         successively find upper bounds to them. *}
  fix t
  obtain a b c where 
    abc: "Rep_triangle t = [a,b,c]"
    and "a \<in> angles" and "b \<in> angles" and "c \<in> angles"
    and "a \<le> b" and "b \<le> c"
    and "a + b + c = 180"
  by (rule unfold_triangle)

  assume "general t"
  hence ni: "\<not> isosceles t" and nra: "\<not> right_angled t"
    by (auto simp add: general_def special_def)

  have "\<not> c \<sim> 90" using nra abc 
    by (auto simp add:right_angled_def)
  hence "c \<le> 75" using `c \<in> angles`
    by (auto simp add:similar_angle_def)

  have "\<not> b \<sim> c" using ni abc
    by (auto simp add:isosceles_def)
  hence "b \<le> 60" using `b \<le> c` and `c \<le> 75`
    by (auto simp add:similar_angle_def)
  
  have "\<not> a \<sim> b" using ni abc
    by (auto simp add:isosceles_def)
  hence "a \<le> 45" using `a \<le> b` and `b \<le> 60`
    by (auto simp add:similar_angle_def)
  
  txt {* The upper bound is actually the value, or we would not have a triangle *}
  have "\<not> (c < 75 \<or> b < 60 \<or> a < 45)"
  proof
    assume "c < 75 \<or> b < 60 \<or> a < 45"
    hence "a + b + c < 180" using `c \<le> 75` `b \<le> 60` `a \<le> 45`
                            and `a \<in> angles` `b \<in> angles` `c \<in> angles`
      by auto
    thus False using `a + b + c = 180` by auto
  qed
  hence "c = 75" and "b = 60" and "a = 45"
    using `c \<le> 75` `b \<le> 60` `a \<le> 45`
    by auto

  txt {* And this concludes the proof. *}
  hence "Abs_triangle (Rep_triangle t) = Abs_triangle [45, 60, 75]"
    using abc by simp
  thus "t = Abs_triangle [45, 60, 75]" by (simp add: Rep_triangle_inverse)
qed

end
