# This file collects common elements that are necessary for computations in different parts. 

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