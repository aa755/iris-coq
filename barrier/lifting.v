Require Import prelude.gmap iris.lifting.
Require Export iris.weakestpre barrier.parameter.
Import uPred.

(* TODO RJ: Figure out a way to to always use our Σ. *)

(** Bind. *)
Lemma wp_bind E e K Q :
  wp (Σ:=Σ) E e (λ v, wp (Σ:=Σ) E (fill K (v2e v)) Q) ⊑ wp (Σ:=Σ) E (fill K e) Q.
Proof.
  by apply (wp_bind (Σ:=Σ) (K := fill K)), fill_is_ctx.
Qed.

(** Base axioms for core primitives of the language: Stateful reductions *)

Lemma wp_lift_step E1 E2 (φ : expr → state → Prop) Q e1 σ1 :
  E1 ⊆ E2 → to_val e1 = None →
  reducible e1 σ1 →
  (∀ e2 σ2 ef, prim_step e1 σ1 e2 σ2 ef → ef = None ∧ φ e2 σ2) →
  pvs E2 E1 (ownP (Σ:=Σ) σ1 ★ ▷ ∀ e2 σ2, (■ φ e2 σ2 ∧ ownP (Σ:=Σ) σ2) -★
    pvs E1 E2 (wp (Σ:=Σ) E2 e2 Q))
  ⊑ wp (Σ:=Σ) E2 e1 Q.
Proof.
  intros ? He Hsafe Hstep.
  (* RJ: working around https://coq.inria.fr/bugs/show_bug.cgi?id=4536 *)
  etransitivity; last eapply wp_lift_step with (σ2 := σ1)
    (φ0 := λ e' σ' ef, ef = None ∧ φ e' σ'); last first.
  - intros e2 σ2 ef Hstep'%prim_ectx_step; last done.
    by apply Hstep.
  - destruct Hsafe as (e' & σ' & ? & ?).
    do 3 eexists. exists EmptyCtx. do 2 eexists.
    split_ands; try (by rewrite fill_empty); eassumption.
  - done.
  - eassumption.
  - apply pvs_mono. apply sep_mono; first done.
    apply later_mono. apply forall_mono=>e2. apply forall_mono=>σ2.
    apply forall_intro=>ef. apply wand_intro_l.
    rewrite always_and_sep_l' -associative -always_and_sep_l'.
    apply const_elim_l; move=>[-> Hφ]. eapply const_intro_l; first eexact Hφ.
    rewrite always_and_sep_l' associative -always_and_sep_l' wand_elim_r.
    apply pvs_mono. rewrite right_id. done.
Qed.

(* TODO RJ: Figure out some better way to make the
   postcondition a predicate over a *location* *)
Lemma wp_alloc E σ e v:
  e2v e = Some v →
  ownP (Σ:=Σ) σ ⊑ wp (Σ:=Σ) E (Alloc e)
       (λ v', ∃ l, ■(v' = LocV l ∧ σ !! l = None) ∧ ownP (Σ:=Σ) (<[l:=v]>σ)).
Proof.
  (* RJ FIXME (also for most other lemmas in this file): rewrite would be nicer... *)
  intros Hvl. etransitivity; last eapply wp_lift_step with (σ1 := σ)
    (φ := λ e' σ', ∃ l, e' = Loc l ∧ σ' = <[l:=v]>σ ∧ σ !! l = None);
    last first.
  - intros e2 σ2 ef Hstep. inversion_clear Hstep. split; first done.
    rewrite Hv in Hvl. inversion_clear Hvl.
    eexists; split_ands; done.
  - set (l := fresh $ dom (gset loc) σ).
    exists (Loc l), ((<[l:=v]>)σ), None. eapply AllocS; first done.
    apply (not_elem_of_dom (D := gset loc)). apply is_fresh.
  - reflexivity.
  - reflexivity.
  - (* RJ FIXME I am sure there is a better way to invoke right_id, but I could not find it. *)
    rewrite -pvs_intro. rewrite -{1}[ownP σ](@right_id _ _ _ _ uPred.sep_True).
    apply sep_mono; first done. rewrite -later_intro.
    apply forall_intro=>e2. apply forall_intro=>σ2.
    apply wand_intro_l. rewrite right_id. rewrite -pvs_intro.
    apply const_elim_l. intros [l [-> [-> Hl]]].
    rewrite -wp_value'; last reflexivity.
    erewrite <-exist_intro with (a := l). apply and_intro.
    + by apply const_intro.
    + done.
Qed.

Lemma wp_load E σ l v:
  σ !! l = Some v →
  ownP (Σ:=Σ) σ ⊑ wp (Σ:=Σ) E (Load (Loc l)) (λ v', ■(v' = v) ∧ ownP (Σ:=Σ) σ).
Proof.
  intros Hl. etransitivity; last eapply wp_lift_step with (σ1 := σ)
    (φ := λ e' σ', e' = v2e v ∧ σ' = σ); last first.
  - intros e2 σ2 ef Hstep. move: Hl. inversion_clear Hstep=>{σ}.
    rewrite Hlookup. case=>->. done.
  - do 3 eexists. econstructor; eassumption.
  - reflexivity.
  - reflexivity.
  - rewrite -pvs_intro. rewrite -{1}[ownP σ](@right_id _ _ _ _ uPred.sep_True).
    apply sep_mono; first done. rewrite -later_intro.
    apply forall_intro=>e2. apply forall_intro=>σ2.
    apply wand_intro_l. rewrite right_id. rewrite -pvs_intro.
    apply const_elim_l. intros [-> ->].
    rewrite -wp_value. apply and_intro.
    + by apply const_intro.
    + done.
Qed.

Lemma wp_store E σ l e v v':
  e2v e = Some v →
  σ !! l = Some v' →
  ownP (Σ:=Σ) σ ⊑ wp (Σ:=Σ) E (Store (Loc l) e)
       (λ v', ■(v' = LitUnitV) ∧ ownP (Σ:=Σ) (<[l:=v]>σ)).
Proof.
  intros Hvl Hl. etransitivity; last eapply wp_lift_step with (σ1 := σ)
    (φ := λ e' σ', e' = LitUnit ∧ σ' = <[l:=v]>σ); last first.
  - intros e2 σ2 ef Hstep. move: Hl. inversion_clear Hstep=>{σ2}.
    rewrite Hvl in Hv. inversion_clear Hv. done.
  - do 3 eexists. eapply StoreS; last (eexists; eassumption). eassumption.
  - reflexivity.
  - reflexivity.
  - rewrite -pvs_intro. rewrite -{1}[ownP σ](@right_id _ _ _ _ uPred.sep_True).
    apply sep_mono; first done. rewrite -later_intro.
    apply forall_intro=>e2. apply forall_intro=>σ2.
    apply wand_intro_l. rewrite right_id. rewrite -pvs_intro.
    apply const_elim_l. intros [-> ->].
    rewrite -wp_value'; last reflexivity. apply and_intro.
    + by apply const_intro.
    + done.
Qed.

(** Base axioms for core primitives of the language: Stateless reductions *)

Lemma wp_fork E e :
  ▷ wp (Σ:=Σ) coPset_all e (λ _, True) ⊑ wp (Σ:=Σ) E (Fork e) (λ v, ■(v = LitUnitV)).
Proof.
  etransitivity; last eapply wp_lift_pure_step with
    (φ := λ e' ef, e' = LitUnit ∧ ef = Some e);
    last first.
  - intros σ1 e2 σ2 ef Hstep%prim_ectx_step; last first.
    { do 3 eexists. eapply ForkS. }
    inversion_clear Hstep. done.
  - intros ?. do 3 eexists. exists EmptyCtx. do 2 eexists.
    split_ands; try (by rewrite fill_empty); [].
    eapply ForkS.
  - reflexivity.
  - apply later_mono.
    apply forall_intro=>e2. apply forall_intro=>ef.
    apply impl_intro_l. apply const_elim_l. intros [-> ->].
    (* FIXME RJ This is ridicolous. *)
    transitivity (True ★ wp coPset_all e (λ _ : ival Σ, True))%I;
      first by rewrite left_id.
    apply sep_mono; last reflexivity.
    rewrite -wp_value'; last reflexivity.
    by apply const_intro.
Qed.

Lemma wp_lift_pure_step E (φ : expr → Prop) Q e1 :
  to_val e1 = None →
  (∀ σ1, reducible e1 σ1) →
  (∀ σ1 e2 σ2 ef, prim_step e1 σ1 e2 σ2 ef → σ1 = σ2 ∧ ef = None ∧ φ e2) →
  (▷ ∀ e2, ■ φ e2 → wp (Σ:=Σ) E e2 Q) ⊑ wp (Σ:=Σ) E e1 Q.
Proof.
  intros He Hsafe Hstep.
  (* RJ: working around https://coq.inria.fr/bugs/show_bug.cgi?id=4536 *)
  etransitivity; last eapply wp_lift_pure_step with
    (φ0 := λ e' ef, ef = None ∧ φ e'); last first.
  - intros σ1 e2 σ2 ef Hstep'%prim_ectx_step; last done.
    by apply Hstep.
  - intros σ1. destruct (Hsafe σ1) as (e' & σ' & ? & ?).
    do 3 eexists. exists EmptyCtx. do 2 eexists.
    split_ands; try (by rewrite fill_empty); eassumption.
  - done.
  - apply later_mono. apply forall_mono=>e2. apply forall_intro=>ef.
    apply impl_intro_l. apply const_elim_l; move=>[-> Hφ].
    eapply const_intro_l; first eexact Hφ. rewrite impl_elim_r.
    rewrite right_id. done.
Qed.

Lemma wp_rec' E e v Q :
  ▷wp (Σ:=Σ) E (e.[Rec e, v2e v /]) Q ⊑ wp (Σ:=Σ) E (App (Rec e) (v2e v)) Q.
Proof.
  etransitivity; last eapply wp_lift_pure_step with
    (φ := λ e', e' = e.[Rec e, v2e v /]); last first.
  - intros ? ? ? ? Hstep. inversion_clear Hstep. done.
  - intros ?. do 3 eexists. eapply BetaS. by rewrite v2v.
  - reflexivity.
  - apply later_mono, forall_intro=>e2. apply impl_intro_l.
    apply const_elim_l=>->. done.
Qed.

Lemma wp_lam E e v Q :
  ▷wp (Σ:=Σ) E (e.[v2e v/]) Q ⊑ wp (Σ:=Σ) E (App (Lam e) (v2e v)) Q.
Proof.
  rewrite -wp_rec'.
  (* RJ: This pulls in functional extensionality. If that bothers us, we have
     to talk to the Autosubst guys. *)
  by asimpl.
Qed.

Lemma wp_plus n1 n2 E Q :
  ▷Q (LitNatV (n1 + n2)) ⊑ wp (Σ:=Σ) E (Plus (LitNat n1) (LitNat n2)) Q.
Proof.
  etransitivity; last eapply wp_lift_pure_step with
    (φ := λ e', e' = LitNat (n1 + n2)); last first.
  - intros ? ? ? ? Hstep. inversion_clear Hstep; done.
  - intros ?. do 3 eexists. econstructor.
  - reflexivity.
  - apply later_mono, forall_intro=>e2. apply impl_intro_l.
    apply const_elim_l=>->.
    rewrite -wp_value'; last reflexivity; done.
Qed.
