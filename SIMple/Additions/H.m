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
Options[BLApplyBounds] = {"xa" -> False, NDSolve -> {}, "t0+" -> $MachineEpsilon, "tf-" -> $MachineEpsilon, "dT" -> 1};

BLApplyBounds::T = "Simulation terminated early.  NDSolve evaluated at: `1` should have gone until `2`.";

BLApplyBounds[bnds_] := Module[{A},
(* only returns bounds with finite values *)
A = {{#[[1]], "l", #[[2, 1]]}, {#[[1]], "u", #[[2, 2]]}}& /@ bnds;
Select[Flatten[A, 1], NumericQ[#[[3]]]&]
];

BLApplyBounds[f_, bnds_, T_, opts:OptionsPattern[]] := BLApplyBounds[f, bnds, {0, T}, opts]

BLApplyBounds[f_, bnds_, {T0_, T_}, opts:OptionsPattern[]] := Module[{t0, tf, dt, c0, f0, eqn, evt, i, t, d, var, A, b, sol, g, ndopt},
(* assume: f = f[t_?NumberQ, i_] *)

t0 = T0 + OptionValue["t0+"];
tf = T - OptionValue["tf-"];
(* correct for derivatives that don't go until next switching time *)
(* dT * Tswitch ... and apply Leibniz's Rule *)
dt = OptionValue["dT"];

ndopt = OptionValue[NDSolve];
g[fi_?VectorQ, b_] := Join[fi[[1;;1]] - b, fi[[2;;-1]]];

Block[{\[DoubleStruckX], \[DoubleStruckC], \[DoubleStruckT]},
(* {i, type, val} *)
A = BLApplyBounds[bnds];
A = Table[
{i, t, b} = A[[j]];

f0 = f[t0, i];
d = (t == "l" && b <= f0[[1]]) || (t == "u" && f0[[1]] <= b);
c0 = If[d, 0, 1];

evt = With[{k = i, c = \[DoubleStruckC][j][\[DoubleStruckT]], v = b},
(* would prefer to use Brent for LocationMethod, but MMA does not always bracket the root correctly or generates an excessive number of detected events, e.g., BLSwingFootHeight and BLFriction; StepBegin is appropriate because changes take effect during the next time step.  Why wouldn't the event (update rule) affect the current time step? *)
WhenEvent[f[\[DoubleStruckT], k][[1]] == v, c -> 1 - c, "DetectionMethod" -> "Sign", "LocationMethod"-> "StepBegin"]
];

eqn = {\[DoubleStruckX][j]'[\[DoubleStruckT]] == \[DoubleStruckC][j][\[DoubleStruckT]] g[f[\[DoubleStruckT], i], b], \[DoubleStruckX][j][t0] == 0 f0,\[DoubleStruckC][j][t0] == c0, evt};

(* Leibniz integral rule (assume one switching time) *)
f0 = f[tf, i];
d = (t == "l" && b <= f0[[1]]) || (t == "u" && f0[[1]] <= b);
c0 = If[d, 0, 1];

{eqn, {\[DoubleStruckX][j], \[DoubleStruckC][j]}, \[DoubleStruckC][j] \[Element] {0, 1}, c0 dt f0[[1]]},
{j, Length@A}
];

(*Return[A];*)

eqn =Join@@ A[[All, 1]];
var =Join@@ A[[All, 2]];
d = A[[All, 3]];

Check[
sol = NDSolveValue[eqn, var, {\[DoubleStruckT], t0, tf}, DiscreteVariables-> d, ndopt];,
Throw[$Failed],
NDSolveValue::evcvmit
];
];

f0 = sol[[1;;-1;;2]];
c0 = sol[[2;;-1;;2]];

Check[
If[OptionValue["xa"], 
{f0, c0}, 
(* else *)
f0 = MapThread[Join, devec[#, 1]& /@ Through[f0[tf]]];
If[Length@f0 >= 2, f0[[2, All, -1]] += A[[All, 4]];];
f0
],
Message[BLApplyBounds::T, Through[f0["Grid"]], tf];
Throw[$Failed],
InterpolatingFunction::dmval
]
];


(* ::Input::Initialization:: *)
Options[BLFoot] = {"i" -> All};

BLFoot[m_, x_, c_, OptionsPattern[]] := Module[{xm, cm},
xm = If[VectorQ[x], devec[x, nx], x];
cm = If[VectorQ[c], devec[c, nc], c];
devec[BLbiped["foot", m][xm, cm], 2 nm][[All, OptionValue["i"]]]
];


(* ::Input::Initialization:: *)
BLStanceFootPosition[t_, M_Association] := BLFoot[M["m[t]"][t], M["x[t]"][t], M["c[t]"][t], "i" -> 1;;mm];

BLSwingFootPosition[t_, M_Association] := BLFoot[M["m[t]"][t], M["x[t]"][t], M["c[t]"][t], "i" -> mm+1;;nm];

TestBLSwingFootPosition[c_, m_:Automatic, opts:OptionsPattern[]] := Module[{mp, X, C},
mp = If[m === Automatic, BLbiped["m[0]"], m];
C = devec[BLmxcp[mp, c][[3]], nc];
X = Flatten@C[[All, 1;;nx]];
C = Flatten@C;
BLSwingFootPosition[0, <|"m[t]" -> (mp&), "x[t]" -> (X&), "c[t]" ->(C&)|>, opts]
];


(* ::Input::Initialization:: *)
BLSwingFootHeight[t_, M_Association, OptionsPattern[BLApplyBounds]] := Module[{a, n, m, x, c, \[Sigma], p, S},
(*a = BLbiped["draw", "axes"];
If[Length[a] \[Equal] 2, 
(* pad 2D axes to 3D *)
a = Insert[a, First@Complement[Range[1, mm], a], 2];
];

(* compute slope *)
m = M["m"]\[LeftDoubleBracket]1\[RightDoubleBracket];
x = M["x-"]\[LeftDoubleBracket]1\[RightDoubleBracket];
c = M["c"]\[LeftDoubleBracket]1\[RightDoubleBracket];
S = devec[BLbiped["\[Sigma]", m][x, c], mm];

(* compute normal to plane n and dn/dc *)
\[Sigma] = \[DoubleStruckA] /@ a;
x = IdentityMatrix[mm];
x = {RotationMatrix[\[Sigma]\[LeftDoubleBracket]2\[RightDoubleBracket], -x\[LeftDoubleBracket]2\[RightDoubleBracket]].x\[LeftDoubleBracket]1\[RightDoubleBracket], RotationMatrix[\[Sigma]\[LeftDoubleBracket]3\[RightDoubleBracket], x\[LeftDoubleBracket]3\[RightDoubleBracket]].x\[LeftDoubleBracket]2\[RightDoubleBracket]};
n = RigidBodyDynamics`Private`skew[x\[LeftDoubleBracket]1\[RightDoubleBracket]].x\[LeftDoubleBracket]2\[RightDoubleBracket];
n = {n, D[n, {\[Sigma]}]} /. \[DoubleStruckA][i_] \[RuleDelayed] S\[LeftDoubleBracket]1, i\[RightDoubleBracket];
n\[LeftDoubleBracket]2\[RightDoubleBracket] = n\[LeftDoubleBracket]2\[RightDoubleBracket].S\[LeftDoubleBracket]2, a\[RightDoubleBracket];

(* get swing foot location at time t *)
p = BLSwingFootPosition[t, M]\[LeftDoubleBracket]All, a\[RightDoubleBracket];
(*Print[MatrixForm/@{n\[LeftDoubleBracket]1\[RightDoubleBracket], p\[LeftDoubleBracket]2\[RightDoubleBracket]}];*)
{{n\[LeftDoubleBracket]1\[RightDoubleBracket].p\[LeftDoubleBracket]1\[RightDoubleBracket], p\[LeftDoubleBracket]1\[RightDoubleBracket].n\[LeftDoubleBracket]2\[RightDoubleBracket] + n\[LeftDoubleBracket]1\[RightDoubleBracket].p\[LeftDoubleBracket]2\[RightDoubleBracket]}}\[Transpose]*)

a = BLbiped["draw", "axes"][[-1]];
BLSwingFootPosition[t, M][[All, {a}]]
];

BLSwingFootHeight[M_Association, bnds_:Automatic, opts:OptionsPattern[BLApplyBounds]] := Module[{T, f, b},
T = M["T"][[-1]];
f[t_?NumberQ, i_] := Flatten@BLSwingFootHeight[Min[t, T], M, opts];
b = If[bnds === Automatic, {1 -> {0, Infinity}}, bnds];
BLApplyBounds[f, b, T, opts]
];

BLSwingFootHeight[t_, M_Association, Once] := Module[{a, h, T},
T = M["T"][[-1]];
h = BLSwingFootHeight[t, M];
a = BLbiped["draw", "axes"][[-1]];
a = BLFoot[M["m[t]"][t], M["x[t]"][t], M["c[t]"][t], "i" -> {mm+a, nm+mm+a}];

(* maybe do this with apply abounds instead of passing dT *)
h[[2, 1, -1]] += t / T a[[1,2]]; 
h
];

TestBLSwingFootHeight[c_, m_:Automatic, opts:OptionsPattern[]] := Module[{mp, C0, CT, X0, XT},
mp = If[m === Automatic, BLbiped["m[0]"], m];
C0 = devec[BLmxcp[mp, c][[3]], nc];
CT = devec[BLmxc0[mp, c][[3]], nc];
X0 = C0[[All, 1;;nx]];
XT = CT[[All, 1;;nx]];
BLSwingFootHeight[0, <|"m[t]" -> (mp&), "x[t]" -> (Flatten@XT&), "c[t]" ->(Flatten@CT&), "x-" -> {X0, XT}, "c" -> {C0, CT}|>, opts]
];

TestBLSwingFootHeightIntegral[c_, m_:Automatic, opts:OptionsPattern[]] := Module[{mp, C0, CT, X0, XT},
mp = If[m === Automatic, BLbiped["m[0]"], m];
C0 = devec[BLmxcp[mp, c][[3]], nc];
CT = devec[BLmxc0[mp, c][[3]], nc];
X0 = C0[[All, 1;;nx]];
XT = CT[[All, 1;;nx]];
BLSwingFootHeight[<|"m[t]" -> (mp&), "x[t]" -> (Flatten@XT&), "c[t]" ->(Flatten@CT&), "x-" -> {X0, XT}, "c" -> {C0, CT}, "T" -> {c[[-1]]}|>, opts]
];


(* ::Input::Initialization:: *)
Options[BLStateBounds] = {"xa" -> False};

BLStateBounds[M_Association, bnds_, opts:OptionsPattern[]] := Module[{f, T, \[CurlyPhi]},
\[CurlyPhi] = M["x[t]"];
T = M["T"][[-1]];
f[t_?NumberQ, i_] := Flatten[devec[\[CurlyPhi][Min[t, T]], nx][[All, i]]];
BLApplyBounds[f, bnds, T, opts]
];


(* ::Input::Initialization:: *)
Options[BLqddfu] = {"i" -> All};

BLqddfu[m_String, x_, c_, OptionsPattern[]] := Module[{xm, cm, n},
xm = If[VectorQ[x], devec[x, nx], x];
cm = If[VectorQ[c], devec[c, nc], c];
n = nq +  BLbiped["n", m, "np"] + BLbiped["n", m, "nv"];

devec[BLbiped["fosim", m][xm, cm], n][[All, OptionValue["i"]]]
];

BLqddfu[t_, M_Association, opts:OptionsPattern[]] := BLqddfu[M["m[t]"][t], M["x[t]"][t], M["c[t]"][t], opts];

BLqdd[t_, M_Association] := BLqddfu[t, M, "i" -> 1;;nq];

BLf[t_, M_Association] := Module[{m, np},
m = M["m[t]"][t];
np = BLbiped["n", m, "np"];
BLqddfu[t, M, "i" -> nq+1;;nq+np]
];

BLu[t_, M_Association] := Module[{m, np, nv},
m = M["m[t]"][t];
np = BLbiped["n", m, "np"];
nv = BLbiped["n", m, "nv"];
BLqddfu[m, M["x[t]"][t], M["c[t]"][t], "i" -> nq+np + 1;;nq+np + nv]
];

BLFriction[\[Mu]_, M_Association, bnds_:Automatic, opts:OptionsPattern[BLApplyBounds]] := Module[{T, f, b, mu},
(* assume \[Sigma] = 0 and planar biped; need to extend lib to compute (fn, ft) *)
T = M["T"][[-1]];
mu = \[Mu] / Sqrt[2];
f[t_?NumberQ, i_] := Module[{\[Lambda], ft, fn},
\[Lambda] = BLf[Min[t, T], M];
ft = \[Lambda][[All, 1;;1]];
fn = \[Lambda][[All, 2;;2]];
Flatten@Which[i == 1, fn, i == 2, ft - mu fn, i == 3, -ft - mu fn]
];

b = If[bnds === Automatic, {1 -> {0, Infinity}, 2 -> {-Infinity, 0}, 3 -> {-Infinity, 0}}, bnds];

BLApplyBounds[f, b, T, opts]
];


(* ::Input::Initialization:: *)
Options[BLqd\[Iota]] = {"i" -> All};

BLqd\[Iota][m_, x_, c_, OptionsPattern[]] := Module[{xm, cm, n},
xm = If[VectorQ[x], devec[x, nx], x];
cm = If[VectorQ[c], devec[c, nc], c];
n = nq +  BLbiped["n", m, "ni"];
devec[BLbiped["hosim", m][xm, cm], n][[All, OptionValue["i"]]]
];

BLqd\[Iota][t_, M_Association] := BLqd\[Iota][M["m[t]"][t], M["x[t]"][t], M["c[t]"][t]];

BLqd[t_, M_Association] := BLqd\[Iota][M["m[t]"][t], M["x[t]"][t], M["c[t]"][t], "i" -> 1;;nq];

BL\[Iota][t_, M_Association] := Module[{m, ni},
m = M["m[t]"][t];
ni = BLbiped["n", m, "ni"];
BLqd\[Iota][m, M["x[t]"][t], M["c[t]"][t], "i" -> nq+1;;nq+ni]
];


(* ::Input::Initialization:: *)
Options[BLcost] = {"i" -> All};

BLcost[m_String, x_, c_, OptionsPattern[]] := Module[{xm, cm},
xm = If[VectorQ[x], devec[x, nx], x];
cm = If[VectorQ[c], devec[c, nc], c];
devec[BLbiped["cost", m][xm, cm], 4][[All, OptionValue["i"]]]
];

BLcost[t_, M_Association, opts:OptionsPattern[]] := BLcost[M["m[t]"][t], M["x[t]"][t], M["c[t]"][t], opts];

BLcost[M_Association, bnds_:Automatic, opts:OptionsPattern[BLApplyBounds]] := Module[{T0, T, f, b},
{T0, T} = M["T"][[{1, -1}]];

f[t_?NumberQ, i_] := Module[{c},
Flatten@BLcost[Min[t, T], M, "i" -> i]
];

b = If[bnds === Automatic, {1 -> {-Infinity, 0}, 2 -> {-Infinity, Infinity}, 3 -> {-Infinity, 0}, 4 -> {-Infinity, Infinity}}, bnds];

BLApplyBounds[f, b, {T0, T}, opts]
];

BLuu[t_, M_Association] := BLcost[M["m[t]"][t], M["x[t]"][t], M["c[t]"][t], "i" -> 1;;1];

BLuBMqd[t_, M_Association] := Module[{m, ni},
m = M["m[t]"][t];
ni = BLbiped["n", m, "ni"];
BLcost[m, M["x[t]"][t], M["c[t]"][t], "i" -> 2;;2]
];

BLuinuin[t_, M_Association] := BLcost[M["m[t]"][t], M["x[t]"][t], M["c[t]"][t], "i" -> 3;;3];

BLuinMqd[t_, M_Association] := Module[{m, ni},
m = M["m[t]"][t];
ni = BLbiped["n", m, "ni"];
BLcost[m, M["x[t]"][t], M["c[t]"][t], "i" -> 4;;4]
];


(* ::Input::Initialization:: *)
Options[BLR\[Sigma]] = {"ax" -> Automatic};

BLR\[Sigma]::imp = "3D is not implemented yet.";

BLR\[Sigma][M_Association, OptionsPattern[]] := Module[{m, X, C, ax, \[Sigma], R, W, WR, WWR, x, d\[Sigma]},
ax = OptionValue["ax"];
If[ax === Automatic, ax = BLbiped["draw", "axes"]];

(* compute slope post impact *)
C = Normal@M["c"][[2]];
X = C[[All, 1;;nx]];
m = M["m"][[2]];
\[Sigma] = devec[BLbiped["\[Sigma]", m][X, C], mm];

If[Length[ax] == 2,
ax = Insert[ax, First@Complement[Range[1, mm],  ax], 2];,
(* else 3D *)
Message[BLR\[Sigma]::imp];
Throw@$Failed;
];

(* compute R *)
\[Sigma] = \[Sigma][[All, ax]];
x = IdentityMatrix[mm];

(*R = RotationMatrix[\[Sigma]\[LeftDoubleBracket]1, 3\[RightDoubleBracket], x\[LeftDoubleBracket]3\[RightDoubleBracket]].RotationMatrix[\[Sigma]\[LeftDoubleBracket]1, 2\[RightDoubleBracket], x\[LeftDoubleBracket]2\[RightDoubleBracket]];*)
R = {RotationMatrix[\[Sigma][[1, 2]], x[[2]]]};
If[Length@\[Sigma] >= 2, 
W = RigidBodyDynamics`Private`skew[x[[2]]];
WR =  ArrayReshape[W . R[[1]], {3, 3, 1}];
d\[Sigma] = \[Sigma][[2, 2;;2]];

R = Join[R, {WR . d\[Sigma]}];
If[Length@\[Sigma] >= 3, 
m = {1, 2, 4, 3};
WWR = ArrayReshape[W . WR, {3 ,3 ,1 ,1}];
R = Join[R, {WR . \[Sigma][[3, 2;;2]] + Transpose[Transpose[WWR, m] . d\[Sigma], m] . d\[Sigma]}];
];
];

R
];

Options[BLL\[Sigma]] = {"i" -> Automatic, "d" -> 0, "ax" -> Automatic, BLR\[Sigma] -> {}};

BLL\[Sigma][M_Association, OptionsPattern[]] := Module[{i, X0, XT, C, L, d, ax, \[Sigma], R, x},
X0 = M["x-"][[-2]];
XT = M["x-"][[-1]];

ax = OptionValue["ax"];
If[ax === Automatic, ax = BLbiped["draw", "axes"];];

R = BLR\[Sigma][M, "ax" -> ax];
If[Length@ax == 2, R = R[[All, {1, 3}, {1, 3}]];];

d = BLIndices[BLGetBipedBase[], "p"][[ax]];
L = XT[[All, d]] - X0[[All, d]];

d = Length[L];
If[d >= 2,
If[d >= 3,
L[[3]] = L[[1]] . Transpose[R[[3]]] + 2(L[[2]]\[Transpose] . R[[2]]\[Transpose])\[Transpose] + R[[1]] . L[[3]];
L[[3]] = 0.5(L[[3]] + Transpose[L[[3]], {1, 3, 2}]);
];
L[[2]] = L[[1]] . Transpose[R[[2]]] + R[[1]] . L[[2]];
];
L[[1]] = R[[1]] . L[[1]] - OptionValue["d"];

(* would be more efficient to only do operations associated with index i *)
(* but this is quick and easy to implement *)
i = OptionValue["i"];
If[i === Automatic, i = 1;;1];

L[[All, i]]
];

Options[BLV\[Sigma]] = {BLL\[Sigma] -> {}, "v" -> 0};

BLV\[Sigma][M_Association, OptionsPattern[]] := Module[{T, L, V, v, d, v1, v2, v3},
T = Normal@M["c"][[1, All, -1;;-1]];
L = BLL\[Sigma][M, OptionValue[BLL\[Sigma]]];

d = Length@L;
(* for sparse arrays defauly value 0 becomes 1/0 = indeterminate *)
V = Quiet@Which[
d == 1, {L[[1]]/T[[1]]},
d == 2,{L[[1]]/T[[1]], (T[[1]]L[[2]]-KroneckerProduct[L[[1]], T[[2]]])/T[[1]]^2},
d == 3,{L[[1]]/T[[1]], (T[[1]]L[[2]]-KroneckerProduct[L[[1]], T[[2]]])/T[[1]]^2,
SparseArray@{L[[3, 1]]/T[[1,1]] -(L[[2]]\[Transpose] . T[[2]]+T[[2]]\[Transpose] . L[[2]])/ T[[1,1]]^2 +  L[[1,1]] (2T[[2]]\[Transpose] . T[[2]]/T[[1,1]]^3 - T[[3,1]]/T[[1,1]]^2)}}
];

v = OptionValue["v"];
V[[1]]= V[[1]] - v;
SparseArray /@ V
]


(* ::Input::Initialization:: *)
Options[BLStep] = {"i" -> Automatic, "d" -> 0};

BLStep[M_Association, OptionsPattern[]] := Module[{X0, XT, L, d},
X0 = M["x-"][[1]];
XT = M["x-"][[-1]];

d = OptionValue["i"];
If[d === Automatic, d = BLbiped["draw", "axes"][[1;;1]]];
d = BLIndices[BLGetBipedBase[], "p"][[d]];
L = XT[[All, d]] - X0[[All, d]];

d = Length@L;
Which[
d == 1, {L[[1]]},
d == 2,{L[[1]] - OptionValue["d"], L[[2]]},
d == 3,{L[[1]] - OptionValue["d"], L[[2]], L[[3]]}
]
]

TestBLStep[c_, m_:Automatic, opts:OptionsPattern[]] := Module[{mp, X0, XT},
mp = If[m === Automatic, BLbiped["m[0]"], m];
X0 = devec[BLmxcp[mp, c][[2]], nx];
XT = devec[BLmxc0[mp, c][[2]], nx];
BLStep[<|"m" -> {mp}, "x-" -> {X0, XT}|>, opts]
]


(* ::Input::Initialization:: *)
Options[BLAverageVelocity] = {BLStep -> {}, "v" -> 0};

BLAverageVelocity[M_Association, OptionsPattern[]] := Module[{T, L, V, v, d},
T = Normal@M["c"][[1, All, -1;;-1]];
L = BLStep[M, OptionValue[BLStep]];

d = Length@L;
(* for sparse arrays defauly value 0 becomes 1/0 = indeterminate *)
V = Quiet@Which[
d == 1, {L[[1]]/T[[1]]},
d == 2,{L[[1]]/T[[1]], (T[[1]]L[[2]]-KroneckerProduct[L[[1]], T[[2]]])/T[[1]]^2},
d == 3,{L[[1]]/T[[1]], (T[[1]]L[[2]]-KroneckerProduct[L[[1]], T[[2]]])/T[[1]]^2,
SparseArray@{L[[3, 1]]/T[[1,1]] -(L[[2]]\[Transpose] . T[[2]]+T[[2]]\[Transpose] . L[[2]])/ T[[1,1]]^2 +  L[[1,1]] (2T[[2]]\[Transpose] . T[[2]]/T[[1,1]]^3 - T[[3,1]]/T[[1,1]]^2)}}
];

v = OptionValue["v"];
V[[1]]= V[[1]] - v;
SparseArray /@ V
]

TestBLAverageVelocity[c_, m_:Automatic, opts:OptionsPattern[]] := Module[{mp, C0, CT, X0, XT},
mp = If[m === Automatic, BLbiped["m[0]"], m];
C0 = devec[BLmxcp[mp, c][[3]], nc];
CT = devec[BLmxc0[mp, c][[3]], nc];
X0 = devec[BLmxcp[mp, c][[2]], nx];
XT = devec[BLmxc0[mp, c][[2]], nx];
BLAverageVelocity[<|"m" -> {mp}, "c" -> {C0, CT}, "x-" -> {X0, XT}|>, opts]
]


(* ::Input::Initialization:: *)
Options[BLSlope] = {"i" -> Automatic, "\[Sigma]" -> None};

BLSlope[A_Association, OptionsPattern[]] := Module[{m, X, C, S, d},
m = A["m"][[1]];
X = A["x-"][[1(*;;1*)]];
C = A["c"][[1(*;;1*)]];

S = devec[BLbiped["\[Sigma]", m][Normal@X, Normal@C], mm];

m = OptionValue["i"];
If[m === Automatic, 
(* get slope axis (axes) for 2D (3D) robot *)
m = BLbiped["draw", "axes"];
m = If[Length[m] == 2, Complement[Range[1, mm], m],m[[1;;2]]];
];
S = S[[All, m]];

m = OptionValue["\[Sigma]"];
d = Length@S;
SparseArray /@ Which[m === None,S, 
d == 1, {Sin[S[[1]] - m]}, 
d == 2, {Sin[S[[1]] - m], Cos[S[[1,1]] - m]S[[2]]},
d == 3, {Sin[S[[1]] - m], Cos[S[[1, 1]] - m]S[[2]], {-Sin[S[[1, 1]] - m](S[[2]]\[Transpose] . S[[2]])\[Transpose]} + Cos[S[[1, 1]] - m]S[[3]]}
]
];

TestBLSlope[c_, m_:Automatic, opts:OptionsPattern[]] := Module[{mp, X, C},
mp = If[m === Automatic, BLbiped["m[0]"], m];
C = devec[BLmxcp[mp, c][[3]], nc];
X = C[[All, 1;;nx]];
BLSlope[<|"m" -> {mp}, "x-" -> {X}, "c" -> {C}|>, opts]
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
