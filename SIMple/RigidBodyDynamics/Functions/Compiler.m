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
CoreDynamicAlgorithms.nb: An implementation of the RNEA algorithm
and its derivative.
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
BeginPackage["RigidBodyDynamics`", {"GlobalVariables`", "Derivatives`"}]
Begin["`Private`"]


(* ::Input::Initialization:: *)
Options[RBDSaveDynamics] = {"D" -> Automatic, "F" -> Automatic};

RBDSaveDynamics[rbd_, n_, OptionsPattern[]] := Module[{dir, fil},
fil = OptionValue["F"];
If[fil === Automatic, fil = "CompiledFunctions";];

dir = OptionValue["D"];
dir = If[dir === Automatic, {NotebookDirectory[], fil}, {dir, fil}];
dir = FileNameJoin@Flatten@dir;

If[!DirectoryQ[dir], CreateDirectory[dir];];

Export[FileNameJoin[{dir, "rbd-" <> ToString[n] <> ".mx"}], rbd]
];


(* ::Input::Initialization:: *)
Attributes[RBDDeleteDynamics] = {Listable};

Options[RBDDeleteDynamics] = {"D" -> Automatic, "F" -> Automatic};

RBDDeleteDynamics[n_, OptionsPattern[]] := Module[{dir, fil},
fil = OptionValue["F"];
If[fil === Automatic, fil = "CompiledFunctions";];

dir = OptionValue["D"];
dir = If[dir === Automatic, {NotebookDirectory[], fil}, {dir, fil}];
dir = FileNameJoin@Flatten@dir;

If[DirectoryQ[dir], DeleteDirectory[dir, DeleteContents->True]]
];


(* ::Input::Initialization:: *)
Options[RBDLoadDynamics] = {"D" -> Automatic, "F" -> Automatic};

RBDLoadDynamics::dir = "`` does not exist.";

RBDLoadDynamics[n_, OptionsPattern[]] := Module[{rbd, lib, dir, fil, d},
fil = OptionValue["F"];
If[fil === Automatic, fil = "CompiledFunctions";];

dir = OptionValue["D"];
dir = If[dir === Automatic, {NotebookDirectory[], fil}, {dir, fil}];
dir = FileNameJoin@Flatten@dir;

If[!DirectoryQ[dir], 
Message[RBDLoadDynamics::dir, dir]; 
Return[$Failed];
];

Import[FileNameJoin[{dir, "rbd-" <> ToString[n] <> ".mx"}]]
];


(* ::Input::Initialization:: *)
SetAttributes[CompileArgs, HoldFirst];
CompileArgs[v_, n_, list_:True] := Module[{a},
a = Thread/@Thread[\[FormalP]@v];
a[[All, 2;;3]] = a[[All, 2;;3]] /. \[FormalP][a_] :> a;
If[list, a[[All, 3]] = If[IntegerQ[#], 1, Length@#]& /@ a[[All, 3]];];

Table[
(* wrap args in Hold *)
{CreateSymbol[Evaluate@i[[1]], j, Hold], i[[2]], i[[3]]+j}, 
{i, a}, {j, 0, n}
]
];


(* ::Input::Initialization:: *)
SetAttributes[RBDCompileExpression, HoldRest];

RBDCompileExpression[F_Association, n_:0, o:OptionsPattern[Compile]] := Module[{f, v, c},
(* add relevant variable to depth *)
v = {v_Symbol, i_Integer} :> depth[v, i, n];
f = Hold["O"]/. F;

If[f =!= Hold["O"] && f =!= Hold[{}], 
ReleaseHold[f[[All, All, {1, 3}]] /. v];
];

(* compile functions *)
f =Hold["I"] /. F;
If[f =!= Hold["I"] && f =!= Hold@{},
f =Thread[f];
c = RBDCompileExpression;
v = Hold[{x_, y_}] :> c[ToString@Unevaluated@x, x, y, n, o];
Association[f /. v],
<||>
]
];

SetAttributes[timer, HoldFirst];
timlst = {};
timer[x_, f_, n_] := Module[{s, t,r},
(*PrependTo[timlst, StringTemplate["`` in `` "][n, f]];*)
PrependTo[timlst, ToString@Unevaluated@n <> " in " <> ToString@Unevaluated@f];
(*Print[Row@timlst];*)
{t, r} = AbsoluteTiming[x];
s = First@timlst;
timlst = Rest@timlst;
Print["\t", s, "took " <> ToString@t <> " seconds."];
r
];

RBDCompileExpression[name_String, expr_, a_, n_:0, o:OptionsPattern[Compile]] := Module[{s, v, f},
(* diff name *)
s = CreateSymbolString[name, #]& /@ Range[0, n];
(* get Compile arguments *)
v = CompileArgs[a, n];
(* replace "b" with args in a *)

ReleaseHold[
Hold@Block["b", 
SetAttributes["b", NHoldAll];
(* differentiate pure function *)
v = Select[a[[All, {1,3}]], Times@@#[[2]] > 0&];
f = If[TensorQ[expr] || NumericQ[expr], (expr&), (expr[##]&)];
f = N@First@Df[{{f}, v}, "ch", D -> n];
f= DfToCompiledFunction[f, a[[All, {1,3}]], a[[All, 2]], o];
] /. "b" -> Flatten[v[[All, All, 1]]] /. Hold[x_Symbol] :> x
];
AssociationThread[s -> f]
];


(* ::Input::Initialization:: *)
Options[RBDCompileFunction] = {"S" -> spatfun, "C" -> confun, "D" -> datrules, "a" -> {1,2}, "e" -> {}, "f" -> {CompilationOptions->{"InlineCompiledFunctions"->True, "ExpressionOptimization"->True}, CompilationTarget -> "C"}};

RBDCompileFunction[F_List, n_, opts:OptionsPattern[]] := Module[{f, a, d, A, S, C, D, slot, part},
(* don't use variable slot, must be kept a symbol *)
S = OptionValue["S"];
C = OptionValue["C"];
D = OptionValue["D"];

(* extract fcns in S & C and create replacement rule: f \[RuleDelayed] f[x] *)
A = Join@@(CreateInlinedFunctionHeaders[#, n]& /@ {S, C});

(* compile functions in S once and create rep rules: *)
S = RulesForInlinedFunctions[S, n, OptionValue["e"]];

{A, S} = Dispatch /@ {A, S};
Association@Table[
(* compile constraints *)
f= Table[
(* tie arguments of f to variables in "v" and "d" *)
d = JoinInputArguments[Fi, n][[All, 1]];
f = Hold["f"]@@d  /. A ;

(* replace independent args w/ Slot[...]; slot should be a symbol here *)
a = Partition[d, n+1][[OptionValue["a"]]];
f = InsertDevecedArguments[f, a];

(* add family of S fcns *)
f = f /. S;

(* add in family of C fcns *)
RBDConstraintFunctions[Fi["C", c]]; (* should consider making this a parameter to pass in... *)
d = RulesForInlinedFunctions[C, n, OptionValue["e"]];
f = f /. d /. Block[{RuleDelayed = Rule}, D];

c -> f,
{c, Keys@Fi["C"]}
];

(* compile function in F *)
f = f /. "f" -> CompileFunction[Fi, n, OptionValue["f"]];
f = f /. Hold[x_] :> x;

(* newest addition --- does not work with NDSolve *)
(*d = With[{g = #}, SparseArray[g@@(Map[Normal, {##}, {2}])]&]&;
f = d /@ Association[f];
Fi["name"] \[Rule] f*)

Fi["name"] -> Association[f],
{Fi, F}
]
];


(* ::Input::Initialization:: *)
JoinInputArguments[F_Association, n_] := Module[{d},
(* merge "v" and "d" without evaluating values into one argument list *)
d = {Hold[CompileArgs["v", n, False]], Hold[CompileArgs["d", 0, False]]};
d = d /. F;
(* extract symbolic arg only, drop type and depth *)
Partition[Flatten[ReleaseHold[d]], 3]
]

InsertDevecedArguments[f_, args_] := Module[{a, p, s},
(* replace independent args w/ Slot[i]\[LeftDoubleBracket]j\[RightDoubleBracket], where j depends on devec[..] *)
a = MapIndexed[(#1 -> p[s[#2[[1]]], #2[[2]]])&, args, {2}];
a = Flatten@a /. {Hold -> HoldPattern};
With[{e = f}, e&] /. a /. s -> Slot /. p -> Part
];

RulesForInlinedFunctions[S_, n_, o:OptionsPattern[]] := Module[{f},
(* create replacement rules for arguments of f *)
f = ToExpression[#1, InputForm, HoldPattern] :> #2&;
(* compile functions in A and create rep rules: *)
(* HoldPattern[f] \[RuleDelayed] CompiledFunction *)
KeyValueMap[f, RBDCompileExpression[S, n, o]]
];

CreateInlinedFunctionHeaders[S_Association, n_] := Module[{A, a, f},
(* extract fcns in A and create replacement rule: f \[RuleDelayed] f[x] *)
A = Hold["I"] /. S;

If[A =!= Hold["I"] && A =!= Hold[{}], 
With[{e = A},
BlockExpression[{},
(* create 0-th order function call *)
a = {#[[1]], #[[1]]@@(#[[2, All, 1]])}& /@ Join@ReleaseHold[e];
(* expand up to n-th order function call *)
f = Table[CreateSymbol[\[FormalP][#], i, Hold], {i, 0, n}]&;
a = Map[f, a, {2}];
(* create HoldPattern[f] \[RuleDelayed] f[x, ...] *)
a = MapThread[HoldPattern[#1] :> #2&, a\[Transpose], 2];
Flatten@a /. Hold[x_] :> x, 
{CreateSymbol, a, Hold, Join}
]
],
{}
]
];

CompileFunction[F_Association, n_, opts:OptionsPattern[Compile]] := Module[{f, i, d, C, I},
(* compile inline expressions; override inline with F's, if key collision *)
I = RBDCompileExpression[F[[{"I", "O"}]], n];

f = ToExpression["HoldPattern[" <> # <> "]"]&;
I = KeyMap[f, I];

(* add "v" and "d" to depth[...] *)
f = Hold["v"]/. F;
If[f =!= Hold["v"] && f =!= Hold[{}], 
ReleaseHold[f[[All, All, {1, 3}]] /. {v_Symbol, i_Integer} :> depth[v, i, n]];
];

f = Hold["d"]/. F;
If[f =!= Hold["d"] && f =!= Hold[{}], 
ReleaseHold[f[[All, All, {1, 3}]] /. {v_Symbol, i_Integer} :> depth[v, i, 0]];
];

(* create function to compile *)
f = ReleaseHold[Hold@MergeFunctions["f", C[], "lcls", n] /. F];

(* take out index variables that aren't directly given a value *)
i = Cases[f, HoldPattern[(Do|Table)[_, x__]] :> Hold[x], Infinity];
d = {i_, x_, ___} :> Hold@SetDelayed[depth[i], depth[x]-If[Total[depth[x]] == 0, 0, {-1, 0}]];
ReleaseHold@Cases[i, d, Infinity];

(* do some post-procesing clean up on differentiated function *)
f = FixLinearSolve@FixDotProducts@FixFunctions[f];

(* merge "v" and "d" without evaluating values into one argument list *)
d = "v" :> Evaluate@JoinInputArguments[F, n] /. Hold[x_] :> x;

(* create Compile *)
f = Hold[Compile["v", C[], opts]] /. d /. C -> CreateSymbol[C, n] /. f;
f = f /. Normal@I;

(* compile function *)
ReleaseHold[f]
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
