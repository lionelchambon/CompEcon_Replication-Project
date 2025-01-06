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

## Data work

## Figures and Tables 

This section focuses on the replication of tables and figures from sections II and III.
Overall, we were unable to precisely replicate the findings of the paper. We suspect
that this is largely driven by the fact that the replication files provided by the authors
only detail how to compute the by-country output share of natural resources
(MSS_Nrshares.dta). However, no code or further information is provided on how to
obtain the tables and figures presented in the paper, which we attempted to replicate
based on our understanding of their methodology. Hence, if the authors made further
asumptions or undertook additional data-cleaning before plotting, this could explain
the discrepancy between our results and theirs.

### Figure 1
We calculate the number of workers as pop*labsh, then we calculate GDP per
worker as cdgdpo divided by this number. The result is close to what is shown in the
paper. However, we encounter issues when using the fit function to compute the
trendline, possibly drive by a lack of variation due to the large values of GDP and the
small values of output shares. The authors do not mention any normalization, so we
choose to not make any further modifications to the data.

### Figure 2
We calculate GDP quartiles using Julia’s quartile function. However, we cannot
replicate the numbers as shown in the paper.

### Figure 3
We can only compute the red elements of this figure as the blue datapoints follow
the methodology followed by Casella and Feyrer (2007). While we can calculate the
natural resource share using Equation (13), the methodology to compute their
estimates of natural resource shares of output is not available in the replication
material. Hence, we restrict ourselves to the estimates provided by the authors and
finnd similar results.

## Figure 4 and Table 3
QMPK and VMPK are computed following the formulae outlines in sections II and III
of the paper. While our estimates are close, we observe minor discrepancies in
percentile ranges. Since we cannot verify our computation of MPKs, if the authors
undertook further data-cleaning or any additional steps not outlined in the paper, this
would explain the divergence in our estimates. They remain, however, reasonably close.

## Tables 4 and 5
It is not possible to reconstruct these tables from the replication files and none of the
datasets provided by the authors include Sachs and Werner’s (1995) openness
indicator. To attempt the replication nonetheless, we used the SW we could find
(available here: [https://www.bristol.ac.uk/depts/Economics/Growth/sachs.htm](https://www.bristol.ac.uk/depts/Economics/Growth/sachs.htm)), which
is called `open.csv` in our output folder. We find that the number of obervations does
not match the ones reported by the authors, so this is likely not the same data they
used. Hence, our results will naturally be different.