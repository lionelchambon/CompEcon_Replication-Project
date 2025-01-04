# This file is dedicated to replicate the results of Part 2 in the article. ###################################################

using StatFiles
using DataFrames
using Statistics

### Table 1 : 

# We first load the data : 
data = DataFrame(load("src/data/MSS_NRshares.dta"))
# summary(data)

# Then, we only select data from year 2000 :
data_2000 = DataFrame(data[data.year .== 2000, :])
# data_2000

# The authors use a sample of 79 and 76 countries, detailed in the appendix.
# To reconstruct the same, we first create an array of 79 countries, used for benchmark in the article : 

benchmark_79 = [
    
    # Africa :
    "Burkina Faso",
    "Cote dIvoire",
    "Cameroon",
    "Kenya",
    "Morocco",
    "Mozambique",
    "Niger",
    "Nigeria",
    "Senegal",
    "Tunisia",
    "Tanzania",
    "South Africa",
    "Zimbabwe",

    # Asia :
    "Bahrain",
    "China",
    "Hong Kong",
    "Indonesia",
    "India",
    "Iran",
    "Israel",
    "Jordan",
    "Korea, Republic of",
    "Kuwait",
    "Sri Lanka",
    "Malaysia",
    "Oman",
    "Philippines",
    "Qatar",
    "Saudi Arabia",
    "Singapore",
    "Thailand",
    "Turkey",
    "Taiwan",

    # Europe :
    "Austria",
    "Belgium",
    "Bulgaria",
    "Switzerland",
    "Cyprus",
    "Germany",
    "Denmark",
    "Spain",
    "Finland",
    "France", 
    "United Kingdom",
    "Greece",
    "Hungary",
    "Ireland",
    "Iceland",
    "Italy",
    "Luxembourg",
    "Malta",
    "Netherlands", 
    "Norway",
    "Poland",
    "Portugal",
    "Sweden",

    # South America
    "Argentina",
    "Barbados",
    "Bolivia",
    "Brazil",
    "Chile",
    "Colombia",
    "Ecuador",
    "Costa Rica",
    "Dominican Republic",
    "Guatemala",
    "Honduras",
    "Jamaica",
    "Mexico",
    "Panama",
    "Peru",
    "Paraguay",
    "Trinidad & Tobago",
    "Uruguay",

    # Oceania :
    "Australia",
    "New Zealand",

    # Others :
    "Japan",
    "United States",
    "Canada"]

# The authors exlude three countries, because these countries do not have data on human capital, to create another set of 76 countries :  
to_exclude = ["Burkina Faso", "Nigeria", "Oman"]
benchmark_76 = filter(e->e ∉ to_exclude,benchmark_79)

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
sum(isin(benchmark_76,data_2000[:,"country"])) == 76
sum(isin(benchmark_79,data_2000[:,"country"])) == 79

# Then, we compute the statistics of each variable for the sample of 79 countries : 

# means : 
mean_NR             = 100*mean(skipmissing(data_79[:, "phi_NR"]))
mean_timber         = 100*mean(skipmissing(data_79[:, "phi_NR_timber"]))
mean_subsoil        = 100*mean(skipmissing(data_79[:, "phi_NR_subsoil"]))
mean_cropland       = 100*mean(skipmissing(data_79[:, "phi_NR_crop_pq_a"])) # This is false ?
mean_pastureland    = 100*mean(skipmissing(data_79[:, "phi_NR_pasture"]))

means = [mean_NR, mean_timber, mean_subsoil, mean_cropland, mean_pastureland]

# medians : 

median_NR             = 100*median(skipmissing(data_79[:, "phi_NR"]))
median_timber         = 100*median(skipmissing(data_79[:, "phi_NR_timber"]))
median_subsoil        = 100*median(skipmissing(data_79[:, "phi_NR_subsoil"]))
median_cropland       = 100*median(skipmissing(data_79[:, "phi_NR_crop_pq_a"]))
median_pastureland    = 100*median(skipmissing(data_79[:, "phi_NR_pasture"]))

medians = [median_NR, median_timber, median_subsoil, median_cropland, median_pastureland]

# Coefficient of variation : 

# The coefficient of variation is defined as the ratio between the standard deviation over the mean.

CV_NR             = 100*std(skipmissing(data_79[:, "phi_NR"]))/mean_NR
CV_timber         = 100*std(skipmissing(data_79[:, "phi_NR_timber"]))/mean_timber
CV_subsoil        = 100*std(skipmissing(data_79[:, "phi_NR_subsoil"]))/mean_subsoil
CV_cropland       = 100*std(skipmissing(data_79[:, "phi_NR_crop_pq_a"]))/2.26 # This is false ?
CV_pastureland    = 100*std(skipmissing(data_79[:, "phi_NR_pasture"]))/mean_pastureland

CVs = [CV_NR, CV_timber, CV_subsoil, CV_cropland, CV_pastureland]

# The last column is 
# the correlation between the variable and the countries’ per capita output levels

# We have to get the countries per capita outout level. 

Corr = zeros(5)

# Creating a Data Frame to get the Table 1 : 

Names = ["Natural Resources", "Timber", "Subsoil", "Crop Land", "Pasture Land"]

Table_1 = DataFrame(
    "Variable" => Names,
    "Mean" => means,
    "Median" => medians, 
    "Coefficient of Variation" => CVs,
    "Correlation with per capita output" => Corr
)

# Then, we should save this Table 1 in the 'output' folder. 

# Table 2 : (...)