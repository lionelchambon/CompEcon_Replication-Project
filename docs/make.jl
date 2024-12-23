using Replication_Monge_et_al_2019
using Documenter

DocMeta.setdocmeta!(Replication_Monge_et_al_2019, :DocTestSetup, :(using Replication_Monge_et_al_2019); recursive=true)

makedocs(;
    modules=[Replication_Monge_et_al_2019],
    authors="Paulogcd <gugelmopaulo@gmail.com> and contributors",
    sitename="Replication_Monge_et_al_2019.jl",
    format=Documenter.HTML(;
        canonical="https://Paulogcd.github.io/Replication_Monge_et_al_2019.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Reference" => "reference.md"
    ],
)

deploydocs(;
    repo="github.com/Paulogcd/Replication_Monge_et_al_2019.jl",
    devbranch="main",
)
