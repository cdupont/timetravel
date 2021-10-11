{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE TypeFamilies              #-}

module Graph where

import Lib
import Data.Graph
import Data.Graph.Inductive.Query.DFS
import Data.Graph.Inductive.Graph
import Data.Graph.Inductive.Basic
import Data.Graph.Inductive.PatriciaTree
import Data.Graph.Inductive.Query.GVD
import Data.Graph.Inductive.NodeMap
import Data.Tree
import Data.Graph.Inductive.Query.BFS
import Types

test :: Gr Pos Dir
test = mkGraph [(0, Pos 0 0 0), (1, Pos 0 1 0), (2, Pos 1 0 0), (3, Pos 1 1 0),
                (4, Pos 0 0 1), (5, Pos 0 1 1), (6, Pos 1 0 1), (7, Pos 1 1 1)]
               [(0, 6, R), (0, 5, U), (1, 7, R), (1, 4, D),
                (2, 4, L), (2, 7, U), (3, 5, L), (3, 6, D), (6, 3, R)]

smallU :: Gr Pos Dir
smallU = insMapEdge nm portal g where
  (g, nm) = genUniverse 3 3 3
  portal :: (Pos, Pos, Dir)
  portal = (Pos 2 0 2, Pos 0 0 0, R)

genUniverse :: Int -> Int -> Int -> (Gr Pos Dir, NodeMap Pos)
genUniverse x y t = mkMapGraph ps ls where
  ps = genPoses x y t
  ls = filter (\(_, b, _) -> b `elem` ps) $ concatMap links ps

genPoses :: Int -> Int -> Int -> [Pos]
genPoses x_max y_max t_max = [(Pos x y t) | t <- [0..t_max-1], y <- [0..y_max-1], x <- [0..x_max-1]]

move :: Pos -> Dir -> Pos
move (Pos x y t) U = (Pos x (y+1) (t+1))
move (Pos x y t) D = (Pos x (y-1) (t+1))
move (Pos x y t) R = (Pos (x+1) y (t+1))
move (Pos x y t) L = (Pos (x-1) y (t+1))

links :: Pos -> [(Pos, Pos, Dir)]
links p = (p, move p U, U)
        : (p, move p D, D)
        : (p, move p L, L)
        : (p, move p R, R)
        : []


trav :: CFun Pos Dir [Node]
trav (_, _, _, outs) = map snd $ filter (\(a, _) -> a == R) outs

res :: CFun Pos Dir Pos
res (_, _, a, _) = a

f a = xdfsWith trav res [a] test 

-- Valid transits
validTrans :: Context Pos Dir -> Bool
-- No transit at all
validTrans ([], _, _, []) = True
--Just going in or out
validTrans ([], _, _, _) = True
validTrans (_, _, _, []) = True
-- Going in, going out
validTrans ([(R, _)], _, _, [(R, _)]) = True
validTrans ([(L, _)], _, _, [(L, _)]) = True
validTrans ([(U, _)], _, _, [(U, _)]) = True
validTrans ([(D, _)], _, _, [(D, _)]) = True
-- Collisions
validTrans ([(R, _), (D, _)], _, _, [(D, _), (R, _)]) = True
validTrans _ = False


validPath :: Gr Pos Dir -> [Node] -> Bool
validPath g ns = and $ map (validTrans . context g) ns

toPos :: Int -> Int -> Int -> Node -> Pos
toPos mx my mt n = Pos (n `rem` mx) ((n `div` mx) `rem` my) ((n `div` (mx * my)) `rem` mt)

toNode :: Int -> Int -> Int -> Pos -> Node
toNode mx my _ (Pos x y t) = x + y*mx + t*mx*my

allPaths = bft 0 smallU

validPaths = filter (\p -> validPath (subgraph p smallU) p) allPaths

