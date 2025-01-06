# using CairoMakie
# using DataFrames
# using PrettyTables
# 
# # Create a sample DataFrame
# df = DataFrame(Name = ["Alice", "Bob", "Charlie"], Age = [25, 30, 35])
# 
# # Convert the DataFrame to a PrettyTables string
# table_io = IOBuffer()
# pretty_table(df, backend = :text, out = table_io)
# table_text = String(take!(table_io))  # Extract the table as a string
# 
# # Create a CairoMakie plot
# f = Figure(resolution = (800, 600))
# 
# # Create an axis (though not really used for the table)
# ax = Axis(f[1, 1])
# 
# # Display the table as text in the plot
# text!(ax, 0.5, 0.5, table_text, align = :center)
# 
# # Save the figure as a PNG file
# savefig(f, "table_output.png")
# 
# println("Table saved as table_output.png")
# 
# # Show the plot (optional)
# display(f)
# 

# Maybe :
# using DataFrames, CSV
# using Cairo, Gadfly
# 
# data = CSV.read("simulate_public.csv")
# p = plot(data, x=:p, y=:Expected, Geom.point);
# img = SVG("public_plot.svg", 6inch, 4inch)
# draw(img, p)

# ?

# Or maybe : 
# using CSV
# using DataFrames
# using PrettyTables
# using CairoMakie
# 
# # Step 1: Load the CSV file into a DataFrame
# df = CSV.File("your_file.csv") |> DataFrame
# 
# # Step 2: Convert the DataFrame to a PrettyTables string
# table_io = IOBuffer()
# pretty_table(df, backend = :text, out = table_io)  # Render as text
# table_text = String(take!(table_io))  # Extract table as a string
# 
# # Step 3: Create a CairoMakie plot to display the table
# f = Figure(resolution = (800, 600))
# 
# # Create an axis (even though it's not really used for the table)
# ax = Axis(f[1, 1])
# 
# # Display the table text as an annotation
# text!(ax, 0.5, 0.5, table_text, align = :center)
# 
# # Step 4: Save the plot as a PNG file
# savefig(f, "table_output.png")
# 
# # Show the plot (optional)
# display(f)
# 
# println("Table saved as table_output.png")
# ? 