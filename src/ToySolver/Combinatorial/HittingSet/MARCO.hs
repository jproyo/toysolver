{-# OPTIONS_GHC -Wall #-}
{-# OPTIONS_HADDOCK show-extensions #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  ToySolver.Combinatorial.HittingSet.MARCO
-- Copyright   :  (c) Masahiro Sakai 2016
-- License     :  BSD-style
--
-- Maintainer  :  masahiro.sakai@gmail.com
-- Stability   :  provisional
-- Portability :  non-portable
--
-- * M. Liffiton and A. Malik, "Enumerating infeasibility: Finding multiple
--   MUSes quickly," in Integration of AI and OR Techniques in Constraint
--   Programming for Combinatorial Optimization Problems, C. Gomes and
--   M. Sellmann, Eds. pp. 160-175.
--   <http://sun.iwu.edu/~mliffito/publications/cpaior13_liffiton_MARCO.pdf>
--
-----------------------------------------------------------------------------
module ToySolver.Combinatorial.HittingSet.MARCO
  (
  -- * Problem definition
    module ToySolver.Combinatorial.HittingSet.InterestingSets

  -- * Main functionality
  , run

  -- * Applications: monotone boolean functions
  , generateCNFAndDNF

  -- * Applicaitons: minimal hitting sets
  , minimalHittingSets
  ) where

import Control.Monad
import Data.Default.Class
import Data.IntMap ((!))
import qualified Data.IntMap as IntMap
import Data.IntSet (IntSet)
import qualified Data.IntSet as IntSet
import Data.IORef
import Data.Set (Set)
import qualified Data.Set as Set
import System.IO.Unsafe
import ToySolver.Combinatorial.HittingSet.InterestingSets
import qualified ToySolver.SAT as SAT

-- | Given a problem and an option, it computes maximal interesting sets and
-- minimal uninteresting sets.
run :: forall prob. IsProblem prob IO => prob -> Options IO -> IO (Set IntSet, Set IntSet)
run prob opt = do
  solver <- SAT.newSolver
  item2var <- liftM IntMap.fromList $ forM (IntSet.toList (universe prob)) $ \item -> do
    v <- SAT.newVar solver
    return (item,v)
  let blockUp xs = SAT.addClause solver [-(item2var ! x) | x <- IntSet.toList xs]
      blockDown xs = SAT.addClause solver [item2var ! x | x <- IntSet.toList (universe prob `IntSet.difference` xs)]
  posRef <- newIORef $ Set.toList $ optMaximalInterestingSets opt
  negRef <- newIORef $ Set.toList $ optMinimalUninterestingSets opt
  mapM_ blockUp $ Set.toList $ optMinimalUninterestingSets opt
  mapM_ blockDown $ Set.toList $ optMaximalInterestingSets opt
  let loop = do
        ret <- SAT.solve solver
        if not ret then
          return ()
        else do
          model <- SAT.getModel solver
          let xs = IntMap.keysSet $ IntMap.filter (SAT.evalLit model) item2var
          ret2 <- minimalUninterestingSetOrMaximalInterestingSet prob xs
          case ret2 of
            UninterestingSet ys -> do
              blockUp ys
              modifyIORef negRef (ys :)
              optOnMinimalUninterestingSetFound opt ys
            InterestingSet ys -> do
              blockDown ys
              modifyIORef posRef (ys :)
              optOnMaximalInterestingSetFound opt ys
          loop
  loop
  pos <- readIORef posRef
  neg <- readIORef negRef
  return (Set.fromList pos, Set.fromList neg)

-- | Compute the irredundant CNF representation and DNF representation.
--
-- Let /f/ be a monotone boolean function over set of variables /S/.
-- This function returns /C/ and /D/ where ∧_{I∈C} ∨_{i∈I} x_i and
-- ∨_{I∈D} ∧_{i∈I} x_i are the irredundant CNF representation /f/ and
-- DNF representation of /f/ respectively.
generateCNFAndDNF
  :: IntSet -- ^ Set of variables /V/
  -> (IntSet -> Bool) -- ^ A monotone boolean function /f/ from /{0,1}^|V| ≅ P(V)/ to @Bool@
  -> Set IntSet -- ^ Subset /C'/ of prime implicates /C/ of /f/
  -> Set IntSet -- ^ Subset /D'/ of prime implicants /D/ of /f/
  -> (Set IntSet, Set IntSet)
generateCNFAndDNF vs f cs ds = unsafeDupablePerformIO $ do
  (pos,neg) <- run prob opt
  return (Set.map (vs `IntSet.difference`) pos, neg)
  where
    prob = SimpleProblem vs (not . f)
    opt = def
      { optMaximalInterestingSets = Set.map (vs `IntSet.difference`) cs
      , optMinimalUninterestingSets = ds
      }

minimalHittingSets :: Set IntSet -> Set IntSet
minimalHittingSets xss =
  case generateCNFAndDNF (IntSet.unions $ Set.toList xss) (evalDNF xss) Set.empty xss of
    (yss, _) -> yss

evalDNF :: Set IntSet -> IntSet -> Bool
evalDNF dnf xs = or [is `IntSet.isSubsetOf` xs | is <- Set.toList dnf]
