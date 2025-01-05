using Replication_Monge_et_al_2019
using Test
using DataFrames
using StatFiles

# Testing the filter_function! function :    
@testset "filter_function.jl" begin
    @test ismissing(Replication_Monge_et_al_2019.filter_function!(missing))
    @test Replication_Monge_et_al_2019.filter_function!(200) == 200
    @test Replication_Monge_et_al_2019.filter_function!(0) == 0
    @test ismissing(Replication_Monge_et_al_2019.filter_function!(-100))
    @test ismissing(Replication_Monge_et_al_2019.filter_function!("this is a string"))
end

@testset "Data_part_1.jl" begin
    
    # Loading the data : 
    # This is the intermediate result gotten from the do file of the authors :
    cd(dirname(pathof(Replication_Monge_et_al_2019)))
    # splitdir(pwd())[2]
    cd("data")
    true_pwt_data_1 = DataFrame(load("true_pwt_data_1.dta"))
    # We sort it to have it in the same order as them : 
    sort!(true_pwt_data_1, [:country, :year])
    # This is our data : 
    # Replication_Monge_et_al_2019.pwt_data_1
    
    # Testing the size of the data :
    @testset "Size of data" begin
        @test size(true_pwt_data_1) == size(Replication_Monge_et_al_2019.pwt_data_1)
    end

    # When testing for perfect equality, we get a 'false' result :
    @testset "Absolute equality of data" begin
        @test (isequal(true_pwt_data_1[:,1:end .!= 61], Replication_Monge_et_al_2019.pwt_data_1[:,1:end .!= 61]))
    end

    # Testing the names of the columns :
    @testset "Names of columns" begin
        for n in names(true_pwt_data_1)
            @test n in names(Replication_Monge_et_al_2019.pwt_data_1)
        end
    end

    # findall(names(true_pwt_data_1) .!== names(Replication_Monge_et_al_2019.pwt_data_1)) # 61
    # findall(names(Replication_Monge_et_al_2019.pwt_data_1) .!== names(true_pwt_data_1)) # 61
    # names(true_pwt_data_1)[61]
    # names(Replication_Monge_et_al_2019.pwt_data_1)[61]

    
    @testset "Equality of columns" begin
        # The columns which are different are : 
        identical = []
        for col in 1:size(true_pwt_data_1)[2]
            @test isequal(true_pwt_data_1[:,col], Replication_Monge_et_al_2019.pwt_data_1[:,col])
            tmp = isequal(true_pwt_data_1[:,col], Replication_Monge_et_al_2019.pwt_data_1[:,col])
            push!(identical, tmp)
        end
        # different_columns = findall(==(false), identical)
    end 
    
    # We could at least compare only numerical columns, with the isapprox function :
    @testset "Approximate equality of numerical columns" begin
    #     approximately = []
    #     for col in 1:size(true_pwt_data_1)[2]
    #         if true_pwt_data_1[:,col] isa Number || Replication_Monge_et_al_2019.pwt_data_1[:,col] isa Number
    #             @test isapprox(true_pwt_data_1[:,col], Replication_Monge_et_al_2019.pwt_data_1[:,col])
    #             tmp2 = isapprox(true_pwt_data_1[:,col], Replication_Monge_et_al_2019.pwt_data_1[:,col])
    #         end
    #         push!(approximately, tmp2)
    #     end
    
        for col in 1:size(true_pwt_data_1)[2]
            if (any(x -> x isa Number, true_pwt_data_1[:,col])) || (any(x -> x isa Number, Replication_Monge_et_al_2019.pwt_data_1[:,col]))
                @test isapprox(true_pwt_data_1[:,col], Replication_Monge_et_al_2019.pwt_data_1[:,col]; atol=0.5)
            end
        end
    end

    # isapprox(1,1.5; atol=1e-7)
    @testset "Approximate equality of character columns" begin        
        for col in 1:size(true_pwt_data_1)[2]
            if (any(x -> x isa String, true_pwt_data_1[:,col])) || (any(x -> x isa String, Replication_Monge_et_al_2019.pwt_data_1[:,col]))
                @test isequal(true_pwt_data_1[:,col], Replication_Monge_et_al_2019.pwt_data_1[:,col]; atol=0.5)
            end
        end
    end

    # typeof(true_pwt_data_1[!,4])
    # Vector{Union{Missing, Number}}
    # if there is a number in the column  
    # # approximately = []
    # # for col in 1:size(true_pwt_data_1)[2]
    # #     true_pwt_data_1[:,col] isa Number
    # # end

end