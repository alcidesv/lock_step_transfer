{-# LANGUAGE OverloadedStrings #-}
import SecondTransfer(
    CoherentWorker
    , DataAndConclusion
    , tlsServeWithALPN
    , http2Attendant
    )
import SecondTransfer.Http2(
      makeSessionsContext
    , defaultSessionsConfig
    )

import Data.Conduit
import Data.ByteString.Char8 (pack)
-- import Data.IORef 
-- import Control.Applicative
import Control.Concurrent.MVar
import Control.Monad.IO.Class (liftIO)


saysHello :: Int -> MVar ComPoint -> Int -> DataAndConclusion
saysHello who_speaks commpoint repeats = 
    if repeats > 0 
      then do 
          -- Not the best way to go about it 
          liftIO $ takeMVar commpoint 
          yield . pack . show $ who_speaks 
          liftIO $ putMVar commpoint ComPoint
          saysHello who_speaks commpoint (repeats-1)
      else
          return []


data ComPoint = ComPoint 


interlockedWorker :: MVar Int -> MVar ComPoint -> CoherentWorker
interlockedWorker counters mvar _ = do
    my_num <- takeMVar counters 
    putMVar counters (my_num+1)
    return (
            [
                (":status", "200")
            ],
            [], -- No pushed streams
            saysHello my_num mvar 100
        )


-- For this program to work, it should be run from the top of 
-- the developement directory.
main :: IO ()
main = do 
    sessions_context <- makeSessionsContext defaultSessionsConfig
    counters <- newMVar 0
    can_talk <- newEmptyMVar
    let 
        http2_attendant = http2Attendant 
        						sessions_context 
        						$ interlockedWorker counters can_talk
    tlsServeWithALPN
        "servercert.pem"   -- Server certificate
        "privkey.pem"      -- Certificate private key
        "127.0.0.1"                      -- On which interface to bind
        [
            ("h2-14", http2_attendant),  -- Protocols present in the ALPN negotiation
            ("h2",    http2_attendant)   -- they may be slightly different, but for this 
                                         -- test it doesn't matter.
        ]
        8000 