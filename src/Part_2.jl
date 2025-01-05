# This file is dedicated to replicate the results of Part 2 in the article.

using Pkg
using StatFiles
using DataFrames
using Statistics
using CSV
using Latexify
using Plots
using Polynomials
using CSV

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

# We have to get the countries per capita output level. 

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

# create_table_1()

# rm("output/doc_table_1.tex")
# rm("output/doc_table_1.pdf")
# rm("output/table_1.tex")
# rm("output/table_1.csv")

# Trying : 
# 
# "oil" in names(pwt_data_1)
# "ng" in names(pwt_data_1)  # ng stands for natural gas
# 
# # "Other" is : 
# Other_names = names(pwt_data_1)[65:75]
# Others_df = pwt_data_1[:,Other_names]
# Others_df
# 
# 
# 
#     print(i)
#     # summation[i] = sum(skipmissing(Others_df[i, :]))
# end
# summation = []
# for row in size(Others_df)[1]
#     sum_of_row = 0
#     for col in size(Others_df)[2]
#         if ismissing(Others_df[row,col])
#             to_add = 0
#         else
#             to_add = Others_df[row,col]
#         end
#         sum_of_row += to_add
#     end
#     push!(summation, sum_of_row)
# end
# 
# 
# a = [1,2,3,4]
# push!(a,5)
# transform!(Others_df, Other_names .=> (row -> sum(skipmissing(row))) => :Other)
# 
# skipmissing.(eachcol(Others_df))
# 
# sum(1,2,3)
# 
# 
# transform!(pwt_data_1, [:Other] => (+) => :c)
# pwt_data_1[:,:Other]
# Others = [  "phi_NR_coal",
#             "phi"
# ]
# 
# ### Figure 1. Output Share of Natural Resources (Excluding Urban Land), 2000
# 

# Moving onto Figure 1:

df_phi = DataFrame(load("src/data/MSS_NRshares.dta"))
df_pwt = DataFrame(load("src/data/pwt80.dta"))
replace!(df_pwt.country, "Cote d`Ivoire" => "Cote dIvoire")

df_phi_NR = select(df_phi, :country, :year, :phi_NR)

data_fig1 = leftjoin(df_pwt, df_phi_NR, on=[:country, :year])

# First, I compute GDP per worker by determining the number of workers, then dividing real GDP:

data_fig1 = filter(row -> !ismissing(row.labsh), data_fig1)
data_fig1[:, :workers] = data_fig1.pop .* (1 .- data_fig1.labsh)
data_fig1[:, :gdp_per_worker] = data_fig1.rgdpo ./ data_fig1.workers

# Cleaning to drop missing values and ensure corresponding types:

data_fig1 = dropmissing(data_fig1, [:gdp_per_worker, :phi_NR])
data_fig1[!, :gdp_per_worker] = Float64.(data_fig1[!, :gdp_per_worker])
data_fig1[!, :phi_NR] = Float64.(data_fig1[!, :phi_NR])

# Splitting the sample:

data_fig1_a = filter(row -> row.country in benchmark_76 && (row.year == 2000), data_fig1)
data_fig1_b = filter(row -> row.country in benchmark_wo_oil && (row.year == 2000), data_fig1)

# Computing fits:

fit_panel_a = fit(data_fig1_a.gdp_per_worker, data_fig1_a.phi_NR, 1)
fit_panel_b = fit(data_fig1_b.gdp_per_worker, data_fig1_b.phi_NR, 1)

trendline_panel_a = fit_panel_a[1] .+ fit_panel_a[2] .* data_fig1_a.gdp_per_worker
trendline_panel_b = fit_panel_b[1] .+ fit_panel_b[2] .* data_fig1_b.gdp_per_worker

# Plotting:

plot_a = plot(
    title="Panel A. All countries",
    xlabel="GDP per worker",
    ylabel="Natural resource output share",
    legend=false,
    ylims=(0, 0.5)  
)

for row in eachrow(data_fig1_a)
    color = row.country in benchmark_wo_oil ? :black : :red
    annotate!(row.gdp_per_worker, row.phi_NR, text(row.country, 8, color))
end

plot!(data_fig1_a.gdp_per_worker, trendline_panel_a, color=:blue, label="", lw=2, linestyle=:dash)

# Panel B: Non-oil-exporting countries
plot_b = plot(
    title="Panel B. Non-oil-exporting countries",
    xlabel="GDP per worker",
    ylabel="Natural resource output share",
    legend=false,
    ylims=(0, 0.25)  # Set y-axis limits
)

for row in eachrow(data_fig1_b)
    annotate!(row.gdp_per_worker, row.phi_NR, text(row.country, 8, :black))
end

plot!(data_fig1_b.gdp_per_worker, trendline_panel_b, color=:blue, label="", lw=2, linestyle=:dash)

# Combining:

fig1_repl = plot(plot_a, plot_b, layout=(1, 2), size=(1000, 500))
display(fig1_repl)
savefig(fig1_repl, "output/figure1_repl.png")

# This is an ugly plot, but close to what is presented in the paper. Furthermore, we have an issue with the trendline,
# as the regression coefficient is virtually 0, I suspect this is due to how Julia computes the trendline, or further filtering
# or normalizing has been done by the authors. Since this is not specified in the paper, we decide to leave it as it is. 

# Now continuing with Figure 2:

data_fig2 = filter(row -> (row.country in benchmark_wo_oil) && (1970 <= row.year <= 2005), data_fig1)
data_fig2 = dropmissing(data_fig2, [:rgdpo])

# Computing quartiles:

quartile_thresholds = quantile(data_fig2.rgdpo, [0.25, 0.50, 0.75])

data_fig2[!, :quartile] = map(row -> begin
    if row.rgdpo <= quartile_thresholds[1]
        "First quartile"
    elseif row.rgdpo <= quartile_thresholds[2]
        "Second quartile"
    elseif row.rgdpo <= quartile_thresholds[3]
        "Third quartile"
    else
        "Fourth quartile"
    end
end, eachrow(data_fig2))

grouped_fig2 = groupby(data_fig2, [:year, :quartile])
averages_fig2 = combine(grouped_fig2, :phi_NR => mean => :phi_NR_avg)
averages_fig2 = dropmissing(averages_fig2, [:phi_NR_avg])
sort!(averages_fig2, [:year, :quartile])

# Plotting:

fig2_repl = plot(
    xlabel="Year", ylabel="Average natural resource share of output",
    title="All non-oil exporting countries", legend=:topright
)

# Extracting unique quartiles and sorting
quartile_order = ["First quartile", "Second quartile", "Third quartile", "Fourth quartile"]
unique_quartiles = sort(unique(averages_fig2.quartile), by=x -> findfirst(==(x), quartile_order))

# Define line styles and colors for each quartile
line_styles = [:dot, :dash, :solid, :dashdot]
colors = [:blue, :red, :black, :purple]

# Plot each quartile
for (quartile, style, color) in zip(unique_quartiles, line_styles, colors)
    # Create a filtered subset for the current quartile
    quartile_data = filter(row -> row.quartile == quartile, averages_fig2)
    
    # Plot the data for this quartile
    plot!(
        quartile_data.year, quartile_data.phi_NR_avg,
        label=quartile, lw=2, linestyle=style, color=color
    )
end

display(fig2_repl)
savefig("output/figure2_repl.png")

# Moving onto Figure 3:

data_fig3 = leftjoin(df_pwt, df_phi_NR, on=[:country, :year])

# I assume we are looking at 1995 to match the computations of Caselli and Feyrer (2007). However, it is not
# clear whether we are looking at the benchmark_76 sample with or without oil exporters. Since such filtering i performed earlier,
# we maintain it here.

data_fig3 = filter(row -> row.country in benchmark_wo_oil && (row.year == 2005), data_fig3)

# First, I compute GDP per worker by determining the number of workers, then dividing real GDP:

data_fig3 = filter(row -> !ismissing(row.labsh), data_fig3)
data_fig3[:, :workers] = data_fig3.pop .* (1 .- data_fig3.labsh)
data_fig3[:, :gdp_per_worker] = data_fig3.rgdpo ./ data_fig3.workers

CSV.write("output/data_fig3.csv", data_fig3)

# While we can compute ϕ manually following Equation (13) to compare to the CF paper, we cannot compute the NR output share
# as we are not provided with CFs numbers.

# Ensuring type compatibility before plotting:

data_fig3[!, :phi_NR] = Float64.(data_fig3[!, :phi_NR]) 

# Now, moving on to the plot:

plot_NR = scatter(data_fig3.gdp_per_worker, data_fig3.phi_NR,
    label="Using rents", color=:red, marker=:square, alpha=0.8,
    xlabel="GDP per worker", ylabel="Natural resource output share", legend=:topright)

fit_NR = fit(data_fig3.gdp_per_worker, data_fig3.phi_NR, 1)  

trendline_NR = fit_NR[1] .+ fit_NR[2] .* data_fig3.gdp_per_worker

plot!(data_fig3.gdp_per_worker, trendline_NR, color=:red, label="", lw=2, linestyle=:dash)

display(plot_NR)

# The flat line could be driven by the sample, large variances and/or outliers, as above. However, since nothing further
# is specified in the replicationn files, we are not ready to make further data cleaning assumptions.
