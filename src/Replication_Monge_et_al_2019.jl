module Replication_Monge_et_al_2019

    """
    This function is a test.
    We can use it as following : 

    test_function()

    It prints "The Replication_Monge_et_al_2019 module is loaded.".
    """ 
    test_function() = print("The Replication_Monge_et_al_2019 module is loaded.")

    # Replicating the data of the article : 
    include("Data_work.jl")

    # Replicating the results of the second part of the article : 
    include("Part_2.jl")

    # Replicating the results of the third part of the article : 
    include("Part_3.jl")


    # The function run() should call all the necessary functions to get the obtained results : 
    """
    The function `run()` call all the results obtained from the replication attempt.
    It produces files and save them in the `output` folder.
    """
    function Base.run()

        # # Part 1 :
        # create_data()

        # # Part 2 :
        create_table_1()
        create_figure_1()
        create_figure_2()
        # create_table_2()
        create_figure_3()

        # # Part 3 : 
        create_figure_4()
        create_table_3()
        create_table_4()
        create_table_5()
    end

    """
    The function `delete_all()` deletes the all the files containing
    the replication results of the package, if the present working directory has a folder `output` containing it.
    
    *Warning* : The function throws an error if any output file is missing. 
    
    """
    function delete_all()
        delete_table_1()
        delete_figure_1()
        delete_figure_2()
        delete_figure_3()
        delete_figure_4()
        delete_table_3()
        delete_table_4()
        delete_table_5()
    end

    # We can make the functions available by using the export function to export only the chosen ones : 
    export test_function
    
    export run 
    export delete_all
    
    export create_table_1
    export delete_table_1
    export create_figure_1
    export delete_figure_1
    export create_figure_2
    export delete_figure_2
    export create_figure_3
    export delete_figure_3
    export create_figure_4
    export delete_figure_4

    export create_table_3
    export delete_table_3

    export create_table_4
    export delete_table_4

    export create_table_5
    export delete_table_5

end
