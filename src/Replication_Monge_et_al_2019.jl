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

# Replicating the results of the fifth part of the article : 
# include("Results_part_5.jl")

# The function run() should call all the necessary functions to get the results : 
function run()

    # # Part 1 :
    # create_data()

    # # Part 2 :
    # create_table_1()
    # create_figure_1()
    # create_figure_2()
    # create_table_2()
    # create_figure_3()

    # # Part 3 : 
    # create_figure_4()
    # create_table_3()
    # create_table_4()

    # # Part 4 : 
    # create_figure_5()
    # create_table_6()
    # create_figure_6()
    # create_table_7()
    # create_figure_7()
    # create_figure_8()
    # create_figure_9()
    # create_table_8()

    # # Part 5 : 
    # create_table_9()
    # create_figure_10()
    # create_figure_11()
end

# We can make the functions available by using the export function to export only the chosen ones : 
export run

end
