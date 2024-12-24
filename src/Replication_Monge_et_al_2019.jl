module Replication_Monge_et_al_2019

# Write your package code here.

"""
This function is a test.
We can use it as following : 

test_function() # Hello world

It prints "hello world".
"""
test_function() = print("Hello world")

"""
This function adds two numbers.
"""
addition(x::Number,y::Number) = x + y

# We can also include other code files with the include function : 
include("Data_work.jl")

# We can make the functions available by using the export function to export only the chosen ones.
# export

end
