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
BeginPackage["BipedalLocomotion`", {"GlobalVariables`", "RigidBodyDynamics`", "HybridDynamics`", "ContinuationMethods`", "BipedalLocomotion`Model`"}]

Begin["`Private`"]


(* ::Input::Initialization:: *)
(* assumes we are starting at an equilibrium point *)
Options[BLGenerateGaits] = {Man -> {}, BLFindBifurcation -> {}, "T" -> Automatic, "nstol" -> Automatic, "A" -> Automatic};

BLGenerateGaits::fd = "Finite-difference of derivatives not yet implemented.";

BLGenerateGaits[P_, t_, h_, N_, opts:OptionsPattern[]] := Module[{n, c, T},
If[NumericQ[t],
(* switching time given, use P or a different map? *)
T = OptionValue["T"];
If[T === Automatic, T = P];
(* find bifurcation *)
T = First@BLFindBifurcation[T, t, Automatic, OptionValue[BLFindBifurcation]];
c = BLbiped["\[DoubleStruckC]", BLbiped["m[0]"], "eq"][T];,
(* else *)
(* c[0] given *)
c = t;
];

n = HybridDynamics`Private`o;
If[n == 0, Message[BLGenerateGaits::fd]];

n = OptionValue@"A";
If[n === Automatic, n = {1}];
n = "ns" -> {Tolerance -> OptionValue@"nstol", "A" -> n};
Man[P, c, h, N, OptionValue[Man], "cm0" -> "cmdata" -> n]
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
