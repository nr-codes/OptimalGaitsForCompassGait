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
RigidBodyDerivatives.nb: High-level functions used to define a rigid body.
Copyright (C) 2016 Nelson Rosa Jr.

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
BeginPackage["Derivatives`"]

depth::usage = "";
FixDotProducts::usage = "";
FixLinearSolve::usage = "";

Begin["`Private`"]


(* ::Input::Initialization:: *)
(* clear previous definitions *)
ClearAll@depth;

SetAttributes[depth, {HoldFirst, Listable}];

depth::undef = "`1` is not defined.";
depth[x__] := (Message[depth::undef, HoldForm@x]; {\[Infinity], \[Infinity]});

depth[x_Real] := {0, 0};
depth[x_Integer] := {0, 0};
depth[x_Length] := {0, 0};

depth[(Cos|Sin|Tan)[x_]] := {0, 0};
depth[ArcTan[x_, y_]] := {0, 0};
depth[Power[x_, y_]] := {0, 0};

depth[Transpose[x_, ___]] := depth[x];

depth[HoldPattern@Part[x_, i__]] := Module[{d, c},
d = depth[x];
c = {_Span -> 0, All -> 0, a_ :> If[Total[depth[a]] === 1, 0, 1]};
c = Replace[Hold[i], c, {1}];
c = List@ReleaseHold@c;
(* Total[{1, 0} d] stays unevaluated if d is not a list *)
c = Total[TakeDrop[c, UpTo@Total[{1, 0}d]], {2}];
d - c
];

depth[f_[___]] := depth[f];

depth[Derivative[d__][x_]] := depth[x] + {0, d};
depth[Derivative[d__][f_][x___]] := depth[f[x]] + {0, d};

depth[HoldPattern@Set[y_, x_]] := depth[y] = depth[x];

depth[HoldPattern[Set[x_List , y_]]] := Module[{S, d, n},
n = depth[y] - {1, 0};
SetAttributes[{S, d}, HoldAll];
Fold[S[#2, #1]&, n, Thread@d[x]] /. d -> depth /. S -> Set
];

depth[Dot[x__]] := Module[{d, c},
(* depth[A.B] = depth[A] + depth[B] - 2, for depth[*] > 0 *)
(* update rule: d^n(A).d^m(B) => *)
(* {depth[A.B], depth[d^n(A).d^m(B)] - depth[A.B]} *)
d = depth[{x}];
(* special case of 0 leads to -'ve #s, map -'ve #s back to 0 *)
(*c = Count[d\[LeftDoubleBracket]All, 1\[RightDoubleBracket], _?Positive];*)
c = Count[Flatten@Take[d, All, 1], _?Positive];
c = If[c > 0, c - 1, 0];
Total[d] - {2 c, 0}
];

depth[Times[x__]] := depth[Dot[x]];

depth[Plus[x__]] := First@Select[depth[{x}], VectorQ[#, IntegerQ]&];

depth[Outer[Times, x_, y_]] := depth[x] + depth[y];

depth[Join[x_, ___]] := depth[x];

(* arrived by setting up system of equations from Dot rule *)
depth[LinearSolve[A_, b_]] := depth[b]-depth[A] + {2, 0};
depth[LeastSquares[A_, b_]] := depth[LinearSolve[A, b]];

depth[x_, d_Integer, n_Integer] := Module[{f, X, D, T},
f = ToString@Unevaluated@depth;
X = List@ToString@Unevaluated@x;
X = List@CreateArgumentsString[Evaluate@X, n];
D = {d, #}& /@ Range[0, n];
T = f <> "[" <> #1 <> "] = " <> ToString@#2 <> ";"&;
ToExpression@StringJoin@MapThread[T, {X, D}]
];

depth[\[FormalP][x__]] := depth[x];
depth[Hold[x__]] := depth[x];

depth[Clear] := (DownValues[depth] = depthfuns;);

(* store all default definitions *)
depthfuns = DownValues[depth];


(* ::Input::Initialization:: *)
(* might have to multiply by 1/2 *)
SetAttributes[tensym, HoldAll]
tensym::hess = "Last@depth[`1`] = `2` != 2";
(*tensym[X_] := Module[{m, n},
{m, n} = depth[X];
Which[
m \[Equal] 0 && n \[Equal] 2, X + X\[Transpose],
m \[Equal] 1 && n \[Equal] 2, X + Transpose[X, {1, 3, 2}],
m \[Equal] 2 && n \[Equal] 2, X + Transpose[X, {1, 2, 4, 3}],
True,
Message[tensym::hess, X, n];
Throw[$Failed]
]
]*)

tensym[X_] := Module[{m, n},
{m, n} = depth[X];
Which[
m == 0 && n == 2, 0.5(X + X\[Transpose]),
m == 1 && n == 2, 0.5(X + Transpose[X, {1, 3, 2}]),
m == 2 && n == 2, 0.5(X + Transpose[X, {1, 2, 4, 3}]),
True,
Message[tensym::hess, X, n];
Throw[$Failed]
]
]


(* ::Input::Initialization:: *)
(* assume derivatives are vectors df/dvec(x), f \[Element] {scalar, vector, matrix} *)
tencon::args = "Unknown Tensor(s): `1` (`2`) and/or `3` (`4`)";

tencon[C__] := Fold[tencon, {C}];

tencon[A_, B_] := Module[{m0, md, n0, nd},
{m0, md} = depth[A];
{n0, nd} = depth[B];
Which[
(* scalar *)
m0 == 0 && md == 0, A B,
n0 == 0 && nd == 0, B A,
m0 == 0 && md == 1 && nd == 1, tensym[Outer[Times, B, A]],
n0 == 0 && nd == 1 && md == 1, tensym[Outer[Times, A, B]],
m0 == 0, Outer[Times, B, A],
n0 == 0, Outer[Times, A, B],

(* vector/matrix, m0 > 0 && n0 > 0, but no derivative in A *)
md == 0, A.B,

(* vector *)
m0 == 1 && n0 == 1 && nd == 0, B.A,
m0 == 1 && n0 == 2 && nd == 0, B\[Transpose].A,
m0 == 1 && md == 1 && n0 == 1 && nd == 1, tensym[B\[Transpose].A],
m0 == 1 && md == 1 && n0 == 2 && nd == 1, tensym[(A\[Transpose].B)\[Transpose]],

(* matrix *)
m0 == 2 && n0 == 1 && nd == 0, B.A\[Transpose],
m0 == 2 && n0 == 2 && nd == 0, (B\[Transpose].A\[Transpose])\[Transpose],
m0 == 2 && md == 1 && n0 == 1 && nd == 1, tensym[(B\[Transpose].A\[Transpose])\[Transpose]],
m0 == 2 && md == 1 && n0 == 2 && nd == 1, 
tensym[Transpose[Transpose[A, {2, 3, 1}].B, {3, 1, 2, 4}]],

True,
Message[tencon::args, A, {m0, md}, B, {n0, nd}];
Throw[$Failed]
]
];


(* ::Input::Initialization:: *)
SetAttributes[FixDot, HoldAll]
FixDot[expr__] := BlockExpression[{Outer, Part}, Hold@Evaluate@tencon[expr], {FixDot, tencon}]

(*FixDotProducts[expr_] := Module[{pos, ex, posd, exd, p, f},
f = expr;

(* first pass, assign depth to symbols *)
pos = Position[f, _Set];
ex = Extract[f, pos, Hold];
depth@@@ex;
(* second pass, update dot products and multiplications *)
f = f /. Times \[Rule] Dot;
f = f /. Dot \[Rule] FixDot;
f = f //. x_FixDot \[RuleDelayed] With[{a = x}, a /; True];
f //. Hold[x_] \[RuleDelayed] x
];*)

FixDotProducts[expr_] := Module[{pos, ex, x, i, p, f},
f = expr;

(* first pass, assign depth to symbols *)
pos = Position[f, _Set];
ex = Extract[f, pos, Hold];
depth@@@ex;
(* second pass, update dot products, powers, and multiplications *)

(* for Power, wrap in \[FormalP] and let FixDot remove it later *)
p = Power[x_, i_Integer /; i > 1] :> With[{a = Dot@@Table[\[FormalP][x], i]}, a /; True];
f = f /. p;
f = f /. Times -> Dot;
f = f /. Dot -> FixDot;
f = f //. x_FixDot :> With[{a = x}, a /; True];
f //. Hold[x_] :> x
];


(* ::Input::Initialization:: *)
FixLinearSolve[expr_] := Module[{f, h, j, pos, ex, r, n},
(* assumes FixDotProducts has already been called *)

(* get max derivative order *)
r = HoldPattern[Set[x_, _]] :> DerivativeOrder[x];
n = Max@Cases[expr, r, Infinity];

(* assume A in LinearSolve has depth[A] \[Equal] (2, 0) *)
(* => depth[LinearSolve[A, b]] = depth[b] *)
r = Table[
(* extract LinearSolve with RHS arg of increasing derivative order *)
pos = Position[expr, x_LinearSolve /; Total[depth[x]] == i+2];
ex = Extract[expr, pos, Hold];

(* d = initial transpose, b = final transpose, k = Map depth *)
(* k has Map solve matrix problems, since LinearSolve can't do *) (* higher-order tensors *)
j = Flatten /@ {{i+1, Range[i], i+2}, {Range[2, i+1], 1, i+2}};
h = With[{d = j[[1]], b = j[[2]], k = i}, 
HoldPattern[LinearSolve[A_, B_]] :> Transpose[Map[LinearSolve[A, #]&, Transpose[B, d], {k}], b]
];

(* accumulate transformations *)
ex = ex /. h;
Thread[pos -> ex],
{i, n}
];
(* apply transformations *)
f = ReplacePart[expr, Join@@r];
f /. Hold[x_] :> x
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
