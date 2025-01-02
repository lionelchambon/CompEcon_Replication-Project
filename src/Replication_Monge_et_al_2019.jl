module Replication_Monge_et_al_2019

# Write your package code here.

"""
This function is a test.
We can use it as following : 

test_function() # Hello world

It prints "hello world".
""" 
test_function() = print("Hello world")

# Replicating the data of the article : 
include("Data_work.jl")

# Replicating the results of the second part of the article : 
include("Part_2.jl")

# Replicating the results of the third part of the article : 
# include("Results_part_3.jl")

# Replicating the results of the fourth part of the article : 
# include("Results_part_4.jl")

# We can make the functions available by using the export function to export only the chosen ones.
# export

end
