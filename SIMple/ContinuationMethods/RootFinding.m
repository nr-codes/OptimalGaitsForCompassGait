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
MultiparameterContinuationMethods.nb: An implementation of various continuation methods.
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
BeginPackage["ContinuationMethods`"]

Begin["`Private`"]

(* stopping criterions for Newton's method *)
rtol = 10^-12; (* stop if step size is really small *)
atol = 10^-8;(* stop if root is really good *)
ftol = 10^-5;(* reject if root is really bad *)
dtol = 10; (* stop if step size is really big *)
MAX = 50; (* max number of Newton iterations *)

newtmsg = StringTemplate["    newton (``/``) --- err: `` step: `` h: ``"];


(* ::Input::Initialization:: *)
newtonmon[i_, normr_, normdc_, h_, opts:OptionsPattern[newton]] := Print[newtmsg[i, OptionValue["max"], ScientificForm[normr, 5], ScientificForm[normdc, 5], NumberForm[h, {1,3}]]];


(* ::Input::Initialization:: *)
Options[newton] = {
Print -> False, 

"ftol" -> ftol, 
"rtol" -> rtol, 
"atol" -> atol, 
"dtol" -> dtol, 

"max" -> MAX, 

"LU" -> {{}, {}}
};

newton::cvmit = "Failed to converge within `3` iterations; starting from `1` the final error was `2`.";

newton::step = "The norm of the step size for `1` is `2`; the search is likely to diverge.";

newton[c0_, h_, NS_, opts:OptionsPattern[]] := Module[{r, dr, c, dc, m, rtol, atol, ftol, dtol, MAX, P, L, U, ndc, nr},
rtol = OptionValue["rtol"];
atol = OptionValue["atol"];
ftol = OptionValue["ftol"];
dtol = OptionValue["dtol"];

MAX = OptionValue["max"];

{L, U} = OptionValue["LU"];
P = OptionValue[Print];

c = c0;
Do[
{r, dr} =  f[c][[1;;2]];
If[VectorQ[h],
r = Join[r, NS.(c-c0) -  h];
dr = Join[dr, NS];
];

dc = LeastSquares[dr, r];
(*Print["augment: ", MatrixForm /@ {c0, NS}, " h: ", h];
Print[i, ": ", MatrixForm /@ {r, dr}, " " MatrixForm@dc];*)

(* projected step *)
If[L =!= {}, dc = c - Median[{c-dc, L, U}];];

nr = Norm[r];
ndc = Norm[dc];

If[Mod[i, P] === 0, newtonmon[i, nr, ndc, h, opts];];

If[ndc < rtol || nr < atol, Break[];];
If[ndc > dtol,
If[P =!= False, Message[newton::step, c0, ndc]];
Throw[$Failed];
];

c = c - dc,
{i, MAX}
];

If[nr > ftol, 
If[P =!= False, Message[newton::cvmit, c0, nr, MAX]];
Throw[$Failed];
];

If[VectorQ[h],
r = r[[;;-Length@h-1]];
dr = dr[[;;-Length@h-1]];
];

{c, r, dr}
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]