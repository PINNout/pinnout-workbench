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
Once nix is setup, simply `cd` to the root of the project and run:
``` bash
nix develop
```

This will install all required dependencies if they have not yet been installed.

If it is the first time that you are entering the devShell, you will be prompted to set up the submodules, the Bender dependencies and the the GVSoC sources. There will be several GB worth of data to download, so expect it to take a while. 

Similarly, you will also be asked whether you would like to build the simulators: `GVSoC` and the `Verilator` model of MAGIA. Note that the Verilator build process can take a long time and is very memory intensive.

## Adjusting Workflow
If you need to make any changes to the environment settings, or the configuration of the simulation runs, you can edit the `scripts/config.sh` file.

Changing the parameters in this file requires building both the simulators and the binaries.

## Verifying it works
To verify the environemnt is setup correctly and the simulators are behaving properly. Run from the project root:
```bash
scripts/verify_setup.sh
```

This will run the same basic "Hello world" test on both simulators and compare that the outputs match.

## Known Limitations
The ISA is temporarily reduced to omit `xcvhwlp`, `xcvmem` and `xcvbitmap` as the riscv64 gcc toolchain doesn't fully support these by default. 


