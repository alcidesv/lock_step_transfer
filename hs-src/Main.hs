{-# LANGUAGE OverloadedStrings #-}
import SecondTransfer(
    CoherentWorker
    , DataAndConclusion
    , tlsServeWithALPN
    , http2Attendant
    , enableConsoleLogging
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
          -- The following if puts the two streams in a lock-step. 
          -- That's probably not much of an ordeal, given that there
          -- are independent control threads pulling data, but anyways...
          if (who_speaks `rem` 3) /= 0 then do
            liftIO $ takeMVar commpoint 
            return ()
          else 
            liftIO $ putMVar commpoint ComPoint
          yield . pack . ( (++) "\nlong line and block with ordinal number ") . show $ who_speaks 
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
                (":status", "200"),
                ("server", "lock_step_transfer")
            ],
            [], -- No pushed streams
            saysHello my_num mvar 100
        )


-- For this program to work, it should be run from the top of 
-- the developement directory.
main :: IO ()
main = do 
    enableConsoleLogging
    sessions_context <- makeSessionsContext defaultSessionsConfig
    counters <- newMVar 0
    can_talk <- newEmptyMVar
    let 
        http2_attendant = http2Attendant 
        						sessions_context 
        						$ interlockedWorker counters can_talk
    tlsServeWithALPN
        "cert.pem"   -- Server certificate
        "privkey.pem"      -- Certificate private key
        "127.0.0.1"                      -- On which interface to bind
        [
            ("h2-14", http2_attendant),  -- Protocols present in the ALPN negotiation
            ("h2",    http2_attendant)   -- they may be slightly different, but for this 
                                         -- test it doesn't matter.
        ]
        8443 