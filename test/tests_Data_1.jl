using Replication_Monge_et_al_2019
using Test
using DataFrames
using StatFiles
using CSV

# Testing the filter_function! function :    
@testset "filter_function" begin
    @test ismissing(Replication_Monge_et_al_2019.filter_function!(missing))
    @test Replication_Monge_et_al_2019.filter_function!(200) == 200
    @test Replication_Monge_et_al_2019.filter_function!(0) == 0
    @test ismissing(Replication_Monge_et_al_2019.filter_function!(-100))
    @test ismissing(Replication_Monge_et_al_2019.filter_function!("this is a string"))
end

@testset "Data part 1" begin
    # Loading the data : 
    # This is the intermediate result gotten from the do file of the authors :
    cd(dirname(pathof(Replication_Monge_et_al_2019)))
    # splitdir(pwd())[2]
    cd("data")
    true_pwt_data_1 = DataFrame(load("true_pwt_data_1.dta"))

    @testset "Loading of own data - 1" begin
        cd(dirname(pathof(Replication_Monge_et_al_2019)))
        cd(splitdir(pwd())[1])
        cd("output")
        # Replication_Monge_et_al_2019.pwt_data_1
        a = CSV.read("pwt_data_1.csv", DataFrame)
        @test names(Replication_Monge_et_al_2019.pwt_data_1) == names(a)    
    end

    # Testing the loading :
    @testset "Loading of true data - 1 " begin
        # We sort it to have it in the same order as them : 
        sort!(true_pwt_data_1, [:country, :year])
        # This is our data : 
        # Replication_Monge_et_al_2019.pwt_data_1
        @test @isdefined true_pwt_data_1
    end 
    
    # Testing the size of the data :
    @testset "Size of data - 1 " begin
        @test size(true_pwt_data_1) == size(Replication_Monge_et_al_2019.pwt_data_1)
    end

    # Testing the names of the columns :
    @testset "Same variables - 1 " begin
        for n in names(true_pwt_data_1)
            @test n in names(Replication_Monge_et_al_2019.pwt_data_1)
        end
    end

    # Testing absolute equality of common columns : 
    @testset "Absolute equality of columns - 1 " begin
        for col in names(true_pwt_data_1)
            if col in names(Replication_Monge_et_al_2019.pwt_data_1)
                @test isequal(true_pwt_data_1[:,col], Replication_Monge_et_al_2019.pwt_data_1[:,col])
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
    @testset "Approximate equality of numerical columns - 1 " begin   
        for col in names(true_pwt_data_1)
            if col in names(Replication_Monge_et_al_2019.pwt_data_1)
                if (any(x -> x isa Number, true_pwt_data_1[:,col])) || (any(x -> x isa Number, Replication_Monge_et_al_2019.pwt_data_1[:,col]))
                    @test isapprox(to_number.(true_pwt_data_1[:,col]), to_number.(Replication_Monge_et_al_2019.pwt_data_1[:,col]); atol=10)
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
    @testset "Approximate equality of character columns - 1 " begin        
        for col in names(true_pwt_data_1)
            if col in names(Replication_Monge_et_al_2019.pwt_data_1)
                if (any(x -> x isa String, true_pwt_data_1[:,col])) || (any(x -> x isa String, Replication_Monge_et_al_2019.pwt_data_1[:,col]))
                    @test isequal(to_character.(true_pwt_data_1[:,col]), to_character.(Replication_Monge_et_al_2019.pwt_data_1[:,col]))
                end
            end
        end
    end
end


