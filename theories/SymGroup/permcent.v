(** * Combi.SymGroup.permcent : The Centralizer of a Permutation *)
(******************************************************************************)
(*      Copyright (C) 2016-2018 Florent Hivert <florent.hivert@lri.fr>        *)
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
(** * The Centralizer of a Permutation

The main goal is to understand the structure of the centralizer group of a
given permutation [s], compute its cardinality and deduce the cardinality
of the conjugacy class of [s].

Here are the notion defined is this file, where [s] is a fixed permutation on
a finite type [T]:

- ['CC(s)] == the group of permutations of [T] which commute with [s] and
            stabilize each cycle of [s].
- [stab_iporbits s] == the group of permutations of [T] which only move
            the cycles of [s] and sends any cycle to a cycle of the same
            length.
- [inporbits s t] == the permutation induced by [t] on the set of the cycles
            of [s]. [inporbits s] is a morphism from [{perm T}] to
            [stab_iporbits s].
- [permcycles s P] == a right inverse morphism from [stab_iporbits s] to
            [{perm T}]. If [P] belongs to [stab_iporbits s] then
            [permcycles s P] si a compatible lifting of [P] in [{perm T}],
            otherwise the identity.

- [zcard l] == $\prod_{i \in N} i^m_i * m_i!$ where $m_i$ is the number of
             occurrence of $i$ in [l].

Here are the main results:

- ['CC(s)'] is the direct product of the group generated by the cycles of [s].
  Lemma [porbitgrpE]:

  [ 'CC(s) = \big[dprod/1]_(c in cycle_dec s) <[c]>. ]

- [stab_iporbits s] is the direct product over [i] of the group permuting
  the set of the cycles of size i. Theorem [stab_iporbitsE]:

  [
    stab_iporbits s =
    \big[dprod/1]_(i < #|T|.+1) Sym (porbits s :&: 'SC_i).
  ]

- The centralizer ['C[s]] is the semidirect product of ['CC(s)'] and the
  lifting of [stab_iporbits s]. Theorem [cent1_permE]:

  [ 'C[s] = 'CC(s) ><| (permcycles s) @* (stab_iporbits s). ]

- The cardinality of the centralizer of [s] given by [zcard].
  Corollary [card_cent1_perm]:

  [ #|'C[s]| = zcard (cycle_type s). ]

- The cardinality of the conjugacy class associated to the partition [l]
  of an integer [n] is given by Theorem [card_class_of_part]:

  [ #|classCT l| = n`! %/ zcard l. ]

*******************************************************************************)
Require Import mathcomp.ssreflect.ssreflect.
From mathcomp Require Import ssrfun ssrbool eqtype ssrnat seq fintype.
From mathcomp Require Import tuple path bigop finset div.
From mathcomp Require Import fingroup perm action gproduct morphism.

Require Import tools partition permcomp cycles cycletype.

Import GroupScope.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

#[local] Hint Resolve porbit_id : core.

Local Notation "''SC_' i " := (finset (fun x => #{x} == i))
    (at level 0).

(** ** Support and cycle in the centralizer *)
Section PermCycles.

Variable T : finType.
Implicit Type (s t c : {perm T}).

Lemma disjoint_psupport_dprodE (S : {set {perm T}}) :
  disjoint_psupports S ->
  (\big[dprod/1]_(s in S) <[s]>) = (\prod_(s in S) <[s]>)%G.
Proof using.
move=> [/trivIsetP Htriv Hinj]; apply/eqP/bigdprodYP => /= s Hs.
apply/subsetP => t; rewrite !inE negb_and negbK.
rewrite bigprodGEgen => /gen_prodgP [n [/= f Hf ->{t}]].
apply/andP; split.
- case: (altP (_ =P _)) => //=; apply contra => Hin.
  rewrite psupport_eq0 -subset0; apply/subsetP => x Hx.
  have [i Hxf] : exists i : 'I_n, x \in psupport (f i).
    apply/existsP; move: Hx; apply contraLR => /=.
    rewrite negb_exists => /forallP /= Hall; rewrite in_psupport negbK.
    apply big_rec => [ | i rec _ Hrec]; first by rewrite perm1.
    by have := Hall i; rewrite permM in_psupport negbK => /eqP ->.
  move/(_ i): Hf => /bigcupP [/= t /andP [tinS tneqs]].
  rewrite inE => /eqP Hfi; rewrite {}Hfi in Hxf.
  move: Hin Hx => /cycleP [j ->] {f} /(subsetP (psupport_expg _ _)) Hxs.
  suff : [disjoint psupport t & psupport s].
    by rewrite -setI_eq0 => /eqP/setP/(_ x) <-; rewrite inE Hxf Hxs.
  apply Htriv; try exact: imset_f.
  by move: tneqs; apply contra => /eqP/Hinj ->.
- apply group_prod => i _.
  have:= Hf i => /bigcupP [/= t /andP [tinS sneqt]].
  rewrite inE cent_cycle => /eqP -> {i f Hf}.
  apply/cent1P; apply: psupport_disjointC.
  apply Htriv; try exact: imset_f.
  by move: sneqt; apply contra => /eqP/Hinj ->.
Qed.

Lemma cent1_act_porbit s t x :
  t \in 'C[s] -> ('P)^* (porbit s x) t = porbit s (t x).
Proof using.
move=> /cent1P Hcom.
apply/setP => y; apply/imsetP/porbitP.
- move=> [z /porbitP [i -> {z}] -> {y}].
  by exists i => /=; rewrite -!permM (commuteX i Hcom) permM.
- move=> [i -> {y}].
  exists ((s ^+ i) x); first exact: mem_porbit.
  by rewrite -!permM (commuteX i Hcom) permM.
Qed.

(* Rewriting of 'C[s] \subset 'N(porbits s | ('P)^* *)
Lemma cent1_act_on_porbits s : [acts 'C[s], on porbits s | ('P)^*].
Proof using.
apply/subsetP => t Hcent; rewrite /astabs !inE /=.
apply/subsetP => C; rewrite inE => /imsetP [x _ -> {C}].
by apply/imsetP; exists (t x); [| apply: cent1_act_porbit].
Qed.

Lemma cent1_act_on_iporbits s i :
  [acts 'C[s], on porbits s :&: 'SC_i | ('P)^*].
Proof using.
apply/subsetP => t Ht; apply (subsetP (astabsI _ _ _)).
rewrite inE (subsetP (cent1_act_on_porbits s)) //=.
rewrite /astabs !inE /=; apply/subsetP => P; rewrite !inE.
by rewrite card_setact.
Qed.

Lemma commute_cyclic c t :
  c \is cyclic -> t \in 'C[c] -> perm_on (psupport c) t -> exists i, t = c ^+ i.
Proof using.
move=> /cyclicP [x Hx Hsupp] Hcent1 Hon.
have /= := cent1_act_porbit x Hcent1.
have:= Hx; rewrite -(perm_closed _ Hon).
move: Hon; rewrite Hsupp -eq_porbit_mem => Hon /eqP -> cx_stable.
move: Hcent1 => /cent1P Hcomm.
have /= := mem_setact ('P) t (porbit_id c x).
rewrite cx_stable => /porbitP [i]; rewrite apermE => Hi.
exists i; apply/permP => z.
case: (boolP (z \in (porbit c x))) => [/porbitP [j -> {z}]|].
- by rewrite -!permM -(commuteX j Hcomm) -expgD addnC expgD !permM Hi.
- move=> Hz; move: Hon => /subsetP/(_ z)/contra/(_ Hz).
  rewrite inE negbK => /eqP ->.
  by move: Hz; rewrite -Hsupp in_psupport negbK => /eqP /permX_fix ->.
Qed.

(** ** The cyclic centralizer *)
Notation "''CC' ( s )" :=
  'C_('C[s])(porbits s | ('P)^* ) (format "''CC' ( s )") : group_scope.

Lemma restr_perm_genC C s t :
  C \in porbit_set s -> t \in 'CC(s) -> restr_perm C t \in <[restr_perm C s]>%G.
Proof using.
move=> HC; rewrite inE => /andP [/cent1P Hcomm /astabP Hstab].
apply/cycleP; apply commute_cyclic.
- have: restr_perm C s \in cycle_dec s by apply/imsetP; exists C.
  by move/cyclic_dec.
- apply/cent1P; rewrite /commute.
  have HS := porbit_set_astabs HC.
  have Ht : t \in 'N(C | 'P).
    rewrite -astab1_set; apply/astab1P; apply Hstab.
    by move: HC; rewrite inE => /andP [].
  rewrite -((morphM (restr_perm_morphism C)) t s) //.
  rewrite -((morphM (restr_perm_morphism C)) s t) //.
  by rewrite Hcomm.
- rewrite psupport_perm_on (psupport_restr_perm HC).
  exact: psupport_restr_perm_incl.
Qed.

Lemma stab_porbit S s :
  s \in 'N(S | 'P) -> forall x, (x \in S) = (porbit s x \subset S).
Proof using.
move=> Hs x; apply/idP/subsetP => [Hx y /porbitP [i ->{y}] | Hsubs].
- elim: i => [|i]; first by rewrite expg0 perm1.
  by rewrite expgSr permM; move: Hs => /astabsP <- /=.
- exact: Hsubs (porbit_id s x).
Qed.

Lemma restr_perm_porbits S s :
  restr_perm S s \in 'C(porbits s | ('P)^* ).
Proof using.
case: (boolP (s \in 'N(S | 'P))) => [nSs | /triv_restr_perm -> //].
apply/astabP => /= X /imsetP [x _ ->{X}].
case: (boolP (x \in S)) => Hx.
- apply/setP => y; apply/imsetP/idP => [[z Hz ->{y}] /= | Hy].
  + have:= Hz; rewrite -eq_porbit_mem => /eqP Hsz.
    rewrite apermE restr_permE //.
    - rewrite -Hsz -{1}(expg1 s); exact: mem_porbit.
    - by rewrite (stab_porbit nSs) // Hsz -stab_porbit.
  + have HsVy : s^-1 y \in porbit s x.
      by rewrite porbit_sym -(porbit_perm _ 1) expg1 permKV porbit_sym.
    exists ((s ^-1) y); first exact: HsVy.
    rewrite /= apermE restr_permE => //; first by rewrite permKV.
    by move: Hx; rewrite (stab_porbit nSs) => /subsetP; apply.
- move: nSs; rewrite -astabsC => nSs.
  have: x \in ~: S by rewrite inE.
  rewrite (stab_porbit nSs) => Hsubs.
  apply/setP => y; apply/imsetP/idP => [[z Hz ->{y}] /= | Hy].
  + rewrite apermE (out_perm (restr_perm_on _ _)) //.
    by have:= subsetP Hsubs z Hz; rewrite inE.
  + exists y; first exact Hy.
    rewrite /= apermE (out_perm (restr_perm_on _ _)) //.
    by have:= subsetP Hsubs y Hy; rewrite inE.
Qed.

Lemma porbitgrpE s : 'CC(s) = \big[dprod/1]_(c in cycle_dec s) <[c]>.
Proof using.
rewrite disjoint_psupport_dprodE; last exact: disjoint_cycle_dec.
apply/setP => /= t; apply/idP/idP.
- rewrite inE => /andP [Hcomm Hstab].
  have:= partition_psupport s => /and3P [/eqP Hcov Htriv _].
  rewrite -(perm_decE (S := porbit_set s) (s := t)) //; first last.
  + by apply/astabP => C; rewrite /porbit_set inE => /andP [/(astabP Hstab)].
  + rewrite {}Hcov; apply/subsetP => x.
    rewrite !in_psupport (porbit_fix s); apply contra => /eqP Hx.
    have /(astabP Hstab) : porbit s x \in porbits s by apply: imset_f.
    rewrite Hx => /setP/(_ x).
    rewrite inE eq_refl /= => /imsetP [y].
    by rewrite inE => /eqP -> /=; rewrite apermE => <-.
  + rewrite /cycle_dec bigprodGE.
    apply/group_prod => c /imsetP [C HC ->{c}].
    apply mem_gen; apply/bigcupP; exists (restr_perm C s).
    * by rewrite /perm_dec; apply/imsetP; exists C.
    * by apply: restr_perm_genC; rewrite // inE Hcomm Hstab.
- rewrite bigprodGEgen; apply /subsetP; rewrite gen_subG.
  apply/subsetP => x /bigcupP [/= c /imsetP [C HC ->{c}]].
  move: HC; rewrite 3!inE => /andP [HC _] /eqP -> {x}.
  apply/andP; split.
  + by apply/cent1P; apply: restr_perm_commute.
  + exact: restr_perm_porbits.
Qed.

Lemma card_porbitgrpE s : #|'CC(s)| = (\prod_(i <- cycle_type s) i)%N.
Proof using.
rewrite -(bigdprod_card (esym (porbitgrpE s))).
rewrite /cycle_type /= /setpart_shape /cycle_dec.
rewrite big_imset /=; last exact: restr_perm_inj.
rewrite [RHS](perm_big [seq #{x} | x in porbits s]);
  last by apply/permPl; apply perm_sort.
rewrite /= [RHS]big_map big_enum.
rewrite [RHS](bigID (fun X => #{X} == 1%N)) /=.
rewrite [X in _ = (X * _)%N]big1 ?mul1n; last by move=> i /andP [_ /eqP].
rewrite [RHS](eq_bigl (mem (porbit_set s))) /=;
  last by move=> C; rewrite /porbit_set !inE.
apply eq_bigr => X HX; rewrite -orderE.
rewrite order_cyclic; last by rewrite unfold_in (porbit_set_restr HX) cards1.
by rewrite psupport_restr_perm.
Qed.



(** ** Permuting the cycles among themselves *)
Definition stab_iporbits s : {set {perm {set T}}} :=
  Sym (porbits s) :&:
    \bigcap_(i : 'I_#|T|.+1) 'N(porbits s :&: 'SC_i | 'P).
(* stab_iporbits is canonically a group *)

Definition inporbits s : {perm T} -> {perm {set T}} :=
  restr_perm (porbits s) \o actperm 'P^*.
(* inporbits is canonically a group morphism *)


Section CM.

Variable s : {perm T}.
Implicit Type P : {perm {set T}}.

Lemma stab_iporbits_stab P :
  (if P \in stab_iporbits s then P else 1) @: porbits s \subset porbits s.
Proof using.
case: (boolP (_ \in _)) => [|_].
- by rewrite !inE => /andP [/im_perm_on -> _].
- by rewrite (eq_imset (g := id)) ?imset_id // => x; rewrite perm1.
Qed.

Lemma stab_iporbits_homog P :
  {in porbits s, forall C,
       #|(if P \in stab_iporbits s then P else 1) C| = #|C| }.
Proof using.
case: (boolP (_ \in _)) => [|_].
- rewrite inE => /andP [_ /bigcapP HP] C HC; rewrite /inporbits /=.
  have:= subsetT C => /subset_leqif_cards []; rewrite -ltnS cardsT => cardC _.
  move/(_ (Ordinal cardC) isT): HP => /= /astabsP/(_ C).
  by rewrite !inE HC eq_refl /= => /andP [_ /eqP].
- by move=> C _; rewrite perm1.
Qed.

Local Definition stab_iporbits_porbitmap P :=
  PorbitMap (stab_iporbits_stab P) (stab_iporbits_homog P).
Local Definition stab_iporbits_map P := cymap (stab_iporbits_porbitmap P).

Lemma stab_iporbits_map_inj P : injective (stab_iporbits_map P).
Proof using.
apply (can_inj (g := stab_iporbits_map P^-1)) => X /=.
rewrite /stab_iporbits_map cymapK //= {X} => C HC.
rewrite groupV /= -/(stab_iporbits s).
by case: (boolP (P \in _)) => [| HP]; rewrite ?perm1 ?permK.
Qed.
Definition permcycles P := perm (@stab_iporbits_map_inj P).

Lemma permcyclesC P : commute (permcycles P) s.
Proof using.
by apply esym; apply/permP => x; rewrite !permM !permE; exact: cymapP.
Qed.

Lemma permcyclesP P : (permcycles P) \in 'C[s].
Proof using. apply/cent1P; exact: permcyclesC. Qed.

Lemma porbit_permcycles P x :
  P \in stab_iporbits s -> porbit s (permcycles P x) = P (porbit s x).
Proof using. by rewrite permE porbit_cymap /= => ->. Qed.

End CM.

Lemma permcyclesM s :
  {in stab_iporbits s &, {morph permcycles s : P Q / P * Q}}.
Proof using.
move=> /= P Q HP HQ /=; apply/permP => X.
rewrite permM !permE -[RHS]/((_ \o _) X).
apply esym; apply cymap_comp => C HC /=.
by rewrite groupM // HP HQ permM.
Qed.
Canonical permcycles_morphism s := Morphism (permcyclesM (s := s)).

Lemma permcyclesK s :
  {in stab_iporbits s, cancel (permcycles s) (inporbits s)}.
Proof using.
move=> /= P HP; apply/permP => C /=.
rewrite /inporbits /=.
case: (boolP (C \in porbits s)) => HC.
- rewrite !restr_permE // ?actpermE /=; first last.
    apply/astabsP => {HC} C; rewrite /= apermE actpermE /=.
    apply (actsP (cent1_act_on_porbits s)).
    exact: permcyclesP.
  move: HC => /imsetP [x _ ->{C}].
  rewrite cent1_act_porbit; last exact: permcyclesP.
  exact: porbit_permcycles.
- rewrite (out_perm (restr_perm_on _ _) HC).
  by move: HP; rewrite inE => /andP []; rewrite inE => /out_perm ->.
Qed.

Lemma permcycles_inj s : 'injm (permcycles s).
Proof using. apply/injmP; apply: can_in_inj; exact: permcyclesK. Qed.

Lemma inporbits_im s : inporbits s @: 'C[s] = stab_iporbits s.
Proof using.
apply/setP => /= P; apply/imsetP/idP => /= [[/= x Hx ->] | HP].
- rewrite inE; apply/andP; split.
  + by rewrite inE; apply: restr_perm_on.
  + apply/bigcapP => [[i Hi] _] /=; apply/astabsP => X.
    have/actsP/(_ _ Hx X)/= := cent1_act_on_iporbits s i.
    rewrite !inE !apermE; case: (boolP (X \in porbits s)) => /= [HX| HX _].
    * rewrite restr_permE // ?actpermE // {X HX}.
      apply/astabsP => X /=; rewrite apermE actpermE /=.
      exact: (actsP (cent1_act_on_porbits s)).
    * rewrite (out_perm (restr_perm_on _ _) HX).
      by move: HX => /negbTE ->.
- by exists (permcycles s P); [apply: permcyclesP | rewrite permcyclesK].
Qed.

Lemma trivIset_iporbits s : trivIset [set porbits s :&: 'SC_i | i : 'I_#|T|.+1].
Proof using.
apply/trivIsetP => A B /imsetP [i _ ->{A}] /imsetP [j _ ->{B}] Hij.
have {}Hij : i != j by move: Hij; apply contra => /eqP -> .
rewrite -setI_eq0; apply/eqP/setP => x.
rewrite !inE -!andbA; apply/negP => /and4P [_ /eqP -> _] /eqP /val_inj Hieqj.
by rewrite Hieqj eq_refl in Hij.
Qed.

Lemma cover_iporbits s :
  cover [set porbits s :&: 'SC_i | i : 'I_#|T|.+1] = porbits s.
Proof using.
apply/setP => C; apply/bigcupP/idP => [[/= X] | Hx].
- by move/imsetP => [/= i _ ->{X}]; rewrite inE => /andP [].
- have:= subsetT C => /subset_leqif_cards []; rewrite -ltnS cardsT => cardC _.
  exists (porbits s :&: 'SC_(Ordinal cardC)); first exact: imset_f.
  by rewrite !inE Hx /=.
Qed.

Lemma stab_iporbitsE_prod s :
  stab_iporbits s =
  (\prod_(i < #|T|.+1) Sym_group (porbits s :&: 'SC_i))%G.
Proof using.
apply/setP => t.
rewrite inE bigprodGE; apply/andP/idP => [[Ht /bigcapP/(_ _ isT) Hcyi] | Ht].
- rewrite -(perm_decE (s := t) (trivIset_iporbits s)); first last.
  + apply/astabP => /= CS /imsetP [/= i _ ->{CS}].
    by apply/astab1P; rewrite astab1_set; exact: Hcyi.
  + by move: Ht; rewrite inE -psupport_perm_on cover_iporbits.
  apply group_prod => u /imsetP [/= X /imsetP [/= i _ ->{X}] ->{u}].
  apply mem_gen; apply/bigcupP; exists i; first by [].
  by rewrite inE; exact: restr_perm_on.
split; move: t Ht; apply/subsetP; rewrite gen_subG;
  apply/subsetP => /= P /bigcupP [/= i _].
- rewrite !inE !psupport_perm_on => /subset_trans; apply.
  exact: subsetIl.
- rewrite inE => HP.
  apply/bigcapP => /= j _; apply/astabsP => /= X; rewrite apermE.
  case: (altP (P X =P X)) => [-> //| HPX].
  have:= HP => /subsetP/(_ X); rewrite inE => /(_ HPX) H.
  have:= H; rewrite -(perm_closed _ HP).
  by move: H; rewrite !inE => /andP [-> /eqP ->] /andP [-> /eqP ->].
Qed.

Theorem stab_iporbitsE s :
  stab_iporbits s = \big[dprod/1]_(i < #|T|.+1) Sym (porbits s :&: 'SC_i).
Proof using.
rewrite stab_iporbitsE_prod; apply/esym/eqP/bigdprodYP => i /= _.
apply/subsetP => /= t Ht; rewrite !inE negb_and negbK.
have {Ht} : t \in Sym (porbits s :&: [set x | #{x} != i]).
  move: Ht; rewrite bigprodGE => /gen_prodgP [n [/= f Hf ->{t}]].
  apply group_prod => j _; move/(_ j): Hf => /bigcupP [k Hk].
  rewrite !inE /perm_on => /subset_trans; apply; apply setIS.
  by apply/subsetP => C; rewrite !inE => /eqP ->.
rewrite inE => on_neqi; apply/andP; split.
- case: (altP (t =P 1)) => //=; apply contra => on_eqi.
  apply/eqP/permP => C; rewrite perm1.
  case: (boolP (#|C| == i)) => [HC | /negbTE HC].
  + by rewrite (out_perm on_neqi) // !inE HC andbF.
  + by rewrite (out_perm on_eqi) // !inE HC andbF.
- apply/centP => /= u; move: on_neqi.
  rewrite inE !psupport_perm_on -[psupport u \subset _]setCS => on_neqi on_eqi.
  apply psupport_disjointC; rewrite disjoints_subset.
  apply: (subset_trans on_neqi); apply: (subset_trans _ on_eqi).
  by apply/subsetP => X; rewrite !inE => /andP [ -> ->].
Qed.

Lemma card_stab_iporbits s :
  #|stab_iporbits s| =
    (\prod_(i < #|T|.+1) (count_mem (nat_of_ord i) (cycle_type s))`!)%N.
Proof using.
rewrite -(bigdprod_card (esym (stab_iporbitsE s))).
apply eq_bigr => i _.
rewrite card_Sym /setpart_shape; congr (_)`!.
have /permPl/seq.permP -> := perm_sort geq [seq #{x} | x in porbits s].
rewrite !cardE -size_filter /= /enum_mem.
rewrite filter_map size_map -filter_predI; congr size.
by apply eq_filter => C; rewrite !inE andbC.
Qed.

Lemma conj_porbitgrp s y z :
  y \in 'C[s] -> z \in 'CC(s) -> z ^ y \in 'CC(s).
Proof using.
move=> Hy; rewrite inE => /andP [zC /astabP zCporbits].
have /= HyV := groupVr Hy.
rewrite inE; apply/andP; split.
- by apply groupM; last exact: groupM.
- apply/astabP => C /imsetP [x _ ->{C}].
  rewrite !actM /= cent1_act_porbit // zCporbits; last exact: imset_f.
  by rewrite -cent1_act_porbit // -!actM mulVg act1.
Qed.

Lemma inporbits1 s t : t \in 'C(porbits s | ('P)^* ) -> inporbits s t = 1.
Proof using.
move=> Ht; have tfix := astab_act Ht.
apply/permP => /= X; rewrite /inporbits perm1.
case: (boolP (X \in porbits s)) => HX.
- rewrite restr_permE //= ?actpermE ?tfix // {X HX}.
  apply/astabsP => X /=; rewrite actpermK.
  by apply astabs_act; move: Ht; apply/subsetP; exact: astab_sub.
- exact: (out_perm (restr_perm_on _ _ ) HX).
Qed.

Lemma cent1_stab_iporbit_porbitgrpS s :
  'C[s] \subset permcycles s @* stab_iporbits s * 'CC(s).
Proof using.
apply/subsetP => t Ht.
pose str := permcycles s (inporbits s t^-1).
have Hstr : str \in 'C[s] by apply: permcyclesP.
rewrite -(mulKg str t); apply mem_mulg.
- rewrite groupV /= -/(stab_iporbits s); apply imset_f.
  by rewrite setIid -inporbits_im; apply imset_f; apply groupVr.
- rewrite inE; apply/andP.
  split; first exact: groupM.
  apply/astabP => C /imsetP [x _ ->{C}].
  rewrite !actM /= cent1_act_porbit //=.
  rewrite porbit_permcycles; first last.
    by rewrite -inporbits_im; apply imset_f; apply groupVr.
  rewrite /inporbits /= restr_permE; first last.
  + exact: imset_f.
  + apply/astabsP => X /=; rewrite actpermK.
    apply astabs_act; move: Ht => /groupVr; apply/subsetP => /=.
    exact: cent1_act_on_porbits.
  by rewrite actpermE /= -actM mulVg act1.
Qed.

(** * Main theorem *)
Theorem cent1_permE s :
  'C[s] = 'CC(s) ><| (permcycles s) @* (stab_iporbits s).
Proof using.
apply/esym/sdprod_normal_complP.
- apply/normalP; split; first exact: subsetIl.
  move=> /= y Hy; apply/setP => /= x; have /= HyV := groupVr Hy.
  apply/imsetP/idP => [[/= z Hz] ->{x} | Hx].
  + exact: conj_porbitgrp.
  + exists (x ^ (y^-1)); last by rewrite conjgKV.
    exact: conj_porbitgrp.
rewrite /= -/(stab_iporbits s).
rewrite inE; apply/andP; split.
- apply/eqP/trivgP; apply/subsetP => t.
  rewrite 2!inE => /andP [/imsetP [/= P]].
  rewrite setIid => HP Ht /andP [tC tCporbits]; rewrite inE.
  suff : P = 1 by rewrite Ht => ->; rewrite morphism.morph1.
  by rewrite -(permcyclesK HP) -Ht; apply: inporbits1.
- rewrite /=; apply/eqP/setP => /= t.
  apply/idP/idP => [/mulsgP [/= t' u /imsetP [P]] | Ht].
  + rewrite setIid => HP ->{t'} Hu ->{t}.
    apply groupM; first exact: permcyclesP.
    by move: Hu; rewrite inE => /andP [].
  + exact: (subsetP (cent1_stab_iporbit_porbitgrpS s)).
Qed.

Local Open Scope nat_scope.

(** ** Conjucacy class cardinality *)
Definition zcard l :=
  \prod_(i <- l) i * \prod_(i < (sumn l).+1) (count_mem (i : nat) l)`!.

Lemma zcard_nil : zcard [::] = 1.
Proof.
rewrite /zcard big_nil mul1n /= big_const fact0.
by rewrite eq_cardT // size_enum_ord /= mul1n.
Qed.

Lemma zcard_any l b :
  (sumn l < b) ->
  \prod_(i <- l) i * \prod_(i < b) (count_mem (i : nat) l)`! = zcard l.
Proof.
rewrite /zcard => /(big_ord_widen _ (fun i : nat => (count_mem i l)`!)) ->.
congr (_ * _).
rewrite (bigID (fun i : 'I_(_) => i < (sumn l).+1)) /=.
rewrite -[RHS]muln1; congr (_ * _).
apply big1 => i Hi.
suff -> : count_mem (i : nat) l = 0 by rewrite fact0.
apply /count_memPn; move: Hi; apply contra.
rewrite ltnS  => /perm_to_rem/perm_sumn -> /=.
exact: leq_addr.
Qed.

Lemma zcard_rem i l :
  i != 0 -> i \in l -> i * (count_mem i l) * (zcard (rem i l)) = zcard l.
Proof.
move => Hi /perm_to_rem Hrem.
have /zcard_any <- : sumn (rem i l) < (sumn l).+1.
  by rewrite ltnS (perm_sumn Hrem) /=; apply leq_addl.
have Hil : i < (sumn l).+1.
  by rewrite ltnS (perm_sumn Hrem) /=; apply leq_addr.
rewrite /zcard (perm_big _ Hrem) /= big_cons -!mulnA; congr (_ * _).
rewrite mulnC -mulnA; congr (_ * _).
rewrite  [in RHS](bigD1 (Ordinal Hil)) //=.
rewrite mulnC (seq.permP Hrem) /= eq_refl /= add1n.
rewrite factS -!mulnA; congr (_ * _).
rewrite  [in LHS](bigD1 (Ordinal Hil)) //=; congr (_ * _).
apply eq_bigr => j; rewrite -val_eqE => /= /negbTE Hij.
move/seq.permP: Hrem => -> /=.
by rewrite eq_sym Hij add0n.
Qed.

Corollary card_cent1_perm s : #|'C[s]| = zcard (cycle_type s).
Proof using.
have /esym/sdprod_card <- := cent1_permE s.
rewrite card_porbitgrpE card_in_imset // ?setIid; first last.
  by apply: can_in_inj; exact: permcyclesK.
by rewrite /zcard card_stab_iporbits // sumn_intpartn.
Qed.

Theorem card_class_perm s :
  #|class s [set: {perm T}]| = #|T|`! %/ zcard (cycle_type s).
Proof using.
rewrite -card_cent1_perm -index_cent1 /= -divgI.
rewrite (eq_card (B := perm_on setT)); first last.
  move=> p; rewrite inE unfold_in /perm_on /=.
  by apply/esym/subsetP => i _; rewrite in_set.
rewrite card_perm cardsE setTI; congr (_ %/ #|_|).
by rewrite /= setTI.
Qed.

End PermCycles.

Lemma dvdn_zcard_fact n (l : 'P_n) : zcard l %| n`!.
Proof.
pose l' := (CTpartn l).
have -> : zcard l = zcard l' by rewrite cast_intpartnE /=.
rewrite -(permCTP l') -(card_cent1_perm (permCT l')).
rewrite -card_Sn -cardsT; apply cardSg.
exact: subsetT.
Qed.

Lemma neq0zcard n (l : 'P_n) : zcard l != 0.
Proof.
have:= dvdn_zcard_fact l; apply contraL => /eqP ->.
by rewrite dvd0n -lt0n fact_gt0.
Qed.

Theorem card_class_of_part n (l : 'P_n) : #|classCT l| = n`! %/ zcard l.
Proof using.
rewrite /classCT card_class_perm permCTP /=.
by rewrite cast_intpartnE /= card_ord.
Qed.
