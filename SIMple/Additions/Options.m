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
BeginPackage["Options`"]
Begin["`Private`"]


(* ::Input::Initialization:: *)
MergeOpts[new_, old_] := MergeOpts[{new, old}];
MergeOpts[opts_] := Module[{f},
f = MatchQ[_Rule];
If[VectorQ[Flatten@opts, f], Normal@Merge[opts, MergeOpts], opts[[1]]]
];


(* ::Input::Initialization:: *)
ComputeBounds[v_, b_, m_:False] := Module[{f, a, i, l, u},
i = b[[All, 1]];
l = b[[All, 2 ,1]];
u = b[[All, 2 ,2]];
f = Which[#2 < #1, #1, #2 > #3, #3, True, #2]&;
a = v;
a[[i]] = MapThread[f, {l, v[[i]], u}];

If[m, 
f = Which[#2 < #1, 1, #2 > #3, 3, True, 2]&;
f = GroupBy[{i, MapThread[f, {l, v[[i]], u}]}\[Transpose], Last][[All, All, 1]];
f = Lookup[f, #, {}]& /@ Range@3;
Print["    bounds: {<, >, *} ", f];
];

a
];


(* ::Input::Initialization:: *)
SetAttributes[Timer, HoldFirst];
timlst = {};
Timer[x_, f_, n_] := Module[{s, t,r},
PrependTo[timlst, ToString@Unevaluated@n <> " in " <> ToString@Unevaluated@f];
{t, r} = AbsoluteTiming[x];
s = First@timlst;
timlst = Rest@timlst;
Print["\t", s, " took " <> ToString@NumberForm[t, {4,3}] <> " seconds."];
r
];


(* ::Input::Initialization:: *)
Sparse[A_] := If[Length@A > 2, Join[A[[1;;2]], SparseArray /@ A[[3;;]]], A];


(* ::Input::Initialization:: *)
End[]
EndPackage[]


