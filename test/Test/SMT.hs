{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
module Test.SMT (smtTestGroup) where

import Control.Applicative((<$>))
import Control.DeepSeq
import Control.Exception (evaluate)
import Control.Monad
import Control.Monad.State.Strict
import Data.Map (Map)
import qualified Data.Map as Map

import Test.Tasty
import Test.Tasty.QuickCheck hiding ((.&&.), (.||.))
import Test.Tasty.HUnit
import Test.Tasty.TH
import qualified Test.QuickCheck.Monadic as QM

import qualified ToySolver.BitVector as BV
import ToySolver.Data.Boolean
import ToySolver.Data.OrdRel
import ToySolver.SMT (Expr (..))
import qualified ToySolver.SMT as SMT
import ToySolver.BitVector (nat2bv)

-- -------------------------------------------------------------------

case_QF_LRA :: Assertion
case_QF_LRA = do
  solver <- SMT.newSolver

  a <- SMT.declareConst solver "a" SMT.sBool
  x <- SMT.declareConst solver "x" SMT.sReal
  y <- SMT.declareConst solver "y" SMT.sReal
  let c1 = ite a (2*x + (1/3)*y .<=. -4) (1.5 * y .==. -2*x)
      c2 = (x .>. y) .||. (a .<=>. (3*x .<. -1 + (1/5)*(x + y)))
  SMT.assert solver c1
  SMT.assert solver c2

  ret <- SMT.checkSAT solver
  ret @?= True

  m <- SMT.getModel solver
  SMT.eval m c1 @?= SMT.ValBool True
  SMT.eval m c2 @?= SMT.ValBool True

case_QF_EUF_1 :: Assertion
case_QF_EUF_1 = do
  solver <- SMT.newSolver
  x <- SMT.declareConst solver "x" SMT.sBool
  f <- SMT.declareFun solver "f" [SMT.sBool] SMT.sBool

  let c1 = f true .==. true
      c2 = notB (f x)
  SMT.assert solver c1
  SMT.assert solver c2
  ret <- SMT.checkSAT solver
  ret @?= True

  m <- SMT.getModel solver
  SMT.eval m c1 @?= SMT.ValBool True
  SMT.eval m c2 @?= SMT.ValBool True

  SMT.assert solver $ x
  ret <- SMT.checkSAT solver
  ret @?= False

case_QF_EUF_2 :: Assertion
case_QF_EUF_2 = do
  solver <- SMT.newSolver
  sU <- SMT.declareSort solver "U" 0

  a <- SMT.declareConst solver "a" SMT.sBool
  x <- SMT.declareConst solver "x" sU
  y <- SMT.declareConst solver "y" sU
  f <- SMT.declareFun solver "f" [sU] sU

  let c1 = a .||. (x .==. y)
      c2 = f x ./=. f y
  SMT.assert solver c1
  SMT.assert solver c2
  ret <- SMT.checkSAT solver
  ret @?= True

  m <- SMT.getModel solver
  SMT.eval m c1 @?= SMT.ValBool True
  SMT.eval m c2 @?= SMT.ValBool True

  SMT.assert solver $ notB a
  ret <- SMT.checkSAT solver
  ret @?= False

case_QF_EUF_LRA :: Assertion
case_QF_EUF_LRA = do
  solver <- SMT.newSolver
  a <- SMT.declareConst solver "a" SMT.sReal
  b <- SMT.declareConst solver "b" SMT.sReal
  c <- SMT.declareConst solver "c" SMT.sReal
  f <- SMT.declareFun solver "f" [SMT.sReal] SMT.sReal
  g <- SMT.declareFun solver "g" [SMT.sReal] SMT.sReal
  h <- SMT.declareFun solver "h" [SMT.sReal, SMT.sReal] SMT.sReal

  let cs =
        [ 2*a .>=. b + f (g c)
        , f b .==. c
        , f c .==. a
        , g a .<. h a a
        , g b .>. h c b
        ]
  mapM_ (SMT.assert solver) cs

  ret <- SMT.checkSAT solver
  ret @?= True
  m <- SMT.getModel solver
  forM_ cs $ \c -> do
    SMT.eval m c @?= SMT.ValBool True

  SMT.assert solver $ b .==. c
  ret <- SMT.checkSAT solver
  ret @?= False

case_QF_EUF_Bool :: Assertion
case_QF_EUF_Bool = do
  solver <- SMT.newSolver
  a <- SMT.declareConst solver "a" SMT.sBool
  b <- SMT.declareConst solver "b" SMT.sBool
  c <- SMT.declareConst solver "c" SMT.sBool
  f <- SMT.declareFun solver "f" [SMT.sBool] SMT.sBool
  g <- SMT.declareFun solver "g" [SMT.sBool] SMT.sBool
  h <- SMT.declareFun solver "h" [SMT.sBool, SMT.sBool] SMT.sBool

  let cs =
        [ f b .==. c
        , f c .==. a
        , g a .==. h a a
        , g b ./=. h c b
        ]
  mapM_ (SMT.assert solver) cs

  ret <- SMT.checkSAT solver
  ret @?= True
  m <- SMT.getModel solver
  forM_ cs $ \c -> do
    SMT.eval m c @?= SMT.ValBool True

  SMT.assert solver $ b .==. c
  ret <- SMT.checkSAT solver
  ret @?= False

case_push :: Assertion
case_push = do
  solver <- SMT.newSolver
  sU <- SMT.declareSort solver "U" 0

  x <- SMT.declareConst solver "x" sU
  y <- SMT.declareConst solver "y" sU
  f <- SMT.declareFun solver "f" [sU] sU

  SMT.assert solver $ f x ./=. f y
  ret <- SMT.checkSAT solver
  ret @?= True

  SMT.push solver
  SMT.assert solver $ x .==. y
  ret <- SMT.checkSAT solver
  ret @?= False
  SMT.pop solver

  ret <- SMT.checkSAT solver
  ret @?= True

case_QF_LRA_division_by_zero :: Assertion
case_QF_LRA_division_by_zero = do
  solver <- SMT.newSolver

  x1 <- SMT.declareConst solver "x1" SMT.sReal
  x2 <- SMT.declareConst solver "x2" SMT.sReal
  let y1 = x1 / 0
      y2 = x2 / 0

  ret <- SMT.checkSAT solver
  ret @?= True
  m <- SMT.getModel solver
  evaluate $ SMT.eval m y1
  evaluate $ SMT.eval m y2

  SMT.assert solver $ y1 ./=. y2
  ret <- SMT.checkSAT solver
  ret @?= True
  m <- SMT.getModel solver

  SMT.assert solver $ x1 .==. x2
  ret <- SMT.checkSAT solver
  ret @?= False

case_LRA_model_construction_bug :: Assertion
case_LRA_model_construction_bug = do
  solver <- SMT.newSolver
  cond <- SMT.declareConst solver "cond" SMT.sBool
  a <- SMT.declareConst solver "a" SMT.sReal
  b <- SMT.declareConst solver "b" SMT.sReal
  let cs = [ a .<. 10
           , b .<. 10
           , cond .=>. a+b .>. 14
           , cond .=>. a+b .<. 15
           ]
  forM_ cs $ SMT.assert solver
  ret <- SMT.checkSATAssuming solver [cond]
  m <- SMT.getModel solver
  forM_ cs $ \c -> do
    let val = SMT.eval m c
    -- unless (val == SMT.ValBool True) $ print val
    val @?= SMT.ValBool True
{-
The solving process goes like the following.

  ASSERT: a <= 10 - delta
  ASSERT: b <= 10 - delta
  PUSH
  ASSERT a+b <= 15 - delta
  ASSERT a+b >= 14 + delta

This produces assignment

  a+b = 14 + delta
  a   = 10 - delta
  b   = (a+b) - a = (14 + delta) - (10 - delta) = 4 + 2 delta

OR alternatively

  a+b = 14 + delta
  b   = 10 - delta
  a   = (a+b) - b = (14 + delta) - (10 - delta) = 4 + 2 delta.

The delta value should be in the range (0, min{(15-14)/2, (10-4)/3}] = (0, 1/2]
to satisfy the constraints. But if we were compute it after backtracking, the
range of delta becomes (0, (10-4)/3] = (0,2] and choosing delta=2 causes
violation of a+b < 15.
-}

case_uninterpretedSortFunction_eval :: Assertion
case_uninterpretedSortFunction_eval = do
  solver <- SMT.newSolver
  (sF :: SMT.Sort -> SMT.Sort) <- SMT.declareSort solver "F" 1
  (sU :: SMT.Sort) <- SMT.declareSort solver "U" 0
  let s = sF sU
  x <- SMT.declareConst solver "x" s
  ret <- SMT.checkSAT solver
  ret @?= True
  m <- SMT.getModel solver
  case SMT.eval m x of
    SMT.ValUninterpreted n s' -> s' @?= s
    _ -> assertFailure "should be ValUninterpreted"

prop_getModel_eval :: Property
prop_getModel_eval = QM.monadicIO $ do
  solver <- QM.run $ SMT.newSolver

  nsorts <- QM.pick $ choose ((0::Int), 3)
  xs <- QM.run $ forM [(1::Int)..nsorts] $ \i -> do
    s <- SMT.declareSort solver ("U" ++ show i) 0
    c <- SMT.declareFSym solver ("U" ++ show i ++ "const") [] s
    return (s, (c, ([],s)))
  let genSorts = oneof $
        [ return SMT.sBool
        , return SMT.sReal
        , do w <- choose (1,10) -- inclusive
             return $ SMT.Sort (SMT.SSymBitVec w) []
        ] ++
        [ fst <$> elements xs | not (null xs) ]
      cs = map snd xs
  fs1 <- QM.pick $ do
    ts <- listOf (genFunType genSorts)
    return [("f" ++ show i, t) | (i,t) <- zip [1..] ts]
  fs2 <- QM.run $ forM fs1 $ \(name, t@(argsSorts, resultSort)) -> do
    f <- SMT.declareFSym solver name argsSorts resultSort
    return (f, t)

  let sig =  [ ("true", ([], SMT.sBool))
             , ("false", ([], SMT.sBool))
             , ("and", ([SMT.sBool,SMT.sBool], SMT.sBool))
             , ("or", ([SMT.sBool,SMT.sBool], SMT.sBool))
             , ("xor", ([SMT.sBool,SMT.sBool], SMT.sBool))
             , ("not", ([SMT.sBool], SMT.sBool))
             , ("=>", ([SMT.sBool,SMT.sBool], SMT.sBool))
             , ("+", ([SMT.sReal,SMT.sReal], SMT.sReal))
             , ("-", ([SMT.sReal,SMT.sReal], SMT.sReal))
             , ("*", ([SMT.sReal,SMT.sReal], SMT.sReal))
             , ("/", ([SMT.sReal,SMT.sReal], SMT.sReal))
             , ("-", ([SMT.sReal], SMT.sReal))
             , (">=", ([SMT.sReal, SMT.sReal], SMT.sBool))
             , ("<=", ([SMT.sReal, SMT.sReal], SMT.sBool))
             , (">", ([SMT.sReal, SMT.sReal], SMT.sBool))
             , ("<", ([SMT.sReal, SMT.sReal], SMT.sBool))
             ]
          ++ fs2 ++ cs

  constrs <- QM.pick $ do
    nconstrs <- choose ((0::Int), 3)
    replicateM nconstrs (genExpr genSorts sig SMT.sBool 10)
  ret <- QM.run $ do
    forM_ constrs $ \constr -> SMT.assert solver constr
    SMT.checkSAT solver
  when ret $ do
    m <- QM.run $ SMT.getModel solver
    forM_ constrs $ \constr -> do
      QM.assert $ SMT.eval m constr == SMT.ValBool True

prop_getModel_evalFSym :: Property
prop_getModel_evalFSym = QM.monadicIO $ do
  solver <- QM.run $ SMT.newSolver

  nsorts <- QM.pick $ choose ((0::Int), 3)
  xs <- QM.run $ forM [(1::Int)..nsorts] $ \i -> do
    s <- SMT.declareSort solver ("U" ++ show i) 0
    c <- SMT.declareFSym solver ("U" ++ show i ++ "const") [] s
    return (s, (c, ([],s)))
  let genSorts = oneof $
        [ return SMT.sBool
        , return SMT.sReal
        , do w <- choose (1,10) -- inclusive
             return $ SMT.Sort (SMT.SSymBitVec w) []
        ] ++
        [ fst <$> elements xs | not (null xs) ]
      cs = map snd xs
  fs1 <- QM.pick $ do
    ts <- listOf (genFunType genSorts)
    return [("f" ++ show i, t) | (i,t) <- zip [1..] ts]
  fs2 <- QM.run $ forM fs1 $ \(name, t@(argsSorts, resultSort)) -> do
    f <- SMT.declareFSym solver name argsSorts resultSort
    return (f, t)

  let sig =  [ ("true", ([], SMT.sBool))
             , ("false", ([], SMT.sBool))
             , ("and", ([SMT.sBool,SMT.sBool], SMT.sBool))
             , ("or", ([SMT.sBool,SMT.sBool], SMT.sBool))
             , ("xor", ([SMT.sBool,SMT.sBool], SMT.sBool))
             , ("not", ([SMT.sBool], SMT.sBool))
             , ("=>", ([SMT.sBool,SMT.sBool], SMT.sBool))
             , ("+", ([SMT.sReal,SMT.sReal], SMT.sReal))
             , ("-", ([SMT.sReal,SMT.sReal], SMT.sReal))
             , ("*", ([SMT.sReal,SMT.sReal], SMT.sReal))
             , ("/", ([SMT.sReal,SMT.sReal], SMT.sReal))
             , ("-", ([SMT.sReal], SMT.sReal))
             , (">=", ([SMT.sReal, SMT.sReal], SMT.sBool))
             , ("<=", ([SMT.sReal, SMT.sReal], SMT.sBool))
             , (">", ([SMT.sReal, SMT.sReal], SMT.sBool))
             , ("<", ([SMT.sReal, SMT.sReal], SMT.sBool))
             ]
          ++ fs2 ++ cs

  constrs <- QM.pick $ do
    nconstrs <- choose ((0::Int), 3)
    replicateM nconstrs (genExpr genSorts sig SMT.sBool 10)
  QM.run $ do
    forM_ constrs $ \constr -> SMT.assert solver constr
    ret <- SMT.checkSAT solver
    when ret $ do
      m <- SMT.getModel solver
      forM_ fs2 $ \(f,_) -> do
        evaluate $ force $ show $ SMT.evalFSym m f
      return ()

-- https://github.com/msakai/toysolver/issues/21
case_issue21_32bit :: Assertion
case_issue21_32bit = do
  solver <- SMT.newSolver
  let constr =
        SMT.EAp (SMT.FSym "bvlshr" []) [SMT.EValue (SMT.ValBitVec (nat2bv 32 0)), SMT.EValue (SMT.ValBitVec (nat2bv 32 31))]
        .==.
        SMT.EValue (SMT.ValBitVec (nat2bv 32 0))
  SMT.assert solver constr

-- https://github.com/msakai/toysolver/issues/21
case_issue21_64bit :: Assertion
case_issue21_64bit = do
  solver <- SMT.newSolver
  let constr =
        SMT.EAp (SMT.FSym "bvlshr" []) [SMT.EValue (SMT.ValBitVec (nat2bv 64 0)), SMT.EValue (SMT.ValBitVec (nat2bv 64 63))]
        .==.
        SMT.EValue (SMT.ValBitVec (nat2bv 64 0))
  SMT.assert solver constr

genFunType :: Gen SMT.Sort -> Gen SMT.FunType
genFunType genSorts = do
  resultSort <- genSorts
  argsSorts <- listOf $ genSorts
  return (argsSorts, resultSort)

genExpr :: Gen SMT.Sort -> [(SMT.FSym, SMT.FunType)] -> SMT.Sort -> Int -> Gen SMT.Expr
genExpr genSorts sig s size = evalStateT (f s) size
  where
    sig' :: Map SMT.Sort [(SMT.FSym, [SMT.Sort])]
    sig' = Map.fromListWith (++) [(resultSort, [(fsym, argsSorts)]) | (fsym, (argsSorts,resultSort)) <- sig]

    f :: SMT.Sort -> StateT Int Gen SMT.Expr
    f s | s == SMT.sReal = do
      modify (subtract 1)
      size <- get
      (e,size') <- lift $ oneof $
        [ do
            r <- arbitrary
            return (fromRational r, size - 1)
        ]
        ++
        [ flip runStateT size $ do
            arg1 <- f SMT.sReal
            arg2 <- lift $ fromRational <$> arbitrary
            lift $ elements [ arg1 * arg2, arg2 * arg1, arg1 / arg2 ]
        | size >= 2
        ]
        ++
        [ flip runStateT size $ do
            args <- mapM f argsSorts
            return $ EAp op args
        | (op, argsSorts) <- Map.findWithDefault [] s sig'
        , op /= "*" && op /= "/"
        , size >= length argsSorts || null argsSorts
        ]
        ++
        [ flip runStateT size $ do
            arg1 <- f SMT.sBool
            arg2 <- f s
            arg3 <- f s
            return $ EAp "ite" [arg1, arg2, arg3]
        | size >= 3
        ]
      put size'
      return e
    f s@(SMT.Sort (SMT.SSymBitVec w) []) = do
      modify (subtract 1)
      size <- get
      (e,size') <- lift $ oneof $
        [ do
            bs <- replicateM w arbitrary
            return (EValue (SMT.ValBitVec (BV.fromDescBits bs)), size)
        ]
        ++
        [ flip runStateT size $ do
            w1 <- lift $ choose (1,w-1)
            arg1 <- f (SMT.Sort (SMT.SSymBitVec w1) [])
            arg2 <- f (SMT.Sort (SMT.SSymBitVec (w - w1)) [])
            return $ EAp "concat" [arg1,arg2]
        | w > 0, size >= 2
        ]
        ++
        [ flip runStateT size $ do
            wd <- lift $ choose (0,10)
            l <- lift $ choose (0, wd) -- inclusive range
            let u = l + w - 1
            arg <- f (SMT.Sort (SMT.SSymBitVec (w + wd)) [])
            return $ EAp (SMT.FSym "extract" [SMT.IndexNumeral (fromIntegral u), SMT.IndexNumeral (fromIntegral l)]) [arg]
        | w > 0, size >= 1
        ]
        ++
        [ flip runStateT size $ do
            arg <- f s
            return $ EAp op [arg]
        | op <- ["bvnot","bvneg"]
        , size >= 1
        ]
        ++
        [ flip runStateT size $ do
            arg1 <- f s
            arg2 <- f s
            return $ EAp op [arg1, arg2]
        | op <- ["bvand","bvor","bvxor","bvnand","bvnor","bvxnor","bvadd"] ++
                ["bvsub","bvmul","bvudiv","bvurem","bvshl","bvlshr","bvashr"] ++
                (if w >= 1 then ["bvsdiv", "bvsrem", "bvsmod"] else [])
        , size >= 2
        ]
        ++
        [ flip runStateT size $ do
            w2 <- lift $ choose (1, 10)
            arg1 <- f (SMT.Sort (SMT.SSymBitVec w2) [])
            arg2 <- f (SMT.Sort (SMT.SSymBitVec w2) [])
            return $ EAp "bvcomp" [arg1, arg2]
        | w == 1, size >= 2
        ]
        ++
        [ flip runStateT size $ do
            args <- mapM f argsSorts
            return $ EAp op args
        | (op, argsSorts) <- Map.findWithDefault [] s sig'
        , size >= length argsSorts || null argsSorts
        ]
        ++
        [ flip runStateT size $ do
            arg1 <- f SMT.sBool
            arg2 <- f s
            arg3 <- f s
            return $ EAp "ite" [arg1, arg2, arg3]
        | size >= 3
        ]
      put size'
      return e
    f s = do
      modify (subtract 1)
      size <- get
      (e,size') <- lift $ oneof $
        [ flip runStateT size $ do
            args <- mapM f argsSorts
            return $ EAp op args
        | (op, argsSorts) <- Map.findWithDefault [] s sig'
        , size >= length argsSorts || null argsSorts
        ]
        ++
        [ flip runStateT size $ do
            arg1 <- f SMT.sBool
            arg2 <- f s
            arg3 <- f s
            return $ EAp "ite" [arg1, arg2, arg3]
        | size >= 3
        ]
        ++
        [ flip runStateT size $ do
            s1 <- lift $ genSorts
            arg1 <- f s1
            arg2 <- f s1
            return $ EAp op [arg1, arg2]
        | s == SMT.sBool, size >= 2
        , op <- ["="]
        ]
        ++
        [ flip runStateT size $ do
            w <- lift $ choose (1, 10)
            arg1 <- f (SMT.Sort (SMT.SSymBitVec w) [])
            arg2 <- f (SMT.Sort (SMT.SSymBitVec w) [])
            return $ EAp op [arg1, arg2]
        | s == SMT.sBool, size >= 2
        , op <- ["bvule","bvult","bvuge","bvugt","bvsle","bvslt","bvsge","bvsgt"]
        ]
      put size'
      return e

------------------------------------------------------------------------
-- Test harness

smtTestGroup :: TestTree
smtTestGroup = $(testGroupGenerator)
