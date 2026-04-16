# Gascity Quickstart

## Prerequisites

* https://github.com/gastownhall/gascity/blob/main/docs/getting-started/installation.md

```bash
mkdir -p ~/Projects/actual-software
pushd ~/Projects/actual-software
git clone git@github.com:actual-software/software-factory-intensive.git
```

## Quick Guide

### GasCity Setup

Pinned Version (preferred)

```bash
brew tap-new $USER/local
brew extract --version=0.14.1 gastownhall/gascity/gascity $USER/local
brew install gascity@0.14.1
```

Latest

```bash
brew update
brew upgrade gascity
which gc
gc version
```

#### Setup Factory - baseline

##### Init Factory and Project

```bash
mkdir -p ~/Projects/factory/baseline/base-project
pushd ~/Projects/factory/baseline/base-project
git init
touch README.md && git add -A && git commit -m "initial"

gc init ~/Projects/factory/baseline/base-gc-factory
```

Select `3. custom`

```bash
Welcome to Gas City SDK!

Choose a config template:
  1. tutorial  — default coding agent (default)
  2. gastown   — multi-agent orchestration pack
  3. custom    — empty workspace, configure it yourself
Template [1]: 3
```

##### Configure Factory

```bash
pushd ~/Projects/factory/baseline/base-gc-factory
cp ~/Projects/actual-software/software-factory-intensive/prerequisites/city.toml ~/Projects/factory/baseline/base-gc-factory
rsync -av ~/Projects/actual-software/software-factory-intensive/packs/ ~/Projects/factory/baseline/base-gc-factory/packs/actual/

gc service restart
gc status
gc doctor --fix
```

##### Add "Rig" ie Project Source Repo to Factory

```bash
pushd ~/Projects/factory/baseline/base-gc-factory
gc rig add ~/Projects/factory/baseline/base-project
```

##### Register City

```bash
gc register ~/Projects/factory/baseline/base-gc-factory
```

##### Patch "convoy" in Factory and Project

```bash
pushd ~/Projects/factory/baseline/base-project && bd config set types.custom "convoy"
pushd ~/Projects/factory/baseline/base-gc-factory && bd config set types.custom "convoy"
```

##### Restart Factory

```bash
pushd ~/Projects/factory/baseline/base-gc-factory
gc stop
gc start
gc restart
```

##### Startup Gascity Dashboard

```bash
pushd ~/Projects/factory/baseline/base-gc-factory
gc dashboard serve
```

Open Gascity Dashboard in Browser

* http://localhost:8080

##### Generate Task to Verify Factory

```bash
gc sling base-gc-factory "Create a script that prints hello world"
```

## References

* https://github.com/gastownhall/gascity/blob/main/docs/getting-started/quickstart.md
* https://github.com/gastownhall/gascity/blob/main/docs/getting-started/coming-from-gastown.md
