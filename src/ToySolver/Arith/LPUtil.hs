-----------------------------------------------------------------------------
-- |
-- Module      :  ToySolver.Arith.LPUtil
-- Copyright   :  (c) Masahiro Sakai 2012
-- License     :  BSD-style
--
-- Maintainer  :  masahiro.sakai@gmail.com
-- Stability   :  provisional
-- Portability :  portable
--
-----------------------------------------------------------------------------
module ToySolver.Arith.LPUtil
  ( toStandardForm
  , toStandardForm'
  ) where

import Control.Exception
import Control.Monad
import Control.Monad.State
import qualified Data.IntMap as IM
import qualified Data.IntSet as IS
import Data.Maybe
import Data.VectorSpace

import qualified Data.Interval as Interval

import ToySolver.Data.OrdRel
import qualified ToySolver.Data.LA as LA
import ToySolver.Data.IntVar
import qualified ToySolver.Arith.BoundsInference as BI

toStandardForm
  :: (LA.Expr Rational, [OrdRel (LA.Expr Rational)])
  -> ( (LA.Expr Rational, [(LA.Expr Rational, Rational)])
     , Model Rational -> Model Rational
     )
toStandardForm prob1@(obj, cs) = (prob2, mt)
  where
    vs = vars obj `IS.union` vars cs
    (prob2,s) = toStandardForm' prob1
    mt :: Model Rational -> Model Rational
    mt m = IM.fromAscList $ do
      v <- IS.toAscList vs
      case IM.lookup v s of
        Just def -> return (v, LA.eval m def)
        Nothing  -> return (v, m IM.! v)

type M = State Var

toStandardForm'
  :: (LA.Expr Rational, [OrdRel (LA.Expr Rational)])
  -> ( (LA.Expr Rational, [(LA.Expr Rational, Rational)])
     , VarMap (LA.Expr Rational)
     )
toStandardForm' (obj, cs) = m
  where
    vs = vars obj `IS.union` vars cs
    v1 = if IS.null vs then 0 else IS.findMax vs + 1
    initialBounds = IM.fromList [(v, Interval.whole) | v <- IS.toList vs]
    bounds = BI.inferBounds initialBounds cs IS.empty 10

    gensym :: M Var
    gensym = do
      v <- get
      put $ v+1
      return v

    m = flip evalState v1 $ do
      s <- liftM IM.unions $ forM (IM.toList bounds) $ \(v,i) -> do
        case Interval.lowerBound i of
          Interval.NegInf -> do
            v1 <- gensym
            v2 <- gensym
            return $ IM.singleton v (LA.var v1 ^-^ LA.var v2)
          Interval.Finite lb
            | lb >= 0   -> return IM.empty
            | otherwise -> do
                v1 <- gensym
                return $ IM.singleton v (LA.var v1 ^-^ LA.constant lb)
      let obj2 = LA.applySubst s obj

      cs2 <- liftM catMaybes $ forM cs $ \(OrdRel lhs op rhs) -> do
        case LA.extract LA.unitVar (LA.applySubst s (lhs ^-^ rhs)) of
          (c,e) -> do
            let (lhs2,op2,rhs2) =
                  if -c >= 0
                  then (e,op,-c)
                  else (negateV e, flipOp op, c)
            case op2 of
              Eql -> return $ Just (lhs2,rhs2)
              Le  -> do
                v <- gensym
                return $ Just (lhs2 ^+^ LA.var v, rhs2)
              Ge  -> do
                case LA.terms lhs2 of
                  [(1,_)] | rhs2<=0 -> return Nothing
                  _ -> do
                    v <- gensym
                    return $ Just (lhs2 ^-^ LA.var v, rhs2)
              _   -> error $ "ToySolver.LPUtil.toStandardForm: " ++ show op2 ++ " is not supported"

      assert (and [isNothing $ LA.lookupCoeff LA.unitVar c | (c,_) <- cs2]) $ return ()

      return ((obj2,cs2),s)
