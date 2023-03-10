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
BeginPackage["BipedalLocomotion`", {"GlobalVariables`", "RigidBodyDynamics`", "HybridDynamics`", "BipedalLocomotion`Model`"}]

Begin["`Private`"]


(* ::Input::Initialization:: *)
Options[BLFunc] = {"i" -> All, "M" -> BLSim, "n" -> Automatic};

BLFunc[f_, x_, c_, OptionsPattern[]] := Module[{fm, xm, cm, n},
fm = If[VectorQ[f], BLbiped@@f, f];
xm = If[VectorQ[x], devec[x], x];
cm = If[VectorQ[c], devec[c], c];
n = OptionValue["n"];
If[n === Automatic, n = Sequence[];];
devec[fm[xm, cm], n][[All, OptionValue["i"]]]
];

BLFunc[f_, t_?NumericQ, c_?VectorQ, opts:OptionsPattern[]] := BLFunc[f, t, OptionValue["M"][c], opts];

BLFunc[k_String, t_?NumericQ, M_Association, opts:OptionsPattern[]] := BLFunc[{k, M["m[t]"][t]}, t, M, opts];

BLFunc[f_, t_?NumericQ, M_Association, opts:OptionsPattern[]] := BLFunc[f, M["x[t]"][t], M["c[t]"][t], opts];


(* ::Input::Initialization:: *)
Options[BLApplyBounds2] = {BLMap -> {}, "dT" -> 1, "M" -> BLSim};

BLApplyBounds2[t_?NumericQ, M_, f_, b_] := Module[{v0, v, i, l, u},
i = b[[All, 1]];
l = b[[All, 2 ,1]];
u = b[[All, 2 ,2]];

v = BLFunc[f, t, M, "i" -> i]\[Transpose]; (* note the transpose!!! *)
v0 = 0 v[[1]]; (* allocate to # of derivatives and elements *)
v = MapThread[If[#1 <= #2[[1]] <= #3, v0, #2]&, {l, v, u}];

v0[[1]] = 1; (* this is time t in order to capture switches *)
Prepend[v, v0]\[Transpose]
];

BLApplyBounds2[M_, fcn_, bnds_, opts:OptionsPattern[]] := Module[{m0, f, h, d, m, r, n, b, t0, tf, z, c},
r = HybridDynamics`Private`rbd;
n = nx;
b = Block[{nx = n, HybridDynamics`Private`rbd = r}, Flatten@BLApplyBounds2[#1, M, fcn, bnds]]&;

(* need to separate switching times from BLSim/BLMap functions *)
t0 = M["T"][[1]];
tf = M["T"][[-1]];
(*z = Module[{v = Dimensions@#}, v + PadRight[{1}, Length@v]]&;*)
(*z = ConstantArray[0, z@#]& /@ b[t0];*)
z = 0 BLApplyBounds2[0, M, fcn, bnds];
z[[1, 1]] = t0;

(* this can be generalized to take in all modes *)
m0 = M["m"][[1]];
f = <|m0 -> (b[Min[#1[[1,1]], tf]]&)|>;
h = <|m0 -> (#1&)|>;
d = <|m0 -> (#2&)|>;
m = <|m0 -> (m0&)|>;

c = Flatten@M["c"][[1]];

(* add option to return M based on f or just "x-" *)
Block[{nx, BLmxcp, HybridDynamics`Private`rbd},
nx = Length@z[[1]];
BLmxcp = {m0, Flatten@z, c}&;
HybridDynamics`Private`rbd = <|"f" -> f, "h" -> h, "m" -> m, "d" -> d|>;
devec[OptionValue["M"][c]["x-"][[-1]]][[All, 2;;]]
]
];


(* ::Input::Initialization:: *)
BLApplyBoundsAux[m_, x_, c_, f_, b_, opts:OptionsPattern[]] := Module[{v0, v, i, l, u},
i = b[[All, 1]];
l = b[[All, 2 ,1]];
u = b[[All, 2 ,2]];

v = BLFunc[{f, m}, x, c, "i" -> i, opts]\[Transpose]; (* note the transpose!!! *)
v0 = 0 v[[1]]; (* allocate to # of derivatives and elements *)
MapThread[If[#1 <= #2[[1]] <= #3, v0, #2]&, {l, v, u}]\[Transpose]
];

BLApplyBoundsAux[fcn_, bnds_, opts:OptionsPattern[]] := Module[{A, f, h, t0, z},
f = With[{m = #}, Flatten@BLApplyBoundsAux[m, ##1, fcn, bnds, opts]&]&;
z = With[{m = #}, 0.0Flatten@BLApplyBoundsAux[m, ##1, fcn, bnds, opts]&]&;
A = {"f" -> (# -> f[#]), "h"  -> (# -> z[#]), "t0"  -> (# -> z[#])}& /@ Keys@BLbiped["m"];
A = Merge[A, Association];
\[CurlyPhi]aux[A]
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
