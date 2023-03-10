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
BLc[m_, cp_] := Module[{C, E, i, j, k},
(* to padded p *)
C = BLbiped["\[DoubleStruckC]", m, "p"][{cp}];

(* callback functions *)
E = BLbiped["BLc", m, "f"];
If[!MissingQ[E], C = E[m, cp, C];];

(* replace linear physical constraints *)
E = BLbiped["BLc", m, "q"];
If[!MissingQ[E] && Length@E == 3,
{i, j, k} = E;
(* solve for linear configuration constraints *)
E = devec[BLbiped["\[Eta]p", m][C[[All, 1;;nx]], C], k];
C[[All, i]] = -E[[All, j]];
];

E = BLbiped["BLc", m, "v"];
If[!MissingQ[E] && Length@E == 3,
{i, j, k} = E;
(* solve for linear velocity constraints *)
E = devec[BLbiped["J[p]", m][C[[All, 1;;nx]], C], k];
C[[All, i]] = E[[All, j]];
];

(*(* callback functions *)
E = BLbiped["BLc", m, "f"];
If[!MissingQ[E], E[m, cp, C], C]*)
C
];

BLc[m0_, x0_, c_] := Module[{xT, c0},
(* m0 is post-impact mode *)
(* next pre-impact x(T) based on c = (x-, \[Lambda]) *)

xT = devec[BLbiped["xT", m0][c[[All, 1;;nx]], c], nx];
(* to c+ *)
c0 = BLbiped["\[DoubleStruckC]", m0, "T"][xT, c];

(* boundary coefficients at x(0) and x(T) *)
BLc0T[m0, x0, xT, c0]
];


(* ::Input::Initialization:: *)
BLc0T[m0_, x0_, xT_, c_] := Module[{\[Theta], c0},
(* solve for known parameters in c *)
c0 = c;
(* set \[Theta]0 and \[Theta]T *)
\[Theta] = BLbiped["BLc0T", m0, "\[Theta]"];
If[\[Theta][[2]] != 0,
Print["\[Theta]\[LeftDoubleBracket]2\[RightDoubleBracket]"];
c0[[All, \[Theta][[2]]]] = x0[[All, \[Theta][[1]]]];
];

If[\[Theta][[3]] != 0,
Print["\[Theta]\[LeftDoubleBracket]3\[RightDoubleBracket]"];
c0[[All, \[Theta][[3]]]] = xT[[All, \[Theta][[1]]]];
];

(* boundary coefficients at post-impact x(0) *)
c0 = BLbiped["\[Eta]0", m0][x0, c0];
c0 = devec[c0, nc];

(* boundary coefficients at (next) pre-impact x(T) *)
BLbiped["\[Eta]T", m0][xT, c0]
];


(* ::Input::Initialization:: *)
BLmxc0[m_, cp_] := Module[{C, E, X0, C0, XT, i, j, k, m0}, 
(* to x- *)
C = BLc[m, cp];

(* to (m+, x+, c+) *)
m0 = BLbiped["m", m][C[[All, 1;;nx]], C];
X0 = BLbiped["h", m0][C[[All, 1;;nx]], C];
C0 = BLc[m0, devec[X0, nx], C];

(* return Flatten /@ {m0, x0, c0}, where c0 = (x(T), \[Lambda]+) *)
{m0, X0, C0, C}
];

BLmxcp[mp_, cp_] := Module[{C}, 
(* to x- *)
C = BLc[mp, cp];
(* return Flatten /@ {m0-, x0-, c0-}, where c0 = (x(0-), \[Lambda]-) *)
{mp, Flatten@C[[All, 1;;nx]], Flatten@C}
];


(* ::Input::Initialization:: *)
Options[BLMap] = {\[CurlyPhi] -> {}, "T" -> Automatic, "DT" -> Automatic, "e" -> Automatic};

BLMap::T = "Options T and DT can't both be automatic.  At least one has to be a vector (T can also be scalar).";

BLMap[m_, x_, c_, OptionsPattern[]] := Module[{T, DT, e},
T = OptionValue["T"];
DT = OptionValue["DT"];

If[T === Automatic, 
(* get switching times from parameter vector *)
If[DT === Automatic, DT = BLbiped["t", m]];
(* get switching times from vec[c(0)]; c is full parameter space *)
(*T = If[# \[NotEqual] 0, c\[LeftDoubleBracket]nc-Abs[#]+1\[RightDoubleBracket], 0]& /@ DT;*)
T = BLGetSwitchingTimes[c, "m" -> m, "DT" -> DT];
];

(* add switching time events *)
e = OptionValue["e"];
If[e === Automatic, e = AddSwitchingTimeEvents[T, DT]];

(*Print["e: ", e];*)

\[CurlyPhi][m, x, c, T, OptionValue@\[CurlyPhi], "e" -> e]
];


(* ::Input::Initialization:: *)
Options[BLP] = {BLMap -> {}, BLSim -> BLSim};

BLP[cp_, opts:OptionsPattern[]] := BLP[BLbiped["m[0]"], cp, opts]["R"];

BLP[mp_String, cp_, opts:OptionsPattern[]] := Module[{xT, xT0,  M, R},
(* apply step map using a wrapper for BLMap *)
M = OptionValue[BLSim][mp, cp, OptionValue[BLMap]];

(* devec state, parameters, and modes at switching times *)
M["c"] = devec[#, nc]& /@ M["c"];
M["x-"] = devec[#, nx]& /@ M["x-"];
M["x+"] = devec[#, nx]& /@ M["x+"];

(* is it a gait? *)
xT = M["x-"][[-1]];
xT0 = M["c"][[-1, All, 1;;nx]];

R = BLbiped["c", mp, "x"];
R = xT[[All, R]] - xT0[[All, R]];
R[[1]] = BLState[R[[1]]];

Join[M, <|"R" -> R, "p" -> cp|>]
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
