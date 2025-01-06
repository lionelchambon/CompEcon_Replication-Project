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

    """
    The function `delete_all()` deletes the all the files containing
    the replication results of the package, if the present working directory has a folder `output` containing it.
    """
    function delete_all()
        delete_table_1()
        delete_figure_1()
        delete_figure_2()
        delete_figure_3()
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
end
