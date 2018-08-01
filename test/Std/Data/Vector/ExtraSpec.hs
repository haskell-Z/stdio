{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Std.Data.Vector.ExtraSpec where

import qualified Data.List                as List
import           Data.Word
import qualified Std.Data.Vector          as V
import qualified Std.Data.Vector.Extra    as V
import           Test.QuickCheck
import           Test.QuickCheck.Function
import           Test.QuickCheck.Property
import           Test.Hspec
import           Test.Hspec.QuickCheck

spec :: Spec
spec =  do
    describe "vector cons == List.(:)" $ do
        prop "vector cons == List.(:)" $ \ xs x ->
            (V.cons x . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack . (:) x $ xs)
        prop "vector cons == List.(:)" $ \ xs x ->
            (V.cons x . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack . (:) x $ xs)
        prop "vector cons == List.(:)" $ \ xs x ->
            (V.cons x . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack . (:) x $ xs)

    describe "vector snoc == List.++" $ do
        prop "vector snoc == List.++" $ \ xs x ->
            ((`V.snoc` x) . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack . (++ [x]) $ xs)
        prop "vector snoc == List.++" $ \ xs x ->
            ((`V.snoc` x) . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack . (++ [x]) $ xs)
        prop "vector snoc == List.++" $ \ xs x ->
            ((`V.snoc` x) . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack . (++ [x]) $ xs)

    describe "vector headMaybe == Just. List.head" $ do
        prop "vector headMaybe === Just . list.head" $ \ (NonEmpty xs) ->
            (V.headMaybe . V.pack @V.Vector @Integer $ xs)  ===
                (Just . List.head $ xs)
        prop "vector headMaybe === Just . List.head" $ \ (NonEmpty xs) ->
            (V.headMaybe . V.pack @V.PrimVector @Int $ xs)  ===
                (Just . List.head $ xs)
        prop "vector headMaybe === Just . List.head" $ \ (NonEmpty xs) ->
            (V.headMaybe . V.pack @V.PrimVector @Word8 $ xs)  ===
                (Just . List.head $ xs)

    describe "vector initMayEmpty == List.init" $ do
        prop "vector initMayEmpty === List.init" $ \ (NonEmpty xs) ->
            (V.initMayEmpty . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack . List.init $ xs)
        prop "vector initMayEmpty === List.init" $ \ (NonEmpty xs) ->
            (V.initMayEmpty . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack . List.init $ xs)
        prop "vector initMayEmpty === List.init" $ \ (NonEmpty xs) ->
            (V.initMayEmpty . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack . List.init $ xs)

    describe "vector lastMaybe == Just. List.last" $ do
        prop "vector lastMaybe === Just . list.last" $ \ (NonEmpty xs) ->
            (V.lastMaybe . V.pack @V.Vector @Integer $ xs)  ===
                (Just . List.last $ xs)
        prop "vector lastMaybe === Just . List.last" $ \ (NonEmpty xs) ->
            (V.lastMaybe . V.pack @V.PrimVector @Int $ xs)  ===
                (Just . List.last $ xs)
        prop "vector lastMaybe === Just . List.last" $ \ (NonEmpty xs) ->
            (V.lastMaybe . V.pack @V.PrimVector @Word8 $ xs)  ===
                (Just . List.last $ xs)

    describe "vector tailMayEmpty == List.tail" $ do
        prop "vector tailMayEmpty === List.tail" $ \ (NonEmpty xs) ->
            (V.tailMayEmpty . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack . List.tail $ xs)
        prop "vector tailMayEmpty === List.tail" $ \ (NonEmpty xs) ->
            (V.tailMayEmpty . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack . List.tail $ xs)
        prop "vector tailMayEmpty === List.tail" $ \ (NonEmpty xs) ->
            (V.tailMayEmpty . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack . List.tail $ xs)

    describe "vector take == List.take" $ do
        prop "vector take == List.take" $ \ xs x ->
            (V.take x . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack . List.take x $ xs)
        prop "vector take == List.take" $ \ xs x ->
            (V.take x . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack . List.take x $ xs)
        prop "vector take == List.take" $ \ xs x ->
            (V.take x . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack . List.take x $ xs)

    describe "vector drop == List.drop" $ do
        prop "vector drop == List.drop" $ \ xs x ->
            (V.drop x . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack . List.drop x $ xs)
        prop "vector drop == List.drop" $ \ xs x ->
            (V.drop x . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack . List.drop x $ xs)
        prop "vector drop == List.drop" $ \ xs x ->
            (V.drop x . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack . List.drop x $ xs)

    describe "vector slice x y == drop x . take (x+y)" $ do
        prop "vector slice x y === drop x . take (x+y)" $ \ x y xs ->
            (V.slice x y  . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack . drop x . take (x+y) $ xs)
        prop "vector slice x y xs === drop x . take (x+y) x" $ \ x y xs ->
            (V.slice x y  . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack . drop x . take (x+y) $ xs)
        prop "vector slice x y xs === drop x . take (x+y) x" $ \ x y xs ->
            (V.slice x y  . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack . drop x . take (x+y) $ xs)

    describe "vector (|..|) rules, see the document for (|..|)" $ do
        let f x y vs = let l = V.length vs
                           x' = if x >= 0 then x else l+x
                           y' = if y >= 0 then y else l+y
                       in V.slice x' (y'-x'+1) vs
        prop "vector (|..|) rules" $ \ x y xs ->
            (V.pack @V.Vector @Integer xs V.|..| (x,y))  === (f x y . V.pack $ xs)
        prop "vector (|..|) rules" $ \ x y xs ->
            (V.pack @V.PrimVector @Int xs V.|..| (x,y))  === (f x y . V.pack $ xs)
        prop "vector (|..|) rules" $ \ x y xs ->
            (V.pack @V.PrimVector @Word8 xs V.|..| (x,y))  === (f x y . V.pack $ xs)

    describe "vector splitAt == List.splitAt" $ do
        prop "vector splitAt == List.splitAt" $ \ xs x ->
            (V.splitAt x . V.pack @V.Vector @Integer $ xs)  ===
                (let (a,b) = List.splitAt x $ xs in (V.pack a, V.pack b))
        prop "vector splitAt == List.splitAt" $ \ xs x ->
            (V.splitAt x . V.pack @V.PrimVector @Int $ xs)  ===
                (let (a,b) = List.splitAt x $ xs in (V.pack a, V.pack b))
        prop "vector splitAt == List.splitAt" $ \ xs x ->
            (V.splitAt x . V.pack @V.PrimVector @Word8 $ xs)  ===
                (let (a,b) = List.splitAt x $ xs in (V.pack a, V.pack b))

    describe "vector takeWhile == List.takeWhile" $ do
        prop "vector takeWhile == List.takeWhile" $ \ xs (Fun _ x) ->
            (V.takeWhile x . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack . List.takeWhile x $ xs)
        prop "vector takeWhile == List.takeWhile" $ \ xs (Fun _ x) ->
            (V.takeWhile x . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack . List.takeWhile x $ xs)
        prop "vector takeWhile == List.takeWhile" $ \ xs (Fun _ x) ->
            (V.takeWhile x . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack . List.takeWhile x $ xs)

    describe "vector dropWhile == List.dropWhile" $ do
        prop "vector dropWhile == List.dropWhile" $ \ xs (Fun _ x) ->
            (V.dropWhile x . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack . List.dropWhile x $ xs)
        prop "vector dropWhile == List.dropWhile" $ \ xs (Fun _ x) ->
            (V.dropWhile x . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack . List.dropWhile x $ xs)
        prop "vector dropWhile == List.dropWhile" $ \ xs (Fun _ x) ->
            (V.dropWhile x . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack . List.dropWhile x $ xs)

    describe "vector break == List.break" $ do
        prop "vector break == List.break" $ \ xs (Fun _ x) ->
            (V.break x . V.pack @V.Vector @Integer $ xs)  ===
                (let (a,b) = List.break x $ xs in (V.pack a, V.pack b))
        prop "vector break == List.break" $ \ xs (Fun _ x) ->
            (V.break x . V.pack @V.PrimVector @Int $ xs)  ===
                (let (a,b) = List.break x $ xs in (V.pack a, V.pack b))
        prop "vector break == List.break" $ \ xs (Fun _ x) ->
            (V.break x . V.pack @V.PrimVector @Word8 $ xs)  ===
                (let (a,b) = List.break x $ xs in (V.pack a, V.pack b))

    describe "vector span == List.span" $ do
        prop "vector span == List.span" $ \ xs (Fun _ x) ->
            (V.span x . V.pack @V.Vector @Integer $ xs)  ===
                (let (a,b) = List.span x $ xs in (V.pack a, V.pack b))
        prop "vector span == List.span" $ \ xs (Fun _ x) ->
            (V.span x . V.pack @V.PrimVector @Int $ xs)  ===
                (let (a,b) = List.span x $ xs in (V.pack a, V.pack b))
        prop "vector span == List.span" $ \ xs (Fun _ x) ->
            (V.span x . V.pack @V.PrimVector @Word8 $ xs)  ===
                (let (a,b) = List.span x $ xs in (V.pack a, V.pack b))

    describe "vector breakEnd == List.break in reverse driection" $ do
        prop "vector breakEnd == List.break in reverse driection" $ \ xs (Fun _ x) ->
            (V.breakEnd x . V.pack @V.Vector @Integer $ xs)  ===
                (let (b,a) = List.break x . List.reverse $ xs
                 in (V.reverse $ V.pack a, V.reverse $ V.pack b))
        prop "vector breakEnd == List.break in reverse driection" $ \ xs (Fun _ x) ->
            (V.breakEnd x . V.pack @V.PrimVector @Int $ xs)  ===
                (let (b,a) = List.break x . List.reverse $ xs
                 in (V.reverse $ V.pack a, V.reverse $ V.pack b))
        prop "vector breakEnd == List.break in reverse driection" $ \ xs (Fun _ x) ->
            (V.breakEnd x . V.pack @V.PrimVector @Word8 $ xs)  ===
                (let (b,a) = List.break x . List.reverse $ xs
                 in (V.reverse $ V.pack a, V.reverse $ V.pack b))

    describe "vector spanEnd == List.span in reverse driection" $ do
        prop "vector spanEnd == List.span in reverse driection" $ \ xs (Fun _ x) ->
            (V.spanEnd x . V.pack @V.Vector @Integer $ xs)  ===
                (let (b,a) = List.span x . List.reverse $ xs
                 in (V.reverse $ V.pack a, V.reverse $ V.pack b))
        prop "vector spanEnd == List.span in reverse driection" $ \ xs (Fun _ x) ->
            (V.spanEnd x . V.pack @V.PrimVector @Int $ xs)  ===
                (let (b,a) = List.span x . List.reverse $ xs
                 in (V.reverse $ V.pack a, V.reverse $ V.pack b))
        prop "vector spanEnd == List.span in reverse driection" $ \ xs (Fun _ x) ->
            (V.spanEnd x . V.pack @V.PrimVector @Word8 $ xs)  ===
                (let (b,a) = List.span x . List.reverse $ xs
                 in (V.reverse $ V.pack a, V.reverse $ V.pack b))

    describe "vector group == List.group" $ do
        prop "vector group == List.group" $ \ xs ->
            (V.group . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack <$> List.group xs)
        prop "vector group == List.group" $ \ xs ->
            (V.group . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack <$> List.group xs)
        prop "vector group == List.group" $ \ xs ->
            (V.group . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack <$> List.group xs)

    describe "vector groupBy == List.groupBy" $ do
        prop "vector groupBy == List.groupBy" $ \ xs x ->
            (V.groupBy (applyFun2 x) . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack <$> List.groupBy (applyFun2 x) xs)
        prop "vector groupBy == List.groupBy" $ \ xs x ->
            (V.groupBy (applyFun2 x) . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack <$> List.groupBy (applyFun2 x) xs)
        prop "vector groupBy == List.groupBy" $ \ xs x ->
            (V.groupBy (applyFun2 x) . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack <$> List.groupBy (applyFun2 x) xs)

    describe "vector stripPrefix a (a+b) = b " $ do
        prop "vector stripPrefix == List.stripPrefix" $ \ xs ys ->
            (V.stripPrefix (V.pack xs) . V.pack @V.Vector @Integer $ xs++ys) ===
                (Just $ V.pack ys)
        prop "vector stripPrefix == List.stripPrefix" $ \ xs ys ->
            (V.stripPrefix (V.pack xs) . V.pack @V.PrimVector @Int $ xs++ys) ===
                (Just $ V.pack ys)
        prop "vector stripPrefix == List.stripPrefix" $ \ xs ys ->
            (V.stripPrefix (V.pack xs) . V.pack @V.PrimVector @Word8 $ xs++ys) ===
                (Just $ V.pack ys)

    describe "vector stripSuffix b (a+b) = a " $ do
        prop "vector stripSuffix == List.stripSuffix" $ \ xs ys ->
            (V.stripSuffix (V.pack xs) . V.pack @V.Vector @Integer $ ys++xs) ===
                (Just $ V.pack ys)
        prop "vector stripSuffix == List.stripSuffix" $ \ xs ys ->
            (V.stripSuffix (V.pack xs) . V.pack @V.PrimVector @Int $ ys++xs) ===
                (Just $ V.pack ys)
        prop "vector stripSuffix == List.stripSuffix" $ \ xs ys ->
            (V.stripSuffix (V.pack xs) . V.pack @V.PrimVector @Word8 $ ys++xs) ===
                (Just $ V.pack ys)

    describe "vector isInfixOf b (a+b+c) = True " $ do
        prop "vector isInfixOf == List.isInfixOf" $ \ xs ys zs ->
            (V.isInfixOf (V.pack xs) . V.pack @V.Vector @Integer $ ys++xs++zs) === True
        prop "vector isInfixOf == List.isInfixOf" $ \ xs ys zs ->
            (V.isInfixOf (V.pack xs) . V.pack @V.PrimVector @Int $ ys++xs++zs) === True
        prop "vector isInfixOf == List.isInfixOf" $ \ xs ys zs ->
            (V.isInfixOf (V.pack xs) . V.pack @V.PrimVector @Word8 $ ys++xs++zs) === True

    describe "vector intercalate [x] . split x == id" $ do
        prop "vector split = List.split" $ \ xs x ->
            (V.intercalate (V.singleton x) . V.split x . V.pack @V.Vector @Integer $ xs) ===
                V.pack xs
        prop "vector split = List.split" $ \ xs x ->
            (V.intercalate (V.singleton x) . V.split x . V.pack @V.PrimVector @Int $ xs) ===
                V.pack xs
        prop "vector split = List.split" $ \ xs x ->
            (V.intercalate (V.singleton x) . V.split x . V.pack @V.PrimVector @Word8 $ xs) ===
                V.pack xs

    describe "vector reverse == List.reverse" $ do
        prop "vector reverse === List.reverse" $ \ xs ->
            (V.reverse . V.pack @V.Vector @Integer $ xs)  === (V.pack . List.reverse $ xs)
        prop "vector reverse === List.reverse" $ \ xs ->
            (V.reverse . V.pack @V.PrimVector @Int $ xs)  === (V.pack . List.reverse $ xs)
        prop "vector reverse === List.reverse" $ \ xs ->
            (V.reverse . V.pack @V.PrimVector @Word8 $ xs)  === (V.pack . List.reverse $ xs)

    describe "vector intersperse == List.intersperse" $ do
        prop "vector intersperse === List.intersperse" $ \ xs x ->
            (V.intersperse x . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack . List.intersperse x $ xs)
        prop "vector intersperse x === List.intersperse x" $ \ xs x ->
            (V.intersperse x . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack . List.intersperse x $ xs)
        prop "vector intersperse x === List.intersperse x" $ \ xs x ->
            (V.intersperse x . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack . List.intersperse x $ xs)

    describe "vector intercalate == List.intercalate" $ do
        prop "vector intercalate === List.intercalate" $ \ xs ys ->
            (V.intercalate (V.pack ys) . List.map (V.pack @V.Vector @Integer) $ xs)  ===
                (V.pack . List.intercalate ys $ xs)
        prop "vector intercalate ys === List.intercalate x" $ \ xs ys ->
            (V.intercalate (V.pack ys) . List.map (V.pack @V.PrimVector @Int) $ xs)  ===
                (V.pack . List.intercalate ys $ xs)
        prop "vector intercalate ys === List.intercalate x" $ \ xs ys ->
            (V.intercalate (V.pack ys) . List.map (V.pack @V.PrimVector @Word8) $ xs)  ===
                (V.pack . List.intercalate ys $ xs)

    describe "vector intercalateElem x == List.intercalate [x]" $ do
        prop "vector intercalateElem x === List.intercalate [x]" $ \ xs x ->
            (V.intercalateElem x . List.map (V.pack @V.Vector @Integer) $ xs)  ===
                (V.pack . List.intercalate [x] $ xs)
        prop "vector intercalateElem ys === List.intercalate x" $ \ xs x ->
            (V.intercalateElem x . List.map (V.pack @V.PrimVector @Int) $ xs)  ===
                (V.pack . List.intercalate [x] $ xs)
        prop "vector intercalateElem ys === List.intercalate x" $ \ xs x ->
            (V.intercalateElem x . List.map (V.pack @V.PrimVector @Word8) $ xs)  ===
                (V.pack . List.intercalate [x] $ xs)

    describe "vector transpose == List.transpose" $ do
        prop "vector transpose == List.transpose" $ \ xs ->
            (V.transpose $ V.pack @V.Vector @Integer <$> xs)  ===
                (V.pack <$> List.transpose xs)
        prop "vector transpose == List.transpose" $ \ xs ->
            (V.transpose $ V.pack @V.PrimVector @Int <$> xs)  ===
                (V.pack <$> List.transpose xs)
        prop "vector transpose == List.transpose" $ \ xs ->
            (V.transpose $ V.pack @V.PrimVector @Word8 <$> xs)  ===
                (V.pack <$> List.transpose xs)

    describe "vector zipWith' == List.zipWith" $ do
        prop "vector zipWith' == List.zipWith" $ \ xs ys x ->
            let pack' = V.pack @V.Vector @Integer
            in (V.zipWith' (applyFun2 x) (pack' xs) (pack' ys))  ===
                (pack' $ List.zipWith (applyFun2 x) xs ys)
        prop "vector zipWith == List.zipWith" $ \ xs ys x ->
            let pack' = V.pack @V.PrimVector @Int
            in (V.zipWith' (applyFun2 x) (pack' xs) (pack' ys))  ===
                (pack' $ List.zipWith (applyFun2 x) xs ys)
        prop "vector zipWith' == List.zipWith" $ \ xs ys x ->
            let pack' = V.pack @V.PrimVector @Word8
            in (V.zipWith' (applyFun2 x) (pack' xs) (pack' ys))  ===
                (pack' $ List.zipWith (applyFun2 x) xs ys)

    describe "vector unzipWith' f == List.unzip . List.map f" $ do
        prop "vector zipWith' == List.unzip . List.map f" $ \ zs (Fun _ x) ->
            let pack' = V.pack @V.Vector @Integer
            in (V.unzipWith' x (pack' zs))  ===
                (let (a,b) = List.unzip (List.map x zs) in (pack' a, pack' b))
        prop "vector zipWith == List.unzip . List.map f" $ \ zs (Fun _ x) ->
            let pack' = V.pack @V.PrimVector @Int
            in (V.unzipWith' x (pack' zs))  ===
                (let (a,b) = List.unzip (List.map x zs) in (pack' a, pack' b))
        prop "vector zipWith' == List.unzip . List.map f" $ \ zs (Fun _ x) ->
            let pack' = V.pack @V.PrimVector @Word8
            in (V.unzipWith' x (pack' zs))  ===
                (let (a,b) = List.unzip (List.map x zs) in (pack' a, pack' b))

    describe "vector scanl' == List.scanl" $ do
        prop "vector scanl' === List.scanl" $ \ xs f x ->
            (V.scanl' @V.Vector @V.Vector (applyFun2 f :: Integer -> Integer -> Integer) x . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack . List.scanl (applyFun2 f) x $ xs)
        prop "vector scanl' x === List.scanl x" $ \ xs f x ->
            (V.scanl' @V.PrimVector @V.PrimVector (applyFun2 f :: Int -> Int -> Int) x . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack . List.scanl (applyFun2 f) x $ xs)
        prop "vector scanl' x === List.scanl x" $ \ xs f x ->
            (V.scanl' @V.PrimVector @V.Vector (applyFun2 f :: Int -> Word8 -> Int) x . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack . List.scanl (applyFun2 f) x $ xs)

    describe "vector scanl1' == List.scanl1" $ do
        prop "vector scanl1' === List.scanl1" $ \ xs f ->
            (V.scanl1' (applyFun2 f :: Integer -> Integer -> Integer) . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack . List.scanl1 (applyFun2 f) $ xs)
        prop "vector scanl1' x === List.scanl1 x" $ \ xs f ->
            (V.scanl1' (applyFun2 f :: Int -> Int -> Int) . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack . List.scanl1 (applyFun2 f) $ xs)
        prop "vector scanl1' x === List.scanl1 x" $ \ xs f ->
            (V.scanl1' (applyFun2 f :: Word8 -> Word8 -> Word8) . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack . List.scanl1 (applyFun2 f) $ xs)

    describe "vector scanr' == List.scanr" $ do
        prop "vector scanr' === List.scanr" $ \ xs f x ->
            (V.scanr' @V.Vector @V.Vector (applyFun2 f :: Integer -> Integer -> Integer) x . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack . List.scanr (applyFun2 f) x $ xs)
        prop "vector scanr' x === List.scanr x" $ \ xs f x ->
            (V.scanr' @V.PrimVector @V.PrimVector (applyFun2 f :: Int -> Int -> Int) x . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack . List.scanr (applyFun2 f) x $ xs)
        prop "vector scanr' x === List.scanr x" $ \ xs f x ->
            (V.scanr' @V.PrimVector @V.Vector (applyFun2 f :: Word8 -> Int -> Int) x . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack . List.scanr (applyFun2 f) x $ xs)

    describe "vector scanr1' == List.scanr1" $ do
        prop "vector scanr1' === List.scanr1" $ \ xs f ->
            (V.scanr1' (applyFun2 f :: Integer -> Integer -> Integer) . V.pack @V.Vector @Integer $ xs)  ===
                (V.pack . List.scanr1 (applyFun2 f) $ xs)
        prop "vector scanr1' x === List.scanr1 x" $ \ xs f ->
            (V.scanr1' (applyFun2 f :: Int -> Int -> Int) . V.pack @V.PrimVector @Int $ xs)  ===
                (V.pack . List.scanr1 (applyFun2 f) $ xs)
        prop "vector scanr1' x === List.scanr1 x" $ \ xs f ->
            (V.scanr1' (applyFun2 f :: Word8 -> Word8 -> Word8) . V.pack @V.PrimVector @Word8 $ xs)  ===
                (V.pack . List.scanr1 (applyFun2 f) $ xs)