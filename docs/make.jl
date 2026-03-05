using Documenter, ImageUtils

@warn "Some errors have been suppressed. Should be checked closely!"

makedocs(
    modules = [ImageUtils],
    format = Documenter.HTML(prettyurls = false, size_threshold = 500000,),
    sitename = "ImageUtils.jl",
    authors = "Tobias Knopp et al.",
    pages = [
        "Home" => "index.md","index.md"
    ],
    warnonly = [:missing_docs],
)

deploydocs(
    repo = "github.com/tknopp/ImageUtils.jl.git",
)