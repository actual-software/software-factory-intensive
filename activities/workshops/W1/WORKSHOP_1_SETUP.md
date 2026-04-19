# Software Factory Intensive - Workshop - W1

https://github.com/actual-software/software-factory-intensive

## Setup

#### Clone Software Factory Intensive

```bash
mkdir -p ~/Projects/actual-software/
pushd -p ~/Projects/actual-software
git clone git@github.com:actual-software/software-factory-intensive.git
```

#### Setup Factory - Workshop - W1

##### Init Factory and Project

```bash
mkdir -p ~/Projects/factory/workshop_w1/w1-project
pushd ~/Projects/factory/workshop_w1/w1-project
git init

gc init ~/Projects/factory/workshop_w1/w1-gc-factory
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
pushd ~/Projects/factory/workshop_w1/w1-gc-factory
cp ~/Projects/actual-software/software-factory-intensive/activities/workshops/W1/gascity/step_0/packs/city.toml ~/Projects/factory/workshop_w1/w1-gc-factory
rsync -av ~/Projects/actual-software/software-factory-intensive/activities/workshops/W1/gascity/step_0/packs/ ~/Projects/factory/workshop_w1/w1-gc-factory/packs/actual/
```

##### Register City

```bash
gc stop
gc register <full_path>/Projects/factory/workshop_w1/w1-gc-factory

gc service restart
gc status
gc doctor --fix
```

##### Add "Rig" ie Project Source Repo to Factory

```bash
pushd ~/Projects/factory/workshop_w1/w1-gc-factory
gc rig add <full_path>/Projects/factory/workshop_w1/w1-project
```

Update city.toml with the includes as in this example:

```bash
[[rigs]]
name = "w1-project"
path = "<full_path/Projects/factory/workshop_w1/w1-project"
includes = ["packs/actual/all"]
```

##### Patch "convoy" in Factory and Project

```bash
pushd ~/Projects/factory/workshop_w1/w1-gc-factory && bd config set types.custom "convoy"
pushd ~/Projects/factory/workshop_w1/w1-project && bd config set types.custom "convoy"
```

##### Restart Factory

```bash
pushd ~/Projects/factory/workshop_w1/w1-gc-factory
gc stop
gc start
gc restart
```

##### Startup Gascity Dashboard

```bash
pushd ~/Projects/factory/workshop_w1/w1-gc-factory
gc dashboard serve
```

Open Gascity Dashboard in Browser

* http://localhost:8080

##### Generate Task to Verify Factory

```bash
pushd ~/Projects/factory/workshop_w1/w1-project
gc sling w1-project/architect "Create a script that prints hello world"
```
