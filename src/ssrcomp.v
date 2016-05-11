Require Import mathcomp.ssreflect.ssreflect.
From mathcomp Require Import ssrfun ssrbool eqtype ssrnat seq choice fintype div.
From mathcomp Require Import tuple finfun path bigop finset binomial.
From mathcomp Require Import fingroup perm automorphism action ssralg.
From mathcomp Require finmodule.

Set Implicit Arguments.
Unset Strict Implicit.


Section SSRComplements.

Variable T: finType.

Variables (R : Type) (idx : R) (op : R -> R -> R) (F : T -> R).

Lemma big_enum (S : {set T}) :
  \big[op/idx]_(s in S) F s = \big[op/idx]_(s <- enum S) F s.
Proof. by rewrite /index_enum big_filter; apply congr_big. Qed.

Lemma triv_part (P:{set {set T}}) (X:{set T}) (D:{set T}):
  partition P D -> X \in P -> D \subset X -> P = [set X].
Proof.
  rewrite /partition => /and3P [] /eqP Hcov /trivIsetP /(_ X) H H0 HXP /subsetP HD.
  case: (set_0Vmem (P :\ X)) => [/eqP | [Y]].
  - rewrite setD_eq0 subset1 => /orP [] /eqP // Hcontra.
    by move: HXP; rewrite Hcontra inE.
  - rewrite in_setD1 => /andP [].
    rewrite eq_sym => Hdiff HYP.
    move/(_ Y HXP HYP Hdiff): H => /disjoint_setI0 HXY.
    case: (set_0Vmem Y) => [HY | [] x HxY]; first by move: H0; rewrite -HY => /negP.
    have: x \in cover P by apply /bigcupP; exists Y.
    rewrite Hcov => /(HD x) HxX.
    have: x \in X :&: Y by rewrite inE; apply /andP.
    by rewrite HXY inE.
Qed.

Lemma partition_of0 (P : {set {set T}}):
  reflect (P = set0) (partition P set0).
Proof.
  rewrite /partition; apply (iffP and3P) => [[/eqP H1 _ H2] | ->].
  - case: (set_0Vmem P) => [// | [] X].
    case: (set_0Vmem X) => [-> H3 | [] x Hx HX]; first by move: H2 => /negP.
    have: x \in cover P by apply /bigcupP; exists X.
    by rewrite H1 inE.
  - by split; rewrite ?inE // /trivIset /cover !big_set0 ?cards0.
Qed.

Lemma pcycleP (s: {perm T}) x y :
  reflect (exists i, y = (s ^+ i)%g x) (y \in pcycle s x).
Proof.
  apply (iffP idP).
  - rewrite pcycle_traject => H.
    have:= H; rewrite -index_mem size_traject => Hlt.
    exists (index y (traject s x #|pcycle s x|)).
    move: Hlt => /(nth_traject s)/(_ x); rewrite (nth_index _ H) => {H} {1}->.
    elim: (index _ _) => [|n IHn] /=; first by rewrite expg0 perm1.
    by rewrite expgSr permM IHn.
  - move=> [i ->]; exact: mem_pcycle.
Qed.

Lemma enum_eq0P (s : {set T}):
  reflect (enum s = [::]) (s == set0).
Proof.
  apply (iffP eqP) => [-> |]; first exact: enum_set0.
  case: (set_0Vmem s) => [-> //| [x]].
  rewrite -mem_enum => Hx Hnil.
  by rewrite Hnil in_nil in Hx.
Qed.

End SSRComplements.

Section uniq.
Variable (T : eqType).        
Variable (s : seq T).
Implicit Types (n : nat).

Lemma take_uniq n : uniq s -> uniq (take n s).
Proof.
  admit.
Admitted.


Lemma drop_uniq n : uniq s -> uniq (drop n s).
Proof.
  admit.
Admitted.
End uniq.

Require Import binomial.

Section CutSet.

Variable (T : finType).

Lemma ex_subset_card (B : {set T}) k :
  k <= #|B| -> exists2 A : {set T}, A \subset B & #|A| == k.
Proof.
  rewrite -bin_gt0 -(cards_draws B k) card_gt0 => /set0Pn [x].
  rewrite inE => /andP [H1 H2]; by exists x.
Qed.

Lemma ex_partition_shape (s : seq nat) (A : {set T}) :
  0 \notin s -> sumn s = #|A| ->
  exists P : seq {set T},
    [/\ uniq P,
     partition [set X in P] A &
     [seq #|(X : {set T})| | X <- P] = s].
Proof.
  elim: s A => [| i s IHs] A /=.
  - move=> _ /esym/cards0_eq ->; exists [::]; split => //.
    apply/partition_of0;apply/setP => x.
    by rewrite !inE in_nil.
  - rewrite inE => /norP [] ine0 ins0 Hi.
    have : i <= #|A| by rewrite -Hi; exact: leq_addr.
    move=> /ex_subset_card [B BsubA /eqP cardB].
    have : sumn s = #|A :\: B|.
      by rewrite cardsD (setIidPr BsubA) cardB -Hi addKn.
    move=> /(IHs _ ins0) [P [Puniq]].
    rewrite /partition inE => /and3P [/eqP covP trivP set0P] Ps.
    have BninP : B \notin P.
      move: ine0; apply contra => BinP.
      rewrite eq_sym -cardB cards_eq0.
      rewrite -subset0 -(setICr B); apply/subsetIP; split; first by [].
      have : B \subset A :\: B.
        rewrite -covP /cover; apply (bigcup_max B) => //.
        by rewrite inE.
      by rewrite setDE => /subsetIP [].
    have H : [set X in B :: P] = B |: [set X in P].
      by apply/setP => X; rewrite !inE.
    have {ine0} Bne0 : B != set0.
      move: ine0; rewrite -cardB; apply contra => /eqP ->.
      by rewrite cards0.
    exists (B :: P); split; [|apply/and3P; split|].
    + rewrite /= Puniq andbT; exact: BninP.
    + rewrite H /cover big_setU1 /= ?inE // -/(cover _) covP.
      by rewrite -{1}(setIidPr BsubA) setID.
    + move: trivP; rewrite /trivIset H /cover !big_setU1 ?inE //= -/(cover _).
      move=> /eqP ->.
      rewrite covP cardsU (_ : B :&: (A :\: B) = set0) ?cards0 ?subn0 //.
      apply/eqP; rewrite -subset0; apply/subsetP => X.
      by rewrite !inE; case: (X \in B).
    + by rewrite !inE negb_or eq_sym Bne0.
    + by rewrite /= cardB Ps.
Qed.
