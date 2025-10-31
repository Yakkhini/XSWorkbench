{
  description = "Nix devshells for XiangShan";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    formatter.x86_64-linux = pkgs.alejandra;

    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        boost
        gflags
        glog
        gperftools
        gtest
        llvm
        libelf
        libffi
        libpng
        libtool
        pkg-config
        (python3.withPackages (ps:
          with ps; [
            scipy
            pandas
            psutil
            pyyaml
            matplotlib
            dash
          ]))
        temurin-bin

        # override scons built-in python library version to 3.10 since newer version
        # has issues in compatibility.
        (scons.override {python3Packages = pkgs.python310Packages;})
        swig
        zlib

        # The following dependencies are optional and seldom used
        # protobuf # protobuf version is strictly enforced by gem5, not sure which version
        # hdf5

        # === lib ===
        readline
        SDL2
        zlib
        zstd
        sqlite
      ];
      packages = with pkgs; [
        # === scripts ===
        (writeScriptBin "nemumake" ''make -C $NEMU_HOME $1'')
        (writeScriptBin "gem5just" ''just -f $GEM5_HOME/Justfile -d $GEM5_HOME $1 $2'')

        # === tool ===
        wget
        git
        zellij
        curl
        time
        parallel
        lazysql
        delta

        # === toolchain ===
        gcc
        pkgsCross.riscv64.buildPackages.gcc
        clang
        bear
        gnumake
        gnum4
        cmake
        ninja
        dtc # device tree compiler
        flex
        autoconf
        bison
        statix
        coursier
        # override mill & verilator to use our version
        (mill.overrideAttrs (finalAttrs: previousAttrs: {
          version = "0.12.3";
          src = fetchurl {
            url = "https://github.com/com-lihaoyi/mill/releases/download/${finalAttrs.version}/${finalAttrs.version}-assembly";
            hash = "sha256-hqzAuYadCciYPs/b6zloLUfrWF4rRtlBSMxSj7tLg7g=";
          };
        }))
        (verilator.overrideAttrs (finalAttrs: previousAttrs: {
          version = "5.028";
          VERILATOR_SRC_VERSION = "v${finalAttrs.version}";
          src = fetchFromGitHub {
            owner = "verilator";
            repo = "verilator";
            rev = "v${finalAttrs.version}";
            hash = "sha256-YgK60fAYG5575uiWmbCODqNZMbRfFdOVcJXz5h5TLuE=";
          };
          doCheck = false;
        }))

        # === debug ===
        gtkwave
      ];

      # Disable hardening, FORTIFY is causing problem when building XS-GEM5 debug version without optimization
      hardeningDisable = ["all"];

      shellHook = ''
        echo "=== Welcome to XiangShan devshell! ==="
        echo "Version info:"
        echo "- $(verilator --version)"
        echo "- $(mill --version | head -n 1)"
        echo "- $(gcc --version | head -n 1)"
        echo "- $(riscv64-unknown-linux-gnu-gcc --version | head -n 1)"
        echo "- $(java -version 2>&1 | head -n 1)"
        echo "You can press Ctrl + D to exit devshell."
        export XS_PROJECT_ROOT=`pwd`
        export NEMU_HOME=`readlink -f NEMU`
        export AM_HOME=`readlink -f nexus-am`
        export NOOP_HOME=`readlink -f XiangShan`
        export DRAMSIM3_HOME=`readlink -f DRAMsim3`
        export GEM5_HOME=`readlink -f GEM5`
        export PATH="$HOME/.local/share/coursier/bin:$XS_PROJECT_ROOT/install/bin:$PATH"
        export PYTHONPATH=`readlink -f GEM5/DataProcess`:$PYTHONPATH
      '';
    };
  };
}
