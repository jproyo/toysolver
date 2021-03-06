module Main where

import Control.Monad
import Data.Array.IArray
import Data.Default.Class
import Text.Printf
import Criterion.Main
import qualified ToySolver.SAT as SAT
import qualified ToySolver.FileFormat as FF
import qualified ToySolver.FileFormat.CNF as CNF

solve :: FilePath -> IO ()
solve fname = do
  ret <- FF.parseFile fname
  case ret of
    Left err  -> error $ show err
    Right cnf -> do
      solver <- SAT.newSolverWithConfig def{ SAT.configRandomFreq = 0 }
      _ <- replicateM (CNF.cnfNumVars cnf) (SAT.newVar solver)
      forM_ (CNF.cnfClauses cnf) $ \clause ->
        SAT.addClause solver (SAT.unpackClause clause)
      SAT.solve solver
      return ()

main :: IO ()
main = do
  Criterion.Main.defaultMain
    [ bgroup "uf250-1065"
        [ bench fname $ whnfIO (solve path)
        | i <- [(1::Int)..100]
        , let fname = printf "uf250-0%d.cnf" i
        , let path = "benchmarks/UF250.1065.100/" ++ fname
        ]
    , bgroup "uuf250-1065"
        [ bench fname $ whnfIO (solve path)
        | i <- [(1::Int)..100]
        , let fname = printf "uuf250-0%d.cnf" i
        , let path = "benchmarks/UUF250.1065.100/" ++ fname
        ]
    ]
