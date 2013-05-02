-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Polynomial.RootSeparation.Graeffe
-- Copyright   :  (c) Masahiro Sakai 2012
-- License     :  BSD-style
-- 
-- Maintainer  :  masahiro.sakai@gmail.com
-- Stability   :  provisional
-- Portability :  portable
-- 
-- Graeffe's Method
--
-- Reference:
-- 
-- * <http://mathworld.wolfram.com/GraeffesMethod.html>
-- 
-- * <http://en.wikipedia.org/wiki/Graeffe's_method>
-- 
-----------------------------------------------------------------------------

module Data.Polynomial.RootSeparation.Graeffe
  ( NthRoot (..)
  , graeffesMethod
  ) where

import Control.Exception
import qualified Data.IntMap as IM
import Data.Polynomial

data NthRoot = NthRoot !Integer !Rational
  deriving (Show)

graeffesMethod :: UPolynomial Rational -> Int -> [NthRoot]
graeffesMethod p v = xs !! (v - 1)
  where
    xs = map (uncurry g) $ zip [1..] (tail $ iterate f $ toMonic grlex p)

    n = deg p

    g :: Int -> UPolynomial Rational -> [NthRoot]
    g v p = do
      i <- [1::Int .. fromInteger n]
      let yi = if i == 1 then - (b i) else - (b i / b (i-1))
      return $ NthRoot (2 ^ fromIntegral v) yi
      where
        bs = IM.fromList [(fromInteger i, b) | (b,ys) <- terms p, let i = n - deg ys, i /= 0]
        b i = IM.findWithDefault 0 i bs

f :: UPolynomial Rational -> UPolynomial Rational
f p = (-1) ^ (deg p) *
      fromTerms [ (c, assert (deg xs `mod` 2 == 0) (var X `mpow` (deg xs `div` 2)))
                | (c, xs) <- terms (p * subst p (\X -> - var X)) ]

f' :: UPolynomial Rational -> UPolynomial Rational
f' p = fromTerms [(b k, var X `mpow` (n - k)) | k <- [0..n]]
  where
    n = deg p

    a :: Integer -> Rational
    a k
      | n >= k    = coeff (var X `mpow` (n - k)) p
      | otherwise = 0

    b :: Integer -> Rational
    b k = (-1)^k * (a k)^2 + 2 * sum [(-1)^j * (a j) * (a (2*k-j)) | j <- [0..k-1]]

test v = graeffesMethod p v
  where
    x = var X
    p = x^2 - 2

test2 v = graeffesMethod p v
 where
    x = var X
    p = x^5 - 3*x - 1
