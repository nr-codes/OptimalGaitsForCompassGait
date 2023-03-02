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
BeginPackage["BipedalLocomotion`CompassGait`", {"GlobalVariables`", "RigidBodyDynamics`", "HybridDynamics`", "BipedalLocomotion`", "BipedalLocomotion`Model`"}]

CompassGaitOpt::usage = "";
CompassGaitPad::usage = "";
GetOptimalMap::usage = "";

CompassGaitSim::usage = "";
CompassGaitMap::usage = "";

Tcrit::usage = "";

Begin["`Private`"]

Tcrit = {0.6241588101929673,0.6846501213593296} / tscale;


(* ::Input::Initialization:: *)
\[CurlyPhi]opt = {"fs"-> {"ExplicitRungeKutta", "DifferenceOrder" -> 4, "Coefficients" -> "EmbeddedExplicitRungeKuttaCoefficients"}, "n" -> 30};

CompassGaitSim[c_, opts:OptionsPattern[BLSim]] := CompassGaitSim[BLbiped["m[0]"], c, opts];

CompassGaitSim[m_, c_, opts:OptionsPattern[BLSim]] := SplineSim[m, If[Length@c == ncp, c[[di]], c], opts, "\[CurlyPhi]" -> \[CurlyPhi]opt, "p" -> 0];

P[cp_, opts:OptionsPattern[]] := P[BLbiped["m[0]"], cp, opts]["R"];

(* the returned map for BLP returns "p" \[Rule] cp and not "p" \[Rule] cp\[LeftDoubleBracket]di\[RightDoubleBracket] *)
P[mp_, cp_, opts: OptionsPattern[]] := BLP[mp, cp, opts, BLSim -> CompassGaitSim]; 

CompassGaitMap = P[BLbiped["m[0]"], ##]&;


(* ::Input::Initialization:: *)
Ip := IdentityMatrix[ncp];

\[CapitalPhi]p[p_, i_, c_] := {{c[[i]] - p}, Ip[[{i}]]};

\[CapitalPhi]\[Sigma][\[Sigma]_, M_] := Module[{S},
S = BLSlope[M, "\[Sigma]" -> None];
S[[1]] = BLAngle[S[[1]] - \[Sigma]];
S
];

\[CapitalPhi]v[v_, M_] := BLV\[Sigma][M, "v" -> v];

\[CapitalPhi]J[J_, M_] := Module[{F, I, \[Tau]},
\[Tau] = M["c"][[1, 1, \[Tau]i]];
I = BLFunc["\[Iota]^2", \[Tau], M];
F = M["a-"][[-1]] + I;
F[[1]] = F[[1]] - J;
SparseArray /@ F
];

pad[R_] := Module[{J, Jcp, i},
i = Join[xi, \[Mu]i, ti];
J = R[[2]];
Jcp = ConstantArray[0.0, {Length@J, ncp}];
Jcp[[All, i]] = J;
{R[[1]], Jcp}
];

pad[cp_ , opt_, p_, i_, P_] := Module[{R},
If[NumericQ[opt], 
\[CapitalPhi]p[p, i, cp],
R = pad@P[[1;;2]];
R[[2, 1, i]] = -1;
R
]
]


(* ::Input::Initialization:: *)
(* pads unactuated gaits w/ {s, v, J, I} and min coords to their padded coords *)
CompassGaitPad[c_, OptionsPattern[CompassGaitOpt]] := Module[{M, \[Sigma], v, J, u,cp, m},
m = BLbiped["m[0]"];
cp = If[NumericQ[c], BLbiped["\[DoubleStruckC]", m, "eq"][c], c];

Which[
(* already padded, nothing to do *)
Length@cp == ncp,
cp,

(* unactuated gait *)
Length@cp > nrx + nrp + 1 && PossibleZeroQ[Norm[cp[[nrx + nrp+1;;-2]]]],
Join[cp[[xi]], cp[[pi]], ConstantArray[0.0, Length@ui], cp[[ii]], cp[[ti]]],

(* else min. coord gait *)
True,
M = P[m, cp, OptionValue[BLP]];

\[Sigma] = OptionValue["\[Sigma]"];
If[!NumericQ[\[Sigma]], \[Sigma] = \[CapitalPhi]\[Sigma][0, M][[1, 1]]];

v = OptionValue["v"];
If[!NumericQ[v], v = \[CapitalPhi]v[0, M][[1, 1]]];

J = OptionValue["J"];
If[!NumericQ[J], J = \[CapitalPhi]J[0, M][[1, 1]]];

u = If[cip["i", "n"] > 0, cp[[\[Mu]i]], Join[cp[[\[Mu]i+1]], {0.0}]];

Join[cp[[xi]], {\[Sigma], v, J}, u, cp[[ti]]]
]
];


(* ::Input::Initialization:: *)
Options[CompassGaitOpt] = {"\[Sigma]" -> True, "v" -> True, "J" -> False, "oc" -> True, BLP -> {}};

CompassGaitOpt[cp_, opts:OptionsPattern[]] := CompassGaitOpt[BLbiped["m[0]"], cp, opts]["R"];

CompassGaitOpt[mp_String, cp_, opts:OptionsPattern[]] := Module[{M, S, V, F, I, a, nopt, \[Sigma]opt, vopt, Jopt, \[Iota]opt, \[Sigma], v, J, \[Iota], R, j},
nopt = Length@cp == ncp;
M = P[mp, cp, OptionValue[BLP]];

(* get parameters: if given, take value, else index value, else compute value *)
\[Sigma]opt = OptionValue["\[Sigma]"];
\[Sigma] = If[NumericQ[\[Sigma]opt], \[Sigma]opt, If[nopt, cp[[\[Sigma]i]], \[CapitalPhi]\[Sigma][0, M][[1, 1]]]];

vopt = OptionValue["v"];
v = If[NumericQ[vopt], vopt, If[nopt, cp[[vi]], \[CapitalPhi]v[0, M][[1, 1]]]];

Jopt = OptionValue["J"];
J = If[NumericQ[Jopt], Jopt, If[nopt, cp[[Ji]], \[CapitalPhi]J[0, M][[1, 1]]]];

(* compute additional constraints *)
S = \[CapitalPhi]\[Sigma][\[Sigma], M];
V = \[CapitalPhi]v[v, M];
F = \[CapitalPhi]J[J, M];

(* optimize *)
a = If[#1 =!= False, #2, Unevaluated@Sequence[]]&;
(*
M\[LeftDoubleBracket]1\[RightDoubleBracket] = (P(c), \[CapitalPhi]opt(c), dJ/dc dc/ds, \[CapitalPhi]params(c)) = (gait constraints, optimality conditions, parameter constraints)
*)

R = Sequence[a[\[Sigma]opt, S], a[vopt, V], a[Jopt, F]];
If[OptionValue["oc"],
M = OptimalityConstraints[F, M, R, False, All];,
(* else do not optimize *)
M["R"] = MapThread[Join, Normal@{M["R"], R}];
];

(* pad *)
If[nopt,
R = pad@M["R"];
j = 5;
If[\[Sigma]opt =!= False, R[[2, j++, \[Sigma]i]] = -1;];
If[vopt =!= False, R[[2, j++, vi]] = -1;];
If[Jopt =!= False, R[[2, j++, Ji]] = -1;];

S = pad[cp , \[Sigma]opt, \[Sigma], \[Sigma]i, S];
V = pad[cp , vopt, v, vi, V];
F = pad[cp , Jopt, J, Ji, F];

\[Iota]opt = cip["i", "n"] > 0;
I = pad[cp , 0, 0.0, \[Iota]i, {}];

a = If[#1 =!= True, #2, Unevaluated@Sequence[]]&;
M["R"] = MapThread[Join, {R, a[\[Sigma]opt, S], a[vopt, V], a[Jopt, F], a[\[Iota]opt, I]}];
];

(* return *)
M
];


(* ::Input::Initialization:: *)
GetOptimalMap[s_, cp_] := Module[{c},
c = CompassGaitPad[cp];
Switch[s, 
"g", CompassGaitOpt[##, {"\[Sigma]" -> False, "v" -> False, "J" -> False}]&, 
"v", With[{v = c[[vi]]}, CompassGaitOpt[##, {"v" -> v}]&],
"\[Sigma]", With[{\[Sigma] = c[[\[Sigma]i]]}, CompassGaitOpt[##, {"\[Sigma]" -> \[Sigma]}]&],
"J", With[{J = c[[Ji]]}, CompassGaitOpt[##, {"J" -> J}]&],
_, s
]
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
