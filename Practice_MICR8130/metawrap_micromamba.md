#### 🧬 Installing MetaWRAP Properly on HPC (Python 3 + Micromamba Strategy)

🚨 Problem

metawrap-mg is outdated.

Standard conda install caused:

● SSL certificate errors

● Dependency conflicts

● Broken PATH issues

● Missing config files

● Python 2/3 incompatibility

● Module conflicts on cluster

**We needed a clean, stable, class-friendly solution.**

#### 🔧 Strategy We Used

Step 1 — Avoid Old Conda

We purged all modules:

```bash
module purge
module load anaconda3/2023.09-0
module load perl
```

**Why?**
Older Anaconda had broken SSL and outdated CA certificates.

#### Step 2 — Install Micromamba Locally (Inside Class Folder)

Instead of relying on cluster conda, we installed micromamba inside:

```bash
/project/.../tools/
```

```bash
BASE=/project/bcampb7/camplab/MICRO_8130_2026/metagenome_jojy/tools
mkdir -p $BASE/bin $BASE/conda_envs

# Download micromamba binary
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj -C $BASE/bin --strip-components=1 bin/micromamba

# Test
$BASE/bin/micromamba --version

export MAMBA_ROOT_PREFIX=$BASE/conda_envs
eval "$($BASE/bin/micromamba shell hook -s bash)"

micromamba --version
micromamba info
```

This gave us:

● Local control

● No system conflicts

● No SSL errors

● No base environment interference

#### Step 3 — Create Clean Python 3 Environment

Then installed dependencies manually.

```bash
micromamba create -p $BASE/conda_envs/metawrap_py3 python=3.9
```

#### Step 4 — MetaWRAP Package Problem

Even though:

```bash
micromamba install metawrap
```

showed “installed”, the metawrap command was missing.

**Why?**

The Bioconda package:

● Does NOT ship the main script correctly

● Does NOT include config-metawrap

● Is partially broken

#### Step 5 — Solution: Clone GitHub Version

```bash
git clone https://github.com/bxlab/metaWRAP.git
```

This gives full folder structure:

metaWRAP/
├── bin/
├── metawrap-modules/
├── metawrap-scripts/

#### Step 6 — Fix Config

MetaWRAP expects:

config-metawrap
We created one manually pointing to:

```bash
export PIPES=.../bin/metawrap-modules
export SOFT=.../bin/metawrap-scripts
```

This fixed:
cannot find config-metawrap file
binning.sh: No such file or directory

#### Step 7 — Final Working Run

We do NOT activate environment manually.
We use:

```bash
micromamba run -p ENV_PATH METAWRAP_SCRIPT module
```

Or better — a wrapper script.

#### 🚧 Errors (And Fixes)

| Error                         | Cause                      | Fix                           |
| ----------------------------- | -------------------------- | ----------------------------- |
| SSL CA cert error             | Old Anaconda module        | Loaded new 2023 module        |
| `metawrap: command not found` | Broken bioconda package    | Cloned GitHub version         |
| `cannot find config-metawrap` | Missing config file        | Created custom config         |
| `binning.sh not found`        | Wrong PIPES path           | Corrected to metawrap-modules |
| Mixed conda environments      | Nested activation          | Used micromamba run           |
| PATH conflicts                | Multiple anaconda versions | module purge first            |

#### 🧬 Final Working Architecture

tools/
├── micromamba
├── conda_envs/
│ └── metawrap_py3/
├── src/
│ └── metaWRAP/ (GitHub clone)
└── run_metawrap.sh

**Students only run:**
run_metawrap.sh binning ... follow from metagenome_practical_full_version_jojy.md
