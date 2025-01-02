# This file is dedicated to the replication of the data of the article. 
# It uses data provided by the authors of the article, stored in the "data" folder. 


# This file is an attempt to reproduce the "build_phiNR.do" file provided in the replication package of the authors in Julia.

# Note of the article's authors : 

    # This do file constructs natural resource shares (phi_NR) as in MSS by calling data from the
    # WB and PWT. As an output it will save a dataset that has phi_NR for multiple countries between 
    # 1970 and 2005. User must set the directory before use. 
    # This do file calls the following dta files:
    #   1) PWT8
    #   2) timber_and_subsoil_rent_input.dta
    #   3) crop_land_rent_input.dta
    #   4) pasture_land_rent_input.dta

using DataFrames
using StatFiles
using Missings
using CSV

# Load the dataset of the Penn World Tables (pwt) :
pwt_data = DataFrame(load("src/data/pwt80.dta"))


# We first work with pl_gdpe and pl_gdpo.
# pl_gdpe is the price level of CGDPe (Expenditure-side real GDP at current PPPs (in mil. 2005US$)) (PPP/XR), price level of USA GDP_e in 2005 = 1
# pl_gdpo is the price level of CGDPo (Output-side real GDP at current PPPs (in mil. 2005US$)) (PPP/XR), price level of USA GDP_o in 2005 = 1

# We want to replace negative values with 'missing' : 
pwt_data[!, :pl_gdpe] .= passmissing(x -> ifelse(x < 0, missing, x)).(pwt_data[!, :pl_gdpe]) # No country
pwt_data[!, :pl_gdpo] .= passmissing(x -> ifelse(x < 0, missing, x)).(pwt_data[!, :pl_gdpo]) # This happens in Bermuda

# ifelse does not support handling missing values directly because it expect to evaluate a Bool.
# To fix this, we have used passmissing which skips computations for missing values and directly propagates them in the result.

# Checking:
count(ismissing, pwt_data[!, :pl_gdpe]) #2080
count(ismissing, pwt_data[!, :pl_gdpo]) #2086 
# These numbers match those from the do file.


# Generate pl_gdpo_old
usa_data = filter(row -> row[:countrycode] == "USA", pwt_data) # Filter rows where countrycode is "USA"
usa_nom_p = combine(groupby(filter(row -> row[:countrycode] == "USA", pwt_data), :year), 
                    :pl_gdpo => maximum => :nom_p) # Group by year and calculate the max value for pl_gdpo
pwt_data = leftjoin(pwt_data, usa_nom_p, on=:year) # Merge the results back into the original dataset
pwt_data = groupby(pwt_data, :year) # Group by year
pwt_data = transform(pwt_data, :nom_p => maximum => :nom_pp) #This line seems redundant but we prefer following the structure of the .do file
pwt_data[!, :pl_gdpo_old] .= pwt_data.pl_gdpo ./ pwt_data.nom_pp 
#Checking
sort!(pwt_data, [:year])
first(select(pwt_data, [:countrycode, :year, :pl_gdpo_old]), 10) # The numbers for pl_gdpo_old match.

# Generate pl_gdpe_old
select!(pwt_data, Not([:nom_p, :nom_pp])) # Drop nom_p and nom_pp
# Filter for USA and compute max(pl_gdpe) by year
usa_nom_p = combine(groupby(filter(row -> row[:countrycode] == "USA", pwt_data), :year), 
                    :pl_gdpe => maximum => :nom_p)
pwt_data = leftjoin(pwt_data, usa_nom_p, on=:year)
pwt_data = groupby(pwt_data, :year)
pwt_data = transform(pwt_data, :nom_p => maximum => :nom_pp)
pwt_data[!, :pl_gdpe_old] .= pwt_data.pl_gdpe ./ pwt_data.nom_pp
# Checking
first(select(pwt_data, [:countrycode, :year, :pl_gdpe_old]), 10) # The numbers match.


# Remark 1.
# We multiply nominal GDP by 1,000,000 to transform GDP 
#   in the same units as rents from natural resources (from "natural_rents.dta")
# Create new columns for nominal_gdpe and nominal_gdpo
pwt_data[!, :nominal_gdpe] .= pwt_data.cgdpe .* 1_000_000 .* pwt_data.pl_gdpe_old
pwt_data[!, :nominal_gdpo] .= pwt_data.cgdpo .* 1_000_000 .* pwt_data.pl_gdpo_old

# Create a new column nominal_gdp based on nominal_gdpo
pwt_data[!, :nominal_gdp] .= pwt_data.nominal_gdpo

# Define scalar variables for sample years
minyear = 1970
maxyear = 2010

# We need to do this replacement here regarding the name of Cote d'Ivoire 
#   because of the d`Ivorie in the original PWT
pwt_data[!, :country] .= replace.(pwt_data.country, "Cote d`Ivoire" => "Cote dIvoire")





###############################################
# (1) Merge with timber_and_subsoil_rents.dta #
###############################################

sort!(pwt_data, [:country, :year])
# using DataFrames, StatFiles

timber_data = DataFrame(load("src/data/timber_and_subsoil_rent_input.dta")) # Load the .dta file

pwt_data = outerjoin(pwt_data, timber_data, on=[:country, :year], makeunique=true) # Merge with the main DataFrame

pwt_data = filter(row -> row.year >= minyear && row.year < maxyear, pwt_data) # Filter rows based on the year range

rename!(pwt_data, :forest => :timber) # Rename column `forest` to `timber`



####
# COMPUTE TIMBER AND SUBSOIL RENTS AS SHARE OF GDP

# List of natural resource types
natural_types = [:timber, :oil, :ng, :coal, :nickel, :lead, 
                :bauxite, :copper, :phosphate, :tin, :zinc, 
                :silver, :iron, :gold]
# Create `phi_NR_x` for each natural resource type
for x in natural_types
    pwt_data[!, Symbol("phi_NR_", x)] .= pwt_data[!, x] ./ pwt_data.nominal_gdp
end


# Generate tag_phi_NR_subsoil
# List of subsoil resource columns:
subsoil_resources = [:phi_NR_oil, :phi_NR_ng, :phi_NR_coal, :phi_NR_nickel, :phi_NR_lead,
                        :phi_NR_bauxite, :phi_NR_copper, :phi_NR_phosphate, :phi_NR_tin,
                         :phi_NR_zinc, :phi_NR_silver, :phi_NR_iron, :phi_NR_gold]
# We check if all the phi_NR_x columns for subsoil resources are missing (missing) 
#   and set tag_phi_NR_subsoil to 1 if true.
pwt_data[!, :tag_phi_NR_subsoil] .= all(row -> ismissing(row), eachrow(pwt_data[!, subsoil_resources]))

# Generate `phi_NR_subsoil` (row sum of subsoil resources)
pwt_data[!, :phi_NR_subsoil] .= ifelse.(pwt_data.tag_phi_NR_subsoil .!= 1,
    [sum(skipmissing(row[subsoil_resources]); init=0.0) for row in eachrow(pwt_data)],
    missing)
# Checking
first(select(pwt_data, [:country, :year, :phi_NR_subsoil]), 10) # The numbers match.


# For Serbia and Montenegro we have joint data but NOT individual.
# We compute individual using gdp as weight. 
# We need to compute the gdp of "Serbia and Montenegro" in order to compute the phi_NR_`x':

# Generate `nominal_gdp_serb`
pwt_data[!, :nominal_gdp_serb] .= ifelse.(pwt_data.country .== "Serbia", pwt_data.nominal_gdp, missing)
# Generate `nominal_gdp_mont`
pwt_data[!, :nominal_gdp_mont] .= ifelse.(pwt_data.country .== "Montenegro", pwt_data.nominal_gdp, missing)
# Group by year and compute max nominal GDP for Serbia and Montenegro
grouped_data = groupby(pwt_data, :year)
# Compute max nominal GDP for Serbia
serb_max = combine(grouped_data, :nominal_gdp_serb => maximum => :mnominal_gdp_serb)
pwt_data = leftjoin(pwt_data, serb_max, on=:year)
# Compute max nominal GDP for Montenegro
mont_max = combine(grouped_data, :nominal_gdp_mont => maximum => :mnominal_gdp_mont)
pwt_data = leftjoin(pwt_data, mont_max, on=:year)
# Replace `nominal_gdp` for "Serbia and Montenegro"
pwt_data[!, :nominal_gdp] .= ifelse.(pwt_data.country .== "Serbia and Montenegro",
    pwt_data.mnominal_gdp_serb .+ pwt_data.mnominal_gdp_mont,
    pwt_data.nominal_gdp)


# For Serbia and Montenegro we have joint data on timber and subsoil but NOT individual. 
#   On the other hand we have data on INDIVIDUAL nominal gdp, but not joint. 
#   We already computed the joint nominal_gdp for "Serbia and Montenegro" above.
#   We compute now timber and subsoil shares using individiual gdp as weights:

# Compute `share_serb`
pwt_data[!, :share_serb] .= pwt_data.mnominal_gdp_serb ./ (pwt_data.mnominal_gdp_serb .+ pwt_data.mnominal_gdp_mont)
# Compute `phi_NR_timber_serb` for "Serbia and Montenegro"
pwt_data[!, :phi_NR_timber_serb] .= ifelse.(pwt_data.country .== "Serbia and Montenegro",
    pwt_data.share_serb .* pwt_data.phi_NR_timber,
    missing)
# Compute `phi_NR_subsoil_serb` for "Serbia and Montenegro"
pwt_data[!, :phi_NR_subsoil_serb] .= ifelse.(pwt_data.country .== "Serbia and Montenegro",
    pwt_data.share_serb .* pwt_data.phi_NR_subsoil,
    missing)
#Checking
serbia_montenegro_rows = filter(row -> row.country == "Serbia and Montenegro", pwt_data)
println(first(serbia_montenegro_rows, 10)) #The numbers match.

# Compute Maximum phi_NR_timber_serb and phi_NR_subsoil_serb by Year
grouped_data = groupby(pwt_data, :year) # Group by year
max_timber = combine(grouped_data, :phi_NR_timber_serb => maximum => :mphi_NR_timber_serb) # Compute max for `phi_NR_timber_serb`
pwt_data = leftjoin(pwt_data, max_timber, on=:year)
max_subsoil = combine(grouped_data, :phi_NR_subsoil_serb => maximum => :mphi_NR_subsoil_serb) # Compute max for `phi_NR_subsoil_serb`
pwt_data = leftjoin(pwt_data, max_subsoil, on=:year)
#Replace phi_NR_timber and phi_NR_subsoil for Serbia
pwt_data[!, :phi_NR_timber] .= ifelse.(pwt_data.country .== "Serbia", # Replace `phi_NR_timber`
    pwt_data.mphi_NR_timber_serb,
    pwt_data.phi_NR_timber)
pwt_data[!, :phi_NR_subsoil] .= ifelse.(pwt_data.country .== "Serbia", # Replace `phi_NR_subsoil`
    pwt_data.mphi_NR_subsoil_serb,
    pwt_data.phi_NR_subsoil)

# Checking
#select(filter(row -> row.country == "Serbia", pwt_data), [:year, :phi_NR_timber, :phi_NR_subsoil])



# Compute `share_mont`
pwt_data[!, :share_mont] .= pwt_data.mnominal_gdp_mont ./ (pwt_data.mnominal_gdp_serb .+ pwt_data.mnominal_gdp_mont)
# Compute `phi_NR_timber_mont` and `phi_NR_subsoil_mont`
pwt_data[!, :phi_NR_timber_mont] .= ifelse.(pwt_data.country .== "Serbia and Montenegro",
    pwt_data.share_mont .* pwt_data.phi_NR_timber,
    missing)

pwt_data[!, :phi_NR_subsoil_mont] .= ifelse.(pwt_data.country .== "Serbia and Montenegro",
    pwt_data.share_mont .* pwt_data.phi_NR_subsoil,
    missing)

# Group by year and compute max values
grouped_data = groupby(pwt_data, :year)
max_timber_mont = combine(grouped_data, :phi_NR_timber_mont => maximum => :mphi_NR_timber_mont)
pwt_data = leftjoin(pwt_data, max_timber_mont, on=:year)
max_subsoil_mont = combine(grouped_data, :phi_NR_subsoil_mont => maximum => :mphi_NR_subsoil_mont)
pwt_data = leftjoin(pwt_data, max_subsoil_mont, on=:year)

# Replace `phi_NR_timber` and `phi_NR_subsoil` for Montenegro
pwt_data[!, :phi_NR_timber] .= ifelse.(pwt_data.country .== "Montenegro",
    pwt_data.mphi_NR_timber_mont,
    pwt_data.phi_NR_timber)

pwt_data[!, :phi_NR_subsoil] .= ifelse.(pwt_data.country .== "Montenegro",
    pwt_data.mphi_NR_subsoil_mont,
    pwt_data.phi_NR_subsoil)

# Drop rows where country is "Serbia and Montenegro"
pwt_data = filter(row -> row.country != "Serbia and Montenegro", pwt_data)

#Checking
#   new columns (they match)
select(pwt_data, [:country, :year, :phi_NR_timber, :phi_NR_subsoil, :phi_NR_timber_mont, :phi_NR_subsoil_mont]) |> first
#   inpsect rows for Montenegro
montenegro_data = filter(row -> row[:country] == "Montenegro", pwt_data)
relevant_columns = [:year, :phi_NR_timber, :phi_NR_subsoil, :phi_NR_timber_mont, :phi_NR_subsoil_mont]
select(montenegro_data, relevant_columns) #the numbers match
#    Ensure "Serbia and Montenegro" is dropped
println(unique(pwt_data.country)) #dropped





######################################
# (2) Merge with crop_rent_input.dta #
######################################

# Load crop_land_rent_input.dta
crop_data = DataFrame(load("crop_land_rent_input.dta"))
# Add marker columns
pwt_data[!, :origin] .= "pwt_data"
crop_data[!, :origin] .= "crop_data"
# Perform the merge
pwt_data = outerjoin(pwt_data, crop_data, on=[:country, :year], makeunique=true)


# Create `_merge` column to track row origin
pwt_data[!, :_merge] .= ifelse.(
    coalesce.(pwt_data.origin .== "pwt_data", false) .&& coalesce.(ismissing.(pwt_data.origin_1), true), 
    "PWT only",
    ifelse.(
        coalesce.(ismissing.(pwt_data.origin), true) .&& coalesce.(pwt_data.origin_1 .== "crop_data", false),
        "Crop only",
        "Both"
    )
)


# Tabulate `_merge` values
merge_tabulation = combine(groupby(pwt_data, :_merge), nrow => :Count)
println("Tabulation of _merge values:")
println(merge_tabulation)
# Create `cc2` column
pwt_data[!, :cc2] .= string.(pwt_data.countrycode, " ", pwt_data.country)
# Tabulate `cc2` for `_merge == "PWT only"`
filtered_cc2_1 = filter(row -> row._merge == "PWT only" && !ismissing(row.nominal_gdp) && row.year < 2006, pwt_data)
cc2_tabulation_1 = combine(groupby(filtered_cc2_1, :cc2), nrow => :Count)
println("Tabulation of cc2 for PWT only:")
println(cc2_tabulation_1) #No observation, this checks with the do-file output.
# Tabulate `cc2` for `_merge == "Crop only"`
filtered_cc2_2 = filter(row -> row._merge == "Crop only" && !ismissing(row.nominal_gdp) && row.year < 2006, pwt_data)
cc2_tabulation_2 = combine(groupby(filtered_cc2_2, :cc2), nrow => :Count)
println("Tabulation of cc2 for Crop only:")
println(cc2_tabulation_2) #No ibservation, this checks with the do-file output.



# Further we have two sets of countries for which we do not have individual data on crop
# land rents per country but joint data for country pairs for a selected number of years: 
#   (a) Belgium (30 periods), Luxembourg (30 periods), 
#   (b) Czech Rep (16 periods), Slovak Republic (16 periods), 


# (a) Belgium and Luxembourg:

# Remark: We notice that we compute crop rents jointly for
# Belgium-Luxembourg from 1966 to 1999, and then separately for Belgium from 2000 to 2001,
# and for Luxembourg from 2000 to 2011. Next, we impute pasture rents for Belgium and 
# Luxembourg separately by assuming that for years before 2000 these are split in 
# the Belgium-Luxembourg variable  as they are split between the Belgium and Luxemburg
# in 2000.

# Create `bel_2000` and `lux_2000`
pwt_data[!, :bel_2000] .= ifelse.(
    (pwt_data.country .== "Belgium") .&& (pwt_data.year .== 2000),
    pwt_data.pq_rent_a,
    missing
)
pwt_data[!, :lux_2000] .= ifelse.(
    (pwt_data.country .== "Luxembourg") .&& (pwt_data.year .== 2000),
    pwt_data.pq_rent_a,
    missing
)

# Compute maximum for bel_2000 and lux_2000
mbel_2000 = maximum(skipmissing(pwt_data.bel_2000))
mlux_2000 = maximum(skipmissing(pwt_data.lux_2000))
#Add these values to the dataframe
pwt_data[!, :mbel_2000] .= mbel_2000
pwt_data[!, :mlux_2000] .= mlux_2000

# Filter rows for Belgium and Luxembourg in the year 2000
bel_lux_2000 = filter(row -> (row.country in ["Belgium", "Luxembourg"]) && (row.year == 2000), pwt_data)
# Select relevant columns to inspect
select(bel_lux_2000, [:country, :year, :pq_rent_a, :bel_2000, :lux_2000, :mbel_2000, :mlux_2000])


#select(pwt_data, [:country, :year, :pq_rent_a, :bel_2000, :lux_2000, :mbel_2000, :mlux_2000])


# Save DataFrame to a CSV file
# CSV.write("pwt_data.csv", pwt_data)
