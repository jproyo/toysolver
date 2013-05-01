{-# LANGUAGE BangPatterns #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Polynomial.Factorization.Integer
-- Copyright   :  (c) Masahiro Sakai 2012-2013
-- License     :  BSD-style
-- 
-- Maintainer  :  masahiro.sakai@gmail.com
-- Stability   :  provisional
-- Portability :  non-portable (BangPatterns)
--
-- Factoriation of integer-coefficient polynomial using Kronecker's method.
--
-- References:
--
-- * <http://en.wikipedia.org/wiki/Polynomial_factorization>
--
-----------------------------------------------------------------------------
module Data.Polynomial.Factorization.Integer
  ( factor
  ) where

import Data.List
import Data.MultiSet (MultiSet)
import qualified Data.MultiSet as MultiSet
import Data.Numbers.Primes (primes)
import Data.Ratio
import Data.Polynomial
import qualified Data.Polynomial.Interpolation.Lagrange as Interpolation
import Util (isInteger)

factor :: UPolynomial Integer -> [(UPolynomial Integer, Integer)]
factor 0 = [(0,1)]
factor 1 = []
factor p | deg p == 0 = [(p,1)]
factor p = [(constant c, 1) | c /= 1] ++ [(q, fromIntegral m) | (q,m) <- MultiSet.toOccurList qs]
  where
    (c,qs) = normalize (cont p, factor' (pp p))

normalize :: (Integer, MultiSet (UPolynomial Integer)) -> (Integer, MultiSet (UPolynomial Integer))
normalize (c,ps) = go (MultiSet.toOccurList ps) c MultiSet.empty
  where
    go [] !c !qs = (c, qs)
    go ((p,m) : ps) !c !qs
      | deg p == 0 = go ps (c * (coeff (var X) p) ^ m) qs
      | fst (leadingTerm grlex p) < 0 = go ps (c * (-1)^m) (MultiSet.insertMany (-p) m qs)
      | otherwise = go ps c (MultiSet.insertMany p m qs)

factor' :: UPolynomial Integer -> MultiSet (UPolynomial Integer)
factor' p = go (MultiSet.singleton p) MultiSet.empty
  where
    go ps ret
      | MultiSet.null ps = ret
      | otherwise =
          case factor2 p of
            Nothing ->
              go ps' (MultiSet.insertMany p m ret)
            Just (q1,q2) ->
              go (MultiSet.insertMany q1 m $ MultiSet.insertMany q2 m ps') ret
          where
            p   = MultiSet.findMin ps
            m   = MultiSet.occur p ps
            ps' = MultiSet.deleteAll p ps

factor2 :: UPolynomial Integer -> Maybe (UPolynomial Integer, UPolynomial Integer)
factor2 p | p == var X = Nothing
factor2 p =
  case find (\(_,yi) -> yi==0) vs of
    Just (xi,_) ->
      let q1 = x - constant xi
          q2 = p' `polyDiv` mapCoeff fromInteger q1
      in Just (q1, toZ q2)
    Nothing ->
      let qs = map Interpolation.interpolate $
                  sequence [[(fromInteger xi, fromInteger z) | z <- factors yi] | (xi,yi) <- vs]
          zs = [ (q1,q2)
               | q1 <- qs, deg q1 > 0, isUPolyZ q1
               , let (q2,r) = p' `polyDivMod` q1
               , r == 0, deg q2 > 0, isUPolyZ q2
               ]
      in case zs of
           [] -> Nothing
           (q1,q2):_ -> Just (toZ q1, toZ q2)
  where
    n = (deg p `div` 2)
    xs = take (fromIntegral n + 1) xvalues
    vs = [(x, eval (\X -> x) p) | x <- xs]
    x = var X
    p' :: UPolynomial Rational
    p' = mapCoeff fromInteger p

isUPolyZ :: UPolynomial Rational -> Bool
isUPolyZ p = and [isInteger c | (c,_) <- terms p]

toZ :: Ord v => Polynomial Rational v -> Polynomial Integer v
toZ p = fromTerms [(numerator (c * fromInteger s), xs) | (c,xs) <- terms p]
  where
    s = foldl' lcm  1 [denominator c | (c,_) <- terms p]

-- [0, 1, -1, 2, -2, 3, -3 ..]
xvalues :: [Integer]
xvalues = 0 : interleave [1,2..] [-1,-2..]

interleave :: [a] -> [a] -> [a]
interleave xs [] = xs
interleave [] ys     = ys
interleave (x:xs) ys = x : interleave ys xs

factors :: Integer -> [Integer]
factors 0 = []
factors x = xs ++ map negate xs
  where
    ps = primeFactors (abs x)
    xs = map product $ sequence [take (n+1) (iterate (p*) 1) | (p,n) <- MultiSet.toOccurList ps]

primeFactors :: Integer -> MultiSet Integer
primeFactors 0 = MultiSet.empty
primeFactors n = go n primes MultiSet.empty
  where
    go :: Integer -> [Integer] -> MultiSet Integer -> MultiSet Integer
    go 1 !_ !result = result
    go n (p:ps) !result
      | p*p > n   = MultiSet.insert n result
      | otherwise =
          case f p n of
            (m,n') -> go n' ps (MultiSet.insertMany p m result)

    f :: Integer -> Integer -> (Int, Integer)
    f p = go2 0
      where
        go2 !m !n
          | n `mod` p == 0 = go2 (m+1) (n `div` p)
          | otherwise = (m, n)
