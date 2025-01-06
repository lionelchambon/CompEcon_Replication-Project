@testset "Data part 2" begin
    
    # Loading the data : 
    # This is the intermediate result gotten from the do file of the authors :
    cd(dirname(pathof(Replication_Monge_et_al_2019)))
    # splitdir(pwd())[2]
    cd("data")
    true_pwt_data_2 = DataFrame(load("true_pwt_data_2.dta"))

    # Testing the loading :
    @testset "Loading data - 2 " begin
        # We sort it to have it in the same order as them : 
        sort!(true_pwt_data_2, [:country, :year])
        # This is our data : 
        # Replication_Monge_et_al_2019.pwt_data_1
        @test @isdefined true_pwt_data_2
    end 
    
    # Testing the size of the data :
    @testset "Size of data - 2 " begin
        @test size(true_pwt_data_2) == size(Replication_Monge_et_al_2019.pwt_data_2)
    end

    # Testing the names of the columns :
    @testset "Same variables - 2 " begin
        for n in names(true_pwt_data_2)
            @test n in names(Replication_Monge_et_al_2019.pwt_data_2)
        end
    end

    # Testing absolute equality of common columns : 
    @testset "Absolute equality of columns - 2 " begin
        for col in names(true_pwt_data_2)
            if col in names(Replication_Monge_et_al_2019.pwt_data_2)
                @test isequal(true_pwt_data2[:,col], Replication_Monge_et_al_2019.pwt_data_2[:,col])
            end
        end
    end

    # We now approximately test for each column. 
    # Given the important number of missing values, it is important to take them into account when comparing DataFrames. 
    # We could at least compare only numerical columns, with the isapprox function :
    # To convert all the values to numbers :
    function to_number(a)
        if a isa Number
            return a
        else
            return a = 0
        end
    end
    @testset "Approximate equality of numerical columns - 2 " begin   
        for col in names(true_pwt_data_2)
            if col in names(Replication_Monge_et_al_2019.pwt_data_2)
                if (any(x -> x isa Number, true_pwt_data_2[:,col])) || (any(x -> x isa Number, Replication_Monge_et_al_2019.pwt_data_2[:,col]))
                    # isapprox(unique(true_pwt_data_1[:,col]), unique(Replication_Monge_et_al_2019.pwt_data_1[:,col]))
                    # @test isapprox(
                    #   print(true_pwt_data_1[:,col])
                    #   print(Replication_Monge_et_al_2019.pwt_data_1[:,col])
                    # numerical_columns += 1
                    # missing_to_zero.(true_pwt_data_1[:,col])
                    @test isapprox(to_number.(true_pwt_data_2[:,col]), to_number.(Replication_Monge_et_al_2019.pwt_data_2[:,col]); atol=10)
                end
            end
        end
    end
    
    # To convert all the values to strings :
    function to_character(a)
        if a isa String
            return a
        else
            return a = "String"
        end
    end
    @testset "Approximate equality of character columns - 2 " begin
        for col in names(true_pwt_data_2)
            if col in names(Replication_Monge_et_al_2019.pwt_data_2)
                if (any(x -> x isa String, true_pwt_data_2[:,col])) || (any(x -> x isa String, Replication_Monge_et_al_2019.pwt_data_2[:,col]))
                    # character_columns += 1
                    @test isequal(to_character.(true_pwt_data_2[:,col]), to_character.(Replication_Monge_et_al_2019.pwt_data_2[:,col]))
                end
            end
        end
    end
end
