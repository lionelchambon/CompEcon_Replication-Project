include("Part_2.jl")

using DataFrames
using DataFramesMeta
using StatFiles
using Statistics
using CSV
using Test
using Plots
using PrettyTables

# First, I merge the pwt data with the author's calculated NRR shares.

df_phi = DataFrame(load("src/data/MSS_NRshares.dta"))
df_pwt = DataFrame(load("src/data/pwt80.dta"))
replace!(df_pwt.country, "Cote d`Ivoire" => "Cote dIvoire")

# Selecting the total phiNR variable:

df_phi_NR = select(df_phi, :country, :year, :phi_NR)

# Merging this onto pwt:

data_fig4 = leftjoin(df_pwt, df_phi_NR, on=[:country, :year])

# Next I restrict to the sample size in the figure. I also assume that we are looking at the previous sample of countires, though
# this is not explicitly mentioned in the paper.

data_fig4 = filter(row -> row.country in benchmark_76 && (1970 <= row.year <= 2005), data_fig4)

CSV.write("src/data/data_fig4.csv", data_fig4)

# Testing that we obtain the correct number of years and countries:

num_countries = length(unique(data_fig4.country))
countries_in_df = unique(data_fig4.country)
unique_years = unique(data_fig4.year)
valid_years = 1970:2005

@test num_countries == 76  # Expected number of unique countries
@test unique_years == valid_years  # Expected unique years (order matters)

# Next, we compute QMKP and VMPK as described in sections II and III of the paper:

data_fig4.QMPK = (1 .- data_fig4.labsh .- data_fig4.phi_NR) .* (data_fig4.rgdpo ./ data_fig4.ck)
data_fig4.VMPK = data_fig4.QMPK .* (data_fig4.pl_gdpo ./ data_fig4.pl_k)

@test "QMPK" in names(data_fig4) 
@test "VMPK" in names(data_fig4)

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

# Finally:

# Panel A

plot_qmpk = plot(
    qmpk_summary.Year, qmpk_summary.Median, label="Median", color=:white, lw=2, legend=false,
    title="Panel A. QMPK", xlabel="Year", ylabel="Quantity MPK", ylim=(0, 0.5), background_color=:black
)

# Add interquartile range (25th–75th) shading
plot!(
    qmpk_summary.Year, qmpk_summary.IQR_25, label="", lw=0, color=:lightblue, alpha=0.5,
    ribbon=(qmpk_summary.IQR_75 .- qmpk_summary.IQR_25)
)

# Add 10th–90th percentile shading
plot!(
    qmpk_summary.Year, qmpk_summary.Percentile_10, label="", lw=0, color=:blue, alpha=0.3,
    ribbon=(qmpk_summary.Percentile_90 .- qmpk_summary.Percentile_10)
)

# Add 5th–95th percentile shading
plot!(
    qmpk_summary.Year, qmpk_summary.Percentile_5, label="", lw=0, color=:darkblue, alpha=0.2,
    ribbon=(qmpk_summary.Percentile_95 .- qmpk_summary.Percentile_5)
)

# Panel B
plot_vmpk = plot(
    vmpk_summary.Year, vmpk_summary.Median, label="Median", color=:white, lw=2, legend=false,
    title="Panel B. VMPK", xlabel="Year", ylabel="Value MPK", ylim=(0, 0.5), background_color=:black
)

# Add interquartile range (25th–75th) shading
plot!(
    vmpk_summary.Year, vmpk_summary.IQR_25, label="", lw=0, color=:lightblue, alpha=0.5,
    ribbon=(vmpk_summary.IQR_75 .- vmpk_summary.IQR_25)
)

# Add 10th–90th percentile shading
plot!(
    vmpk_summary.Year, vmpk_summary.Percentile_10, label="", lw=0, color=:blue, alpha=0.3,
    ribbon=(vmpk_summary.Percentile_90 .- vmpk_summary.Percentile_10)
)

# Add 5th–95th percentile shading
plot!(
    vmpk_summary.Year, vmpk_summary.Percentile_5, label="", lw=0, color=:darkblue, alpha=0.2,
    ribbon=(vmpk_summary.Percentile_95 .- vmpk_summary.Percentile_5)
)

display(plot_qmpk)
display(plot_vmpk)

# Moving on to Table 3 of Section III.

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
    (:log_QMPK :log_PY_div_PK, :Cov_QMPK_PY_div_PK)
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

# Restricting attention to decades like in the paper:

years_of_interest = [1970, 1980, 1990, 2000]
data_tab3 = filter(row -> row.year in years_of_interest, data_tab3)

pretty_table(data_tab3)


