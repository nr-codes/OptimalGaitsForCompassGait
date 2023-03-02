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
BeginPackage["BipedalLocomotion`CompassGait`", {"GlobalVariables`", "Derivatives`", "RigidBodyDynamics`", "BipedalLocomotion`", "BipedalLocomotion`Model`", "ContinuationMethods`", "HybridDynamics`", "Options`"}];

FindBifurcations::usage = "";
DistributeSIMple::usage = "";
RunInParallel::usage = "";
GetGaitParameters::usage = "";
PlotGaitParameters::usage = "";
TraceCurve::usage = "";
GaitEigenvalues::usage = "";
StateBasedSim::usage = "";
SaveDataCSV::usage = "";
ConvertCSV::usage = "";
FindAGait::usage = "";
FileToControllerParameters::usage = "";
SummarizeGaitParameters::usage = "";
FindCSVFile::usage = "";
GetTrajectory::usage = "";
CompareTrajectory::usage = "";
CompassGaitWalk::usage = "";
SortGaits::usage ="";
TeXLabel::usage = "";
LabelTicks::usage = "";
LabelFrameTicks::usage = "";
SigFig::usage = "";

Begin["`Private`"];


(* ::Input::Initialization:: *)
DistributeSIMple[k_, p_, f_] := With[{d = BLPath["Here", ""]},
CloseKernels[];
LaunchKernels[k];
ParallelEvaluate[
SetDirectory[FileNameJoin[{d, "../../"}]];
<< "SIMple`";
<< "SIMple`Additions`";

SetDirectory[FileNameJoin[{d, "../"}]];
Get[p];
Block[{NotebookDirectory = (d&)}, f[];];
];
];


(* ::Input::Initialization:: *)
Attributes[RunInParallel] = {HoldAll};

RunInParallel[x_, i__] := With[{path = BLPath["Here", ""]},
ParallelTable[Block[{NotebookDirectory = (path&)}, x], i]
];


(* ::Input::Initialization:: *)
AllRoots[f_, x0_, x1_, N_:All, n_:100, tol_:Automatic] := Module[{x, y, r, xr, yr, e},
x = Subdivide[x0, x1, n];
DistributeDefinitions[f];
y = ParallelMap[f, x];
If[ListQ@First@y, 
r = BipedalLocomotion`Private`binewton;
y = y[[All, 1]];, 
(* else *)
r = BipedalLocomotion`Private`brent
];

yr = y[[1;;-2]]y[[2;;-1]];
xr = MapThread[List, {x[[1;;-2]], x[[2;;-1]]}];
xr = Pick[xr, yr, z_/;Negative@z];
xr = Which[Length@xr == 0, xr, IntegerQ[N], Take[xr, N], True, xr[[N]]];

e = If[tol === Automatic, BipedalLocomotion`Private`TOL, tol];
DistributeDefinitions[r, e];
r = ParallelMap[r[f, #[[1]], #[[2]], e]&,  xr];

{ParallelMap[{#, f[#]}&, r], {x, y}\[Transpose]}
];


(* ::Input::Initialization:: *)
AllExtrema[g_, x0_, x1_, h_:Automatic, N_:All, n_:100, tol_:Automatic] := Module[{f, r, p},
(* use finite differencing to compute derivative *)
With[{h0 = If[h === Automatic, 10^-5, h]},
f = (g[# + h0]-g[# - h0]) / (2h0)&;
];

{r, p} = AllRoots[f,x0, x1, N, n, tol];

r = ParallelMap[Insert[#, g[#[[1]]], 2]&, r];
p = ParallelMap[Insert[#, g[#[[1]]], 2]&, p];

{r, p}
];


(* ::Input::Initialization:: *)
Options[FindBifurcations] = {"i" -> All, "j" -> All, "svd" -> True};

SetRank[t_?NumericQ, f_, OptionsPattern[FindBifurcations]] := Module[{c, R, S, r, i, j},
c = BLbiped["\[DoubleStruckC]", BLbiped["m[0]"], "eq"][t];
c = CompassGaitPad[c, "\[Sigma]" -> 0.0, "v" -> 0.0, "J" -> 0.0];
i = OptionValue["i"];
j = OptionValue["j"];
R = f[c];
S = SingularValueDecomposition[R[[2, i, j]]][[2]];
Length@S - Count[Normal@Diagonal@S, _?PossibleZeroQ]
];

IndicatorFunction[t_?NumericQ, f_] := Module[{c, H, J, \[Phi], z},
(* algebraic bifurcation equation test *)
c = BLbiped["\[DoubleStruckC]", BLbiped["m[0]"], "eq"][t];
c = CompassGaitPad[c, "\[Sigma]" -> 0.0, "v" -> 0.0, "J" -> 0.0];
H = FiniteDifferenceJacobian[f[#][[2]]&, c];
J = f[c][[2]];
\[Phi] = NullSpace[J]\[Transpose] . {1, 0}; (* take the non-switching time vector *)
z  = NullSpace[J\[Transpose]];
Abs@First[z . (H . \[Phi]) . \[Phi]]
];

IndicatorFunction[t_?NumericQ, r_, f_, OptionsPattern[FindBifurcations]] := Module[{c, R, i, j},
(* constant rank test *)
c = BLbiped["\[DoubleStruckC]", BLbiped["m[0]"], "eq"][t];
c = CompassGaitPad[c, "\[Sigma]" -> 0.0, "v" -> 0.0, "J" -> 0.0];
i = OptionValue["i"];
j = OptionValue["j"];
R = f[c];
SingularValueList[R[[2, i, j]], r][[r]]
];

FindBifurcations[f_, t0_, a_, b_, n_, opts:OptionsPattern[]] := Module[{r, I},
If[OptionValue["svd"], 
r = SetRank[t0, f, opts];
I = IndicatorFunction[#, r, f, opts]&;, 
(* else *)
I = IndicatorFunction[#, f]&;
];
AllExtrema[I, a, b, Automatic, All, n]
];


(* ::Input::Initialization:: *)
Options[SaveDataCSV] = {Write ->  None, "ns" -> {}};

SaveDataCSV[Man_, z_, z0_, c_, R_, A_:<||>, opts:OptionsPattern[]] := Module[{o},
o = OptionValue[Write];
If[o =!= None, Export[o,{Join[z, c]},"CSV"];];
o = FilterRules[{opts}, Options@ContinuationMethods`Private`data];
ContinuationMethods`Private`data[Man, z, z0, c, R, A, o]
];


(* ::Input::Initialization:: *)
Options[TraceCurve] = {"h" -> Positive, "m" -> 50, Tolerance-> Automatic, "f" -> "g", BLGenerateGaits -> {}, Write -> None, "mon" -> Automatic, "c0" -> (If[VectorQ[#], #, #[{0}, "c"][[1]]]&)};

TraceCurve[c_, OptionsPattern[]] := Module[{opts, c0, man, h, m, tol, f, strm, mon, prnt},
h = OptionValue["h"];
h = Which[h === Positive, 0.02, h === Negative, -0.02, True, h];
m = OptionValue["m"];
tol = OptionValue[Tolerance];
mon = OptionValue["mon"];
prnt = If[mon === None, False, 1];
mon = Which[mon === Automatic, tmon, mon === None, ({}&), True, mon];

strm = OptionValue[Write];
If[StringQ[strm], strm = OpenAppend[strm, BinaryFormat -> True];];

opts = (# -> {10.0^-4, \[Infinity]})& /@ ti; (* \[Tau] > 0 *)
opts = {Man-> {Method -> cmac, "n" -> Positive, Monitor -> mon, 
"cmdata" -> SaveDataCSV,
"cm" -> {"max" -> 5, Print -> prnt, "corrector" -> {"max" -> 5, "dtol" -> 2, Print -> prnt, "b" -> opts}, "cmdata" -> {"ns" -> Tolerance -> tol, Write -> strm}}}, "nstol" -> tol, "A" -> {1}};
opts = MergeOpts[OptionValue@BLGenerateGaits, opts];
c0 = If[NumericQ[c], CompassGaitPad[c], c];
f = GetOptimalMap[OptionValue["f"], OptionValue["c0"][c0]];
f = BLGenerateGaits[f, c0, h, m, opts];
If[strm =!= None, Close[strm];];
KeySort@Select[f, # =!= $Failed&]
];


(* ::Input::Initialization:: *)
SortGaits[file_String, path_:Automatic, f_:(#[["c", 1, 5]]&)] := Module[{ctls, A},
ctls = FileToControllerParameters[file];
A = ConvertCSV[file, path];
SortGaits[A, f]
];

SortGaits[A_Association, f_:(#[["c", 1, 5]]&)] := SortBy[A, f];


(* ::Input::Initialization:: *)
Options[FindAGait] = {"i" -> 1, "max" -> 25, "f" -> "v", "h" -> 0.3, "N" -> 1000, "ftolfun" -> (10.0^-8&), Man -> {}, CompassGait -> {}, "polish" ->{}};

FindAGait[file_String, path_:Automatic, opts:OptionsPattern[]] := Module[{ctls, A},
ctls = FileToControllerParameters[file];
A = ConvertCSV[file, path];
FindAGait[A, MergeOpts[{CompassGait -> ctls}, {opts}]]
];

FindAGait[A_Association, opts:OptionsPattern[]] := Module[{c0, i},
i = OptionValue["i"];
c0 = If[IntegerQ[i] || Head[i] === Key, 
A[[i, "c", 1]], 
(* else *)
(*MinimalBy[Values@A\[LeftDoubleBracket]All, "c", 1\[RightDoubleBracket], i, 1]\[LeftDoubleBracket]1\[RightDoubleBracket]*)
SortGaits[A, i][[1, "c", 1]]
];

FindAGait[c0, opts]
];

FindAGait[c0_, opts:OptionsPattern[]] := Module[{f, h, N, o, strm},
o = OptionValue[CompassGait];
If[o =!= {}, CompassGait[Normal@o];];

h = OptionValue["ftolfun"][c0];
o = (# -> {10.0^-4, \[Infinity]})& /@ ti; (* \[Tau] > 0 *)
o = {"max" -> OptionValue["max"], "b" -> o, "rtol" -> 10.0^-8};
o = "cm" -> {"cm" -> "corrector" -> o, "ftol" -> h, "lsopts" -> "stp" -> 0.25};
o = MergeOpts[OptionValue@Man, o];

h = OptionValue["h"];
N = OptionValue["N"];

f = OptionValue["f"];
f = If[StringQ[f], GetOptimalMap[f, c0], f];

f = Homotopy[f, c0, h, N, Man -> o];
f = KeySort@Select[f, # =!= $Failed&];
polish[f, Man -> o, opts]
];


(* ::Input::Initialization:: *)
(* maybe move into Homotopy...and make independent from FindAGait *) 
polish[H_, OptionsPattern[FindAGait]] := Module[{ftol, o, z0, z, C, C0, R, n, a, co},
o = OptionValue[Man];
o = OptionValue[Man, o, "cm"];
ftol = OptionValue[cmroot, o, "ftol"];
(*co = OptionValue[cmroot, o, "cm"];
co = OptionValue[OptionValue[cmroot, o, Method], co, "corrector"];
co = MergeOpts[OptionValue["polish"], co];*)
co = OptionValue["polish"];
o  = OptionValue[cmroot, o, "cmdata"];

C = <||>;
If[Length@H > 0 && H[[-1, "cmroot", "f", 1, 1]] < ftol,
z0 = Last[Keys[H]];
z = z0 + 1;
C0 = MapThread[Join, {H[[-1, "c"]], H[[-1, "\[Lambda]"]]}];
a = MapThread[Join, {#2, {#1[[-1;;-1]], PadLeft[{{1}}, {1, Length@#1}]}}]&;

Catch[
(* should pass in corrector options *)
{C, R, n} = ContinuationMethods`Private`corrector[C0[[1]], 0, C0, "f+" -> a, co];

a = <|"polish" -> <| "nfev" -> n|>|>;
Block[{ContinuationMethods`Private`rframe = ({#3, {}}&)},
C = ContinuationMethods`Private`cmdata[H, z, z0, C,R[[All, 1;;-2]], a, o];
];

(* parse out homotopy parameter *)
C["\[Lambda]"] = C["c"][[All, -1;;-1]];
C["c"] = C["c"][[All, 1;;-2]];

(* create new entry *)
C = <|z -> C|>;
];
];

Join[H, C]
];


(* ::Input::Initialization:: *)
Attributes[GetTrajectory] = {Listable};

GetTrajectory::\[Lambda] = "For ``, only reached \[Lambda] = `` (!= 0).";

GetTrajectory[\[Sigma]_, file_, path_:Automatic, opts:OptionsPattern[FindAGait]] := Module[{v, f, tol, i, hom, o, c0, M, ann},
f = GetGaitParameters[file, Path -> path, "i" -> {"v"}];
v = f[[1, 2, 1]];
ann = f[[1, 3]];

f = CompassGaitOpt[##1,"\[Sigma]"-> \[Sigma],"v"->v]&;

i = Abs[#[["c", 1, 5]]]&;
tol = 10.0^-2/Abs[#[[5]]]&;
o = MergeOpts[{opts}, {"f" -> f, "max" -> 25, "h" -> 0.3, "ftolfun" -> tol, "i" -> i, Man -> Monitor -> ({}&)}];
hom = FindAGait[file, path, o];
If[Length@hom > 0(* && Chop[hom\[LeftDoubleBracket]-1, "\[Lambda]", 1, 1\[RightDoubleBracket]] == 0*),
If[Chop[hom[[-1, "\[Lambda]", 1, 1]]] != 0,
Message[GetTrajectory::\[Lambda], file, hom[[-1, "\[Lambda]", 1, 1]]];
];

c0 = hom[[-1, "c", 1]];
M = P[BLbiped["m[0]"], c0];
i = Flatten[M["x[t]"]["Grid"]][[3;;-2]]; (* drop pre- and post-impacts *)
M["hom"] = hom;
M["ann"] = ann;
M["u[t]"] = With[{u = BLbiped["u"], m = M["m[t]"], x = M["x[t]"], c = M["c[t]"], n = nc}, u[m[#]][devec[x[#], nx], devec[c[#], n]]&];
M,
(* else *)
<|"hom" -> hom, "ann" -> ann|>
]
];


(* ::Input::Initialization:: *)
CompareTrajectory[\[Sigma]_, file_, path_:Automatic, opts:OptionsPattern[FindAGait]] := Module[{M, I, f},
M = GetTrajectory[\[Sigma], file, path, opts];
{CompareTrajectory[M, opts], M}
];

CompareTrajectory[M_] := Module[{I, f, t, J},
J = MapThread[NIntegrate[#1[t #2] . #1[t #2], {t, 0, 1}] + #3^2&,  {M[[All, "u[t]"]], M[[All, "T", -1]], M[[All, "p", -2]]}];
I = {{"x[t]", "x[t]", "x[t]", "x[t]", "u[t]"}, {3, 4, nq +3, nq +4, nq}}\[Transpose];
f = Table[With[{a = m[i[[1]]], T = m["T"][[-1]], j = Last@i}, Indexed[a[t T], j]], {i, I}, {m, M}];

I = {"\!\(\*SubscriptBox[\(q\), \(1\)]\) (left [dark gray] leg angle)", "\!\(\*SubscriptBox[\(q\), \(2\)]\) (right [light gray] leg angle)", "\!\(\*SubscriptBox[OverscriptBox[\(q\), \(.\)], \(1\)]\) (left [dark gray] leg angle)", "\!\(\*SubscriptBox[OverscriptBox[\(q\), \(.\)], \(2\)]\) (right [light gray] leg angle)", "u (input)"};

Append[MapThread[Plot[#1, {t, 0, 1}, Frame -> True, FrameLabel->{"t/\[Tau] (scaled time)", #2}, PlotLegends-> M[[All, "ann"]]]&, {f, I}], BarChart[AssociationThread[M[[All, "ann"]] -> J], BarOrigin->Left , ChartLabels-> Placed[Automatic, Left], ChartStyle->"Pastel", PlotLabel->"Cost Comparison: J = \[Integral]u.u dt + \[Iota]^2"]]
]


(* ::Input::Initialization:: *)
csvsearchpath = {"csv", "csv-e", "csv-56"};


(* ::Input::Initialization:: *)
FindCSVFile[file_, d_:Automatic] := Module[{f, p},
Which[
d === Automatic,  p = csvsearchpath;, 
!VectorQ[d], p = {d};,
True, p = d;
];
p = If[d =!= None, BLPath["Here", #]& /@ p, ""];

f = If[VectorQ[file], file, {file}];
f = If[StringEndsQ[#, ".csv"], #, # <> ".csv"]& /@ f;

FileNames[f, p]
];


(* ::Input::Initialization:: *)
ConvertCSV::file = "Selecting first of multiple files: ``";

ConvertCSV[file_String, path_:Automatic, d_:False] := Module[{f},
f = FindCSVFile[file, path];
If[f =!= {},
If[Length@f > 1, Message[ConvertCSV::file, f];];
f = First@f;
If[IntegerQ[d], FileToControllerParameters[f, d];];
ConvertCSV[Import[f]],
(* else *)
<||>
]
];

ConvertCSV[csv_] := Module[{f},
f = #[[{1}]] -> <|"c" -> {#[[2;;]]}|>&;
Association[f /@ csv]
]


(* ::Input::Initialization:: *)
FileToControllerParameters::parse = "Invalid format.  Cannot parse file: ``.";

FileToControllerParameters[file_, d_:False] := Module[{f, a, e, i},
(* Here we assume file is base name with substring: "*a_e_i_*" *)
f = FileBaseName[file];

(* find *)
a = ("F"~~"_"~~DigitCharacter..)|("B"~~"_"~~DigitCharacter..~~"_"~~DigitCharacter..)|"Z"|"I";

i = StringPosition[f, a, 3];
If[Length@i != 3, 
Message[FileToControllerParameters::parse, file];
Return[<|"a" -> {}, "e" -> {}, "i" -> False|>];
];

(* extract *)
{a, e, i} = StringSplit[StringTake[f, #], "_"]& /@ i;

(* convert *)
f = x_/; StringQ[x] && StringMatchQ[x, DigitCharacter..] :> ToExpression[x];
{a, e} = {a, e} /. {"B" -> BSplineCurve, "F" -> Fourier, "Z" -> Unevaluated@Sequence[], f};

i = If[i[[1]] == "I", True, False];

(* load *)
f = {"a" -> a, "e" -> e, "i" -> i};
If[IntegerQ[d] && d >= 0, CompassGait[f, "d" -> d]];

(* return *)
Association@f
];


(* ::Input::Initialization:: *)
nbls = <|"x1"->1, "x2"->2, "x3"->3, "x4"->4,"\[Sigma]"->5,"v"->6,"J"->7,"\[Tau]"->-1|>;
scale = <|Thread[{1, 2, 5} -> 1.0/Degree]|>; (* missing values are assumed to be 1 *)
lbls = <|1 -> "x1 (left leg angle)", 2 -> "x2 (right leg angle)", 3 -> "x3 (left leg velocity)", 4 -> "x4 (right leg velocity)", 5 -> "\[Sigma] (walking slope)", 6 -> "v (avg. walking velocity)", 7 -> "J (cost)", -1 -> "\[Tau] (step duration)"|>;

Options[GetGaitParameters] = {Path -> Automatic, "i" -> {"\[Sigma]", "v"}, "a" -> Automatic};

GetGaitParameters[file_String, opts:OptionsPattern[]] := Module[{p, f, a},
p = OptionValue[Path];
f = FindCSVFile[file, p];
a = StringTake[FileNameSplit[#][[-1]], 1;;-5]& /@ f;
MapThread[First@GetGaitParameters[ConvertCSV[#1, None], opts, "a" -> #2]&, {f, a}]
]

GetGaitParameters[A_Association, opts:OptionsPattern[]] := Module[{f, i, a, f0},
(* expect list of <||> of gaits = {<|g1, g2, ...|>, <|...|>} *)
i = OptionValue["i"];
If[i === All, i = Range@Length@A[[1, "c", 1]];];
i = If[NumericQ@#, #, nbls[#]]& /@ i;
f = KeySort@A[[All, "c", 1, i]];
f = Map[Lookup[scale, i, 1] #&, f];
a = 0 Keys[A][[1]]; (* get zero key, assume const. dim *)
f0 = f[a];
a = OptionValue["a"];
If[a === Automatic, 
a = ToString@DecimalForm[#, {\[Infinity],2}]& /@ f0;
a = StringRiffle[a, {"(", ",", ")"}];
];
{{Values@f, f0, a}}
];

GetGaitParameters[C_?VectorQ, opts:OptionsPattern[]] := (GetGaitParameters[#, opts]& /@ C);


(* ::Input::Initialization:: *)
size = {1920, 1080}/2;
ls = 18;
ts = 12;

size = Automatic;
ls = Sequence[];
ts = Automatic;

PlotGaitParameters[Print] := (size = {1920, 1080}/2; ls = 18; ts = 12;)
PlotGaitParameters[Automatic] := (size = Automatic; ls = Sequence[]; ts = Automatic;)

PlotGaitParameters[C_, opts:OptionsPattern[{GetGaitParameters, ListPlot, ListLinePlot3D}]] := Module[{Z, Z0, A, i, p, o},
i = If[!VectorQ[C], {C}, C];
{Z, Z0, A} = (Join@@GetGaitParameters[i, FilterRules[{opts}, Options[GetGaitParameters]]])\[Transpose];

i = lbls /@ (If[NumericQ@#, #, nbls[#]]& /@ OptionValue["i"]);
i = Style[#, ls]& /@ i;

p = MapThread[Tooltip, {Z, A}];
o = {PlotRange->All, PlotLegends-> A, Joined->True, Mesh->All, MeshStyle->Directive[Black, PointSize@Small], ImageSize -> size};

If[Last@Dimensions@Z0[[1]] == 3, 
o = Join[FilterRules[{opts}, Options[ListLinePlot3D]], o, {TicksStyle->ts}];
ListLinePlot3D[p, o, AxesLabel->i],
(* else *)
o = Join[FilterRules[{opts}, Options[ListPlot]], o, {FrameTicksStyle->ts}];
ListPlot[p, o, Prolog->{PointSize@Large, Black, Point@Z0}, Frame -> True, FrameLabel-> i
]
]
];


(* ::Input::Initialization:: *)
tickmag = 0.85 2.5;

SigFig [data_] := Module[{r},
r = Subtract@@Reverse@TakeSmallest[Select[Flatten@data, NumericQ], 2];
r = Last@RealDigits@r;
If[r > 0, {r + 1, 0}, Abs[r] + {2, 1}]
];

Options[TeXLabel] = {"s" -> Automatic, "n" -> Automatic, "m" -> Automatic, "pre" -> {}};

TeXLabel[data_, OptionsPattern[]] :=  Module[{d, n, f, s, u, i},
(* for list "s" {..., si, ...} is applied at data = {..., di, ...} *)
(* di can be any order tensor irrespective of the other dj's *)
s = OptionValue["s"];
s = s /. Automatic -> StringTemplate["\\num{``}"];

(* apply string format(s) *)
n = OptionValue@"n";
(* NumberForm returns expression if it is not a number *)
u = Which[!NumericQ[#2], #2, #2 == 0, #1@0, True, #1@NumberForm[#2, #3]]& ;
f = Function[{s, n, d}, 
With[{m = If[n === Automatic, SigFig[d], n]}, 
Map[u[s, #, m]&, N@d, {-1}]
]
];

d = Flatten@If[ListQ[s], MapThread[f, {s, n, data}], f[s, n, data]];

(* texify *)
n = OptionValue@"m";
d = BLTeX[d, If[n === Automatic, tickmag, n], OptionValue@"pre"];

(* restore structure *)
n = Dimensions /@ data;
d = TakeList[d, Map[Times@@#&, n]];
MapThread[ArrayReshape, {d, n}]
];

ExpandTicks[g_, d_:4] := Module[{t, f, h},
t = Transpose@{#, #}&;
h = FindDivisions[{Floor@#[[1]], Ceiling@#[[2]]}, d]&;
f = Which[#1 === Automatic,  t@h[#2], VectorQ[#1], t@#1, True, #1]&;
MapThread[f, Values@AbsoluteOptions[g, {Ticks, PlotRange}]]
];

Options[LabelTicks] = {Min -> True, TeXLabel -> {}, Div -> 4};
LabelTicks[ g_, OptionsPattern[]] := Module[{o, r, t},
t = ExpandTicks[g, OptionValue@Div];

(* remove minor ticks *)
If[!OptionValue[Min], t = Select[#, NumericQ[#[[2]]]&]& /@ t;];

(* treat rows of t as their own dataset, which might require padding of s and n *)
r = OptionValue@TeXLabel;
o = OptionValue[TeXLabel, {r},  {"s", "n"}];
If[!ListQ[o[[1]]], o = Transpose@ConstantArray[o, Length@t];];
t[[All, All, 2]] = TeXLabel[t[[All, All, 2]], {"s" -> o[[1]], "n" -> o[[2]], r}];

Show[g, Ticks -> t]
];

LabelFrameTicks[g_, opts:OptionsPattern[LabelTicks]] := Module[{o, f, l, r, t, b},
{{l, r}, {b, t}} = FrameTicks /. Options[g, FrameTicks];

(* get l and b data from Ticks *)
o = MemberQ[{Automatic, True}, #]& /@ {b, l};
If[o[[1]] || o[[2]],
f = ExpandTicks[Show[g, Frame -> False], OptionValue@Div];
If[o[[1]], b = f[[1]];];
If[o[[2]], l = f[[2]];];
];

(* expand any vectors into {{val, label}, ..} *)
f = If[VectorQ[#], {#, #}\[Transpose], #]&;
f = f /@ <|"l" -> l, "b" -> b, "r" -> r, "t" -> t|>;

(* scale right axis w.r.t. left axis *)
If[r === True && l =!= None,
o = Abs@Min@Cases[g[[1]], {x_?NumericQ, y_?NumericQ} :> y, Infinity];
o = If[PossibleZeroQ[o], 1, o];
r = f["l"];
r[[All, 2]] = If[NumericQ@#, #/ o, #]& /@ r[[All, 2]];
f["r"] = r;
];

o = Select[f, ListQ];
(* remove minor ticks *)
If[!OptionValue[Min], o = Select[#, NumericQ[#[[2]]]&]& /@ o;];

If[Length@o > 0,
(* treat rows as their own dataset, which might require padding of s and n *)
r = OptionValue@TeXLabel;
b = OptionValue[TeXLabel, {r},  {"s", "n"}];
If[!ListQ[b[[1]]], b = Transpose@ConstantArray[b, Length@o];];

(* texify *)
o[[All, All, 2]] = TeXLabel[Values@o[[All, All, 2]], {"s" -> b[[1]], "n" -> b[[2]], r}];
f = Join[f, o];
];

f = {{f["l"], f["r"]}, {f["b"], f["t"]}};
Show[g, Frame -> True, FrameTicks -> f]
];


(* ::Input::Initialization:: *)
(*LabelTicks[NumberForm, data_] := Module[{f},
f = Abs[Last@RealDigits[Subtract@@Reverse@TakeSmallest[#, 2]]] + 1&;
Map[f, data, {-2}]
];

LabelTicks["\[Sigma]", d_:Automatic] := ToString@Round[#, If[d === Automatic, 1, d]] <> "^\\circ"& ;

LabelTicks["\[Tau]", d_:Automatic] := Module[{unit, fmt}, 
fmt = If[d === Automatic, {3,1}, d];
unit = "\\frac{s \\sqrt{g}}{\\sqrt{L}}";
unit = StringTemplate["\\SI{``}{"<> unit <> "}"];
If[# \[Equal] 0, unit[0], unit[(*ToString@*)NumberForm[N@#, fmt]]]& 
];

LabelTicks["v", d_:Automatic] := Module[{unit, fmt}, 
fmt = If[d === Automatic, {3,2}, d];
unit = "\\frac{m \\sqrt{L}}{s L \\sqrt{g}}";
unit = StringTemplate["\\SI{``}{"<> unit <> "}"];
If[# \[Equal] 0, unit[0], unit[(*ToString@*)NumberForm[N@#, fmt]]]& 
];

LabelTicks["n", d_:{3,1}] := Module[{unit, fmt}, 
fmt = If[d === Automatic, {3,1}, d];
unit = StringTemplate["\\num{``}"];
If[# \[Equal] 0, unit[0], unit[NumberForm[N@#, fmt]]]& 
];

LabelTicks[Ticks, t_, s_:"n", d_:Automatic] := BLTeX[If[StringQ[s], LabelTicks[s, d], s] /@ t, tickmag];

LabelTicks[g_, OptionsPattern[GetGaitParameters]] := Module[{x, y, ft, i},
i = OptionValue["i"];

If[Length@i == 3, Print["3 axes not implemented."]; Return[g]];

{x, y} = Ticks /. First@AbsoluteOptions[Show[g, Frame -> False], Ticks];

x = Select[x, NumericQ[#\[LeftDoubleBracket]2\[RightDoubleBracket]]&];
y = Select[y, NumericQ[#\[LeftDoubleBracket]2\[RightDoubleBracket]]&];

x\[LeftDoubleBracket]All, 2\[RightDoubleBracket] = StringTemplate["\\num{``}"] /@ x\[LeftDoubleBracket]All, 2\[RightDoubleBracket];
x\[LeftDoubleBracket]All, 2\[RightDoubleBracket] = BLTeX[x\[LeftDoubleBracket]All, 2\[RightDoubleBracket], tickmag];

y\[LeftDoubleBracket]All, 2\[RightDoubleBracket] = StringTemplate["\\num{``}"] /@ y\[LeftDoubleBracket]All, 2\[RightDoubleBracket];
y\[LeftDoubleBracket]All, 2\[RightDoubleBracket] = BLTeX[y\[LeftDoubleBracket]All, 2\[RightDoubleBracket], tickmag];

ft = {{y, None}, {x, None}};

Show[g, Frame -> True, FrameTicks -> ft]
];*)


(* ::Input::Initialization:: *)
SummarizeGaitParameters[C_, opts:OptionsPattern[GetGaitParameters]] := Module[{Z, Z0, A, i, f},
i = If[!VectorQ[C], {C}, C];
{Z, Z0, A} = (Join@@GetGaitParameters[i, opts, "i" -> All])\[Transpose];

f = Map[Interval@MinMax[#]&, #1\[Transpose]]&;
MapThread[{#2, Sequence@@f[#1]}&, {Z, A}]
];


(* ::Input::Initialization:: *)
CompassGaitWalk[x__] := BLWalk[x, BLAnimateBiped -> {"Sim" -> CompassGaitSim}];


(* ::Input::Initialization:: *)
Options[GaitEigenvalues] = {"e" -> Max, "\[Sigma]" -> Automatic};

GaitEigenvalues[c_?VectorQ, opts:OptionsPattern[]] := GaitEigenvalues[P[BLbiped["m[0]"], c], opts];

GaitEigenvalues[M_Association, OptionsPattern[]] := Module[{i, m, \[Sigma]T, \[Sigma]0, x, c, \[Sigma], dSdT, dSdc, dTdc, f, A, j, Je, Jt, eigs, k},
m = M[["m", 1]];
i = BLbiped["c", m, "x"];
j = BLbiped["p", m, "x"];
k = OptionValue["\[Sigma]"];
If[k === Automatic, 
(* get slope axis (axes) for 2D (3D) robot *)
k = BLbiped["draw", "axes"];
k = If[Length[k] == 2, Complement[Range[1, mm], k],k[[1;;2]]][[1]];
];

(* compute slopes (Poincare section) *)
m = M[["m", -1]];
c = Normal@M[["c", -1]];
(* t = 0 *)
x = Normal@M[["x+", 2]];
\[Sigma]0 = devec[BLbiped["\[Sigma]", m][x, c], mm][[All, k]];
(* t = T *)
x = Normal@M[["x-", -1]];
\[Sigma]T = devec[BLbiped["\[Sigma]", m][x, c], mm][[All, k]];

(* compute Jacobians *)
A = Lookup[BLbiped, "A", BLA[]];
A = A[[i, i]];

(* time-based switching *)
Jt = A . x[[2, i, j]];

(* state-based switching *)
\[Sigma] = \[Sigma]T-\[Sigma]0;
dSdT = \[Sigma][[2, -1]];
If[PossibleZeroQ[dSdT],
Je = Indeterminate;,
(* else *)
(* finish computing dTdc *)
dSdc = \[Sigma][[2]];
dTdc = -dSdc/dSdT;
(* get state-based derivative *)
f = x[[2, All, -1]];
f= KroneckerProduct[f, dTdc];
Je = A . (x[[2, i, j]] + f[[i, j]]);
];
eigs = Map[If[# =!= Indeterminate, Eigenvalues@#, #]&, {Je, Jt}];

Switch[OptionValue["e"],
Max, Map[Max@Abs@#&, eigs],
All, eigs,
"J", {Je, Jt}
]
];


(* ::Input::Initialization:: *)
\[Sigma][q_] :=q[[4]]+0.5q[[5]];

be[x_?VectorQ, c_?VectorQ] := Sin[\[Sigma][x]-\[Sigma][c]];

(* for simulation *)
StateBasedSim[p_, n_Integer:1] := Module[{Tc, m, x, c, DTsw, Tsw, esw, r},
Print["This needs to be updated."];
Throw@$Failed;

Tc = p[[-1]];
m = BLbiped["m[0]"];
{m, x, c} = BLmxcp[m, p];

esw = {
WhenEvent[\[DoubleStruckT]-0==0,{\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`TF[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]],0],\[DoubleStruckM][\[DoubleStruckT]]->HybridDynamics`Private`m[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`h[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckC][\[DoubleStruckT]]->HybridDynamics`Private`d[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`T0[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]],0],"RemoveEvent"},{"Priority"->1}],

WhenEvent[be[\[DoubleStruckX][\[DoubleStruckT]], \[DoubleStruckC][\[DoubleStruckT]]] > 0,{\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`TF[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]],0],\[DoubleStruckM][\[DoubleStruckT]]->HybridDynamics`Private`m[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`h[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckC][\[DoubleStruckT]]->HybridDynamics`Private`d[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`T0[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]],0]},{"Priority"->2}]
};

\[CurlyPhi][m, x, c, {0, n Tc}, "e" -> esw]
];


(* ::Input::Initialization:: *)
End[];
EndPackage[];