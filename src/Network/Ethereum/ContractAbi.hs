{-# LANGUAGE TemplateHaskell #-}
-- |
-- Module      :  Network.Ethereum.ContractAbi
-- Copyright   :  Alexander Krupenkin 2016
-- License     :  BSD3
--
-- Maintainer  :  mail@akru.me
-- Stability   :  experimental
-- Portability :  POSIX / WIN32
--
-- Ethereum smart contract utils.
--
module Network.Ethereum.ContractAbi where

import qualified Data.Text as T
import Data.Char (toLower)
import Data.Monoid ((<>))
import Data.Text (Text)
import Data.Aeson.TH

data FunctionArg = FunctionArgs
  { funArgName :: Text
  , funArgType :: Text
  } deriving Show

$(deriveJSON (defaultOptions { fieldLabelModifier = map toLower . drop 6 }) ''FunctionArg)

data EventArg = EventArg
  { eveArgName    :: Text
  , eveArgType    :: Text
  , eveArgIndexed :: Bool
  } deriving Show

$(deriveJSON (defaultOptions { fieldLabelModifier = map toLower . drop 6 }) ''EventArg)

data Method = Constructor { conInputs :: [FunctionArg] }

            | Function { funName      :: Text
                       , funInputs    :: [FunctionArg]
                       , funOutputs   :: Maybe [FunctionArg] }

            | Event { eveName      :: Text
                    , eveInputs    :: [EventArg]
                    , eveAnonymous :: Bool }
  deriving Show

$(deriveJSON (defaultOptions {
    sumEncoding = defaultTaggedObject { tagFieldName = "type" }
  , constructorTagModifier = map toLower
  , fieldLabelModifier = map toLower . drop 3 }) ''Method)

type ContractABI = [Method]

events :: ContractABI -> [Method]
events = filter (\x -> case x of Event _ _ _ -> True; _ -> False)

eventSignature :: Method -> Text
eventSignature event = eveName event <> "(" <> args event <> ")"
  where args = T.init . foldMap (<> ",") . inputTypes
        inputTypes = fmap eveArgType . filter eveArgIndexed . eveInputs