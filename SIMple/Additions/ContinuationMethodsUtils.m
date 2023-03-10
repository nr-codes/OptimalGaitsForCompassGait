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
ContinuationMethods.nb: An implementation of various continuation methods.
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
BeginPackage["ContinuationMethods`"]
Begin["`Private`"]


(* ::Input::Initialization:: *)
(* stopping criterion for adaptive step size *)
(*htol = 10^-10;
{kder, dder, ader} = {3.0, 0.5, 0.05};*)


(* ::Input::Initialization:: *)
augment[c_, R_, C0_, h_] := Module[{o, k, n, Z}, 
o = Length@R;
k = dim[C0];
n = Length@c;
Z = ConstantArray[0.0, {k, n, n}];
MapThread[Join, {R, {C0[[2]]\[Transpose].(c-C0[[1]]) - h, C0[[2]]\[Transpose], Z}[[1;;o]]}]
];

augment[c_, R_, C0_, h_, Raug_] := Module[{k, R0}, 
k = Length@h;
R0 = Raug;
R0[[All, 1;;-k-1]] = R;
R0[[1, -k;;-1]] = C0[[2]]\[Transpose].(c-C0[[1]]) - h;
R0
];


(* ::Input::Initialization:: *)
Clear@ns; (* original signature is more specific *)

Options[ns] = Join[Options@NullSpace, {"A" ->  All}];

ns::tangent = "The tangent space at the current point might be empty.  Check tolerances or point.";

ns[R_, U0_, opts:OptionsPattern[]] := Module[{U, A, o},
A = OptionValue@"A";
o = FilterRules[{opts}, Options@NullSpace];
U = If[MatrixQ[A], NullSpace[Join[R[[2]], A], o], NullSpace[R[[2]], o][[A]]];

If[U =!= {}, 
U = U\[Transpose];,
(* else *)
Message[ns::tangent];
Throw@$Failed;
];

If[dim[U0] == 0 || dim[U0] != dim[U], U, orientation[U, U0]]
];

(*Options[nsinit] = Join[Options@NullSpace, {"A" \[Rule]  {}}];
nsinit[R_, {}, opts:OptionsPattern[]] := Module[{A, o}, 
A = OptionValue@"A";
o = FilterRules[{opts}, Options@NullSpace];
Print["U0: ", A];
If[A === {} || MatrixQ[A], 
NullSpace[Join[R\[LeftDoubleBracket]2\[RightDoubleBracket], A], o]\[Transpose], 
(* else *)
NullSpace[R\[LeftDoubleBracket]2\[RightDoubleBracket], o]\[LeftDoubleBracket]A\[RightDoubleBracket]\[Transpose]
]
];*)

orientmf[U_, U0_] := Module[{Q},
(* moving frame algorithm *)
Q = SingularValueDecomposition[U\[Transpose].U0];
Q = Q[[1]].Q[[3]]\[Transpose];
(*Print["Det[Q] = ", Det[Q], " ", Det[U\[Transpose].U0]];*)
U.Q
];

(*nsmulti::nosol = "The Jacobian and reference frame are linearly dependent.  Cannot compute tangent space.";

nsmulti[R_, U0_, opts:OptionsPattern[]] := Module[{m, k, A, B},
(* fast moving frame algorithm with no NullSpace call *)
m = Length[R\[LeftDoubleBracket]2\[RightDoubleBracket]];
k = Length[U0\[Transpose]];
A = Join[R\[LeftDoubleBracket]2\[RightDoubleBracket], U0\[Transpose]];
If[PossibleZeroQ@Det[A],
Message[nsmulti::nosol];
Throw@$Failed,
(* else *)
B = Join[ConstantArray[0.0, {m, k}], IdentityMatrix[k]];
Transpose@Orthogonalize@Transpose@LinearSolve[A, B]
]
];*)

orientcurve[U_, U0_] := If[Det[U\[Transpose].U0] < 0, -U, U];


(* ::Input::Initialization:: *)
mand[c_, R_, U0_, opts:OptionsPattern[]] := Module[{o, k, n, m, cd, cdd, A, B},
(* compute {c, dc/ds, d^2c/ds^2} *)
cd = ns[R, U0, opts];

o = Length@R;
m = Length@R[[1]];
{n, k} = Dimensions[cd];
If[o <= 2 || n - m != k, 
{c, cd}, 
(* else *)
A = Join[R[[2]], cd\[Transpose]];
B = Join[-(cd\[Transpose].R[[3]]\[Transpose])\[Transpose].cd, ConstantArray[0.0, {k, k, k}]];
cdd = LinearSolve[A, ArrayReshape[B, {n, k^2}]];

{c, cd, ArrayReshape[cdd, {n, k, k}]}
]
];


(* ::Input::Initialization:: *)
predictor[C0_, d_] := Sum[Nest[Dot[#, d]&, C0[[i]], i - 1]/(i-1)!,  {i, Length@C0}];


(* ::Input::Initialization:: *)
rframe[Man_, z_, z0_] := Module[{r, U0},
If[KeyExistsQ[Man[z0], "rf"],
(* try on circle test; it fails and bounces around *)
(*r = Man[z0, "rf"];*) (* TrM cannot become orthogonal to TzM (??) *)
r = z0;
{z0, Man[r, "c"][[2]]},
(* else *)
{z, {}}
]
];


(* ::Input::Initialization:: *)
(*data::dir = "Cannot determine indices for subspace of `1` given Man[`2`, \"d\"] = `3`.";*)

Options[data] = {"ns" -> {}}; 
data[Man_, z_, z0_, c_, R_, A_:<||>, OptionsPattern[]] := Module[{h, r, k0, d, U0, C, k},
h = Man[z0, "h"];
{r, U0} = rframe[Man, z, z0];
k0 = dim[U0];

C = mand[c, R, U0, OptionValue@"ns"];
(*b = Det[Join[R\[LeftDoubleBracket]2\[RightDoubleBracket], C\[LeftDoubleBracket]2\[RightDoubleBracket]\[Transpose]]]; SVD?*)

k = dim[C];
If[k != k0, r = z;];

(* figure out which dimension z is part of *)
d = Man[z0, "d"];
U0 = Abs[embed[z] - embed[z0]];
(* assume we are moving in 1D at z0 along z - z0 *)
If[k < k0, d = Pick[d, U0, _?(!PossibleZeroQ[#]&)]];
(*(* local dim(z) = k should be greater than # of indices *)
(* we've identified for z's subspace.  k > Length[d] => bifurcation *)
If[k < Length[d], 
Message[data::dir, z, z0, d];
Throw@$Failed;
];*)

(* only need c, h, and d for continuation *)
d = <|"c" -> C, "h" -> h, "d" -> d, "rf" -> r, "z0" -> z0|>;
Join[d, A]
];


(* ::Input::Initialization:: *)
BifurcationPointTest::args = "Requires second-order derivative for test.";
Options[BifurcationPointTest] = {"S" -> {}, "P" -> {}}
BifurcationPointTest[R_, OptionsPattern[]] := Module[{S, P, B},
If[Length@R < 3, 
Message[BifurcationPointTest::args];,
(* else *)
S = NullSpace[R[[2]], OptionValue@"S"];
P = NullSpace[R[[2]]\[Transpose], OptionValue@"P"];
B = P[[1]].R[[3]];
B = S.B.S\[Transpose];
(* does S span the tangent space? *)
{Det[B](* \[NotEqual] 0*), B}
]
];


(* ::Input::Initialization:: *)
(* lifts up to k and projects down to d *)
(* z, z0 is a vector in the subspace *)
(* p is a direction (free vector) in the subspace *)
project[Man_, z_, z0_] := Module[{d},
d = Man[z0, "d"];
z[[d]] - embed[z0][[d]]
]


(* ::Input::Initialization:: *)
embed::subspace = "Cannot embed directions `` in dimensions ``";
embed[Man_, z_, p_] := embed[z] + embed[p, Man[z, "d"]];

embed[p_, d_] := If[k > 0 && Length[d] >= Length[p], Normal@SparseArray[Thread[d[[1;;Length@p]] -> p], k], 
Message[embed::subspace, p, d];
Throw@$Failed
];

embed[z_] := If[k > 0, PadRight[Flatten[{z}], k], z];

dim[Man_, z_] := dim[Man[z, "c"]]
dim[{c_?VectorQ, cd_?MatrixQ, ___?TensorQ}] := dim[cd];
dim[C_] := If[C === {}, 0, Length[C\[Transpose]]];


(* ::Input::Initialization:: *)
End[]
EndPackage[]



