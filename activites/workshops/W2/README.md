# Software Factory Intensive - Workshop - W2

https://github.com/actual-software/software-factory-intensive

## Setup

#### Clone Software Factory Intensive

```bash
mkdir -p ~/Projects/actual-software/
pushd -p ~/Projects/actual-software
git clone git@github.com:actual-software/software-factory-intensive.git
```

#### Setup Factory - Workshop - W2

##### Init Factory and Project

```bash
mkdir -p ~/Projects/factory/workshop_w2/w2-project
pushd ~/Projects/factory/workshop_w2/w2-project
git init

mkdir -p ~/Projects/factory/workshop_w2/w2-gc-factory
gc init ~/Projects/factory/workshop_w2/w2-gc-factory
```

##### Configure Factory

```bash
pushd ~/Projects/factory/workshop_w2/w2-gc-factory
cp ~/Projects/actual-software/software-factory-intensive/activites/workshops/W2/gascity/step_0/packs/city.toml ~/Projects/factory/workshop_w2/w2-gc-factory
rsync -av ~/Projects/actual-software/software-factory-intensive/activites/workshops/W2/gascity/step_0/packs/ ~/Projects/factory/workshop_w2/w2-gc-factory/packs/actual/

gc service restart
gc status
gc doctor
```

##### Add "Rig" ie Project Source Repo to Factory

```bash
pushd ~/Projects/factory/workshop_w2/w2-gc-factory
gc rig add ~/Projects/factory/workshop_w2/w2-project
```

##### Register City

```bash
gc register ~/Projects/factory/workshop_w2/w2-gc-factory
```

##### Patch "convoy" in Factory and Project

```bash
pushd ~/Projects/factory/workshop_w2/w2-project && bd config set types.custom "convoy"
pushd ~/Projects/factory/workshop_w2/w2-gc-factory && bd config set types.custom "convoy"
```

##### Restart Factory

```bash
pushd ~/Projects/factory/workshop_w2/w2-gc-factory
gc stop
gc start
gc restart
```

##### Startup Gascity Dashboard

```bash
pushd ~/Projects/factory/workshop_w2/w2-gc-factory
gc dashboard serve
```

Open Gascity Dashboard in Browser

* http://localhost:8080

##### Generate Task to Verify Factory

```bash
gc sling w2-gc-factory "Create a script that prints hello world"
```
