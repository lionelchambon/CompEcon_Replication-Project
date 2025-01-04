# This file is dedicated to replicate the results of the part 3 of the article.

using DataFrames
using DataFramesMeta
using StatFiles
using Statistics
using CSV

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

num_countries = length(unique(data_fig4.country))
countries_in_df = unique(data_fig4.country)
unique_years = unique(data_fig4.year)
valid_years = 1970:2005

if num_countries !== 76
    @error("The expected number of unique countries is 76.")
end
if  unique_years !== valid_years 
    @error("Expected unique years (order matters) is wrong.")
end

# The test, there is a country missing.

# No sure about the following two lines : 
# missing_countries = setdiff(benchmark_76, countries_in_df)
# println("Missing countries: $missing_countries")

