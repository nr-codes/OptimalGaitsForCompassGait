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
BeginPackage["BipedalLocomotion`Model`", {"GlobalVariables`", "Derivatives`", "RigidBodyDynamics`", "BipedalLocomotion`", "HybridDynamics`"}]

Begin["`Private`"]


(* ::Input::Initialization:: *)
AlternateCompile[RBDIME, opts:OptionsPattern[]] := Module[{I},
I = Module[{ime, q, \[Alpha], B, u},
ime = RBDIME[#1, #2];

B = RigidBodyDynamics`Private`ucons;
B = If[Length@B == 2, RigidBodyDynamics`Private`J[[B]]\[Transpose],  ConstantArray[0, {nq, 2}]];
u = If[StringContainsQ[OptionValue["cons"], "left"], #1[[4]]+#1[[5]], #1[[4]]];
u = {Sin[u], -Cos[u]} #2[[nc-1]];
ime[[1;;nq, - 1]] += TrigReduce@Simplify[B . u];

\[Alpha] = Lookup[fcon, "\[Alpha]\[Theta]", {}];
If[\[Alpha] === {}, \[Alpha] = {0, 1};]; (* sometimes key exists but is {} *)
q = #1[[1;;nq]];
Block[{\[Alpha]\[Theta] = \[Alpha], RigidBodyDynamics`Private`q = q},
\[Theta]0[];
\[Alpha] = IdentityMatrix[nq];
ArrayFlatten[{{\[Alpha], 0, {RigidBodyDynamics`Private`q}\[Transpose]}, {0, ime[[All, 1;;-2]], {ime[[All, -1]]}\[Transpose]}}]
]
]&;

AlternateCompile["Ab", I[##, opts]&, opts]
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
