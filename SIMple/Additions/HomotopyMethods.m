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



(* ::Input::Initialization:: *)
BeginPackage["ContinuationMethods`", {"Options`"}]

Homotopy::usage = "";
hmg::usage = "";
hmcvx::usage = "";

HomotopyPlot::usage = "";
HomotopyMin::usage = "";

Begin["`Private`"]


(* ::Input::Initialization:: *)
hmg[f_, cp_, OptionsPattern[]] := {
Append[cp, 1], 
With[{r0 = SparseArray@f[cp][[1]]},
Module[{c, \[Lambda], R},
c = #1[[;;-2]];
\[Lambda] = #1[[-1]]; (* homotopy parameter *)
(* apply homotopy *)
R = (*SparseArray /@*) f[c];

(* homotopy function *)
R[[1]] = R[[1]] - \[Lambda] r0;
If[Length@R > 1, 
R[[2]] = ArrayFlatten[{{R[[2]], {-r0}\[Transpose]}}];
];
If[Length@R > 2, 
R[[3]] = ArrayPad[R[[3]], {{0, 0}, {0, 1}, {0, 1}}];
];
R
]&
]
};


(* ::Input::Initialization:: *)
hmcvx[{f_, g_}, cp_, OptionsPattern[]] := {
Append[cp, 1], 
Module[{c, o, \[Lambda], F, G, a, s, n},
c = #1[[;;-2]];
\[Lambda] = #1[[-1]]; (* homotopy parameter *)

(* apply homotopy *)
F = SparseArray /@ f[c];
G = SparseArray /@ g[c];

n = Min[Length@F, Length@G];
s = If[n >= #1, #2, Sequence[]]&;

(* homotopy function *)
SparseArray /@ {
(1-\[Lambda])F[[1]] + \[Lambda] G[[1]],

s[2, ArrayFlatten[{{(1-\[Lambda])F[[2]] + \[Lambda] G[[2]], {-F[[1]]+ G[[1]]}\[Transpose]}}]],

s[3, a = ArrayFlatten[{{#1, {#2}\[Transpose]}, {{#2}, 0}}]&;
MapThread[a, {(1-\[Lambda]) F[[3]]+ \[Lambda] G[[3]], -F[[2]] + G[[2]]}]
]
}
]&};


(* ::Input::Initialization:: *)
Options[Homotopy] = {Method -> hmg, Man -> {}, "hm" -> {}, Root -> True};
Homotopy[f_, c_, h_, N_Integer, opts:OptionsPattern[]] := Module[{r, c0, o},
{c0, r} = OptionValue[Method][f, c, OptionValue@"hm"];

If[OptionValue@Root,
(* create indicator function for finding \[Lambda] = 0 in R *)
(* in homotopy continuation of H(x, \[Lambda]) = 0 *)
o = Length@c0;
o = {SparseArray[{{1, o} -> 1.0}, {1, o}], SparseArray[{}, {1, o, o}]};
o = With[{a = o[[1]], b = o[[2]]}, {#[[-1;;-1]], a, b}&];
o = {Method -> cmroot, Monitor -> rootmon, "n" -> Root, "cm" -> {Root -> True, "f" -> o}};,
(* else *)
o = {};
];

(* run continuation *)
r = Man[r, c0, h, N, MergeOpts[OptionValue[Man], o]];

(* parse out homotopy parameter *)
Do[
If[r[k] =!= $Failed,
r[k, "\[Lambda]"] = r[k, "c"][[All, -1;;-1]];
r[k, "c"] = r[k, "c"][[All, 1;;-2]];
],
{k, Keys@r}
];

r
];


(* ::Input::Initialization:: *)
HomotopyPlot[man_, opts:OptionsPattern[]] := ListPlot[Lookup[Values@KeySort@Select[man, # =!= $Failed&], "\[Lambda]"][[All, 1, 1]], opts, Joined->True, AxesOrigin->{0, 0}, PlotRange->All]

HomotopyMin[man_] := MinimalBy[Select[man, # =!= $Failed&], #["\[Lambda]"][[1]]^2&, 2][[All, {"c", "\[Lambda]"}, 1]]


(* ::Input::Initialization:: *)
End[]
EndPackage[]


