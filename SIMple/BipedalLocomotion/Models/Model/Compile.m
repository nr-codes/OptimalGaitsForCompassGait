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
BeginPackage["BipedalLocomotion`Model`", {"GlobalVariables`", "RigidBodyDynamics`", "HybridDynamics`", "BipedalLocomotion`"}]

Begin["`Private`"]


(* ::Input::Initialization:: *)
confun = <|"I" :> {{Pfun, {{\[DoubleStruckX], _Real, nx}, {\[DoubleStruckC], _Real, nc}}}, {B0fun, {{\[DoubleStruckX], _Real, nx}, {\[DoubleStruckC], _Real, nc}}}, {BTfun, {{\[DoubleStruckX], _Real, nx}, {\[DoubleStruckC], _Real, nc}}}}|>;

confun = RBDMergeRecipes["confun", confun];

datrules = Normal@RBDMergeRecipes["datrules", {HoldPattern[\[Alpha]0] :> fcon["\[Alpha]0"], HoldPattern[\[Alpha]T] :> fcon["\[Alpha]T"], HoldPattern[\[Alpha]\[Theta]] :> fcon["\[Alpha]\[Theta]"], HoldPattern[\[Alpha]Jp] :> fcon["\[Alpha]J[p]"]}];


(* ::Input::Initialization:: *)
GetCompilableFunctions[] := Select[con, AssociationQ[#] && KeyExistsQ[#, "name"]&];


(* ::Input::Initialization:: *)
Options[BLCompileBiped] = {"m" -> Automatic, "d" -> Automatic, "b" -> <||>, Compile -> {}}
BLCompileBiped[n_, OptionsPattern[]] := Module[{biped, cons, M, D, C},
(* compile dynamics *)
biped = Quiet@RBDLoadDynamics[n, "F" -> BLbiped["name"] <> "CompiledFunctions/"];

If[biped === $Failed,
(* new compile *)
(*cons = Select[con, AssociationQ[#] && KeyExistsQ[#, "name"]&];*)
cons = GetCompilableFunctions[];
If[Length@cons > 0,
Block[{RBDConstraintFunctions = BLConstraintFunctions}, 
biped = RBDCompileFunction[Values@cons, n, "C" -> confun, "D" -> datrules, OptionValue@Compile];
];,
(* else *)
biped = <||>;
];

M = OptionValue["m"];
If[M === Automatic,
M  = <|"left" -> ("right"&), "right" -> ("left"&)|>;
];

D = OptionValue["d"];
If[D === Automatic,
D = Function[x, x -> (BLc[x, ##]&), Listable];
D  = <|D@Keys@M|>;
];

(* set up hybrid flow *)
biped = Join[biped, OptionValue["b"]];
biped = Join[biped, <|"m" -> M, "d" -> D, "t" -> con["t"]|>];

(* save to avoid lengthy compilation in future *)
RBDSaveDynamics[biped, n, "F" -> BLbiped["name"] <> "CompiledFunctions/"];
];

\[CurlyPhi][biped, n];

(* compile continuation parameters *)
BLbiped[["\[DoubleStruckC]", All, "p"]] = Values@(p2c[#, n]& /@ con["p"]);
BLbiped[["\[DoubleStruckC]", All, "T"]] = Values@(c2c[#, n]& /@ con["cT"]);

AssociateTo[BLbiped, biped]
];


(* ::Input::Initialization:: *)
Attributes[BLDeleteCompiledFunctions] = {Listable};
BLDeleteCompiledFunctions[n_] := RBDDeleteDynamics[n, "F" -> BLbiped["name"] <> "CompiledFunctions/"];


(* ::Input::Initialization:: *)
DownValues[ConstraintFunctions]= DownValues[RBDConstraintFunctions] /. RBDConstraintFunctions -> ConstraintFunctions;

conmat::mulp = "There are multiple matrices for constraint `` of type ``; selecting first one.";

conmat[t_, n_, fcn_:True] := Module[{f},
f = Lookup[con[t], n, {}];
(* make sure zero or one matrix is selected *)
If[VectorQ[n], 
f = Select[f, MatrixQ];
If[Length@f > 0, 
If[Length@f > 1, Message[conmat::mulp, n, t]];
f = First@f;
];
];

If[fcn,
fcon[t] = RigidBodyDynamics`Private`ConvertToXLFunction[f],
fcon[t] = f
];
];

BLConstraintFunctions[name_] := Module[{C, P},
C = ConstraintFunctions[name];

conmat["P", name];
conmat["B0", name];
conmat["BT", name];
conmat["\[Alpha]0", name, False];
conmat["\[Alpha]T", name, False];
conmat["\[Alpha]\[Theta]", name, False];
conmat["\[Alpha]J[p]", name, False];

C
];


(* ::Input::Initialization:: *)
Pfun[x_:{}, \[Lambda]_:{}] := EvaluateFunction["P", x, \[Lambda]];
B0fun[x_:{}, \[Lambda]_:{}] := EvaluateFunction["B0", x, \[Lambda]];
BTfun[x_:{}, \[Lambda]_:{}] := EvaluateFunction["BT", x, \[Lambda]];

EvaluateFunction[t_, x_:{}, \[Lambda]_:{}] := Module[{f, a, b},
f = fcon[t];
a = If[x === {}, Array[\[DoubleStruckX], nx], x];
b = If[\[Lambda] === {}, Array[\[DoubleStruckC], nc], \[Lambda]];
f[a, b]
];


(* ::Input::Initialization:: *)
BeginPackage["BipedalLocomotion`Model`", {"GlobalVariables`", "RigidBodyDynamics`", "HybridDynamics`", "BipedalLocomotion`"}];

Begin["`Private`"];

BLF[x_:{}, \[Lambda]_:{}] := Module[{p, vJ},
RBDEOM[x, \[Lambda]];
RigidBodyDynamics`Private`UpperTriangularizeAb[];
Block[{Pfun = Pfun[x, \[Lambda]]}, Ucon[]];
RigidBodyDynamics`Private`F[]
];

BLH[x_:{}, \[Lambda]_:{}] := Module[{p, vJ},
RBDIME[x, \[Lambda]];
RigidBodyDynamics`Private`H[]
];

End[];
EndPackage[];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
