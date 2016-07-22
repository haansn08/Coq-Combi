(******************************************************************************)
(*       Copyright (C) 2014 Florent Hivert <florent.hivert@lri.fr>            *)
(*                                                                            *)
(*  Distributed under the terms of the GNU General Public License (GPL)       *)
(*                                                                            *)
(*    This code is distributed in the hope that it will be useful,            *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of          *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       *)
(*    General Public License for more details.                                *)
(*                                                                            *)
(*  The full text of the GPL is available at:                                 *)
(*                                                                            *)
(*                  http://www.gnu.org/licenses/                              *)
(******************************************************************************)
Require Import mathcomp.ssreflect.ssreflect.
From mathcomp Require Import ssrfun ssrbool eqtype ssrnat seq choice fintype.
From mathcomp Require Import tuple finfun finset bigop ssralg path perm fingroup.
From SsrMultinomials Require Import ssrcomplements poset freeg bigenough mpoly.

Require Import tools ordtype partition Yamanouchi std tableau stdtab.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Local Open Scope ring_scope.
Import GRing.Theory.


Reserved Notation "{ 'sympoly' T [ n ] }"
  (at level 0, T, n at level 2, format "{ 'sympoly'  T [ n ] }").


Section DefType.

Variable n : nat.
Variable R : ringType.

Structure sympoly : predArgType :=
  SymPoly {spol :> {mpoly R[n]}; _ : spol \in symmetric}.

Canonical sympoly_subType := Eval hnf in [subType for spol].
Definition sympoly_eqMixin := Eval hnf in [eqMixin of sympoly by <:].
Canonical sympoly_eqType := Eval hnf in EqType sympoly sympoly_eqMixin.
Definition sympoly_choiceMixin := Eval hnf in [choiceMixin of sympoly by <:].
Canonical sympoly_choiceType :=
  Eval hnf in ChoiceType sympoly sympoly_choiceMixin.

Definition sympoly_of of phant R := sympoly.

Identity Coercion type_sympoly_of : sympoly_of >-> sympoly.

Lemma spol_inj : injective spol. Proof. exact: val_inj. Qed.

End DefType.

(* We need to break off the section here to let the argument scope *)
(* directives take effect.                                         *)
Bind Scope ring_scope with sympoly_of.
Bind Scope ring_scope with sympoly.
Arguments Scope spol [_ ring_scope].
Arguments Scope spol_inj [_ ring_scope ring_scope _].

Notation "{ 'sympoly' T [ n ] }" := (sympoly_of n (Phant T)).


Section SymPolyRingType.

Variable n : nat.
Variable R : ringType.

Definition sympoly_zmodMixin :=
  Eval hnf in [zmodMixin of {sympoly R[n]} by <:].
Canonical sympoly_zmodType :=
  Eval hnf in ZmodType {sympoly R[n]} sympoly_zmodMixin.
Definition sympoly_ringMixin :=
  Eval hnf in [ringMixin of {sympoly R[n]} by <:].
Canonical sympoly_ringType :=
  Eval hnf in RingType {sympoly R[n]} sympoly_ringMixin.
Definition sympoly_lmodMixin :=
  Eval hnf in [lmodMixin of {sympoly R[n]} by <:].
Canonical sympoly_lmodType :=
  Eval hnf in LmodType R {sympoly R[n]} sympoly_lmodMixin.
Definition sympoly_lalgMixin :=
  Eval hnf in [lalgMixin of {sympoly R[n]} by <:].
Canonical sympoly_lalgType :=
  Eval hnf in LalgType R {sympoly R[n]} sympoly_lalgMixin.

Lemma spol_is_additive : additive (fun x : {sympoly R[n]} => spol x).
Proof. by move=> x y. Qed.
Canonical spol_additive := Additive spol_is_additive.

End SymPolyRingType.

Section SymPolyComRingType.

Variable n : nat.
Variable R : comRingType.

Definition sympoly_comRingMixin :=
  Eval hnf in [comRingMixin of {sympoly R[n]} by <:].
Canonical sympoly_comRingType :=
  Eval hnf in ComRingType {sympoly R[n]} sympoly_comRingMixin.
Definition sympoly_algMixin :=
  Eval hnf in [algMixin of {sympoly R[n]} by <:].
Canonical sympoly_algType :=
  Eval hnf in AlgType R {sympoly R[n]} sympoly_algMixin.

End SymPolyComRingType.

Section SymPolyIdomainType.

Variable n : nat.
Variable R : idomainType.

Definition sympoly_unitRingMixin :=
  Eval hnf in [unitRingMixin of {sympoly R[n]} by <:].
Canonical sympoly_unitRingType :=
  Eval hnf in UnitRingType {sympoly R[n]} sympoly_unitRingMixin.
Canonical sympoly_comUnitRingType :=
  Eval hnf in [comUnitRingType of {sympoly R[n]}].
Definition sympoly_idomainMixin :=
  Eval hnf in [idomainMixin of {sympoly R[n]} by <:].
Canonical sympoly_idomainType :=
  Eval hnf in IdomainType {sympoly R[n]} sympoly_idomainMixin.
Canonical sympoly_unitAlgType :=
  Eval hnf in [unitAlgType R of {sympoly R[n]}].

End SymPolyIdomainType.



Section Bases.

Variable n : nat.
Variable R : ringType.


Local Notation "m # s" := [multinom m (s i) | i < n]
  (at level 40, left associativity, format "m # s").


(* From  mpoly.v : \sum_(h : {set 'I_n} | #|h| == k) \prod_(i in h) 'X_i. *)
Fact elementary_sym d : mesym n R d \is symmetric.
Proof using . exact: mesym_sym. Qed.
Definition elementary d : {sympoly R[n]} := SymPoly (elementary_sym d).


Fact complete_sym d :
  (\sum_(m : 'X_{1..n < d.+1} | mdeg m == d)
    'X_[m] : {mpoly R[n]}) \is symmetric.
Proof using .
  apply/issymP => s; rewrite -mpolyP => m.
  rewrite mcoeff_sym !raddf_sum /=.
  case: (altP (mdeg m =P d%N)) => [<- | Hd].
  - have Hsm : mdeg (m#s) < (mdeg m).+1.
      by rewrite mdeg_mperm.
    rewrite (bigD1 (BMultinom Hsm)) /=; last by rewrite mdeg_mperm.
    rewrite mcoeffX eq_refl big1 ?addr0 /=; first last.
      move=> mon /= /andP [] _ /negbTE.
      by rewrite {1}/eq_op /= mcoeffX => ->.
    have Hm : mdeg m < (mdeg m).+1 by [].
    rewrite (bigD1 (BMultinom Hm)) //=.
    rewrite mcoeffX eq_refl big1 ?addr0 //=.
    move=> mon /= /andP [] _ /negbTE.
    by rewrite {1}/eq_op /= mcoeffX => ->.
  - rewrite big1; first last.
      move=> mon /eqP Hd1; rewrite mcoeffX.
      suff /= : val mon != m#s by move/negbTE ->.
      move: Hd; rewrite -{1}Hd1; apply contra=> /eqP ->.
      by rewrite mdeg_mperm.
    rewrite big1 //.
    move=> mon /eqP Hd1; rewrite mcoeffX.
    suff /= : val mon != m by move/negbTE ->.
    by move: Hd; rewrite -{1}Hd1; apply contra=> /eqP ->.
Qed.
Definition complete d : {sympoly R[n]} := SymPoly (complete_sym d).

Fact power_sum_sym d : (\sum_(i < n) 'X_i^+d : {mpoly R[n]}) \is symmetric.
Proof using .
  apply/issymP => s.
  rewrite raddf_sum /= (reindex_inj (h := s^-1))%g /=; last by apply/perm_inj.
  apply eq_bigr => i _; rewrite rmorphX /=; congr (_ ^+ _).
  rewrite msymX /=; congr mpolyX.
  rewrite mnmP => j; rewrite !mnmE /=; congr nat_of_bool.
  apply/eqP/eqP => [|->//].
  exact: perm_inj.
Qed.
Definition power_sum d : {sympoly R[n]} := SymPoly (power_sum_sym d).

Fact monomial_sym (sh : seq nat) :
  (\sum_(m : 'X_{1..n < (sumn sh).+1} |
         sort leq m == sh :> seq nat) 'X_[m] : {mpoly R[n]})
    \is symmetric.
Proof using .
  apply/issymP => s; rewrite raddf_sum /=.
  pose fm := fun m : 'X_{1..n < (sumn sh).+1} => m#s.
  have Hfm m : mdeg (fm m) < (sumn sh).+1 by rewrite /fm mdeg_mperm bmdeg.
  rewrite (reindex_inj (h := fun m => BMultinom (Hfm m))) /=; first last.
    rewrite /fm => m1 m2 /= /(congr1 val) /=.
    rewrite mnmP => Heq; apply val_inj; rewrite mnmP /= => i.
    have:= Heq ((s^-1)%g i).
    by rewrite !mnmE permKV.
  apply congr_big => //.
  - move=> m /=; rewrite [sort _ _](_ : _ = sort leq m) //.
    apply (eq_sorted leq_trans anti_leq); try exact: (sort_sorted leq_total).
    do 2 rewrite perm_eq_sym (perm_sort leq _).
    apply/tuple_perm_eqP; exists s.
    by apply (eq_from_nth (x0 := 0%N)); rewrite size_map.
  - move=> m _.
    rewrite msymX /fm /=; congr mpolyX.
    rewrite mnmP => j; rewrite !mnmE /=.
    by rewrite permKV.
Qed.
Definition monomial sh : {sympoly R[n]} := SymPoly (monomial_sym sh).


Lemma mesym_homog d : mesym n R d \is d.-homog.
Proof using .
  apply/dhomogP => m.
  rewrite msupp_mesymP => /existsP [] s /andP [] /eqP <- {d} /eqP -> {m}.
  exact: mdeg_mesym1.
Qed.

Lemma elementary_homog d : (elementary d : {mpoly R[n]}) \is d.-homog.
Proof using . by rewrite mesym_homog. Qed.

Lemma complete_homog d : (complete d : {mpoly R[n]}) \is d.-homog.
Proof using .
  apply rpred_sum => m /eqP H.
  by rewrite dhomogX /= H.
Qed.

Lemma power_sum_homog d : (power_sum d : {mpoly R[n]}) \is d.-homog.
Proof using .
  apply rpred_sum => m _.
  have /(dhomogMn d) : ('X_m : {mpoly R[n]}) \is 1.-homog.
    by rewrite dhomogX /= mdeg1.
  by rewrite mul1n.
Qed.

Lemma monomial_homog d (sh : intpartn d) :
  (monomial sh  : {mpoly R[n]}) \is d.-homog.
Proof using .
  apply rpred_sum => m /eqP Hm.
  rewrite dhomogX /= -{2}(intpartn_sumn sh) /mdeg.
  have Hperm : perm_eq m sh.
    by rewrite -(perm_sort leq) Hm perm_eq_refl.
  by rewrite (eq_big_perm _ Hperm) /= sumnE.
Qed.


(** Basis at degree 0 *)
Lemma elementary0 : elementary 0 = 1.
Proof using . by apply val_inj; rewrite /= mesym0E. Qed.

Lemma powersum0 : power_sum 0 = n%:R.
Proof using .
  apply /val_inj.
  rewrite /= (eq_bigr (fun _ => 1)); last by move=> i _; rewrite expr0.
  rewrite sumr_const card_ord /=.
  by rewrite [RHS](raddfMn (@spol_additive _ _) n).
Qed.

Lemma complete0 : complete 0 = 1.
Proof using .
  have Hd0 : (mdeg (0%MM : 'X_{1..n})) < 1 by rewrite mdeg0.
  apply val_inj => /=.
  rewrite /complete (big_pred1 (BMultinom Hd0)); first last.
    move=> m /=; by rewrite mdeg_eq0 {2}/eq_op /=.
  by rewrite /= mpolyX0.
Qed.


(** All basis agrees at degree 1 *)
Lemma elementary1 : elementary 1 = \sum_(i < n) 'X_i :> {mpoly R[n]}.
Proof using . by rewrite /= mesym1E. Qed.

Lemma power_sum1 : power_sum 1 = \sum_(i < n) 'X_i :> {mpoly R[n]}.
Proof using . by apply eq_bigr => i _; rewrite expr1. Qed.

Lemma complete1 : complete 1 = \sum_(i < n) 'X_i :> {mpoly R[n]}.
Proof using .
  rewrite /complete -mpolyP => m.
  rewrite !raddf_sum /=.
  case: (boolP (mdeg m == 1%N)) => [/mdeg1P [] i /eqP -> | Hm].
  - have Hdm : (mdeg U_(i))%MM < 2 by rewrite mdeg1.
    rewrite (bigD1 (BMultinom Hdm)) /=; last by rewrite mdeg1.
    rewrite mcoeffX eq_refl big1; first last.
      move=> mm /andP [] _ /negbTE.
      by rewrite mcoeffX {1}/eq_op /= => ->.
    rewrite /= (bigD1 i) // mcoeffX eq_refl /= big1 // => j /negbTE H.
    rewrite mcoeffX.
    case eqP => //; rewrite mnmP => /(_ i).
    by rewrite !mnm1E H eq_refl.
  - rewrite big1; first last.
      move=> p /eqP Hp; rewrite mcoeffX.
      case eqP => // Hpm; subst m.
      by move: Hm; rewrite Hp.
    rewrite big1 // => p _.
    rewrite mcoeffX; case eqP => // Hmm; subst m.
    by rewrite mdeg1 in Hm.
Qed.

End Bases.

Section Schur.

Variable n0 : nat.
Local Notation n := (n0.+1).
Variable R : ringType.

Definition Schur d (sh : intpartn d) : {mpoly R[n]} :=
  \sum_(t : tabsh n0 sh) \prod_(v <- to_word t) 'X_v.

Lemma Schur_tabsh_readingE  d (sh : intpartn d) :
  Schur sh =  \sum_(t : d.-tuple 'I_n | tabsh_reading sh t)
               \prod_(v <- t) 'X_v.
Proof using .
  rewrite /Schur /index_enum -!enumT.
  rewrite -[LHS](big_map (fun t => to_word (val t)) xpredT
                         (fun w => \prod_(v <- w) 'X_v)).
  rewrite -[RHS](big_map val (tabsh_reading sh)
                         (fun w => \prod_(v <- w) 'X_v)).
  rewrite -[RHS]big_filter.
  by rewrite (eq_big_perm _ (to_word_enum_tabsh _ sh)) /=.
Qed.

Lemma Schur0 (sh : intpartn 0) : Schur sh = 1.
Proof using .
  rewrite Schur_tabsh_readingE (eq_bigl (xpred1 [tuple])); first last.
    move=> i /=; by rewrite tuple0 [RHS]eq_refl intpartn0.
  by rewrite big_pred1_eq big_nil.
Qed.


Lemma Schur_oversize d (sh : intpartn d) : size sh > n -> Schur sh = 0.
Proof using .
  rewrite Schur_tabsh_readingE=> Hn; rewrite big_pred0 // => w.
  apply (introF idP) => /tabsh_readingP [] tab [] Htab Hsh _ {w}.
  suff F0 i : i < size sh -> nth (inhabitant _) (nth [::] tab i) 0 >= i.
    have H := ltn_ord (nth (inhabitant _) (nth [::] tab n) 0).
    have:= leq_trans H (F0 _ Hn); by rewrite ltnn.
  rewrite -Hsh size_map; elim: i => [//= | i IHi] Hi.
  have := IHi (ltn_trans (ltnSn i) Hi); move/leq_ltn_trans; apply.
  rewrite -ltnXnatE.
  move: Htab => /is_tableauP [] Hnnil _ Hdom.
  have {Hdom} := Hdom _ _ (ltnSn i) => /dominateP [] _; apply.
  rewrite lt0n; apply/nilP/eqP; exact: Hnnil.
Qed.



Lemma tabwordshape_row d (w : d.-tuple 'I_n) :
  tabsh_reading (rowpartn d) w = sorted leq [seq val i | i <- w].
Proof using .
  rewrite /tabsh_reading /= /rowpart ; case: w => w /=/eqP Hw.
  case: d Hw => [//= | d] Hw; rewrite Hw /=; first by case: w Hw.
  rewrite addn0 eq_refl andbT //=.
  case: w Hw => [//= | w0 w] /= /eqP; rewrite eqSS => /eqP <-.
  rewrite take_size; apply esym; apply (map_path (b := pred0)) => /=.
  - move=> i j /= _ ; exact: leqXnatE.
  - by apply/hasPn => x /=.
Qed.


Lemma perm_eq_enum_basis d :
  perm_eq [seq s2m (val s) | s <- enum (basis n d)]
          [seq val m | m <- enum [set m : 'X_{1..n < d.+1} | mdeg m == d]].
Proof using .
  apply uniq_perm_eq.
  - rewrite map_inj_in_uniq; first exact: enum_uniq.
    move=> i j; rewrite !mem_enum => Hi Hj; exact: inj_s2m.
  - rewrite map_inj_uniq; first exact: enum_uniq.
    exact: val_inj.
  move=> m; apply (sameP idP); apply (iffP idP).
  - move=> /mapP [] mb; rewrite mem_enum inE => /eqP Hmb ->.
    have Ht : size (m2s mb) == d by rewrite -{2}Hmb size_m2s.
    apply/mapP; exists (Tuple Ht) => /=; last by rewrite s2mK.
    rewrite mem_enum inE /=; exact: srt_m2s.
  - move=> /mapP [] s; rewrite mem_enum inE /= => Hsort ->.
    have mdegs : mdeg (s2m s) = d.
      rewrite /s2m /mdeg mnm_valK /= big_map enumT -/(index_enum _).
      by rewrite combclass.sum_count_mem count_predT size_tuple.
    have mdegsP : mdeg (s2m s) < d.+1 by rewrite mdegs.
    apply/mapP; exists (BMultinom mdegsP) => //.
    by rewrite mem_enum inE /= mdegs.
Qed.

(** Equivalent definition of complete symmetric function *)
Lemma complete_basisE d : \sum_(s in (basis n d)) 'X_[s2m s] = Schur (rowpartn d).
Proof using .
  rewrite Schur_tabsh_readingE (eq_bigl _ _ (@tabwordshape_row d)).
  rewrite [RHS](eq_bigr (fun s : d.-tuple 'I_n => 'X_[s2m s])); first last.
    move=> [s _] /= _; rewrite /s2m; elim: s => [| s0 s IHs]/=.
      by rewrite big_nil -/mnm0 mpolyX0.
    rewrite big_cons {}IHs -mpolyXD; congr ('X_[_]).
    rewrite mnmP => i; by rewrite mnmDE !mnmE.
  apply eq_bigl => m;  by rewrite inE /=.
Qed.

End Schur.


Section SchurComRingType.

Variable n0 : nat.
Local Notation n := (n0.+1).
Variable R : comRingType.

Lemma completeE d : complete n R d = Schur _ R (rowpartn d) :> {mpoly R[n]}.
Proof using .
  rewrite /= -complete_basisE.
  rewrite -(big_map (@bmnm n d.+1) (fun m => mdeg m == d) (fun m => 'X_[m])).
  rewrite /index_enum -enumT -big_filter.
  set tmp := filter _ _.
  have {tmp} -> : tmp = [seq val m | m <- enum [set m :  'X_{1..n < d.+1} | mdeg m == d]].
    rewrite {}/tmp /enum_mem filter_map -filter_predI; congr map.
    apply eq_filter => s /=; by rewrite !inE andbT.
  rewrite -(eq_big_perm _ (perm_eq_enum_basis _ d)) /=.
  by rewrite big_map -[RHS]big_filter.
Qed.

Lemma tabwordshape_col d (w : d.-tuple 'I_n) :
    tabsh_reading (colpartn d) w = sorted gtnX w.
Proof using .
  rewrite /tabsh_reading /= /colpart ; case: w => w /=/eqP Hw.
  have -> : sumn (nseq d 1%N) = d.
    elim: d {Hw} => //= d /= ->; by rewrite add1n.
  rewrite Hw eq_refl /= rev_nseq.
  have -> : rev (reshape (nseq d 1%N) w) = [seq [:: i] | i <- rev w].
    rewrite map_rev; congr rev.
    elim: d w Hw => [| d IHd] //=; first by case.
    case => [| w0 w] //= /eqP; rewrite eqSS => /eqP /IHd <-.
    by rewrite take0 drop0.
  rewrite -rev_sorted.
  case: {w} (rev w) {d Hw} => [|w0 w] //=.
  elim: w w0 => [//= | w1 w /= <-] w0 /=.
  by congr andb; rewrite /dominate /= andbT {w}.
Qed.

(** The definition of elementary symmetric polynomials as column Schur
    function agrees with the one from mpoly *)
Lemma elementaryE d : elementary n R d = Schur n0 R (colpartn d) :> {mpoly R[n]}.
Proof using .
  rewrite /= mesym_tupleE /tmono /elementary Schur_tabsh_readingE.
  rewrite (eq_bigl _ _ (@tabwordshape_col d)).
  set f := BIG_F.
  rewrite (eq_bigr (fun x => f(rev_tuple x))); first last.
    rewrite /f => i _ /=; apply: eq_big_perm; exact: perm_eq_rev.
  rewrite (eq_bigl (fun i => sorted gtnX (rev_tuple i))); first last.
    move=> [t /= _]; rewrite rev_sorted.
    case: t => [//= | t0 t] /=.
    apply: (map_path (b := pred0)).
    + move=> x y /= _; by rewrite -ltnXnatE.
    + by apply/hasPn => x /=.
  rewrite /f {f}.
  rewrite [RHS](eq_big_perm
                  (map (@rev_tuple _ _)
                       (enum (tuple_finType d (ordinal_finType n))))) /=.
  rewrite big_map /=; first by rewrite /index_enum /= enumT.
  apply uniq_perm_eq.
  - rewrite /index_enum -enumT; exact: enum_uniq.
  - rewrite map_inj_uniq; first exact: enum_uniq.
    apply (can_inj (g := (@rev_tuple _ _))).
    move=> t; apply val_inj => /=; by rewrite revK.
  - rewrite /index_enum -enumT /= => t.
    rewrite mem_enum /= inE; apply esym; apply/mapP.
    exists (rev_tuple t) => /=.
    + by rewrite mem_enum.
    + apply val_inj; by rewrite /= revK.
Qed.


Lemma Schur1 (sh : intpartn 1) : Schur n0 R sh = \sum_(i<n) 'X_i.
Proof using .
  suff -> : sh = rowpartn 1 by rewrite -completeE complete1.
  apply val_inj => /=; exact: intpartn1.
Qed.

End SchurComRingType.
