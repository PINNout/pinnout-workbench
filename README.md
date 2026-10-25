# PINNout Workbench
This repository contains a reproducible development environment for hardware and compiler development targeted at the MAGIA platform.

It supports simulation via `GVSoC` and `Verilator`

## Usage
This environment is optimised to be used with Nix. 

### Nix setup [Skip if you already have Flakes enabled] 
This section will focus on setting up Nix for Ubuntu.

> **Note for WSL:**
>
> Make sure you are using WSL 2, not WSL 1. `wsl -l -v` will show the version.
>
> The Nix daemon requires systemd. In Ubuntu, edit `/etc/wsl.conf` with root privileges and add:
> ```
> [boot]
> systemd=true
> ```
>
> Then run `wsl --shutdown` in PowerShell and reopen Ubuntu
>
> If building Verilator is too memory intensive you can raise the memory limit.
> If you don't already have a `.wslconfig` file you can just run this:
> ```
> Set-Content -Path "$env:USERPROFILE\.wslconfig" -Value '[wsl2]','memory=12GB' -Encoding ascii
> wsl --shutdown
> ```
> If you do already have a `.wslconfig` file then add this to the end (or modify):
> ```
> [wsl2]
> memory=12GB
> ```
> 12GB is just a placeholder. Select an appropriate value based on your available hardware.

#### Installation via Determinate installer
Run this command to download and install Nix:
``` bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Flakes and the `nix` command will be enabled automatically.

To verify everything worked:
``` bash
nix --version
nix flake --help # errors here mean flakes aren't enabled
```

### Using the environment

#### Basic Usage
This environment requires a fork of the LLVM project in order to compile instructions for the Spatz vector accelerator. To save the hassle and wait of having to build this LLVM fork from source, I have cached a build to Cachix, so that Nix will automatically pull the compiled binary from the server.

> *IMPORTANT NOTE ON USING SPATZ LLVM:*
> The Cachix LLVM build is not trusted by default, so on **NixOS** you will need to add the following to your `configuration.nix`:
> ```
> nix.settings.extra-substituters = [ "https://pinnout.cachix.org" ];
> nix.settings.extra-trusted-public-keys = [ "pinnout.cachix.org-1:51YtDHyrWhyzFO9Q8TCzF5Fb0BNBu3s5t58ovErMsns=" ];
> ```
> Then run `sudo nixos-rebuild switch`
>
> On **any system other than NixOS (Ubuntu, WSL, other distros)** you can simply run this command before entering the devShell:
> ```
> nix shell nixpkgs#cachix -c sh -c 'sudo "$(command -v cachix)" use pinnout'
> sudo systemctl restart nix-daemon
> ```
>
> The first time you run `nix develop`, Nix asks whether to trust the flake's cache settings. Answer `y` to each prompt.

Once nix is setup, simply `cd` to the root of the project and run:
``` bash
nix develop
```

This will install all required dependencies if they have not yet been installed.

If it is the first time that you are entering the devShell, you will be prompted to set up the submodules, the Bender dependencies and the GVSoC sources. There will be several GB worth of data to download, so expect it to take a while. 

Similarly, you will also be asked whether you would like to build the simulators: `GVSoC` and the `Verilator` model of MAGIA. Note that the Verilator build process can take a long time and is very memory intensive.

#### Using Deeploy
To keep dependencies lighter-weight, a separate devShell has been created that adds the required dependencies for Deeploy. To enter this environment, `cd` to the root of the project and run:
``` bash
nix develop .#deeploy
```

## Adjusting Workflow
Changing the parameters in this file requires rebuilding both the simulators and the binaries. The setup script only checks whether the simulators exist, not whether they match the current config, so rebuild them manually:
``` bash
rm -rf magia-sdk/build
(cd magia-sdk && make gvsoc tiles=<tiles> spatz=<spatz>)
(cd MAGIA && make verilate mesh_dv=1)
```

## Verifying it works
To verify the environment is set up correctly and the simulators are behaving properly, run from the project root:
```bash
scripts/verify_setup.sh
```

This will run the same basic "Hello world" test on both simulators and compare that the outputs match.

### Testing Deeploy Compilation
This must be run inside the Deeploy shell (`nix develop .#deeploy`). The `tiles` value must match `scripts/config.sh`.
`cd` to `magia-sdk/` and run:
``` bash
make deploy_with_spatz test=pinn-mlp/fp16/spatz platform=gvsoc tiles=4
```

This will compile the PINN-MLP ONNX graph on to the MAGIA platform and verify its behaviour with GVSoC.

## Maintenance
The cached Spatz LLVM only matches the exact nixpkgs version pinned in `flake.lock` and the `spatzLlvm` definition in `flake.nix`. If either changes (e.g. after `nix flake update`), rebuild it and push it to the cache:
``` bash
nix build .#spatz-llvm -L
nix shell nixpkgs#cachix -c cachix push pinnout ./result
```
Otherwise everyone silently builds LLVM from source. To check whether a flake change affects it, run `nix build .#spatz-llvm --dry-run`: if `spatz_llvm` is listed under "will be built", the cache no longer matches.

## Known Limitations
The ISA is temporarily reduced to omit `xcvhwlp`, `xcvmem` and `xcvbitmanip` as the riscv64 gcc toolchain doesn't fully support these by default. 
