module Velo.Trace

import Text.PrettyPrint.Prettyprinter

import Toolkit.DeBruijn.Context.Item
import Toolkit.DeBruijn.Context
import Toolkit.Data.Location
import Velo.Types
import Velo.Terms
import Velo.Values

import Velo.Elaborator

import Velo.Semantics.Reductions
import Velo.Semantics.Evaluation

import Velo.Core

%default total

ty : Ty -> Doc ()
ty (TyNat) = pretty "Nat"
ty (TyBool) = pretty "Bool"
ty (TyFunc x y)
  = parens (hsep [ty x, pretty "->", ty y])

elem : IsVar ctxt type -> Doc ()
elem (V pos prf) = pretty pos


velo : Term ctxt type -> Doc ()
velo (Var prf)
  = elem prf
velo (Fun body)

  = parens (pretty "fun" <++> velo body)

velo (App f a)
  = parens (pretty "apply" <++> align (vsep [velo f, velo a]))

velo Zero = pretty "zero"
velo (Plus x) = group $ parens $ hsep [pretty "inc", velo x]
velo (Add l r) = group $ parens (hsep [pretty "add", velo l, velo r])
velo True = pretty "True"
velo False = pretty "False"
velo (And l r) = group $ parens (hsep [pretty "and", velo l, velo r])

namespace Velo

  export
  pretty : Term ctxt type -> Doc ()
  pretty = velo

  export
  prettyTypes : Ty -> Doc ()
  prettyTypes = ty


showRedux : Redux a b -> String
showRedux (SimplifyAndLeft x) = "Simplify And Left Operand by " ++ showRedux x
showRedux (SimplifyAndRight x y) = "Simplify And Right Operand by " ++ showRedux y
showRedux (ReduceAndTT) = "Reduce And True True"
showRedux (ReduceAndWF) = "Reduce And Right is False"
showRedux (ReduceAndFW) = "Reduce And Left is False"

showRedux (SimplifyAddLeft x) = "Simplify Add Left Operand by " ++ showRedux x
showRedux (SimplifyAddRight x y) = "Simplify Add Right Operand by " ++ showRedux y
showRedux (ReduceAddZW vr) = "Reduce Add Left is Zero"
showRedux (RewriteEqNatPW vl vr) = "Rewriting Add"

showRedux (SimplifyPlus x) = "Simplify Plus by " ++ showRedux x

showRedux (SimplifyFuncAppFunc func) = "Simplify Application Function"
showRedux (SimplifyFuncAppVar value var) = "Simplify Application Variable by " ++ showRedux var
showRedux (ReduceFuncApp x) = "Reduce Application"


wrap : {type : Ty} -> Term Nil type -> Doc ()
wrap {type} tm
  = vcat [ Doc.pretty "```"
         , velo tm
         , Doc.pretty "```"
         ]


showSteps : {ty : Ty} -> {a,b : Term Nil ty} -> Reduces a b -> List (Doc ())
showSteps {a = a} {b = a} Refl
  = [wrap a]

showSteps {a = a} {b = b} (Trans x y)
  = wrap a :: (pretty $ "### " <+> showRedux x) :: showSteps y

export
prettyComputation : {ty : Ty}
                 -> {term : Term Nil ty}
                 -> (res  : Result term)
                         -> Velo ()
prettyComputation {term = term} (R that val steps)
  = printLn $ vcat (showSteps steps)


item : {a : Ty} -> Item a -> Doc ()
item (I str a)
  = hcat [ pretty str
         , Doc.pretty ":"
         , ty a]

ctxt : Context Ty is -> List (Doc ())
ctxt [] = []
ctxt (elem :: rest)
  = item elem :: ctxt rest

hole : Hole h -> Doc ()
hole (H fc str t c)
  = vcat [hcat [pretty (show fc), pretty str]
         , vcat (ctxt c ++ [Doc.pretty "---", hcat [pretty str, Doc.pretty ":", ty t]])
         ]


holes' : Holes holes -> List (Doc ())
holes' [] = []
holes' (elem :: rest)
  = (vcat [hole elem, Doc.pretty ""]) :: holes' rest

export
prettyHoles : Holes ss -> Velo ()
prettyHoles h
  = printLn $ vcat (holes' h)

-- [ EOF ]
