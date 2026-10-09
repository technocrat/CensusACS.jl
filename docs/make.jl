using Documenter
using MaterialDocs
using CensusACS

makedocs(;
    sitename = "CensusACS.jl",
    authors = "Richard Careaga <public@careaga.net>",
    modules = [CensusACS],
    format = Material3(;
        theme = :ocean_depth,
        dark_mode = :toggle,
        edit_link = "main",
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://technocrat.github.io/CensusACS.jl",
    ),
    repo = Remotes.GitHub("technocrat", "CensusACS.jl"),
    pages = [
        "Home" => "index.md",
        "API Reference" => "api/functions.md",
        "Examples" => "examples.md",
        "Contributing" => "contributing.md",
    ],
    checkdocs = :none,
)

deploydocs(;
    repo = "github.com/technocrat/CensusACS.jl.git",
    devbranch = "main",
)
