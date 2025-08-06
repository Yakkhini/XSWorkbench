# OpenXiangShan Workbench

Yet another OpenXiangShan develop framework with heavy modifications and more aggressive features:

1. Use Nix Flakes to manage environments and delete several scripts;
2. Provide more rational global command system even in Git submodules;
3. More integrated projects like GEM5.

## Setup

To set up the environment, it needs to install Nix and enable Flakes support. Then, run:

```sh
nix develop
```

Direnv is another optional tool to enter the development environment automatically when you `cd` into the project directory.

Since all dependencies and environment variables are declared in `flake.nix`, no need to run `setup-tools.sh` to install theme anymore.

Use `just` to run setup command which declared in `Justfile`:

```sh
just setup
```

## Acknowledgements

This project is modified from [Original XiangShan Frontend Develop Environment.](https://github.com/OpenXiangShan/xs-env)
