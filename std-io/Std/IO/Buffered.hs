{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE ImplicitParams #-}

{-|
Module      : Std.IO.Buffered
Description : Buffered IO interface
Copyright   : (c) Dong Han, 2017-2018
License     : BSD
Maintainer  : winterland1989@gmail.com
Stability   : experimental
Portability : non-portable

This module provide buffered IO interface.

-}

module Std.IO.Buffered
  ( -- * Input & Output device
    Input(..), Output(..)
    -- * Buffered Input
  , BufferedInput
  , newBufferedInput
  , readBuffer
  , unReadBuffer
  , readParser
  , readExactly
  , readToMagic, readToMagic'
  , readLine, readLine'
  , readAll, readAll'
    -- * Buffered Output
  , BufferedOutput
  , newBufferedOutput
  , writeBuffer
  , writeBuilder
  , flushBuffer
    -- * Exceptions
  , ShortReadException(..)
    -- * common buffer size
  , V.defaultChunkSize
  , V.smallChunkSize
  ) where

import           Control.Concurrent.MVar
import           Control.Concurrent.STM.TVar
import           Control.Monad
import           Control.Monad.Primitive     (ioToPrim, primToIO)
import           Control.Monad.ST
import           Data.IORef
import           Data.Primitive.PrimArray
import           Data.Typeable
import           Data.Word
import           Foreign.Ptr
import           Std.Data.Array
import qualified Std.Data.Builder.Base       as B
import qualified Std.Data.Parser             as P
import qualified Std.Data.Vector             as V
import qualified Std.Data.Vector.Base        as V
import qualified Std.Data.Text               as T
import           Std.Data.PrimIORef
import           Std.Foreign.PrimArray
import           Std.IO.Exception

-- | Input device
--
-- Laws: 'readInput' should return 0 on EOF.
--
-- Note: 'readInput' is considered not thread-safe, e.g. A 'Input' device
-- can only be used with a single 'BufferedInput', If multiple 'BufferedInput' s
-- are opened on a same 'Input' device, the behaviour will be undefined.
--
class Input i where
    readInput :: HasCallStack => i -> Ptr Word8 -> Int -> IO Int

-- | Output device
--
-- Laws: 'writeOutput' should not return until all data are written (may not
-- necessarily flushed to hardware, that should be done in device specific way).

-- Note: 'writeOutput' is considered not thread-safe, e.g. A 'Output' device
-- can only be used with a single 'BufferedOutput', If multiple 'BufferedOutput' s
-- are opened on a same 'Input' device, the behaviour will be undefined.
--
class Output o where
    writeOutput :: HasCallStack => o -> Ptr Word8 -> Int -> IO ()

-- | Input device with buffer, NOT THREAD SAFE!
data BufferedInput i = BufferedInput
    { bufInput    :: i
    , bufPushBack :: {-# UNPACK #-} !(IORef V.Bytes)
    , inputBuffer :: {-# UNPACK #-} !(IORef (MutablePrimArray RealWorld Word8))
    }

-- | Output device with buffer, NOT THREAD SAFE!
data BufferedOutput o = BufferedOutput
    { bufOutput     :: o
    , bufIndex      :: {-# UNPACK #-} !Counter
    , outputBuffer  :: {-# UNPACK #-} !(MutablePrimArray RealWorld Word8)
    }


newBufferedInput :: input
                 -> Int     -- ^ Input buffer size
                 -> IO (BufferedInput input)
newBufferedInput i bufSiz = do
    pb <- newIORef V.empty
    buf <- newPinnedPrimArray (max bufSiz 0)
    inputBuffer <- newIORef buf
    return (BufferedInput i pb inputBuffer)

newBufferedOutput :: output
                  -> Int    -- ^ Output buffer size
                  -> IO (BufferedOutput output)
newBufferedOutput o bufSiz = do
    index <- newPrimIORef 0
    buf <- newPinnedPrimArray (max bufSiz 0)
    return (BufferedOutput o index buf)

-- | Request bytes from 'BufferedInput'.
--
-- The buffering logic is quite simple:
--
-- If we have pushed back bytes, directly return it, otherwise we read using buffer size.
-- If we read N bytes, and N is larger than half of the buffer size, then we freeze buffer and return,
-- otherwise we copy buffer into result and reuse buffer afterward.
--
readBuffer :: (HasCallStack, Input i) => BufferedInput i -> IO V.Bytes
readBuffer BufferedInput{..} = do
    pb <- readIORef bufPushBack
    if V.null pb
    then do
        rbuf <- readIORef inputBuffer
        bufSiz <- getSizeofMutablePrimArray rbuf
        l <- readInput bufInput (mutablePrimArrayContents rbuf) bufSiz
        if l < bufSiz `quot` 2                -- read less than half size
        then do
            mba <- newPrimArray l              -- copy result into new array
            copyMutablePrimArray mba 0 rbuf 0 l
            ba <- unsafeFreezePrimArray mba
            return $! V.fromArr ba 0 l
        else do                                -- freeze buf into result
            when (bufSiz /= 0) $ do
                buf' <- newPinnedPrimArray bufSiz
                writeIORef inputBuffer buf'
            ba <- unsafeFreezePrimArray rbuf
            return $! V.fromArr ba 0 l
    else do
        writeIORef bufPushBack V.empty
        return pb

-- | Read exactly N bytes
--
-- If EOF reached before N bytes read, a 'ShortReadException' will be thrown
--
readExactly :: (HasCallStack, Input i) => Int -> BufferedInput i -> IO V.Bytes
readExactly n h = V.concat `fmap` (go h n)
  where
    go h n = do
        chunk <- readBuffer h
        let l = V.length chunk
        if l > n
        then do
            let (lastChunk, rest) = V.splitAt n chunk
            unReadBuffer rest h
            return [lastChunk]
        else if l == n
            then return [chunk]
            else if l == 0
                then
                    throwIO (ShortReadException
                        (IOEInfo "" "unexpected EOF reached" callStack))
                else do
                    chunks <- go h (n - l)
                    return (chunk : chunks)

-- | Read all chunks from a 'BufferedInput'.
readAll :: (HasCallStack, Input i) => BufferedInput i -> IO [V.Bytes]
readAll i = loop []
  where
    loop acc = do
        chunk <- readBuffer i
        if V.null chunk
        then return $! reverse (chunk:acc)
        else loop (chunk:acc)

-- | Read all chunks from a 'BufferedInput', and concat chunks together.
readAll' :: (HasCallStack, Input i) => BufferedInput i -> IO V.Bytes
readAll' i = V.concat <$> readAll i


data ShortReadException = ShortReadException IOEInfo deriving (Show, Typeable)

instance Exception ShortReadException where
    toException = ioExceptionToException
    fromException = ioExceptionFromException

-- | Push bytes back into buffer
--
unReadBuffer :: (HasCallStack, Input i) => V.Bytes -> BufferedInput i -> IO ()
unReadBuffer pb' BufferedInput{..} = do
    modifyIORef' bufPushBack $ \ pb -> pb' `V.append` pb

-- | Read buffer and parse with 'Parser'.
--
readParser :: (HasCallStack, Input i) => P.Parser a -> BufferedInput i -> IO (V.Bytes, Either P.ParseError a)
readParser p i = do
    bs <- readBuffer i
    P.parseChunks p (readBuffer i) bs

-- | Read until reach a magic bytes
--
-- If EOF is reached before meet a magic byte, partial bytes are returned.
readToMagic :: (HasCallStack, Input i) => Word8 -> BufferedInput i -> IO V.Bytes
readToMagic magic h = V.concat `fmap` (go h magic)
  where
    go h magic = do
        chunk <- readBuffer h
        if V.null chunk
        then return []
        else case V.elemIndex magic chunk of
            Just i -> do
                let (lastChunk, rest) = V.splitAt (i+1) chunk
                unReadBuffer rest h
                return [lastChunk]
            Nothing -> do
                chunks <- go h magic
                return (chunk : chunks)

-- | Read until reach a magic bytes
--
-- If EOF is reached before meet a magic byte, a 'ShortReadException' will be thrown.
readToMagic' :: (HasCallStack, Input i) => Word8 -> BufferedInput i -> IO V.Bytes
readToMagic' magic h = V.concat `fmap` (go h magic)
  where
    go h magic = do
        chunk <- readBuffer h
        if V.null chunk
        then throwIO (ShortReadException
            (IOEInfo "" "unexpected EOF reached" callStack))
        else case V.elemIndex magic chunk of
            Just i -> do
                let (lastChunk, rest) = V.splitAt (i+1) chunk
                unReadBuffer rest h
                return [lastChunk]
            Nothing -> do
                chunks <- go h magic
                return (chunk : chunks)

-- | Read to a linefeed ('\n' or '\r\n'), return 'Bytes' before it.
--
-- If EOF is reached before meet a magic byte, partial line is returned.
readLine :: (HasCallStack, Input i) => BufferedInput i -> IO V.Bytes
readLine i = do
    bs@(V.PrimVector arr s l) <- readToMagic 10 i
    if l == 0
    then return bs
    else return $ case bs `V.indexMaybe` (l-2) of
        Nothing -> V.PrimVector arr s (l-1)
        Just r | r == 13   -> V.PrimVector arr s (l-2)
               | otherwise -> V.PrimVector arr s (l-1)

-- | Read to a linefeed ('\n' or '\r\n'), return 'Bytes' before it.
--
-- If EOF reached before meet a '\n', a 'ShortReadException' will be thrown.
readLine' :: (HasCallStack, Input i) => BufferedInput i -> IO V.Bytes
readLine' i = do
    bs@(V.PrimVector arr s l) <- readToMagic' 10 i
    if l == 0
    then return bs
    else return $ case bs `V.indexMaybe` (l-2) of
        Nothing -> V.PrimVector arr s (l-1)
        Just r | r == 13   -> V.PrimVector arr s (l-2)
               | otherwise -> V.PrimVector arr s (l-1)

--------------------------------------------------------------------------------

-- | Write 'V.Bytes' into buffered handle.
--
-- Copy 'V.Bytes' to buffer if it can hold, otherwise
-- write both buffer(if not empty) and 'V.Bytes'.
--
writeBuffer :: (Output o) => BufferedOutput o -> V.Bytes -> IO ()
writeBuffer o@BufferedOutput{..} v@(V.PrimVector ba s l) = do
    i <- readPrimIORef bufIndex
    bufSiz <- getSizeofMutablePrimArray outputBuffer
    if i + l <= bufSiz
    then do
        -- current buffer can hold it
        copyPrimArray outputBuffer i ba s l   -- copy to buffer
        writePrimIORef bufIndex (i+l)              -- update index
    else do
        if (i > 0)
        then do
            -- flush the buffer
            withMutablePrimArrayContents outputBuffer $ \ ptr -> writeOutput bufOutput ptr i
            writePrimIORef bufIndex 0

            writeBuffer o v -- try write to buffer again
        else
            withPrimVectorSafe v (writeOutput bufOutput)


-- | Write 'V.Bytes' into buffered handle.
--
-- Copy 'V.Bytes' to buffer if it can hold, otherwise
-- write both buffer(if not empty) and 'V.Bytes'.
--
writeBuilder :: (Output o) => BufferedOutput o -> B.Builder a -> IO ()
writeBuilder BufferedOutput{..} (B.Builder b) = do
    i <- readPrimIORef bufIndex
    originBufSiz <- getSizeofMutablePrimArray outputBuffer
    _ <- primToIO (b (B.OneShotAction action) (lastStep originBufSiz) (B.Buffer outputBuffer i))
    return ()
  where
    action :: V.Bytes -> ST RealWorld ()
    action bytes = ioToPrim (withPrimVectorSafe bytes (writeOutput bufOutput))

    lastStep :: Int -> a -> B.BuildStep RealWorld
    lastStep originBufSiz _ (B.Buffer buf offset)
        | sameMutablePrimArray buf outputBuffer = ioToPrim $ do
            writePrimIORef bufIndex offset   -- record new buffer index
            return []
        | offset >= originBufSiz = ioToPrim $ do
            withMutablePrimArrayContents buf $ \ ptr -> writeOutput bufOutput ptr offset
            writePrimIORef bufIndex 0
            return [] -- to match 'BuildStep' return type
        | otherwise = ioToPrim $ do
            copyMutablePrimArray outputBuffer 0 buf 0 offset
            writePrimIORef bufIndex offset
            return [] -- to match 'BuildStep' return type

-- | Flush the buffer(if not empty).
--
flushBuffer :: Output f => BufferedOutput f -> IO ()
flushBuffer BufferedOutput{..} = do
    i <- readPrimIORef bufIndex
    withMutablePrimArrayContents outputBuffer $ \ ptr -> writeOutput bufOutput ptr i
    writePrimIORef bufIndex 0
