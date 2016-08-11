From iris.algebra Require Export cmra updates.
Local Hint Extern 1 (_ ≼ _) => etrans; [eassumption|].
Local Hint Extern 1 (_ ≼ _) => etrans; [|eassumption].
Local Hint Extern 10 (_ ≤ _) => omega.

Record uPred (M : ucmraT) : Type := IProp {
  uPred_holds :> nat → M → Prop;
  uPred_mono n x1 x2 : uPred_holds n x1 → x1 ≼{n} x2 → uPred_holds n x2;
  uPred_closed n1 n2 x : uPred_holds n1 x → n2 ≤ n1 → ✓{n2} x → uPred_holds n2 x
}.
Arguments uPred_holds {_} _ _ _ : simpl never.
Add Printing Constructor uPred.
Instance: Params (@uPred_holds) 3.

Delimit Scope uPred_scope with I.
Bind Scope uPred_scope with uPred.
Arguments uPred_holds {_} _%I _ _.

Section cofe.
  Context {M : ucmraT}.

  Inductive uPred_equiv' (P Q : uPred M) : Prop :=
    { uPred_in_equiv : ∀ n x, ✓{n} x → P n x ↔ Q n x }.
  Instance uPred_equiv : Equiv (uPred M) := uPred_equiv'.
  Inductive uPred_dist' (n : nat) (P Q : uPred M) : Prop :=
    { uPred_in_dist : ∀ n' x, n' ≤ n → ✓{n'} x → P n' x ↔ Q n' x }.
  Instance uPred_dist : Dist (uPred M) := uPred_dist'.
  Program Instance uPred_compl : Compl (uPred M) := λ c,
    {| uPred_holds n x := c n n x |}.
  Next Obligation. naive_solver eauto using uPred_mono. Qed.
  Next Obligation.
    intros c n1 n2 x ???; simpl in *.
    apply (chain_cauchy c n2 n1); eauto using uPred_closed.
  Qed.
  Definition uPred_cofe_mixin : CofeMixin (uPred M).
  Proof.
    split.
    - intros P Q; split.
      + by intros HPQ n; split=> i x ??; apply HPQ.
      + intros HPQ; split=> n x ?; apply HPQ with n; auto.
    - intros n; split.
      + by intros P; split=> x i.
      + by intros P Q HPQ; split=> x i ??; symmetry; apply HPQ.
      + intros P Q Q' HP HQ; split=> i x ??.
        by trans (Q i x);[apply HP|apply HQ].
    - intros n P Q HPQ; split=> i x ??; apply HPQ; auto.
    - intros n c; split=>i x ??; symmetry; apply (chain_cauchy c i n); auto.
  Qed.
  Canonical Structure uPredC : cofeT := CofeT (uPred M) uPred_cofe_mixin.
End cofe.
Arguments uPredC : clear implicits.

Instance uPred_ne {M} (P : uPred M) n : Proper (dist n ==> iff) (P n).
Proof.
  intros x1 x2 Hx; split=> ?; eapply uPred_mono; eauto; by rewrite Hx.
Qed.
Instance uPred_proper {M} (P : uPred M) n : Proper ((≡) ==> iff) (P n).
Proof. by intros x1 x2 Hx; apply uPred_ne, equiv_dist. Qed.

Lemma uPred_holds_ne {M} (P Q : uPred M) n1 n2 x :
  P ≡{n2}≡ Q → n2 ≤ n1 → ✓{n2} x → Q n1 x → P n2 x.
Proof.
  intros [Hne] ???. eapply Hne; try done.
  eapply uPred_closed; eauto using cmra_validN_le.
Qed.

(** functor *)
Program Definition uPred_map {M1 M2 : ucmraT} (f : M2 -n> M1)
  `{!CMRAMonotone f} (P : uPred M1) :
  uPred M2 := {| uPred_holds n x := P n (f x) |}.
Next Obligation. naive_solver eauto using uPred_mono, cmra_monotoneN. Qed.
Next Obligation. naive_solver eauto using uPred_closed, validN_preserving. Qed.

Instance uPred_map_ne {M1 M2 : ucmraT} (f : M2 -n> M1)
  `{!CMRAMonotone f} n : Proper (dist n ==> dist n) (uPred_map f).
Proof.
  intros x1 x2 Hx; split=> n' y ??.
  split; apply Hx; auto using validN_preserving.
Qed.
Lemma uPred_map_id {M : ucmraT} (P : uPred M): uPred_map cid P ≡ P.
Proof. by split=> n x ?. Qed.
Lemma uPred_map_compose {M1 M2 M3 : ucmraT} (f : M1 -n> M2) (g : M2 -n> M3)
    `{!CMRAMonotone f, !CMRAMonotone g} (P : uPred M3):
  uPred_map (g ◎ f) P ≡ uPred_map f (uPred_map g P).
Proof. by split=> n x Hx. Qed.
Lemma uPred_map_ext {M1 M2 : ucmraT} (f g : M1 -n> M2)
      `{!CMRAMonotone f} `{!CMRAMonotone g}:
  (∀ x, f x ≡ g x) → ∀ x, uPred_map f x ≡ uPred_map g x.
Proof. intros Hf P; split=> n x Hx /=; by rewrite /uPred_holds /= Hf. Qed.
Definition uPredC_map {M1 M2 : ucmraT} (f : M2 -n> M1) `{!CMRAMonotone f} :
  uPredC M1 -n> uPredC M2 := CofeMor (uPred_map f : uPredC M1 → uPredC M2).
Lemma uPredC_map_ne {M1 M2 : ucmraT} (f g : M2 -n> M1)
    `{!CMRAMonotone f, !CMRAMonotone g} n :
  f ≡{n}≡ g → uPredC_map f ≡{n}≡ uPredC_map g.
Proof.
  by intros Hfg P; split=> n' y ??;
    rewrite /uPred_holds /= (dist_le _ _ _ _(Hfg y)); last lia.
Qed.

Program Definition uPredCF (F : urFunctor) : cFunctor := {|
  cFunctor_car A B := uPredC (urFunctor_car F B A);
  cFunctor_map A1 A2 B1 B2 fg := uPredC_map (urFunctor_map F (fg.2, fg.1))
|}.
Next Obligation.
  intros F A1 A2 B1 B2 n P Q HPQ.
  apply uPredC_map_ne, urFunctor_ne; split; by apply HPQ.
Qed.
Next Obligation.
  intros F A B P; simpl. rewrite -{2}(uPred_map_id P).
  apply uPred_map_ext=>y. by rewrite urFunctor_id.
Qed.
Next Obligation.
  intros F A1 A2 A3 B1 B2 B3 f g f' g' P; simpl. rewrite -uPred_map_compose.
  apply uPred_map_ext=>y; apply urFunctor_compose.
Qed.

Instance uPredCF_contractive F :
  urFunctorContractive F → cFunctorContractive (uPredCF F).
Proof.
  intros ? A1 A2 B1 B2 n P Q HPQ.
  apply uPredC_map_ne, urFunctor_contractive=> i ?; split; by apply HPQ.
Qed.

(** logical entailement *)
Inductive uPred_entails {M} (P Q : uPred M) : Prop :=
  { uPred_in_entails : ∀ n x, ✓{n} x → P n x → Q n x }.
Hint Extern 0 (uPred_entails _ _) => reflexivity.
Instance uPred_entails_rewrite_relation M : RewriteRelation (@uPred_entails M).

Hint Resolve uPred_mono uPred_closed : uPred_def.

(** logical connectives *)
Program Definition uPred_pure_def {M} (φ : Prop) : uPred M :=
  {| uPred_holds n x := φ |}.
Solve Obligations with done.
Definition uPred_pure_aux : { x | x = @uPred_pure_def }. by eexists. Qed.
Definition uPred_pure {M} := proj1_sig uPred_pure_aux M.
Definition uPred_pure_eq :
  @uPred_pure = @uPred_pure_def := proj2_sig uPred_pure_aux.

Instance uPred_inhabited M : Inhabited (uPred M) := populate (uPred_pure True).

Program Definition uPred_and_def {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := P n x ∧ Q n x |}.
Solve Obligations with naive_solver eauto 2 with uPred_def.
Definition uPred_and_aux : { x | x = @uPred_and_def }. by eexists. Qed.
Definition uPred_and {M} := proj1_sig uPred_and_aux M.
Definition uPred_and_eq: @uPred_and = @uPred_and_def := proj2_sig uPred_and_aux.

Program Definition uPred_or_def {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := P n x ∨ Q n x |}.
Solve Obligations with naive_solver eauto 2 with uPred_def.
Definition uPred_or_aux : { x | x = @uPred_or_def }. by eexists. Qed.
Definition uPred_or {M} := proj1_sig uPred_or_aux M.
Definition uPred_or_eq: @uPred_or = @uPred_or_def := proj2_sig uPred_or_aux.

Program Definition uPred_impl_def {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := ∀ n' x',
       x ≼ x' → n' ≤ n → ✓{n'} x' → P n' x' → Q n' x' |}.
Next Obligation.
  intros M P Q n1 x1 x1' HPQ [x2 Hx1'] n2 x3 [x4 Hx3] ?; simpl in *.
  rewrite Hx3 (dist_le _ _ _ _ Hx1'); auto. intros ??.
  eapply HPQ; auto. exists (x2 ⋅ x4); by rewrite assoc.
Qed.
Next Obligation. intros M P Q [|n1] [|n2] x; auto with lia. Qed.
Definition uPred_impl_aux : { x | x = @uPred_impl_def }. by eexists. Qed.
Definition uPred_impl {M} := proj1_sig uPred_impl_aux M.
Definition uPred_impl_eq :
  @uPred_impl = @uPred_impl_def := proj2_sig uPred_impl_aux.

Program Definition uPred_forall_def {M A} (Ψ : A → uPred M) : uPred M :=
  {| uPred_holds n x := ∀ a, Ψ a n x |}.
Solve Obligations with naive_solver eauto 2 with uPred_def.
Definition uPred_forall_aux : { x | x = @uPred_forall_def }. by eexists. Qed.
Definition uPred_forall {M A} := proj1_sig uPred_forall_aux M A.
Definition uPred_forall_eq :
  @uPred_forall = @uPred_forall_def := proj2_sig uPred_forall_aux.

Program Definition uPred_exist_def {M A} (Ψ : A → uPred M) : uPred M :=
  {| uPred_holds n x := ∃ a, Ψ a n x |}.
Solve Obligations with naive_solver eauto 2 with uPred_def.
Definition uPred_exist_aux : { x | x = @uPred_exist_def }. by eexists. Qed.
Definition uPred_exist {M A} := proj1_sig uPred_exist_aux M A.
Definition uPred_exist_eq: @uPred_exist = @uPred_exist_def := proj2_sig uPred_exist_aux.

Program Definition uPred_eq_def {M} {A : cofeT} (a1 a2 : A) : uPred M :=
  {| uPred_holds n x := a1 ≡{n}≡ a2 |}.
Solve Obligations with naive_solver eauto 2 using (dist_le (A:=A)).
Definition uPred_eq_aux : { x | x = @uPred_eq_def }. by eexists. Qed.
Definition uPred_eq {M A} := proj1_sig uPred_eq_aux M A.
Definition uPred_eq_eq: @uPred_eq = @uPred_eq_def := proj2_sig uPred_eq_aux.

Program Definition uPred_sep_def {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := ∃ x1 x2, x ≡{n}≡ x1 ⋅ x2 ∧ P n x1 ∧ Q n x2 |}.
Next Obligation.
  intros M P Q n x y (x1&x2&Hx&?&?) [z Hy].
  exists x1, (x2 ⋅ z); split_and?; eauto using uPred_mono, cmra_includedN_l.
  by rewrite Hy Hx assoc.
Qed.
Next Obligation.
  intros M P Q n1 n2 x (x1&x2&Hx&?&?) ?; rewrite {1}(dist_le _ _ _ _ Hx) // =>?.
  exists x1, x2; cofe_subst; split_and!;
    eauto using dist_le, uPred_closed, cmra_validN_op_l, cmra_validN_op_r.
Qed.
Definition uPred_sep_aux : { x | x = @uPred_sep_def }. by eexists. Qed.
Definition uPred_sep {M} := proj1_sig uPred_sep_aux M.
Definition uPred_sep_eq: @uPred_sep = @uPred_sep_def := proj2_sig uPred_sep_aux.

Program Definition uPred_wand_def {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := ∀ n' x',
       n' ≤ n → ✓{n'} (x ⋅ x') → P n' x' → Q n' (x ⋅ x') |}.
Next Obligation.
  intros M P Q n x1 x1' HPQ ? n3 x3 ???; simpl in *.
  apply uPred_mono with (x1 ⋅ x3);
    eauto using cmra_validN_includedN, cmra_monoN_r, cmra_includedN_le.
Qed.
Next Obligation. naive_solver. Qed.
Definition uPred_wand_aux : { x | x = @uPred_wand_def }. by eexists. Qed.
Definition uPred_wand {M} := proj1_sig uPred_wand_aux M.
Definition uPred_wand_eq :
  @uPred_wand = @uPred_wand_def := proj2_sig uPred_wand_aux.

Program Definition uPred_always_def {M} (P : uPred M) : uPred M :=
  {| uPred_holds n x := P n (core x) |}.
Next Obligation.
  intros M; naive_solver eauto using uPred_mono, @cmra_core_monoN.
Qed.
Next Obligation. naive_solver eauto using uPred_closed, @cmra_core_validN. Qed.
Definition uPred_always_aux : { x | x = @uPred_always_def }. by eexists. Qed.
Definition uPred_always {M} := proj1_sig uPred_always_aux M.
Definition uPred_always_eq :
  @uPred_always = @uPred_always_def := proj2_sig uPred_always_aux.

Program Definition uPred_later_def {M} (P : uPred M) : uPred M :=
  {| uPred_holds n x := match n return _ with 0 => True | S n' => P n' x end |}.
Next Obligation.
  intros M P [|n] x1 x2; eauto using uPred_mono, cmra_includedN_S.
Qed.
Next Obligation.
  intros M P [|n1] [|n2] x; eauto using uPred_closed, cmra_validN_S with lia.
Qed.
Definition uPred_later_aux : { x | x = @uPred_later_def }. by eexists. Qed.
Definition uPred_later {M} := proj1_sig uPred_later_aux M.
Definition uPred_later_eq :
  @uPred_later = @uPred_later_def := proj2_sig uPred_later_aux.

Program Definition uPred_ownM_def {M : ucmraT} (a : M) : uPred M :=
  {| uPred_holds n x := a ≼{n} x |}.
Next Obligation.
  intros M a n x1 x [a' Hx1] [x2 ->].
  exists (a' ⋅ x2). by rewrite (assoc op) Hx1.
Qed.
Next Obligation. naive_solver eauto using cmra_includedN_le. Qed.
Definition uPred_ownM_aux : { x | x = @uPred_ownM_def }. by eexists. Qed.
Definition uPred_ownM {M} := proj1_sig uPred_ownM_aux M.
Definition uPred_ownM_eq :
  @uPred_ownM = @uPred_ownM_def := proj2_sig uPred_ownM_aux.

Program Definition uPred_valid_def {M : ucmraT} {A : cmraT} (a : A) : uPred M :=
  {| uPred_holds n x := ✓{n} a |}.
Solve Obligations with naive_solver eauto 2 using cmra_validN_le.
Definition uPred_valid_aux : { x | x = @uPred_valid_def }. by eexists. Qed.
Definition uPred_valid {M A} := proj1_sig uPred_valid_aux M A.
Definition uPred_valid_eq :
  @uPred_valid = @uPred_valid_def := proj2_sig uPred_valid_aux.

Program Definition uPred_rvs_def {M} (Q : uPred M) : uPred M :=
  {| uPred_holds n x := ∀ k yf,
      k ≤ n → ✓{k} (x ⋅ yf) → ∃ x', ✓{k} (x' ⋅ yf) ∧ Q k x' |}.
Next Obligation.
  intros M Q n x1 x2 HQ [x3 Hx] k yf Hk.
  rewrite (dist_le _ _ _ _ Hx); last lia. intros Hxy.
  destruct (HQ k (x3 ⋅ yf)) as (x'&?&?); [auto|by rewrite assoc|].
  exists (x' ⋅ x3); split; first by rewrite -assoc.
  apply uPred_mono with x'; eauto using cmra_includedN_l.
Qed.
Next Obligation. naive_solver. Qed.
Definition uPred_rvs_aux : { x | x = @uPred_rvs_def }. by eexists. Qed.
Definition uPred_rvs {M} := proj1_sig uPred_rvs_aux M.
Definition uPred_rvs_eq : @uPred_rvs = @uPred_rvs_def := proj2_sig uPred_rvs_aux.

Notation "P ⊢ Q" := (uPred_entails P%I Q%I)
  (at level 99, Q at level 200, right associativity) : C_scope.
Notation "(⊢)" := uPred_entails (only parsing) : C_scope.
Notation "P ⊣⊢ Q" := (equiv (A:=uPred _) P%I Q%I)
  (at level 95, no associativity) : C_scope.
Notation "(⊣⊢)" := (equiv (A:=uPred _)) (only parsing) : C_scope.
Notation "■ φ" := (uPred_pure φ%C%type)
  (at level 20, right associativity) : uPred_scope.
Notation "x = y" := (uPred_pure (x%C%type = y%C%type)) : uPred_scope.
Notation "x ⊥ y" := (uPred_pure (x%C%type ⊥ y%C%type)) : uPred_scope.
Notation "'False'" := (uPred_pure False) : uPred_scope.
Notation "'True'" := (uPred_pure True) : uPred_scope.
Infix "∧" := uPred_and : uPred_scope.
Notation "(∧)" := uPred_and (only parsing) : uPred_scope.
Infix "∨" := uPred_or : uPred_scope.
Notation "(∨)" := uPred_or (only parsing) : uPred_scope.
Infix "→" := uPred_impl : uPred_scope.
Infix "★" := uPred_sep (at level 80, right associativity) : uPred_scope.
Notation "(★)" := uPred_sep (only parsing) : uPred_scope.
Notation "P -★ Q" := (uPred_wand P Q)
  (at level 99, Q at level 200, right associativity) : uPred_scope.
Notation "∀ x .. y , P" :=
  (uPred_forall (λ x, .. (uPred_forall (λ y, P)) ..)%I) : uPred_scope.
Notation "∃ x .. y , P" :=
  (uPred_exist (λ x, .. (uPred_exist (λ y, P)) ..)%I) : uPred_scope.
Notation "□ P" := (uPred_always P)
  (at level 20, right associativity) : uPred_scope.
Notation "▷ P" := (uPred_later P)
  (at level 20, right associativity) : uPred_scope.
Infix "≡" := uPred_eq : uPred_scope.
Notation "✓ x" := (uPred_valid x) (at level 20) : uPred_scope.
Notation "|=r=> Q" := (uPred_rvs Q)
  (at level 99, Q at level 200, format "|=r=>  Q") : uPred_scope.
Notation "P =r=> Q" := (P ⊢ |=r=> Q)
  (at level 99, Q at level 200, only parsing) : C_scope.
Notation "P =r=★ Q" := (P -★ |=r=> Q)%I
  (at level 99, Q at level 200, format "P  =r=★  Q") : uPred_scope.

Definition uPred_iff {M} (P Q : uPred M) : uPred M := ((P → Q) ∧ (Q → P))%I.
Instance: Params (@uPred_iff) 1.
Infix "↔" := uPred_iff : uPred_scope.

Definition uPred_always_if {M} (p : bool) (P : uPred M) : uPred M :=
  (if p then □ P else P)%I.
Instance: Params (@uPred_always_if) 2.
Arguments uPred_always_if _ !_ _/.
Notation "□? p P" := (uPred_always_if p P)
  (at level 20, p at level 0, P at level 20, format "□? p  P").

Definition uPred_now_True {M} (P : uPred M) : uPred M := ▷ False ∨ P.
Notation "◇ P" := (uPred_now_True P)
  (at level 20, right associativity) : uPred_scope.
Instance: Params (@uPred_now_True) 1.
Typeclasses Opaque uPred_now_True.

Class TimelessP {M} (P : uPred M) := timelessP : ▷ P ⊢ ◇ P.
Arguments timelessP {_} _ {_}.

Class PersistentP {M} (P : uPred M) := persistentP : P ⊢ □ P.
Arguments persistentP {_} _ {_}.

Module uPred.
Definition unseal :=
  (uPred_pure_eq, uPred_and_eq, uPred_or_eq, uPred_impl_eq, uPred_forall_eq,
  uPred_exist_eq, uPred_eq_eq, uPred_sep_eq, uPred_wand_eq, uPred_always_eq,
  uPred_later_eq, uPred_ownM_eq, uPred_valid_eq, uPred_rvs_eq).
Ltac unseal := rewrite !unseal /=.

Section uPred_logic.
Context {M : ucmraT}.
Implicit Types φ : Prop.
Implicit Types P Q : uPred M.
Implicit Types A : Type.
Notation "P ⊢ Q" := (@uPred_entails M P%I Q%I). (* Force implicit argument M *)
Notation "P ⊣⊢ Q" := (equiv (A:=uPred M) P%I Q%I). (* Force implicit argument M *)
Arguments uPred_holds {_} !_ _ _ /.
Hint Immediate uPred_in_entails.

Global Instance: PreOrder (@uPred_entails M).
Proof.
  split.
  - by intros P; split=> x i.
  - by intros P Q Q' HP HQ; split=> x i ??; apply HQ, HP.
Qed.
Global Instance: AntiSymm (⊣⊢) (@uPred_entails M).
Proof. intros P Q HPQ HQP; split=> x n; by split; [apply HPQ|apply HQP]. Qed.

Lemma equiv_spec P Q : (P ⊣⊢ Q) ↔ (P ⊢ Q) ∧ (Q ⊢ P).
Proof.
  split; [|by intros [??]; apply (anti_symm (⊢))].
  intros HPQ; split; split=> x i; apply HPQ.
Qed.
Lemma equiv_entails P Q : (P ⊣⊢ Q) → (P ⊢ Q).
Proof. apply equiv_spec. Qed.
Lemma equiv_entails_sym P Q : (Q ⊣⊢ P) → (P ⊢ Q).
Proof. apply equiv_spec. Qed.
Global Instance entails_proper :
  Proper ((⊣⊢) ==> (⊣⊢) ==> iff) ((⊢) : relation (uPred M)).
Proof.
  move => P1 P2 /equiv_spec [HP1 HP2] Q1 Q2 /equiv_spec [HQ1 HQ2]; split; intros.
  - by trans P1; [|trans Q1].
  - by trans P2; [|trans Q2].
Qed.
Lemma entails_equiv_l (P Q R : uPred M) : (P ⊣⊢ Q) → (Q ⊢ R) → (P ⊢ R).
Proof. by intros ->. Qed.
Lemma entails_equiv_r (P Q R : uPred M) : (P ⊢ Q) → (Q ⊣⊢ R) → (P ⊢ R).
Proof. by intros ? <-. Qed.

(** Non-expansiveness and setoid morphisms *)
Global Instance pure_proper : Proper (iff ==> (⊣⊢)) (@uPred_pure M).
Proof. intros φ1 φ2 Hφ. by unseal; split=> -[|n] ?; try apply Hφ. Qed.
Global Instance and_ne n : Proper (dist n ==> dist n ==> dist n) (@uPred_and M).
Proof.
  intros P P' HP Q Q' HQ; unseal; split=> x n' ??.
  split; (intros [??]; split; [by apply HP|by apply HQ]).
Qed.
Global Instance and_proper :
  Proper ((⊣⊢) ==> (⊣⊢) ==> (⊣⊢)) (@uPred_and M) := ne_proper_2 _.
Global Instance or_ne n : Proper (dist n ==> dist n ==> dist n) (@uPred_or M).
Proof.
  intros P P' HP Q Q' HQ; split=> x n' ??.
  unseal; split; (intros [?|?]; [left; by apply HP|right; by apply HQ]).
Qed.
Global Instance or_proper :
  Proper ((⊣⊢) ==> (⊣⊢) ==> (⊣⊢)) (@uPred_or M) := ne_proper_2 _.
Global Instance impl_ne n :
  Proper (dist n ==> dist n ==> dist n) (@uPred_impl M).
Proof.
  intros P P' HP Q Q' HQ; split=> x n' ??.
  unseal; split; intros HPQ x' n'' ????; apply HQ, HPQ, HP; auto.
Qed.
Global Instance impl_proper :
  Proper ((⊣⊢) ==> (⊣⊢) ==> (⊣⊢)) (@uPred_impl M) := ne_proper_2 _.
Global Instance sep_ne n : Proper (dist n ==> dist n ==> dist n) (@uPred_sep M).
Proof.
  intros P P' HP Q Q' HQ; split=> n' x ??.
  unseal; split; intros (x1&x2&?&?&?); cofe_subst x;
    exists x1, x2; split_and!; try (apply HP || apply HQ);
    eauto using cmra_validN_op_l, cmra_validN_op_r.
Qed.
Global Instance sep_proper :
  Proper ((⊣⊢) ==> (⊣⊢) ==> (⊣⊢)) (@uPred_sep M) := ne_proper_2 _.
Global Instance wand_ne n :
  Proper (dist n ==> dist n ==> dist n) (@uPred_wand M).
Proof.
  intros P P' HP Q Q' HQ; split=> n' x ??; unseal; split; intros HPQ x' n'' ???;
    apply HQ, HPQ, HP; eauto using cmra_validN_op_r.
Qed.
Global Instance wand_proper :
  Proper ((⊣⊢) ==> (⊣⊢) ==> (⊣⊢)) (@uPred_wand M) := ne_proper_2 _.
Global Instance eq_ne (A : cofeT) n :
  Proper (dist n ==> dist n ==> dist n) (@uPred_eq M A).
Proof.
  intros x x' Hx y y' Hy; split=> n' z; unseal; split; intros; simpl in *.
  - by rewrite -(dist_le _ _ _ _ Hx) -?(dist_le _ _ _ _ Hy); auto.
  - by rewrite (dist_le _ _ _ _ Hx) ?(dist_le _ _ _ _ Hy); auto.
Qed.
Global Instance eq_proper (A : cofeT) :
  Proper ((≡) ==> (≡) ==> (⊣⊢)) (@uPred_eq M A) := ne_proper_2 _.
Global Instance forall_ne A n :
  Proper (pointwise_relation _ (dist n) ==> dist n) (@uPred_forall M A).
Proof.
  by intros Ψ1 Ψ2 HΨ; unseal; split=> n' x; split; intros HP a; apply HΨ.
Qed.
Global Instance forall_proper A :
  Proper (pointwise_relation _ (⊣⊢) ==> (⊣⊢)) (@uPred_forall M A).
Proof.
  by intros Ψ1 Ψ2 HΨ; unseal; split=> n' x; split; intros HP a; apply HΨ.
Qed.
Global Instance exist_ne A n :
  Proper (pointwise_relation _ (dist n) ==> dist n) (@uPred_exist M A).
Proof.
  intros Ψ1 Ψ2 HΨ.
  unseal; split=> n' x ??; split; intros [a ?]; exists a; by apply HΨ.
Qed.
Global Instance exist_proper A :
  Proper (pointwise_relation _ (⊣⊢) ==> (⊣⊢)) (@uPred_exist M A).
Proof.
  intros Ψ1 Ψ2 HΨ.
  unseal; split=> n' x ?; split; intros [a ?]; exists a; by apply HΨ.
Qed.
Global Instance later_contractive : Contractive (@uPred_later M).
Proof.
  intros n P Q HPQ; unseal; split=> -[|n'] x ??; simpl; [done|].
  apply (HPQ n'); eauto using cmra_validN_S.
Qed.
Global Instance later_proper' :
  Proper ((⊣⊢) ==> (⊣⊢)) (@uPred_later M) := ne_proper _.
Global Instance always_ne n : Proper (dist n ==> dist n) (@uPred_always M).
Proof.
  intros P1 P2 HP.
  unseal; split=> n' x; split; apply HP; eauto using @cmra_core_validN.
Qed.
Global Instance always_proper :
  Proper ((⊣⊢) ==> (⊣⊢)) (@uPred_always M) := ne_proper _.
Global Instance ownM_ne n : Proper (dist n ==> dist n) (@uPred_ownM M).
Proof.
  intros a b Ha.
  unseal; split=> n' x ? /=. by rewrite (dist_le _ _ _ _ Ha); last lia.
Qed.
Global Instance ownM_proper: Proper ((≡) ==> (⊣⊢)) (@uPred_ownM M) := ne_proper _.
Global Instance valid_ne {A : cmraT} n :
Proper (dist n ==> dist n) (@uPred_valid M A).
Proof.
  intros a b Ha; unseal; split=> n' x ? /=.
  by rewrite (dist_le _ _ _ _ Ha); last lia.
Qed.
Global Instance valid_proper {A : cmraT} :
  Proper ((≡) ==> (⊣⊢)) (@uPred_valid M A) := ne_proper _.
Global Instance rvs_ne n : Proper (dist n ==> dist n) (@uPred_rvs M).
Proof.
  intros P Q HPQ.
  unseal; split=> n' x; split; intros HP k yf ??;
    destruct (HP k yf) as (x'&?&?); auto;
    exists x'; split; auto; apply HPQ; eauto using cmra_validN_op_l.
Qed.
Global Instance rvs_proper : Proper ((≡) ==> (≡)) (@uPred_rvs M) := ne_proper _.

(** Introduction and elimination rules *)
Lemma pure_intro φ P : φ → P ⊢ ■ φ.
Proof. by intros ?; unseal; split. Qed.
Lemma pure_elim φ Q R : (Q ⊢ ■ φ) → (φ → Q ⊢ R) → Q ⊢ R.
Proof.
  unseal; intros HQP HQR; split=> n x ??; apply HQR; first eapply HQP; eauto.
Qed.
Lemma and_elim_l P Q : P ∧ Q ⊢ P.
Proof. by unseal; split=> n x ? [??]. Qed.
Lemma and_elim_r P Q : P ∧ Q ⊢ Q.
Proof. by unseal; split=> n x ? [??]. Qed.
Lemma and_intro P Q R : (P ⊢ Q) → (P ⊢ R) → P ⊢ Q ∧ R.
Proof. intros HQ HR; unseal; split=> n x ??; by split; [apply HQ|apply HR]. Qed.
Lemma or_intro_l P Q : P ⊢ P ∨ Q.
Proof. unseal; split=> n x ??; left; auto. Qed.
Lemma or_intro_r P Q : Q ⊢ P ∨ Q.
Proof. unseal; split=> n x ??; right; auto. Qed.
Lemma or_elim P Q R : (P ⊢ R) → (Q ⊢ R) → P ∨ Q ⊢ R.
Proof. intros HP HQ; unseal; split=> n x ? [?|?]. by apply HP. by apply HQ. Qed.
Lemma impl_intro_r P Q R : (P ∧ Q ⊢ R) → P ⊢ Q → R.
Proof.
  unseal; intros HQ; split=> n x ?? n' x' ????. apply HQ;
    naive_solver eauto using uPred_mono, uPred_closed, cmra_included_includedN.
Qed.
Lemma impl_elim P Q R : (P ⊢ Q → R) → (P ⊢ Q) → P ⊢ R.
Proof. by unseal; intros HP HP'; split=> n x ??; apply HP with n x, HP'. Qed.
Lemma forall_intro {A} P (Ψ : A → uPred M): (∀ a, P ⊢ Ψ a) → P ⊢ ∀ a, Ψ a.
Proof. unseal; intros HPΨ; split=> n x ?? a; by apply HPΨ. Qed.
Lemma forall_elim {A} {Ψ : A → uPred M} a : (∀ a, Ψ a) ⊢ Ψ a.
Proof. unseal; split=> n x ? HP; apply HP. Qed.
Lemma exist_intro {A} {Ψ : A → uPred M} a : Ψ a ⊢ ∃ a, Ψ a.
Proof. unseal; split=> n x ??; by exists a. Qed.
Lemma exist_elim {A} (Φ : A → uPred M) Q : (∀ a, Φ a ⊢ Q) → (∃ a, Φ a) ⊢ Q.
Proof. unseal; intros HΦΨ; split=> n x ? [a ?]; by apply HΦΨ with a. Qed.
Lemma eq_refl {A : cofeT} (a : A) : True ⊢ a ≡ a.
Proof. unseal; by split=> n x ??; simpl. Qed.
Lemma eq_rewrite {A : cofeT} a b (Ψ : A → uPred M) P
  {HΨ : ∀ n, Proper (dist n ==> dist n) Ψ} : (P ⊢ a ≡ b) → (P ⊢ Ψ a) → P ⊢ Ψ b.
Proof.
  unseal; intros Hab Ha; split=> n x ??. apply HΨ with n a; auto.
  - by symmetry; apply Hab with x.
  - by apply Ha.
Qed.
Lemma eq_equiv {A : cofeT} (a b : A) : (True ⊢ a ≡ b) → a ≡ b.
Proof.
  unseal=> Hab; apply equiv_dist; intros n; apply Hab with ∅; last done.
  apply cmra_valid_validN, ucmra_unit_valid.
Qed.
Lemma eq_rewrite_contractive {A : cofeT} a b (Ψ : A → uPred M) P
  {HΨ : Contractive Ψ} : (P ⊢ ▷ (a ≡ b)) → (P ⊢ Ψ a) → P ⊢ Ψ b.
Proof.
  unseal; intros Hab Ha; split=> n x ??. apply HΨ with n a; auto.
  - destruct n; intros m ?; first omega. apply (dist_le n); last omega.
    symmetry. by destruct Hab as [Hab]; eapply (Hab (S n)).
  - by apply Ha.
Qed.

(* Derived logical stuff *)
Global Instance iff_ne n : Proper (dist n ==> dist n ==> dist n) (@uPred_iff M).
Proof. unfold uPred_iff; solve_proper. Qed.
Global Instance iff_proper :
  Proper ((⊣⊢) ==> (⊣⊢) ==> (⊣⊢)) (@uPred_iff M) := ne_proper_2 _.

Lemma False_elim P : False ⊢ P.
Proof. by apply (pure_elim False). Qed.
Lemma True_intro P : P ⊢ True.
Proof. by apply pure_intro. Qed.
Lemma and_elim_l' P Q R : (P ⊢ R) → P ∧ Q ⊢ R.
Proof. by rewrite and_elim_l. Qed.
Lemma and_elim_r' P Q R : (Q ⊢ R) → P ∧ Q ⊢ R.
Proof. by rewrite and_elim_r. Qed.
Lemma or_intro_l' P Q R : (P ⊢ Q) → P ⊢ Q ∨ R.
Proof. intros ->; apply or_intro_l. Qed.
Lemma or_intro_r' P Q R : (P ⊢ R) → P ⊢ Q ∨ R.
Proof. intros ->; apply or_intro_r. Qed.
Lemma exist_intro' {A} P (Ψ : A → uPred M) a : (P ⊢ Ψ a) → P ⊢ ∃ a, Ψ a.
Proof. intros ->; apply exist_intro. Qed.
Lemma forall_elim' {A} P (Ψ : A → uPred M) : (P ⊢ ∀ a, Ψ a) → ∀ a, P ⊢ Ψ a.
Proof. move=> HP a. by rewrite HP forall_elim. Qed.

Hint Resolve or_elim or_intro_l' or_intro_r'.
Hint Resolve and_intro and_elim_l' and_elim_r'.
Hint Immediate True_intro False_elim.

Lemma impl_intro_l P Q R : (Q ∧ P ⊢ R) → P ⊢ Q → R.
Proof. intros HR; apply impl_intro_r; rewrite -HR; auto. Qed.
Lemma impl_elim_l P Q : (P → Q) ∧ P ⊢ Q.
Proof. apply impl_elim with P; auto. Qed.
Lemma impl_elim_r P Q : P ∧ (P → Q) ⊢ Q.
Proof. apply impl_elim with P; auto. Qed.
Lemma impl_elim_l' P Q R : (P ⊢ Q → R) → P ∧ Q ⊢ R.
Proof. intros; apply impl_elim with Q; auto. Qed.
Lemma impl_elim_r' P Q R : (Q ⊢ P → R) → P ∧ Q ⊢ R.
Proof. intros; apply impl_elim with P; auto. Qed.
Lemma impl_entails P Q : (True ⊢ P → Q) → P ⊢ Q.
Proof. intros HPQ; apply impl_elim with P; rewrite -?HPQ; auto. Qed.
Lemma entails_impl P Q : (P ⊢ Q) → True ⊢ P → Q.
Proof. auto using impl_intro_l. Qed.

Lemma iff_refl Q P : Q ⊢ P ↔ P.
Proof. rewrite /uPred_iff; apply and_intro; apply impl_intro_l; auto. Qed.
Lemma iff_equiv P Q : (True ⊢ P ↔ Q) → (P ⊣⊢ Q).
Proof.
  intros HPQ; apply (anti_symm (⊢));
    apply impl_entails; rewrite HPQ /uPred_iff; auto.
Qed.
Lemma equiv_iff P Q : (P ⊣⊢ Q) → True ⊢ P ↔ Q.
Proof. intros ->; apply iff_refl. Qed.

Lemma pure_mono φ1 φ2 : (φ1 → φ2) → ■ φ1 ⊢ ■ φ2.
Proof. intros; apply pure_elim with φ1; eauto using pure_intro. Qed.
Lemma pure_iff φ1 φ2 : (φ1 ↔ φ2) → ■ φ1 ⊣⊢ ■ φ2.
Proof. intros [??]; apply (anti_symm _); auto using pure_mono. Qed.
Lemma and_mono P P' Q Q' : (P ⊢ Q) → (P' ⊢ Q') → P ∧ P' ⊢ Q ∧ Q'.
Proof. auto. Qed.
Lemma and_mono_l P P' Q : (P ⊢ Q) → P ∧ P' ⊢ Q ∧ P'.
Proof. by intros; apply and_mono. Qed.
Lemma and_mono_r P P' Q' : (P' ⊢ Q') → P ∧ P' ⊢ P ∧ Q'.
Proof. by apply and_mono. Qed.
Lemma or_mono P P' Q Q' : (P ⊢ Q) → (P' ⊢ Q') → P ∨ P' ⊢ Q ∨ Q'.
Proof. auto. Qed.
Lemma or_mono_l P P' Q : (P ⊢ Q) → P ∨ P' ⊢ Q ∨ P'.
Proof. by intros; apply or_mono. Qed.
Lemma or_mono_r P P' Q' : (P' ⊢ Q') → P ∨ P' ⊢ P ∨ Q'.
Proof. by apply or_mono. Qed.
Lemma impl_mono P P' Q Q' : (Q ⊢ P) → (P' ⊢ Q') → (P → P') ⊢ Q → Q'.
Proof.
  intros HP HQ'; apply impl_intro_l; rewrite -HQ'.
  apply impl_elim with P; eauto.
Qed.
Lemma forall_mono {A} (Φ Ψ : A → uPred M) :
  (∀ a, Φ a ⊢ Ψ a) → (∀ a, Φ a) ⊢ ∀ a, Ψ a.
Proof.
  intros HP. apply forall_intro=> a; rewrite -(HP a); apply forall_elim.
Qed.
Lemma exist_mono {A} (Φ Ψ : A → uPred M) :
  (∀ a, Φ a ⊢ Ψ a) → (∃ a, Φ a) ⊢ ∃ a, Ψ a.
Proof. intros HΦ. apply exist_elim=> a; rewrite (HΦ a); apply exist_intro. Qed.
Global Instance pure_mono' : Proper (impl ==> (⊢)) (@uPred_pure M).
Proof. intros φ1 φ2; apply pure_mono. Qed.
Global Instance and_mono' : Proper ((⊢) ==> (⊢) ==> (⊢)) (@uPred_and M).
Proof. by intros P P' HP Q Q' HQ; apply and_mono. Qed.
Global Instance and_flip_mono' :
  Proper (flip (⊢) ==> flip (⊢) ==> flip (⊢)) (@uPred_and M).
Proof. by intros P P' HP Q Q' HQ; apply and_mono. Qed.
Global Instance or_mono' : Proper ((⊢) ==> (⊢) ==> (⊢)) (@uPred_or M).
Proof. by intros P P' HP Q Q' HQ; apply or_mono. Qed.
Global Instance or_flip_mono' :
  Proper (flip (⊢) ==> flip (⊢) ==> flip (⊢)) (@uPred_or M).
Proof. by intros P P' HP Q Q' HQ; apply or_mono. Qed.
Global Instance impl_mono' :
  Proper (flip (⊢) ==> (⊢) ==> (⊢)) (@uPred_impl M).
Proof. by intros P P' HP Q Q' HQ; apply impl_mono. Qed.
Global Instance forall_mono' A :
  Proper (pointwise_relation _ (⊢) ==> (⊢)) (@uPred_forall M A).
Proof. intros P1 P2; apply forall_mono. Qed.
Global Instance exist_mono' A :
  Proper (pointwise_relation _ (⊢) ==> (⊢)) (@uPred_exist M A).
Proof. intros P1 P2; apply exist_mono. Qed.

Global Instance and_idem : IdemP (⊣⊢) (@uPred_and M).
Proof. intros P; apply (anti_symm (⊢)); auto. Qed.
Global Instance or_idem : IdemP (⊣⊢) (@uPred_or M).
Proof. intros P; apply (anti_symm (⊢)); auto. Qed.
Global Instance and_comm : Comm (⊣⊢) (@uPred_and M).
Proof. intros P Q; apply (anti_symm (⊢)); auto. Qed.
Global Instance True_and : LeftId (⊣⊢) True%I (@uPred_and M).
Proof. intros P; apply (anti_symm (⊢)); auto. Qed.
Global Instance and_True : RightId (⊣⊢) True%I (@uPred_and M).
Proof. intros P; apply (anti_symm (⊢)); auto. Qed.
Global Instance False_and : LeftAbsorb (⊣⊢) False%I (@uPred_and M).
Proof. intros P; apply (anti_symm (⊢)); auto. Qed.
Global Instance and_False : RightAbsorb (⊣⊢) False%I (@uPred_and M).
Proof. intros P; apply (anti_symm (⊢)); auto. Qed.
Global Instance True_or : LeftAbsorb (⊣⊢) True%I (@uPred_or M).
Proof. intros P; apply (anti_symm (⊢)); auto. Qed.
Global Instance or_True : RightAbsorb (⊣⊢) True%I (@uPred_or M).
Proof. intros P; apply (anti_symm (⊢)); auto. Qed.
Global Instance False_or : LeftId (⊣⊢) False%I (@uPred_or M).
Proof. intros P; apply (anti_symm (⊢)); auto. Qed.
Global Instance or_False : RightId (⊣⊢) False%I (@uPred_or M).
Proof. intros P; apply (anti_symm (⊢)); auto. Qed.
Global Instance and_assoc : Assoc (⊣⊢) (@uPred_and M).
Proof. intros P Q R; apply (anti_symm (⊢)); auto. Qed.
Global Instance or_comm : Comm (⊣⊢) (@uPred_or M).
Proof. intros P Q; apply (anti_symm (⊢)); auto. Qed.
Global Instance or_assoc : Assoc (⊣⊢) (@uPred_or M).
Proof. intros P Q R; apply (anti_symm (⊢)); auto. Qed.
Global Instance True_impl : LeftId (⊣⊢) True%I (@uPred_impl M).
Proof.
  intros P; apply (anti_symm (⊢)).
  - by rewrite -(left_id True%I uPred_and (_ → _)%I) impl_elim_r.
  - by apply impl_intro_l; rewrite left_id.
Qed.

Lemma or_and_l P Q R : P ∨ Q ∧ R ⊣⊢ (P ∨ Q) ∧ (P ∨ R).
Proof.
  apply (anti_symm (⊢)); first auto.
  do 2 (apply impl_elim_l', or_elim; apply impl_intro_l); auto.
Qed.
Lemma or_and_r P Q R : P ∧ Q ∨ R ⊣⊢ (P ∨ R) ∧ (Q ∨ R).
Proof. by rewrite -!(comm _ R) or_and_l. Qed.
Lemma and_or_l P Q R : P ∧ (Q ∨ R) ⊣⊢ P ∧ Q ∨ P ∧ R.
Proof.
  apply (anti_symm (⊢)); last auto.
  apply impl_elim_r', or_elim; apply impl_intro_l; auto.
Qed.
Lemma and_or_r P Q R : (P ∨ Q) ∧ R ⊣⊢ P ∧ R ∨ Q ∧ R.
Proof. by rewrite -!(comm _ R) and_or_l. Qed.
Lemma and_exist_l {A} P (Ψ : A → uPred M) : P ∧ (∃ a, Ψ a) ⊣⊢ ∃ a, P ∧ Ψ a.
Proof.
  apply (anti_symm (⊢)).
  - apply impl_elim_r'. apply exist_elim=>a. apply impl_intro_l.
    by rewrite -(exist_intro a).
  - apply exist_elim=>a. apply and_intro; first by rewrite and_elim_l.
    by rewrite -(exist_intro a) and_elim_r.
Qed.
Lemma and_exist_r {A} P (Φ: A → uPred M) : (∃ a, Φ a) ∧ P ⊣⊢ ∃ a, Φ a ∧ P.
Proof.
  rewrite -(comm _ P) and_exist_l. apply exist_proper=>a. by rewrite comm.
Qed.

Lemma pure_intro_l φ Q R : φ → (■ φ ∧ Q ⊢ R) → Q ⊢ R.
Proof. intros ? <-; auto using pure_intro. Qed.
Lemma pure_intro_r φ Q R : φ → (Q ∧ ■ φ ⊢ R) → Q ⊢ R.
Proof. intros ? <-; auto using pure_intro. Qed.
Lemma pure_intro_impl φ Q R : φ → (Q ⊢ ■ φ → R) → Q ⊢ R.
Proof. intros ? ->. eauto using pure_intro_l, impl_elim_r. Qed.
Lemma pure_elim_l φ Q R : (φ → Q ⊢ R) → ■ φ ∧ Q ⊢ R.
Proof. intros; apply pure_elim with φ; eauto. Qed.
Lemma pure_elim_r φ Q R : (φ → Q ⊢ R) → Q ∧ ■ φ ⊢ R.
Proof. intros; apply pure_elim with φ; eauto. Qed.
Lemma pure_equiv (φ : Prop) : φ → ■ φ ⊣⊢ True.
Proof. intros; apply (anti_symm _); auto using pure_intro. Qed.

Lemma eq_refl' {A : cofeT} (a : A) P : P ⊢ a ≡ a.
Proof. rewrite (True_intro P). apply eq_refl. Qed.
Hint Resolve eq_refl'.
Lemma equiv_eq {A : cofeT} P (a b : A) : a ≡ b → P ⊢ a ≡ b.
Proof. by intros ->. Qed.
Lemma eq_sym {A : cofeT} (a b : A) : a ≡ b ⊢ b ≡ a.
Proof. apply (eq_rewrite a b (λ b, b ≡ a)%I); auto. solve_proper. Qed.
Lemma eq_iff P Q : P ≡ Q ⊢ P ↔ Q.
Proof.
  apply (eq_rewrite P Q (λ Q, P ↔ Q))%I; first solve_proper; auto using iff_refl.
Qed.

(* BI connectives *)
Lemma sep_mono P P' Q Q' : (P ⊢ Q) → (P' ⊢ Q') → P ★ P' ⊢ Q ★ Q'.
Proof.
  intros HQ HQ'; unseal.
  split; intros n' x ? (x1&x2&?&?&?); exists x1,x2; cofe_subst x;
    eauto 7 using cmra_validN_op_l, cmra_validN_op_r, uPred_in_entails.
Qed.
Global Instance True_sep : LeftId (⊣⊢) True%I (@uPred_sep M).
Proof.
  intros P; unseal; split=> n x Hvalid; split.
  - intros (x1&x2&?&_&?); cofe_subst; eauto using uPred_mono, cmra_includedN_r.
  - by intros ?; exists (core x), x; rewrite cmra_core_l.
Qed. 
Global Instance sep_comm : Comm (⊣⊢) (@uPred_sep M).
Proof.
  by intros P Q; unseal; split=> n x ?; split;
    intros (x1&x2&?&?&?); exists x2, x1; rewrite (comm op).
Qed.
Global Instance sep_assoc : Assoc (⊣⊢) (@uPred_sep M).
Proof.
  intros P Q R; unseal; split=> n x ?; split.
  - intros (x1&x2&Hx&?&y1&y2&Hy&?&?); exists (x1 ⋅ y1), y2; split_and?; auto.
    + by rewrite -(assoc op) -Hy -Hx.
    + by exists x1, y1.
  - intros (x1&x2&Hx&(y1&y2&Hy&?&?)&?); exists y1, (y2 ⋅ x2); split_and?; auto.
    + by rewrite (assoc op) -Hy -Hx.
    + by exists y2, x2.
Qed.
Lemma wand_intro_r P Q R : (P ★ Q ⊢ R) → P ⊢ Q -★ R.
Proof.
  unseal=> HPQR; split=> n x ?? n' x' ???; apply HPQR; auto.
  exists x, x'; split_and?; auto.
  eapply uPred_closed with n; eauto using cmra_validN_op_l.
Qed.
Lemma wand_elim_l' P Q R : (P ⊢ Q -★ R) → P ★ Q ⊢ R.
Proof.
  unseal =>HPQR. split; intros n x ? (?&?&?&?&?). cofe_subst.
  eapply HPQR; eauto using cmra_validN_op_l.
Qed.

(* Derived BI Stuff *)
Hint Resolve sep_mono.
Lemma sep_mono_l P P' Q : (P ⊢ Q) → P ★ P' ⊢ Q ★ P'.
Proof. by intros; apply sep_mono. Qed.
Lemma sep_mono_r P P' Q' : (P' ⊢ Q') → P ★ P' ⊢ P ★ Q'.
Proof. by apply sep_mono. Qed.
Global Instance sep_mono' : Proper ((⊢) ==> (⊢) ==> (⊢)) (@uPred_sep M).
Proof. by intros P P' HP Q Q' HQ; apply sep_mono. Qed.
Global Instance sep_flip_mono' :
  Proper (flip (⊢) ==> flip (⊢) ==> flip (⊢)) (@uPred_sep M).
Proof. by intros P P' HP Q Q' HQ; apply sep_mono. Qed.
Lemma wand_mono P P' Q Q' : (Q ⊢ P) → (P' ⊢ Q') → (P -★ P') ⊢ Q -★ Q'.
Proof.
  intros HP HQ; apply wand_intro_r. rewrite HP -HQ. by apply wand_elim_l'.
Qed.
Global Instance wand_mono' : Proper (flip (⊢) ==> (⊢) ==> (⊢)) (@uPred_wand M).
Proof. by intros P P' HP Q Q' HQ; apply wand_mono. Qed.

Global Instance sep_True : RightId (⊣⊢) True%I (@uPred_sep M).
Proof. by intros P; rewrite comm left_id. Qed.
Lemma sep_elim_l P Q : P ★ Q ⊢ P.
Proof. by rewrite (True_intro Q) right_id. Qed.
Lemma sep_elim_r P Q : P ★ Q ⊢ Q.
Proof. by rewrite (comm (★))%I; apply sep_elim_l. Qed.
Lemma sep_elim_l' P Q R : (P ⊢ R) → P ★ Q ⊢ R.
Proof. intros ->; apply sep_elim_l. Qed.
Lemma sep_elim_r' P Q R : (Q ⊢ R) → P ★ Q ⊢ R.
Proof. intros ->; apply sep_elim_r. Qed.
Hint Resolve sep_elim_l' sep_elim_r'.
Lemma sep_intro_True_l P Q R : (True ⊢ P) → (R ⊢ Q) → R ⊢ P ★ Q.
Proof. by intros; rewrite -(left_id True%I uPred_sep R); apply sep_mono. Qed.
Lemma sep_intro_True_r P Q R : (R ⊢ P) → (True ⊢ Q) → R ⊢ P ★ Q.
Proof. by intros; rewrite -(right_id True%I uPred_sep R); apply sep_mono. Qed.
Lemma sep_elim_True_l P Q R : (True ⊢ P) → (P ★ R ⊢ Q) → R ⊢ Q.
Proof. by intros HP; rewrite -HP left_id. Qed.
Lemma sep_elim_True_r P Q R : (True ⊢ P) → (R ★ P ⊢ Q) → R ⊢ Q.
Proof. by intros HP; rewrite -HP right_id. Qed.
Lemma wand_intro_l P Q R : (Q ★ P ⊢ R) → P ⊢ Q -★ R.
Proof. rewrite comm; apply wand_intro_r. Qed.
Lemma wand_elim_l P Q : (P -★ Q) ★ P ⊢ Q.
Proof. by apply wand_elim_l'. Qed.
Lemma wand_elim_r P Q : P ★ (P -★ Q) ⊢ Q.
Proof. rewrite (comm _ P); apply wand_elim_l. Qed.
Lemma wand_elim_r' P Q R : (Q ⊢ P -★ R) → P ★ Q ⊢ R.
Proof. intros ->; apply wand_elim_r. Qed.
Lemma wand_apply_l P Q Q' R R' : (P ⊢ Q' -★ R') → (R' ⊢ R) → (Q ⊢ Q') → P ★ Q ⊢ R.
Proof. intros -> -> <-; apply wand_elim_l. Qed.
Lemma wand_apply_r P Q Q' R R' : (P ⊢ Q' -★ R') → (R' ⊢ R) → (Q ⊢ Q') → Q ★ P ⊢ R.
Proof. intros -> -> <-; apply wand_elim_r. Qed.
Lemma wand_apply_l' P Q Q' R : (P ⊢ Q' -★ R) → (Q ⊢ Q') → P ★ Q ⊢ R.
Proof. intros -> <-; apply wand_elim_l. Qed.
Lemma wand_apply_r' P Q Q' R : (P ⊢ Q' -★ R) → (Q ⊢ Q') → Q ★ P ⊢ R.
Proof. intros -> <-; apply wand_elim_r. Qed.
Lemma wand_frame_l P Q R : (Q -★ R) ⊢ P ★ Q -★ P ★ R.
Proof. apply wand_intro_l. rewrite -assoc. apply sep_mono_r, wand_elim_r. Qed.
Lemma wand_frame_r P Q R : (Q -★ R) ⊢ Q ★ P -★ R ★ P.
Proof.
  apply wand_intro_l. rewrite ![(_ ★ P)%I]comm -assoc.
  apply sep_mono_r, wand_elim_r.
Qed.
Lemma wand_diag P : (P -★ P) ⊣⊢ True.
Proof. apply (anti_symm _); auto. apply wand_intro_l; by rewrite right_id. Qed.
Lemma wand_True P : (True -★ P) ⊣⊢ P.
Proof.
  apply (anti_symm _); last by auto using wand_intro_l.
  eapply sep_elim_True_l; first reflexivity. by rewrite wand_elim_r.
Qed.
Lemma wand_entails P Q : (True ⊢ P -★ Q) → P ⊢ Q.
Proof.
  intros HPQ. eapply sep_elim_True_r; first exact: HPQ. by rewrite wand_elim_r.
Qed.
Lemma entails_wand P Q : (P ⊢ Q) → True ⊢ P -★ Q.
Proof. auto using wand_intro_l. Qed.
Lemma wand_curry P Q R : (P -★ Q -★ R) ⊣⊢ (P ★ Q -★ R).
Proof.
  apply (anti_symm _).
  - apply wand_intro_l. by rewrite (comm _ P) -assoc !wand_elim_r.
  - do 2 apply wand_intro_l. by rewrite assoc (comm _ Q) wand_elim_r.
Qed.

Lemma sep_and P Q : (P ★ Q) ⊢ (P ∧ Q).
Proof. auto. Qed.
Lemma impl_wand P Q : (P → Q) ⊢ P -★ Q.
Proof. apply wand_intro_r, impl_elim with P; auto. Qed.
Lemma pure_elim_sep_l φ Q R : (φ → Q ⊢ R) → ■ φ ★ Q ⊢ R.
Proof. intros; apply pure_elim with φ; eauto. Qed.
Lemma pure_elim_sep_r φ Q R : (φ → Q ⊢ R) → Q ★ ■ φ ⊢ R.
Proof. intros; apply pure_elim with φ; eauto. Qed.

Global Instance sep_False : LeftAbsorb (⊣⊢) False%I (@uPred_sep M).
Proof. intros P; apply (anti_symm _); auto. Qed.
Global Instance False_sep : RightAbsorb (⊣⊢) False%I (@uPred_sep M).
Proof. intros P; apply (anti_symm _); auto. Qed.

Lemma sep_and_l P Q R : P ★ (Q ∧ R) ⊢ (P ★ Q) ∧ (P ★ R).
Proof. auto. Qed.
Lemma sep_and_r P Q R : (P ∧ Q) ★ R ⊢ (P ★ R) ∧ (Q ★ R).
Proof. auto. Qed.
Lemma sep_or_l P Q R : P ★ (Q ∨ R) ⊣⊢ (P ★ Q) ∨ (P ★ R).
Proof.
  apply (anti_symm (⊢)); last by eauto 8.
  apply wand_elim_r', or_elim; apply wand_intro_l; auto.
Qed.
Lemma sep_or_r P Q R : (P ∨ Q) ★ R ⊣⊢ (P ★ R) ∨ (Q ★ R).
Proof. by rewrite -!(comm _ R) sep_or_l. Qed.
Lemma sep_exist_l {A} P (Ψ : A → uPred M) : P ★ (∃ a, Ψ a) ⊣⊢ ∃ a, P ★ Ψ a.
Proof.
  intros; apply (anti_symm (⊢)).
  - apply wand_elim_r', exist_elim=>a. apply wand_intro_l.
    by rewrite -(exist_intro a).
  - apply exist_elim=> a; apply sep_mono; auto using exist_intro.
Qed.
Lemma sep_exist_r {A} (Φ: A → uPred M) Q: (∃ a, Φ a) ★ Q ⊣⊢ ∃ a, Φ a ★ Q.
Proof. setoid_rewrite (comm _ _ Q); apply sep_exist_l. Qed.
Lemma sep_forall_l {A} P (Ψ : A → uPred M) : P ★ (∀ a, Ψ a) ⊢ ∀ a, P ★ Ψ a.
Proof. by apply forall_intro=> a; rewrite forall_elim. Qed.
Lemma sep_forall_r {A} (Φ : A → uPred M) Q : (∀ a, Φ a) ★ Q ⊢ ∀ a, Φ a ★ Q.
Proof. by apply forall_intro=> a; rewrite forall_elim. Qed.

(* Always *)
Lemma always_pure φ : □ ■ φ ⊣⊢ ■ φ.
Proof. by unseal. Qed.
Lemma always_elim P : □ P ⊢ P.
Proof.
  unseal; split=> n x ? /=.
  eauto using uPred_mono, @cmra_included_core, cmra_included_includedN.
Qed.
Lemma always_intro' P Q : (□ P ⊢ Q) → □ P ⊢ □ Q.
Proof.
  unseal=> HPQ; split=> n x ??; apply HPQ; simpl; auto using @cmra_core_validN.
  by rewrite cmra_core_idemp.
Qed.
Lemma always_and P Q : □ (P ∧ Q) ⊣⊢ □ P ∧ □ Q.
Proof. by unseal. Qed.
Lemma always_or P Q : □ (P ∨ Q) ⊣⊢ □ P ∨ □ Q.
Proof. by unseal. Qed.
Lemma always_forall {A} (Ψ : A → uPred M) : (□ ∀ a, Ψ a) ⊣⊢ (∀ a, □ Ψ a).
Proof. by unseal. Qed.
Lemma always_exist {A} (Ψ : A → uPred M) : (□ ∃ a, Ψ a) ⊣⊢ (∃ a, □ Ψ a).
Proof. by unseal. Qed.
Lemma always_and_sep_1 P Q : □ (P ∧ Q) ⊢ □ (P ★ Q).
Proof.
  unseal; split=> n x ? [??].
  exists (core x), (core x); rewrite -cmra_core_dup; auto.
Qed.
Lemma always_and_sep_l_1 P Q : □ P ∧ Q ⊢ □ P ★ Q.
Proof.
  unseal; split=> n x ? [??]; exists (core x), x; simpl in *.
  by rewrite cmra_core_l cmra_core_idemp.
Qed.
Lemma always_later P : □ ▷ P ⊣⊢ ▷ □ P.
Proof. by unseal. Qed.

(* Always derived *)
Lemma always_mono P Q : (P ⊢ Q) → □ P ⊢ □ Q.
Proof. intros. apply always_intro'. by rewrite always_elim. Qed.
Hint Resolve always_mono.
Global Instance always_mono' : Proper ((⊢) ==> (⊢)) (@uPred_always M).
Proof. intros P Q; apply always_mono. Qed.
Global Instance always_flip_mono' :
  Proper (flip (⊢) ==> flip (⊢)) (@uPred_always M).
Proof. intros P Q; apply always_mono. Qed.
Lemma always_impl P Q : □ (P → Q) ⊢ □ P → □ Q.
Proof.
  apply impl_intro_l; rewrite -always_and.
  apply always_mono, impl_elim with P; auto.
Qed.
Lemma always_eq {A:cofeT} (a b : A) : □ (a ≡ b) ⊣⊢ a ≡ b.
Proof.
  apply (anti_symm (⊢)); auto using always_elim.
  apply (eq_rewrite a b (λ b, □ (a ≡ b))%I); auto.
  { intros n; solve_proper. }
  rewrite -(eq_refl a) always_pure; auto.
Qed.
Lemma always_and_sep P Q : □ (P ∧ Q) ⊣⊢ □ (P ★ Q).
Proof. apply (anti_symm (⊢)); auto using always_and_sep_1. Qed.
Lemma always_and_sep_l' P Q : □ P ∧ Q ⊣⊢ □ P ★ Q.
Proof. apply (anti_symm (⊢)); auto using always_and_sep_l_1. Qed.
Lemma always_and_sep_r' P Q : P ∧ □ Q ⊣⊢ P ★ □ Q.
Proof. by rewrite !(comm _ P) always_and_sep_l'. Qed.
Lemma always_sep P Q : □ (P ★ Q) ⊣⊢ □ P ★ □ Q.
Proof. by rewrite -always_and_sep -always_and_sep_l' always_and. Qed.
Lemma always_wand P Q : □ (P -★ Q) ⊢ □ P -★ □ Q.
Proof. by apply wand_intro_r; rewrite -always_sep wand_elim_l. Qed.
Lemma always_sep_dup' P : □ P ⊣⊢ □ P ★ □ P.
Proof. by rewrite -always_sep -always_and_sep (idemp _). Qed.
Lemma always_wand_impl P Q : □ (P -★ Q) ⊣⊢ □ (P → Q).
Proof.
  apply (anti_symm (⊢)); [|by rewrite -impl_wand].
  apply always_intro', impl_intro_r.
  by rewrite always_and_sep_l' always_elim wand_elim_l.
Qed.
Lemma always_entails_l' P Q : (P ⊢ □ Q) → P ⊢ □ Q ★ P.
Proof. intros; rewrite -always_and_sep_l'; auto. Qed.
Lemma always_entails_r' P Q : (P ⊢ □ Q) → P ⊢ P ★ □ Q.
Proof. intros; rewrite -always_and_sep_r'; auto. Qed.

(* Conditional always *)
Global Instance always_if_ne n p : Proper (dist n ==> dist n) (@uPred_always_if M p).
Proof. solve_proper. Qed.
Global Instance always_if_proper p : Proper ((⊣⊢) ==> (⊣⊢)) (@uPred_always_if M p).
Proof. solve_proper. Qed.
Global Instance always_if_mono p : Proper ((⊢) ==> (⊢)) (@uPred_always_if M p).
Proof. solve_proper. Qed.

Lemma always_if_elim p P : □?p P ⊢ P.
Proof. destruct p; simpl; auto using always_elim. Qed.
Lemma always_elim_if p P : □ P ⊢ □?p P.
Proof. destruct p; simpl; auto using always_elim. Qed.
Lemma always_if_and p P Q : □?p (P ∧ Q) ⊣⊢ □?p P ∧ □?p Q.
Proof. destruct p; simpl; auto using always_and. Qed.
Lemma always_if_or p P Q : □?p (P ∨ Q) ⊣⊢ □?p P ∨ □?p Q.
Proof. destruct p; simpl; auto using always_or. Qed.
Lemma always_if_exist {A} p (Ψ : A → uPred M) : (□?p ∃ a, Ψ a) ⊣⊢ ∃ a, □?p Ψ a.
Proof. destruct p; simpl; auto using always_exist. Qed.
Lemma always_if_sep p P Q : □?p (P ★ Q) ⊣⊢ □?p P ★ □?p Q.
Proof. destruct p; simpl; auto using always_sep. Qed.
Lemma always_if_later p P : □?p ▷ P ⊣⊢ ▷ □?p P.
Proof. destruct p; simpl; auto using always_later. Qed.

(* Later *)
Lemma later_mono P Q : (P ⊢ Q) → ▷ P ⊢ ▷ Q.
Proof.
  unseal=> HP; split=>-[|n] x ??; [done|apply HP; eauto using cmra_validN_S].
Qed.
Lemma later_intro P : P ⊢ ▷ P.
Proof.
  unseal; split=> -[|n] x ??; simpl in *; [done|].
  apply uPred_closed with (S n); eauto using cmra_validN_S.
Qed.
Lemma löb P : (▷ P → P) ⊢ P.
Proof.
  unseal; split=> n x ? HP; induction n as [|n IH]; [by apply HP|].
  apply HP, IH, uPred_closed with (S n); eauto using cmra_validN_S.
Qed.
Lemma later_and P Q : ▷ (P ∧ Q) ⊣⊢ ▷ P ∧ ▷ Q.
Proof. unseal; split=> -[|n] x; by split. Qed.
Lemma later_or P Q : ▷ (P ∨ Q) ⊣⊢ ▷ P ∨ ▷ Q.
Proof. unseal; split=> -[|n] x; simpl; tauto. Qed.
Lemma later_forall {A} (Φ : A → uPred M) : (▷ ∀ a, Φ a) ⊣⊢ (∀ a, ▷ Φ a).
Proof. unseal; by split=> -[|n] x. Qed.
Lemma later_exist_1 {A} (Φ : A → uPred M) : (∃ a, ▷ Φ a) ⊢ (▷ ∃ a, Φ a).
Proof. unseal; by split=> -[|[|n]] x. Qed.
Lemma later_exist_2 `{Inhabited A} (Φ : A → uPred M) : (▷ ∃ a, Φ a) ⊢ ∃ a, ▷ Φ a.
Proof. unseal; split=> -[|[|n]] x; done || by exists inhabitant. Qed.
Lemma later_sep P Q : ▷ (P ★ Q) ⊣⊢ ▷ P ★ ▷ Q.
Proof.
  unseal; split=> n x ?; split.
  - destruct n as [|n]; simpl.
    { by exists x, (core x); rewrite cmra_core_r. }
    intros (x1&x2&Hx&?&?); destruct (cmra_extend n x x1 x2)
      as ([y1 y2]&Hx'&Hy1&Hy2); eauto using cmra_validN_S; simpl in *.
    exists y1, y2; split; [by rewrite Hx'|by rewrite Hy1 Hy2].
  - destruct n as [|n]; simpl; [done|intros (x1&x2&Hx&?&?)].
    exists x1, x2; eauto using dist_S.
Qed.

(* Later derived *)
Lemma later_proper P Q : (P ⊣⊢ Q) → ▷ P ⊣⊢ ▷ Q.
Proof. by intros ->. Qed.
Hint Resolve later_mono later_proper.
Global Instance later_mono' : Proper ((⊢) ==> (⊢)) (@uPred_later M).
Proof. intros P Q; apply later_mono. Qed.
Global Instance later_flip_mono' :
  Proper (flip (⊢) ==> flip (⊢)) (@uPred_later M).
Proof. intros P Q; apply later_mono. Qed.
Lemma later_True : ▷ True ⊣⊢ True.
Proof. apply (anti_symm (⊢)); auto using later_intro. Qed.
Lemma later_impl P Q : ▷ (P → Q) ⊢ ▷ P → ▷ Q.
Proof. apply impl_intro_l; rewrite -later_and; eauto using impl_elim. Qed.
Lemma later_exist `{Inhabited A} (Φ : A → uPred M) :
  ▷ (∃ a, Φ a) ⊣⊢ (∃ a, ▷ Φ a).
Proof. apply: anti_symm; eauto using later_exist_2, later_exist_1. Qed.
Lemma later_wand P Q : ▷ (P -★ Q) ⊢ ▷ P -★ ▷ Q.
Proof. apply wand_intro_r;rewrite -later_sep; eauto using wand_elim_l. Qed.
Lemma later_iff P Q : ▷ (P ↔ Q) ⊢ ▷ P ↔ ▷ Q.
Proof. by rewrite /uPred_iff later_and !later_impl. Qed.

(* True now *)
Global Instance now_True_ne n : Proper (dist n ==> dist n) (@uPred_now_True M).
Proof. solve_proper. Qed.
Global Instance now_True_proper : Proper ((⊣⊢) ==> (⊣⊢)) (@uPred_now_True M).
Proof. solve_proper. Qed.
Global Instance now_True_mono' : Proper ((⊢) ==> (⊢)) (@uPred_now_True M).
Proof. solve_proper. Qed.
Global Instance now_True_flip_mono' :
  Proper (flip (⊢) ==> flip (⊢)) (@uPred_now_True M).
Proof. solve_proper. Qed.

Lemma now_True_intro P : P ⊢ ◇ P.
Proof. rewrite /uPred_now_True; auto. Qed.
Lemma now_True_mono P Q : (P ⊢ Q) → ◇ P ⊢ ◇ Q.
Proof. by intros ->. Qed.
Lemma now_True_idemp P : ◇ ◇ P ⊢ ◇ P.
Proof. rewrite /uPred_now_True; auto. Qed.

Lemma now_True_True : ◇ True ⊣⊢ True.
Proof. rewrite /uPred_now_True. apply (anti_symm _); auto. Qed.
Lemma now_True_or P Q : ◇ (P ∨ Q) ⊣⊢ ◇ P ∨ ◇ Q.
Proof. rewrite /uPred_now_True. apply (anti_symm _); auto. Qed.
Lemma now_True_and P Q : ◇ (P ∧ Q) ⊣⊢ ◇ P ∧ ◇ Q.
Proof. by rewrite /uPred_now_True or_and_l. Qed.
Lemma now_True_sep P Q : ◇ (P ★ Q) ⊣⊢ ◇ P ★ ◇ Q.
Proof.
  rewrite /uPred_now_True. apply (anti_symm _).
  - apply or_elim; last by auto.
    by rewrite -!or_intro_l -always_pure -always_later -always_sep_dup'.
  - rewrite sep_or_r sep_elim_l sep_or_l; auto.
Qed.
Lemma now_True_forall {A} (Φ : A → uPred M) : ◇ (∀ a, Φ a) ⊢ ∀ a, ◇ Φ a.
Proof. apply forall_intro=> a. by rewrite (forall_elim a). Qed.
Lemma now_True_exist {A} (Φ : A → uPred M) : (∃ a, ◇ Φ a) ⊢ ◇ ∃ a, Φ a.
Proof. apply exist_elim=> a. by rewrite (exist_intro a). Qed.
Lemma now_True_later P : ◇ ▷ P ⊢ ▷ P.
Proof. by rewrite /uPred_now_True -later_or False_or. Qed.
Lemma now_True_always P : ◇ □ P ⊣⊢ □ ◇ P.
Proof. by rewrite /uPred_now_True always_or always_later always_pure. Qed.
Lemma now_True_always_if p P : ◇ □?p P ⊣⊢ □?p ◇ P.
Proof. destruct p; simpl; auto using now_True_always. Qed.
Lemma now_True_frame_l P Q : P ★ ◇ Q ⊢ ◇ (P ★ Q).
Proof. by rewrite {1}(now_True_intro P) now_True_sep. Qed.
Lemma now_True_frame_r P Q : ◇ P ★ Q ⊢ ◇ (P ★ Q).
Proof. by rewrite {1}(now_True_intro Q) now_True_sep. Qed.

(* Own *)
Lemma ownM_op (a1 a2 : M) :
  uPred_ownM (a1 ⋅ a2) ⊣⊢ uPred_ownM a1 ★ uPred_ownM a2.
Proof.
  unseal; split=> n x ?; split.
  - intros [z ?]; exists a1, (a2 ⋅ z); split; [by rewrite (assoc op)|].
    split. by exists (core a1); rewrite cmra_core_r. by exists z.
  - intros (y1&y2&Hx&[z1 Hy1]&[z2 Hy2]); exists (z1 ⋅ z2).
    by rewrite (assoc op _ z1) -(comm op z1) (assoc op z1)
      -(assoc op _ a2) (comm op z1) -Hy1 -Hy2.
Qed.
Lemma always_ownM (a : M) : Persistent a → □ uPred_ownM a ⊣⊢ uPred_ownM a.
Proof.
  split=> n x /=; split; [by apply always_elim|unseal; intros Hx]; simpl.
  rewrite -(persistent_core a). by apply cmra_core_monoN.
Qed.
Lemma ownM_something : True ⊢ ∃ a, uPred_ownM a.
Proof. unseal; split=> n x ??. by exists x; simpl. Qed.
Lemma ownM_empty : True ⊢ uPred_ownM ∅.
Proof. unseal; split=> n x ??; by  exists x; rewrite left_id. Qed.

(* Valid *)
Lemma ownM_valid (a : M) : uPred_ownM a ⊢ ✓ a.
Proof.
  unseal; split=> n x Hv [a' ?]; cofe_subst; eauto using cmra_validN_op_l.
Qed.
Lemma valid_intro {A : cmraT} (a : A) : ✓ a → True ⊢ ✓ a.
Proof. unseal=> ?; split=> n x ? _ /=; by apply cmra_valid_validN. Qed.
Lemma valid_elim {A : cmraT} (a : A) : ¬ ✓{0} a → ✓ a ⊢ False.
Proof. unseal=> Ha; split=> n x ??; apply Ha, cmra_validN_le with n; auto. Qed.
Lemma always_valid {A : cmraT} (a : A) : □ ✓ a ⊣⊢ ✓ a.
Proof. by unseal. Qed.
Lemma valid_weaken {A : cmraT} (a b : A) : ✓ (a ⋅ b) ⊢ ✓ a.
Proof. unseal; split=> n x _; apply cmra_validN_op_l. Qed.

(* Own and valid derived *)
Lemma ownM_invalid (a : M) : ¬ ✓{0} a → uPred_ownM a ⊢ False.
Proof. by intros; rewrite ownM_valid valid_elim. Qed.
Global Instance ownM_mono : Proper (flip (≼) ==> (⊢)) (@uPred_ownM M).
Proof. intros a b [b' ->]. rewrite ownM_op. eauto. Qed.

(* Viewshifts *)
Lemma rvs_intro P : P =r=> P.
Proof.
  unseal. split=> n x ? HP k yf ?; exists x; split; first done.
  apply uPred_closed with n; eauto using cmra_validN_op_l.
Qed.
Lemma rvs_mono P Q : (P ⊢ Q) → (|=r=> P) =r=> Q.
Proof.
  unseal. intros HPQ; split=> n x ? HP k yf ??.
  destruct (HP k yf) as (x'&?&?); eauto.
  exists x'; split; eauto using uPred_in_entails, cmra_validN_op_l.
Qed.
Lemma rvs_trans P : (|=r=> |=r=> P) =r=> P.
Proof. unseal; split; naive_solver. Qed.
Lemma rvs_frame_r P R : (|=r=> P) ★ R =r=> P ★ R.
Proof.
  unseal; split; intros n x ? (x1&x2&Hx&HP&?) k yf ??.
  destruct (HP k (x2 ⋅ yf)) as (x'&?&?); eauto.
  { by rewrite assoc -(dist_le _ _ _ _ Hx); last lia. }
  exists (x' ⋅ x2); split; first by rewrite -assoc.
  exists x', x2; split_and?; auto.
  apply uPred_closed with n; eauto 3 using cmra_validN_op_l, cmra_validN_op_r.
Qed.
Lemma rvs_ownM_updateP x (Φ : M → Prop) :
  x ~~>: Φ → uPred_ownM x =r=> ∃ y, ■ Φ y ∧ uPred_ownM y.
Proof.
  unseal=> Hup; split=> n x2 ? [x3 Hx] k yf ??.
  destruct (Hup k (Some (x3 ⋅ yf))) as (y&?&?); simpl in *.
  { rewrite /= assoc -(dist_le _ _ _ _ Hx); auto. }
  exists (y ⋅ x3); split; first by rewrite -assoc.
  exists y; eauto using cmra_includedN_l.
Qed.
Lemma now_True_rvs P : ◇ (|=r=> P) ⊢ (|=r=> ◇ P).
Proof.
  rewrite /uPred_now_True. apply or_elim; auto using rvs_mono.
  by rewrite -rvs_intro -or_intro_l.
Qed.

(** * Derived rules *)
Global Instance rvs_mono' : Proper ((⊢) ==> (⊢)) (@uPred_rvs M).
Proof. intros P Q; apply rvs_mono. Qed.
Global Instance rvs_flip_mono' : Proper (flip (⊢) ==> flip (⊢)) (@uPred_rvs M).
Proof. intros P Q; apply rvs_mono. Qed.
Lemma rvs_frame_l R Q : (R ★ |=r=> Q) =r=> R ★ Q.
Proof. rewrite !(comm _ R); apply rvs_frame_r. Qed.
Lemma rvs_wand_l P Q : (P -★ Q) ★ (|=r=> P) =r=> Q.
Proof. by rewrite rvs_frame_l wand_elim_l. Qed.
Lemma rvs_wand_r P Q : (|=r=> P) ★ (P -★ Q) =r=> Q.
Proof. by rewrite rvs_frame_r wand_elim_r. Qed.
Lemma rvs_sep P Q : (|=r=> P) ★ (|=r=> Q) =r=> P ★ Q.
Proof. by rewrite rvs_frame_r rvs_frame_l rvs_trans. Qed.
Lemma rvs_ownM_update x y : x ~~> y → uPred_ownM x ⊢ |=r=> uPred_ownM y.
Proof.
  intros; rewrite (rvs_ownM_updateP _ (y =)); last by apply cmra_update_updateP.
  by apply rvs_mono, exist_elim=> y'; apply pure_elim_l=> ->.
Qed.

(* Products *)
Lemma prod_equivI {A B : cofeT} (x y : A * B) : x ≡ y ⊣⊢ x.1 ≡ y.1 ∧ x.2 ≡ y.2.
Proof. by unseal. Qed.
Lemma prod_validI {A B : cmraT} (x : A * B) : ✓ x ⊣⊢ ✓ x.1 ∧ ✓ x.2.
Proof. by unseal. Qed.

(* Later *)
Lemma later_equivI {A : cofeT} (x y : later A) :
  x ≡ y ⊣⊢ ▷ (later_car x ≡ later_car y).
Proof. by unseal. Qed.

(* Discrete *)
Lemma discrete_valid {A : cmraT} `{!CMRADiscrete A} (a : A) : ✓ a ⊣⊢ ■ ✓ a.
Proof. unseal; split=> n x _. by rewrite /= -cmra_discrete_valid_iff. Qed.
Lemma timeless_eq {A : cofeT} (a b : A) : Timeless a → a ≡ b ⊣⊢ ■ (a ≡ b).
Proof.
  unseal=> ?. apply (anti_symm (⊢)); split=> n x ?; by apply (timeless_iff n).
Qed.

(* Option *)
Lemma option_equivI {A : cofeT} (mx my : option A) :
  mx ≡ my ⊣⊢ match mx, my with
             | Some x, Some y => x ≡ y | None, None => True | _, _ => False
             end.
Proof.
  uPred.unseal. do 2 split. by destruct 1. by destruct mx, my; try constructor.
Qed.
Lemma option_validI {A : cmraT} (mx : option A) :
  ✓ mx ⊣⊢ match mx with Some x => ✓ x | None => True end.
Proof. uPred.unseal. by destruct mx. Qed.

(* Equivalent definition of timeless in the model *)
Lemma timelessP_spec P : TimelessP P ↔ ∀ n x, ✓{n} x → P 0 x → P n x.
Proof.
  split.
  - intros HP n x ??; induction n as [|n]; auto.
    move: HP; rewrite /TimelessP /uPred_now_True /=.
    unseal=> /uPred_in_entails /(_ (S n) x) /=.
    by destruct 1; auto using cmra_validN_S.
  - move=> HP; rewrite /TimelessP /uPred_now_True /=.
    unseal; split=> -[|n] x /=; auto.
    right. apply HP, uPred_closed with n; eauto using cmra_validN_le.
Qed.

(* Timeless instances *)
Global Instance pure_timeless φ : TimelessP (■ φ : uPred M)%I.
Proof. by apply timelessP_spec; unseal => -[|n] x. Qed.
Global Instance valid_timeless {A : cmraT} `{CMRADiscrete A} (a : A) :
  TimelessP (✓ a : uPred M)%I.
Proof.
  apply timelessP_spec; unseal=> n x /=. by rewrite -!cmra_discrete_valid_iff.
Qed.
Global Instance and_timeless P Q: TimelessP P → TimelessP Q → TimelessP (P ∧ Q).
Proof. intros; rewrite /TimelessP now_True_and later_and; auto. Qed.
Global Instance or_timeless P Q : TimelessP P → TimelessP Q → TimelessP (P ∨ Q).
Proof. intros; rewrite /TimelessP now_True_or later_or; auto. Qed.
Global Instance impl_timeless P Q : TimelessP Q → TimelessP (P → Q).
Proof.
  rewrite !timelessP_spec; unseal=> HP [|n] x ? HPQ [|n'] x' ????; auto.
  apply HP, HPQ, uPred_closed with (S n'); eauto using cmra_validN_le.
Qed.
Global Instance sep_timeless P Q: TimelessP P → TimelessP Q → TimelessP (P ★ Q).
Proof. intros; rewrite /TimelessP now_True_sep later_sep; auto. Qed.
Global Instance wand_timeless P Q : TimelessP Q → TimelessP (P -★ Q).
Proof.
  rewrite !timelessP_spec; unseal=> HP [|n] x ? HPQ [|n'] x' ???; auto.
  apply HP, HPQ, uPred_closed with (S n');
    eauto 3 using cmra_validN_le, cmra_validN_op_r.
Qed.
Global Instance forall_timeless {A} (Ψ : A → uPred M) :
  (∀ x, TimelessP (Ψ x)) → TimelessP (∀ x, Ψ x).
Proof. by setoid_rewrite timelessP_spec; unseal=> HΨ n x ?? a; apply HΨ. Qed.
Global Instance exist_timeless {A} (Ψ : A → uPred M) :
  (∀ x, TimelessP (Ψ x)) → TimelessP (∃ x, Ψ x).
Proof.
  by setoid_rewrite timelessP_spec; unseal=> HΨ [|n] x ?;
    [|intros [a ?]; exists a; apply HΨ].
Qed.
Global Instance always_timeless P : TimelessP P → TimelessP (□ P).
Proof. intros; rewrite /TimelessP now_True_always -always_later; auto. Qed.
Global Instance always_if_timeless p P : TimelessP P → TimelessP (□?p P).
Proof. destruct p; apply _. Qed.
Global Instance eq_timeless {A : cofeT} (a b : A) :
  Timeless a → TimelessP (a ≡ b : uPred M)%I.
Proof.
  intro; apply timelessP_spec; unseal=> n x ??; by apply equiv_dist, timeless.
Qed.
Global Instance ownM_timeless (a : M) : Timeless a → TimelessP (uPred_ownM a).
Proof.
  intro; apply timelessP_spec; unseal=> n x ??; apply cmra_included_includedN,
    cmra_timeless_included_l; eauto using cmra_validN_le.
Qed.

(* Persistence *)
Global Instance pure_persistent φ : PersistentP (■ φ : uPred M)%I.
Proof. by rewrite /PersistentP always_pure. Qed.
Global Instance always_persistent P : PersistentP (□ P).
Proof. by intros; apply always_intro'. Qed.
Global Instance and_persistent P Q :
  PersistentP P → PersistentP Q → PersistentP (P ∧ Q).
Proof. by intros; rewrite /PersistentP always_and; apply and_mono. Qed.
Global Instance or_persistent P Q :
  PersistentP P → PersistentP Q → PersistentP (P ∨ Q).
Proof. by intros; rewrite /PersistentP always_or; apply or_mono. Qed.
Global Instance sep_persistent P Q :
  PersistentP P → PersistentP Q → PersistentP (P ★ Q).
Proof. by intros; rewrite /PersistentP always_sep; apply sep_mono. Qed.
Global Instance forall_persistent {A} (Ψ : A → uPred M) :
  (∀ x, PersistentP (Ψ x)) → PersistentP (∀ x, Ψ x).
Proof. by intros; rewrite /PersistentP always_forall; apply forall_mono. Qed.
Global Instance exist_persistent {A} (Ψ : A → uPred M) :
  (∀ x, PersistentP (Ψ x)) → PersistentP (∃ x, Ψ x).
Proof. by intros; rewrite /PersistentP always_exist; apply exist_mono. Qed.
Global Instance eq_persistent {A : cofeT} (a b : A) :
  PersistentP (a ≡ b : uPred M)%I.
Proof. by intros; rewrite /PersistentP always_eq. Qed.
Global Instance valid_persistent {A : cmraT} (a : A) :
  PersistentP (✓ a : uPred M)%I.
Proof. by intros; rewrite /PersistentP always_valid. Qed.
Global Instance later_persistent P : PersistentP P → PersistentP (▷ P).
Proof. by intros; rewrite /PersistentP always_later; apply later_mono. Qed.
Global Instance ownM_persistent : Persistent a → PersistentP (@uPred_ownM M a).
Proof. intros. by rewrite /PersistentP always_ownM. Qed.
Global Instance from_option_persistent {A} P (Ψ : A → uPred M) (mx : option A) :
  (∀ x, PersistentP (Ψ x)) → PersistentP P → PersistentP (from_option Ψ P mx).
Proof. destruct mx; apply _. Qed.

(* Derived lemmas for persistence *)
Lemma always_always P `{!PersistentP P} : □ P ⊣⊢ P.
Proof. apply (anti_symm (⊢)); auto using always_elim. Qed.
Lemma always_if_always p P `{!PersistentP P} : □?p P ⊣⊢ P.
Proof. destruct p; simpl; auto using always_always. Qed.
Lemma always_intro P Q `{!PersistentP P} : (P ⊢ Q) → P ⊢ □ Q.
Proof. rewrite -(always_always P); apply always_intro'. Qed.
Lemma always_and_sep_l P Q `{!PersistentP P} : P ∧ Q ⊣⊢ P ★ Q.
Proof. by rewrite -(always_always P) always_and_sep_l'. Qed.
Lemma always_and_sep_r P Q `{!PersistentP Q} : P ∧ Q ⊣⊢ P ★ Q.
Proof. by rewrite -(always_always Q) always_and_sep_r'. Qed.
Lemma always_sep_dup P `{!PersistentP P} : P ⊣⊢ P ★ P.
Proof. by rewrite -(always_always P) -always_sep_dup'. Qed.
Lemma always_entails_l P Q `{!PersistentP Q} : (P ⊢ Q) → P ⊢ Q ★ P.
Proof. by rewrite -(always_always Q); apply always_entails_l'. Qed.
Lemma always_entails_r P Q `{!PersistentP Q} : (P ⊢ Q) → P ⊢ P ★ Q.
Proof. by rewrite -(always_always Q); apply always_entails_r'. Qed.

(* Soundness results *)
Lemma adequacy φ n : (True ⊢ Nat.iter n (λ P, |=r=> ▷ P) (■ φ)) → φ.
Proof.
  cut (∀ x, ✓{n} x → Nat.iter n (λ P, |=r=> ▷ P)%I (■ φ)%I n x → φ).
  { intros help H. eapply (help ∅); eauto using ucmra_unit_validN.
    eapply H; try unseal; eauto using ucmra_unit_validN. }
  unseal. induction n as [|n IH]=> x Hx Hvs; auto.
  destruct (Hvs (S n) ∅) as (x'&?&?); rewrite ?right_id; auto.
  eapply IH with x'; eauto using cmra_validN_S, cmra_validN_op_l.
Qed.

Theorem soundness : ¬ (True ⊢ False).
Proof. exact (adequacy False 0). Qed.
End uPred_logic.

(* Hint DB for the logic *)
Hint Resolve pure_intro.
Hint Resolve or_elim or_intro_l' or_intro_r' : I.
Hint Resolve and_intro and_elim_l' and_elim_r' : I.
Hint Resolve always_mono : I.
Hint Resolve sep_elim_l' sep_elim_r' sep_mono : I.
Hint Immediate True_intro False_elim : I.
Hint Immediate iff_refl eq_refl' : I.
End uPred.