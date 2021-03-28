{
  description = "A very basic flake";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils/master";
    smunix-diagrams-contrib.url = "github:smunix/diagrams-contrib/fix.diagrams";
    smunix-diagrams-core.url = "github:smunix/diagrams-core/fix.diagrams";
    smunix-diagrams-lib.url = "github:smunix/diagrams-lib/fix.diagrams";
    smunix-diagrams-svg.url = "github:smunix/diagrams-svg/fix.diagrams";
  }; 
  outputs =
    { self, nixpkgs, flake-utils, smunix-diagrams-lib,
      smunix-diagrams-contrib, smunix-diagrams-core, smunix-diagrams-svg,
      ...
    }:
    with flake-utils.lib;
    with nixpkgs.lib;
    eachSystem [ "x86_64-linux" ] (system:
      let version = "${substring 0 8 self.lastModifiedDate}.${self.shortRev or "dirty"}";
          overlay = self: super:
            with self;
            with haskell.lib;
            with haskellPackages.extend(self: super: {
              inherit (smunix-diagrams-contrib.packages.${system}) diagrams-contrib;
              inherit (smunix-diagrams-core.packages.${system}) diagrams-core;
              inherit (smunix-diagrams-lib.packages.${system}) diagrams-lib;
              inherit (smunix-diagrams-svg.packages.${system}) diagrams-svg;
            });
            {
              diagrams-contrib = rec {
                package = overrideCabal (callCabal2nix "diagrams-contrib" ./. {}) (o: { version = "${o.version}-${version}"; });
              };
            };
          overlays = [ overlay ];
      in
        with (import nixpkgs { inherit system overlays; });
        rec {
          packages = flattenTree (recurseIntoAttrs { diagrams-contrib = diagrams-contrib.package; });
          defaultPackage = packages.diagrams-contrib;
        });
}
