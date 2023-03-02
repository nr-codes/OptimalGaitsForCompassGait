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
RigidBodyDerivatives.nb: High-level functions used to define a rigid body.
Copyright (C) 2016 Nelson Rosa Jr.

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
BeginPackage["RigidBodyDynamics`", {"GlobalVariables`", "Derivatives`"}]
Begin["`Private`"]


(* ::Input::Initialization:: *)
common = {FixFunctionsWithFlatten, FixFunctionsWithSelect};

FixFunctions[expr_] := Block[{Derivatives`Private`common = Derivatives`Private`common},
Derivatives`Private`common = Join[common, Derivatives`Private`common];
FixCommonFunctions[expr]
];


(* ::Input::Initialization:: *)
FixFunctionsWithFlatten = Module[{f, e, m},
f = #;
(* get max derivative order *)
e = HoldPattern[Set[x_, _]] :> DerivativeOrder[x];
m = Max@Cases[f, e, Infinity];

(* add derivatives to Flatten[....] *)
e = HoldPattern[Flatten[x__]] :> Thread[\[FormalP][x]];
e = Flatten@Cases[f, e, Infinity];
If[Length@e > 0, 
e = Table[CreateSymbol[Evaluate@i, j, Hold], {i, e}, {j, 0, m}];
e = \[FormalP]@Evaluate@e /. Hold[x_] :> x;
f = f /. _Flatten ->   e /. \[FormalP] -> Flatten;
];
f
]&;


(* ::Input::Initialization:: *)
depth[HoldPattern[Select[x_, __]]] := depth[x];

FixFunctionsWithSelect = #  /. "***Select***" ->  Select&;

CreateSymbol[HoldPattern[Select[x__]], d_Integer:0] := "***Select***"[x];

TransformExpression[HoldPattern[Set[_, Select[__]]]] := {IgnoreCase}; 

TransformExpression[HoldPattern[Set[_, Select[__]\[Transpose]]]] := {IgnoreCase}; 


(* ::Input::Initialization:: *)
TransformExpression[HoldPattern[Set[x_, ba[[y__]]]]] := {IgnoreCase}; 

TransformExpression[HoldPattern[Set[_, Length[_]]]] := {IgnoreCase}; 


(* ::Input::Initialization:: *)
depth[Range[__]] := {1, 0};

FixFunctionsWithSelect = #  /. {"***Select***" ->  Select, "***Range***" ->  Range}&;

CreateSymbol[HoldPattern[Select[Range[x__], y__]], d_Integer:0] := "***Select***"["***Range***"[x], y];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
