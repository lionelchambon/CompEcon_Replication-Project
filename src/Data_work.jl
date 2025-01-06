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

# Note of the replicators : 
    # At almost each step, we write the Stata code used by the authors after "They do" and three '#' signs.
    # We will then proceed to explain step by step the functions used in Julia. 
    # Any created function is tested in the "tests_Data_work.jl" file, in the "test" folder.

using DataFrames
using StatFiles
using StatsBase
using Missings
using CSV
using Statistics

# Load the dataset of the Penn World Tables (pwt) :
# cd(dirname(pathof(Replication_Monge_et_al_2019)))
# splitdir(pwd())[2]
# cd("data")
pwt_data = DataFrame(load("src/data/pwt80.dta"))
# We save the dimensions for later checks : 
initial_size = size(pwt_data)
# We will regularly proceed to Dimension Checks, referred as "DC".
 


# We first work with pl_gdpe and pl_gdpo.
# pl_gdpe is the price level of Expenditure-side real GDP at current PPPs (in mil. 2005US$).
# pl_gdpo is the price level of Output-side real GDP at current PPPs (in mil. 2005US$).
# The authors replace negative values of those variables with 'missing'.

# They do : 
### replace pl_gdpe=. if pl_gdpe<0 /* No country */
### replace pl_gdpo=. if pl_gdpo<0 /*This happens in Bermuda*/

# For us to do so, we create a function that takes any negative value and replace it by 'missing'
function filter_function!(x)
    if x isa Number
        if x < 0 
            x = missing
        else
            x = x
        end
    else
        x = missing
    end
    return x
end

# We then broadcast the function on the pl_gdpe and pl_gdpo columns of the data frame :
pwt_data[!, :pl_gdpe] = filter_function!.(pwt_data[!, :pl_gdpe])
pwt_data[!, :pl_gdpo] = filter_function!.(pwt_data[!, :pl_gdpo])

# We can then check that the number of missing observations are the same as in the original do file : 
# To obtain the number of missing observations in pl_gdpe and pl_gdpo in Stata, we do : 
### count if missing(pl_gdpe) # 2080
### count if missing(pl_gdpo) # 2086
if count(ismissing, pwt_data[!, :pl_gdpe]) !== 2080
    @error("Wrong number of missing observations in pl_gdpe.")
end
if count(ismissing, pwt_data[!, :pl_gdpo]) !== 2086 
    @error("Wrong number of missing observations in pl_gdpo.")
end
# DC
if size(pwt_data) !== initial_size
    @error("Error in the data frame dimensions.")
end



# The authors then generate the pl_gdpo_old variable, equal to the ratio of `pl_gdp` over `nom_pp` for the USA.

# They do : 
### bys year: egen nom_p=max(pl_gdpo) if countrycode=="USA"
### bys year: egen nom_pp=max(nom_p)
### gen pl_gdpo_old = pl_gdpo/nom_pp

# For us to do so, we first separate the data of the USA :
usa_data = pwt_data[pwt_data[!,:countrycode] .== "USA", :] 
size(usa_data)[2] == initial_size[2] # DC
# We group by year and calculate the max value for pl_gdpo
usa_nom_p = combine(groupby(filter(row -> row[:countrycode] == "USA", pwt_data), :year), 
                    :pl_gdpo => maximum => :nom_p) 
# We merge the results back into the original dataset : 
pwt_data = leftjoin(pwt_data, usa_nom_p, on=:year, makeunique=true) 
# We group by year :
pwt_data = groupby(pwt_data, :year)
# This line seems redundant but we prefer following the logic of the do file
pwt_data = transform(pwt_data, :nom_p => maximum => :nom_pp)
# We finally generate the variable : 
pwt_data[!, :pl_gdpo_old] .= pwt_data.pl_gdpo ./ pwt_data.nom_pp 

# Checking by comparing the obtained value with the one the authors get :
if mean(skipmissing(pwt_data.pl_gdpo_old)) ≉ .7216124
    @error("Error in the creation of the variable pl_gdpe_old.")
end


# The authors then generate the pl_gdpe_old variable.
# They do : 
### drop nom_p nom_pp
### bys year: egen nom_p=max(pl_gdpe) if countrycode=="USA"
### bys year: egen nom_pp=max(nom_p)
### gen pl_gdpe_old = pl_gdpe/nom_pp

# Drop nom_p and nom_pp :
select!(pwt_data, Not([:nom_p, :nom_pp])) 
# Filter for USA and compute max(pl_gdpe) by year
usa_nom_p = combine(groupby(filter(row -> row[:countrycode] == "USA", pwt_data), :year), 
                    :pl_gdpe => maximum => :nom_p)
pwt_data = leftjoin(pwt_data, usa_nom_p, on=:year)
pwt_data = groupby(pwt_data, :year)
pwt_data = transform(pwt_data, :nom_p => maximum => :nom_pp)
pwt_data[!, :pl_gdpe_old] .= pwt_data.pl_gdpe ./ pwt_data.nom_pp
# Checking by comparing the obtained value with the one the authors get :
if mean(skipmissing(pwt_data.pl_gdpe_old)) ≉ .7002738
    @error("Error in the creation of the variable pl_gdpe_old.")
end


# Remark 1 of the authors : 
# We multiply nominal GDP by 1,000,000 to transform GDP 
#   in the same units as rents from natural resources (from "natural_rents.dta")

# They do : 
### gen nominal_gdpe = (cgdpe)*1000000*pl_gdpe_old
### gen nominal_gdpo = (cgdpo)*1000000*pl_gdpo_old

# To create new columns for nominal_gdpe and nominal_gdpo, we can do :
pwt_data[!, :nominal_gdpe] .= pwt_data.cgdpe .* 1_000_000 .* pwt_data.pl_gdpe_old
pwt_data[!, :nominal_gdpo] .= pwt_data.cgdpo .* 1_000_000 .* pwt_data.pl_gdpo_old

# Also, they do the equivalent of :
pwt_data[!, :nominal_gdp] .= pwt_data.nominal_gdpo
minyear = 1970
maxyear = 2010
pwt_data[!, :country] .= replace.(pwt_data.country, "Cote d`Ivoire" => "Cote dIvoire")

pwt_data_0 = copy(pwt_data)
CSV.write("output/pwt_data_0.csv", pwt_data_0)

# ###############################################
# # (1) Merge with timber_and_subsoil_rents.dta #
# ###############################################

# They do : 
### codebook country	
### sort country year
### merge 1:1 country year using "timber_and_subsoil_rent_input.dta"
### 
### keep if year>=minyear & year<maxyear 

sort!(pwt_data, [:country, :year])

# We load the .dta file
timber_data = DataFrame(load("src/data/timber_and_subsoil_rent_input.dta")) 
# We merge with the main DataFrame
pwt_data = outerjoin(pwt_data, timber_data, on=[:country, :year], makeunique=true) 
# We filter rows based on the year range
pwt_data = filter(row -> row.year >= minyear && row.year < maxyear, pwt_data)
# We rename column `forest` to `timber`
rename!(pwt_data, :forest => :timber) 

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
# The numbers match : 
# first(select(pwt_data, [:country, :year, :phi_NR_subsoil]), 10) 


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
# println(first(serbia_montenegro_rows, 10)) #The numbers match.

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

# Checking
#   new columns (they match)
select(pwt_data, [:country, :year, :phi_NR_timber, :phi_NR_subsoil, :phi_NR_timber_mont, :phi_NR_subsoil_mont]) |> first
#   inpsect rows for Montenegro
montenegro_data = filter(row -> row[:country] == "Montenegro", pwt_data)
relevant_columns = [:year, :phi_NR_timber, :phi_NR_subsoil, :phi_NR_timber_mont, :phi_NR_subsoil_mont]
select(montenegro_data, relevant_columns) #the numbers match
#    Ensure "Serbia and Montenegro" is dropped
# println(unique(pwt_data.country)) # dropped

# At this point, pwt_data is what we want. We will call it 
pwt_data_1 = copy(pwt_data)

# Save DataFrame to a CSV file
CSV.write("output/pwt_data_1.csv", pwt_data_1)

# Check : 
# a = CSV.read("output/pwt_data_1.csv", DataFrame)
# pwt_data_1 == a 
# isequal(pwt_data_1,a)
# names(a) == names(pwt_data_1)
# isapprox(a, pwt_data_1)

###################################################################################################



### ######################################
### # (2) Merge with crop_rent_input.dta #
### ######################################

# Load crop_land_rent_input.dta
crop_data = DataFrame(load("src/data/crop_land_rent_input.dta"))
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
# println("Tabulation of _merge values:")
# println(merge_tabulation)
# Create `cc2` column
pwt_data[!, :cc2] .= string.(pwt_data.countrycode, " ", pwt_data.country)
# Tabulate `cc2` for `_merge == "PWT only"`
filtered_cc2_1 = filter(row -> row._merge == "PWT only" && !ismissing(row.nominal_gdp) && row.year < 2006, pwt_data)
cc2_tabulation_1 = combine(groupby(filtered_cc2_1, :cc2), nrow => :Count)
# println("Tabulation of cc2 for PWT only:")
# println(cc2_tabulation_1) #No observation, this checks with the do-file output.
# Tabulate `cc2` for `_merge == "Crop only"`
filtered_cc2_2 = filter(row -> row._merge == "Crop only" && !ismissing(row.nominal_gdp) && row.year < 2006, pwt_data)
cc2_tabulation_2 = combine(groupby(filtered_cc2_2, :cc2), nrow => :Count)
# println("Tabulation of cc2 for Crop only:")
# println(cc2_tabulation_2) #No ibservation, this checks with the do-file output.



# Further we have two sets of countries for which we do not have individual data on crop
# land rents per country but joint data for country pairs for a selected number of years: 
#   (a) Belgium (30 periods), Luxembourg (30 periods), 
#   (b) Czech Rep (16 periods), Slovak Republic (16 periods), 


# (a) Belgium and Luxembourg:
# Remark of the authors:
# We notice that we compute crop rents jointly for
#   Belgium-Luxembourg from 1966 to 1999, and then separately for Belgium from 2000 to 2001,
#   and for Luxembourg from 2000 to 2011. Next, we impute pasture rents for Belgium and 
#   Luxembourg separately by assuming that for years before 2000 these are split in 
#   the Belgium-Luxembourg variable  as they are split between the Belgium and Luxemburg
#   in 2000.
# They do:
### gen  bel_2000=pq_rent_a if country=="Belgium"    & year==2000
### gen  lux_2000=pq_rent_a if country=="Luxembourg" & year==2000
### egen mbel_2000=max(bel_2000)
### egen mlux_2000=max(lux_2000)
# We create `bel_2000` and `lux_2000`
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
#Checking
# Filter rows for Belgium and Luxembourg in the year 2000
bel_lux_2000 = filter(row -> (row.country in ["Belgium", "Luxembourg"]) && (row.year == 2000), pwt_data);
# Select relevant columns to inspect
select(bel_lux_2000, [:country, :year, :pq_rent_a, :bel_2000, :lux_2000, :mbel_2000, :mlux_2000]); #The numbers check.
# They do:
### gen  share_bel_2000=mbel_2000/(mbel_2000+mlux_2000) 
### gen pq_rent_a_bel=share_bel_2000*pq_rent_a if country=="Belgium-Luxembourg"
### bys year: egen mpq_rent_a_bel=max(pq_rent_a_bel)
### replace pq_rent_a = mpq_rent_a_bel if country=="Belgium" & year<2000	
# We compute `share_bel_2000`
pwt_data[!, :share_bel_2000] .= pwt_data.mbel_2000 ./ (pwt_data.mbel_2000 .+ pwt_data.mlux_2000)
# We compute `pq_rent_a_bel` only for "Belgium-Luxembourg"
pwt_data[!, :pq_rent_a_bel] .= ifelse.(
    pwt_data.country .== "Belgium-Luxembourg",
    pwt_data.share_bel_2000 .* pwt_data.pq_rent_a,
    missing
)
# Checking
    # Filter rows for "Belgium-Luxembourg"
    bel_lux_rows = filter(row -> row.country == "Belgium-Luxembourg", pwt_data)
    # Select relevant columns for inspection
    # println(select(bel_lux_rows, [:country, :year, :pq_rent_a, :share_bel_2000, :pq_rent_a_bel])) #the numbers match!
# Create a mapping of `year` to `pq_rent_a_bel` for Belgium-Luxembourg
bel_lux_mapping = Dict(
    row.year => row.pq_rent_a_bel for row in eachrow(pwt_data) 
    if row.country == "Belgium-Luxembourg" && !ismissing(row.pq_rent_a_bel)
)
# Assign `mpq_rent_a_bel` based on the mapping
pwt_data[!, :mpq_rent_a_bel] .= get.(Ref(bel_lux_mapping), pwt_data.year, missing)
# Checking
    # Filter rows for years between 1970 and 1999
    filtered_data = filter(row -> row.year >= 1970 && row.year <= 1999, pwt_data)
    # Sort the filtered data by year
    sorted_data = sort(filtered_data, :year)
    # Group data by year and display the relevant columns
    grouped_by_year = groupby(sorted_data, :year)
    # Iterate through each group and display the relevant rows
    for group in grouped_by_year
        # println("Year: ", first(group).year)
        # println(select(group, [:country, :year, :pq_rent_a_bel, :mpq_rent_a_bel]))
        # println("--------------------------")
    end # the numbers match!
# Replace `pq_rent_a` for Belgium for years before 2000
pwt_data[!, :pq_rent_a] .= ifelse.(
    (pwt_data.country .== "Belgium") .&& (pwt_data.year .< 2000),
    pwt_data.mpq_rent_a_bel,
    pwt_data.pq_rent_a
)
# They do:
### gen  share_lux_2000=mlux_2000/(mbel_2000+mlux_2000) 
### gen pq_rent_a_lux=share_lux_2000*pq_rent_a if country=="Belgium-Luxembourg"
### bys year: egen mpq_rent_a_lux=max(pq_rent_a_lux)
### replace pq_rent_a = mpq_rent_a_lux if country=="Luxembourg" & year<2000	
# Compute `share_lux_2000`
pwt_data[!, :share_lux_2000] .= pwt_data.mlux_2000 ./ (pwt_data.mbel_2000 .+ pwt_data.mlux_2000)
# Compute `pq_rent_a_lux` only for "Belgium-Luxembourg"
pwt_data[!, :pq_rent_a_lux] .= ifelse.(
    pwt_data.country .== "Belgium-Luxembourg",
    pwt_data.share_lux_2000 .* pwt_data.pq_rent_a,
    missing
)
#Intermediary check
    # Filter rows for "Belgium-Luxembourg"
    bel_lux_rows = filter(row -> row.country == "Belgium-Luxembourg", pwt_data)
    # Select relevant columns for inspection
    # println(select(bel_lux_rows, [:country, :year, :pq_rent_a, :share_lux_2000, :pq_rent_a_lux])) #the numbers match!
    # Create a mapping of `year` to `pq_rent_a_lux` for Belgium-Luxembourg
bel_lux_mapping = Dict(
    row.year => row.pq_rent_a_lux for row in eachrow(pwt_data) 
    if row.country == "Belgium-Luxembourg" && !ismissing(row.pq_rent_a_lux)
)
# Assign `mpq_rent_a_lux` based on the mapping
pwt_data[!, :mpq_rent_a_lux] .= get.(Ref(bel_lux_mapping), pwt_data.year, missing)
# Intermediary check
    # Filter rows for years between 1970 and 1999
    filtered_data = filter(row -> row.year >= 1970 && row.year <= 1999, pwt_data)
    # Sort the filtered data by year
    sorted_data = sort(filtered_data, :year)
    # Group data by year and display the relevant columns
    grouped_by_year = groupby(sorted_data, :year)
    # Iterate through each group and display the relevant rows
    for group in grouped_by_year
        # println("Year: ", first(group).year)
        # println(select(group, [:country, :year, :pq_rent_a_lux, :mpq_rent_a_lux]))
        # println("--------------------------")
    end# the numbers match!
# Replace `pq_rent_a` for Luxembourg for years before 2000
pwt_data[!, :pq_rent_a] .= ifelse.(
    (pwt_data.country .== "Luxembourg") .&& (pwt_data.year .< 2000),
    pwt_data.mpq_rent_a_lux,
    pwt_data.pq_rent_a
)
# They do:
### sort country year
### drop bel_2000-mpq_rent_a_lux
### drop if country=="Belgium-Luxembourg" 
# Sort by country and year
pwt_data = sort(pwt_data, [:country, :year])
# Drop intermediate columns (bel_2000 to mpq_rent_a_lux)
select!(pwt_data, Not([:bel_2000, :lux_2000, :mbel_2000, :mlux_2000, :share_bel_2000, :share_lux_2000, :pq_rent_a_bel, :pq_rent_a_lux]));
# Drop rows where country is "Belgium-Luxembourg"
pwt_data = filter(row -> row.country != "Belgium-Luxembourg", pwt_data)
# We also drop every row before 1970 and after 2009 to get a cleaner dataset
pwt_data = filter(row -> row.year >= 1970 && row.year <= 2009, pwt_data)

# (b) Czech Rep. and Slovakia Rep.
# Note of the authors
# Simlarly, the World Bank provides pasture land rents jointly for Czechoslovakia 
# from 1966 to 1992, and then separately for Czech Rep. from 1993 to 2011 and 
# Slovakia Rep. from 1993 to 2011. Next, we impute pasture rents for Czech Rep. and 
# Slovakia Rep. separately by assuming that for years before 1993 these rents are split
# in Czechoslovakia variable as they are split between the Czech Rep and the Slovakia Rep. 
# in 1993.
# They do:
### gen  cze_1993=pq_rent_a if country=="Czech Republic"  & year==1993
### gen  slo_1993=pq_rent_a if country=="Slovak Republic" & year==1993
### egen mcze_1993=max(cze_1993)
### egen mslo_1993=max(slo_1993)
# Generate `cze_1993` for Czech Republic in 1993
pwt_data[!, :cze_1993] .= ifelse.(
    (pwt_data.country .== "Czech Republic") .&& (pwt_data.year .== 1993),
    pwt_data.pq_rent_a,
    missing
)
# Generate `slo_1993` for Slovak Republic in 1993
pwt_data[!, :slo_1993] .= ifelse.(
    (pwt_data.country .== "Slovak Republic") .&& (pwt_data.year .== 1993),
    pwt_data.pq_rent_a,
    missing
)
# Compute max for `cze_1993`
mcze_1993 = maximum(skipmissing(pwt_data.cze_1993))
# Compute max for `slo_1993`
mslo_1993 = maximum(skipmissing(pwt_data.slo_1993))
# Add these maximums to the DataFrame as new columns
pwt_data[!, :mcze_1993] .= mcze_1993
pwt_data[!, :mslo_1993] .= mslo_1993
# Checkingf
    # Filter and inspect rows for Czech Republic and Slovak Republic in 1993
    cze_slo_rows = filter(
        row -> row.country in ["Czech Republic", "Slovak Republic"] && row.year == 1993,
        pwt_data
    )
    # Display relevant columns
    # println(select(cze_slo_rows, [:country, :year, :pq_rent_a, :cze_1993, :slo_1993, :mcze_1993, :mslo_1993]))
    #it checks out

# They do:
### gen  share_cze_1993=mcze_1993/(mcze_1993+mslo_1993) 
### gen pq_rent_a_cze=share_cze_1993*pq_rent_a if country=="Czechoslovakia"
### bys year: egen mpq_rent_a_cze=max(pq_rent_a_cze)
### replace pq_rent_a = mpq_rent_a_cze if country=="Czech Republic" & year<1993	

# We compute the share for Czech Republic in 1993
pwt_data[!, :share_cze_1993] .= pwt_data.mcze_1993 ./ (pwt_data.mcze_1993 .+ pwt_data.mslo_1993)
# We compute `pq_rent_a_cze` for rows where country is "Czechoslovakia"
pwt_data[!, :pq_rent_a_cze] .= ifelse.(
    pwt_data.country .== "Czechoslovakia",
    pwt_data.share_cze_1993 .* pwt_data.pq_rent_a,
    missing
)
# We create a mapping of year to `pq_rent_a_cze` for Czechoslovakia
cze_mapping = Dict(
    row.year => row.pq_rent_a_cze for row in eachrow(pwt_data)
    if row.country == "Czechoslovakia" && !ismissing(row.pq_rent_a_cze)
)
# We replace `pq_rent_a` for Czech Republic for years before 1993 based on the mapping
pwt_data[!, :pq_rent_a] .= ifelse.(
    (pwt_data.country .== "Czech Republic") .&& (pwt_data.year .< 1993),
    get.(Ref(cze_mapping), pwt_data.year, missing),
    pwt_data.pq_rent_a
)
# Checking :
# We inspect rows for Czech Republic and Czechoslovakia
cze_rows = filter(
    row -> row.country in ["Czechoslovakia", "Czech Republic"],
    pwt_data
)
# Displaying relevant columns to validate
# println(select(cze_rows, [:country, :year, :pq_rent_a, :pq_rent_a_cze]))
#The numbers match!


# They do:
###  gen  share_slo_1993=mslo_1993/(mcze_1993+mslo_1993) 
### gen pq_rent_a_slo=share_slo_1993*pq_rent_a if country=="Czechoslovakia"
### bys year: egen mpq_rent_a_slo=max(pq_rent_a_slo)
### replace pq_rent_a = mpq_rent_a_slo if country=="Slovak Republic" & year<1993	

# We compute the share for Slovak Republic in 1993
pwt_data[!, :share_slo_1993] .= pwt_data.mslo_1993 ./ (pwt_data.mcze_1993 .+ pwt_data.mslo_1993)
# We compute `pq_rent_a_slo` for rows where country is "Czechoslovakia"
pwt_data[!, :pq_rent_a_slo] .= ifelse.(
    pwt_data.country .== "Czechoslovakia",
    pwt_data.share_slo_1993 .* pwt_data.pq_rent_a,
    missing
)
# We create a mapping of year to `pq_rent_a_slo` for Czechoslovakia
slo_mapping = Dict(
    row.year => row.pq_rent_a_slo for row in eachrow(pwt_data)
    if row.country == "Czechoslovakia" && !ismissing(row.pq_rent_a_slo)
)
# We replace `pq_rent_a` for Slovak Republic for years before 1993 based on the mapping
pwt_data[!, :pq_rent_a] .= ifelse.(
    (pwt_data.country .== "Slovak Republic") .&& (pwt_data.year .< 1993),
    get.(Ref(slo_mapping), pwt_data.year, missing),
    pwt_data.pq_rent_a
)

# Checking
    # We inspect rows for Czech Republic and Czechoslovakia
    slo_rows = filter(
        row -> row.country in ["Czechoslovakia", "Slovakia"],
        pwt_data
    )
    # Displaying relevant columns to validate
    # println(select(slo_rows, [:country, :year, :pq_rent_a, :pq_rent_a_slo]))


# # They do:
# ### sort country year	
# ### drop cze_1993-mpq_rent_a_slo
# ### drop if country=="Czechoslovakia"  

# We sort the data by country and year
pwt_data = sort(pwt_data, [:country, :year])
# Drop intermediate columns (cze_1993 to mpq_rent_a_slo)
select!(pwt_data, Not([:cze_1993, :slo_1993, :mcze_1993, :mslo_1993, :share_cze_1993, :share_slo_1993, :pq_rent_a_cze, :pq_rent_a_slo]))
# Drop rows where country is "Czechoslovakia"
pwt_data = filter(row -> row.country != "Czechoslovakia", pwt_data)
# Checking
    # We filter rows for Czechoslovakia, Czech Republic, and Slovak Republic
    relevant_rows = filter(
        row -> row.country in [ "Czech Republic", "Slovak Republic"],
        pwt_data
    )
    # Inspect relevant rows with additional columns
    # println(select(relevant_rows, [:country, :countrycode, :year, :pq_rent_a,])) # Numbers check





# (c) Serbia and Montenegro

# Note from the authors: 
# Finally, the World Bank provides pasture land rents jointly for Serbia and Montenegro 
#   from 1992 to 2005, and then separately for Serbia 2006 to 2011 and Montenegro 2006 to 2011.
# Next, we impute pasture rents for Serbia and 
#   Montenegro separately by assuming that for years before 2006 these are split in 
#   the "Serbia and Montenegro" variable as they are split between Serbia and Montenegro
#   in 2006.

# They do:
### gen  serb_2006=pq_rent_a if country=="Serbia"     & year==2006
### gen  mont_2006=pq_rent_a if country=="Montenegro" & year==2006
### egen mserb_2006=max(serb_2006)
### egen mmont_2006=max(mont_2006)

# Generate `serb_2006` for Serbia in 2006
pwt_data[!, :serb_2006] .= ifelse.(
    (pwt_data.country .== "Serbia") .&& (pwt_data.year .== 2006),
    pwt_data.pq_rent_a,
    missing
)
# Generate `mont_2006` for Montenegro in 2006
pwt_data[!, :mont_2006] .= ifelse.(
    (pwt_data.country .== "Montenegro") .&& (pwt_data.year .== 2006),
    pwt_data.pq_rent_a,
    missing
)
# Compute the maximum of `serb_2006`
mserb_2006 = maximum(skipmissing(pwt_data.serb_2006))
# Compute the maximum of `mont_2006`
mmont_2006 = maximum(skipmissing(pwt_data.mont_2006))
# Add these maximums as new columns in the DataFrame
pwt_data[!, :mserb_2006] .= mserb_2006
pwt_data[!, :mmont_2006] .= mmont_2006
# Filter rows for Serbia and Montenegro in 2006
serb_mont_rows = filter(
    row -> row.country in ["Serbia", "Montenegro"] && row.year == 2006,
    pwt_data
)
# Display relevant columns to validate
# println(select(serb_mont_rows, [:country, :year, :pq_rent_a, :serb_2006, :mont_2006, :mserb_2006, :mmont_2006]))



# They do:
### gen  share_serb_2006=mserb_2006/(mserb_2006+mmont_2006) 
### gen pq_rent_a_serb=share_serb_2006*pq_rent_a if country=="Serbia and Montenegro"
### bys year: egen mpq_rent_a_serb=max(pq_rent_a_serb)
### replace pq_rent_a = mpq_rent_a_serb if country=="Serbia" & year<2006

# Compute the share for Serbia in 2006
pwt_data[!, :share_serb_2006] .= pwt_data.mserb_2006 ./ (pwt_data.mserb_2006 .+ pwt_data.mmont_2006)
# Compute `pq_rent_a_serb` for rows where country is "Serbia and Montenegro"
pwt_data[!, :pq_rent_a_serb] .= ifelse.(
    pwt_data.country .== "Serbia and Montenegro",
    pwt_data.share_serb_2006 .* pwt_data.pq_rent_a,
    missing
)
# Create a mapping of year to `pq_rent_a_serb` for Serbia and Montenegro
serb_mapping = Dict(
    row.year => row.pq_rent_a_serb for row in eachrow(pwt_data)
    if row.country == "Serbia and Montenegro" && !ismissing(row.pq_rent_a_serb)
)
# Replace `pq_rent_a` for Serbia for years before 2006 based on the mapping
pwt_data[!, :pq_rent_a] .= ifelse.(
    (pwt_data.country .== "Serbia") .&& (pwt_data.year .< 2006),
    get.(Ref(serb_mapping), pwt_data.year, missing),
    pwt_data.pq_rent_a
)

#Checking
    # Inspect rows for Serbia and Serbia and Montenegro
    serb_rows = filter(
        row -> row.country in ["Serbia", "Serbia and Montenegro"],
        pwt_data
    )
    # Display relevant columns to validate
    # println(select(serb_rows, [:country, :year, :pq_rent_a_serb, :pq_rent_a]))


# They do:
### gen  share_mont_2006=mmont_2006/(mserb_2006+mmont_2006) 
### gen pq_rent_a_mont=share_mont_2006*pq_rent_a if country=="Serbia and Montenegro"
### bys year: egen mpq_rent_a_mont=max(pq_rent_a_mont)
### replace pq_rent_a = mpq_rent_a_mont if country=="Montenegro" & year<2006

# Compute the share for Montenegro in 2006
pwt_data[!, :share_mont_2006] .= pwt_data.mmont_2006 ./ (pwt_data.mserb_2006 .+ pwt_data.mmont_2006)
# Compute `pq_rent_a_mont` for rows where country is "Serbia and Montenegro"
pwt_data[!, :pq_rent_a_mont] .= ifelse.(
    pwt_data.country .== "Serbia and Montenegro",
    pwt_data.share_mont_2006 .* pwt_data.pq_rent_a,
    missing
)
# Create a mapping of year to `pq_rent_a_mont` for Serbia and Montenegro
mont_mapping = Dict(
    row.year => row.pq_rent_a_mont for row in eachrow(pwt_data)
    if row.country == "Serbia and Montenegro" && !ismissing(row.pq_rent_a_mont)
)
# Replace `pq_rent_a` for Montenegro for years before 2006 based on the mapping
pwt_data[!, :pq_rent_a] .= ifelse.(
    (pwt_data.country .== "Montenegro") .&& (pwt_data.year .< 2006),
    get.(Ref(mont_mapping), pwt_data.year, missing),
    pwt_data.pq_rent_a
)
# Inspect rows for Montenegro and Serbia and Montenegro
mont_rows = filter(
    row -> row.country in ["Montenegro", "Serbia and Montenegro"],
    pwt_data
)
# Display relevant columns to validate
# println(select(mont_rows, [:country, :year, :pq_rent_a_mont, :pq_rent_a]))



# They do:
### sort country year	
### drop serb_2006-mpq_rent_a_mont  
### drop if country=="Serbia and Montenegro" 
 
# Sort the data by country and year
pwt_data = sort(pwt_data, [:country, :year]);
# Drop intermediate columns used in calculations (serb_2006 to mpq_rent_a_mont)
select!(pwt_data, Not([:serb_2006, :mont_2006, :mserb_2006, :mmont_2006, :share_serb_2006, :share_mont_2006, :pq_rent_a_serb, :pq_rent_a_mont]));
# Drop rows where country is "Serbia and Montenegro"
pwt_data = filter(row -> row.country != "Serbia and Montenegro", pwt_data);

#Checking
    # Filter rows for Serbia and Montenegro
    serb_mont_rows = filter(
        row -> row.country in ["Serbia", "Montenegro"],
        pwt_data
    )
    # Inspect rows for Serbia, Montenegro, and Serbia and Montenegro with additional columns
    # println(select(serb_mont_rows, [:country, :countrycode, :year, :pq_rent_a])) #numbers check



##### COMPUTE CROP LAND RENTS AS SHARE OF GDP

# They do:
### g phi_NR_crop_pq_a  =  pq_rent_a/nominal_gdp
### g phi_NR_crop_fao_a = fao_rent_a/nominal_gdp
### g phi_NR_crop_pq_p  =  pq_rent_p/nominal_gdp
### g phi_NR_crop_fao_p = fao_rent_p/nominal_gdp

# Compute phi_NR_crop_pq_a as the share of GDP
pwt_data[!, :phi_NR_crop_pq_a] .= pwt_data.pq_rent_a ./ pwt_data.nominal_gdp
# Compute phi_NR_crop_fao_a as the share of GDP
pwt_data[!, :phi_NR_crop_fao_a] .= pwt_data.fao_rent_a ./ pwt_data.nominal_gdp
# Compute phi_NR_crop_pq_p as the share of GDP
pwt_data[!, :phi_NR_crop_pq_p] .= pwt_data.pq_rent_p ./ pwt_data.nominal_gdp
# Compute phi_NR_crop_fao_p as the share of GDP
pwt_data[!, :phi_NR_crop_fao_p] .= pwt_data.fao_rent_p ./ pwt_data.nominal_gdp

# Checking the first rows
# println(first(select(pwt_data, [:country, :year, :phi_NR_crop_pq_a, :phi_NR_crop_fao_a, :phi_NR_crop_pq_p, :phi_NR_crop_fao_p]), 10))



# They do:
### label variable phi_NR_crop_pq_a  "phi_NR_crop_a: rent/gdp using p*q and area weights"
### label variable phi_NR_crop_fao_a "phi_NR_crop_FAO_a: rent/gdp using FAO and area weights"
### label variable phi_NR_crop_pq_p  "phi_NR_crop_p: rent/gdp using p*q and production weights"
### label variable phi_NR_crop_fao_p "phi_NR_crop_FAO_p: rent/gdp using FAO and production weights"
# Julia does not natively support variable labels like Stata,
#    but we can create a dictionary to store metadata about your variables. 
# Create a dictionary to store variable labels
variable_labels = Dict(
    :phi_NR_crop_pq_a => "phi_NR_crop_a: rent/gdp using p*q and area weights",
    :phi_NR_crop_fao_a => "phi_NR_crop_FAO_a: rent/gdp using FAO and area weights",
    :phi_NR_crop_pq_p => "phi_NR_crop_p: rent/gdp using p*q and production weights",
    :phi_NR_crop_fao_p => "phi_NR_crop_FAO_p: rent/gdp using FAO and production weights"
)
# Access a label example
# println("Label for phi_NR_crop_pq_a: ", variable_labels[:phi_NR_crop_pq_a])



# They do:
### table year, c(n phi_NR_crop_pq_a n phi_NR_crop_pq_p n phi_NR_crop_fao_a n phi_NR_crop_fao_p)

# Group by year and compute non-missing counts for each variable
summary_table = combine(
    groupby(pwt_data, :year),
    :phi_NR_crop_pq_a => (x -> sum(.!ismissing.(x))) => :n_phi_NR_crop_pq_a,
    :phi_NR_crop_pq_p => (x -> sum(.!ismissing.(x))) => :n_phi_NR_crop_pq_p,
    :phi_NR_crop_fao_a => (x -> sum(.!ismissing.(x))) => :n_phi_NR_crop_fao_a,
    :phi_NR_crop_fao_p => (x -> sum(.!ismissing.(x))) => :n_phi_NR_crop_fao_p
)

# They do:
### drop _merge	

# Drop the `_merge` column
select!(pwt_data, Not(:_merge))

# Saving it : 
pwt_data_2 = copy(pwt_data)
CSV.write("output/pwt_data_2.csv", pwt_data_2)




###################################################################################################



### #########################################
### # (3) Merge with pasture_rent_input.dta #
### #########################################

# They do:
### codebook country	
### sort country year
### merge country year using "pasture_land_rent_input.dta"
### keep if year>=minyear & year<maxyear 	

# Load the pasture rent data
pasture_data = DataFrame(load("src/data/pasture_land_rent_input.dta"))

# Merge with the main DataFrame
pwt_data = outerjoin(
    pwt_data, 
    pasture_data, 
    on=[:country, :year], 
    makeunique=true, 
    indicator=:_merge
)
# Filter rows within the year range
pwt_data = filter(row -> row.year >= minyear && row.year < maxyear, pwt_data)


# They do:
### tab _merge if nominal_gdp~=.
### gen cc3 = countrycode + " " + country
### tabulate cc3 if _merge==1 & nominal_gdp~=. & year<2006
### tabulate cc3 if _merge==2 & nominal_gdp~=. & year<2006
### tab _merge


# Tabulate `_merge` column
merge_counts = combine(groupby(DataFrame(_merge=pwt_data._merge), :_merge), nrow => :count)
# Print the tabulation
println(merge_counts)
# Create `cc3` column
pwt_data[!, :cc3] = string.(pwt_data.countrycode, " ", pwt_data.country)
# Filter and tabulate for _merge == 1
filtered_data1 = filter(row -> row._merge == 1 && !ismissing(row.nominal_gdp) && row.year < 2006, pwt_data)

# Tabulate `cc3` for `_merge == 1`
println(countmap(filtered_data1[!, :cc3]))
# Count occurrences of each value in the `cc3` column
cc3_counts = combine(groupby(filtered_data1, :cc3), nrow => :count)
# Print the counts
println(cc3_counts)




# Note from the authors:
# Further we have a collection of countries for which we have not individual data per country but joint data on a set country pairs for a selected number of years: 
#     (a) Belgium (30 periods), Luxembourg (30 periods), 
#     (b) Czech Rep (3 periods), Slovak Republic (3 periods), 
#     (c) Serbia (16 periods), Montenegro (16 periods), 



# (a) Belgium and Luxembourg:

# Remark from the authors:
# We notice that the world bank provides timber_and_subsoil rents jointly for
#   Belgium-Luxembourg from 1966 to 1999, and then separately for Belgium from 2000 to 2001,
#   and for Luxembourg from 2000 to 2011. Next, we impute pasture rents for Belgium and 
#   Luxembourg separately by assuming that for years before 2000 these are split in 
#   the Belgium-Luxembourg variable  as they are split between the Belgium and Luxemburg
#   in 2000.


# They do:
###  gen  bel_2000=pasture_rent if country=="Belgium"     & year==2000
###  gen  lux_2000=pasture_rent if country=="Luxembourg" & year==2000
###  egen mbel_2000=max(bel_2000)
###  egen mlux_2000=max(lux_2000)
   

# Create new columns for bel_2000 and lux_2000
pwt_data[:, :bel_2000] = ifelse.((pwt_data[:, :country] .== "Belgium") .& (pwt_data[:, :year] .== 2000), pwt_data[:, :pasture_rent], missing)
pwt_data[:, :lux_2000] = ifelse.((pwt_data[:, :country] .== "Luxembourg") .& (pwt_data[:, :year] .== 2000), pwt_data[:, :pasture_rent], missing)
# Calculate the maximum values for bel_2000 and lux_2000
mbel_2000 = maximum(skipmissing(pwt_data[:, :bel_2000]))
mlux_2000 = maximum(skipmissing(pwt_data[:, :lux_2000]))
# Assign the value to every row in the column
pwt_data[:, :mbel_2000] = fill(mbel_2000, nrow(pwt_data))
pwt_data[:, :mlux_2000] = fill(mlux_2000, nrow(pwt_data))


# They do:
### gen  share_bel_2000=mbel_2000/(mbel_2000+mlux_2000) 
### gen pasture_rent_bel=share_bel_2000*pasture_rent if country=="Belgium-Luxembourg"
### bys year: egen mpasture_rent_bel=max(pasture_rent_bel)
### replace pasture_rent = mpasture_rent_bel if country=="Belgium" & year<2000	

# Create share_bel_2000
pwt_data[!, :share_bel_2000] .= pwt_data.mbel_2000 ./ (pwt_data.mbel_2000 .+ pwt_data.mlux_2000)
# Compute pasture_rent_bel
pwt_data[!, :pasture_rent_bel] .= ifelse.(
    pwt_data.country .== "Belgium-Luxembourg",
    pwt_data.share_bel_2000 .* pwt_data.pasture_rent,
    missing
)
# Compute mpasture_rent_bel for each year
mpasture_rent_bel = combine(
    groupby(pwt_data, :year),
    :pasture_rent_bel => (x -> isempty(skipmissing(x)) ? missing : only(skipmissing(x))) => :mpasture_rent_bel
)
# Add `mpasture_rent_bel` back to the main dataset
pwt_data = leftjoin(pwt_data, mpasture_rent_bel, on=:year)

# Replace `pasture_rent` with `mpasture_rent_bel` for Belgium before 2000
pwt_data[!, :pasture_rent] .= ifelse.(
    (pwt_data.country .== "Belgium") .&& (pwt_data.year .< 2000),
    pwt_data.mpasture_rent_bel,
    pwt_data.pasture_rent
)

#Checking
#   belgium_rows_updated = filter(row -> row.country == "Belgium" && row.year < 2000, pwt_data)
#    println(first(select(belgium_rows_updated, [:year, :country, :pasture_rent, :mpasture_rent_bel]), 10)) 
# the numbers check



# Now we do the same with Luxembourg
# Create share_lux_2000
pwt_data[!, :share_lux_2000] .= pwt_data.mlux_2000 ./ (pwt_data.mbel_2000 .+ pwt_data.mlux_2000)
# Compute pasture_rent_lux
pwt_data[!, :pasture_rent_lux] .= ifelse.(
    pwt_data.country .== "Belgium-Luxembourg",
    pwt_data.share_lux_2000 .* pwt_data.pasture_rent,
    missing
)
# Compute mpasture_rent_lux for each year
mpasture_rent_lux = combine(
    groupby(pwt_data, :year),
    :pasture_rent_lux => (x -> isempty(skipmissing(x)) ? missing : only(skipmissing(x))) => :mpasture_rent_lux
)
# Add `mpasture_rent_lux` back to the main dataset
pwt_data = leftjoin(pwt_data, mpasture_rent_lux, on=:year)
# Replace `pasture_rent` with `mpasture_rent_lux` for Luxembourg before 2000
pwt_data[!, :pasture_rent] .= ifelse.(
    (pwt_data.country .== "Luxembourg") .&& (pwt_data.year .< 2000),
    pwt_data.mpasture_rent_lux,
    pwt_data.pasture_rent
)

# Checking
#   luxembourg_rows_updated = filter(row -> row.country == "Luxembourg" && row.year < 2000, pwt_data)
#   println(first(select(luxembourg_rows_updated, [:year, :country, :pasture_rent, :mpasture_rent_lux]), 10)) 
# The numbers check.




# Sort by `country` and `year`
sort!(pwt_data, [:country, :year])
# Drop columns from `bel_2000` to `mpasture_rent_lux`
select!(pwt_data, Not([:bel_2000, :lux_2000, :mbel_2000, :mlux_2000, :share_bel_2000, :pasture_rent_bel, :mpasture_rent_bel]))

# Checking
#   Filter rows
#       bel_lux_rows = filter(
#        row -> row.country in ["Belgium", "Luxembourg"],
#        pwt_data
#        )
#   Inspecting rows
#       println(select(bel_lux_rows, [:country, :countrycode, :year, :pasture_rent])) 
# Numbers check






# (b) Czech Rep. and Slovakia Rep.

# Note from the authors:
# Simlarly, the World Bank provides pasture land rents jointly for Czechoslovakia 
# from 1966 to 1992, and then separately for Czech Rep. from 1993 to 2011 and 
# Slovakia Rep. from 1993 to 2011. Next, we impute pasture rents for Czech Rep. and 
# Slovakia Rep. separately by assuming that for years before 1993 these rents are split
# in Czechoslovakia variable as they are split between the Czech Rep and the Slovakia Rep. 
# in 1993.

# They do:
### gen  cze_1993=pasture_rent if country=="Czech Republic"  & year==1993
### gen  slo_1993=pasture_rent if country=="Slovak Republic" & year==1993
### egen mcze_1993=max(cze_1993)
### egen mslo_1993=max(slo_1993)


# Generate `cze_1993` and `slo_1993`
pwt_data[!, :cze_1993] = ifelse.((pwt_data[!, :country] .== "Czech Republic") .& (pwt_data[!, :year] .== 1993), pwt_data[!, :pasture_rent], missing)
pwt_data[!, :slo_1993] = ifelse.((pwt_data[!, :country] .== "Slovak Republic") .& (pwt_data[!, :year] .== 1993), pwt_data[!, :pasture_rent], missing)
# Compute maximum values
mcze_1993 = maximum(skipmissing(pwt_data[!, :cze_1993]))
mslo_1993 = maximum(skipmissing(pwt_data[!, :slo_1993]))
# Add the maximum values to the dataset (optional)
pwt_data[!, :mcze_1993] .= mcze_1993
pwt_data[!, :mslo_1993] .= mslo_1993


# They do
### gen  share_cze_1993=mcze_1993/(mcze_1993+mslo_1993) 
### gen pasture_rent_cze=share_cze_1993*pasture_rent if country=="Czechoslovakia"
### bys year: egen mpasture_rent_cze=max(pasture_rent_cze)
### replace pasture_rent = mpasture_rent_cze if country=="Czech Republic" & year<1993	

# Generate `share_cze_1993`
share_cze_1993 = mcze_1993 / (mcze_1993 + mslo_1993)
# Add as a new column
pwt_data[!, :share_cze_1993] .= share_cze_1993
# Generate `pasture_rent_cze` for Czechoslovakia
pwt_data[!, :pasture_rent_cze] = ifelse.(
    pwt_data[!, :country] .== "Czechoslovakia",
    share_cze_1993 * pwt_data[!, :pasture_rent],
    missing
)
# Filter rows where `pasture_rent_cze` is not missing
filtered_data = filter(row -> !ismissing(row[:pasture_rent_cze]), pwt_data)
# Compute max of `pasture_rent_cze` per year with an init value
mpasture_rent_cze = combine(
    groupby(filtered_data, :year),
    :pasture_rent_cze => (x -> maximum(skipmissing(x); init=0)) => :mpasture_rent_cze
)
# Merge the max values back into the main dataset
pwt_data = leftjoin(pwt_data, mpasture_rent_cze, on=:year)
# Replace `pasture_rent` for Czech Republic before 1993
pwt_data[!, :pasture_rent] = ifelse.(
    (pwt_data[!, :country] .== "Czech Republic") .& (pwt_data[!, :year] .< 1993),
    pwt_data[!, :mpasture_rent_cze],
    pwt_data[!, :pasture_rent]
)
# Inspecting rows for Czechoslovakia and Czech Republic
#   cze_rows = filter(row -> row[:country] in ["Czechoslovakia", "Czech Republic"], pwt_data)
#   relevant_columns = [:country, :year, :pasture_rent, :pasture_rent_cze, :mpasture_rent_cze, :share_cze_1993]
#   println(first(cze_rows[:, relevant_columns],10))
# The numbers check



#Now moving on with Slovakia
#They do:
### gen  share_slo_1993=mslo_1993/(mcze_1993+mslo_1993) 
### gen pasture_rent_slo=share_slo_1993*pasture_rent if country=="Czechoslovakia"
### bys year: egen mpasture_rent_slo=max(pasture_rent_slo)
### replace pasture_rent = mpasture_rent_slo if country=="Slovak Republic" & year<1993

# Generate `share_slo_1993`
share_slo_1993 = mslo_1993 / (mcze_1993 + mslo_1993)
# Add as a new column
pwt_data[!, :share_slo_1993] .= share_slo_1993
# Generate `pasture_rent_cze` for Czechoslovakia
pwt_data[!, :pasture_rent_slo] = ifelse.(
    pwt_data[!, :country] .== "Czechoslovakia",
    share_slo_1993 * pwt_data[!, :pasture_rent],
    missing
)
# Filter rows where `pasture_rent_cze` is not missing
filtered_data = filter(row -> !ismissing(row[:pasture_rent_slo]), pwt_data)
# Compute max of `pasture_rent_slo` per year with an init value
mpasture_rent_slo = combine(
    groupby(filtered_data, :year),
    :pasture_rent_slo => (x -> maximum(skipmissing(x); init=0)) => :mpasture_rent_slo
)
# Merge the max values back into the main dataset
pwt_data = leftjoin(pwt_data, mpasture_rent_slo, on=:year)
# Replace `pasture_rent` for Czech Republic before 1993
pwt_data[!, :pasture_rent] = ifelse.(
    (pwt_data[!, :country] .== "Slovak Republic") .& (pwt_data[!, :year] .< 1993),
    pwt_data[!, :mpasture_rent_slo],
    pwt_data[!, :pasture_rent]
)

# Inspecting rows for Czechoslovakia and Slovakia
#   slo_rows = filter(row -> row[:country] in ["Slovak Republic"], pwt_data)
#   relevant_columns = [:country, :year, :pasture_rent, :pasture_rent_slo, :mpasture_rent_slo, :share_slo_1993]
#   println(first(slo_rows[:, relevant_columns],10))
# The numbers check



# They do:
### sort country year	
### drop cze_1993-mpq_rent_a_slo
### drop if country=="Czechoslovakia"


# Sort the dataset by country and year
pwt_data = sort(pwt_data, [:country, :year])
# Drop the intermediate columns used for calculations
select!(pwt_data, Not([:cze_1993, :slo_1993, :mcze_1993, :mslo_1993, :share_cze_1993, :share_slo_1993, :pasture_rent_cze, :pasture_rent_slo, :mpasture_rent_cze, :mpasture_rent_slo]))
# Drop rows where the country is "Czechoslovakia"
pwt_data = filter(row -> row[:country] != "Czechoslovakia", pwt_data)

# Checking
#     Check unique countries to ensure "Czechoslovakia" is removed
#         println(unique(pwt_data[!, :country])) 
#     Filter for rows belonging to Czech Republic and Slovak Republic
#         czech_slovak_rows = filter(row -> row[:country] in ["Czech Republic", "Slovak Republic"], pwt_data)
#     Select relevant columns for inspection
#         relevant_columns = [:country, :year, :pasture_rent]
#         println(first(czech_slovak_rows[:, relevant_columns], 10))
# Everything matches



# (c) Serbia and Montenegro

# Note from the authors:
# Finally, the World Bank provides pasture land rents jointly for Serbia and Montenegro 
# from 1992 to 2005, and then separately for Serbia 2006 to 2011 and Montenegro 2006 to 2011.
# Next, we impute pasture rents for Serbia and 
# Montenegro separately by assuming that for years before 2006 these are split in 
# the "Serbia and Montenegro" variable as they are split between Serbia and Montenegro
# in 2006.


# They do:
### gen  serb_2006=pq_rent_a if country=="Serbia"     & year==2006
### gen  mont_2006=pq_rent_a if country=="Montenegro" & year==2006
### egen mserb_2006=max(serb_2006)
### egen mmont_2006=max(mont_2006)


# Filter rows for Serbia and Montenegro in 2006
serbia_2006 = filter(row -> row.country == "Serbia" && row.year == 2006, pwt_data)
montenegro_2006 = filter(row -> row.country == "Montenegro" && row.year == 2006, pwt_data)
# Create `serb_2006` and `mont_2006` columns
pwt_data[!, :serb_2006] .= ifelse.((pwt_data.country .== "Serbia") .&& (pwt_data.year .== 2006), pwt_data.pasture_rent, missing)
pwt_data[!, :mont_2006] .= ifelse.((pwt_data.country .== "Montenegro") .&& (pwt_data.year .== 2006), pwt_data.pasture_rent, missing)
# Inspecting the relevant rows
# println(select(filter(row -> row.year == 2006, pwt_data), [:country, :year, :pasture_rent, :serb_2006, :mont_2006]))

# Compute maximum values
mserb_2006 = maximum(skipmissing(pwt_data.serb_2006))
mmont_2006 = maximum(skipmissing(pwt_data.mont_2006))
# Add maximum values back to the dataset
pwt_data[!, :mserb_2006] .= mserb_2006
pwt_data[!, :mmont_2006] .= mmont_2006
# Inspecting to ensure values are correctly assigned
#println(select(filter(row -> row.year == 2006, pwt_data), [:country, :year, :serb_2006, :mont_2006, :mserb_2006, :mmont_2006]))



# They do:
### gen  share_serb_2006=mserb_2006/(mserb_2006+mmont_2006) 
### gen pq_rent_a_serb=share_serb_2006*pq_rent_a if country=="Serbia and Montenegro"
### bys year: egen mpq_rent_a_serb=max(pq_rent_a_serb)
### replace pq_rent_a = mpq_rent_a_serb if country=="Serbia" & year<2006	

# Compute `share_serb_2006`
share_serb_2006 = mserb_2006 / (mserb_2006 + mmont_2006)
# Add the value as a column to the dataset
pwt_data[!, :share_serb_2006] .= share_serb_2006
# Create `pasture_rent_serb` column
pwt_data[!, :pasture_rent_serb] .= ifelse.(
    (pwt_data.country .== "Serbia and Montenegro"),
    share_serb_2006 .* pwt_data.pasture_rent,
    missing
)

# Compute maximum for `pasture_rent_serb` by year, handling empty groups
mpasture_rent_serb = combine(
    groupby(pwt_data, :year),
    :pasture_rent_serb => (x -> maximum(skipmissing(x); init=0)) => :mpasture_rent_serb
)

# Add computed values back to the main DataFrame
pwt_data = leftjoin(pwt_data, mpasture_rent_serb, on=:year)

# Replace `pasture_rent` for Serbia for years before 2006
pwt_data[!, :pasture_rent] .= ifelse.(
    (pwt_data.country .== "Serbia") .&& (pwt_data.year .< 2006),
    pwt_data.mpasture_rent_serb,
    pwt_data.pasture_rent
)

# Inspecting relevant rows to confirm changes
# serbia_rows = filter(row -> row.country == "Serbia" && row.year < 2006, pwt_data)
# println(select(serbia_rows, [:country, :year, :pasture_rent, :mpasture_rent_serb]))
# numbers check


# They do:
### gen  share_mont_2006=mmont_2006/(mserb_2006+mmont_2006) 
### gen pq_rent_a_mont=share_mont_2006*pq_rent_a if country=="Serbia and Montenegro"
### bys year: egen mpq_rent_a_mont=max(pq_rent_a_mont)
### replace pq_rent_a = mpq_rent_a_mont if country=="Montenegro" & year<2006	

# Compute `share_mont_2006`
share_mont_2006 = mmont_2006 / (mserb_2006 + mmont_2006)
# Add the value as a column to the dataset
pwt_data[!, :share_mont_2006] .= share_mont_2006
# Create `pasture_rent_mont` column
pwt_data[!, :pasture_rent_mont] .= ifelse.(
    (pwt_data.country .== "Serbia and Montenegro"),
    share_mont_2006 .* pwt_data.pasture_rent,
    missing
)
# Compute maximum for `pasture_rent_mont` by year, handling empty groups
mpasture_rent_mont = combine(
    groupby(pwt_data, :year),
    :pasture_rent_mont => (x -> maximum(skipmissing(x); init=0)) => :mpasture_rent_mont
)
# Add computed values back to the main DataFrame
pwt_data = leftjoin(pwt_data, mpasture_rent_mont, on=:year)
# Replace `pasture_rent` for Montenegro for years before 2006
pwt_data[!, :pasture_rent] .= ifelse.(
    (pwt_data.country .== "Montenegro") .&& (pwt_data.year .< 2006),
    pwt_data.mpasture_rent_mont,
    pwt_data.pasture_rent
)

# Checking
# serbia_rows = filter(row -> row.country == "Serbia" && row.year < 2006, pwt_data)
# println(select(serbia_rows, [:country, :year, :pasture_rent, :mpasture_rent_serb]))



# They do:
### sort country year	
### drop serb_2006-mpq_rent_a_mont  

# Sort the dataset by country and year
sort!(pwt_data, [:country, :year])
# Drop intermediate columns
select!(pwt_data, Not([:serb_2006, :mont_2006, :mserb_2006, :mmont_2006, :mpasture_rent_serb, :mpasture_rent_mont]))



# Finally they do:
### keep if year>=minyear & year<maxyear & nominal_gdp~=.	
### g phi_NR_pasture = pasture_rent/nominal_gdp

# Filter the dataset based on the conditions
pwt_data = filter(
        row -> row.year >= minyear && row.year < maxyear && !ismissing(row.nominal_gdp),
        pwt_data)
# Generate `phi_NR_pasture`
pwt_data[!, :phi_NR_pasture] .= pwt_data.pasture_rent ./ pwt_data.nominal_gdp
# Inspect the first 10 rows of relevant columns
println(first(select(pwt_data, [:country, :year, :pasture_rent, :nominal_gdp, :phi_NR_pasture]), 10))

# Saving it : 
pwt_data_3 = copy(pwt_data)
CSV.write("output/pwt_data_3.csv", pwt_data_3)