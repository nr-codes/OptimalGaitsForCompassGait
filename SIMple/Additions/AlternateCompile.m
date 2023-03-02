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
Options[AlternateCompile] = {"cons" -> None, "n" -> 2, Compile -> {}, LinearSolve -> Method->Automatic(*"Krylov"*), "v" :> {{\[DoubleStruckX], nx}, {\[DoubleStruckC], nc}}};


(* ::Input::Initialization:: *)
AlternateCompile[A0_?MatrixQ, A1_:{}, A2_:{}] := Module[{n, r, c, e},
(* n\[LeftDoubleBracket]1;;2\[RightDoubleBracket] = {i, j} of A0 and n\[LeftDoubleBracket]3;;4\[RightDoubleBracket] = derivatives *)
n = Which[
A1 === {}, PadRight[Dimensions[A0], 4],
A2 === {}, PadRight[Dimensions[A1], 4],
True, Dimensions[A2]
];

r = n[[1]] + n[[1]] n[[3]] + n[[1]] n[[3]] n[[4]];
c = n[[2]] + n[[2]] n[[3]] + n[[2]] n[[3]] n[[4]];

e = Flatten[{
(* column entries for 0th-order derivative values *)
Table[{i, j} -> A0[[i, j]], {i, n[[1]]}, {j, n[[2]]}],
Table[{k+ n[[1]] + n[[3]] (i-1), j} -> A1[[i, j, k]], {i, n[[1]]}, {j, n[[2]]}, {k, n[[3]]}],
Table[{m+ n[[1]] + n[[1]] n[[3]] + n[[4]] n[[3]] (i-1) + n[[4]] (k-1), j} -> A2[[i, j, k, m]], {i, n[[1]]}, {j, n[[2]]}, {k, n[[3]]}, {m, n[[4]]}],

(* column entries for 1st-order derivative values *)
Table[{k + n[[1]] + n[[3]] (i-1), k + n[[2]] + n[[3]] (j-1)} -> A0[[i, j]], {i, n[[1]]}, {j, n[[2]]}, {k, n[[3]]}],
Table[ If[m == k, 
{m + n[[1]] + n[[1]] n[[3]] + n[[4]] n[[3]] (i-1) + n[[4]] (k-1), m + n[[2]] + n[[3]] (j-1)} ->2A1[[i, j, k]], 
(* else *)
{
{m + n[[1]] + n[[1]] n[[3]] + n[[4]] n[[3]] (i-1) + n[[4]] (k-1), m + n[[2]] + n[[3]] (j-1)} -> A1[[i, j, k]],

{m + n[[1]] + n[[1]] n[[3]] + n[[4]] n[[3]] (i-1) + n[[4]] (k-1), k + n[[2]] + n[[4]] (j-1)} -> A1[[i, j, m]]
}
], {i, n[[1]]}, {j, n[[2]]}, {k, n[[3]]}, {m, n[[4]]}],

(* column entries for 2nd-order derivative values *)
Table[{m + n[[1]] + n[[1]] n[[3]] + n[[4]] n[[3]] (i-1) + n[[4]] (k-1), m + n[[2]] + n[[2]] n[[3]] + n[[4]] n[[3]] (j-1) + n[[4]] (k-1)} -> A0[[i, j]], {i, n[[1]]}, {j, n[[2]]}, {k, n[[3]]}, {m, n[[4]]}]
}];

(* wrap in SparseArray to keep dimensions *)
SparseArray[e, {r, c}]
];

AlternateCompile[v0_?VectorQ, v1_:{}, v2_:{}] := Module[{n, r, c, e},
SparseArray@Flatten[{v0, v1, v2}]
];


(* ::Input::Initialization:: *)
AlternateCompile[D, f_, OptionsPattern[]] := Module[{x, c, v, exp, n},
c = OptionValue["cons"];
RBDConstraintFunctions[c];

v = OptionValue["v"];
v = MapThread[Array, v\[Transpose]];
exp = RBDExpandExpression[(f@@v), TimeConstraint -> 15];

v = Flatten@v;
If[exp === {},  
exp,
(* else *)
exp = D[exp, {v, #}]& /@ Range[0, OptionValue["n"]];
AlternateCompile@@exp
]
];


(* ::Input::Initialization:: *)
AlternateCompile["Ab", f_, opts:OptionsPattern[]] := Module[{A, b, d},
A = AlternateCompile[D, f[##][[All, ;;-2]]&, opts];
b = AlternateCompile[D, f[##][[All, -1]]&, opts];

d = Dimensions@A + {0, 1};
A = ArrayRules[A][[;;-2]];
b = ArrayRules[b][[;;-2]]/. Rule[x_, y_] :> Rule[Join[x, {d[[2]]}], y];

SparseArray[Join[A, b], d]
];


(* ::Input::Initialization:: *)
AlternateCompile[RBDEOM, opts:OptionsPattern[]] := Module[{},
AlternateCompile["Ab", RBDEOM[#1, #2]&, opts]
];

AlternateCompile[RBDIME, opts:OptionsPattern[]] := Module[{I},
I = Module[{ime, q, \[Alpha]},
ime = RBDIME[#1, #2];
\[Alpha] = Lookup[fcon, "\[Alpha]\[Theta]", {}];
If[\[Alpha] === {}, \[Alpha] = {0, 1};]; (* sometimes key exists but is {} *)
q = #1[[1;;nq]];
Block[{\[Alpha]\[Theta] = \[Alpha], RigidBodyDynamics`Private`q = q},
\[Theta]0[];
\[Alpha] = IdentityMatrix[nq];
ArrayFlatten[{{\[Alpha], 0, {RigidBodyDynamics`Private`q}\[Transpose]}, {0, ime[[All, 1;;-2]], {ime[[All, -1]]}\[Transpose]}}]
]
]&;

AlternateCompile["Ab", I, opts]
];

AlternateCompile[RBDJ, opts:OptionsPattern[]] := Module[{J, \[Phi]},
J = RBDJ[#1, #2][[1]]&;
\[Phi] = RBDJ[#1, #2][[2]]&;
J = AlternateCompile[D, J, opts];
\[Phi] = AlternateCompile[D, \[Phi], opts];
];

AlternateCompile[RBD\[Eta], opts:OptionsPattern[]] := Module[{\[Eta]},
AlternateCompile[D, Flatten@RBD\[Eta][#1, #2]&, opts]
];


(* ::Input::Initialization:: *)
AlternateCompile[Compile, {}, OptionsPattern[]] := {}

AlternateCompile[SparseArray, x_, c_, {}, OptionsPattern[]] := {};

AlternateCompile[Compile, A_SparseArray, OptionsPattern[]] := Module[{i, e, d, v, r, a},
i = ArrayRules[A][[All, 1]][[;;-2]];
e = ArrayRules[A][[All, 2]][[;;-2]];
d = Dimensions@A;

v = OptionValue["v"];
a = v[[All, 1]];
v = {#, _Real, 1}& /@ a;
r = (#[i_] :> #[[i]])& /@ a;

ReleaseHold[Hold[
Block["a",
SetAttributes["a", NHoldAll];
<|
"i" -> i, 
"f" -> ReleaseHold@With[{exp = N@e, o = OptionValue[Compile]},
Hold@Compile["var", exp, o] /. r], 
"d" -> d
|>
]
] /. {"a" -> a, "var" -> v}
]
];

AlternateCompile[SparseArray, args__, A_Association, OptionsPattern[]] := Module[{i, e, d},
i = A["i"];
e = A["f"][args];
d = A["d"];
SparseArray[i -> e, d]
];

AlternateCompile[Return, args__, A_Association, opts:OptionsPattern[]] := Module[{f, v, d},
v = {args};
f = AlternateCompile[SparseArray, Sequence@@v[[All, 1]], A, opts];
If[MatrixQ[f], 
f = LinearSolve[f[[All, ;;-2]], f[[All, -1]], OptionValue@LinearSolve];
];

(* devec f(v(p)) *)
v = SparseArray /@ MapThread[Join, v];
d = Length@v[[1]];

d = Length[f]/Sum[d^i, {i, 0, OptionValue["n"]}];
f = devec[f, d];

(* chain rule for f(v(p)) *)
If[Length@v > 2, f[[3]] =((v[[2]]\[Transpose] . (f[[3]] . v[[2]])\[Transpose])\[Transpose] + f[[2]] . v[[3]]);];
If[Length@v > 1, f[[2]] = f[[2]] . v[[2]];];
f
];


(* ::Input::Initialization:: *)
AlternateCompile["f", opts:OptionsPattern[]] := Module[{Ab},
Ab = AlternateCompile[RBDEOM, opts];
AlternateCompile[Compile, Ab, opts]
];

AlternateCompile["h", opts:OptionsPattern[]] := Module[{Ab},
Ab = AlternateCompile[RBDIME, opts];
AlternateCompile[Compile, Ab, opts]
];

AlternateCompile["\[Eta]", opts:OptionsPattern[]] := Module[{\[Eta]},
\[Eta] = AlternateCompile[RBD\[Eta], opts];
AlternateCompile[Compile, \[Eta], opts]
];


(* ::Input::Initialization:: *)
AlternateCompile["\[Eta]0", opts:OptionsPattern[]] := Module[{\[Eta]},
\[Eta] = Module[{x, c, a, b, \[Alpha], B, r},
x = Array[a, Dimensions@#1];
c = Array[b, Dimensions@#2];
r = Thread[Join[x, c] -> Join[#1, #2]];
RBDJ[x, c];
B = B0fun[x, c];
\[Alpha] = Lookup[fcon, "\[Alpha]0", {{}, {}}];
Block[{\[Alpha]0= \[Alpha], \[DoubleStruckC] = c, B0fun = B}, \[Eta]0[]]/. r
]&;

\[Eta] = AlternateCompile[D, \[Eta], opts];
AlternateCompile[Compile, \[Eta], opts]
];

AlternateCompile["\[Eta]T", opts:OptionsPattern[]] := Module[{\[Eta]},
\[Eta] = Module[{x, c, a, b, \[Alpha], B, r},
x = Array[a, Dimensions@#1];
c = Array[b, Dimensions@#2];
r = Thread[Join[x, c] -> Join[#1, #2]];
RBDJ[x, c];
B = BTfun[x, c];
\[Alpha] = Lookup[fcon, "\[Alpha]T", {{}, {}}];
Block[{\[Alpha]T= \[Alpha], \[DoubleStruckC] = c, BTfun = B}, \[Eta]T[]]/. r
]&;

\[Eta] = AlternateCompile[D, \[Eta], opts];
AlternateCompile[Compile, \[Eta], opts]
];

AlternateCompile["J[p]", opts:OptionsPattern[]] := Module[{\[Eta]},
\[Eta] = Block[{\[Alpha]Jp= fcon["\[Alpha]J[p]"]}, RBDJ[#1, #2]; Jac[]]&;
\[Eta] = AlternateCompile[D, \[Eta], opts];
AlternateCompile[Compile, \[Eta], opts]
];

AlternateCompile["\[Sigma]", opts:OptionsPattern[]] := Module[{\[Alpha], \[Eta]},
\[Eta] = Module[{st, sw},
RBDJ[#1, #2];
(* difference of foot locations *)
st = RigidBodyDynamics`Private`\[Eta][[1, 1;;mm]];
sw = RigidBodyDynamics`Private`\[Eta][[1, mm+1;;nm]];
With[{a = sw - st},
{Piecewise[{{ArcTan[a[[2]], a[[3]]], a[[2]] != 0 || a[[3]] != 0}}],
Piecewise[{{ArcTan[a[[1]], a[[3]]], a[[1]] != 0 || a[[3]] != 0}}],
Piecewise[{{ArcTan[a[[1]], a[[2]]], a[[1]] != 0 || a[[2]] != 0}}]}
]]&;
\[Eta] = AlternateCompile[D, \[Eta], opts];
AlternateCompile[Compile, \[Eta], opts]
];

AlternateCompile["cost", opts:OptionsPattern[]] := Module[{L},
L = Module[{u, M}, 
u = ufun@##;
(*M = RBDM[#1, #2];*)
(*{0.0, 0.0, PiecewiseExpand[u.u], PiecewiseExpand[u.M.#1\[LeftDoubleBracket]nq+1;;nx\[RightDoubleBracket]]}*)
{0.0, 0.0, PiecewiseExpand[u . u, TimeConstraint -> 1], 0.0}
]&;

L = AlternateCompile[D, L, opts];
AlternateCompile[Compile, L, opts]
];

AlternateCompile["u", opts:OptionsPattern[]] := Module[{u},
u = AlternateCompile[D, ufun, opts];
AlternateCompile[Compile, u, opts]
];

AlternateCompile[s_String /; StringMatchQ[s, {"\[Eta]p","\[Eta]v","\[Eta]a","\[Eta]d", "xT","foot"}], opts:OptionsPattern[]] := AlternateCompile["\[Eta]", opts];

AlternateCompile[f:"fosim"|"hosim", opts:OptionsPattern[]] := AlternateCompile[StringPart[f, 1], opts];

AlternateCompile::args = "Unknown argument: `1`.";
AlternateCompile[n_String, ___] := Message[AlternateCompile::args, n];


(* ::Input::Initialization:: *)
BLAlternateCompile[opts:OptionsPattern[]] := Module[{c, n, A},
c = con;
c = Select[c, KeyExistsQ[#, "name"]&][[All, {"name", "C"}]];
Block[{RBDConstraintFunctions = BLConstraintFunctions},
n = Flatten@Table[
n = c[k, "name"];
A = AlternateCompile[n, "cons" -> c[k, "C", m], opts];
n -> m -> BLAlternateCompile[Return, n, A, opts],
{k, Keys@c}, {m, Keys@c[k, "C"]}];
];
Merge[n, Association@@#&]
];

BLAlternateCompile[Return, "f", A_, opts:OptionsPattern[]] := Flatten@MapThread[Join, {#1[[All, nq+1;;nx]], AlternateCompile[Return, ##, A, opts][[All, 1;;nq]]}]&;

BLAlternateCompile[Return, "h", A_, opts:OptionsPattern[]] := Module[{h},
Flatten@AlternateCompile[Return, ##, A, opts][[All, 1;;nx]]
]&;

BLAlternateCompile[Return, _String, A_, opts:OptionsPattern[]] := Flatten@AlternateCompile[Return, ##, A, opts]&;


(* ::Input::Initialization:: *)
Options[BLAlternateCompileWithInputSpline] = {BLAlternateCompile -> {}, CompileWithInputSpline -> {}};

BLAlternateCompileWithInputSpline[ci_, ti_, opts:OptionsPattern[]] := Module[{n, o, ao, bo},
ao = OptionValue@BLAlternateCompile;
bo = OptionValue@CompileWithInputSpline;

Block[{\[DoubleStruckU], ufun},
(* compile biped *)
n = OptionValue[CompileWithInputSpline, bo, BLCompileBiped];
o = {ao, "v" -> {{\[DoubleStruckX], nx}, {\[DoubleStruckC], nc}, {\[DoubleStruckU], nq}}};
ufun = Array[\[DoubleStruckU], nq]&;
BLAlternateCompileBiped[BLCompileBiped -> n, BLAlternateCompile -> o];

(* compile u *)
n = OptionValue[AlternateCompile, ao, "n"];
Block[{BLCompileBiped},
CompileWithInputSpline[n, ci, ti, bo]
]
]
];

Options[BLAlternateCompileBiped] = {BLAlternateCompile -> {}, BLCompileBiped -> {}};

BLAlternateCompileBiped[opts:OptionsPattern[]] := Module[{ao, bo, n},
ao = OptionValue@BLAlternateCompile;
bo = OptionValue@BLCompileBiped;
n = OptionValue[AlternateCompile, ao, "n"];
Block[{RBDCompileFunction = BLAlternateCompile[ao]&},
BLCompileBiped[n, bo]
]
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]


