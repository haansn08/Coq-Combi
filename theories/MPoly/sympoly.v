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
Require Import ssreflect ssrfun ssrbool eqtype ssrnat seq fintype.
Require Import tuple finfun finset bigop ssralg path.
Require Import ssrcomplements poset freeg bigenough mpoly.

Require Import tools ordtype partition Yamanouchi std tableau stdtab.
Require Import Schensted Greene_inv.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Local Open Scope ring_scope.
Import GRing.Theory.

Section TableauReading.

Variable A : ordType.

Definition tabsh_reading (sh : seq nat) (w : seq A) :=
  (size w == sumn sh) && (is_tableau (rev (reshape (rev sh) w))).
Definition tabsh_reading_RS (sh : seq nat) (w : seq A) :=
  (to_word (RS w) == w) && (shape (RS (w)) == sh).

Lemma tabsh_readingP (sh : seq nat) (w : seq A) :
  reflect
    (exists tab, [/\ is_tableau tab, shape tab = sh & to_word tab = w])
    (tabsh_reading sh w).
Proof.
  apply (iffP idP).
  - move=> /andP [] /eqP Hsz Htab.
    exists (rev (reshape (rev sh) w)); split => //.
    rewrite shape_rev -{2}(revK sh); congr (rev _).
    apply: reshapeKl; by rewrite sumn_rev Hsz.
    rewrite /to_word revK; apply: reshapeKr; by rewrite sumn_rev Hsz.
  - move=> [] tab [] Htab Hsh Hw; apply/andP; split.
    + by rewrite -Hw size_to_word /size_tab Hsh.
    + rewrite -Hw /to_word -Hsh.
      by rewrite /shape -map_rev -/(shape _) flattenK revK.
Qed.

Lemma tabsh_reading_RSP (sh : seq nat) (w : seq A) :
  reflect
    (exists tab, [/\ is_tableau tab, shape tab = sh & to_word tab = w])
    (tabsh_reading_RS sh w).
Proof.
  apply (iffP idP).
  - move=> /andP [] /eqP HRS /eqP Hsh.
    exists (RS w); split => //; exact: is_tableau_RS.
  - move=> [] tab [] Htab Hsh Hw; apply/andP.
    have:= RS_tabE Htab; rewrite Hw => ->.
    by rewrite Hw Hsh.
Qed.

Lemma tabsh_reading_RSE sh :
  tabsh_reading sh =1 tabsh_reading_RS sh.
Proof.
  move=> w.
  apply/idP/idP.
  - by move /tabsh_readingP/tabsh_reading_RSP.
  - by move /tabsh_reading_RSP/tabsh_readingP.
Qed.

End TableauReading.


Section Bases.

Variable n : nat.
Hypothesis Hnpos : n != 0%N.
Canonical Alph := Eval hnf in OrdType 'I_n (ord_ordMixin Hnpos).

Variable R : comRingType.


(* From  mpoly.v : \sum_(h : {set 'I_n} | #|h| == k) \prod_(i in h) 'X_i. *)
Definition elementary (k : nat) : {mpoly R[n]} := mesym n R k.
Definition complete (d : nat) : {mpoly R[n]} :=
  \sum_(m : 'X_{1..n < d.+1} | mdeg m == d) 'X_[m].
Definition power_sum (d : nat) : {mpoly R[n]} :=
  \sum_(i < n) 'X_i^+d.
Definition Schur d (sh : intpartn d) : {mpoly R[n]} :=
  \sum_(t : d.-tuple 'I_n | tabsh_reading sh t)
   \prod_(v <- t) 'X_v.

Lemma elementary_mesymE d : elementary d = mesym n R d.
Proof. by []. Qed.

(* TODO:  All agrees at degree 1 *)

Lemma Schur0 (sh : intpartn 0) : Schur sh = 1.
Proof.
  rewrite /Schur (eq_bigl (xpred1 [tuple])); first last.
    move=> i /=; by rewrite tuple0 [RHS]eq_refl intpartn0.
  by rewrite big_pred1_eq big_nil.
Qed.

Lemma Schur_oversize d (sh : intpartn d) : size sh > n -> Schur sh = 0.
Proof.
  rewrite /Schur=> Hn; rewrite big_pred0 // => w.
  apply (introF idP) => /tabsh_readingP [] tab [] Htab Hsh _ {w}.
  suff F0 i : i < size sh -> nth (inhabitant Alph) (nth [::] tab i) 0 >= i.
    have H := ltn_ord (nth (inhabitant Alph) (nth [::] tab n) 0).
    have:= leq_trans H (F0 _ Hn); by rewrite ltnn.
  rewrite -Hsh size_map; elim: i => [//= | i IHi] Hi.
  have := IHi (ltn_trans (ltnSn i) Hi); move/leq_ltn_trans; apply.
  rewrite -ltnXnatE.
  move: Htab => /is_tableauP [] Hnnil _ Hdom.
  have {Hdom} := Hdom _ _ (ltnSn i) => /dominateP [] _; apply.
  rewrite lt0n; apply/nilP/eqP; exact: Hnnil.
Qed.

Definition rowpart d := if d is _.+1 then [:: d] else [::].
Fact rowpartnP d : is_part_of_n d (rowpart d).
Proof. case: d => [//= | d]; by rewrite /is_part_of_n /= addn0 eq_refl. Qed.
Definition rowpartn d : intpartn d := IntPartN (rowpartnP d).
(* Definition complete d : {mpoly R[n]} := Schur (rowpartn d). *)

Definition colpart d := nseq d 1%N.
Fact colpartnP d : is_part_of_n d (colpart d).
Proof.
  elim: d => [| d ] //= /andP [] /eqP -> ->.
  rewrite add1n eq_refl andbT /=.
  by case: d.
Qed.
Definition colpartn d : intpartn d := IntPartN (colpartnP d).
(* Definition elementary d : {mpoly R[n]} := Schur (colpartn d). *)

Lemma conj_rowpartn d : conj_intpartn (rowpartn d) = colpartn d.
Proof. apply val_inj => /=; rewrite /rowpart /colpart; by case: d. Qed.
Lemma conj_colpartn d : conj_intpartn (colpartn d) = rowpartn d.
Proof. rewrite -[RHS]conj_intpartnK; by rewrite conj_rowpartn. Qed.


Lemma rev_nseq (T : eqType) (x : T) d : rev (nseq d x) = nseq d x.
Proof.
  elim: d => [//= | d IHd].
  by rewrite -{1}(addn1 d) nseqD rev_cat IHd /=.
Qed.


Lemma tabwordshape_row d (w : d.-tuple 'I_n) :
  tabsh_reading (rowpartn d) w = sorted leq [seq val i | i <- w].
Proof.
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
Proof.
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
Proof.
  rewrite /Schur (eq_bigl _ _ (@tabwordshape_row d)).
  rewrite [RHS](eq_bigr (fun s : d.-tuple 'I_n => 'X_[s2m s])); first last.
    move=> [s _] /= _; rewrite /s2m; elim: s => [| s0 s IHs]/=.
      by rewrite big_nil -/mnm0 mpolyX0.
    rewrite big_cons {}IHs -mpolyXD; congr ('X_[_]).
    rewrite mnmP => i; by rewrite mnmDE !mnmE.
  apply eq_bigl => m;  by rewrite inE /=.
Qed.

Lemma completeE d : complete d = Schur (rowpartn d).
Proof.
  rewrite /complete -complete_basisE.
  rewrite -(big_map (@bmnm n d.+1) (fun m => mdeg m == d) (fun m => 'X_[m])).
  rewrite /index_enum -enumT -big_filter.
  set tmp := filter _ _.
  have {tmp} -> : tmp = [seq val m | m <- enum [set m :  'X_{1..n < d.+1} | mdeg m == d]].
    rewrite {}/tmp /enum_mem filter_map -filter_predI; congr map.
    apply eq_filter => s /=; by rewrite !inE andbT.
  rewrite -(eq_big_perm _ (perm_eq_enum_basis d)) /=.
  by rewrite big_map -[RHS]big_filter.
Qed.

Lemma tabwordshape_col d (w : d.-tuple 'I_n) :
    tabsh_reading (colpartn d) w = sorted (@gtnX _) w.
Proof.
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
  congr andb; rewrite /dominate /= andbT {w}.
  by rewrite /ltnX_op leqXE /= /leqOrd -ltn_neqAle.
Qed.

(** The definition of elementary symmetric polynomials as column Schur
    function agrees with the one from mpoly *)
Lemma elementaryE d : elementary d = Schur (colpartn d).
Proof.
  rewrite elementary_mesymE mesym_tupleE /tmono /elementary/Schur.
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

End Bases.
