using Replication_Monge_et_al_2019
using Test
using DataFrames
using StatFiles

@testset "Data final part" begin


    # Loading the data : 
    # This is the final dataset gotten from the do file of the authors :
    cd(dirname(pathof(Replication_Monge_et_al_2019)))
    # splitdir(pwd())[2]
    cd("data")
    MSS_NRshares = DataFrame(load("MSS_NRshares.dta"))

    # Testing the loading:
    @testset "Loading data - final " begin
        # We sort it to have it in the same order as them : 
        sort!(MSS_NRshares, [:country, :year])
        # This is our data : 
        # Replication_Monge_et_al_2019.pwt_data_3
        @test @isdefined MSS_NRshares
    end 

    # Testing the size of the data :
    @testset "Size of data - final " begin
        @test size(MSS_NRshares) == size(Replication_Monge_et_al_2019.pwt_data)
    end

    # Testing the names of the columns :
    @testset "Same variables - final " begin
        for n in names(MSS_NRshares)
            @test n in names(Replication_Monge_et_al_2019.pwt_data)
        end
    end

    # Testing absolute equality of common columns : 
    @testset "Absolute equality of columns - final " begin
        for col in names(MSS_NRshares)
            if col in names(Replication_Monge_et_al_2019.pwt_data)
                @test isequal(MSS_NRshares[:,col], Replication_Monge_et_al_2019.pwt_data[:,col])
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
    @testset "Approximate equality of numerical columns - final " begin   
        for col in names(MSS_NRshares)
            if col in names(Replication_Monge_et_al_2019.pwt_data)
                if (any(x -> x isa Number, MSS_NRshares[:,col])) || (any(x -> x isa Number, Replication_Monge_et_al_2019.pwt_data[:,col]))
                    # isapprox(unique(MSS_NRshares[:,col]), unique(Replication_Monge_et_al_2019.pwt_data[:,col]))
                    # @test isapprox(
                    #   print(MSS_NRshares[:,col])
                    #   print(Replication_Monge_et_al_2019.pwt_data[:,col])
                    # numerical_columns += 1
                    # missing_to_zero.(MSS_NRshares[:,col])
                    @test isapprox(to_number.(MSS_NRshares[:,col]), to_number.(Replication_Monge_et_al_2019.pwt_data[:,col]); atol=10)
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

    @testset "Approximate equality of character columns - final " begin
        for col in names(MSS_NRshares)
            if col in names(Replication_Monge_et_al_2019.pwt_data)
                if (any(x -> x isa String, MSS_NRshares[:,col])) || (any(x -> x isa String, Replication_Monge_et_al_2019.pwt_data[:,col]))
                    # character_columns += 1
                    @test isequal(to_character.(MSS_NRshares[:,col]), to_character.(Replication_Monge_et_al_2019.pwt_data[:,col]))
                end
            end
        end
    end
end