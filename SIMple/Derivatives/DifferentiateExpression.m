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

Df::usage = "";
DfToFunction::usage = "";
DfToCompiledFunction::usage = "";

Begin["`Private`"]


(* ::Input::Initialization:: *)
DfToFunction[f_, v_] := MapIndexed[DfToFunction[#1, v, #2[[1]]-1]&, f];

DfToFunction[expr_, v_List, n_Integer] := Module[{a, u, m},
a = Flatten[List@CreateArguments[{#}, n]& /@ v[[All, 1]]];
u = Dispatch@Thread[a -> (Slot /@ Range[1, Length@a])];
a = Dispatch[#[i__] :>  #[[i]]& /@ a];
Function@expr /.a /. u /. Hold[m_] :> m /.  C[m_] :> m
];

DfToFunction[expr_, v_List, n_Integer, t_, o:OptionsPattern[]] := DfToCompiledFunction[expr, v, n, t, o];


(* ::Input::Initialization:: *)
DfToCompiledFunction[f_, v_, t_:_Real, o:OptionsPattern[]] := MapIndexed[DfToCompiledFunction[#1, v, #2[[1]]-1, t, o]&, f];

DfToCompiledFunction[expr_, v_List, n_Integer, t_:_Real, o:OptionsPattern[Compile]] := Module[{a, f, g, e},
(* get args *)
a = Flatten[List@CreateArguments[{#}, n]& /@ v[[All, 1]]];

(* replace x[] w/ x\[LeftDoubleBracket]\[RightDoubleBracket] and removes Hold and C from Df[..., "ch"] *)
e = Dispatch[#[i__] :>  #[[i]]& /@ a];
e = \[FormalP][a, expr, o] /. e  /. Hold[m_] :> m /. C[m_] :> m;

(* create args for compile: {{vi, ui, len(vi)}} *)
g = If[VectorQ[v[[#2[[1]], 2]]], Length@v[[#2[[1]], 2]], 1]+#2[[2]]-1&;
f = Join[#1, {If[VectorQ[t], t[[#2[[1]]]], t], g[##]}]&;
a = ArrayReshape[a, {Length@v, n+1, 1}];
a = Join@@MapIndexed[f, a, {2}];

(* compile *)
e /. HoldPattern[a] :> Evaluate@a /. \[FormalP] -> Compile
];


(* ::Input::Initialization:: *)
Options[Df] = {D -> 2, Simplify -> False, N -> Automatic}; (* max for D is 2 *)
Df::zero = "Cannot differentiate.  There exist variables with zero length: ``";

Df[f_Function, x_, opts:OptionsPattern[]] := Module[{e},
(* create args and func *)
e = Df[x, "args", D-> 0];
e = f[Sequence@@e[[All, 1]]];
Df[e, x, opts]
];

Df[expr_, x_, opts:OptionsPattern[]] := Module[{e, f, n, v, F, J, H},
n = OptionValue[D];
(* if x has a var w/ zero parameters D crashes MMA *)
v = Or@@PossibleZeroQ@Flatten@x[[All, 2]];
If[v, Message[Df::zero, x]; Throw[$Failed];];

(* regular simplify does not execute in reasonable amount of time *)
e = expr //. {HoldPattern[a___ + (0.|0) + b___] :> (a+b), HoldPattern[a___ * (1.|1) * b___] :> (a*b)};

(* get vectorized derivatives v = {{x[1], dx[1], ddx[1], ..}, ..} *)
v = Df[x, "vec", opts];

(* compute derivatives 1..n *)
F = Table[D[e, {i, j}], {i, v[[All, 1]]}, {j, n}];
F = {F, v[[All, 2;;n+1]]};

J = Df[F, "J", opts];
H = Df[F, "H", opts];

F = {e, J, H}[[1;;n+1]];
If[OptionValue[Simplify], 
v = Element[#, Reals]& /@ Flatten@v;
Simplify[F, Assumptions-> v], 
F
]
];


(* ::Input::Initialization:: *)
Df::D = "Maximum value for D is 2.  It's currently ``.  Errors are likely.";
Df[v_, N, opts:OptionsPattern[]] := Module[{n},
n = OptionValue[D];
If[n > 2 || n < 0, Message[Df::D, n]];

n = OptionValue[N]; (* # of variables to diff w.r.t *)
If[n === Automatic, Total[Times@@@v[[All, 2]]], n]
]


(* ::Input::Initialization:: *)
Df[v_, "args", opts:OptionsPattern[]] := Module[{n, m, d, u, nd},
n = OptionValue[D];
nd = Df[v, N, opts];
u = List@CreateArguments[{#}, n]& /@ v[[All, 1]];
d = If[VectorQ[#], #, {#}]& /@ v[[All, 2]];

Table[
m = Length@d[[i]];
m = PadRight[d[[i]], {m+j}, nd];
Array[u[[i, j+1]], m], 
{i, Length@v}, {j, 0, n}
]
];

Df[v_, "vec", opts:OptionsPattern[]] := Module[{n, m, d, u, nd},
m = Length@v;
n = OptionValue[D];
nd = Df[v, N, opts];
u = Df[v, "args", opts, N -> nd];

(* vectorize derivatives *)
Table[
d = Times@@v[[i, 2]];
d = PadRight[{d}, j, nd];
ArrayReshape[u[[i, j]], d], 
{i, m}, {j, n+1}
]
];


(* ::Input::Initialization:: *)
Df[F_, "J", opts:OptionsPattern[]] := Module[{J, d},
(* chain rule Jacobian: df/dx dx/dc *)
(* F = {{df/dx1, ..., df/dxn}, {dx1/dc, ..., dxn/dc}} *)
J = If[MemberQ[Join[#1[[1;;1]], #2[[1;;1]]], {}], {}, #1[[1]].#2[[1]]]&;
If[OptionValue[D] >= 1, Plus@@MapThread[J, F],{}]
];

Df[F_, "H", opts:OptionsPattern[]] := Module[{H, t, d, h},
(* chain rule Hessian: (dx/dc)\[Transpose].d^2f/dx^2.(dx/dc) + (df/dx).d^2x/dc^2  *)
(* F = {{{df/dx, d^2f/dx^2}, ..}, {{dx/dc, d^2x/dc^2}, ..}} *)
d = ArrayDepth;
t = Transpose[#1, Join[Range[1, #2-2], {#2, #2 - 1}]]&;
h = t[t[#1[[2]].#2[[1]], d[#1[[2]]]].#2[[1]], d[#1[[2]]]]+ #1[[1]].#2[[2]]&;
H = If[MemberQ[Join[#1[[1;;2]], #2[[1;;2]]], {}], {}, h@##]&;
If[OptionValue[D] >= 2, Plus@@MapThread[H, F], {}]
];


(* ::Input::Initialization:: *)
Df::i = "An index is out of bounds: `1` <= `2` ";
Df[F_, "i", opts:OptionsPattern[]] := Module[{n ,N},
(* multi-index {i, j, ..} into linear index k *)
(* A[i, j, ...] \[Rule] vec(A)[k] *)
{n, N} = F;
Which[
MemberQ[Thread[1 <= n <= N], False], Message[Df::i, n ,N]; Throw[$Failed],
Length@n == 0, n, 
True,
Sum[(n[[i]]-1) Times@@N[[i+1;;]], {i, Length[n]-1}] + n[[-1]]
]
];


(* ::Input::Initialization:: *)
Df[F_, "ch", opts:OptionsPattern[]] := Module[{e, f0, f, m, u, d, J, H, n, r},
(* chain rule with symbols *)
(* F = {{f1, ..., fn}, {v1, ..., vm}}, where fi is a vector *)
f0 = First@Df[#, F[[2]], D-> 0, opts]& /@ F[[1]];
n = OptionValue[D];
If[n > 0,
f = Total[
Table[
(* take partial derivative df/dv *)
m = Times@@v[[2]];
e = Df[f, {v}, N -> m, opts];

(* we now have df/dv dv/dc, let dv/dc = dv/dv *)
(* do this by declaring rules to zero out non-diagonal terms *)
(* and set diagonal terms to 1 *)
u = List@CreateArguments[Evaluate@{v[[1]]}, n];

r = #[__Integer] -> 0& /@ u[[2;;n+1]];
r = Prepend[r, u[[2]][i__Integer, j_Integer] /; Df[{{i}, v[[2]]}, "i", opts] == j -> 1];

d = {{e[[2;;n+1]] /. r}, {u[[2;;n+1]]}};
(* hacky workaround to avoid errors from Partition and Flatten *)
(* would like to keep these functions in unevaluated state while *)
(* maintaining rule that resulting expressions don't need to be held *)
(* DfToFunction removes hold? *)

J = Df[d, "J", opts];
H = Df[d, "H", opts];

If[Length@v[[2]] > 1, 
(* variable C has attribute NHoldAll *)
J = J /. u[[2]] -> \[FormalX];
J = With[{a = J, b = u[[2]]},
Hold@Block[{\[FormalX]}, 
\[FormalX] = Partition[Flatten[b], Dimensions[b][[-1]]];
a
]
];

If[n >= 2,
H = H /. {u[[2]] -> \[FormalX], u[[3]] -> \[FormalY]};
H = With[{a = H, b = u[[2]], c = u[[3]]}, 
Hold@Block[{\[FormalX], \[FormalY]}, 
\[FormalX] = Partition[Flatten[c], Dimensions[c][[-1]]];
\[FormalY] = Partition[\[FormalX], Dimensions[c][[-2]]];
\[FormalX] = Partition[Flatten[b], Dimensions[b][[-1]]];
a
]
];
];
];
{J, H}[[1;;n]],
{f, f0}, {v, F[[2]]}
],
{2}
];
Join[{f0}, f\[Transpose]]\[Transpose],
(* else *)
{f0}\[Transpose]
]
(* returns {{f1, df1/dv1 dv1/dc + .., d^2f1/dv1^2 d^2v1/dc^2 + ..}, ..} *)
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
