{-# LANGUAGE TemplateHaskell #-}

import Prelude hiding (lex)
import Control.Monad
import Data.List
import Data.Ratio
import qualified Data.Set as Set
import qualified Data.Map as Map
import Test.HUnit hiding (Test)
import Test.QuickCheck
import Test.Framework (Test, defaultMain, testGroup)
import Test.Framework.TH
import Test.Framework.Providers.HUnit
import Test.Framework.Providers.QuickCheck2
import Polynomial

{--------------------------------------------------------------------
  Polynomial type
--------------------------------------------------------------------}

prop_plus_comm = 
  forAll polynomials $ \a ->
  forAll polynomials $ \b ->
    a + b == b + a

prop_plus_assoc = 
  forAll polynomials $ \a ->
  forAll polynomials $ \b ->
  forAll polynomials $ \c ->
    a + (b + c) == (a + b) + c

prop_plus_unitL = 
  forAll polynomials $ \a ->
    constant 0 + a == a

prop_plus_unitR = 
  forAll polynomials $ \a ->
    a + constant 0 == a

prop_prod_comm = 
  forAll polynomials $ \a ->
  forAll polynomials $ \b ->
    a * b == b * a

prop_prod_assoc = 
  forAll polynomials $ \a ->
  forAll polynomials $ \b ->
  forAll polynomials $ \c ->
    a * (b * c) == (a * b) * c

prop_prod_unitL = 
  forAll polynomials $ \a ->
    constant 1 * a == a

prop_prod_unitR = 
  forAll polynomials $ \a ->
    a * constant 1 == a

prop_distL = 
  forAll polynomials $ \a ->
  forAll polynomials $ \b ->
  forAll polynomials $ \c ->
    a * (b + c) == a * b + a * c

prop_distR = 
  forAll polynomials $ \a ->
  forAll polynomials $ \b ->
  forAll polynomials $ \c ->
    (b + c) * a == b * a + c * a

prop_negate =
  forAll polynomials $ \a ->
    a + negate a == 0

prop_negate_involution =
  forAll polynomials $ \a ->
    negate (negate a) == a

{--------------------------------------------------------------------
  Monomial
--------------------------------------------------------------------}

{--------------------------------------------------------------------
  Monic Monomial
--------------------------------------------------------------------}

prop_mmDegreeOfProduct =
  forAll monicMonomials $ \a -> 
  forAll monicMonomials $ \b -> 
    mmDegree (a `mmProd` b) == mmDegree a + mmDegree b

prop_mmDegreeOfOne =
  mmDegree mmOne == 0

prop_mmProd_unitL = 
  forAll monicMonomials $ \a -> 
    mmOne `mmProd` a == a

prop_mmProd_unitR = 
  forAll monicMonomials $ \a -> 
    a `mmProd` mmOne == a

prop_mmProd_comm = 
  forAll monicMonomials $ \a -> 
  forAll monicMonomials $ \b -> 
    a `mmProd` b == b `mmProd` a

prop_mmProd_assoc = 
  forAll monicMonomials $ \a ->
  forAll monicMonomials $ \b ->
  forAll monicMonomials $ \c ->
    a `mmProd` (b `mmProd` c) == (a `mmProd` b) `mmProd` c

prop_mmProd_Divisible = 
  forAll monicMonomials $ \a -> 
  forAll monicMonomials $ \b -> 
    let c = a `mmProd` b
    in mmDivisible c a && mmDivisible c b

prop_mmProd_Div = 
  forAll monicMonomials $ \a -> 
  forAll monicMonomials $ \b -> 
    let c = a `mmProd` b
    in c `mmDiv` a == b && c `mmDiv` b == a

case_mmDeriv = mmDeriv p 1 @?= (2, q)
  where
    p = mmFromList [(1,2),(2,4)]
    q = mmFromList [(1,1),(2,4)]

-- lcm (x1^2 * x2^4) (x1^3 * x2^1) = x1^3 * x2^4
case_mmLCM = mmLCM p1 p2 @?= mmFromList [(1,3),(2,4)]
  where
    p1 = mmFromList [(1,2),(2,4)]
    p2 = mmFromList [(1,3),(2,1)]

-- gcd (x1^2 * x2^4) (x2^1 * x3^2) = x2
case_mmGCD = mmGCD p1 p2 @?= mmFromList [(2,1)]
  where
    p1 = mmFromList [(1,2),(2,4)]
    p2 = mmFromList [(2,1),(3,2)]

prop_mmLCM_divisible = 
  forAll monicMonomials $ \a -> 
  forAll monicMonomials $ \b -> 
    let c = mmLCM a b
    in c `mmDivisible` a && c `mmDivisible` b

prop_mmGCD_divisible = 
  forAll monicMonomials $ \a -> 
  forAll monicMonomials $ \b -> 
    let c = mmGCD a b
    in a `mmDivisible` c && b `mmDivisible` c

{--------------------------------------------------------------------
  Monomial Order
--------------------------------------------------------------------}

-- http://en.wikipedia.org/wiki/Monomial_order
case_lex = sortBy lex [a,b,c,d] @?= [b,a,d,c]
  where
    x = 1
    y = 2
    z = 3
    a = mmFromList [(x,1),(y,2),(z,1)]
    b = mmFromList [(z,2)]
    c = mmFromList [(x,3)]
    d = mmFromList [(x,2),(z,2)]

-- http://en.wikipedia.org/wiki/Monomial_order
case_grlex = sortBy grlex [a,b,c,d] @?= [b,c,a,d]
  where
    x = 1
    y = 2
    z = 3
    a = mmFromList [(x,1),(y,2),(z,1)]
    b = mmFromList [(z,2)]
    c = mmFromList [(x,3)]
    d = mmFromList [(x,2),(z,2)]

-- http://en.wikipedia.org/wiki/Monomial_order
case_grevlex = sortBy grevlex [a,b,c,d] @?= [b,c,d,a]
  where
    x = 1
    y = 2
    z = 3
    a = mmFromList [(x,1),(y,2),(z,1)]
    b = mmFromList [(z,2)]
    c = mmFromList [(x,3)]
    d = mmFromList [(x,2),(z,2)]

prop_refl_lex     = propRefl lex
prop_refl_grlex   = propRefl grlex
prop_refl_grevlex = propRefl grevlex

prop_trans_lex     = propTrans lex
prop_trans_grlex   = propTrans grlex
prop_trans_grevlex = propTrans grevlex

prop_sym_lex     = propSym lex
prop_sym_grlex   = propSym grlex
prop_sym_grevlex = propSym grevlex

prop_monomial_order_property1_lex     = monomialOrderProp1 lex
prop_monomial_order_property1_grlex   = monomialOrderProp1 grlex
prop_monomial_order_property1_grevlex = monomialOrderProp1 grevlex

prop_monomial_order_property2_lex     = monomialOrderProp2 lex
prop_monomial_order_property2_grlex   = monomialOrderProp2 grlex
prop_monomial_order_property2_grevlex = monomialOrderProp2 grevlex

propRefl cmp =
  forAll monicMonomials $ \a -> cmp a a == EQ

propTrans cmp =
  forAll monicMonomials $ \a ->
  forAll monicMonomials $ \b ->
    cmp a b == LT ==>
      forAll monicMonomials $ \c ->
        cmp b c == LT ==> cmp a c == LT

propSym cmp =
  forAll monicMonomials $ \a ->
  forAll monicMonomials $ \b ->
    cmp a b == flipOrdering (cmp b a)
  where
    flipOrdering EQ = EQ
    flipOrdering LT = GT
    flipOrdering GT = LT

monomialOrderProp1 cmp =
  forAll monicMonomials $ \a ->
  forAll monicMonomials $ \b ->
    let r = cmp a b
    in cmp a b /= EQ ==>
         forAll monicMonomials $ \c ->
           cmp (a `mmProd` c) (b `mmProd` c) == r

monomialOrderProp2 cmp =
  forAll monicMonomials $ \a ->
    a /= mmOne ==> cmp mmOne a == LT

{--------------------------------------------------------------------
  Gröbner basis
--------------------------------------------------------------------}

-- http://math.rice.edu/~cbruun/vigre/vigreHW6.pdf
-- Example 1
case_spolynomial = spolynomial grlex f g @?= - x^3*y^3 - constant (1/3) * y^3 + x^2
  where
    x = var 1
    y = var 2
    f, g :: Polynomial Rational
    f = x^3*y^2 - x^2*y^3 + x
    g = 3*x^4*y + y^2


-- http://math.rice.edu/~cbruun/vigre/vigreHW6.pdf
-- Exercise 1
case_buchberger1 = Set.fromList gbase @?= Set.fromList expected
  where
    gbase = buchberger lex [x^2-y, x^3-z]
    expected = [y^3 - z^2, x^2 - y, x*z - y^2, x*y - z]

    x :: Polynomial Rational
    x = var 1
    y = var 2
    z = var 3

-- http://math.rice.edu/~cbruun/vigre/vigreHW6.pdf
-- Exercise 2
case_buchberger2 = Set.fromList gbase @?= Set.fromList expected
  where
    gbase = buchberger grlex [x^3-2*x*y, x^2*y-2*y^2+x]
    expected = [x^2, x*y, y^2 - constant (1/2) * x]

    x :: Polynomial Rational
    x = var 1
    y = var 2

-- http://www.iisdavinci.it/jeometry/buchberger.html
case_buchberger3 = Set.fromList gbase @?= Set.fromList expected
  where
    gbase = buchberger lex [x^2+2*x*y^2, x*y+2*y^3-1]
    expected = [x, y^3 - constant (1/2)]
    x :: Polynomial Rational
    x = var 1
    y = var 2

-- http://www.orcca.on.ca/~reid/NewWeb/DetResDes/node4.html
-- 時間がかかるので自動実行されるテストケースには含めていない
test_buchberger4 = Set.fromList gbase @?= Set.fromList expected                   
  where
    x :: Polynomial Rational
    x = var 1
    y = var 2
    z = var 3

    gbase = buchberger lex [x^2+y*z-2, x*z+y^2-3, x*y+z^2-5]

    expected = reduceGBase lex $
      [ 8*z^8-100*z^6+438*z^4-760*z^2+361
      , 361*y+8*z^7+52*z^5-740*z^3+1425*z
      , 361*x-88*z^7+872*z^5-2690*z^3+2375*z
      ]
{-
Risa/Asir での結果

load("gr");
gr([x^2+y*z-2, x*z+y^2-3, x*y+z^2-5],[x,y,z], 2);

[8*z^8-100*z^6+438*z^4-760*z^2+361,
361*y+8*z^7+52*z^5-740*z^3+1425*z,
361*x-88*z^7+872*z^5-2690*z^3+2375*z]
-}

-- Seven Trees in One
-- http://arxiv.org/abs/math/9405205
case_Seven_Trees_in_One = reduce lex (x^7 - x) gbase @?= 0
  where
    x :: Polynomial Rational
    x = var 1
    gbase = buchberger lex [x-(x^2 + 1)]

-- Non-linear loop invariant generation using Gröbner bases
-- http://portal.acm.org/citation.cfm?id=964028
-- http://www-step.stanford.edu/papers/popl04.pdf
-- Example 3
-- Consider again the ideal from Example 2; I = {f : x^2-y, g : y-z, h
-- : x+z}.  The Gröbner basis for I is G = {f' : z^2-z, g : y-z, h :
-- x+z}. With this basis, every reduction of p : x^2 - y^2 will yield
-- a normal form 0.
case_sankaranarayanan04nonlinear = do
  Set.fromList gbase @?= Set.fromList [f', g, h]
  reduce lex (x^2 - y^2) gbase @?= 0
  where
    x :: Polynomial Rational
    x = var 1
    y = var 2
    z = var 3
    f = x^2 - y
    g = y - z
    h = x + z
    f' = z^2 - z
    gbase = buchberger lex [f, g, h]

{--------------------------------------------------------------------
  Generators
--------------------------------------------------------------------}

monicMonomials :: Gen MonicMonomial
monicMonomials = do
  size <- choose (0, 3)
  xs <- replicateM size $ do
    v <- choose (-5, 5)
    e <- liftM ((+1) . abs) arbitrary
    return $ mmFromList [(v,e)]
  return $ foldl mmProd mmOne xs

monomials :: Gen (Monomial Rational)
monomials = do
  m <- monicMonomials
  c <- arbitrary
  return (c,m)

polynomials :: Gen (Polynomial Rational)
polynomials = do
  size <- choose (0, 5)
  xs <- replicateM size monomials
  return $ sum $ map fromMonomial xs 

------------------------------------------------------------------------
-- Test harness

main :: IO ()
main = $(defaultMainGenerator)