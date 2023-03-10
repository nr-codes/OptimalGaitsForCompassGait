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
BeginPackage["BipedalLocomotion`", {"GlobalVariables`", "RigidBodyDynamics`", "HybridDynamics`", "BipedalLocomotion`Model`", "MaTeX`"}]

Begin["`Private`"]

tol = 10^-5; (* minimum distance between two links *)

lc = Gray; (* default link color *)

jc = White;

sc = {Black};
fc = {LightGray};

ground = {z6, I6[[mm+1]]};

widths = {0.01, 0.01, 0.01};

r = 0.025; (* joint radius *)

axes = {1,2,3};

ignorejoint = ignorelink = ignore = {Root, "\[Theta]"};

poi = {};
scale = 1;

paths = <|
"Local" -> DirectoryName@$InputFileName,
"Figures" -> "../../../Figures",
"JSON" -> "../../../GaitBrowser/src/bipeds",
"Images" -> "../../../GaitBrowser/app/imgs",
"Here" :>  StringReplace[NotebookDirectory[], ___~~"Models" -> "../../../Models"]
|>;

BLPath[where_, n_] := Module[{path},
path = Lookup[paths, where, $Failed];
FileNameJoin[{paths["Local"],path, n}]
];

BLExportTo[where_, n_, d_, opts:OptionsPattern[]] := Export[BLPath[where, n], d,opts];

BLImportFrom[where_, n_, opts:OptionsPattern[]] := Import[BLPath[where, n], opts];

Attributes[BLSaveTo] = {HoldRest};
BLSaveTo[where_, n_, d_] := Save[BLPath[where, n], d];

BLGetFrom[where_, n_, opts:OptionsPattern[]] := Get[BLPath[where, n], opts];

(* IEEETran/LaTex info *)
(*BLLaTex = <|"text width" \[Rule] 485.1, "text height" \[Rule] 696.0, "column width" \[Rule] 236.55, "image height" \[Rule] 500|>;*)

BLLaTex = <|"text width" -> 516, "text height" -> 696, "column width" -> 252, "image height" -> 500|>;

BLTeX[e_, m_:5, pre_:""] := MaTeX[e, Magnification->m, "Preamble" ->{"\\usepackage{"<> pre <> ",color,siunitx}"}];


(* ::Input::Initialization:: *)
BLWidth[w_] := widths = If[VectorQ@w, w[[1;;3]], {w, w, w}];

BLRadius[w_] := r = w;

BLLinkColor[c_] := lc = c;

BLJointColor[c_] := jc = c;

BLAxes[c_] := axes = c;

BLScaleLengths[n_:1] := scale = n;

BLDontDraw[lname_:{}, jname_:{}] := Module[{},
ignorelink = DeleteDuplicates[Join[ignore, Flatten@{lname}]];
ignorejoint = DeleteDuplicates[Join[ignore, Flatten@{jname}]]
];


(* ::Input::Initialization:: *)
Link[p_, c_, color_, axes_] := Module[{wl, wu, u, v, l, m, R, C, A},
m = Length@p;
v = c - p;
l = Norm[v];
u = PadLeft[{l}, m];

(* set rectangular bounding box *)
wl = -widths[[axes]];
wl[[-1]] = 0;
wu = widths[[axes]];
wu[[-1]] = l;

(* ignore "RotationMatrix vectors do not define a plane" warning *)
R = If[PossibleZeroQ[l], 
ConstantArray[0, {m, m}], 
Quiet[RotationMatrix[{u, v}], RotationMatrix::spln]
];

C = Cuboid[wl, wu];
A = AffineTransform[{R, p}];

{EdgeForm[{Thick, Black}], color, Thick, GeometricTransformation[C, A]}
];

Joint[pos_, color_] := {EdgeForm[{Thick, Black}], color, Ball[pos, r]};

Options[DrawFlatGround] = {"axes" :> Lookup[BLbiped["draw", "axes"], axes], "g" -> True, "o" -> z3};

DrawFlatGround[OptionsPattern[]] := Module[{g, o},
If[OptionValue["g"], 
(* origin is assumed to be in axes order *)
o = OptionValue["o"];
If[Length@OptionValue["axes"] == 2,
o = o+#& /@ ground[[All, 4;;5]];
Join[sc(*fc*), {InfiniteLine[o]}],
(* else flat ground is 3D *)
{}
], 
{}
]
];

PiecewiseLinearSurface[\[CurlyPhi]_, d_, OptionsPattern[]] := Module[{ax, p, g, n, pts, ends, mids},
ax = mm + Lookup[d, "axes", axes];
n = {{1},1, All}; (* should generalize to take all possible slopes, or use opts to select specific slopes *)
(*n = OptionValue["\[Sigma][i]"];
If[n === Automatic, n = {{1},1, All}];*)

p = BLGetFootFalls[\[CurlyPhi]];
If[p === {}, Return[{}]];
p = p[[Sequence@@n, ax]];
p = p/Lookup[d, "scale", scale];

pts = Join@@p;
n = Length@pts;
ends = If[n > 2, HalfLine /@ pts[[{1, -1}]], List@InfiniteLine@pts];
mids = If[n > 3, Line /@ pts[[2;;-2]], {}];
Join[fc, {InfiniteLine[g]}, sc, ends, mids]
];

Options[OneSurface] = {"m" :> BLbiped["m[0]"], "g" -> True};
OneSurface[\[CurlyPhi]_, d_, OptionsPattern[]] := Module[{m, n, \[Sigma], x, c, ax, p, g},
ax = mm + Lookup[d, "axes", axes];
n = Lookup[d, "\[Sigma]", Automatic];

(* compute slope *)
c = If[AssociationQ[\[CurlyPhi]],  \[CurlyPhi]["c[t]"][0], \[CurlyPhi]];
c = devec[c, nc];
x = c[[All, 1;;nx]];

(* get post-impact m *)
m = OptionValue["m"];
(*m = BLSide[m, Automatic, 2];*)
m = BLbiped["m"][m][x, c];

\[Sigma] = BLbiped["\[Sigma]", m][x, c];
\[Sigma] = \[Sigma][[1;;mm]];

(* get (post-impact) stance foot location *)
p = BLbiped["\[Eta]a", m][x, c][[ax - mm]];
p = p/Lookup[d, "scale", scale];

g = DrawFlatGround["o" -> p, "g"-> OptionValue["g"], "axes" -> ax];

If[Length[ax] == 2,
If[n === Automatic, n = First@Complement[Range[mm+1, nm],  ax]-mm;];
\[Sigma] = \[Sigma][[n]];
Join[g, {sc, InfiniteLine[p, RotationMatrix[\[Sigma]] . {1, 0}]}],
(* else biped is 3D *)
If[n === Automatic, n = ax;];
n = n - mm;

\[Sigma] = \[Sigma][[n]];
x = IdentityMatrix[mm];

{sc, InfinitePlane[p, {RotationMatrix[\[Sigma][[2]], -x[[2]]] . x[[1]], RotationMatrix[\[Sigma][[3]], x[[3]]] . x[[2]]}]}
]
];

Options[BLWalkingSurface] = {"b" :> Lookup[BLbiped, "draw", <||>], "\[Sigma][i]" -> Automatic, SurfaceData -> OneSurface, "g" -> True, "SurfaceDataOptions" -> {}};

BLWalkingSurface[\[CurlyPhi]_, opts:OptionsPattern[]] := Module[{x, c, f, d, g, ax, \[Sigma]},
If[\[CurlyPhi] === None, Return[{}]];

d = OptionValue["b"];
ax = mm + Lookup[d, "axes", axes];

If[Length@ax == 2,
OptionValue[SurfaceData][\[CurlyPhi], d, OptionValue["SurfaceDataOptions"]],
OptionValue[SurfaceData][\[CurlyPhi], d, OptionValue["SurfaceDataOptions"]]
]
];


(* ::Input::Initialization:: *)
Options[LinkPositions] = {"b" :> Lookup[BLbiped, "draw", <||>]};

LinkPositions[x_, c_, OptionsPattern[]] := Module[{a, b, d, X, L, f, pos, ax},
a = Flatten[x][[1;;nx]];
b = Flatten[c][[1;;nc]];

d = OptionValue["b"]; (* extract draw options *)

(* get position of link in world frame *)
X = XL0fun[a, b];
L = RBDGetLinkInfo["p"];

f = RBDSpatialPosition[X, z3, #, "x" -> a, "\[Lambda]" -> b][[4;;6]]&;
pos = <||>;
Do[pos[k] = f[k], {k, Keys@L}];
pos[Root] = z3;

(* add POIs *)
ax = Lookup[d, "poi", <||>];
f = RBDSpatialPosition[X, #3, #1][[4;;6]]&;
Do[
L[k] = Block[{\[DoubleStruckB] = #1&}, ax[k]];
pos[k] = Block[{\[DoubleStruckB] = f}, ax[k]];, 
{k, Keys@ax}
];

(* hack *)
pos = # /. {\[DoubleStruckX][i_] :> a[[i]], \[DoubleStruckC][i_] :> b[[i]]}& /@ pos;

(* scale model and get axes to draw on *)
ax = Lookup[d, "axes", axes];
pos = pos/Lookup[d, "scale", scale];
pos = pos[[All, ax]];

{pos, L}
]


(* ::Input::Initialization:: *)
BLWrap[f_, c_, opts:OptionsPattern[]] := Module[{C},
C = BLc[BLbiped["m[0]"], c];
f[C[[All, 1;;nx]], C, opts]
];


(* ::Input::Initialization:: *)
Options[BLDrawBiped] = {Graphics -> {}, "b" :> Lookup[BLbiped, "draw", <||>], "\[CurlyPhi]" -> None, BLWalkingSurface -> {}};

BLDrawBiped[x_, c_, OptionsPattern[]] := Module[{ax, a, b, d, X, L, J, f, pos, \[Sigma]},
d = OptionValue["b"]; (* extract draw options *)
ax = Lookup[d, "axes", axes];(* get axes to draw on *)
{pos, L} = LinkPositions[x, c, "b" -> d];

(* get lengths *)
a = Association[# -> Norm[pos[#]-pos[L@#]]& /@ Keys@L];

(* get graphics of links *)
b = Lookup[d, "lc", <||>];
f = #1 -> Link[pos[#2], pos[#1], Lookup[b, #1, lc], ax]&;
L = KeyValueMap[f, L];

(* drop unwanted links and joints *)
f = L[#] === Root || MemberQ[ignorelink, #]||a[#] <= tol&;
a = Select[Keys@L, f];
L = Values@KeyDrop[L, a];

b = Lookup[d, "jc", <||>];
a = Complement[RBDGetLinkNames[], ignorejoint];
J = Joint[pos[#], Lookup[b, #, jc]]& /@ a;

(* draw slope *)
\[Sigma] = OptionValue["\[CurlyPhi]"];
\[Sigma] = BLWalkingSurface[\[Sigma], OptionValue[BLWalkingSurface], "b" -> d];

f = Lookup[d, "f", ({}&)];
X = {\[Sigma], L, J, f[x, c]};

If[Length@ax == 2,
Graphics[X, OptionValue[Graphics]],
Graphics3D[X, OptionValue[Graphics], Lighting->"Neutral", Boxed->False]
]
];


(* ::Input::Initialization:: *)
Options[BLDrawAxes] = Join[{"axlen" ->  1/8}, Options[BLDrawBiped]];
BLDrawAxes[x_, c_, opts:OptionsPattern[]] := Module[{n, l, A, T, C},
n = Complement[RBDGetLinkNames[], ignorelink];
l = OptionValue["axlen"];

T = StringTemplate["``-axis-``"];
C = Switch[#2, 4, Red, 5, Green, 6, Blue]&;
A = {T[##] -> \[DoubleStruckB][#1, {4, 5, 6}, l I6[[#2]]], T[##] -> C[##]}&;
A = Join@@Table[A[k, r],{k,  n}, {r,{4,5,6}}];

T = Association@Flatten@A[[All, 1]];
C = Association@Flatten@A[[All, 2]];

A = OptionValue["b"];
A["poi"] = Join[Lookup[A, "poi", <||>], T];
A["lc"] = Join[Lookup[A, "lc", <||>], C];

BLDrawBiped[x, c, "b" -> A, opts]
];


(* ::Input::Initialization:: *)
Options[BLDrawCOM] = Join[{"r" ->  1/8}, Options[BLDrawBiped]];

BLDrawCOM[x_, c_, opts:OptionsPattern[]] := Module[{n, L, A, T, C},
n = Complement[RBDGetLinkNames[], ignorelink];
L = RBDGetLinkInfo["inertia"][[All, 5;;7]];

T = StringTemplate["``-com-``"];
C = Yellow&;
A = {T[##] -> \[DoubleStruckB][#1, {4, 5, 6}, L[#1]], T[##] -> C[##]}&;
A = Join@@Table[A[k, r],{k,  n}, {r,{4}}];

T = Association@Flatten@A[[All, 1]];
C = Association@Flatten@A[[All, 2]];

A = OptionValue["b"];
A["poi"] = Join[Lookup[A, "poi", <||>], T];
A["lc"] = Join[Lookup[A, "lc", <||>], C];

BLDrawBiped[x, c, "b" -> A, opts]
];


(* ::Input::Initialization:: *)
SetAttributes[BLAddPOI, Listable];

Options[BLAddPOI] = {"J" -> Automatic, "C" -> Automatic};

BLAddPOI[name_, len_, OptionsPattern[]] := Module[{n, l, A, T, C},
n = OptionValue["J"];
If[n === Automatic, n = BLValues["", "r"]];

(* match \[DoubleStruckQ][name, dof-as-string] to dof axis *)
C = Switch[#2, "px"|"rx", 4, "py"|"ry", 5, "pz"|"rz", 6]&;
n = {Sequence@@#1, C@@#1}& /@ n;

(* naming convention *)
T = "``-``-"<> name;
T = StringTemplate[T];

(* match dof axis to color *)
C = OptionValue["C"];
If[C === Automatic, C = Switch[#3, 4, Blue, 5, Red, 6, Green]&];

(* put name into \[DoubleStruckB][...] and name to color *)
A = {T[##] -> \[DoubleStruckB][#1, {4, 5, 6}, len I6[[#3]]], T[##] -> C[##]}&;
A = MapThread[A,n\[Transpose]];

T = Association@Flatten@A[[All, 1]];
C = Association@Flatten@A[[All, 2]];

<|"poi" -> T, "lc" -> C|>
];

Options[BLDrawJoints] = {"len" ->  {-1/64, 1/64, 1/28}, BLAddPOI -> {}, "b" :> Lookup[BLbiped, "draw", <||>], "L" -> 0.0075, "A" -> {0.01}, "C" -> 0.03, Graphics -> {}, "O" -> 1/28, AxesOrigin -> Automatic};

BLDrawJoints[x_, c_, OptionsPattern[]] := Module[{A, B, O, pos, L, dof, lnks, ax, cyl, o, d},
(* get draw settings *)
A = OptionValue["b"];

(* add POI *)
B = OptionValue[{"len", BLAddPOI}];
B[[2]] = Sequence@@B[[2]];
B = BLAddPOI[{"cyl-b", "cyl-f", "axis"}, Sequence@@B];
B = Merge[B, Join@@#&];

O = OptionValue["O"];
O = BLAddPOI["origin", O, "J" -> BLValues[BLGetBipedBase[], "p"]];

(* get pos *)
A["poi"] = Join@@Lookup[{A, B, O}, "poi", <||>];
A["lc"] = Join@@Lookup[{A, B, O}, "lc", <||>];
{pos, L} = LinkPositions[x, c, "b" -> A];

(* add links *)
dof = Join[ignorelink, {"axis", "cyl"}];
dof = Select[dof, StringQ];
dof = KeySelect[L, StringFreeQ[#, dof]&];
B = Thickness[OptionValue["L"]];
lnks = {B, Lookup[A["lc"], #1, lc], Line[pos /@ Reverse@{##}]}&;

lnks = KeyValueMap[lnks, dof];

(* add arrows *)
dof = "axis";
dof = KeySelect[L, StringContainsQ[#, dof]&];
B = OptionValue["A"];
B = {Thickness[B[[1]]], Arrowheads[B[[-1]]]};
ax = {B[[1]], B[[-1]], A["lc", #1], Arrow[pos /@ Reverse@{##}]}&;
ax = KeyValueMap[ax, dof];

(* add cylinders *)
dof = "cyl-b";
dof = KeySelect[L, StringContainsQ[#, dof]&];
dof = {#1, StringPart[#1,;;-2] <> "f"}& /@ Keys@dof;
B = OptionValue["C"];
cyl = {Cylinder[pos /@ #, B]}& /@ dof;

(* add world frame *)
d = OptionValue[AxesOrigin];
If[d =!= False,
dof = "origin";
dof = KeySelect[L, StringContainsQ[#, dof]&];

If[d === Automatic, d = {0, 0, #[[1, 3]]}&];
B = OptionValue["A"];
B = {Thickness[B[[1]]], Arrowheads[B[[-1]]]};
O = #[[1;;2]]-ConstantArray[d@#, 2]&;
o = {B[[1]], B[[-1]], A["lc", #1], Arrow@O[pos /@ Reverse@{##}]}&;

o = KeyValueMap[o, dof];,
(* else *)
o = {};
];

Graphics3D[{lnks, cyl, ax, o}, OptionValue[Graphics], ImageSize->BLLaTex["text width"], Boxed->False]
];


(* ::Input::Initialization:: *)
BLSim[p_, opts:OptionsPattern[]] := BLSim[BLbiped["m[0]"], p, opts];

BLSim[m_String, p_, opts:OptionsPattern[]] := BLMap[Sequence@@BLmxcp[m, p], opts];


(* ::Input::Initialization:: *)
Options[BLAnimateBiped] = {BLDrawBiped -> {}, Animate -> {}, BLSim -> {}, "\[CurlyPhi]" -> Automatic, "f" -> Automatic, "Sim" -> BLSim};

BLAnimateBiped[c_?(VectorQ[#, NumericQ]&), opts:OptionsPattern[]] := BLAnimateBiped[BLbiped["m[0]"], c, opts]

BLAnimateBiped[m_String, c_, opts:OptionsPattern[]] := BLAnimateBiped[OptionValue["Sim"][m, c, OptionValue[BLSim]], opts]

BLAnimateBiped[\[CurlyPhi]_, OptionsPattern[]] := Module[{x, c, T, \[Sigma], o, f},
x = \[CurlyPhi][[1]];
c = \[CurlyPhi][[2]];
T = Flatten@x["Domain"];

\[Sigma] = OptionValue["\[CurlyPhi]"];
If[\[Sigma] === Automatic, \[Sigma] = \[CurlyPhi];];

f = OptionValue["f"];
If[f === Automatic, f = BLDrawBiped;];

(* compute a bounding box? *)
o = Association@OptionValue[BLDrawBiped];
If[KeyFreeQ[o, Graphics] || Lookup[o[Graphics], PlotRange, Automatic] === Automatic,
o[Graphics] = Flatten[{Lookup[o, Graphics, {}], PlotRange -> BLBoundingBox[\[CurlyPhi]]}];
];
o = Normal@o;

Animate[
f[x[t], c[t], o, "\[CurlyPhi]" -> \[Sigma]],
{t, T[[1]], T[[2]]}, 
Evaluate@OptionValue[Animate]
]
];


(* ::Input::Initialization:: *)
xAt[x_?VectorQ, M_, n_] := Module[{\[CurlyPhi], T, A, p, b, r, p0, pT, d},
T = M["T"][[2]];
\[CurlyPhi] = M["x[t]"];

(* floating-base offset *)
p = BLIndices[{"\[Theta]", BLGetBipedBase[]}, "p"];
p0 = \[CurlyPhi][0][[p]];
pT = \[CurlyPhi][T][[p]];
d = p;

(* positions to offset by multiples of n *)
A = BLbiped["A"];
r = Diagonal[A[[p ,p]]];
p = Pick[p, r, _?Positive];

(* get out-of-plane axis *)
d = Complement[d, p];

If[EvenQ[n],
(* x at step n *)
b = PadRight[pT-p0, nx];
b[[p]] = n b[[p]];
b[[d]] = 0;
x + b,
(* else *)
b = PadRight[pT-r p0, nx];
b[[p]] = n b[[p]];
(* mirrored x at step n *)
A . x + b
]
];

TAt[t_, M_] := Module[{m, T, s, n},
(* Lenght@BLbiped["t", BLbiped["m[0]"]] *)
T = M["T"][[2]];
s = Mod[t, T];
n =Quotient[t, T];
{T, s, n}
];

xAt[t_, M_] := Module[{x, T, s, n},
x = M["x[t]"];
{T, s, n} = TAt[t, M];
xAt[x[s][[1;;nx]], M, n]
];

mAt[t_, M_] := Module[{m, T, s, n},
(* t => t+ *)
m = M["m[t]"];
{T, s, n} = TAt[t, M];
(*If[EvenQ[n], m[s], BLbiped["m", m[s]][]]*)
If[EvenQ[n], BLbiped["m", m[s]][], m[s]]
];

cAt[t_, M_] := Module[{T, s, n, c, x, m0, x0}, 
{T, s, n} = TAt[t, M];
(* project pre-impact state n steps ahead *)
x = xAt[M["x-"][[1, 1;;nx]], M, n];
(* add controls *)
c = If[EvenQ[n], 1, 2];
c = Join[x, M["c"][[c, nx+1;;nc]]];

(* project post-impact state n+1 steps ahead *)
m0 = mAt[n T, M];
x0 = xAt[n T, M];

(* quick hack to cover 1st derivative case *)
If[devec["o"] == 0, 
x0 = {x0};
c = {c};, 
(* else *)
n = Table[0, nc, 1];
x0 = {x0, n[[1;;nx]]};
c = {c, n};
];

BLc[m0, x0, c][[1;;nc]]
];


(* ::Input::Initialization:: *)
Options[BLGaitKinematics] = {BLSim -> {}, "n" -> 5, "T" -> 2, "at" -> True};

BLGaitKinematics[c_?(VectorQ[#, NumericQ]&), opts:OptionsPattern[]] := BLGaitKinematics[BLbiped["m[0]"], c, opts]

BLGaitKinematics[m_String, c_, opts:OptionsPattern[]] := BLGaitKinematics[BLSim[m, c, OptionValue[BLSim]], opts]

BLGaitKinematics[\[CurlyPhi]_, opts:OptionsPattern[]] := Module[{n, M, t, x, T, A, X, o, at},
M = \[CurlyPhi];
n = OptionValue["n"];
T = M["T"][[OptionValue["T"]]]; (* period of gait *)
at = If[OptionValue["at"],
AssociationThread[{"x[t]", "c[t]", "m[t]"} -> {xAt, cAt, mAt}],
(* else, keep original values and filter time stamps *)
With[{f = #}, f[#]&]& /@ M[[{"x[t]", "c[t]", "m[t]"}]]
];

Assert[n > 0 && IntegerQ@n];

Do[
x = M[k];
t = Flatten@DeleteCases[x["Grid"], {_?Negative}, {1}];
t = Flatten@Table[t + i T, {i, 0, n-1}];
(* some trajectories don't have t = 0 *)
t = Prepend[t, 0];

(* MMA bug, <||> below should get rid of duplicates too *)
t = DeleteDuplicates[t, Norm[#1-#2] <= 10^-(*12*)6(*100$MachineEpsilon*)&];
X = at[k][#, M]& /@ t;

(* If crazy interpolation values appear, like with *)(* Marlo rootman\[LeftDoubleBracket]12, 1\[RightDoubleBracket], try increasing multiplier *)
(* to $MachineEpsilon above.  Problem might be caused *)
(* by time stamps being too close to each other. *)

o = {InterpolationOrder->First@x["InterpolationOrder"], Method->x["InterpolationMethod"]};

M[k] = Interpolation[KeyValueMap[List, AssociationThread[{t}\[Transpose] -> X]], o];,
{k, {"x[t]", "c[t]", "m[t]"}}
];

M
];


(* ::Input::Initialization:: *)
Options[BLSimGaitKinematics] = {BLAnimateBiped -> {}, BLGaitKinematics -> {}};

BLSimGaitKinematics[c_?(VectorQ[#, NumericQ]&), opts:OptionsPattern[]] := Module[{M},
M = BLGaitKinematics[c, OptionValue[BLGaitKinematics]];
BLAnimateBiped[M, OptionValue[BLAnimateBiped]]
];

BLSimGaitKinematics[m_String, c_, opts:OptionsPattern[]] := 
Module[{M},
M = BLGaitKinematics[m, c, OptionValue[BLGaitKinematics]];
BLAnimateBiped[M, OptionValue[BLAnimateBiped]]
];

BLSimGaitKinematics[\[CurlyPhi]_, opts:OptionsPattern[]] := Module[{M},
M = BLGaitKinematics[\[CurlyPhi], OptionValue[BLGaitKinematics]];
BLAnimateBiped[M, OptionValue[BLAnimateBiped]]
];


(* ::Input::Initialization:: *)
BLGetPOI[c_] := Module[{m0, X, C},
m0 = BLbiped["m[0]"];
{X, C} = BLmxcp[m0, c][[2;;3]];
BLGetPOI[X, C]
];

BLGetPOI[x_, c_] := Module[{f},
f = BLbiped[["draw", "poi"]];
RBDSpatialPosition[#[[3]], #[[1]], "x" -> x, "\[Lambda]" -> c]& /@ f
];

BLManifold[M_Association] := Module[{P, x, c, TcM},
P = BLmxcp[BLbiped["m[0]"], #[[1]]][[2;;3]]& /@ M;
x = P[[All, 1]];
c = P[[All, 2]];

TcM = #[[3]] . #[[2]]& /@ M;
x = devec[#, nx]& /@ x;
c = devec[#, nc]& /@ c;

x = Interpolation[KeyValueMap[{#1, #2[[1]], #2[[2]] . TcM[#1]}&, x]];
c = Interpolation[KeyValueMap[{#1, #2[[1]], #2[[2]] . TcM[#1]}&, c]];
P = Interpolation[KeyValueMap[{#1, #2[[1]], TcM[#1]}&, M]];

<|"x[s]" -> x, "c[s]" -> c, "M[s]" -> P|>
];


(* ::Input::Initialization:: *)
Options[BLBoundingBox] = {"b" :> BLbiped["draw"], Padding -> 4, "t" -> Automatic};
BLBoundingBox[\[CurlyPhi]_, opts:OptionsPattern[]] := Module[{t, x, c},
x = Lookup[\[CurlyPhi], "x[t]", Lookup[\[CurlyPhi], "x[s]", {}]];
c = Lookup[\[CurlyPhi], "c[t]", Lookup[\[CurlyPhi], "c[s]", {}]];
t = OptionValue["t"];
If[t === Automatic, t = Flatten@x["Grid"]];
BLBoundingBox[x[t], c[t], opts]
];

BLBoundingBox[x_, c_, OptionsPattern[]] := Module[{p, d, w},
d = Lookup[OptionValue["b"], "axes", axes];
w = OptionValue[Padding]  widths[[d]];
d = d + mm;
p = MapThread[Values@First@LinkPositions[##]&, {x, c}];
d = (Join@@p)\[Transpose];
{(Min /@ d) -  w, (Max /@ d)+ w}\[Transpose]
];


(* ::Input::Initialization:: *)
BLCreateGridPoints[T_, n_] := Module[{t},
(* get interval, T is either vector of points or an interpolating function *)
t = MinMax@If[VectorQ[T], T, Chop@T["Domain"]];
If[n == 1, t[[1;;1]], Range[t[[1]], t[[2]], (t[[2]]-t[[1]])/(n-1)]]
]

BLCreateGridPoints[HoldPattern[T_ -> n_]] := BLCreateGridPoints[T, n];

BLCreateGridPoints[n_] := n;


(* ::Input::Initialization:: *)
Options[BLBipedGrid] = {"n" -> (Automatic-> 9), BLDrawBiped -> {}, ImageSize ->  {BLLaTex["text width"], BLLaTex["image height"]}, BLBoundingBox -> {}, "\[CurlyPhi]" -> (#2[[1]]&)};

BLBipedGrid[M_, opts:OptionsPattern[]] := Module[{\[CurlyPhi], x, c, n},
Which[
(* M is a vector in the state-time-control space *)
VectorQ[M, NumericQ], 
\[CurlyPhi] = BLSim[M],
(* M is a pair of trajectories (manifolds have interpolation errors) *) 
VectorQ[M] && Length@M == 2, 
\[CurlyPhi] = AssociationThread[{"x[t]", "c[t]"} -> M],
(* M is a trajectory *)
KeyExistsQ[M, "x[t]"], 
\[CurlyPhi] = M,
(* M is a manifold *)
KeyExistsQ[M, "x[s]"], 
\[CurlyPhi] = M,
(* M is a manifold (output of continuation method) *)
True, 
\[CurlyPhi] = BLManifold[M];
];

x = Lookup[\[CurlyPhi], "x[t]", Lookup[\[CurlyPhi], "x[s]", {}]];
c = Lookup[\[CurlyPhi], "c[t]", Lookup[\[CurlyPhi], "c[s]", {}]];
n = BLCreateGridPoints@(OptionValue["n"] /. Automatic -> x);
BLBipedGrid[x[n], c[n], opts]
];

BLBipedGrid[x_?MatrixQ, c_?MatrixQ, OptionsPattern[]] := Module[{is, d, o, n, t0, tf},
(* image size *)
is =  OptionValue[ImageSize];

(* BLDrawBiped options *)
d = BLBoundingBox[x, c, OptionValue[BLBoundingBox]];
d = {ImageSize-> is, PlotRange-> d};

o = Association@OptionValue[BLDrawBiped];
o[Graphics] = Join[d, Lookup[o, Graphics, {}]];
o = Normal@o;

d = OptionValue["\[CurlyPhi]"];

(* create grid *)
MapThread[BLDrawBiped[##, "\[CurlyPhi]" -> d[#2, c], o]&, {x, c}]
]


(* ::Input::Initialization:: *)
BLBipedTimeGridStringFunction["Path"] := {(Which[# == 0, "p = p(0)", # == 1, "p(1)", True, "p(" <> ToString@NumberForm[N@#, {2,1}] <> ")"]&), True};

BLBipedTimeGridStringFunction["ArcLength"] := {(If[# == 0, "\\alpha = ", ""] <> ToString@StringForm["\\alpha_{``}", ToString@Round[#]]&), False};

BLBipedTimeGridStringFunction["Trajectory"] := {(If[# == 0, "t = \\SI{0}{s}", StringForm["\\SI{``}{s}", ToString@NumberForm[N@#, {3,3}]]]&), False};

BLBipedTimeGridStringFunction["SwitchingTime"] := {(Which[# == 0, "t = \\SI{0}{s}", # == 1, "\\tau \\in \\mathbb{R}", True, StringForm["\\SI{``}{\\tau}", ToString@NumberForm[N@#, {3,3}]]]&), True};

BLBipedTimeGridStringFunction[x_] := x;


(* ::Input::Initialization:: *)
Options[BLBipedTimeGrid] = {(*"d" \[Rule] {1/2, 3}, *)"n" -> (Automatic-> 9), "T" -> "Trajectory", ImageSize -> {5(*16*), 1/3, 1/15}, BLBipedGrid -> {}, ImageData -> False, ImageCrop -> False};

BLBipedTimeGrid[M_, opts:OptionsPattern[]] := Module[{\[CurlyPhi]},
If[VectorQ[M], 
\[CurlyPhi] = BLSim[M];
BLBipedTimeGrid[\[CurlyPhi]["x[t]"], \[CurlyPhi]["c[t]"], opts], 
(* else *)
\[CurlyPhi] = BLManifold[M];
BLBipedTimeGrid[\[CurlyPhi]["x[s]"], \[CurlyPhi]["c[s]"], opts, "T" -> "Path"]
]
];

BLBipedTimeGrid[x_, c_, OptionsPattern[]] := Module[{t, grid, arrow, T, time, motion, o, n, ts, d},
(* image size *)
ts = {1, BLLaTex["text width"], BLLaTex["image height"]};
ts = OptionValue[ImageSize] ts;

(* time grid values *)
t = OptionValue["n"];
(* time to string function *)
{T, n} = BLBipedTimeGridStringFunction@OptionValue["T"];
Which[
n && VectorQ[t],
(* create time grid, make sure n in [0, 1] using values in t *)
n = MinMax[t];
n = If[PossibleZeroQ[n[[2]]-n[[1]]], {0}, Chop[(t-n[[1]])/(n[[2]]-n[[1]])]];,
(* else *)
n,
(* create time grid with n in [0, 1] using t\[LeftDoubleBracket]2\[RightDoubleBracket] = # of points  *)
n = BLCreateGridPoints[{0, 1}, t[[2]]];,
(* else *)
True,
(* use regular grid points *)
n = BLCreateGridPoints[t /. Automatic -> x];
];

(* time list *)
time = Table[Graphics[BLTeX[T[s], ts[[1]]], ImageSize-> ts[[2;;3]]],{s, n}];

(* motion list, use our time grid values *)
motion = OptionValue[ImageData];
If[StringQ[motion], motion = BLImportFrom["Images", motion]];
If[VectorQ[motion] && Length@motion == Length@time,
motion = Image[#, Magnification->1]& /@ motion;,
(* else *)
motion = BLBipedGrid[{x, c}, "n" -> t, OptionValue[BLBipedGrid]];
];

If[OptionValue[ImageCrop], motion = ImageCrop /@ motion];

Grid[{time, motion}, Frame->All, Dividers->{Automatic, Flatten@ConstantArray[{Directive[Thick, Black], Gray}, 3]}]
];


(* ::Input::Initialization:: *)
Options[BLBipedFFMPEG] = {Duration -> 4, Directory -> "./img/", Delete -> True, BLBipedGrid -> {}, BLGaitKinematics -> {}, Path -> "", Print -> False};

BLBipedFFMPEG::err = "ffmpeg command did not run successfully, return value ``.";

BLBipedFFMPEG[O_Association, M_, opts:OptionsPattern[]] := Module[{N, A, i, m, a, c, G},
(* preproces O so that it's {c index, M index} pair *)
N = Which[Length@# == 1, {#[[1]], 1}, True, #]& /@ O;
A = If[AssociationQ[M], {M}, M];
Table[
{i, m} = N[k];
a = A[[m]];
c = First@If[VectorQ[i], a[i], a[[i]]];
G = BLGaitKinematics[c, OptionValue[BLGaitKinematics]];
BLBipedFFMPEG[k, G, opts], 
{k, Keys@N}
]
];

BLBipedFFMPEG[out_String, \[CurlyPhi]_Association, opts:OptionsPattern[]] := BLBipedFFMPEG[out, BLBipedGrid[\[CurlyPhi], OptionValue[BLBipedGrid]], opts];

BLBipedFFMPEG[out_String, L_, OptionsPattern[]] := Module[{d, n, fps, o, cmd, m},
d = OptionValue[Directory];
CreateDirectory[d];

n = Length@L;
m = IntegerLength[n];
fps = n / OptionValue[Duration];

(* create images in directory *)
o = d <>  StringPadLeft["1", m, "0"] <> ".jpg";
n = Export[o, L,"VideoFrames"];

(* create .mp4 file (yes | ... => overwrite file) *)
o = out <> ".mp4";

(* https://trac.ffmpeg.org/wiki/Slideshow *)
cmd = "ffmpeg -y -framerate `1` -i `2`%0`3`d.jpg -filter:v \"crop='iw-mod(iw, 2)':'ih-mod(ih, 2)'\"";
cmd = cmd <> " " <> "-c:v libx264 -r 20 -pix_fmt yuv420p `4`";
cmd = StringTemplate[FileNameJoin[{OptionValue[Path],  cmd}]];
cmd = cmd[fps, d, m, o];
If[OptionValue@Print, Print[cmd]];
cmd = Run@cmd;

(* clean up *)
If[OptionValue[Delete], 
DeleteFile[n];
DeleteDirectory[d];
];

(* would like to play saved vido, but Import fails *)
If[cmd =!= 0,  Message[BLBipedFFMPEG::err, cmd], ListAnimate[L]]
];


(* ::Input::Initialization:: *)
Options[BipedGIF] = Prepend[Options@BipedList, AnimationRepetitions -> 0];
BipedGIF[f_, n_, c_, range_, opts:OptionsPattern[]] := Module[{g, N},
g = BipedList[n, c, range, FilterRules[{opts}, Options@BipedList]];
N = OptionValue@AnimationRepetitions;
If[StringQ@f && StringLength@f > 0, Export[f, g, "AnimationRepetitions" -> N]];
ListAnimate[g, AnimationRepetitions -> N+1]
]


(* ::Input::Initialization:: *)
(* color of singular and regular points on connected component *)
RPColor = RGBColor[0,176/255,80/255];
SPColor = Red;

EPSize = {1/25, 1/35};
EPLeaderThickness = 1/200;

EPCallout[p_, g_] := Module[{r},
r = p[[2]];
r = Which[Negative[r], Below, Positive[r], Above, True, Before];
Callout[p, g, r, Background->None, CalloutStyle->Directive[Thickness[EPLeaderThickness], Black]]
];

SEP[p_, ps_:Automatic] := Module[{sz},
sz = If[ps === Automatic, EPSize, ps];
{SPColor, PointSize@sz[[1]], Point[p], Black, PointSize@sz[[2]], Point[p]}
];

REP[p_, ps_:Automatic] :=  Module[{sz},
sz = If[ps === Automatic, EPSize, ps];
{RPColor, PointSize@sz[[1]], Point[p], Black, PointSize@sz[[2]], Point[p]}
];

SEPLine = {Thickness[2/200], SPColor, InfiniteLine[{{0,0}, {1, 0}}]};

Options[BLSingularPointQ] = {"P" -> BLP, "nstol" -> Automatic};

BLSingularPointQ[C_, OptionsPattern[]] := Module[{N, m0, c0, h},
m0 = BLbiped["m[0]"];
c0 = C[[1]];
h = C[[3]];
(* requires Jacobian to exist *)
N = NullSpace[OptionValue["P"][c0][[2]], Tolerance->OptionValue["nstol"]];
Length@N > Length@h
];


(* ::Input::Initialization:: *)
(* compute slope *)
Options[\[Sigma]] = {"i" -> mm, FixAngles -> {}};

\[Sigma][C_List, OptionsPattern[]] := Module[{m, c, s, i},
i = OptionValue["i"];
i = Which[
IntegerQ[i], i, 
StringContainsQ[i, "x"], 1, 
StringContainsQ[i, "y"], 2, 
StringContainsQ[i, "z"], 3,
True, mm
];

(* get slope *)
m = BLbiped["m[0]"];
c = C[[1]];

s = BLmxcp[m, c][[2;;3]]; (* {x, c} *)
s[[1]] = devec[s[[1]], nx];
s[[2]] = devec[s[[2]], nc];
s = BLAngle[BLbiped["\[Sigma]", m][s[[1]], s[[2]]][[i]]]/Degree;

{c[[-1]], s}
];

\[Sigma][A__Association, opts:OptionsPattern[]] := FixAngles[Map[\[Sigma][#, opts]&, {A}, {2}], OptionValue[FixAngles]];


(* ::Input::Initialization:: *)
qt[A__Association, i_Integer:2] := Module[{B},
B = #[[All, 1, {-1, i}]]& /@ {A};
B = Map[{#[[1]], BLAngle[#[[2]]]/Degree}&, B, {2}];
FixAngles[B]
];


(* ::Input::Initialization:: *)
SetAttributes[FixAngle, Listable];

FixAngle[b_, a_] := Module[{s, d},
(* assumes angles in degrees *)
s = b - a;
d = Abs[s];
s = Which[d > 90 && s > 0, Ceiling[s, 180], d > 90, Floor[s, 180], True, 0];

d = b-s;
(* recurse to double-check d is w/i bounds to avoid edge cases *)
If[s == 0, d, FixAngle[d, a]]
];

(* ex. FixAngle[-26, 155] leads to 334 not 154 w/o recursion *)

Options[FixAngles] = {"K" -> 1, "V" -> 2, "a" -> Automatic};

FixAngles[{A__Association}, opts:OptionsPattern[]] := FixAngles[A, opts];

FixAngles[A__Association, OptionsPattern[]] := Module[{M, f, s, k, v, \[Theta], z},
k = OptionValue["K"];
v = OptionValue["V"];
z = SparseArray[{}, v, 0];

Table[
(* get walking slope *)
M = a;

(* fix angles *)
f = Select[Keys@M, Positive@#[[k]]&];
\[Theta] = OptionValue["a"];
If[\[Theta] === Automatic, \[Theta] = Lookup[a, Key@{0}, z][[v]]];
Do[
M[i] = ReplacePart[M[i], v -> FixAngle[M[i][[v]], \[Theta]]];
\[Theta] = M[i][[v]];,
{i, f}
];

f = Select[Keys@M, Negative@#[[k]]&];
\[Theta] = OptionValue["a"];
If[\[Theta] === Automatic, \[Theta] = Lookup[a, Key@{0}, z][[v]]];
Do[
M[i] = ReplacePart[M[i], v -> FixAngle[M[i][[v]], \[Theta]]];
\[Theta] = M[i][[v]];,
{i, f}
];

M,
{a, {A}}
]
]


(* ::Input::Initialization:: *)
Options[BLPlotProjection] = {Projection -> 2, ListPlot -> {}, BLSingularPointQ -> {}, Magnification -> 5, FrameStyle -> 18, Callout -> {}, PointSize -> EPSize};

BLPlotProjection[{A__Association}, o___] := BLPlotProjection[A, o];

BLPlotProjection[A__Association, opts:OptionsPattern[]] := Module[{B, e, AP, BP, lb, o, ps, mag},
e = OptionValue[Projection];
If[IntegerQ@e, 
B = qt[A, e];
lb = ToString@StringForm["q_`` \\; \\text{(joint angle)}", e], 
(* else *)
B = \[Sigma][A, "i" -> e];
lb = "\\sigma \\; \\text{(slope)}";
];

lb = {"\\tau \\; \\text{(switching time)}", lb};

(* format data *)
AP = DeleteMissing@Lookup[{A}, Key@{0}];
BP = DeleteMissing@Lookup[B, Key@{0}];

(* mark initial points as regular or singular points *)
e = BLSingularPointQ[#, OptionValue@BLSingularPointQ]&;
e = e /@ AP;
(* add branch of EPs? *)
AP = If[Or@@e, SEPLine, {}];
(* add REPs and SEPs *)
ps = OptionValue[PointSize];
If[VectorQ[ps], ps = {ps, ps}];
e = MapThread[If[#1, SEP[#2, ps[[1]]], REP[#2, ps[[2]]]]&, {e, BP}];

(* add callouts *)
o = {};
BP = OptionValue[Callout];
Do[
o = {If[PossibleZeroQ@Norm[j], {}, REP[B[[i, Key@j]], ps[[2]]]], o};
B[[i, Key@j]] = EPCallout[B[[i, Key@j]], BP[i,j]], 
{i, Keys@BP}, {j, Keys@BP[i]}
];

e = Flatten@{e, o};

(* format plot *)
mag = OptionValue@Magnification;
If[NumericQ[mag], mag = {mag, 0.5mag}]; (* for backwards compatibility *)
lb = BLTeX[#,mag[[1]]]& /@ lb;

o = <|{FrameLabel -> lb, Prolog -> AP, Epilog -> e, FrameStyle->Directive[Black, OptionValue@FrameStyle],PlotStyle-> Directive[Thickness[1.5/200], RPColor], ImageSize->BLLaTex["text width"]}|>;

o = Normal@Join[o, <|OptionValue[ListPlot]|>];

(* extract data *)
B = Values@KeySort@#& /@ B;
BLFramePlot[B, ListPlot-> o, Format -> BLFormatPlot[mag[[2]]]]
];


(* ::Input::Initialization:: *)
(* might need to be updated to work with new FramePlot *)
PlotIndicatorFunction[root_, t_, tmax_:Automatic, opts:OptionsPattern[FindRoot]] := Module[{T, IF, TD},
{T, IF, TD} = FindBifurcation[root, t, tmax, opts];
T = {#, 0}& /@ T;
FramePlot[TD, "sp" -> T, 
"tstr" -> {StringForm["`` s", If[PossibleZeroQ@#, 0, NumberForm[#, 2]]]&, StringForm["``", ScientificForm[#, {3,2}]]&}, "lbl" -> {"T (switching time, s)", "IF(T)"}]
];


(* ::Input::Initialization:: *)
Options[BLFormatPlot] = {Magnification -> 1, NumberForm -> {3, 1}};
BLFormatPlot[mag_:1, nf_:{3,1}] := {(BLTeX[If[# == 0, "\\SI{0}{s}", StringForm["\\SI{``}{s}", ToString@NumberForm[N@#, nf]]], mag]&), BLTeX[ToString@Round@# <> "^\\circ", mag]&}

Options[BLFramePlot] = {Format -> BLFormatPlot[], ListPlot -> {}, Ticks-> Automatic};

BLFramePlot[G_, opts:OptionsPattern[]] := Module[{plot, ft, o, ticks, f},
plot = ListPlot[G, Joined-> True, Ticks-> OptionValue[Ticks]];

(* get x- and y-coordinate tick marks and relabel major tick marks *)
ticks = OptionValue[Format];
ft = Ticks /. First@AbsoluteOptions[plot, Ticks];

f = If[NumericQ[#1[[2]]], Insert[Delete[#1, 2], #2[#1[[2]]], 2], #]&;
Do[
ft[[i]] = Select[ft[[i]], NumericQ[#[[2]]]&];
ft[[i]] = f[#, ticks[[i]]]& /@ ft[[i]],
 {i, Length@ft}
];

ft = {{ft[[2]], None}, {ft[[1]], None}};

(* plot *)
o = Sequence[Frame->True, Axes -> False, FrameTicks -> ft, OptionValue[ListPlot]];

ListPlot[G, Joined->True, o]
];

(* [1] http://mathematica.stackexchange.com/questions/19859/plot-extract-data-to-a-file *)


(* ::Input::Initialization:: *)
End[]
EndPackage[]
