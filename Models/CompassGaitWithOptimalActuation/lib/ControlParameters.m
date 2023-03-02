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

bpn::usage ="";
fpn::usage ="";
Lpn::usage ="";

ParameterName::usage = "";

Begin["`Private`"]


(* ::Input::Initialization:: *)
(* cf path *)
cfpath = "cf/";

(* control input parameters *)
cip = <||>;

(* # of state, time, and control/design parameters *)
nrx = 4; (* # of reduced states *)
nrp = 3; (* # of optimization parameters *)
nru1; (* # of control points *)
nru2; (* # of control points *)
nru; (* # of control points *)
nrt; (* # of switching times *)
nri = 1; (* # of impulses *)

n\[Mu];
ncp;

ti;
ui;
pi;
xi;

(* specific parameters *)
\[Sigma]i;
vi;
Ji;
\[Tau]i;
\[Mu]i;
di;

(* max # of control points *)
(* # of control points > |\[CapitalPhi]| (= {\[Sigma], v} = 2) to satisfy constraints *)
prange = {0, 1, 3};
nrange = {2, 10, 20}; 

bpn = Join@@Table[{BSplineCurve, p, n}, {n, nrange}, {p, prange}];
bpn = Select[bpn, #[[3]] >= #[[2]]&];
fpn = Select[Table[{Fourier, n}, {n, nrange}], EvenQ[#[[2]]]&];
ipn = {False, True};
Lpn = Flatten[Table[{{"a" -> f, "e" -> f, "i" -> i}, {"a" -> b, "e" -> b, "i" -> i}, {"a" -> b, "e" -> f, "i" -> i}, {"a" -> f, "e" -> b, "i" -> i}, {"a" -> f, "e" -> Null, "i" -> i}, {"a" -> b, "e" -> Null, "i" -> i}}, {b, bpn}, {f, fpn}, {i, ipn}], 3]


(* ::Input::Initialization:: *)
ParameterName[] := StringRiffle[{cip["a", "name"], cip["e", "name"], cip["i", "name"]}, "_"];


(* ::Input::Initialization:: *)
updateCheck::poly = "`3`: p = `1`, n = `2` >= 0 && n = `2` >= p = `1`.";

updateCheck::Fourier = "n = `1` is an odd #.  ufun will only compute with the first `1` coefficients, which is the same as setting n = `2`.  Call again with n = `2`.";

updateCheck[Fourier, n_] := Module[{},
If[OddQ[n], 
Message[updateCheck::Fourier, n, n - 1];
Throw@$Failed;
];

If[n < 0,
Message[updateCheck::poly, n, n, Fourier];
Throw@$Failed
];
];

updateCheck[BSplineCurve, p_, n_] := If[n < 0 || p < 0 || n < p,
Message[updateCheck::poly, p, n, BSplineCurve];
Throw@$Failed
];


(* ::Input::Initialization:: *)
updateController::u = "u must either be Fourier|BSplineCurve|Null.";

updateController[{Fourier|"F", n_}]:= Module[{f, name},
updateCheck[Fourier, n];
f = fourier;
name = StringTemplate["F_``"][n];
<|"u" -> Fourier, "p" -> n, "n" -> n, "f" -> f, "name" -> name|>
];

updateController[{BSplineCurve|"B", p_, n_}]:= Module[{f, name},
updateCheck[BSplineCurve, p, n];
f = bspline;
name = StringTemplate["B_``_``"][p, n];
<|"u" -> BSplineCurve, "p" -> p, "n" -> n, "f" -> f, "name" -> name|>
];

updateController[{}|Null|"Z", ___]:= Module[{f, name},
f = 0&;
name = "Z";
<|"u" -> Null, "p" -> -1, "n" -> -1, "f" -> f, "name" -> name|>
];

updateController[__]:= Module[{}, Message[updateController::u]; Throw@$Failed];

updateImpulse[i_] := <|"u" -> I, "p" -> -1, "n" -> If[i, 1, 0], "name" -> If[i, "I", "Z"]|>


(* ::Input::Initialization:: *)
updateFunction[k_] := With[{f = cip[k, "f"], p = cip[k, "p"], n = cip[k, "n"], i = If[k == "a", u1i, u2i]},
f[##1, i, p, n]&
]


(* ::Input::Initialization:: *)
updateParams[opts:OptionsPattern[CompassGait]] := Module[{u, p, n, u1, u2},
cip["a"] = updateController[OptionValue["a"]];
u1 = cip["a", "f"];

cip["e"] = updateController[OptionValue["e"]];
u2 = cip["e", "f"];

cip["i"] = updateImpulse[OptionValue["i"]];

name = {"CG_", ParameterName[], "_"};
name = FileNameJoin[{cfpath, StringJoin[name]}];

(* # of state, time, and control/design parameters *)
(*nrx = 4;*) (* # of reduced states *)
(*nrp = 3;*) (* # of optimization parameters *)

nru1 = cip["a", "n"] + 1;
nru2 = cip["e", "n"] + 1;
nru = nru1 + nru2; (* # of control points *)
nri = 1; (* # of impulses *)

nrt = 1; (* # of switching times *)
n\[Mu] = nru + nri;
ncp = nrx + nrp + n\[Mu] + nrt;

ti = Range[-nrt, -1];
ii = Range[-nri - nrt, -nrt - 1];
u2i = Range[-nru2 - nri - nrt, -nrt -nri - 1];
u1i = Range[-nru1-nru2 - nri - nrt, -nru2 - nrt -nri - 1];
ui = Range[-nru - nri - nrt, -nrt -nri - 1];
pi = Range[nrx + 1, nrx + nrp];
xi = Range[1, nrx];

(* specific parameters *)
\[Sigma]i = pi[[1]];
vi = pi[[2]];
Ji = pi[[3]];
\[Iota]i = ii[[1]];
\[Tau]i = ti[[-1]];
If[cip["i", "n"] > 0, 
di = Join[xi, ui, ii, ti];
\[Mu]i = Join[ui, ii];,
(* else: drop impulse as free parameter *)
di = Join[xi, ui, ti];
\[Mu]i = ui;
];

u1fun = updateFunction["a"];
u2fun = updateFunction["e"];
];


(* ::Input::Initialization:: *)
fourier = Module[{t, T, a, b, f},
t = #1[[1]];
T = #2[[\[Tau]i]];
(* this always pads to an odd number s.t. n + 1 = 7 and n + 1 = 8 *)
(* produce the same series *)
{a, b} = Transpose@Partition[Insert[#2[[#3]], 0, 2], 2];
f = a[[#]] Cos[2\[Pi]/T (# - 1) t] + b[[#]] Sin[2\[Pi]/T (# - 1) t]&;
0.5 a[[1]] + Sum[f[i], {i, 2, Length@a}]
]&;


(* ::Input::Initialization:: *)
ctlpoints[u_] := PadLeft[If[VectorQ[#], #, {#}], nq]& /@ u;

knots[p_, n_] := Module[{c0, c1},
(* uniform, clamped knot vector *)
c0 = ConstantArray[0, p];
c1 = ConstantArray[1, p];
N@Join[c0, Subdivide[0, 1, n - p + 1], c1]
];


(* ::Input::Initialization:: *)
bspline = BipedalLocomotion`Private`Spline[#1[[1]]/#2[[\[Tau]i]], knots[#4, #5], #2[[#3]]]&;


(* ::Input::Initialization:: *)
u1fun = 0&;
u2fun = 0&;

cip["u"] = <|
"right" -> (PadLeft[{u1fun@##, u1fun@## + u2fun@##}, nq]&),
"left" -> (PadLeft[{u1fun@##, u2fun@##}, nq]&)
|>;

ufun = cip["u", "left"];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
