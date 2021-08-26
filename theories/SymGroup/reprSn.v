(** * Combi.SymGroup.reprSn : Basic representations of the Symmetric Groups *)
(******************************************************************************)
(*      Copyright (C) 2016-2021 Florent Hivert <florent.hivert@lri.fr>        *)
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
(** * Basic representation of the Symmetric Groups

We define the two representations of dimension 1 together with the natural
representation, and show that ['S_2] has only 2 representations. More precisely,
for a fixed [n] and  [g : 'S_n]:

- [triv_mx g] == the 1x1 identity matrix.
- [sign_mx g] == the 1x1 scalar matrix equal to the sign of [g].
- [signed_mx R g] == given a representation [R] the matrix [sign g * R g]
- [nat_mx g] == the permutation matrix associated to [g]

These four matrices are actually representation matrices:

- [triv_repr] == the trivial representation
- [sign_repr] == the sign representation
- [signed_repr R] == the representation [R] times the sign
- [nat_repr n] == the natural representation of degree [n]

We show in Lemmas [repr1] and [repr_S2] that [triv_repr] and [sign_repr]
exhausts all representations of ['S_n] of degree 1 and all irreducible
representations of of ['S_2].
*************)
Require Import mathcomp.ssreflect.ssreflect.
From mathcomp Require Import ssreflect ssrfun ssrbool eqtype ssrnat seq.
From mathcomp Require Import fintype tuple finfun bigop finset fingroup perm.
From mathcomp Require Import ssralg fingroup morphism perm action.
From mathcomp Require Import zmodp. (* Defines the coercion nat -> 'I_n.+1 *)
From mathcomp Require Import vector matrix mxalgebra ssrnum algC.
From mathcomp Require Import mxrepresentation classfun character.

Require Import permcomp tools sorted partition congr cycles cycletype presentSn.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GroupScope GRing.Theory Num.Theory.
Local Open Scope ring_scope.

Local Notation reprS n d :=
  (mx_representation [fieldType of algC] 'SG_n d).


Section TcastVal.
Variable (T : eqType).

Lemma tval_tcastE m n (eq_mn : m = n) (t : m.-tuple T) :
  tcast eq_mn t = t :> seq T.
Proof. by case: n / eq_mn. Qed.

End TcastVal.

Lemma NirrSn n : Nirr 'SG_n = #|{:'P_n}|.
Proof using. by rewrite NirrE card_classes_perm card_ord. Qed.

(** * Representation of dimension 1 and natural representation *)
Section DefTrivSign.

Variables n d : nat.

Definition triv_mx (g : 'S_n) : 'M[algC]_1 := 1.
Definition sign_mx (g : 'S_n) : 'M[algC]_1 := (-1) ^+ (odd_perm g).
Definition signed_mx (rho : reprS n d) (g : 'S_n) : 'M[algC]_d :=
  (-1) ^+ (odd_perm g) *: rho g.

Definition nat_mx (g : 'S_n) : 'M[algC]_n := perm_mx g.


Lemma triv_mx_repr : mx_repr 'SG_n triv_mx.
Proof. by split => [//|g1 g2 _ _]; rewrite mul1mx. Qed.
Canonical triv_repr : reprS n 1 := MxRepresentation triv_mx_repr.

Lemma triv_irr : mx_irreducible triv_repr.
Proof. by apply: mx_abs_irrW; exact: linear_mx_abs_irr. Qed.

Lemma sign_mx_repr : mx_repr 'SG_n sign_mx.
Proof.
rewrite /sign_mx; split; first by rewrite /= odd_perm1.
by move=> g1 g2 _ _; rewrite odd_permM signr_addb.
Qed.
Canonical sign_repr : reprS n 1 := MxRepresentation sign_mx_repr.

Lemma sign_irr : mx_irreducible sign_repr.
Proof. apply: mx_abs_irrW; exact: linear_mx_abs_irr. Qed.

Lemma signed_mx_repr rho : mx_repr 'SG_n (signed_mx rho).
Proof.
rewrite /signed_mx; split; first by rewrite /= odd_perm1 repr_mx1 expr0 scale1r.
move=> g1 g2 _ _; rewrite odd_permM.
by rewrite -scalemxAl -scalemxAr scalerA signr_addb repr_mxM ?inE.
Qed.
Canonical signed_repr rho : reprS n d := MxRepresentation (signed_mx_repr rho).

Lemma nat_mx_repr : mx_repr 'SG_n nat_mx.
Proof. by split=> [|g1 g2 _ _]; [exact: perm_mx1 | exact: perm_mxM]. Qed.
Canonical nat_repr : reprS n n := MxRepresentation nat_mx_repr.

Lemma cfRepr_trivE : cfRepr triv_repr = 1.
Proof using.
rewrite -cfunP => s.
by rewrite cfunE cfun1E !inE mulr1n mxtrace1.
Qed.

Lemma cfRepr_triv : cfRepr triv_repr = 'chi_0.
Proof using. by rewrite irr0 cfRepr_trivE. Qed.
Lemma triv_Chi : mx_rsim triv_repr 'Chi_0.
Proof using. by apply/cfRepr_rsimP; rewrite cfRepr_triv irrRepr. Qed.

Lemma sign_char_subproof :
  is_class_fun <<'SG_n>> [ffun g => (-1) ^+ (odd_perm g)].
Proof.
rewrite genGid.
by apply: intro_class_fun => /= [s t | s]; rewrite ?odd_permJ ?inE.
Qed.
Definition sign_char := Cfun 0 sign_char_subproof.

Lemma cfRepr_sign : cfRepr sign_repr = sign_char.
Proof.
apply cfunP => /= s; rewrite /= !cfunE inE /= !mulr1n.
rewrite /trmx trace_mx11 /sign_mx.
by case: (odd_perm s) => /=; rewrite ?expr1 ?expr0 !mxE eqxx.
Qed.
Lemma sign_charP : sign_char \is a linear_char.
Proof. by rewrite qualifE -{1}cfRepr_sign cfRepr_char /= cfunE odd_perm1. Qed.

Lemma cfRepr_signed (rho : reprS n d) :
  cfRepr (signed_repr rho) = sign_char * cfRepr rho.
Proof.
apply cfunP => /= s; rewrite /= !cfunE inE /= !mulr1n.
by rewrite /signed_mx mxtraceZ.
Qed.

End DefTrivSign.

Arguments triv_mx_repr {n}.
Arguments triv_repr {n}.
Arguments sign_mx_repr {n}.
Arguments sign_repr {n}.
Arguments sign_char {n}.


(** * Representations of the symmetric Group for n = 0 and 1  *)

Lemma row_free1 : row_free (1 : 'M[algC]_1).
Proof. by apply/row_freeP; exists 1; rewrite mul1mx. Qed.

Lemma repr1_S0 (rho : reprS 0 1) : mx_rsim rho triv_repr.
Proof.
apply: (MxReprSim (B := 1)) => //; first exact: row_free1.
rewrite /triv_mx_repr /= => g _ /=.
by rewrite mul1mx mulmx1 (permS0 g) repr_mx1.
Qed.

Lemma repr1_S1 (rho : reprS 1 1) : mx_rsim rho triv_repr.
Proof.
apply: (MxReprSim (B := 1)) => //; first exact: row_free1.
rewrite /triv_mx_repr /= => g _ /=.
by rewrite mul1mx mulmx1 (permS1 g) repr_mx1.
Qed.

Lemma charSG0 X : X \in irr 'SG_0 -> X = 1.
Proof.
move/irrP => [[i Hi] ->{X}].
apply/eqP; rewrite irr_eq1 -val_eqE /=.
by move: Hi; rewrite NirrSn card_intpartn -[intpartn_nb 0%N]/1%N ltnS leqn0.
Qed.

Lemma charSG1 X : X \in irr 'SG_1 -> X = 1.
Proof.
move/irrP => [[i Hi] ->{X}].
apply/eqP; rewrite irr_eq1 -val_eqE /=.
by move: Hi; rewrite NirrSn card_intpartn -[intpartn_nb 1%N]/1%N ltnS leqn0.
Qed.


(** * Representations of dimension 1 the symmetric Group for n > 1*)

Lemma triv_sign_not_sim n :
  (n > 1)%N -> ~ mx_rsim (G := [group of 'SG_n]) triv_repr sign_repr.
Proof.
case: n => // n; rewrite ltnS => Hn [B _].
rewrite row_free_unit => /mulrI HB Hsim.
have {}/Hsim : 's_0 \in 'SG_n.+1 by [].
rewrite /triv_repr /sign_repr /triv_mx /sign_mx /= mul1mx (odd_eltr Hn).
rewrite -[LHS]mulmx1 => /HB/eqP; rewrite -addr_eq0 -mulr2n => /eqP.
apply/matrixP => /(_ ord0 ord0).
rewrite !mxE eq_refl /= => /eqP.
by have := Cchar; rewrite charf0P => /(_ 2) ->.
Qed.

Lemma repr1 n (rho : reprS n 1) :
  mx_rsim rho triv_repr \/ mx_rsim rho sign_repr.
Proof.
case: n rho => [| n] rho; first by left; exact: repr1_S0.
have Hs0 : 's_0 \in 'SG_n.+1 by [].
have /esym := repr_mxMr rho Hs0 Hs0.
set M := rho 's_0.
rewrite eltr2 repr_mx1 (mx11_scalar M).
rewrite -mulmxE -scalar_mxM -matrixP => /(_ ord0 ord0) /eqP.
rewrite !mxE eq_refl mulr1n /= -expr2 sqrf_eq1 => /orP [] /eqP HM.
- left; apply: (MxReprSim (B := 1)) => //; first exact: row_free1.
  rewrite /triv_mx_repr /= => g _; rewrite mul1mx mulmx1.
  have Heltr i : (i < n)%N -> rho 's_i = 1.
    elim: i => [| i IHi] Hi; first by rewrite -/M (mx11_scalar M) HM.
    have /(congr1 rho) := eltr_braid Hi.
    rewrite !repr_mxMr ?inE //= IHi; last exact: ltnW.
    rewrite !mulr1.
    have: 's_i.+1 \in 'SG_n.+1 by [].
    by move=> /(repr_mx_unit rho)/mulIr H{}/H <-.
  rewrite -(canwordP g); elim: (canword g) => [| w0 w IHw] /=.
    by rewrite big_nil repr_mx1.
  rewrite big_cons repr_mxM ?inE // IHw mulmx1.
  exact: Heltr.
- right; apply: (MxReprSim (B := 1)) => //; first exact: row_free1.
  rewrite /sign_mx_repr /= => g _; rewrite mul1mx mulmx1 /sign_mx.
  have Heltr i : (i < n)%N -> rho 's_i = -1.
    elim: i => [| i IHi] Hi.
      by rewrite -/M (mx11_scalar M) HM -[RHS]scaleN1r -scalemx1.
    have /(congr1 rho) := eltr_braid Hi.
    rewrite !repr_mxMr ?inE //= IHi; last exact: ltnW.
    rewrite !mulrN1 mulNr => /eqP; rewrite eqr_opp => /eqP.
    have: 's_i.+1 \in 'SG_n.+1 by [].
    by move=> /(repr_mx_unit rho)/mulIr H{}/H <-.
  rewrite -(canwordP g); elim: (canword g) => [| w0 w IHw] /=.
    by rewrite big_nil repr_mx1 odd_perm1.
  rewrite big_cons repr_mxM ?inE // {}IHw odd_permM odd_eltr //= Heltr //.
  case: (odd_perm (\prod_(i <- w) 's_i)); rewrite /= mulmxE mulN1r //.
  exact: opprK.
Qed.


(** * Representations of the symmetric Group for n=2  *)

Lemma NirrS2 : Nirr 'SG_2 = 2.
Proof using. by rewrite NirrSn card_intpartn. Qed.

Lemma cast_IirrS2 (i : Iirr 'SG_2) :
  i != 0 -> i = cast_ord (esym NirrS2) 1.
Proof using.
move=> Hi; apply val_inj => /=.
by case: i Hi => [[|[|i]]] //=; rewrite NirrS2.
Qed.

Lemma cfRepr_sign2 : cfRepr sign_repr = 'chi_(cast_ord (esym NirrS2) 1).
Proof using.
have : cfRepr sign_repr \in irr 'SG_2.
  by apply/irr_reprP; exists (Representation sign_repr); first exact: sign_irr.
move=> /irrP [j]; rewrite -!irrRepr => /eqP/cfRepr_rsimP/mx_rsim_sym Hj.
apply/eqP/cfRepr_rsimP.
apply (mx_rsim_trans (mx_rsim_sym Hj)).
rewrite (cast_IirrS2 (i := j)); first exact: mx_rsim_refl.
apply/eqP => Hj0; subst j.
apply: (triv_sign_not_sim (n := 2)) => //.
exact: mx_rsim_trans (triv_Chi 2) Hj.
Qed.

Lemma sign_Chi2 : mx_rsim sign_repr 'Chi_(cast_ord (esym NirrS2) 1).
Proof using. by apply/cfRepr_rsimP; rewrite cfRepr_sign2 irrRepr. Qed.

Lemma char_S2 :
  irr 'SG_2 = tcast (esym NirrS2) [tuple cfRepr triv_repr; cfRepr sign_repr].
Proof using.
apply eq_from_tnth => i.
case: (altP (i =P 0)) => [-> | Hi].
- by rewrite tcastE {2}/tnth /= cfRepr_triv; congr 'chi_(_); exact: val_inj.
- by rewrite tcastE {2}/tnth /= cfRepr_sign2 (cast_IirrS2 Hi) /=.
Qed.

Lemma repr_S2 (rho : representation [fieldType of algC] [group of 'SG_2]) :
  mx_irreducible rho -> mx_rsim rho triv_repr \/ mx_rsim rho sign_repr.
Proof using.
move=> Hirr.
have : cfRepr rho \in irr 'SG_2 by apply/irr_reprP; exists rho.
by rewrite char_S2 memtE tval_tcastE !inE =>
  /orP[]/cfRepr_rsimP; [left | right].
Qed.
