# This file is dedicated to replicate the results of the part 3 of the article.

using Pkg
using DataFrames
using DataFramesMeta
using StatFiles
using Statistics
using CSV
using Plots
using PrettyTables

# We are going to use the array benchmark_76 of the common file.
include("common.jl")

# First, I merge the pwt data with the author's calculated NRR shares.

df_phi = DataFrame(load("src/data/MSS_NRshares.dta"))
df_pwt = DataFrame(load("src/data/pwt80.dta"))
replace!(df_pwt.country, "Cote d`Ivoire" => "Cote dIvoire")

# Selecting the total phiNR variable:

df_phi_NR = select(df_phi, :country, :year, :phi_NR)

# Merging this onto pwt:

data_fig4 = leftjoin(df_pwt, df_phi_NR, on=[:country, :year])

# Next I restrict to the sample size in the figure.
# I also assume that we are looking at the previous sample of countires, though
# this is not explicitly mentioned in the paper.

data_fig4 = filter(row -> row.country in benchmark_76 && (1970 <= row.year <= 2005), data_fig4)

CSV.write("output/data_fig4.csv", data_fig4)

# Testing that we obtain the correct number of years and countries:

# num_countries = length(unique(data_fig4.country))
# unique_years = length(unique(data_fig4.year))

if num_countries !== 76
    @error("The expected number of unique countries is 76.")
end
if  unique_years !== 36
    @error("Expected unique years (order matters) is wrong.")
end

# Next, we compute QMKP and VMPK as described in sections II and III of the paper:

data_fig4.QMPK = (1 .- data_fig4.labsh .- data_fig4.phi_NR) .* (data_fig4.rgdpo ./ data_fig4.ck)
data_fig4.VMPK = data_fig4.QMPK .* (data_fig4.pl_gdpo ./ data_fig4.pl_k)

# We briefly test that the comuputed MPK variables are indeed present in the dataset:

columns_to_check = ["QMPK", "VMPK"]
for col in columns_to_check
    if col ∉ names(data_fig4)
        @error("Column $col is missing in data_fig4.")
    end
end

# We can now proceed to plotting.

# First, we need to calculate the percentiles and ranges as displayed in Figure 4:

function summarize(df, column)
    grouped = groupby(df, :year)
    years = unique(df.year)
    
    # Initialize vectors to store the results
    medians = Float64[]
    iqr_25 = Float64[]
    iqr_75 = Float64[]
    pct_10 = Float64[]
    pct_90 = Float64[]
    pct_5 = Float64[]
    pct_95 = Float64[]

    # Looping
    for group in grouped
        data = group[!, column]  # Extract the relevant column
        
        push!(medians, median(data))
        push!(iqr_25, quantile(data, 0.25))
        push!(iqr_75, quantile(data, 0.75))
        push!(pct_10, quantile(data, 0.1))
        push!(pct_90, quantile(data, 0.9))
        push!(pct_5, quantile(data, 0.05))
        push!(pct_95, quantile(data, 0.95))
    end

    # Create the resulting DataFrame
    return DataFrame(
        Year = years,
        Median = medians,
        IQR_25 = iqr_25,
        IQR_75 = iqr_75,
        Percentile_10 = pct_10,
        Percentile_90 = pct_90,
        Percentile_5 = pct_5,
        Percentile_95 = pct_95
    )
end

# Summarize QMPK and VMPK
qmpk_summary = summarize(data_fig4, :QMPK)
vmpk_summary = summarize(data_fig4, :VMPK)

# Finally, we can proceed to plotting:

function plot_fig4(data, variable, title, ylabel; ylim_range=(0, 0.5), background_color=:white)
    # Define shading levels like in the paper
    shading_levels = [
        (:IQR_25, :IQR_75, :darkblue, 0.5),
        (:Percentile_10, :Percentile_90, :blue, 0.3),
        (:Percentile_5, :Percentile_95, :lightblue, 0.2)
    ]

    # Plot the largest percentile range as the base
    plot_obj = plot(
        data.Year, data[!, :Percentile_5],
        ribbon=(data[!, :Percentile_95] .- data[!, :Percentile_5]),
        label="", lw=0, color=:lightblue, alpha=0.5,
        title=title, xlabel="Year", ylabel=ylabel,
        ylim=ylim_range, background_color=background_color
    )

    # Add the remaining layers
    for (lower, upper, color, alpha) in shading_levels[1:2]
        plot!(
            plot_obj,
            data.Year, data[!, lower],
            ribbon=(data[!, upper] .- data[!, lower]),
            label="", lw=0, color=color, alpha=alpha
        )
    end

    # Add the median line
    plot!(
        plot_obj,
        data.Year, data[!, :Median],
        label="", color=:white, lw=2
    )

    # Return the plot object
    return plot_obj
end


plot_qmpk = plot_fig4(qmpk_summary, :QMPK, "Panel A. QMPK", "Quantity MPK", ylim_range=(0, 0.5),background_color=:white)
plot_vmpk = plot_fig4(vmpk_summary, :VMPK, "Panel B. VMPK", "Value MPK", ylim_range=(0, 0.5),background_color=:white)

display(plot_qmpk)
display(plot_vmpk)

fig4_repl = plot(plot_qmpk,
                    plot_vmpk,
                    layout=(1, 2),
                    size=(1000, 450),
                    subtitle="Figure 4: Global Evolution of MPKs") # Plot is cut off, fix later
savefig(fig4_repl, "output/fig4_repl.png")

### Table 3 :

# Computing logs
data_fig4[:, :log_QMPK] = log.(data_fig4.QMPK)
data_fig4[:, :log_VMPK] = log.(data_fig4.VMPK)
data_fig4[:, :log_phi] = log.(1 .- data_fig4.labsh .- data_fig4.phi_NR)
data_fig4[:, :log_Y_div_K] = log.(data_fig4.rgdpo ./ data_fig4.ck)
data_fig4[:, :log_PY_div_PK] = log.(data_fig4.pl_gdpo ./ data_fig4.pl_k)

grouped = groupby(data_fig4, :year)

covariances = DataFrame(year=unique(data_fig4.year))

# List of covariance pairs
cov_pairs = [
    (:log_phi, :log_Y_div_K, :Cov_phi_Y_div_K),
    (:log_Y_div_K, :log_PY_div_PK, :Cov_Y_div_K_PY_div_PK),
    (:log_phi, :log_PY_div_PK, :Cov_phi_PY_div_PK),
    (:log_QMPK, :log_PY_div_PK, :Cov_QMPK_PY_div_PK)
]

# Computing variances
variances = combine(grouped, 
    :log_QMPK => var => :Var_QMPK,
    :log_VMPK => var => :Var_VMPK,
    :log_phi => var => :Var_phi,
    :log_Y_div_K => var => :Var_Y_div_K,
    :log_PY_div_PK => var => :Var_PY_div_PK
)

# Computing covariances

for (var1, var2, name) in cov_pairs
    values = Float64[]
    for group in grouped
        x = group[!, var1]
        y = group[!, var2]
        push!(values, cov(x, y))
    end
    covariances[:, name] = values
end

# Merge variances and covariances
data_tab3 = leftjoin(variances, covariances, on=:year)

# I check whether our computed results match the manual computation using the variance formulae provided
# in the paper. This is to test that there are no larger computational discrepancies or errors in our data.

manual_varQMPK = var(data_fig4[!, :log_phi]) +
                 var(data_fig4[!, :log_Y_div_K]) +
                 2 * cov(data_fig4[!, :log_phi], data_fig4[!, :log_Y_div_K])

manual_varVMPK = var(data_fig4[!, :log_QMPK]) +
                 var(data_fig4[!, :log_PY_div_PK]) + 
                 2 * cov(data_fig4[!, :log_QMPK], data_fig4[!, :log_PY_div_PK]) 

computed_varQMPK = var(data_fig4[!, :log_QMPK])
computed_varVMPK = var(data_fig4[!, :log_VMPK])

if isapprox(computed_varQMPK, manual_varQMPK; atol=1e-7)
    println("VarQMPK matches the manual computation!")
else
    println("Error: VarQMPK does not match the manual computation.")
    println("Computed VarQMPK: $computed_varQMPK")
    println("Manual VarQMPK: $manual_varQMPK")
end

if isapprox(computed_varVMPK, manual_varVMPK; atol=1e-7)
    println("VarVMPK matches the manual computation!")
else
    println("Error: VarVMPK does not match the manual computation.")
    println("Computed VarVMPK: $computed_varVMPK")
    println("Manual VarVMPK: $manual_varVMPK")
end

# Back to building Table 3.
# Restricting attention to decades like in the paper:

years_of_interest = [1970, 1980, 1990, 2000]
data_tab3 = filter(row -> row.year in years_of_interest, data_tab3)

pretty_table(data_tab3) # Can we find a way to export this into the output folder?

### Table 4 & 5

# Now, we move on to the final tables of this section. To do so, we need data on the Sachs & Warner indicator as cited in the 
# paper. However, this is not available in the replication package, so I use a .csv file from: https://www.bristol.ac.uk/depts/Economics/Growth/sachs.htm

sw_indicator = CSV.read("src/data/open.csv", DataFrame)

# Standardizing variable names:
 
rename!(sw_indicator, Dict(:OPEN => :open))
rename!(sw_indicator, Dict(:YEAR => :year))
rename!(sw_indicator, Dict(:COUNTRY => :country))
sw_indicator.country = lowercase.(sw_indicator.country)
data_fig4.country = lowercase.(data_fig4.country)  

# Performing the join as before: 

df_open = select(sw_indicator, :country, :year, :open)
data_tab4and5 = leftjoin(data_fig4, df_open, on=[:country, :year])

# Finally:

CSV.write("output/data_tab4and5.csv", data_tab4and5)

# Checking:

num_countries_bis = length(unique(data_tab4and5.country))
unique_years_bis = length(unique(data_tab4and5.year))

if num_countries_bis !== 76
    @error("The expected number of unique countries is 76.")
end
if  unique_years_bis !== 36
    @error("Expected unique years (order matters) is wrong.")
end

# Now, we can build Tables 4 and 5. I cannot be sure whether the indicator data I added is identical to the data used by
# the authors, but I first proceed by filtering mising values and coding the open variable as a binary one:

data_tab4and5 = filter(row -> !ismissing(row.open) && row.open in [0.00, 1.00], data_tab4and5)


data_tab4and5.open .= Int.(data_tab4and5.open .== 1.0)

# Next, computing relevant output:

 # First, creating bins like in the paper

 function create_year_bins(year)
    if year >= 1970 && year <= 1975
        return "1970–1975"
    elseif year >= 1976 && year <= 1980
        return "1976–1980"
    elseif year >= 1981 && year <= 1985
        return "1981–1985"
    elseif year >= 1986 && year <= 1990
        return "1986–1990"
    elseif year >= 1991 && year <= 1995
        return "1991–1995"
    elseif year >= 1996 && year <= 2000
        return "1996–2000"
    else
        return "Outside Range"
    end
end

data_tab4and5.year_bin = map(create_year_bins, data_tab4and5.year)
# Grouped by SW indicator
grouped_tab4 = groupby(data_tab4and5, [:year_bin, :open]) 

stats_tab4 = combine(grouped_tab4, 
    :QMPK => mean => :QMPK_mean,
    :VMPK => mean => :VMPK_mean,
    :QMPK => std => :QMPK_std,
    :VMPK => std => :VMPK_std,
    :QMPK => length => :count
)

stats_tab4_open = filter(row -> row.open == 1, stats_tab4)
stats_tab4_closed = filter(row -> row.open == 0, stats_tab4)

tab4 = innerjoin(stats_tab4_open, stats_tab4_closed, on=:year_bin, makeunique=true)

# WWriting a function to compute t-stats:

function compute_t_stat(mean1, mean2, n1, n2, std1, std2)
    return (mean1 - mean2) / sqrt((std1^2 / n1) + (std2^2 / n2))
end

tab4.QMPK_t_stat = map(row -> compute_t_stat(
    row.QMPK_mean, row.QMPK_mean_1,
    row.count, row.count_1,
    row.QMPK_std, row.QMPK_std_1
), eachrow(tab4))

tab4.VMPK_t_stat = map(row -> compute_t_stat(
    row.VMPK_mean, row.VMPK_mean_1,
    row.count, row.count_1,
    row.VMPK_std, row.VMPK_std_1
), eachrow(tab4))

select!(tab4, Not([:open, :open_1, :QMPK_std, :QMPK_std_1, :VMPK_std, :VMPK_std_1]))

# Renaming columns for clarity:

rename!(tab4, Dict(
    :QMPK_mean => :QMPK_open,
    :VMPK_mean => :VMPK_open,
    :count => :Obervations_open,
    :QMPK_mean_1 => :QMPK_closed,
    :VMPK_mean_1 => :VMPK_closed,
    :count_1 => :Observations_closed
))

# Reordering columns like in the paper:

desired_order = [:QMPK_open, :QMPK_closed, :QMPK_t_stat, :VMPK_open, :VMPK_closed, :VMPK_t_stat, :Obervations_open, :Observations_closed]

# Reorder columns
tab4_repl = select(tab4, desired_order...)

println(tab4_repl)
CSV.write("output/table4_repl.csv", tab4_repl)

# For the last table of Section III, we repeat the exercise for factor shares, output-to-capital ratios, and relative prices:

# First, adding variables of interest:

data_tab5 = data_tab4and5  
data_tab5[:, :phi] = 1 .- data_tab5.labsh .- data_tab5.phi_NR  
data_tab5[:, :Y_div_K] = data_tab5.rgdpo ./ data_tab5.ck       
data_tab5[:, :P_Y_div_P_K] = data_tab5.pl_gdpo ./ data_tab5.pl_k  

grouped_tab5 = groupby(data_tab5, [:year_bin, :open])

stats_tab5 = combine(grouped_tab5,
    :phi => mean => :phi_mean,
    :phi => std => :phi_std,
    :Y_div_K => mean => :Y_div_K_mean,
    :Y_div_K => std => :Y_div_K_std,
    :P_Y_div_P_K => mean => :P_Y_div_P_K_mean,
    :P_Y_div_P_K => std => :P_Y_div_P_K_std,
    :phi => length => :count
)


stats_tab5_open = filter(row -> row.open == 1, stats_tab5)
stats_tab5_closed = filter(row -> row.open == 0, stats_tab5)

tab5 = innerjoin(stats_tab5_open, stats_tab5_closed, on=[:year_bin], makeunique=true)

# Next, adding t-stats:

tab5.phi_t_stat = map(row -> compute_t_stat(
    row.phi_mean, row.phi_mean_1,
    row.count, row.count_1,
    row.phi_std, row.phi_std_1
), eachrow(tab5))

tab5.Y_div_K_t_stat = map(row -> compute_t_stat(
    row.Y_div_K_mean, row.Y_div_K_mean_1,
    row.count, row.count_1,
    row.Y_div_K_std, row.Y_div_K_std_1
), eachrow(tab5))

tab5.P_Y_div_P_K_t_stat = map(row -> compute_t_stat(
    row.P_Y_div_P_K_mean, row.P_Y_div_P_K_mean_1,
    row.count, row.count_1,
    row.P_Y_div_P_K_std, row.P_Y_div_P_K_std_1
), eachrow(tab5))

# Finally, puttting everything together:

tab5_repl = DataFrame(
    Year = tab5.year_bin,
    phi_Open = tab5.phi_mean,
    phi_Closed = tab5.phi_mean_1,
    phi_t_stat = tab5.phi_t_stat,
    Y_div_K_Open = tab5.Y_div_K_mean,
    Y_div_K_Closed = tab5.Y_div_K_mean_1,
    Y_div_K_t_stat = tab5.Y_div_K_t_stat,
    P_Y_div_P_K_Open = tab5.P_Y_div_P_K_mean,
    P_Y_div_P_K_Closed = tab5.P_Y_div_P_K_mean_1,
    P_Y_div_P_K_t_stat = tab5.P_Y_div_P_K_t_stat
)

rename!(tab5_repl, Dict(
    :phi_Open => "φ (Open)", :phi_Closed => "φ (Closed)", :phi_t_stat => "φ t-stat",
    :Y_div_K_Open => "Y/K (Open)", :Y_div_K_Closed => "Y/K (Closed)", :Y_div_K_t_stat => "Y/K t-stat",
    :P_Y_div_P_K_Open => "P_Y/P_K (Open)", :P_Y_div_P_K_Closed => "P_Y/P_K (Closed)", :P_Y_div_P_K_t_stat => "P_Y/P_K t-stat"
))

println(tab5_repl)
CSV.write("output/table5_repl.csv", tab5_repl)

