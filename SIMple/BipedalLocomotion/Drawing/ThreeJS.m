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

base16 = 16;

(* THREE.InterpolateSmooth *)
interpolation = 2302;


(* ::Input::Initialization:: *)
SetAttributes[ColorToInteger, Listable];
ColorToInteger[c_] := FromDigits[StringJoin@IntegerString[Round[255 List@@ColorConvert[c, "RGB"]], base16], base16]

addMu[\[Mu]_] := Module[{m, n, c, mu},
m = BLbiped["m[0]"];
n = Length@(Join@@BLbiped["p", m]);
c = ConstantArray[0, n];
mu = BLbiped["p", m, "\[Mu]"];
If[mu =!= {}, c[[mu]] = \[Mu];];
Flatten[BLc[m, c]][[1;;nc]]
]


(* ::Input::Initialization:: *)
CreateTba[M_?MatrixQ] := Module[{T, R, p},
T = RigidBodyDynamics`Private`Tba[M];
(* invert frame: T^-1 = {{R^T, -R^T p}, {0, 1}} *)
R = T[[1;;3, 1;;3]];
p = T[[1;;3, 4]];

T[[1;;3, 1;;3]] = R\[Transpose];
T[[1;;3, 4]] = -R\[Transpose].p;
Flatten@Transpose@T
];

CreateTba[v_?VectorQ] := CreateTba@RigidBodyDynamics`Private`Xba[PadLeft[v, nm]];

CreateTransforms[t_, x_, c_] := Module[{Xba, X},
Table[
X = XLfun[x[s], c[s]];
RBDExpandExpression[CreateTba /@ X],
{s, t}
]
];

CreateTransforms[\[Mu]_:1] := Module[{c},
c = addMu[\[Mu]];
First@CreateTransforms[{0}, c[[1;;nx]]&, c[[1;;nc]]&]
];


(* ::Input::Initialization:: *)
CreateTracks[n_, x_, c_] := Module[{tn, t, v},
(* create track name; key on .matrix property *)
If[n === Automatic, 
tn = Keys[RigidBodyDynamics`Private`GetExpandedTree[][TreeForm]],
tn = n;
];

tn = #1 <> ".matrix"& /@ tn;

(* get track data *)
t = Flatten@x["Grid"];
v = Flatten /@ Transpose@CreateTransforms[t, x, c];

(* create track *)
MapThread[
<|"name" -> #1, "type" -> "vector", "times" -> t, "values" -> #2, "interpolation" -> interpolation|>&,
{tn, v}
]
];

CreateClips[M_Association, tn_, d_:-1, fps_:1] := KeyValueMap[CreateClip[#1, tn, #2["x[t]"], #2["c[t]"], d, fps]&, M];

(* 07/12/2021 - added UUID, which is causing issues in v127 of three.js *)
CreateClip[n_, tn_, x_, c_, d_:-1, fps_:1] := <|"name" -> n, "fps" -> 1, "duration" -> d, "uuid" -> CreateUUID[], "tracks" -> CreateTracks[tn, x, c]|>;


(* ::Input::Initialization:: *)
GetSurfaceAngles[M_Association] :=
KeyValueMap[GetSurfaceAngle[#1, #2["m"][[1]], {#2["x-"][[1]], Table[0, nx, 1]}, {#2["c"][[1]], Table[0, nc, 1]}]&, M];

GetSurfaceAngle[n_, m_, x_, c_] := Module[{a, norm, g},
a = CreateSurface[m, x, c];
norm = Cross[a[[3]], a[[2]]];

g = I3[[Lookup[BLbiped["draw"], "axes", axes][[-1]]]];
<|"c" -> -norm.a[[1]], "n" -> norm, "d" -> -g.a[[1]], "o" -> a[[1]]|>
]


(* ::Input::Initialization:: *)
(* get post-impact m, x, c *)
CreateSurface[M_] := CreateSurface[M["m[t]"][0], devec[M["x[t]"][0], nx], devec[M["c[t]"][0], nc]];

CreateSurface[m_, x_, c_] := Module[{d, \[Sigma], r, ax, p, n},
d = Lookup[BLbiped, "draw", <||>];
ax = Lookup[d, "axes", BipedalLocomotion`Private`axes];
n = Length[ax];
If[n == 2, ax = Insert[ax, First@Complement[Range[mm],  ax], 2];];

(* compute slope *)
\[Sigma] = BLbiped["\[Sigma]", m][x, c][[1;;mm]];

(* get (post-impact) stance foot location *)
p = Lookup[d, "surface", Automatic];
p = If[p === Automatic, BLSide[m, BLbiped["feet"], 2], p[m, x, c]];
p = RBDSpatialPosition[p[[2]], p[[1]], "x" -> x[[1]], "\[Lambda]" -> c[[1]]][[mm+1;;nm]];

\[Sigma] = \[Sigma][[ax]];
r = IdentityMatrix[mm][[ax]];
If[n == 2, r[[2]] = -r[[2]];];

{p, RotationMatrix[\[Sigma][[2]], -r[[2]]].r[[1]], RotationMatrix[\[Sigma][[3]], r[[3]]].r[[2]]}
];


(* ::Input::Initialization:: *)
Object3D[n_, p_, objopts_:<||>] := Module[{A, c},
A = <|"name" -> n, "parent" -> Quiet@Check[RBDGetPositionIndex@p, 0], objopts|>;

If[KeyFreeQ[A, "dof"],
Which[
StringEndsQ[n, "px"], A["dof"] = "px",
StringEndsQ[n, "py"], A["dof"] = "py",
StringEndsQ[n, "pz"], A["dof"] = "pz",
StringEndsQ[n, "rx"], A["dof"] = "rx",
StringEndsQ[n, "ry"], A["dof"] = "ry",
StringEndsQ[n, "rz"], A["dof"] = "rz",
True,  A["dof"] = If[StringContainsQ[n, "foot", IgnoreCase->True], "poi", "poi-flat"];
];
];

If[KeyFreeQ[A, "mesh"], A["mesh"] = <||>];

(* draw/render link for relevant joint types *)
c = StringMatchQ[A["dof"], "rx"|"ry"|"rz"|"poi"|"poi-flat"|"poi-circ"];
If[c,
c = BLbiped["draw", "lc"];
(* hack to remove, e.g., "-rx" from string *)
c = Lookup[c, n, Lookup[c, StringTake[n, {1, -4}], lc]];

If[KeyFreeQ[A["mesh"], "link"], A["mesh", "link"] = <||>];
If[KeyFreeQ[A["mesh", "link"], "color"],
A["mesh", "link", "color"] = ColorToInteger[c];
];
];

(* draw/render joint for relevant joint types *)
c = StringMatchQ[A["dof"], "rx"|"ry"|"rz"|"poi-circ"];
If[c,
c = Lookup[BLbiped["draw"], "jc", <||>];
c = Lookup[c, n, Lookup[c, StringTake[n, {1, -4}], jc]];

If[KeyFreeQ[A["mesh"], "joint"], A["mesh", "joint"] = <||>];
If[KeyFreeQ[A["mesh", "joint"], "color"],
A["mesh", "joint", "color"] = ColorToInteger[c];
];
];

A
]


(* ::Input::Initialization:: *)
CreatePOI[\[Mu]_:1, objopts_: <||>] := Module[{o, c, poi, f},
c = addMu[\[Mu]];
poi = BLbiped["draw", "poi"] /. \[DoubleStruckC][i_] :> c[[i]];
o = Lookup[objopts, #, <||>]&;
f = <|Object3D[#1, #2[[1]], o[#1]], "value" -> CreateTba[#2[[3]]]|>&;
KeyValueMap[f, poi]
]

CreateJoints[rb_:Automatic, \[Mu]_:1, objopts_: <||>] := Module[{r, p, n, v, o},
r = If[rb === Automatic, RigidBodyDynamics`Private`GetExpandedTree[], rb];
p = r[ParentList];
n = Keys[r[TreeForm]];
v = CreateTransforms[\[Mu]];
o = Lookup[objopts, #, <||>]&;
MapThread[<|Object3D[#1, #2, o[#1]], "value" -> #3|>&, {n, p, v}]
]


(* ::Input::Initialization:: *)
Options[BLMeshOptions] = {Length -> 0.1}
BLMeshOptions[OptionsPattern[]] := Module[{w, f, info, joints, links, A},
w = OptionValue[Length];
f = Function[x, StringRiffle[List@@x, "-"], Listable];

(* get all joint names *)
A = f[RBDGetValue[1, nq, "n" -> True]];
A = Association@Thread[A -> <|"mesh" -> <|"joint" -> <|"height" -> 1.1 w, "radius" -> w/2|>,"link" -> <|"width" -> w|>|>|>];

A
];


(* ::Input::Initialization:: *)
BLCreateBipedToThreeJS[A_] := Module[{T, K, mu, j, f, ax, mopts, mroot},
(* get kinematic tree properties *)
T = RigidBodyDynamics`Private`GetExpandedTree[];

(* functions for a model entry, model defined by \[Mu] vector in \[DoubleStruckC] *)
K = KeyDrop[Key@Options];
(* mu assumes no derivatives, i.e., Length[mu] === nc *)
mu = #[[1, "c", 1, (If[# <0, nc+#+1, #]&) /@ BLbiped["c", #[[1, "m", 1]], "\[Mu]"]]]&;
j = Join[CreateJoints[T, #1, #2], CreatePOI[#1, #2]]&;
mopts = Lookup[#, Options, <||>]&;

ax = {"x", "y", "z"}[[Lookup[BLbiped["draw"], "axes", axes]]];
mroot = <|"axes" -> ax, "loader" -> "DefaultMesh.js", Lookup[mopts[#], Root, <||>]|>&;

f = <|"joints" -> j[mu[#], mopts[#]],"clips" -> CreateClips[K@#, Automatic], mroot[#], "surfaces" -> GetSurfaceAngles[K@#]|>&;

<|
"name" -> BLbiped["name"],
"models" -> KeyValueMap[<|"name" -> #1, f[#2]|>&, A]
|>
];

BLExportBipedToThreeJS[A_, folder_:Automatic] := Module[{n, e, biped, file, m},
n = Lookup[A, "name", Null];
biped = If[!StringQ[n], BLCreateBipedToThreeJS[A], A];
file = biped["name"] <> ".json";
If[folder === Automatic,
BLExportTo["JSON", file, biped],
(* else *)
Export[FileNameJoin[{folder, file}], biped]
]
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]