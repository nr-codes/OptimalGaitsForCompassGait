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
ArticulatedBodyAlgorithm.nb: An implementation of the ABA algorithm
and its derivative.
Copyright (C) 2014 Nelson Rosa Jr.

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
BeginPackage["RigidBodyDynamics`", "GlobalVariables`"]
Begin["`Private`"]


(* ::Input::Initialization:: *)
(* 
user inputs: x, u;
zeroed inputs: c, v, a, f, IC, Xext;
model data: ag, \[DoubleStruckCapitalI], parent, nq, fext0;
modifies: c, v, a, f, qdd, U, uJ, d, fext;
output: qdd (joint-space accelerations)
*)

ABA[] := Module[{p, vJ, IJ, fJ, IC, c, U, UU, d, mv, mf, Iv, Xext},
qdd = zq; (* C-space accelerations *)
uJ = zq; (* joint force *)

(* clear/set spatial variables *)
v = zspat; (* spatial velocity *)
a = zspat; (* spatial acceleration *)
f = zspat; (* spatial force *)

IC = \[DoubleStruckCapitalI];
vJ = z6;
fJ = z6;
IJ = Z6;
Xext = XL; (* spatial transform 0 to i *)

(* clear/set ABA variables *)
c = zspat; (* spatial velocity products *)
U = zspat;
UU = Z6;
d = zq;

Do[
p = parent[[i]];
vJ = s[[i]] qd[[i]];
If[p == 0,
v[[i]] = vJ;
(*c\[LeftDoubleBracket]i\[RightDoubleBracket] = z6;*),
v[[i]] = XL[[i]].v[[p]] + vJ;
mv = mxv[v[[i]], vJ];
c[[i]] =  mv  + sdot[[i]] qd[[i]];
Xext[[i]] = XL[[i]].Xext[[p]];
];

Iv = IC[[i]].v[[i]];
mf = mxstarf[v[[i]], Iv];
fext[[i]] = LinearSolve[Xext[[i]]\[Transpose], fext0[[i]]];
f[[i]] = mf - fext[[i]];, (* bias force *)
{i, nq}
];

Do[
U[[i]] = IC[[i]].s[[i]];
d[[i]] = s[[i]].U[[i]];
uJ[[i]] = u[[i]] - s[[i]].f[[i]];

p = parent[[i]];
If[p != 0,
UU = Outer[Times, U[[i]], U[[i]]];
IJ = IC[[i]] - UU/d[[i]];
IC[[p]] = IC[[p]] +  XL[[i]]\[Transpose].IJ.XL[[i]];

fJ = f[[i]] + IJ.c[[i]] + U[[i]]uJ[[i]]/d[[i]];
f[[p]] = f[[p]] +  XL[[i]]\[Transpose].fJ;
];,
{i, nq, 1, -1}
];

Do[
p = parent[[i]];
If[p == 0,
a[[i]] = XL[[i]].ag + c[[i]];,
a[[i]] = XL[[i]].a[[p]] + c[[i]];
];

qdd[[i]] = (uJ[[i]] - U[[i]].a[[i]])/d[[i]];
a[[i]] = a[[i]] + s[[i]]qdd[[i]];,
{i, nq}
];
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
