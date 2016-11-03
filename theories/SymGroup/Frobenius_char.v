(** * Combi.SymGroup.Frobenius_char : Frobenius characteristic *)
(******************************************************************************)
(*       Copyright (C) 2016 Florent Hivert <florent.hivert@lri.fr>            *)
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
(** * Frobenius characteristic associated to a class function of ['SG_n].

- [Fchar f] == the Frobenius characteristic of the class function [f].
               the number of variable is inferred from the context.
 *)
Require Import mathcomp.ssreflect.ssreflect.
From mathcomp Require Import ssreflect ssrfun ssrbool eqtype ssrnat seq path.
From mathcomp Require Import finfun fintype tuple finset bigop.
From mathcomp Require Import ssralg fingroup morphism perm gproduct.
From mathcomp Require Import rat ssralg ssrnum algC vector.
From mathcomp Require Import classfun character.

From SsrMultinomials Require Import mpoly.
Require Import ordtype tools partition sympoly homogsym Cauchy Schur_altdef.
Require Import permcomp cycletype towerSn permcent.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import LeqGeqOrder.
Import GroupScope GRing.Theory.
Open Scope ring_scope.

Lemma rem_irr1 n (xi phi : 'CF('SG_n)) :
  xi \in irr 'SG_n -> phi \is a character -> '[phi, xi] != 0 ->
       phi - xi \is a character.
Proof.
move=> /irrP [i ->{xi}] Hphi.
rewrite -irr_consttE => /(constt_charP i Hphi) [psi Hpsi ->{phi Hphi}].
by rewrite [_ + psi]addrC addrK.
Qed.

Lemma rem_irr n (xi phi : 'CF('SG_n)) :
  xi \in irr 'SG_n -> phi \is a character -> phi - '[phi, xi] *: xi \is a character.
Proof.
move=> Hxi Hphi.
have /CnatP [m Hm] := Cnat_cfdot_char Hphi (irrWchar Hxi).
rewrite Hm.
elim: m phi Hphi Hm => [|m IHm] phi Hphi Hm; first by rewrite scale0r subr0.
rewrite mulrS scalerDl scale1r opprD addrA.
apply IHm; first last.
  by rewrite cfdotBl Hm irrWnorm // mulrS [1 + _]addrC addrK.
by apply rem_irr1; rewrite //= Hm Num.Theory.pnatr_eq0.
Qed.

Local Notation algCF := [numFieldType of algC].

Section NVar.

Variable nvar0 : nat.
Local Notation "''z_' p" := (zcoeff p) (at level 2, format "''z_' p").
Local Notation "''1z_[' p ]" := (ncfuniCT p)  (format "''1z_[' p ]").
Local Notation nvar := nvar0.+1.

Section Defs.

Variable n : nat.
Local Notation HS := {homsym algC[nvar, n]}.

Definition Fchar (f : 'CF('SG_n)) : HS :=
  locked (\sum_(la : intpartn n) (f (permCT la) / 'z_la) *: 'hp[la]).

Definition Fchar_inv (p : HS) : 'CF('SG_n) :=
  \sum_(la : intpartn n) (coord 'hp (enum_rank la) p) *: '1z_[la].

Lemma FcharE (f : 'CF('SG_n)) :
  Fchar f = \sum_(la : intpartn n) (f (permCT la) / 'z_la) *: 'hp[la].
Proof. by rewrite /Fchar; unlock. Qed.

Lemma Fchar_is_linear : linear Fchar.
Proof using.
move=> a f g; rewrite !FcharE scaler_sumr -big_split /=.
apply eq_bigr => l _; rewrite !cfunElock.
by rewrite scalerA mulrA -scalerDl mulrDl.
Qed.
Canonical Fchar_linear := Linear Fchar_is_linear.

Lemma Fchar_ncfuniCT (l : intpartn n) : Fchar '1z_[l] = 'hp[l].
Proof using.
rewrite !FcharE (bigD1 l) //= big1 ?addr0; first last.
  move=> m /negbTE Hm /=.
  rewrite cfunElock cfuniCTE /=.
  rewrite /cycle_typeSn permCTP.
  rewrite partnCTE /= !CTpartnK Hm /=.
  by rewrite mulr0 mul0r scale0r.
rewrite cfunElock cfuniCTE /=.
rewrite /cycle_typeSn permCTP eq_refl /=.
by rewrite mulr1 divff ?scale1r.
Qed.

Lemma Fchar_inv_is_linear : linear Fchar_inv.
Proof using.
move=> a f g; rewrite /Fchar_inv scaler_sumr -big_split /=.
apply eq_bigr => la _.
move: ('1z_[la]) => U.
by rewrite !linearD !linearZ /= scalerDl scalerA mulrC.
Qed.
Canonical Fchar_inv_linear := Linear Fchar_inv_is_linear.

Hypothesis Hn : (n <= nvar)%N.

Lemma FcharK : cancel Fchar Fchar_inv.
Proof using Hn.
move=> f.
rewrite /Fchar_inv {2}(ncfuniCT_gen f); apply eq_bigr => la _.
rewrite FcharE; congr (_ *: _).
rewrite !(reindex (enum_val (A := {:intpartn n}))) /=; first last.
  by apply (enum_val_bij_in (x0 := (rowpartn n))).
transitivity
  (coord 'hp (enum_rank la)
         (\sum_(j < #|{:intpartn n}|)
           (f (permCT (enum_val j)) / 'z_(enum_val j)) *:
           ('hp`_j : {homsym algC[nvar , n]}))).
  congr coord; apply eq_bigr => /= i _; congr (_ *: _).
  rewrite (nth_map (rowpartn n)); last by rewrite -cardE ltn_ord.
  by congr ('hp[_]); apply enum_val_nth.
rewrite coord_sum_free; last exact: (basis_free (symbp_basis _ Hn)).
by rewrite enum_rankK.
Qed.

Lemma Fchar_invK : cancel Fchar_inv Fchar.
Proof using Hn.
move=> p.
rewrite /Fchar_inv linear_sum.
have: p \in span 'hp by rewrite (span_basis (symbp_basis _ Hn)) memvf.
move=> /coord_span => {2}->.
rewrite (reindex enum_rank) /=; last by apply onW_bij; apply enum_rank_bij.
apply eq_bigr => i _.
rewrite linearZ /= Fchar_ncfuniCT; congr (_ *: _).
rewrite (nth_map (rowpartn n)); last by rewrite -cardE ltn_ord.
by congr ('hp[_]); rewrite -enum_val_nth enum_rankK.
Qed.

Lemma Fchar_triv : Fchar 1 = 'hh[rowpartn n].
Proof.
rewrite -decomp_cf_triv linear_sum.
rewrite (eq_bigr (fun la => 'z_la^-1 *: 'hp[la])); first last.
  move=> la _.
  rewrite -Fchar_ncfuniCT /ncfuniCT /= linearZ /=.
  by rewrite scalerA /= mulrC divff // scale1r.
apply val_inj; case: n => [|n0]/=.
  rewrite /= prod_gen0.
  rewrite (big_pred1 (rowpartn 0)); first last.
    by move=> la /=; symmetry; apply/eqP/val_inj; rewrite /= intpartn0.
  rewrite linearZ /= prod_gen0.
  rewrite zcoeffE /zcard big_nil mul1n /=.
  rewrite (big_pred1 ord0); first last.
    move=> i /=; symmetry; apply/eqP/val_inj/eqP.
    by rewrite /= -leqn0 -ltnS ltn_ord.
  by rewrite fact0 invr1 scale1r.
rewrite /prod_gen big_seq1 raddf_sum symh_to_symp /=.
by apply eq_bigr => l _; rewrite zcoeffE.
Qed.

Lemma Fchar_isometry (f g : 'CF('SG_n)) : '[Fchar f | Fchar g] = '[f, g].
Proof using Hn.
rewrite (ncfuniCT_gen f) (ncfuniCT_gen g) !linear_sum /=.
rewrite homsymdot_suml cfdot_suml; apply eq_bigr => la _.
rewrite homsymdot_sumr cfdot_sumr; apply eq_bigr => mu _.
rewrite ![Fchar (_ *: '1z_[_])]linearZ /= !Fchar_ncfuniCT.
rewrite homsymdotZl homsymdotZr cfdotZl cfdotZr; congr (_ * (_ * _)).
rewrite homsymdotp // cfdotZl cfdotZr cfdot_classfun_part.
case: (altP (la =P mu)) => [<-{mu} | _]; rewrite ?mulr0 ?mulr1 //.
rewrite -zcoeffE -[LHS]mulr1; congr (_ * _).
rewrite /zcoeff rmorphM rmorphV; first last.
  by rewrite unitfE Num.Theory.pnatr_eq0 card_classCT_neq0.
rewrite !conjC_nat -mulrA [X in _ * X]mulrC - mulrA divff; first last.
  by rewrite Num.Theory.pnatr_eq0 card_classCT_neq0.
by rewrite mulr1 divff // Num.Theory.pnatr_eq0 -lt0n cardsT card_Sn fact_gt0.
Qed.

End Defs.

(**
This cannot be written as a SSReflect [{morph Fchar : f g / ...  >-> ... }]
because the dependency of Fchar on the degree [n]. The three [Fchar] below are
actually three different functions.

Note: this can be solved using a dependant record [{n; 'CF('S_n)}] with a
dependent equality but I'm not sure this is really needed.

*)


Theorem Fchar_ind_morph m n (f : 'CF('SG_m)) (g : 'CF('SG_n)) :
  Fchar ('Ind['SG_(m + n)] (f \o^ g)) = Fchar f *h Fchar g.
Proof using.
rewrite (ncfuniCT_gen f) (ncfuniCT_gen g) !linear_sum; apply eq_bigr => /= l _.
rewrite cfextprod_suml homsymprod_suml !linear_sum; apply eq_bigr => /= k _.
do 2 rewrite [in RHS]linearZ /= Fchar_ncfuniCT.
rewrite cfextprodZr cfextprodZl homsymprodZr homsymprodZl !scalerA.
rewrite 2!linearZ /= Ind_ncfuniCT linearZ /= Fchar_ncfuniCT /=; congr (_ *: _).
by apply val_inj => /=; rewrite prod_genM.
Qed.

Section Character.

Import LeqGeqOrder.

Lemma homsymh_character d (la : intpartn d) :
  (d <= nvar)%N -> Fchar_inv 'hh[la] \is a character.
Proof.
case: la => [la /= Hla]; have:= Hla => /andP [/eqP Hd _]; subst d.
elim: la Hla => [| l0 la IHla] Hlla Hd.
  have -> : 'hh[(IntPartN Hlla)] = Fchar 1.
    by rewrite Fchar_triv; congr 'hh[_]; apply val_inj.
  by rewrite FcharK // cfun1_char.
have Hla : (sumn la == sumn la) && is_part la.
  by rewrite eq_refl /=; have:= Hlla => /andP [_ /is_part_consK ->].
have Hdla : (sumn la <= nvar)%N by apply: (leq_trans _ Hd); rewrite /= leq_addl.
have {IHla }Hrec := IHla Hla Hdla.
have -> : 'hh[(IntPartN Hlla)] = 'hh[rowpartn l0] *h 'hh[(IntPartN Hla)]
           :> {homsym algC[nvar, sumn (l0 :: la)]}.
  apply val_inj; rewrite /= prod_genM; congr prod_gen.
  apply val_inj; rewrite union_intpartnE /= /rowpart.
  move: Hlla => /andP [_] Hpart.
  have:= part_head_non0 Hpart => /=.
  move: Hpart; rewrite is_part_sortedE => /andP [Hsort _].
  case: l0 Hsort {Hd} => // l0 Hsort _.
  apply (eq_sorted (leT := geq)) => //; first exact: sort_sorted.
  by rewrite perm_eq_sym perm_sort /=.
rewrite -Fchar_triv -(Fchar_invK Hdla 'hh[(IntPartN Hla)]).
rewrite -Fchar_ind_morph (FcharK Hd).
apply cfInd_char; rewrite cfIsom_char.
exact: (cfextprod_char (cfun1_char _) Hrec).
Qed.


Import IntPartNDom.

Lemma homsyms_irr (d : nat) (la : intpartndom d) :
  (d <= nvar)%N -> Fchar_inv 'hs[la] \in irr 'SG_d.
Proof.
move=> Hd.
elim/finord_wf_down : la => /= la IHla.
rewrite irrEchar.
rewrite -Fchar_isometry // Fchar_invK // homsymdotss // !eq_refl andbT.
have -> : 'hs[la] =
         'hh[la] - \sum_(mu : intpartndom d | (la < mu)%Ord)
                   '[ Fchar_inv 'hh[la], Fchar_inv 'hs[mu] ] *: 'hs[mu]
                   :> {homsym algC[nvar, d]}.
  apply/eqP; rewrite eq_sym subr_eq.
  apply/eqP/val_inj; rewrite -[val 'hh[la]]/('h[la]).
  rewrite symh_syms_partdom /=; congr (_ + _).
  rewrite linear_sum /=; apply eq_bigr => mu Hmu.
  congr (_ *: _).
  rewrite -Fchar_isometry // !Fchar_invK //.
  have -> : 'hh[la] = \sum_(nu : intpartn d) 'K(nu, la) *: 'hs[nu]
                   :> {homsym algC[nvar, d]}.
    apply val_inj; rewrite -[val 'hh[la]]/('h[la]).
    by rewrite symh_syms /= linear_sum.
  rewrite homsymdot_suml (bigD1 mu) //= homsymdotZl homsymdotss // eq_refl mulr1.
  rewrite big1 ?addr0 // => nu /negbTE Hnu.
  by rewrite homsymdotZl homsymdotss // Hnu mulr0.
rewrite -big_filter /index_enum -enumT.
set L := filter _ _.
have : all (fun y => (la < y)%Ord) L by apply filter_all.
have : uniq L by apply filter_uniq; apply enum_uniq.
elim: L => [| l0 l IHl].
  by rewrite big_nil subr0 homsymh_character.
rewrite big_cons /= => /andP [Hl0l Huniq] /andP [Hl0 Hall].
rewrite [X in 'hh[la] - X]addrC opprD addrA.
have {IHl Huniq Hall}  := IHl Huniq Hall.
set Frec := 'hh[la] - _ => HFrec.
suff -> : '[Fchar_inv 'hh[la], Fchar_inv 'hs[l0]] =
          '[Fchar_inv Frec, Fchar_inv 'hs[l0]].
  rewrite linearB linearZ /=.
  apply rem_irr => //.
  exact: IHla.
rewrite {HFrec}/Frec.
rewrite linearB /= cfdotBl.
rewrite linear_sum /= [X in _ - X]cfdot_suml.
rewrite big_seq big1 ?subr0 // => mu Hmu.
rewrite linearZ cfdotZl /=.
rewrite -!Fchar_isometry // !Fchar_invK //.
rewrite homsymdotss //.
suff /negbTE -> : mu != l0 by rewrite mulr0.
by move: Hl0l; apply contra => /eqP <-.
Qed.

Definition irrChs d := [seq Fchar_inv f | f <- 'hs : seq {homsym algC[nvar, d]}].

Theorem irrChsP d : (d <= nvar)%N -> perm_eq (irrChs d) (irr 'SG_d).
Proof.
move=> Hd.
have HirrChs : uniq (irrChs d).
  rewrite map_inj_uniq.
  + exact: free_uniq (basis_free (symbs_basis algCF Hd)).
  + exact: can_inj (Fchar_invK Hd).
apply uniq_perm_eq.
- exact: HirrChs.
- exact: (free_uniq (basis_free (irr_basis _))).
have /(leq_size_perm HirrChs) Htmp : {subset irrChs d <= irr 'SG_d}.
  move=> /= f /mapP [/= p /mapP [/= la _ ->{p}] -> {f}].
  exact: homsyms_irr.
suff /Htmp [] : (size (irr 'SG_d) <= size (irrChs d))%N by [].
rewrite size_tuple -(vector.size_basis (irr_basis _)) dim_cfun.
rewrite card_classes_perm /=.
by rewrite size_tuple card_ord.
Qed.

End Character.

End NVar.

Arguments Fchar [nvar0 n] f.
Arguments Fchar_inv [nvar0 n] p.
