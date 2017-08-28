From iris.program_logic Require Export weakestpre.
From iris.proofmode Require Import coq_tactics.
From iris.proofmode Require Export tactics.
From iris.heap_lang Require Export tactics lifting.
Set Default Proof Using "Type".
Import uPred.

(** wp-specific helper tactics *)
Ltac wp_bind_core K :=
  lazymatch eval hnf in K with
  | [] => idtac
  | _ => etrans; [|fast_by apply (wp_bind K)]; simpl
  end.

(* Solves side-conditions generated by the wp tactics *)
Ltac wp_done :=
  match goal with
  | |- Closed _ _ => solve_closed
  | |- is_Some (to_val _) => solve_to_val
  | |- to_val _ = Some _ => solve_to_val
  | |- language.to_val _ = Some _ => solve_to_val
  | _ => fast_done
  end.

Ltac wp_value_head := etrans; [|eapply wp_value; wp_done]; lazy beta.

Ltac wp_seq_head :=
  lazymatch goal with
  | |- _ ⊢ wp ?E (Seq _ _) ?Q =>
    etrans; [|eapply wp_seq; wp_done]; iNext
  end.

Ltac wp_finish := intros_revert ltac:(
  rewrite /= ?to_of_val;
  try iNext;
  repeat lazymatch goal with
  | |- _ ⊢ wp ?E (Seq _ _) ?Q =>
     etrans; [|eapply wp_seq; wp_done]; iNext
  | |- _ ⊢ wp ?E _ ?Q => wp_value_head
  end).

Tactic Notation "wp_value" :=
  iStartProof;
  lazymatch goal with
  | |- _ ⊢ wp ?E ?e ?Q => reshape_expr e ltac:(fun K e' =>
    wp_bind_core K; wp_value_head) || fail "wp_value: cannot find value in" e
  | _ => fail "wp_value: not a wp"
  end.

Lemma of_val_unlock v e : of_val v = e → of_val (locked v) = e.
Proof. by unlock. Qed.

(* Applied to goals that are equalities of expressions. Will try to unlock the
   LHS once if necessary, to get rid of the lock added by the syntactic sugar. *)
Ltac solve_of_val_unlock := try apply of_val_unlock; reflexivity.

Tactic Notation "wp_rec" :=
  iStartProof;
  lazymatch goal with
  | |- _ ⊢ wp ?E ?e ?Q => reshape_expr e ltac:(fun K e' =>
    match eval hnf in e' with App ?e1 _ =>
(* hnf does not reduce through an of_val *)
(*      match eval hnf in e1 with Rec _ _ _ => *)
    wp_bind_core K; etrans;
      [|eapply wp_rec; [solve_of_val_unlock|wp_done..]]; simpl_subst; wp_finish
(*      end *) end) || fail "wp_rec: cannot find 'Rec' in" e
  | _ => fail "wp_rec: not a 'wp'"
  end.

Tactic Notation "wp_lam" :=
  iStartProof;
  lazymatch goal with
  | |- _ ⊢ wp ?E ?e ?Q => reshape_expr e ltac:(fun K e' =>
    match eval hnf in e' with App ?e1 _ =>
(*    match eval hnf in e1 with Rec BAnon _ _ => *)
    wp_bind_core K; etrans;
      [|eapply wp_lam; [solve_of_val_unlock|wp_done..]]; simpl_subst; wp_finish
(*    end *) end) || fail "wp_lam: cannot find 'Lam' in" e
  | _ => fail "wp_lam: not a 'wp'"
  end.

Tactic Notation "wp_let" := wp_lam.
Tactic Notation "wp_seq" := wp_let.

Tactic Notation "wp_op" :=
  iStartProof;
  lazymatch goal with
  | |- _ ⊢ wp ?E ?e ?Q => reshape_expr e ltac:(fun K e' =>
    lazymatch eval hnf in e' with
    | BinOp LtOp _ _ => wp_bind_core K; apply wp_lt; wp_finish
    | BinOp LeOp _ _ => wp_bind_core K; apply wp_le; wp_finish
    | BinOp EqOp _ _ =>
       wp_bind_core K; eapply wp_eq; [wp_done|wp_done|wp_finish|wp_finish]
    | BinOp _ _ _ =>
       wp_bind_core K; etrans;
         [|eapply wp_bin_op; [wp_done|wp_done|try fast_done]]; wp_finish
    | UnOp _ _ =>
       wp_bind_core K; etrans;
         [|eapply wp_un_op; [wp_done|try fast_done]]; wp_finish
    end) || fail "wp_op: cannot find 'BinOp' or 'UnOp' in" e
  | _ => fail "wp_op: not a 'wp'"
  end.

Tactic Notation "wp_proj" :=
  iStartProof;
  lazymatch goal with
  | |- _ ⊢ wp ?E ?e ?Q => reshape_expr e ltac:(fun K e' =>
    match eval hnf in e' with
    | Fst _ => wp_bind_core K; etrans; [|eapply wp_fst; wp_done]; wp_finish
    | Snd _ => wp_bind_core K; etrans; [|eapply wp_snd; wp_done]; wp_finish
    end) || fail "wp_proj: cannot find 'Fst' or 'Snd' in" e
  | _ => fail "wp_proj: not a 'wp'"
  end.

Tactic Notation "wp_if" :=
  iStartProof;
  lazymatch goal with
  | |- _ ⊢ wp ?E ?e ?Q => reshape_expr e ltac:(fun K e' =>
    match eval hnf in e' with
    | If _ _ _ =>
      wp_bind_core K;
      etrans; [|eapply wp_if_true || eapply wp_if_false]; wp_finish
    end) || fail "wp_if: cannot find 'If' in" e
  | _ => fail "wp_if: not a 'wp'"
  end.

Tactic Notation "wp_match" :=
  iStartProof;
  lazymatch goal with
  | |- _ ⊢ wp ?E ?e ?Q => reshape_expr e ltac:(fun K e' =>
    match eval hnf in e' with
    | Case _ _ _ =>
      wp_bind_core K;
      etrans; [|first[eapply wp_match_inl; wp_done|eapply wp_match_inr; wp_done]];
      simpl_subst; wp_finish
    end) || fail "wp_match: cannot find 'Match' in" e
  | _ => fail "wp_match: not a 'wp'"
  end.

Tactic Notation "wp_bind" open_constr(efoc) :=
  iStartProof;
  lazymatch goal with
  | |- _ ⊢ wp ?E ?e ?Q => reshape_expr e ltac:(fun K e' =>
    match e' with
    | efoc => unify e' efoc; wp_bind_core K
    end) || fail "wp_bind: cannot find" efoc "in" e
  | _ => fail "wp_bind: not a 'wp'"
  end.

(** Heap tactics *)
Section heap.
Context `{heapG Σ}.
Implicit Types P Q : iProp Σ.
Implicit Types Φ : val → iProp Σ.
Implicit Types Δ : envs (iResUR Σ).

Lemma tac_wp_alloc Δ Δ' E j e v Φ :
  to_val e = Some v →
  IntoLaterNEnvs 1 Δ Δ' →
  (∀ l, ∃ Δ'',
    envs_app false (Esnoc Enil j (l ↦ v)) Δ' = Some Δ'' ∧
    (Δ'' ⊢ Φ (LitV (LitLoc l)))) →
  Δ ⊢ WP Alloc e @ E {{ Φ }}.
Proof.
  intros ?? HΔ. eapply wand_apply; first exact: wp_alloc.
  rewrite left_id into_laterN_env_sound; apply later_mono, forall_intro=> l.
  destruct (HΔ l) as (Δ''&?&HΔ'). rewrite envs_app_sound //; simpl.
  by rewrite right_id HΔ'.
Qed.

Lemma tac_wp_load Δ Δ' E i l q v Φ :
  IntoLaterNEnvs 1 Δ Δ' →
  envs_lookup i Δ' = Some (false, l ↦{q} v)%I →
  (Δ' ⊢ Φ v) →
  Δ ⊢ WP Load (Lit (LitLoc l)) @ E {{ Φ }}.
Proof.
  intros. eapply wand_apply; first exact: wp_load.
  rewrite into_laterN_env_sound -later_sep envs_lookup_split //; simpl.
  by apply later_mono, sep_mono_r, wand_mono.
Qed.

Lemma tac_wp_store Δ Δ' Δ'' E i l v e v' Φ :
  to_val e = Some v' →
  IntoLaterNEnvs 1 Δ Δ' →
  envs_lookup i Δ' = Some (false, l ↦ v)%I →
  envs_simple_replace i false (Esnoc Enil i (l ↦ v')) Δ' = Some Δ'' →
  (Δ'' ⊢ Φ (LitV LitUnit)) →
  Δ ⊢ WP Store (Lit (LitLoc l)) e @ E {{ Φ }}.
Proof.
  intros. eapply wand_apply; first by eapply wp_store.
  rewrite into_laterN_env_sound -later_sep envs_simple_replace_sound //; simpl.
  rewrite right_id. by apply later_mono, sep_mono_r, wand_mono.
Qed.

Lemma tac_wp_cas_fail Δ Δ' E i l q v e1 v1 e2 v2 Φ :
  to_val e1 = Some v1 → to_val e2 = Some v2 →
  IntoLaterNEnvs 1 Δ Δ' →
  envs_lookup i Δ' = Some (false, l ↦{q} v)%I → v ≠ v1 →
  (Δ' ⊢ Φ (LitV (LitBool false))) →
  Δ ⊢ WP CAS (Lit (LitLoc l)) e1 e2 @ E {{ Φ }}.
Proof.
  intros. eapply wand_apply; first exact: wp_cas_fail.
  rewrite into_laterN_env_sound -later_sep envs_lookup_split //; simpl.
  by apply later_mono, sep_mono_r, wand_mono.
Qed.

Lemma tac_wp_cas_suc Δ Δ' Δ'' E i l v e1 v1 e2 v2 Φ :
  to_val e1 = Some v1 → to_val e2 = Some v2 →
  IntoLaterNEnvs 1 Δ Δ' →
  envs_lookup i Δ' = Some (false, l ↦ v)%I → v = v1 →
  envs_simple_replace i false (Esnoc Enil i (l ↦ v2)) Δ' = Some Δ'' →
  (Δ'' ⊢ Φ (LitV (LitBool true))) →
  Δ ⊢ WP CAS (Lit (LitLoc l)) e1 e2 @ E {{ Φ }}.
Proof.
  intros; subst. eapply wand_apply; first exact: wp_cas_suc.
  rewrite into_laterN_env_sound -later_sep envs_simple_replace_sound //; simpl.
  rewrite right_id. by apply later_mono, sep_mono_r, wand_mono.
Qed.
End heap.

Tactic Notation "wp_apply" open_constr(lem) :=
  iPoseProofCore lem as false true (fun H =>
    lazymatch goal with
    | |- _ ⊢ wp ?E ?e ?Q =>
      reshape_expr e ltac:(fun K e' =>
        wp_bind_core K; iApplyHyp H; try iNext; simpl) ||
      lazymatch iTypeOf H with
      | Some (_,?P) => fail "wp_apply: cannot apply" P
      end
    | _ => fail "wp_apply: not a 'wp'"
    end).

Tactic Notation "wp_alloc" ident(l) "as" constr(H) :=
  iStartProof;
  lazymatch goal with
  | |- _ ⊢ wp ?E ?e ?Q =>
    first
      [reshape_expr e ltac:(fun K e' =>
         match eval hnf in e' with Alloc _ => wp_bind_core K end)
      |fail 1 "wp_alloc: cannot find 'Alloc' in" e];
    eapply tac_wp_alloc with _ H _;
      [let e' := match goal with |- to_val ?e' = _ => e' end in
       wp_done || fail "wp_alloc:" e' "not a value"
      |apply _
      |first [intros l | fail 1 "wp_alloc:" l "not fresh"];
        eexists; split;
          [env_cbv; reflexivity || fail "wp_alloc:" H "not fresh"
          |wp_finish]]
  | _ => fail "wp_alloc: not a 'wp'"
  end.

Tactic Notation "wp_alloc" ident(l) :=
  let H := iFresh in wp_alloc l as H.

Tactic Notation "wp_load" :=
  iStartProof;
  lazymatch goal with
  | |- _ ⊢ wp ?E ?e ?Q =>
    first
      [reshape_expr e ltac:(fun K e' =>
         match eval hnf in e' with Load _ => wp_bind_core K end)
      |fail 1 "wp_load: cannot find 'Load' in" e];
    eapply tac_wp_load;
      [apply _
      |let l := match goal with |- _ = Some (_, (?l ↦{_} _)%I) => l end in
       iAssumptionCore || fail "wp_load: cannot find" l "↦ ?"
      |wp_finish]
  | _ => fail "wp_load: not a 'wp'"
  end.

Tactic Notation "wp_store" :=
  iStartProof;
  lazymatch goal with
  | |- _ ⊢ wp ?E ?e ?Q =>
    first
      [reshape_expr e ltac:(fun K e' =>
         match eval hnf in e' with Store _ _ => wp_bind_core K end)
      |fail 1 "wp_store: cannot find 'Store' in" e];
    eapply tac_wp_store;
      [let e' := match goal with |- to_val ?e' = _ => e' end in
       wp_done || fail "wp_store:" e' "not a value"
      |apply _
      |let l := match goal with |- _ = Some (_, (?l ↦{_} _)%I) => l end in
       iAssumptionCore || fail "wp_store: cannot find" l "↦ ?"
      |env_cbv; reflexivity
      |wp_finish]
  | _ => fail "wp_store: not a 'wp'"
  end.

Tactic Notation "wp_cas_fail" :=
  iStartProof;
  lazymatch goal with
  | |- _ ⊢ wp ?E ?e ?Q =>
    first
      [reshape_expr e ltac:(fun K e' =>
         match eval hnf in e' with CAS _ _ _ => wp_bind_core K end)
      |fail 1 "wp_cas_fail: cannot find 'CAS' in" e];
    eapply tac_wp_cas_fail;
      [let e' := match goal with |- to_val ?e' = _ => e' end in
       wp_done || fail "wp_cas_fail:" e' "not a value"
      |let e' := match goal with |- to_val ?e' = _ => e' end in
       wp_done || fail "wp_cas_fail:" e' "not a value"
      |apply _
      |let l := match goal with |- _ = Some (_, (?l ↦{_} _)%I) => l end in
       iAssumptionCore || fail "wp_cas_fail: cannot find" l "↦ ?"
      |try congruence
      |wp_finish]
  | _ => fail "wp_cas_fail: not a 'wp'"
  end.

Tactic Notation "wp_cas_suc" :=
  iStartProof;
  lazymatch goal with
  | |- _ ⊢ wp ?E ?e ?Q =>
    first
      [reshape_expr e ltac:(fun K e' =>
         match eval hnf in e' with CAS _ _ _ => wp_bind_core K end)
      |fail 1 "wp_cas_suc: cannot find 'CAS' in" e];
    eapply tac_wp_cas_suc;
      [let e' := match goal with |- to_val ?e' = _ => e' end in
       wp_done || fail "wp_cas_suc:" e' "not a value"
      |let e' := match goal with |- to_val ?e' = _ => e' end in
       wp_done || fail "wp_cas_suc:" e' "not a value"
      |apply _
      |let l := match goal with |- _ = Some (_, (?l ↦{_} _)%I) => l end in
       iAssumptionCore || fail "wp_cas_suc: cannot find" l "↦ ?"
      |try congruence
      |env_cbv; reflexivity
      |wp_finish]
  | _ => fail "wp_cas_suc: not a 'wp'"
  end.
