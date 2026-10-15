{
  description = "PINNacle encapsulated environment for compiler and hardware development for PINN training optimisation targeted at the MAGIA platform";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux"; # devlopment system architecture
      pkgs = nixpkgs.legacyPackages.${system};

      cross = pkgs.pkgsCross.riscv64-embedded.buildPackages;

      riscvAliases = pkgs.runCommand "riscv64-unknown-elf-aliases" {} ''
mkdir -p $out/bin
for pkg in ${cross.gcc} ${cross.binutils}; do
    for f in $pkg/bin/riscv64-none-elf-*; do
        ln -sf "$f" "$out/bin/riscv64-unknown-elf-''${f##*riscv64-none-elf-}"
    done
done
'';


    in with pkgs; {
      devShells.${system} = rec {
        default = mkShell {
          buildInputs = [
            python312
            verilator
            cross.gcc
            cross.binutils
            riscvAliases
            cmake
            rustc
            git
            ccache
          ];
          hardeningDisable = [ "all" ];
          shellHook = ''
export MAGIA_RTL_DIR="$(git rev-parse --show-toplevel)/MAGIA"
export MAKEFLAGS="SHELL=${pkgs.bash}/bin/bash"
'';
        };
      };
    };
}


