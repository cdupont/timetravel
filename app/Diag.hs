{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE TypeFamilies              #-}

module Diag where

import Diagrams.Prelude hiding (rotate, E)
import Diagrams.Backend.SVG.CmdLine
import Control.Monad
import Tree
import Data.Maybe
import Linear.Quaternion
import Text.Printf
import Data.Colour.Palette.BrewerSet
import Data.Map hiding (map)
import Diagrams.TwoD.Arrow

clrs :: [Colour Double]
clrs = brewerSet Reds 3 

showGraph :: Map Pos Room -> Diagram B
showGraph m = spots (keys m) <> arrows (toList m)

spots :: [Pos] -> Diagram B
spots ps = mconcat $ map (\p -> spot p <> tex p) ps where
  spot :: Pos -> Diagram B
  spot p@(Pos _ _ t) = circle 0.02 # lw none # fc (clrs !! t) # moveTo (proj $ toP3 p) 
  tex p@(Pos x y t)  = text (" (" ++ (show x) ++ "," ++ (show y) ++ "," ++ (show t) ++ ")") # fontSizeL 0.1 moveTo (proj $ toP3 p) # fc (clrs !! t)

arrows :: [(Pos, Room)] -> Diagram B
arrows rs = mconcat $ map (\(p1, (Room ds))-> doorArrows p1 (toList ds)) rs where

doorArrows :: Pos -> [(Dir, (Pos, Dir))] -> Diagram B
doorArrows p1@(Pos _ _ t) ds = mconcat $ map (\(d1, (p2, d2)) -> mkArrow (proj $ toP3 p1, d1) (proj $ toP3 p2, d2) t) ds


toP3 :: Pos -> P3 Double
toP3 (Pos x y t) = p3 (fromIntegral x, fromIntegral y, fromIntegral t)

proj :: P3 Double -> P2 Double 
proj p = origin .+^ v ^._xy where
  v = rotate q (p .-. origin)
  q = axisAngle (V3 1.0 1.0 0.0) 0.3 


control :: Dir -> V2 Double
control N = r2 (0, 0.5)
control S = r2 (0, -0.5)
control E = r2 (0.5, 0)
control W = r2 (-0.5, 0)

shaft :: (P2 Double, Dir) -> (P2 Double, Dir) ->  Located (Trail V2 Double)
shaft (p, d) (p', d') = trailFromSegments [bézier3 (control d) ((p' .-. p) - (control d')) (p' .-. p)] `at` p

mkArrow :: (P2 Double, Dir) -> (P2 Double, Dir) -> Int -> Diagram B
mkArrow a b col = arrowFromLocatedTrail' (with & arrowHead .~ dart
                              & lengths .~ veryLarge
                              & shaftStyle %~ lw thick) (shaft a b) # lc (clrs !! col)

ex :: IO ()
--ex = mainWith $ bg white $ showGraph (genUniv (Pos 2 2 2)) # centerXY # pad 1.1
ex = mainWith $ bg white $ showGraph smallU' # centerXY # pad 1.1
--ex = mainWith $ bg white $ (mkArrow (p2 (0, 0), E) (p2 (1, 1), W)) # centerXY # pad 1.1
