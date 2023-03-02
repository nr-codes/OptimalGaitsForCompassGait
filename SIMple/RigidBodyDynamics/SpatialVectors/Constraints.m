(* ::Package:: *)

(************************************************************************)
(* This file was generated automatically by the Mathematica front end.  *)
(* It contains Initialization cells from a Notebook file, which         *)
(* typically will have the same name as this file except ending in      *)
(* ".nb" instead of ".m".                                               *)
(*                                                                      *)
(* This file is intended to be loaded into the Mathematica kernel using *)
(* the package loading commands Get or Needs.  Doing so is equivalent   *)
(* to using the Evaluate Initialization Cells menu command in the front *)
(* end.                                                                 *)
(*                                                                      *)
(* DO NOT EDIT THIS FILE.  This entire file is regenerated              *)
(* automatically each time the parent Notebook file is saved in the     *)
(* Mathematica front end.  Any changes you make to this file will be    *)
(* overwritten.                                                         *)
(************************************************************************)



(* ::Code::Initialization:: *)
(*
RigidBodySystem.nb: High-level functions used to define a rigid body.
Copyright (C) 2014 Nelson Rosa Jr.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version. This program is distributed in the 
hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details. You should have 
received a copy of the GNU General Public License along with this program.
If not, see <http://www.gnu.org/licenses/>.
*)


(* ::Input::Initialization:: *)
BeginPackage["RigidBodyDynamics`", "GlobalVariables`"]
Begin["`Private`"]
con = {};
\[Epsilon] = 1;


(* ::Input::Initialization:: *)
RBDSetEpsilon[e_:1] := (\[Epsilon] = e);


(* ::Input::Initialization:: *)
RBDListConstraints[form_:{___}] := Cases[con, form];


(* ::Input::Initialization:: *)
RBDRemoveConstraint[form_:{___}] := (con = DeleteCases[con, form]);


(* ::Input::Initialization:: *)
RBDAddConstraints[c_] := con = c;


(* ::Input::Initialization:: *)
Options[RBDConQ] = {"n" -> Automatic, "\[Phi]" -> True, Expand -> True, "Kp" -> 1, "Kv" -> 1}


(* ::Input::Initialization:: *)
addcon[c_, n_, e_, t_, OptionsPattern[RBDConQ]]:= AppendTo[con, {c, n, e, t, OptionValue["\[Phi]"], OptionValue["Kp"], OptionValue["Kv"], OptionValue[Expand], OptionValue["n"]}];


(* ::Input::Initialization:: *)
SetAttributes[{RBDConQ, RBDConV, RBDConA}, Listable];

RBDConQ[name_, expr_, opts:OptionsPattern[]] := addcon["q", name, expr, "p", opts];

RBDConV[name_, expr_, opts:OptionsPattern[RBDConQ]] := addcon["v", name, expr, "p", "Kp" -> 0, opts];

RBDConA[name_, expr_, opts:OptionsPattern[RBDConQ]] := addcon["a", name, expr, "p", "Kp" -> 0, "Kv" -> 0, opts];


(* ::Input::Initialization:: *)
SetAttributes[{RBDVirtQ, RBDVirtV, RBDVirtA}, Listable];

RBDVirtQ[name_, expr_, opts:OptionsPattern[RBDConQ]] := addcon["q", name, expr, "v", opts];

RBDVirtV[name_, expr_, opts:OptionsPattern[RBDConQ]] := addcon["v", name, expr, "v", "Kp" -> 0, opts];

RBDVirtA[name_, expr_, opts:OptionsPattern[RBDConQ]] := addcon["a", name, expr, "v", "Kp" -> 0, "Kv" -> 0, opts];


(* ::Input::Initialization:: *)
(* P = qdot\[Transpose].B.u, using Con we can determine B from expr = B\[Transpose].qdot *)
SetAttributes[RBDTranV, Listable];

RBDTranV::expr = "Expression should either be T.\[DoubleStruckV] or \[DoubleStruckB]'[...], where T is a matrix.  Resulting expression will result in zero force transmission.";

RBDTranV[name_, expr_, opts:OptionsPattern[RBDConQ]] := Module[{},
(* should provide \[DoubleStruckB]'[...] and \[DoubleStruckV][...] expressions here only *)
If[FreeQ[expr, \[DoubleStruckV]|Derivative[1][\[DoubleStruckB]]], Message[RBDTranV::expr]];
addcon["v", name, expr, "u", "\[Phi]" -> False, "Kp" -> 0, "Kv" -> 0, opts]
];


(* ::Input::Initialization:: *)
Options[RBDExpandExpression] = Join[{Assumptions -> Element[(_\[DoubleStruckQ]|_\[DoubleStruckV]|_\[DoubleStruckX]|_\[DoubleStruckC]|_\[DoubleStruckB]), Reals],
Trig -> False, TransformationFunctions->{Automatic, TrigReduce}}, Options[Simplify]];

RBDExpandExpression[expr_, opts:OptionsPattern[]] := Module[{e, r},
e = expr /. b_\[DoubleStruckB] :> RBDSpatialPosition[b];
e = Block[{Derivative},
Derivative[1][\[DoubleStruckQ]][x__] := \[DoubleStruckV][x];
Derivative[2][\[DoubleStruckQ]][x__] := \[DoubleStruckA][x];
Derivative[1][\[DoubleStruckV]][x__] := \[DoubleStruckA][x];
(* memoize expanded \[DoubleStruckB]'s *)
Derivative[1][\[DoubleStruckB]][x__] := Derivative[1][\[DoubleStruckB]][x] = Con[RBDSpatialPosition@\[DoubleStruckB][x], \[DoubleStruckQ], \[DoubleStruckV]];
Derivative[2][\[DoubleStruckB]][x__] := Derivative[2][\[DoubleStruckB]][x] = Module[{b = \[DoubleStruckB]'[x]}, Con[b, \[DoubleStruckV], \[DoubleStruckA]]+Con[b, \[DoubleStruckQ], \[DoubleStruckV]]];
Derivative[n_?Positive][\[DoubleStruckC]][x__] := 0;

e
];

r = {1. -> 1, -1. -> -1, 0. ->  0};
e = e /. r;
Chop[TrigReduce@Simplify[e, opts]] /. r
];


(* ::Input::Initialization:: *)
rfun[x_:{}, \[Lambda]_:{}] := EvaluateConstraintFunction["r", x, \[Lambda]];

rdotfun[x_:{}, \[Lambda]_:{}] := EvaluateConstraintFunction["rdot", x, \[Lambda]];

Tcbfun[x_:{}, \[Lambda]_:{}] := EvaluateConstraintFunction["Tcb", x, \[Lambda]];

Jfun[x_:{}, \[Lambda]_:{}] := EvaluateConstraintFunction["J", x, \[Lambda]];

\[Phi]fun[x_:{}, \[Lambda]_:{}] := EvaluateConstraintFunction["\[Phi]", x, \[Lambda]];

\[Eta]fun[x_:{}, \[Lambda]_:{}] := EvaluateConstraintFunction["\[Eta]", x, \[Lambda]];

Kfun[x_:{}, \[Lambda]_:{}] := EvaluateConstraintFunction["K", x, \[Lambda]];

EvaluateConstraintFunction[t_, x_:{}, \[Lambda]_:{}] := Module[{a, b},
a = If[x === {}, Array[\[DoubleStruckX], nx], x];
b = If[\[Lambda] === {}, Array[\[DoubleStruckC], nc], \[Lambda]];
rb[C, t][a, b]
];


(* ::Input::Initialization:: *)
RBDConstraintFunctions::a = "`1` is not an nca of `2`.  Replacing `1` with `3`.  Update constraint if this is not desired behavior.";

RBDConstraintFunctions[] := Module[{j, t, b},
j = <|"J" -> ({}&), "\[Phi]" -> ({}&), "\[Eta]" -> ({}&), "K" -> ({}&), "n" -> <||>|>;
t = <|"p" -> {}, "v" -> {}, "u" -> {}|>;
b = ConBFunctions[False];
SetConstraintData[j, t, b]
];

RBDConstraintFunctions[None] := RBDConstraintFunctions[];

RBDConstraintFunctions[All] := RBDConstraintFunctions@DeleteDuplicates[con[[All, 2]]];

RBDConstraintFunctions[name_] := Module[{c, J, \[Phi], \[Eta], K, brX, n, t},
(* adds desired constraints to rb[C]; returns an intermediate representation *)
(* of final constraints; rest of code places in final representation *)
c = PreprocessConstraints[name];
If[c === {} || KeyFreeQ[rb, C], Return[RBDConstraintFunctions[]]];

(* extract data from intermediate representation in rb[C] *)
{J, \[Phi]} = ConvertToXLFunction /@ {rb[C, "J"], rb[C, "\[Phi]"]};
brX = ConBFunctions[];

(* partition row type *)
t = rb[C, "t"];
t = GroupBy[Range@Length@t, t[[#]]&];
t = Join[<|"p" -> {}, "v" -> {}, "u" -> {}|>, t];

(* define feedback error for constraint stabilization *)
\[Eta] = ConvertToXLFunction@Transpose@rb[C, "\[Eta]"];
K = {1/\[Epsilon]^2, 1/\[Epsilon]}#& /@ rb[C, "K"];
K = DiagonalMatrix /@ Transpose[K];
K = ConvertToXLFunction@K;

n = <|"J" -> J, "\[Phi]" -> \[Phi], "\[Eta]" -> \[Eta], "K" -> K, "n" -> rb[C, "n"]|>;
SetConstraintData[n, t, brX]
];


(* ::Input::Initialization:: *)
SetConstraintData::u = "There are `1` actuators and `2` virtual constraints.  There may not be enough actuators to solve for these constraints.";

SetConstraintData[J_, T_, B_] := Module[{n},
{nf, nv, nu} = Length /@ Values@T[[{"p", "v", "u"}]];
If[nu < nv, Message[SetConstraintData::u, nu, nv]];
zpos = Table[z1, Length@B["bo"](*nf + nv + nu*)];
ZAb = Table[z1, nq + nf + nv, nq + nf + nu + 1];
rb[C] = Join[J, T, B]
]


(* ::Input::Initialization:: *)
PreprocessConstraints::name = "No valid constraints found under ``.";
PreprocessConstraints[names_] := Module[{c, t, f},
(* remove C; it has Function as head not List, which AddCon needs *)
KeyDropFrom[rb, C];
t = {"q", "v", "a", "b"};
f = {ConQ, ConV, ConA, ConB};
c = Cases[con, {_, Alternatives@@names, __}];
c= Select[c, StringMatchQ[First@#, t]&];

If[c === {}, Message[PreprocessConstraints::name, names]; Return[{}]];
(* expand constraints?*)
c[[All, 1]] = MapThread[If[#1, #2, "b" ]&, c[[All, {8, 1}]]\[Transpose]];
(* replace with con type *)
c[[All, 1]] = c[[All, 1]] /. Thread[t -> f];
(* drop expand column *)
c = Drop[c, None, {8}];
(* adds constraints to rb and returns the results from ConQ, etc. *)
#[[1]]@@#[[2;;]]& /@ c;
(* return intermediate format *)
rb[C]
];


(* ::Input::Initialization:: *)
Con[expr_, c_, dc_, z_:z1] := Module[{e, a, b},
e = RBDExpandExpression[expr];
(* try to figure out vars to take derivates w/, if not specified *)

a = If[VectorQ[c], c, SortBy[DeleteDuplicates[Cases[e, _c, {-2}]], RBDGetIndex]];

b = If[TensorQ[dc],dc, a /. Thread[c -> dc]];

If[a === {}, z, D[e, {a}].b]
];

(* convert from string to number *)
StandardizeCon[expr_] := expr /. f_[x_, y_String] /; MemberQ[{\[DoubleStruckQ], \[DoubleStruckV], \[DoubleStruckA]}, f] :> RBDGetDOF[f[x, y]];

ValidCon::expr = "Ignoring constraint `2` in `1`.  The expression can only be a function of `3`.  Modify source expression.";

ValidCon[name_, expr_, excl_:{}, Jexcl_:{}, h_:{\[DoubleStruckQ], \[DoubleStruckV], \[DoubleStruckA]}] := Module[{v, J, a},
J = Jexcl;
If[J =!= {},
(* is constraint linear in variables in Jexcl? compute Jacobian *)
v = Alternatives@@(Blank /@ J);
a = Flatten@DeleteDuplicates[Cases[expr, v, {-2}]];
J = If[a === {}, z1, D[expr, {a}]];
];
a = Alternatives@@(Blank /@ excl);

(* is constraint valid? *)
v = FreeQ[J, v] && FreeQ[expr, a];

(* if invalid, print error message *)
If[!v, 
J = Switch[Length@#, 0, "", 1, #[[1]], 2, #[[1]] <> " and " <> #[[2]], 3, #[[1]] <> ", " <> #[[2]] <> ", and " <> #[[3]]]&;
a = J[ToString /@ Complement[h, excl]];
J = J[ToString /@ Jexcl];
If[StringLength@J > 0, a = a <> "; and must be linear in " <> J;];
J = ToString[expr, InputForm];
If[StringLength@J > 200, J = StringTake[J, 200] <> "..."];
Message[ValidCon::expr, name, J, a]
];
v
];


(* ::Input::Initialization:: *)
SetAttributes[{ConQ, ConV, ConA, ConB}, Listable];

ConQ[name_, expr_, t_, \[Phi]_, Kp_, Kv_, n_] := Module[{e},
e = RBDExpandExpression[expr];
If[ValidCon[name, e, {\[DoubleStruckV], \[DoubleStruckA]}], 
ConV[name, Con[e, \[DoubleStruckQ], \[DoubleStruckV]], t, \[Phi], Kp, Kv, n, e]
]
];

ConV[name_, expr_, t_, \[Phi]_, Kp_, Kv_, n_, h_:z1] := Module[{e, Ja, Jv},
e = RBDExpandExpression[expr];
If[ValidCon[name, e, {\[DoubleStruckA]}, {\[DoubleStruckV]}], 
ConA[name, Con[e, \[DoubleStruckV], \[DoubleStruckA]] + Con[e, \[DoubleStruckQ], \[DoubleStruckV]], t, \[Phi], Kp, Kv, n, h, e]
]
];

ConA[name_, expr_, t_, \[Phi]bool_, Kp_, Kv_, n_, h_:z1, hdot_:z1] := Module[{e, a, J, \[Phi], m, \[Eta]},
(* compute Jacobian *)
e = StandardizeCon@RBDExpandExpression[expr];
(* convert to numbered indexing if string-based indexing is used *)
a = StandardizeCon@DeleteDuplicates[Cases[e, _\[DoubleStruckA], {-2}]];
J = Con[e, a, D[a, {RBDGetValue[nx+1, 3nq, "n" -> False]}], zq];
\[Eta] = RBDExpandExpression[{h, hdot}];
(* is expr linear in \[DoubleStruckA] with \[Eta] only a function of \[DoubleStruckQ] and \[DoubleStruckV]? *)
m = ValidCon[name, J, {\[DoubleStruckA]}] && ValidCon[name, \[Eta][[1]],{\[DoubleStruckV], \[DoubleStruckA]}];
m = m && ValidCon[name, \[Eta][[2]],{\[DoubleStruckA]}];
If[m, 
(* compute \[Phi][q, v] *)
\[Phi] = RBDExpandExpression@If[\[Phi]bool, e /. Thread[a -> 0], z1];
AddCon[name, t, n, "J" -> J, "\[Phi]" -> \[Phi], "\[Eta]" -> \[Eta], "K" -> {Kp, Kv}]
]
];

ConB[name_, Derivative[1][\[DoubleStruckB]][x__], t_, rdot_,  Kp_, Kv_, n_, v_:1] := ConB[name, \[DoubleStruckB][x], t, rdot,  Kp, Kv, n, v];

ConB[name_, expr_\[DoubleStruckB], t_, rdot_, Kp_, Kv_, n_, v_:0] := Module[{b, r, Xcb, o},
{b, r, Xcb, o} = expr /. \[DoubleStruckB][b_, r_, Xcb_, o___] :> {b, r, Xcb, {o}};
o = OptionValue[\[DoubleStruckB], o, {"a", "o"}];

b = RBDGetPositionIndex@Prepend[o, b];
b = Append[b, v];
r = If[IntegerQ[r], Sign[r]I6[[Abs@r]], r];
Xcb = If[VectorQ[Xcb], Xba[PadLeft[Xcb, nm]], Xcb];
r = RBDExpandExpression[r];
Xcb = RBDExpandExpression[Xcb];
AddCon[name, t, n, "b" -> b, "r" -> r, "X" -> Xcb, "rdot" -> rdot, "K" -> {Kp, Kv}];
];


(* ::Input::Initialization:: *)
Options[AddCon] = {"J" :> zq, "\[Phi]" -> z1, "b" -> {}, "r" -> {}, "X" -> {}, "rdot" -> {}, "\[Eta]" -> {z1, z1}, "K" -> {z1, z1}};

AddCon::t = "A constraint in `1` corresponding to row `2` in J is not of type `3`.  It has type `4`.  Row `2` in J will stay type `3`.";

AddCon::K = "Encountered different gain values, (Kp, Kv) = `4`, in constraint `1` corresponding to row `2` in \[Eta].  The gains will remain (Kp, Kv) = `3`.";

AddCon[name_, t_, n_, OptionsPattern[]] := Module[{m, J, \[Phi], \[Eta], J\[Phi]\[Eta], b, r, X, rdot, brX, K},
J\[Phi]\[Eta] = {"J", "\[Phi]", "\[Eta]"};
{J, \[Phi],\[Eta]} = OptionValue[#]& /@ J\[Phi]\[Eta];
J\[Phi]\[Eta] = {J\[Phi]\[Eta], {J, \[Phi], \[Eta]}};

brX = {"b", "r", "X", "rdot"};
If[OptionValue["b"] === {}, 
{b, r, X, rdot} = {{}, {}, {}, {}};, 
{b, r, X, rdot} =  {OptionValue[#]}& /@ brX;
];
brX = {brX, {b, r, X, rdot}};

K = OptionValue["K"];

(* add/update constraint entry *)
Which[
!MissingQ[rb[C, "n", n]],
(* append to old constraint entry *)
m = rb[C, "n", n];
MapThread[(rb[[Key@C, #1, m]] += #2;)&, J\[Phi]\[Eta]];
MapThread[(rb[[Key@C, #1, m]] = Join[rb[[Key@C, #1, m]], #2];)&, brX];
(* are constraints the same type? *)
b = rb[[Key@C, "t", m]];
If[b != t, Message[AddCon::t, name, m, b, t]];
(* are gains the same? *)
b = rb[[Key@C, "K", m]];
If[b =!= K, Message[AddCon::K, name, m, b, K]];,
!MissingQ[rb[C, "n"]],
(* add new entry to constraint *)
MapThread[(rb[[Key@C, #1]] = Join[rb[C, #1], {#2}];)&, J\[Phi]\[Eta]];
rb[C, "t"] = Join[rb[C, "t"], {t}];
rb[C, "K"] = Join[rb[C, "K"], {K}];
m = If[n === Automatic, Max[Keys@rb[C, "n"]]+1, n];
(* map n to actual index in J *)
m = rb[C, "n", m] = Length@rb[C, "J"];
MapThread[(rb[C, #1, m] = #2;)&, brX];,
True,
(* add brand new constraint *)
m = If[n === Automatic, 1, n];
rb[C] = <|"n" -> <|m -> 1|>, "t" -> {t}, "K" -> {K}|>;
AssociateTo[rb[C], MapThread[#1 -> {#2}&, J\[Phi]\[Eta]]];
AssociateTo[rb[C], MapThread[#1 -> <|1 -> #2|>&,  brX]];
];
];


(* ::Input::Initialization:: *)
MakeSparse[x_] := Module[{d},
(* pad ragged arrays to full array for use in Compile *)
d = Map[Dimensions, x, {1}];
d = Prepend[MapThread[Max, d], Length@d];
SparseArray@PadRight[x, d]
];

ConBFunctions[B_:True] := Module[{b, r, X, dot, rdot, Xdot, bo, ba, bs, bx, f},
b = Select[rb[C, "b"], # =!= {}&];
If[B && AssociationQ[b] && Length@b > 0,
r = Values@Select[rb[C, "r"], # =!= {}&];
X = Values@Select[rb[C, "X"], # =!= {}&];
dot = Values@Select[rb[C, "rdot"], # =!= {}&];

(* make X into translation matrix *)
Do[
X[[i, j, 1;;3,1;;3]] = X[[i, j, 4;;6,4;;6]] = I3, 
{i, Length@X}, {j, Length@X[[i]]}
];

(* create dots based on Jdot options *)
f = Table[If[dot[[i, j]], #1[[i, j]], #2], {i, Length@b}, {j, Length@b[[i]]}]&;
rdot = f[r, z6];
Xdot = f[X, Z6];

(* collapse ragged list into one big linear array *)
(* b[i] = {b = body #, a = stopping #, o = o frame, v = velocity constraint if 0, i = con # in J} *)
b = Join@@Table[Join[e, {k}], {k, Keys@b}, {e, b[k]}];
X = Join@@X;
r = Join@@r;
rdot = Join@@rdot;
Xdot = Join@@Xdot;

(* make functions *)
{r, X} = ConvertToXLFunction /@ {r, X};
{rdot, Xdot} = ConvertToXLFunction[#, "dot" -> True][[2]]& /@ {rdot, Xdot};

(* process data *)
(* no point in having body a in a different branch or a child of b *)
f = If[#1 > 0 && #2 > 0 && nca[[#1, #2]] != #2,Message[RBDConstraintFunctions::a, RBDGetValue[#2], RBDGetValue[#1], Root]; 0, (* else *) If[#2 == 0, #2, parent[[#2]]]]&; (* changed else stmt 01/15/2022 *)
(* project a to root if a is not a nearest common ancestor (nca) of b *)
b[[All, 2]] = MapThread[f, b[[All, 1;;2]]\[Transpose]];

(* save computation on matrices used in world to body transforms XL0 *)
(* include b & o frames in bx, ignore all other frames *)
f = DeleteDuplicates /@ Transpose@b[[All, {1, 3}]];
f =GetPath@f;
bs = Sort@DeleteDuplicates@Flatten@f[[1]];
If[bs =!= {}, bs = Rest@bs;];
bx = Sort@DeleteDuplicates@Flatten@f;
If[bx =!= {}, bx = Rest@bx;];

(* w/ b and o can move r to final coordinate *)
bo = b[[All, {1, 3}]];
(* w/ b and a (and i and k) can compute Jacobian w.r.t to # of b's *)
(* i.e., take fewer trips up the chain *)
ba = MapIndexed[Join[##]&, b[[All, {1, 2, 4, 5}]]];
(* ba[i] = {b = body #, a = stopping #, v = velocity constraint if 0, i = con # in J, k = flattened constraint position} *)
(* convert ragged lists into proper tensors *)
ba = Normal@MakeSparse@GatherBy[ba, #[[1;;2]]&];,
(* else *)
r = X= rdot = Xdot = ({}&);
bo = ba = bs = bx = {};
];

<|"r" -> r, "Tcb" -> X, "rdot" -> rdot, "Tcbdot" -> Xdot, "bo" -> bo, "ba" -> ba, "bs" -> bs, "bx" -> bx|>
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]