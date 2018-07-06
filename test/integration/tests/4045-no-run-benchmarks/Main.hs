import Control.Monad (unless,when)
import Data.List (isInfixOf)
import StackTest

main :: IO ()
main = do
    stack [defaultResolverArg, "clean"]
    stack [defaultResolverArg, "build"]
    stackOk ["test"] 
    stackFail ["bench"] 
    stackFail ["test", "--no-run-benchmarks"] 
    putStrLn "DONE"

stackOk :: [String] -> IO ()
stackOk arg = stackCheckStderr args (\_ -> return ())
  
stackFail :: [String] -> IO ()
stackFail args = stackErrStderr args (\_ -> return ())


