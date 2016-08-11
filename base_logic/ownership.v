From iris.base_logic Require Export iprop.
From iris.algebra Require Import iprod gmap.
Import uPred.

(** The class [inG Σ A] expresses that the CMRA [A] is in the list of functors
[Σ]. This class is similar to the [subG] class, but written down in terms of
individual CMRAs instead of (lists of) CMRA *functors*. This additional class is
needed because Coq is otherwise unable to solve type class constraints due to
higher-order unification problems. *)
Class inG (Σ : gFunctors) (A : cmraT) :=
  InG { inG_id : gid Σ; inG_prf : A = Σ inG_id (iPreProp Σ) }.
Arguments inG_id {_ _} _.

Lemma subG_inG Σ (F : gFunctor) : subG F Σ → inG Σ (F (iPreProp Σ)).
Proof. move=> /(_ 0%fin) /= [j ->]. by exists j. Qed.

(** * Definition of the connective [own] *)
Definition iRes_singleton `{i : inG Σ A} (γ : gname) (a : A) : iResUR Σ :=
  iprod_singleton (inG_id i) {[ γ := cmra_transport inG_prf a ]}.
Instance: Params (@iRes_singleton) 4.

Definition own_def `{inG Σ A} (γ : gname) (a : A) : iProp Σ :=
  uPred_ownM (iRes_singleton γ a).
Definition own_aux : { x | x = @own_def }. by eexists. Qed.
Definition own {Σ A i} := proj1_sig own_aux Σ A i.
Definition own_eq : @own = @own_def := proj2_sig own_aux.
Instance: Params (@own) 4.
Typeclasses Opaque own.

(** * Properties about ghost ownership *)
Section global.
Context `{i : inG Σ A}.
Implicit Types a : A.

(** ** Properties of [iRes_singleton] *)
Global Instance iRes_singleton_ne γ n :
  Proper (dist n ==> dist n) (@iRes_singleton Σ A _ γ).
Proof. by intros a a' Ha; apply iprod_singleton_ne; rewrite Ha. Qed.
Lemma iRes_singleton_op γ a1 a2 :
  iRes_singleton γ (a1 ⋅ a2) ≡ iRes_singleton γ a1 ⋅ iRes_singleton γ a2.
Proof.
  by rewrite /iRes_singleton iprod_op_singleton op_singleton cmra_transport_op.
Qed.

(** ** Properties of [own] *)
Global Instance own_ne γ n : Proper (dist n ==> dist n) (@own Σ A _ γ).
Proof. rewrite !own_eq. solve_proper. Qed.
Global Instance own_proper γ :
  Proper ((≡) ==> (⊣⊢)) (@own Σ A _ γ) := ne_proper _.

Lemma own_op γ a1 a2 : own γ (a1 ⋅ a2) ⊣⊢ own γ a1 ★ own γ a2.
Proof. by rewrite !own_eq /own_def -ownM_op iRes_singleton_op. Qed.
Global Instance own_mono γ : Proper (flip (≼) ==> (⊢)) (@own Σ A _ γ).
Proof. move=>a b [c ->]. rewrite own_op. eauto with I. Qed.
Lemma own_valid γ a : own γ a ⊢ ✓ a.
Proof.
  rewrite !own_eq /own_def ownM_valid /iRes_singleton.
  rewrite iprod_validI (forall_elim (inG_id i)) iprod_lookup_singleton.
  rewrite gmap_validI (forall_elim γ) lookup_singleton option_validI.
  (* implicit arguments differ a bit *)
  by trans (✓ cmra_transport inG_prf a : iProp Σ)%I; last destruct inG_prf.
Qed.
Lemma own_valid_r γ a : own γ a ⊢ own γ a ★ ✓ a.
Proof. apply: uPred.always_entails_r. apply own_valid. Qed.
Lemma own_valid_l γ a : own γ a ⊢ ✓ a ★ own γ a.
Proof. by rewrite comm -own_valid_r. Qed.
Global Instance own_timeless γ a : Timeless a → TimelessP (own γ a).
Proof. rewrite !own_eq /own_def; apply _. Qed.
Global Instance own_core_persistent γ a : Persistent a → PersistentP (own γ a).
Proof. rewrite !own_eq /own_def; apply _. Qed.

(** ** Allocation *)
(* TODO: This also holds if we just have ✓ a at the current step-idx, as Iris
   assertion. However, the map_updateP_alloc does not suffice to show this. *)
Lemma own_alloc_strong a (G : gset gname) :
  ✓ a → True =r=> ∃ γ, ■ (γ ∉ G) ∧ own γ a.
Proof.
  intros Ha.
  rewrite -(rvs_mono (∃ m, ■ (∃ γ, γ ∉ G ∧ m = iRes_singleton γ a) ∧ uPred_ownM m)%I).
  - rewrite ownM_empty.
    eapply rvs_ownM_updateP, (iprod_singleton_updateP_empty (inG_id i));
      first (eapply alloc_updateP_strong', cmra_transport_valid, Ha);
      naive_solver.
  - apply exist_elim=>m; apply pure_elim_l=>-[γ [Hfresh ->]].
    by rewrite !own_eq /own_def -(exist_intro γ) pure_equiv // left_id.
Qed.
Lemma own_alloc a : ✓ a → True =r=> ∃ γ, own γ a.
Proof.
  intros Ha. rewrite (own_alloc_strong a ∅) //; [].
  apply rvs_mono, exist_mono=>?. eauto with I.
Qed.

(** ** Frame preserving updates *)
Lemma own_updateP P γ a : a ~~>: P → own γ a =r=> ∃ a', ■ P a' ∧ own γ a'.
Proof.
  intros Ha. rewrite !own_eq.
  rewrite -(rvs_mono (∃ m, ■ (∃ a', m = iRes_singleton γ a' ∧ P a') ∧ uPred_ownM m)%I).
  - eapply rvs_ownM_updateP, iprod_singleton_updateP;
      first by (eapply singleton_updateP', cmra_transport_updateP', Ha).
    naive_solver.
  - apply exist_elim=>m; apply pure_elim_l=>-[a' [-> HP]].
    rewrite -(exist_intro a'). by apply and_intro; [apply pure_intro|].
Qed.

Lemma own_update γ a a' : a ~~> a' → own γ a =r=> own γ a'.
Proof.
  intros; rewrite (own_updateP (a' =)); last by apply cmra_update_updateP.
  by apply rvs_mono, exist_elim=> a''; apply pure_elim_l=> ->.
Qed.
End global.

Arguments own_valid {_ _} [_] _ _.
Arguments own_valid_l {_ _} [_] _ _.
Arguments own_valid_r {_ _} [_] _ _.
Arguments own_updateP {_ _} [_] _ _ _ _.
Arguments own_update {_ _} [_] _ _ _ _.

Lemma own_empty `{inG Σ (A:ucmraT)} γ : True =r=> own γ ∅.
Proof.
  rewrite ownM_empty !own_eq /own_def.
  apply rvs_ownM_update, iprod_singleton_update_empty.
  apply (alloc_unit_singleton_update (cmra_transport inG_prf ∅)); last done.
  - apply cmra_transport_valid, ucmra_unit_valid.
  - intros x; destruct inG_prf. by rewrite left_id.
Qed.