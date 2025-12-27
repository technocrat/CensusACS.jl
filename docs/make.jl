using Documenter
using CensusACS

makedocs(
    sitename = "CensusACS.jl Documentation",
    authors = "Richard Careaga",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://technocrat.github.io/CensusACS.jl",
        assets = String[],
    ),
    modules = [CensusACS],
    pages = [
        "Home" => "index.md",
        "API Reference" => "api/functions.md",
        "Examples" => "examples.md",
        "Contributing" => "contributing.md"
    ],
    repo = "https://github.com/technocrat/CensusACS.jl/blob/{commit}{path}#{line}",
    clean = true,
    checkdocs = :none,
    linkcheck = false,  # Set to true when URLs are finalized
)

# Uncomment this when ready to deploy to GitHub Pages
# deploydocs(
#     repo = "github.com/technocrat/ACS.jl.git",
#     target = "build",
#     branch = "gh-pages",
#     devbranch = "main",
# )
