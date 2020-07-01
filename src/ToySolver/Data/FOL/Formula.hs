{-# OPTIONS_HADDOCK show-extensions #-}
{-# LANGUAGE MultiParamTypeClasses #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  ToySolver.Data.FOL.Formula
-- Copyright   :  (c) Masahiro Sakai 2011-2015
-- License     :  BSD-style
--
-- Maintainer  :  masahiro.sakai@gmail.com
-- Stability   :  provisional
-- Portability :  non-portable
--
-- Formula of first order logic.
--
-----------------------------------------------------------------------------
module ToySolver.Data.FOL.Formula
  (
  -- * Overloaded operations for formula.
    module ToySolver.Data.Boolean

  -- * Concrete formula
  , Formula (..)
  , pushNot
  ) where

import qualified Data.IntSet as IS

import ToySolver.Data.Boolean
import ToySolver.Data.IntVar

-- ---------------------------------------------------------------------------

-- | formulas of first order logic
data Formula a
    = T
    | F
    | Atom a
    | And (Formula a) (Formula a)
    | Or (Formula a) (Formula a)
    | Not (Formula a)
    | Imply (Formula a) (Formula a)
    | Equiv (Formula a) (Formula a)
    | Forall Var (Formula a)
    | Exists Var (Formula a)
    deriving (Show, Eq, Ord)

instance Variables a => Variables (Formula a) where
  vars T = IS.empty
  vars F = IS.empty
  vars (Atom a) = vars a
  vars (And a b) = vars a `IS.union` vars b
  vars (Or a b) = vars a `IS.union` vars b
  vars (Not a) = vars a
  vars (Imply a b) = vars a `IS.union` vars b
  vars (Equiv a b) = vars a `IS.union` vars b
  vars (Forall v a) = IS.delete v (vars a)
  vars (Exists v a) = IS.delete v (vars a)

instance Complement (Formula a) where
  notB = Not

instance MonotoneBoolean (Formula c) where
  true  = T
  false = F
  (.&&.) = And
  (.||.) = Or

instance IfThenElse (Formula c) (Formula c) where
  ite = iteBoolean

instance Boolean (Formula c) where
  (.=>.)  = Imply
  (.<=>.) = Equiv

-- | convert a formula into negation normal form
pushNot :: Complement a => Formula a -> Formula a
pushNot T = F
pushNot F = T
pushNot (Atom a) = Atom $ notB a
pushNot (And a b) = pushNot a .||. pushNot b
pushNot (Or a b) = pushNot a .&&. pushNot b
pushNot (Not a) = a
pushNot (Imply a b) = a .&&. pushNot b
pushNot (Equiv a b) = a .&&. pushNot b .||. b .&&. pushNot a
pushNot (Forall v a) = Exists v (pushNot a)
pushNot (Exists v a) = Forall v (pushNot a)
