import Control.Monad (unless)
import StackTest
import System.IO (readFile)

main :: IO ()
main = do
  removeFileIgnore "stack.yaml"
  stackErr ["init", "--snapshot", "lts-22.7"]
  stack ["init", "--snapshot", "lts-22.7", "--omit-packages"]
  contents <- lines <$> readFile "stack.yaml"
  unless ("#- bad" `elem` contents) $
    error "commented out 'bad' package was expected"
