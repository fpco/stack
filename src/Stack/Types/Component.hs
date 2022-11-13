{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveDataTypeable #-}

-- | All component related types (library, internal library, foreign library, executable, tests, benchmarks) in stack.
-- The chosen design replicates many of cabal existing things but in simplified
-- and sometimes more typed versions. It's a work in progress to bring
-- Stack to a more componentized design, and closer to cabal.
module Stack.Types.Component(
    HasName,
    HasBuildInfo,
    StackBenchmark(..),
    StackBuildInfo(..),
    StackExecutable(..),
    StackForeignLibrary(..),
    StackLibrary(..),
    StackTest(..),
    StackUnqualCompName(..),
    unqualCompToText
) where

import           Stack.Prelude
import           Stack.Types.Dependency (DepValue)
import           GHC.Records (HasField)
import           Distribution.PackageDescription (BenchmarkInterface, TestSuiteInterface)
import           Distribution.ModuleName (ModuleName)
import Distribution.Utils.Path (SymbolicPath, PackageDir, SourceDir)

type HasName component = HasField "name" component StackUnqualCompName
type HasBuildInfo component = HasField "buildInfo" component StackBuildInfo

-- | A main or sub library. We do not keep the [Cabal ADT name distinction](https://hackage.haskell.org/package/Cabal-syntax/docs/Distribution-Types-LibraryName.html#t:LibraryName)
-- because in Cabal 3.0 it's [likely](https://github.com/haskell/cabal/issues/8567) that the main/sub distinction doesn't make sense anymore.
-- Besides, the missing name from main libe can simply be encoded as an empty string for backward compatibility without loosing info.
-- Through this simplification we get a clean name interface for all components (they all have a potentially mempty name of the same type).
--
-- [Library](https://hackage.haskell.org/package/Cabal-syntax/docs/Distribution-Types-Library.html) is the Cabal equivalent.
--
data StackLibrary =
    StackLibrary
    { name :: StackUnqualCompName
    , buildInfo :: !StackBuildInfo
    , exposedModules :: [ModuleName]
    -- ^ This is only used for gathering the files related to this component.
    }
    deriving (Show, Typeable)

-- Stack foreign libraries.
--
-- [ForeignLib](https://hackage.haskell.org/package/Cabal-syntax/docs/Distribution-Types-Foreign-Libraries.html) is the Cabal equivalent.
--
data StackForeignLibrary =
    StackForeignLibrary
    { name :: StackUnqualCompName
    , buildInfo :: !StackBuildInfo
    }
    deriving (Show, Typeable)

-- Stack executable.
--
-- [Executable](https://hackage.haskell.org/package/Cabal-syntax/docs/Distribution-Types-Executable.html) is the Cabal equivalent.
--
data StackExecutable =
    StackExecutable
    { name :: StackUnqualCompName
    , buildInfo :: !StackBuildInfo
    , modulePath :: FilePath
    }
    deriving (Show, Typeable)

-- Stack test.
--
-- [TestSuite](https://hackage.haskell.org/package/Cabal-syntax/docs/Distribution-Types-TestSuite.html) is the Cabal equivalent.
--
data StackTest =
    StackTest
    { name :: StackUnqualCompName
    , buildInfo :: !StackBuildInfo
    , interface :: !TestSuiteInterface
    }
    deriving (Show, Typeable)

-- Stack benchmark.
--
-- [Benchmark](https://hackage.haskell.org/package/Cabal-syntax/docs/Distribution-Types-Benchmark.html) is the Cabal equivalent.
--
data StackBenchmark =
    StackBenchmark
    { name :: StackUnqualCompName
    , buildInfo :: StackBuildInfo
    , interface :: BenchmarkInterface
    -- ^ This is only used for gathering the files related to this component.
    }
    deriving (Show, Typeable)

-- | Name of an executable.
newtype ExeName = ExeName Text
    deriving (Show, Eq, Ord, Hashable, IsString, Generic, NFData, Data, Typeable)

-- | The name of an unqualified component (that is, it can be an executable, a library, anything).
-- The Cabal equivalent is [UnqualComponentName](https://hackage.haskell.org/package/Cabal-syntax/docs/Distribution-Types-UnqualComponentName.html#t:UnqualComponentName).
-- Ideally, we'd want to use the cabal type behing this newtype and not Text to avoid unnecessary work, but
-- for now this is too much refactoring (also there is no Hashable instance for UnqualComponentName yet).
newtype StackUnqualCompName = StackUnqualCompName Text
    deriving (Show, Eq, Ord, Hashable, IsString, Generic, NFData, Data, Typeable)
unqualCompToText :: StackUnqualCompName -> Text
unqualCompToText (StackUnqualCompName v) = v

-- | This is the Stack equivalent of Cabal's [BuildInfo](https://hackage.haskell.org/package/Cabal-syntax/docs/Distribution-Types-BuildInfo.html).
-- We don't use the cabal version because Cabal provides a list of dependencies (and we need a Map), and we only need a tiny subset of all
-- the Cabal provided info.
-- It's also the decomposition of @Package@ based information in prior versions of stack,
-- to enable component based builds and backpack.
-- The file gathering related fields are lazy because not always needed.
data StackBuildInfo =
    StackBuildInfo {sbiBuildable :: !Bool
                   -- ^ From BuildInfo in cabal
                   ,sbiDependency :: !(Map PackageName DepValue)
                   -- ^ From targetBuildDepends in BuildInfo in cabal.
                   ,sbiUnknownTools :: Set Text
                   -- ^ From buildTool in Cabal, we only keep the legacy
                   -- build tool depends that we know (from a hardcoded list).
                   -- We only use the deduplication aspect of the Set here, as this
                   -- field is only used for error reporting in the end.
                   -- This is kept lazy because it's an error reporting field only.
                   ,sbiOtherModules :: [ModuleName]
                   -- ^ Only used in file gathering. See usage in "Stack.ComponentFile" module.
                   ,sbiJsSources :: [FilePath]
                   -- ^ Only used in file gathering. See usage in "Stack.ComponentFile" module.
                   ,hsSourceDirs :: [SymbolicPath PackageDir SourceDir]
                   -- ^ Only used in file gathering. See usage in "Stack.ComponentFile" module.
                   ,cSource :: [FilePath]
                   -- ^ Only used in file gathering. See usage in "Stack.ComponentFile" module.
                   }
                   deriving (Show)
