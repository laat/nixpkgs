# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, Extra, haskellSrc }:

cabal.mkDerivation (self: {
  pname = "ipprint";
  version = "0.5";
  sha256 = "0h75k21blbnzvp5l20qsima557dx6zfrww79y7qsqf04pbd81j7s";
  buildDepends = [ Extra haskellSrc ];
  meta = {
    description = "Tiny helper for pretty-printing values in ghci console";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;

    # Works For Me. GHC 7.8.4, 2015-01-08 
    #broken = true;
  };
})