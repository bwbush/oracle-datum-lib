{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}

module Test.Utils where

import qualified PlutusTx
import qualified PlutusTx.Builtins as BI
import qualified UntypedPlutusCore as UPLC
import qualified UntypedPlutusCore.Evaluation.Machine.Cek as UPLC
import           PlutusCore.Evaluation.Machine.ExBudgetingDefaults (defaultCekParameters)
import           Text.Hex
import           PlutusLedgerApi.V2
import           Test.Tasty.HUnit
import           PlutusCore.Evaluation.Machine.Exception
import           PlutusTx (CompiledCode, getPlc)
import           Utils (insertMap)

assertValidator :: CompiledCode a -> Assertion
assertValidator = uncurry assertBool . either (const ("", True)) ((, False) . show) . evaluateScriptPure

evaluateScriptPure :: CompiledCode a -> Either [Text] [Text]
evaluateScriptPure s =
    let namedT = UPLC._progTerm $ getPlc s
    in case UPLC.checkScope @UPLC.FreeVariableError namedT of
        Left _ -> Right []
        _ -> let (result, _, logOut) = UPLC.runCekDeBruijn defaultCekParameters UPLC.tallying UPLC.logEmitter namedT
            in case result of
                 Right _ -> Left logOut
                 Left (ErrorWithCause _ _) -> Right logOut

{-# INLINABLE exBD #-}
exBD :: BuiltinData
exBD = BI.mkConstr 0 [ exShareData
                     , exGenData
                     , exExtData
                     ]

{-# INLINABLE exShareData #-}
exShareData :: BuiltinData
exShareData =
    BI.mkConstr 0 [ BI.mkMap [(BI.mkI 0, exPriceMap')] ]

{-# INLINABLE exGenData #-}
exGenData :: BuiltinData
exGenData = BI.mkConstr 2 [ exPriceMap ]

{-# INLINABLE exPriceMap #-}
exPriceMap :: BuiltinData
exPriceMap = insertMap 0 (BI.mkI exPrice) exPriceMap'

{-# INLINABLE exPriceMap' #-}
exPriceMap' :: BuiltinData
exPriceMap' = BI.mkMap [ (BI.mkI 1, BI.mkI $ toInteger exTimestamp)
                       , (BI.mkI 2, BI.mkI $ toInteger exExpiry)
                       , (BI.mkI 3, BI.mkI exPrecision)
                       , (BI.mkI 4, BI.mkI exBaseId)
                       , (BI.mkI 5, BI.mkI exQuoteId)
                       , (BI.mkI 6, PlutusTx.toBuiltinData exBaseSymbol)
                       , (BI.mkI 7, PlutusTx.toBuiltinData exQuoteSymbol)
                       , (BI.mkI 8, PlutusTx.toBuiltinData exBaseName)
                       , (BI.mkI 9, PlutusTx.toBuiltinData exQuoteName)
                       , (BI.mkI exCustomIdx, BI.mkI exCustomField)
                       ]

{-# INLINABLE exExtData #-}
exExtData :: BuiltinData
exExtData = BI.mkConstr 1 [ BI.mkMap [ (BI.mkI 0, BI.mkI exOracleProviderId)
                                     , (BI.mkI 1, BI.mkI exDataSourceCount)
                                     , (BI.mkI 2, BI.mkI exDataSignatoriesCount)
                                     , (BI.mkI 3, BI.mkB exOracleProviderSignature)
                                     ]
                            ]

{-# INLINABLE exPrice #-}
exPrice :: Integer
exPrice = 467_810

{-# INLINABLE exTimestamp #-}
exTimestamp :: POSIXTime
exTimestamp = 1660765806

{-# INLINABLE exExpiry #-}
exExpiry :: POSIXTime
exExpiry = 1660795806

{-# INLINABLE exPrecision #-}
exPrecision :: Integer
exPrecision = 6

{-# INLINABLE exBaseId #-}
exBaseId :: Integer
exBaseId = 1

{-# INLINABLE exQuoteId #-}
exQuoteId :: Integer
exQuoteId = 0

{-# INLINABLE exBaseSymbol #-}
exBaseSymbol :: CurrencySymbol
exBaseSymbol = adaSymbol

{-# INLINABLE exQuoteSymbol #-}
exQuoteSymbol :: CurrencySymbol
exQuoteSymbol = adaSymbol

{-# INLINABLE exBaseName #-}
exBaseName :: TokenName
exBaseName = adaToken

{-# INLINABLE exQuoteName #-}
exQuoteName :: TokenName
exQuoteName = adaToken

{-# INLINABLE exOracleProviderId #-}
exOracleProviderId :: Integer
exOracleProviderId = 1

{-# INLINABLE exDataSourceCount #-}
exDataSourceCount :: Integer
exDataSourceCount = 12

{-# INLINABLE exDataSignatoriesCount #-}
exDataSignatoriesCount :: Integer
exDataSignatoriesCount = 20

exOracleProviderSignature :: BuiltinByteString
exOracleProviderSignature = "AAAAAAAAAAAAA"

{-# INLINABLE exCustomIdx #-}
exCustomIdx :: Integer
exCustomIdx = 20

{-# INLINABLE exCustomField #-}
exCustomField :: Integer
exCustomField = 42
