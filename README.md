# Replication_Monge_et_al_2019

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://Paulogcd.github.io/Replication_Monge_et_al_2019.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://Paulogcd.github.io/Replication_Monge_et_al_2019.jl/dev/)
[![Build Status](https://github.com/Paulogcd/Replication_Monge_et_al_2019.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Paulogcd/Replication_Monge_et_al_2019.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/Paulogcd/Replication_Monge_et_al_2019.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Paulogcd/Replication_Monge_et_al_2019.jl)


This repository is dedicated to the replication of the article _Natural Resources and Global Misallocation_ by Monge et al, 2019, in Julia. 

We are COMPÉRAT Étienne, CHAMBON Lionel, and GUGELMO CAVALHEIRO DIAS Paulo, and this replication package is done for the *Computational Economics* Class, taught by Florian Oswald during the Fall 2024 semester in the Sciences Po Master of Research in Economics. 

You can go to its dedicated webpage [here](https://www.paulogcd.com/Replication_Monge_et_al_2019.jl/) to have a better overview of the package. 

# Starting the package :

```
using Pkg
Pkg.activate(".")
using Replicaion_Monge_et_al_2019.jl # The precompilation might ake some time (24 seconds on Mac M1)

# to get all the results inside a 'output' folder : 
run()

# to delete all the output : 
delete_all()
```