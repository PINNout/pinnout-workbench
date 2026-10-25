{
  description = "PINNout encapsulated environment for compiler and hardware development for PINN training optimisation targeted at the MAGIA platform";

  nixConfig = {
    extra-substituters = [ "https://pinnout.cachix.org" ];
    extra-trusted-public-keys = [ "pinnout.cachix.org-1:51YtDHyrWhyzFO9Q8TCzF5Fb0BNBu3s5t58ovErMsns=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs?ref=nixos-26.05";
  };

  outputs = { nixpkgs, nixpkgs-stable, ... }:

    # ----------------------------------------
    # define parameters
    # ----------------------------------------
    let
      system = "x86_64-linux"; # development system architecture
      pkgs = nixpkgs.legacyPackages.${system};
      pkgsStable = nixpkgs-stable.legacyPackages.${system};

      cross = pkgs.pkgsCross.riscv64-embedded.buildPackages;

      basePackages = with pkgs; [
        verilator
        cross.gcc
        cross.binutils
        riscvAliases
        cmake
        rustc
        git
        ccache
        pkg-config
        SDL2
        SDL2_ttf
        libsndfile
        rsync
        zlib
        lz4
        shellcheck
        pkgsStable.bender];

      basePython = ps: [
        ps.numpy ps.prettytable ps.pyelftools ps.rich ps.six
        ps.pexpect ps.psutil ps.typing-extensions ps.pyyaml ps.protobuf
      ];

      commonHook = ''
export MAGIA_RTL_DIR="$(git rev-parse --show-toplevel)/MAGIA"
export MAKEFLAGS="SHELL=${pkgs.bash}/bin/bash"
export NIX_ENFORCE_NO_NATIVE=0
unset OBJCOPY OBJDUMP
export LLVM_INSTALL_DIR=${spatzLlvm}
"$(git rev-parse --show-toplevel)/scripts/setup_env.sh"
'';

      riscvAliases = pkgs.runCommand "riscv64-unknown-elf-aliases" {} ''
mkdir -p $out/bin
for pkg in ${cross.gcc} ${cross.binutils}; do
    for f in $pkg/bin/riscv64-none-elf-*; do
        ln -sf "$f" "$out/bin/riscv64-unknown-elf-''${f##*riscv64-none-elf-}"
    done
done
'';

      # ----------------------------------------
      # Build packages
      # ----------------------------------------
      onnxGraphsurgeon = pkgs.python3.pkgs.buildPythonPackage rec {
        pname = "onnx_graphsurgeon";
        version = "0.6.1";
        format = "wheel";

        src = pkgs.python3.pkgs.fetchPypi {
          inherit pname version format;
          dist = "py2.py3";
          python = "py2.py3";
          hash = "sha256-+rxT/GCQndAyz9iJAW3V1BOatWavSpA5ACgY9VLHNUc=";
        };

        dependencies = with pkgs.python3.pkgs; [ numpy onnx ];
        pythonImportsCheck = [ "onnx_graphsurgeon" ];
      };


      # Current magia-sdk depends on unreleased Deeploy version "am/magia-kernels-2"
      deeployPulp = pkgs.python3.pkgs.buildPythonPackage rec {
        pname = "deeploy_pulp";
        version = "0.2.1";
        # format = "wheel";
        pyproject = true;
        build-system = with pkgs.python3.pkgs; [ setuptools wheel ];

        src = pkgs.fetchFromGitHub {
          owner = "FondazioneChipsIT";
          repo = "Deeploy";
          rev = "36e348548be5b6215e28db45b4b69d1fa2c3fd86";
          hash = "sha256-WPkS2D1fjZ5ePssQiISSm/Z2kZQ0XrA+IPDjSeyBWMw=";
        };
        
        # src = pkgs.python3.pkgs.fetchPypi {
        #   inherit pname version format;
        #   dist = "py3";
        #   python = "py3";
        #   hash = "sha256-8835VQUsYibQbhXC3bGcQ+SwXKughov6TGn3nDXvT5M=";
        # };

        pythonRelaxDeps = [ "numpy" "protobuf" "setuptools" ];
        pythonRemoveDeps = [ "plotly" "pytest" "pytest-xdist" "argparse" ];
        dependencies = with pkgs.python3.pkgs; [ numpy protobuf setuptools onnx onnxruntime mako toml coloredlogs onnxGraphsurgeon ortools ];
        pythonImportsCheck = [ "Deeploy" "Deeploy.Targets.Generic.Layers" ];
      };

      spatzLlvm = pkgs.gcc13Stdenv.mkDerivation{
        pname = "spatz_llvm";
        version = "14-b494f2d";

        src = pkgs.fetchFromGitHub{
          owner = "pulp-platform";
          repo = "llvm-project";
          rev = "b494f2d8dde88723026db8ec16ac6c7ee1e140ca";
          hash = "sha256-BT6X8F0OKsSv4CyjiYuu7ZJVrZTiB38uaa0Id3BX/co=";
        };

        nativeBuildInputs = with pkgs; [ cmake ninja python3 ];
        cmakeDir = "../llvm";
        env.CXXFLAGS = "-include cstdint";
        cmakeFlags = [ "-DLLVM_APPEND_VC_REV=OFF"
                       "-DLLVM_PARALLEL_LINK_JOBS=2"
                       "-DLLVM_OPTIMIZED_TABLEGEN=True"
                       "-DLLVM_ENABLE_PROJECTS=clang;lld"
                       "-DLLVM_TARGETS_TO_BUILD=RISCV"
                       "-DLLVM_DEFAULT_TARGET_TRIPLE=riscv32-unknown-elf"
                       "-DLLVM_ENABLE_LLD=False"
                       "-DCMAKE_BUILD_TYPE=Release"
                       "-DCMAKE_INSTALL_BINDIR=bin"
                     ];
      };

      # ----------------------------------------
      # declare devShells
      # ----------------------------------------
    in with pkgs; {
      devShells.${system} = rec {
        # default shell
        default = mkShell {
          packages = basePackages ++ [ (python3.withPackages basePython) ];
          hardeningDisable = [ "all" ];
          shellHook = commonHook;
        };

        # shell with deeploy (run with `nix develop .#deeploy`)
        deeploy = mkShell {
          packages = basePackages ++ [ (python3.withPackages
            (ps: basePython ps ++ [ onnxGraphsurgeon deeployPulp ])) ];
          hardeningDisable = ["all"];
          shellHook = commonHook;
        };
      };
      packages.${system}.spatz-llvm = spatzLlvm;
    };
}


