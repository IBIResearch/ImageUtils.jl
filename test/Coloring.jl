@testset "Testing Coloring Submodule" begin

@test ColoringParams(0, 1, 0) == ColoringParams(0, 1, "gray")

Random.seed!(1)

N = 64
I = shepp_logan(N)

IC = colorize(I .- 1, -1.0, 0.0,colorschemes[:grays].colors,normalize=false)
@test typeof(IC) == Array{RGB{Float64}, 2}

exportImage("img/coloring1.png", IC)
@testImg("coloring1.png")

IC = colorize(I, 0.0, 1.0, cmap("viridis"),normalize=false)
exportImage("img/coloring2.png", IC)
@testImg("coloring2.png")

exportImage("img/coloring3.png", I, vmin=0.0, vmax=0.5, colormap="vangogh", normalize=true)
@testImg("coloring3.png")

# Movie

Itemp = Array(reshape(range(0,1,length=90000),30,30,100))
exportMovie("img/movie.gif", Itemp, vmin=0.0, vmax=1.0, colormap="viridis", normalize=true)
@testImg("movie.gif")

exportMovies("img/movie.gif", [Itemp,Itemp,Itemp])
@testImg("movie_xy.gif")
@testImg("movie_xz.gif")
@testImg("movie_yz.gif")


# Overlay

O = zeros(N,N)
O[10:30,10:30] .= 1.0

OC = colorize(O, ColoringParams(0,1,"red"), 0.0, 1.0)

over = overlay(IC, OC, cmap("red")[1])
exportImage("img/coloring4.png", over)
@testImg("coloring4.png")


over = blend(IC, OC)
exportImage("img/coloring5.png", over)
@testImg("coloring5.png")


I = reshape(shepp_logan(N),1,N,N)
O = reshape(O,1,N,N)
I = cat(I,O,dims=1)

OC = colorize(I, [ColoringParams(0,1,"gray"), ColoringParams(0,1,"red"),],
     [0.0,0.0], [1.0,1.0])

exportImage("img/coloring6.png", OC)
@testImg("coloring6.png")


## Complex coloring

# create 2D colorbar
hues = range(0,2π,length=50)
saturations = 0:0.05:1.0
HS = vec(tuple.(hues, saturations'))
D = kron(saturations,(exp.(im*hues))')
# complex coloring
Y = complexColoring(abs.(D), angle.(D))
exportImage("img/coloring7.png", Y)
@testImg("coloring7.png")

# normalizeGray
colormap = ImageUtils.ColorSchemes.phase
@test all(isapprox.(ImageUtils.normalizeGray(colormap[1]), RGB{Float64}(0.8979049716100672,0.6795060499249219,0.28645928277939586), rtol=1e-6))
@test @test_logs (:warn,"Normalization of gray value failed, g ≈ 0.056 is used. Use g >= 0.056 for a consistent normalization.") match_mode=:any all(isapprox.(ImageUtils.normalizeGray(colormap[1],0.05), RGB{Float64}(0.18396207457891003,0.0,0.0), rtol=1e-6))
@test @test_logs (:warn,"Normalization of gray value failed, g ≈ 0.925 is used. Use g <= 0.925 for a consistent normalization.") match_mode=:any all(isapprox.(ImageUtils.normalizeGray(colormap[1],0.95), RGB{Float64}(1.0,0.9603124734843839,0.5548057892335283), rtol=1e-6))

end

@testset "Testing Coloring Helpers" begin

# weighted_color_mean
@test ImageUtils.weighted_color_mean(0.5, RGB(1.0,0.0,0.0), RGB(0.0,0.0,1.0)) == RGB(0.5,0.0,0.5)
@test ImageUtils.weighted_color_mean(0.0, RGB(1.0,0.0,0.0), RGB(0.0,0.0,1.0)) == RGB(0.0,0.0,1.0)
@test ImageUtils.weighted_color_mean(1.0, RGB(1.0,0.0,0.0), RGB(0.0,0.0,1.0)) == RGB(1.0,0.0,0.0)
@test ImageUtils.weighted_color_mean(0.5, RGB{N0f8}(1,0,0), RGB{N0f8}(0,0,1)) isa RGB{N0f8}
@test_throws DomainError ImageUtils.weighted_color_mean(1.5, RGB(1.0,0.0,0.0), RGB(0.0,0.0,1.0))
@test_throws DomainError ImageUtils.weighted_color_mean(-0.1, RGB(1.0,0.0,0.0), RGB(0.0,0.0,1.0))

# getBounds
@test ImageUtils.getBounds(nothing, ColoringParams(0.2,0.8,"gray"), -1.0, 1.0) == (-0.6, 0.6000000000000001)

# ColoringParams index constructor
@test ColoringParams(0, 1, 1) == ColoringParams(0, 1, "blue")
@test ColoringParams(0, 1, 2) == ColoringParams(0, 1, "green")
@test_throws BoundsError ColoringParams(0, 1, length(existing_cmaps()))

# _colorize clamping and interpolation
cm3 = [RGB(0.0,0.0,0.0), RGB(0.5,0.5,0.5), RGB(1.0,1.0,1.0)]
@test ImageUtils._colorize(-5.0, 0.0, 1.0, cm3) == first(cm3)
@test ImageUtils._colorize(5.0, 0.0, 1.0, cm3) == last(cm3)
@test ImageUtils._colorize(0.5, 1.0, 1.0, cm3) == first(cm3)
@test ImageUtils._colorize(0.25, 0.0, 1.0, cm3) == RGB(0.25,0.25,0.25)
@test ImageUtils._colorize(0.75, 0.0, 1.0, cm3) == RGB(0.75,0.75,0.75)

# linearDodge
@test linearDodge([fill(RGB(0.2,0.0,0.0),2,2), fill(RGB(0.3,0.0,0.0),2,2)]) ≈ fill(RGB(0.5,0.0,0.0),2,2)
@test linearDodge([fill(RGB(0.8,0.0,0.0),2,2), fill(RGB(0.8,0.0,0.0),2,2)]) == fill(RGB(1.0,0.0,0.0),2,2)
@test linearDodge(fill(RGB(0.2,0.0,0.0),2,2), fill(RGB(0.3,0.0,0.0),2,2)) ≈ fill(RGB(0.5,0.0,0.0),2,2)
@test linearDodge([fill(RGB(0.3,0.0,0.0),2,2)]) == fill(RGB(0.3,0.0,0.0),2,2)
@test linearDodge([fill(RGB(0.2,0.0,0.0),2,2), fill(RGB(0.3,0.0,0.0),2,2)]) isa Matrix{RGB{Float64}}

# reorderColor
img = [RGB{N0f8}(1,0,0) RGB{N0f8}(0,1,0); RGB{N0f8}(0,0,1) RGB{N0f8}(1,1,1)]
rc = reorderColor(img)
@test size(rc) == (2,2,3)
@test eltype(rc) == UInt8
@test rc[:,:,1] == UInt8[0xff 0x00; 0x00 0xff]
@test rc[:,:,2] == UInt8[0x00 0xff; 0x00 0xff]
@test rc[:,:,3] == UInt8[0x00 0x00; 0xff 0xff]
@test reorderColor(rc) == img

# blend
@test blend(RGB(0.0,0.0,0.0), RGB(1.0,1.0,1.0), 0.5) == RGB(0.5,0.5,0.5)
@test blend(RGB(0.0,0.0,0.0), RGB(1.0,1.0,1.0), 0.0) == RGB(0.0,0.0,0.0)
@test blend(RGB(0.0,0.0,0.0), RGB(1.0,1.0,1.0), 1.0) == RGB(1.0,1.0,1.0)
@test blend(RGBA(0.0,0.0,0.0,0.5), RGBA(1.0,1.0,1.0,0.5)) ≈ RGBA(0.25,0.25,0.25,0.375)
@test blend(RGB(0.0,0.0,0.0), RGBA(1.0,1.0,1.0,0.25)) == RGB(0.25,0.25,0.25)

bg = fill(RGB{N0f8}(0,0,0),2,2)
fg = fill(RGBA{N0f8}(1,1,1,0.5),2,2)
@test blend(bg,fg) == fill(RGBA{N0f8}(0.5,0.5,0.5,1.0),2,2)
@test blend(bg,fg) isa Matrix{RGBA{N0f8}}

bg3 = fill(RGB{N0f8}(0,0,0),2,2,1)
fg4 = fill(RGBA{N0f8}(1,1,1,0.5),2,2,1,3)
@test size(blend(bg3,fg4)) == (2,2,1,3)
@test blend(bg3,fg4) isa Array{RGBA{N0f8},4}

# overlay
bg = fill(RGB{N0f8}(0,0,0),2,2)
fg = fill(RGBA{N0f8}(1,0,0,1),2,2)
fg[1,1] = RGBA{N0f8}(0,0,0,0)
o = overlay(bg, fg, RGBA{N0f8}(0,0,0,0))
@test o[1,1] == RGBA{N0f8}(0,0,0,1)
@test o[2,2] == fg[2,2]
@test o isa Matrix{RGBA{N0f8}}

bg3 = fill(RGB{N0f8}(0,0,0),2,2,1)
fg4 = fill(RGBA{N0f8}(1,1,1,0.5),2,2,1,3)
fg4[1,1,1,2] = RGBA{N0f8}(0,0,0,0)
o34 = overlay(bg3, fg4, RGBA{N0f8}(0,0,0,0))
@test size(o34) == (2,2,1,3)
@test o34[1,1,1,2] == RGBA{N0f8}(0,0,0,1)
@test o34[1,1,1,1] == fg4[1,1,1,1]

# cmap
@test cmap(RGB(1.0,0.0,0.0)) == RGBA{N0f8}[RGBA{N0f8}(0,0,0,0), RGBA{N0f8}(1,0,0,1)]
@test cmap([(1.0,0.0,0.0),(0.0,0.0,1.0)]) == RGBA{N0f8}[RGBA{N0f8}(1,0,0,1), RGBA{N0f8}(0,0,1,1)]
@test cmap([(1.0,0.0,0.0,0.5)]) == RGBA{N0f8}[RGBA{N0f8}(1,0,0,0.5)]
@test cmap("gray") == cmap(RGB(1.0,1.0,1.0))
@test cmap("blue") == cmap(RGB(0.0,0.0,1.0))
@test cmap("green") == cmap(parse(Colorant,"green"))
@test cmap("red") == cmap(RGB(1.0,0.0,0.0))
@test length(cmap("viridis")) == 256
@test first(cmap("viridis")).alpha == 0 && last(cmap("viridis")).alpha == 1
@test cmap("viridis") isa Vector{RGBA{N0f8}}
@test @test_logs (:warn,"doesnotexist is not existing in ColorSchemes.jl. Colorscheme grays is used instead.") match_mode=:any cmap("doesnotexist") == cmap("grays")

# existing_cmaps / important_cmaps
ec = existing_cmaps()
@test ec[1:4] == ["gray","blue","green","red"]
@test length(unique(ec)) == length(ec)
@test all(m -> m in ec, important_cmaps())
@test length(unique(important_cmaps())) == length(important_cmaps())
@test important_cmaps()[1:4] == ["gray","blue","green","red"]

# RGBAGradient
g = RGBAGradient([RGB(1.0,0.0,0.0), RGB(0.0,0.0,1.0)], 0.0, 1.0)
@test length(g) == 2
@test g isa Vector{RGBA{N0f8}}
@test alpha(g[1]) == 0 && alpha(g[2]) == 1
@test color(g[1]) == RGB{N0f8}(1,0,0) && color(g[2]) == RGB{N0f8}(0,0,1)
g2 = RGBAGradient([RGB(1.0,0.0,0.0), RGB(0.0,1.0,0.0), RGB(0.0,0.0,1.0)], 0.2, 0.8)
@test alpha(g2[1]) == 0.2 && alpha(g2[3]) == 0.8

# complexColoring
C = [1.0+0.0im 0.0+1.0im; -1.0+0.0im 0.0-1.0im]
@test complexColoring(C) == complexColoring(abs.(C), angle.(C))
@test complexColoring(abs.(C), angle.(C)) isa Matrix{RGBA{N0f8}}
@test complexColoring(abs.(C), angle.(C), normalizeG=false) != complexColoring(abs.(C), angle.(C))
@test size(complexColoring(abs.(C), angle.(C), amax=2.0)) == size(C)
@test complexColoring(abs.(C), angle.(C), amax=2.0) != complexColoring(abs.(C), angle.(C))
@test complexColoring(abs.(C), angle.(C), g=0.5) != complexColoring(abs.(C), angle.(C))

# colorize dispatch on multi-channel data
data = zeros(2,2,2)
data[1,:,:] = [1.0 2.0; 3.0 4.0]
data[2,:,:] = [1.0 2.0; 3.0 4.0]
coloring = [ColoringParams(0,1,"gray"), ColoringParams(0,1,"red")]
minval = [0.0,0.0]
maxval = [4.0,4.0]
@test colorize(data, coloring, minval, maxval, false, 2, false) == colorize(data[2,:,:], coloring[2], 0.0, 4.0)
@test colorize(data, coloring, minval, maxval, true, 1, false) == colorize(data, coloring, minval, maxval)
@test colorize(data, coloring, minval, maxval) == linearDodge([colorize(data[1,:,:], coloring[1], 0.0, 4.0),
                                                               colorize(data[2,:,:], coloring[2], 0.0, 4.0)])

data2 = zeros(2,2,2)
data2[1,:,:] = [1.0 2.0; 3.0 4.0]
@test colorize(data2, [ColoringParams(0,1,"gray")], [0.0], [4.0], true, 1, true) ==
      complexColoring(data2[1,:,:], data2[2,:,:], amax=4.0)
@test_throws ErrorException colorize(reshape(collect(1.0:4.0),1,2,2), [ColoringParams(0,1,"gray")],
                                     [0.0], [4.0], true, 1, true)

# colorize normalization branches
@test colorize(fill(2.0,2,2), 0.0, 1.0, cmap("gray")) == fill(RGBA{N0f8}(1,1,1,1),2,2)
@test colorize(zeros(2,2), 0.0, 1.0, cmap("gray")) == fill(RGBA{N0f8}(0,0,0,0),2,2)
c = colorize([0.0 1.0; 2.0 3.0], 0.0, 1.0, cmap("gray"))
@test c[1,1] == RGBA{N0f8}(0,0,0,0)
@test c[2,2] == RGBA{N0f8}(1,1,1,1)
@test c[1,2] ≈ RGBA{N0f8}(1/3,1/3,1/3,1/3)
@test c[2,1] ≈ RGBA{N0f8}(2/3,2/3,2/3,2/3)
n = colorize([0.0 1.0; 2.0 3.0], 0.0, 1.0, cm3, normalize=false)
@test n[1,1] == RGB(0.0,0.0,0.0)
@test n[1,2] == RGB(1.0,1.0,1.0)
@test n[2,1] == RGB(1.0,1.0,1.0)
@test n isa Matrix{RGB{Float64}}

end
