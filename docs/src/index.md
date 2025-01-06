# Replication package of Monge et al 2019

This is the documentation for [Replication\_Monge\_et\_al\_2019](https://github.com/Paulogcd/Replication_Monge_et_al_2019.jl).

This package allows to replicate the results in Monge et al, 2019. 

## Installation 

To install the package, you can enter the pkg mode in Julia by pressing `]`, or you can directly enter : 

```
julia> using Pkg
julia> Pkg.add("https://www.github.com/Paulogcd/Replication_Monge_et_al_2019")
```

To visualise the replicated results, you can first activate the environment, and then use the `run()` function :

```
julia> Pkg.activate(".")
julia> using Replication_Monge_et_al_2019
```

# Two main functions : 

The two main functions of the package are : 

```
# Will produce all the replicated results in an output folder : 

julia> run()

# Will delete all the produced results. 
# The function throws an error if any output file is missing.

julia> delete_all()
```

# Comments on replication results : 
