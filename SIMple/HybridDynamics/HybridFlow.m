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
SimplestModel.nb: An implementation of various continuation methods.
Copyright (C) 2017 Nelson Rosa Jr.

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
BeginPackage["HybridDynamics`", "GlobalVariables`"]

Begin["`Private`"]
rbd = <||>;
e = {};
o = 0;


(* ::Input::Initialization:: *)
SetAttributes[{DefaultSwitchingEvent, AddSwitchingEvent}, HoldFirst];

Options[DefaultSwitchingEvent] = {"i" -> 2;;-2, "p" -> {}, "a" -> {}, WhenEvent -> {}, "DT" -> 0};

Events[k_:0] := {\[DoubleStruckX][\[DoubleStruckT]] -> TF[\[DoubleStruckM][\[DoubleStruckT]], \[DoubleStruckX][\[DoubleStruckT]], \[DoubleStruckC][\[DoubleStruckT]], k], \[DoubleStruckM][\[DoubleStruckT]] -> m[\[DoubleStruckM][\[DoubleStruckT]], \[DoubleStruckX][\[DoubleStruckT]], \[DoubleStruckC][\[DoubleStruckT]]], \[DoubleStruckX][\[DoubleStruckT]] -> h[\[DoubleStruckM][\[DoubleStruckT]], \[DoubleStruckX][\[DoubleStruckT]], \[DoubleStruckC][\[DoubleStruckT]]], \[DoubleStruckC][\[DoubleStruckT]] -> d[\[DoubleStruckM][\[DoubleStruckT]], \[DoubleStruckX][\[DoubleStruckT]], \[DoubleStruckC][\[DoubleStruckT]]], \[DoubleStruckX][\[DoubleStruckT]] -> T0[\[DoubleStruckM][\[DoubleStruckT]], \[DoubleStruckX][\[DoubleStruckT]], \[DoubleStruckC][\[DoubleStruckT]], k]};

DefaultSwitchingEvent[evnt_, opts:OptionsPattern[]] := Module[{a},
a = Events[OptionValue["DT"]];
a = Join[OptionValue["p"], a[[OptionValue["i"]]], OptionValue["a"]];
With[{e = a, o = OptionValue[WhenEvent]}, WhenEvent[evnt, e, o]]
];

AddSwitchingTimeEvents[T_, DT_:Automatic, opts:OptionsPattern[DefaultSwitchingEvent]] := Module[{t0, tf, p, a, k, n},
(* T contains indices in \[DoubleStruckC], with \[DoubleStruckC]\[LeftDoubleBracket]i\[RightDoubleBracket] being absolute time from t0 (= 0). *)
(* assumes T is in ascending order 0 <= T[i] <= T[i+1] *)
n = Length@T;
Table[
k = If[VectorQ[DT] && DT =!= {}, DT[[i]], 0];
(* final switching time derivative *)
tf = {\[DoubleStruckX][\[DoubleStruckT]] -> TF[\[DoubleStruckM][\[DoubleStruckT]], \[DoubleStruckX][\[DoubleStruckT]], \[DoubleStruckC][\[DoubleStruckT]], k]};
p = "p" -> tf;

(* start switching time derivative *)
t0 = {\[DoubleStruckX][\[DoubleStruckT]] -> T0[\[DoubleStruckM][\[DoubleStruckT]], \[DoubleStruckX][\[DoubleStruckT]], \[DoubleStruckC][\[DoubleStruckT]], k]};
a = "a" -> Append[If[i < n, t0, {}], "RemoveEvent"];

(* final switching time? *)
k = "i" -> If[i < n, OptionValue[DefaultSwitchingEvent, "i"], {}];

(* create event *)
k = With[{j = T[[i]]}, DefaultSwitchingEvent[\[DoubleStruckT] - j == 0, p, a, k, WhenEvent -> Join[{"Priority" -> i}, OptionValue@WhenEvent], opts]];

(* allow for parameters in T *)
k /. \[DoubleStruckC][k_Integer] :> \[DoubleStruckC][[k]],
{i, n}
]
];

AddSwitchingEvent[evnt_, opts:OptionsPattern[]] := Module[{a},
a =DefaultSwitchingEvent[evnt, opts];
Last@AppendTo[e, a]
];

RemoveSwitchingEvent[form_:(_WhenEvent)] := e = DeleteCases[e, form];


(* ::Input::Initialization:: *)
FixedStepSize[M_, T_, n_] := If[n > 0, {MaxStepFraction->Infinity, Method-> {"FixedStep", "StepSize" -> If[n < 1, n, T/n],
Method->M}}, {}];


(* ::Input::Initialization:: *)
devec["o"] := o;

devec[d_, n_] := Module[{m, N, x, dx, ddx},
N = Length[d]/n;
m = Switch[o, 0, 0, 1, N-1, 2, (-1+Sqrt[1-4(1-N)])/2];

If[o >= 0, x = d[[1;;n]];];
If[o >= 1, dx = ArrayReshape[d[[n+1;;n (m+1)]], {n, m}];];
If[o >= 2, ddx = ArrayReshape[d[[n (m+1)+1;;n(m^2+m+1)]], {n, m, m}];];

{x,dx,ddx}[[1;;o+1]]
];

devecF[f_, v_] := Module[{n, F, r, d, p},
n = Length@f;
d = Table[p[Slot[i], j], {i, Length@v}, {j, n}];
r = With[{a = Sequence@@Flatten@d[[All, 1;;#2[[1]]]]}, Hold[#1][a]]&;
F = MapIndexed[r, f];
With[{a = F}, a&] /. Hold[a_] :> a /. p -> Part
];


(* ::Input::Initialization:: *)
m[m_, x_?VectorQ, c_?VectorQ] :=Module[{X, C}, 
X = devec[x, nx];
C = devec[c, nc];
Sow[rbd["m", m][X, C], "m"]
];

f[m_, x_?VectorQ, c_?VectorQ] := Module[{X, C}, 
X = devec[x, nx];
C = devec[c, nc];
rbd["f", m][X, C]
];

h[m_, x_?VectorQ, c_?VectorQ] := Module[{X, C}, 
X = devec[x, nx];
C = devec[c, nc];
rbd["h", m][X, C]
];

d[m_, x_?VectorQ, c_?VectorQ] := Module[{X, C}, 
X = devec[x, nx];
C = devec[c, nc];
Sow[rbd["d", m][X, C], "c"]
];

T0[m_, x_?VectorQ, c_?VectorQ, i_Integer] := Module[{X, C},
X = devec[x, nx];
C = devec[c, nc];
Sow[DT0[m, X, C, i], "x+"]
];

TF[m_, x_?VectorQ, c_?VectorQ, i_Integer] := Module[{X, C},
X = devec[x, nx];
C = devec[c, nc];
Sow[DTF[m, X, C, i], "x-"]
];


(* ::Input::Initialization:: *)
Options[\[CurlyPhi]] = {"e" -> {}, "n" -> 0, "fs" -> {}, NDSolve -> {}, "t0" -> $MachineEpsilon, "tf" -> $MachineEpsilon};

\[CurlyPhi][RBD_Association, ord_] := Module[{},
o = ord;
rbd = RBD;
];

\[CurlyPhi][m_, x_, c_, T_, opts:OptionsPattern[]] := Module[{eqn, o, t0, tf},
(* set time interval *)
{t0, tf} = If[VectorQ[T], T[[{1, -1}]], {0, T}];
(* MMA cannot detect events @ end points, push start and end times a little *)
t0 -= OptionValue["t0"];
tf += OptionValue["tf"];

(* TODO: DELETE Check[...] and instead figure out why \[Tau] < 0 despite bounds *)
Check[
Block[{\[DoubleStruckX], \[DoubleStruckC], \[DoubleStruckT], \[DoubleStruckM]},
(* eqns & events *)
eqn = {\[DoubleStruckX]'[\[DoubleStruckT]] == f[\[DoubleStruckM][\[DoubleStruckT]], \[DoubleStruckX][\[DoubleStruckT]], \[DoubleStruckC][\[DoubleStruckT]]]};
eqn = Join[eqn, {\[DoubleStruckX][t0] == x, \[DoubleStruckC][t0] == c, \[DoubleStruckM][t0] == m}, e, OptionValue["e"]];

(* get options: fixed step size? NDSolve opts *)
o = FixedStepSize[OptionValue["fs"], tf-t0, OptionValue["n"]];
o = Flatten@{o, OptionValue[NDSolve]};

(* solve ODE *)
o = Reap[Sow[m, "m"];Sow[c, "c"];Sow[x, "x-"];Sow[x, "x+"];
NDSolveValue[eqn, {\[DoubleStruckX], \[DoubleStruckC], \[DoubleStruckM]}, {\[DoubleStruckT], t0, tf}, DiscreteVariables-> {\[DoubleStruckC], \[DoubleStruckM] \[Element] Keys@rbd["m"]}, o], _, Rule];

(* should Throw@$Failed if NDSolveValue has errors *)

(* return trajectories and events *)
<|Thread[{"x[t]", "c[t]", "m[t]"} -> o[[1]]], Rest@o, "T" -> T|>
],
Print["-----: T = ", T];
Throw@$Failed;
]
];


(* ::Input::Initialization:: *)
DT0[m_, x_, c_, T_] := Module[{z, F},
(* T (an index) => switching time derivatives at s = t0 *)
z = x;
If[o >= 1 && T !=  0,
F = devec[rbd["f", m][z, c], nx][[1]];
z[[2, All, T]] -= F;

If[o >= 2, 
(* must have dx/dT set above before solving for Hessian *)
F = devec[rbd["f", m][z, c], nx][[2]];
Do[z[[3, i, T, All]] = z[[3, i, All, T]] -= F[[i]];, {i, nx}];
];
];

Flatten[z]
];

DTF[m_, x_, c_, T_] := Module[{z, F},
(* T (an index) => switching time derivatives at s = tf *)
(* or initial condition @ s = t0 for switching time derivatives at s = tf *)
z = x;
If[o >= 1 && T !=  0,
F = devec[rbd["f", m][z, c], nx][[1]];
z[[2, All, T]] += F;

If[o >= 2, 
(* must have dx/dT set above before solving for Hessian *)
F = devec[rbd["f", m][z, c], nx][[2]];
(* should this be df/dT dT/dc + f(T) d^2/dc^2(T)? *)
(* does this ignore f(T) d^2/dc^2(T) by assuming it's always zero? *)
(* by design it has been, but still... *)
Do[z[[3, i, T, All]] = z[[3, i, All, T]] += F[[i]];, {i, nx}];
];
];

Flatten[z]
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
