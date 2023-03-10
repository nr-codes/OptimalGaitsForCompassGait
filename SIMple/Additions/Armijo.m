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
Armijo.nb: An implementation of various line search methods.
Copyright (C) 2021 Nelson Rosa Jr.

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
BeginPackage["ContinuationMethods`"]
Begin["`Private`"]


(* ::Input::Initialization:: *)
Options[Armijo] = {
"\[Alpha]" -> 10.0^-4, 
"stp" -> 0.5, (* \[Beta] *)
"m0" -> 0,
"mf" -> 30
};


(* ::Input::Initialization:: *)
Armijo::args = "Improper input parameters: ``";
Armijo::ls = "Cannot find sufficient decrease for m \[Element] [``, ``].";


(* ::Input::Initialization:: *)
Armijo[fg0_, s0_, {}, OptionsPattern[]] := Module[{\[Alpha], \[Beta], m0, mf, g0, info, d, stp},
\[Alpha] = OptionValue["\[Alpha]"];
\[Beta] = OptionValue["stp"];
m0 = OptionValue["m0"];
mf = OptionValue["mf"];

If[\[Alpha] < 0 || \[Alpha] > 1 || \[Beta] < 0 || \[Beta] > 1 || mf < m0, 
Message[Armijo::args, "\[Alpha], stp, m0, or mf is invalid."];
Throw@$Failed;
];

g0 = fg0[[2]];
If[g0 . s0 >= 0, 
Message[Armijo::args, "Not a descent direction."];
Throw@$Failed;
];

info = 0;
stp = \[Beta]^m0;
d = stp s0;

{d, info, stp, m0, fg0[[1;;2]], \[Alpha], \[Beta], m0, mf}
];


(* ::Input::Initialization:: *)
Armijo[fg_, s0_, data_, OptionsPattern[]] := Module[{m, \[Alpha], \[Beta], d, m0, mf, f, f0, g0, a, stp, info},
info = 0;
f = fg[[1]];
{d, info, stp, m, {f0, g0}, \[Alpha], \[Beta], m0, mf} = data;

If[m >= mf,
(* max iterations *)
info = 3;
Message[Armijo::ls, m0, mf]; 
];

If[f - f0 <= \[Alpha] g0 . d, 
(* sufficient decrease found *)
info = 1;,
(* else (try new x) *)
m = m + 1;
];

stp = \[Beta]^m;
d = stp s0;
{d, info, stp, m, {f0, g0}, \[Alpha], \[Beta], m0, mf}
];


(* ::Input::Initialization:: *)
ArmijoDriver[fcn_, x0_, fg0_, s0_, opts:OptionsPattern[Armijo]] := Module[{d, info, stp, data, fg, nfev},
info = 0;
nfev = 0;
data = {};
fg = fg0;

While[True,
data = Armijo[fg, s0, data, opts];
{d, info, stp} = data[[1;;3]];
If[info != 0, Break[]];
fg = fcn[x0 + d][[1;;2]];
nfev++;
];

{x0 + d,fg,stp,info,nfev}
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]



