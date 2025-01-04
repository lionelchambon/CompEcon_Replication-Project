# This file is dedicated to replicate the results of Part 2 in the article.

using StatFiles
using DataFrames
using Statistics
using CSV
using Latexify

# In the common.jl file, we take the sample of 76 and 79 countries used in the article and 
# detailed in the appendix. 
include("common.jl")

### Table 1—Output Share of Natural Resources (Percent, 2000 )

# We first load the data : 
data = DataFrame(load("src/data/MSS_NRshares.dta"))
# summary(data)

# Then, we only select data from year 2000 :
data_2000 = DataFrame(data[data.year .== 2000, :])

# To filter the data to only get those 76 countries, we build the "isin" function : 
function isin(A,B)
    tmp = Vector{Bool}()
    result = Vector{Bool}()
    for a in A
        if in(a,B)
            tmp = true
        else
            tmp = false
        end
        append!(result, tmp)
    end
    return result
end

sample_76 = isin(data_2000[:,"country"], benchmark_76)
sample_79 = isin(data_2000[:,"country"], benchmark_79)

data_76 = data_2000[sample_76,:]
data_79 = data_2000[sample_79,:]

# Testing that we have all the selected countries for the samples of 76 and 79 countries : 
if sum(isin(benchmark_76,data_2000[:,"country"])) !== 76
    @error("Error in the creation of the sample of 76 countries.")
end
if sum(isin(benchmark_79,data_2000[:,"country"])) !== 79
    @error("Error in the creation of the sample of 79 countries.")
end

# Then, we compute the statistics of each variable for the sample of 79 countries : 

# means : 
mean_NR             = 100*mean(skipmissing(data_79[:, "phi_NR"]))
mean_timber         = 100*mean(skipmissing(data_79[:, "phi_NR_timber"]))
mean_subsoil        = 100*mean(skipmissing(data_79[:, "phi_NR_subsoil"]))
mean_oil            = NaN # Missing
mean_gas            = NaN # Missing
mean_other          = NaN # Missing
mean_cropland       = 100*mean(skipmissing(data_79[:, "phi_NR_crop_pq_a"])) # This should be 2.26
mean_pastureland    = 100*mean(skipmissing(data_79[:, "phi_NR_pasture"]))
mean_nrul           = 0 # 100*mean(skipmissing(data_79[:, ""])) # Missing.

means = [   mean_NR,
            mean_timber,
            mean_subsoil,
            mean_oil, # Missing
            mean_gas, # Missing
            mean_other, # Missing
            mean_cropland,
            mean_pastureland, 
            mean_nrul]

# medians : 

median_NR             = 100*median(skipmissing(data_79[:, "phi_NR"]))
median_timber         = 100*median(skipmissing(data_79[:, "phi_NR_timber"]))
median_subsoil        = 100*median(skipmissing(data_79[:, "phi_NR_subsoil"]))
median_oil            = NaN # Missing
median_gas            = NaN # Missing
median_other          = NaN # Missing
median_cropland       = 100*median(skipmissing(data_79[:, "phi_NR_crop_pq_a"]))
median_pastureland    = 100*median(skipmissing(data_79[:, "phi_NR_pasture"]))
median_nrul           = NaN # Missing

medians = [ median_NR,
            median_timber,
            median_subsoil,
            median_oil, # Missing
            median_gas, # Missing
            median_other, # Missing
            median_cropland,
            median_pastureland,
            median_nrul # Missing
            ]

# Coefficient of variation : 

# The coefficient of variation is defined as the ratio between the standard deviation over the mean.

CV_NR             = 100*std(skipmissing(data_79[:, "phi_NR"]))/mean_NR
CV_timber         = 100*std(skipmissing(data_79[:, "phi_NR_timber"]))/mean_timber
CV_subsoil        = 100*std(skipmissing(data_79[:, "phi_NR_subsoil"]))/mean_subsoil
CV_oil            = NaN # Missing
CV_gas            = NaN # Missing
CV_other          = NaN # Missing
CV_cropland       = 100*std(skipmissing(data_79[:, "phi_NR_crop_pq_a"]))/2.26 # This is false ?
CV_pastureland    = 100*std(skipmissing(data_79[:, "phi_NR_pasture"]))/mean_pastureland
CV_nrul           = NaN # Missing

CVs = [ CV_NR,
        CV_timber,
        CV_subsoil,
        CV_oil, # Missing
        CV_gas, # Missing
        CV_other, # Missing
        CV_cropland,
        CV_pastureland, 
        CV_nrul]

# The last column is 
# the correlation between the variable and the countries’ per capita output levels

# We have to get the countries per capita outout level. 

Corr = repeat([NaN], 9) # We do not have the per capita output yet.

# The observations : 

if size(data_79)[1] !== 79
    @error("Error in the data frame dimensions.")
else 
    Observationsrow = ["Observations",79,79,79,79]
end

# Creating a Data Frame to get the Table 1 : 

Names = [   "Natural Resources",
            "Timber",
            "Subsoil",
            "Oil",
            "Gas",
            "Other",
            "Crop Land",
            "Pasture Land", 
            "Natural Resources with Urban Land"]

Table_1 = DataFrame(
    "Variable" => Names,
    "Mean" => means,
    "Median" => medians, 
    "Coefficient of Variation" => CVs,
    "Correlation with per capita output" => Corr
)

push!(Table_1, Observationsrow)

# Then, we should save this Table 1 in the 'output' folder. 

CSV.write("output/table_1.csv", Table_1)

"""
The function `create_table_1()` generates a pdf containing the results 
we got trying to replicate table 1 of the authors.

The pdf `doc_table_1.pdf` is generated in the folder `output`.
"""
function create_table_1()
    # Create the latex code and save it : 
    Table_1_tex = latexify(Table_1; env = :table, booktabs = true, latex = false)
    write("output/table_1.tex", Table_1_tex)

    # Wrap the latex code in a template :
    beginning = "\\documentclass{article} \n \\usepackage{amssymb,amsmath}
    \\usepackage{booktabs} \n \\usepackage{pdflscape}
    \\begin{document} \n \\begin{landscape}
    \\centering"
    ending = "\\end{landscape} \n \\end{document}"
    write("output/doc_table_1.tex",beginning)
    io = open("output/doc_table_1.tex", "a")
    write(io,"\n", Table_1_tex)
    write(io, ending)
    close(io)
    # rm("output/doc_table_1.tex")   

    # Compile the latex code :
    Base.run(pipeline(`pwd`,`cd output/`,`pdflatex --interaction=batchmode output/doc_table_1.tex`));
    Base.run(`mv doc_table_1.pdf output/doc_table_1.pdf`);
    Base.run(`rm doc_table_1.aux doc_table_1.log`);
end

create_table_1()

rm("output/doc_table_1.tex")
rm("output/doc_table_1.pdf")
rm("output/table_1.tex")
rm("output/table_1.csv")

### Figure 1. Output Share of Natural Resources (Excluding Urban Land), 2000
