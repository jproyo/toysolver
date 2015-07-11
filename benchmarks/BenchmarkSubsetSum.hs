module Main where

import Criterion.Main
import qualified ToySolver.Combinatorial.Knapsack.BB as KnapsackBB
import qualified ToySolver.Combinatorial.Knapsack.DPDense as KnapsackDPDense
import qualified ToySolver.Combinatorial.Knapsack.DPSparse as KnapsackDPSparse
import qualified ToySolver.Combinatorial.SubsetSum as SubsetSum
import qualified Data.Vector as V
import qualified Data.Vector.Unboxed as VU

main :: IO ()
main = Criterion.Main.defaultMain $
  [ bgroup "problem1"
      [ bench "KnapsackBB" $ nf (\(lhs,rhs) -> KnapsackBB.solve [(fromIntegral x, fromIntegral x) | x <- lhs] (fromIntegral rhs)) problem1
      , bench "KnapsackDPDense" $ nf (\(lhs,rhs) -> KnapsackDPDense.solve [(fromIntegral x, x) | x <- lhs] rhs) problem1
      , bench "KnapsackDPSparse" $ nf (\(lhs,rhs) -> KnapsackDPSparse.solveGeneric [(x, x) | x <- lhs] rhs) problem1
      , bench "KnapsackDPSparseInt" $ nf (\(lhs,rhs) -> KnapsackDPSparse.solveInt [(x, x) | x <- lhs] rhs) problem1
      , bench "SubsetSum" $ nf (\(lhs,rhs) -> SubsetSum.maxSubsetSum (V.fromList (map fromIntegral lhs)) (fromIntegral rhs)) problem1
      ]
  ] ++
  [ bgroup ("problem2_" ++ show rhs) $
      [ bench "KnapsackBB" $ nf (\lhs -> KnapsackBB.solve [(fromIntegral x, fromIntegral x) | x <- lhs] (fromIntegral rhs)) problem2_items
      ] ++
      (if rhs <= 500 then
         [ bench "KnapsackDPDense" $ nf (\lhs -> KnapsackDPDense.solve [(fromIntegral x, x) | x <- lhs] rhs) problem2_items
         , bench "KnapsackDPSparse" $ nf (\lhs -> KnapsackDPSparse.solveGeneric [(x, x) | x <- lhs] rhs) problem2_items
         , bench "KnapsackDPSparseInt" $ nf (\lhs -> KnapsackDPSparse.solveInt [(x, x) | x <- lhs] rhs) problem2_items
         ]
       else
         [])
      ++
      [ bench "SubsetSum" $ nf (\lhs -> SubsetSum.maxSubsetSum (V.fromList (map fromIntegral lhs)) (fromIntegral rhs)) problem2_items ]
  | rhs <- [50 :: Int, 100, 200, 500, 1000, 2000, 5000, 10000, 50000, 100000, 150000]
  ] ++ 
  [ bgroup ("problem3_" ++ show rhs) $
      [ bench "KnapsackBB" $ nf (\lhs -> KnapsackBB.solve [(fromIntegral x, fromIntegral x) | x <- lhs] (fromIntegral rhs)) problem3_items
      , bench "SubsetSum" $ nf (\lhs -> SubsetSum.maxSubsetSum (V.fromList (map fromIntegral lhs)) (fromIntegral rhs)) problem3_items
      ]
  | rhs <- [3000000, 5000000, 10000000, 50000000, 100000000, 1000000000]
  ]

problem1 :: ([Int], Int)
problem1 = ([6,2,3,8,1,8,10,4,4,10,7,2,4,4,10,10,8,10,4,8,1,4,5,6,1,6,9,7,10,6,7,3,9,6,6,7,8,1,1,1,10,1,5,10,4,1,3,4,2,9,4,7,7,2,6,10,8,6,5,4,1,2,2,1,2,3,7,7,2,6,1,3,4,6,4,2,1,8,1,4,3,7,4,3,9,4,4,10,5,7,4,4,4,6,10,1,7,2,4,3,5,5,1,5,3,1,9,5,8,2,5,10,1,9,10,4,7,10,1,2,4,2,8,5,6,1,1,5,3,1,3,8,9,5,2,9,5,1,5,4,8,6,4,9,2,1,2,3,9,6,8,5,9,9,9,2,2,8,7,1,1,2,7,6,5,5,2,8,4,3,6,4,5,6,6,3,1,4,2,6,3,10,5,4,9,3,7,2,3,3,3,10,9,9,10,7,8,3,2,2,7,8,8,10,9,1,1,4,3,10,8,7,9,4,5,5,1,7,8,7,6,3,1,5,10,8,7,1,10,4,8,3,7,8,3,10,10,7,1,1,5,6,5,3,10,9,8,3,9,3,3,7,10,3,6,3,1,3,5,7,10,9,4,6,10,4,5,5,7,1,5,8,8,4,1,10,10,3,6,2,8,1,7,2,7,7,1,1,2,10,4,2,5,3,7,2,4,1,6,2,9,10,9,9,2,5,2,5,7,5,9,9,2,10,2,7,6,8,5,8,6,1,5,2,2,4,1,4,3,9,4,4,4,5,8,3,4,1,4,1,5,5,1,3,5,8,7,9,2,1,1,5,1,4,7,10,8,10,3,8,8,5,10,1,5,3,8,6,8,3,6,8,6,10,4,2,5,7,10,4,10,6,4,8,1,9,1,9,7,3,7,3,1,10,8,8,4,8,4,5,7,8,7,6,2,3,6,1,7,10,7,1,6,6,1,5,2,4,1,5,5,2,2,4,10,5,5,3,4,8,4,3,4,9,3,4,5,8,5,9,10,9,9,4,9,6,4,3,6,9,1,2,1,6,4,5,3,9,6,4,8,9,3,3,9,7,9,5,3,8,3,9,2,6,4,10,6,1,2,6,4,1,5,10,3,9,7,1,4,2,8,9,1,3,3,6,2,1,1,5,1,8,1,2,9,10,8,1,2,2,5,4,10,2,7,4,8,2,1,2,1,2,2,2,7,3,9,7,5,7,7,3,9,7,4,1,2,8,1,3,4,1,7,2,10,10,10,1,6,10,2,6,1,4,7,8,7,5,1,2,2,7,1,9,1,2,2,8,1,8,7,2,7,3,9,6,5,1,10,4,2,9,3,3,8,6,4,8,7,7,9,2,1,6,7,1,6,10,3,5,4,8,7,1,10,10,6,5,1,9,2,4,6,9,6,5,2,8,5,9,8,9,3,8,5,9,6,1,1,5,7,5,9,8,1,1,3,5,4,8,4,6,2,8,1,8,7,7,5,9,2,8,2,10,9,1,7,4,6,7,8,10,10], 75)

problem2_items :: [Int]
problem2_items = [153,170,128,167,178,158,162,142,134,186,141,178,104,178,121,149,111,175,191,163,141,135,157,128,109,136,127,133,188,132,127,109,169,124,158,128,182,121,147,124,198,127,179,156,184,176,134,170,137,168,192,171,158,117,156,138,112,177,152,168,121,129,196,167,131,132,113,151,117,159,121,147,153,155,195,171,159,188,194,149,184,192,199,183,111,155,187,183,198,194,121,172,118,104,171,109,150,160,104,189,119,102,133,197,175,181,114,193,199,163,157,110,175,151,112,142,121,144,191,101,111,103,126,106,109,113,113,191,186,103,153,138,120,166,159,197,159,136,180,187,185,120,158,150,128,106,195,163,153,144,107,174,199,143,112,145,140,196,105,117,181,120,159,114,101,115,186,158,121,121,109,120,155,194,136,164,132,144,182,163,191,194,126,190,146,138,188,178,152,170,198,156,195,150,153,192,159,200,143,167,124,130,165,110,116,178,159,145,188,192,170,173,108,120,156,123,119,175,130,149,129,124,114,163,167,171,148,164,151,166,122,183,148,180,180,159,181,153,132,169,164,128,195,112,182,132,167,168,127,134,108,157,104,200,130,179,187,187,112,142,112,162,188,169,124,110,111,170,134,136,104,147,167,153,172,174,195,159,131,107,151,179,114,100,167,157,133,167,175,100,154,150,128,139,150,174,117,177,192,187,171,174,168,184,187,173,167,134,179,175,178,151,196,123,183,174,136,141,171,105,173,173,167,100,186,120,187,138,106,160,181,141,178,180,164,102,153,165,136,100,172,151,158,169,142,164,104,179,117,173,146,172,114,196,142,111,199,194,118,140,189,187,198,171,127,184,113,139,182,179,199,113,113,189,111,182,169,145,182,149,100,197,193,132,196,128,169,180,122,158,125,176,190,141,140,182,149,157,185,104,188,118,165,199,134,143,186,104,127,158,102,142,187,176,172,187,112,119,200,113,193,124,142,141,137,151,181,155,174,154,159,171,124,122,103,185,182,144,108,156,170,188,140,177,119,148,108,180,193,133,136,144,174,195,198,166,186,133,102,132,183,151,164,182,172,158,109,189,152,190,164,105,160,188,164,108,187,161,162,191,168,105,141,199,182,141,184,104,160,187,101,193,160,120,186,118,163,150,105,111,167,122,118,153,132,127,131,104,164,121,179,167,118,180,174,135,136,181,123,102,118,184,104,166,188,175,133,173,187,165,168,184,123,185,131,143,183,163,112,137,125,154,124,186,158,134,149,145,127,124,121,135,113,191,120,162,185,115,189,101,136,182,182,186,147,123,113,105,198,181,192,135,124,194,183,181,134,128,138,194,184,118,113,121,176,152,188,131,152,124,179,136,176,200,125,164,110,147,194,107,164,199,132,117,196,104,115,165,189,150,134,178,186,171,124,195,146,168,127,102,112,129,182,107,196,193,131,144,121,173,196,171,108,168,124,106,175,110,110,195,200,181,186,186,155,130,150,154,176,105,119,191,110,138,180,175,183,117,189,192,192,179,169,197,131,130,142,193,164,150,152,129,135,114,119,124,144,123,187,129,116,120,108,112,188,189,191,161,103,138,108,114,191,180,107,159,130,174,121,153,187,109,145,194,188,114,108,154,141,130,189,180,158,177,122,160,182,126,164,131,161,115,185,182,109,116,188,118,157,178,152,124,144,149,173,130,155,137,172,153,145,145,195,153,189,106,131,155,188,105,121,165,138,197,119,129,200,128,185,177,198,154,147,144,102,195,141,176,156,176,130,169,118,130,148,107,146,102,194,135,182,154,136,118,146,102,170,185,152,131,165,124,135,132,115,187,200,120,119,183,119,163,174,179,155,153,115,144,104,116,113,160,103,172,130,188,152,185,137,172,134,187,130,140,134,187,146,145,118,137,181,129,149,183,111,181,148,188,126,131,147,154,175,183,122,140,180,108,126,127,122,131,103,195,100,102,167,121,198,160,154,198,134,119,141,149,183,131,188,141,154,193,170,174,163,106,140,152,153,120,169,145,164,168,188,140,116,185,158,192,195,139,122,149,188,120,133,182,171,162,195,182,144,135,167,142,192,169,125,134,102,189,183,157,132,186,174,139,187,149,119,155,113,115,187,188,197,146,159,192,135,138,167,170,125,196,142,143,153,191,144,101,127,130,163,173,150,172,191,171,158,141,185,191,189,184,149,173,194,197,160,139,137,163,110,110,171,165,166,107,161,112,193,158,174,196,122,140,149,100,176,196,200,141,122,187,148,158,148,164,118,135,175,104,180,110,164,199,180,111]

problem3_items :: [Int]
problem3_items = [207486,278718,392484,332630,124581,307649,132267,136091,375212,163415,164347,430138,212508,309206,215276,251377,491250,373538,307637,447782,240424,461022,357034,223503,144424,207864,284687,420511,153358,321780,330369,369032,135725,268285,150930,383988,129493,281960,474921,257163,373045,223252,331242,411113,352001,351171,487540,489552,327939,469661,113153,340686,371278,470801,213710,446593,387688,231485,395898,459990,364795,399479,217801,246079,452483,446148,192388,403245,297280,271177,143554,232687,449863,104797,358276,468307,453129,219370,190587,415669,430833,331924,138190,359822,267972,376306,366836,421704,465564,209707,469491,397631,472458,167151,485050,165291,484372,251168,472722,468335,338020,194333,463694,263999,465139,268585,247707,173942,349507,165508,462807,398117,337302,413974,476648,468807,355557,304651,365958,193244,387236,484118,278334,258536,446833,152882,383133,486581,219227,459770,387769,387446,476125,277867,486709,248116,257316,130993,185829,417723,170028,198402,372810,182034,407229,366088,372362,383881,352151,114654,443216,447015,498825,459860,139855,192453,338995,321434,379652,481859,416264,105290,402806,457987,169685,252935,310167,268636,241850,100309,226297,191182,188723,374562,320544,243511,103823,426076,412436,468122,464664,316622,201015,229608,154615,412154,112874,369969,341732,304808,246714,290454,387280,303884,171132,193237,223693,488723,308389,181564,346151,368835,436496,353691,453094,355662,455065,137786,249900,113112,191444,407414,452547,168760,134902,162105,406871,450030,381171,378906,338574,157057,141305,186765,234688,375256,475105,491134,334671,431456,365210,118028,148280,330723,172051,258041,117355,205889,495549,493055,154613,162961,379075,196528,190625,423150,175660,375023,289422,237142,463494,235678,434029,327281,445674,369632,458219,388482,212423,372783,180349,335692,267192,448579,330522,313152,369572,426534,248974,222225,292740,284119,132210,429853,105306,352128,122707,472220,134357,285449,275075,248019,412536,179249,280860,294280,211022,168139,218128,139694,322893,121994,199188,100946,162961,453924,149571,364564,460145,495353,458575,213335,379299,275863,499164,274562,498522,321663,398349,318770,280071,331862,416142,308365,357140,319125,453961,480139,457347,377016,390537,196520,362845,154020,349537,385398,489602,423343,406602,123196,125568,417019,445758,458457,426268,452946,484910,448836,433729,324834,245734,380743,331514,157686,252577,428253,367083,471968,107156,427005,338277,262113,243864,269615,101192,170263,377730,270319,453471,391486,312811,443293,442349,487380,275884,440150,401134,166965,219570,104692,122358,120122,123715,498602,481952,347054,139916,401685,128200,149526,379371,331212,255522,159711,451272,156166,128210,211342,406991,366052,465497,100935,409995,280758,196996,397580,302005,480820,411628,348585,176772,111313,325528,411155,464260,347850,381752,259870,467789,477848,364054,436910,140876,134519,298893,325424,297696,184711,489607,338680,148571,443567,121034,322846,266345,222726,407504,414860,263524,434754,480910,207578,100518,347880,491921,134422,491674,182404,272279,444586,208971,192320,105950,157957,494658,205049,387026,339336,120353,383788,112304,275220,173269,169935,459692,410554,192883,175441,335000,222520,191763,302031,384352,274792,329574,103181,355560,127196,398565,417460,435428,451061,142796,101625,430071,353206,195934,364794,289998,467835,432256,288010,180436,460457,254518,387047,302439,152503,382526,152151,276423,450924,258088,322662,417620,344560,375094,395000,422076,366038,377494,332132,130406,229975,356346,203391,341025,283338,482403,336858,381023,438744,498121,176731,283221,449347,203945,480157,116567,198402,273210,258412,409135,348131,293673,409130,289279,302852,483872,177765,278125,486131,323631,392250,148731,352894,462025,394209,218092,400875,199282,318878,469669,396214,444880,220890,461749,284621,248745,456192,258819,103823,338314,191114,424112,268203,102427,267158,388420,239238,490769,371313,402759,162233,350904,127891,183998,123101,490827,176694,447670,397616,394469,323341,288604,297557,127951,218476,326345,354291,222402,384715,121194,405907,225630,363196,478621,252732,207491,186871,272663,230365,292240,227611,261584,362554,315000,179303,421116,270981,116340,483614,442535,446465,227958,343310,222133,307940,497624,113907,309642,126127,144524,222534,353109,486518,466031,162406,206819,154028,175422,384428,317852,489360,361660,173693,113270,349328,375476,374206,204314,450394,225912,201302,182999,356797,245752,398634,117138,177539,378892,331514,155500,399268,275638,173379,493859,142698,377633,269203,449070,269981,447674,413623,371651,156798,407610,249336,405543,236377,244941,169824,100922,156824,137972,155013,295926,361560,486317,435873,120864,141297,167198,425783,188249,441102,445107,395797,264716,471431,497153,136545,301877,354308,462237,227129,456740,472932,459907,391637,497929,399034,143258,411335,426067,470653,188964,108327,111293,336893,137013,194771,372853,329908,171847,194233,106477,380103,274446,450426,206112,415014,379602,439951,340846,272306,470527,133107,115415,259145,122312,338325,369567,470474,451959,338705,437051,452385,216707,449479,151907,428835,180424,241719,151597,244448,130373,430986,229168,459204,179617,199849,237246,306232,397934,243576,285789,277656,377599,156077,499688,231424,262394,415528,280356,234538,227091,345733,453131,217177,146006,333356,200052,470346,474708,168370,151077,371419,330227,231800,325079,199910,471947,493645,308292,122563,399958,162229,429168,474283,236945,140724,209683,388777,182064,136415,372367,400126,278111,369922,289321,113753,438008,324773,321419,188484,475891,411146,233377,175517,289258,339540,214601,176171,423047,483095,171064,462917,189709,303239,312276,204826,241605,155775,128859,326257,468421,236736,207392,333266,409611,286615,207848,314478,269296,343981,421504,353118,385327,367074,401314,281485,462831,279112,306293,198716,101333,418468,215057,346864,161105,159666,471781,112554,120145,230864,391123,227569,324701,277482,368782,280997,458626,452233,234281,391069,144662,336217,434198,481102,133920,263594,214746,471616,419015,223479,138342,462079,447443,134762,331833,429154,117219,285914,250377,118305,101881,498060,218401,213614,223017,300566,158469,121267,286310,301055,107407,178755,141092,456251,166112,402955,408829,439204,426501,480440,304923,201539,445094,205879,162844,228806,103807,427620,202098,209810,139248,424057,348761,109339,347667,374073,175100,495918,112570,135682,310236,407785,167419,257810,156857,261235,443784,352624,110542,224061,222757,253310,146420,411890,365520,297378,401917,191628,105592,316024,490318,492512,487964,433825,156132,126204,105729,467611,496444,457501,265183,195022,278749,439519,322335,137504,427583,245468,366402,460217,356020,274419,156097,205850,436420,128530,473145,479112,473688,169695,326903,290616,203165,453887,143601,223044,496570,366639,261971,186528,100402,285722,496695,398394,398107,473809,397183,239671,499792,214367,364772,376038,473733,324308,248931,468892,478836,244353,217797,442546,338187,247684,115001,131862]
