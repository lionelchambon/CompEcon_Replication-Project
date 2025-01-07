using Replication_Monge_et_al_2019
using Documenter

DocMeta.setdocmeta!(Replication_Monge_et_al_2019, :DocTestSetup, :(using Replication_Monge_et_al_2019); recursive=true)

makedocs(;
    modules=[Replication_Monge_et_al_2019],
    authors="CHAMBON Lionel, COMPÉRAT Étienne, and GUGELMO CAVALHEIRO DIAS Paulo",
    sitename="Replication_Monge_et_al_2019.jl",
    format=Documenter.HTML(;
        canonical="https://Paulogcd.github.io/Replication_Monge_et_al_2019.jl/dev",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Reference" => "reference.md"
    ],
)

deploydocs(;
    repo="github.com/Paulogcd/Replication_Monge_et_al_2019.jl/dev",
    devbranch="main",
)
