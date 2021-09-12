
import Pkg

Pkg.activate(".")
Pkg.instantiate()

import JSON3
import StructTypes
import Base.convert

using RecipesBase

using Plots
Plots.gr()

import Plots.scatter

struct Player
    lastname:: String
    firstname:: String
    playerid:: Int64
    jersey:: String
    position:: String
end

struct Team
    name:: String
    teamid:: Int64
    abbreviation:: String
    players:: Vector{Player}
end

struct Location
    teamId:: Int64
    playerId:: Int64
    x:: Float64
    y:: Float64
    radius:: Float64
end

function convert(::Type{Location}, v:: Vector{Any})
    @assert length(v) == 5
    Location(
        convert(Int64, v[1]),
        convert(Int64, v[2]),
        convert(Float64, v[3]),
        convert(Float64, v[4]),
        convert(Float64, v[5])
    )
end

struct Moment
    quarter:: Int64
    millis:: Int64
    game_clock:: Float64
    shot_clock:: Float64
    unknown:: Any
    locations:: Vector{Location}
end

function Moment(v:: Vector{Any})
    Moment(v[1], v[2], v[3] isa Nothing ? 0.0 : v[3], v[4] isa Nothing ? 0.0 : v[4], v[5], v[6])
end

struct Event
    eventId:: String
    visitor:: Team
    home:: Team
    moments:: Vector{Moment}
end

struct Game
    gameid:: String
    gamedate:: String
    events:: Vector{Event}
end

StructTypes.StructType(::Type{Player}) = StructTypes.Struct()
StructTypes.StructType(::Type{Team}) = StructTypes.Struct()
StructTypes.StructType(::Type{Location}) = StructTypes.ArrayType()
StructTypes.StructType(::Type{Moment}) = StructTypes.ArrayType()
StructTypes.StructType(::Type{Event}) = StructTypes.Struct()
StructTypes.StructType(::Type{Game}) = StructTypes.Struct()

game = open("..\\nba-movement-data\\data\\12.25.2015.LAC.at.LAL\\0021500440.json", "r") do f
# game = open("crap.json", "r") do f
    JSON3.read(f, Game)
end;

function getCircle(center_x:: Float64, center_y:: Float64, radius:: Float64, angle_start:: Float64 = 0.0, angle_end:: Float64 = 2π)
    θ = LinRange(angle_start, angle_end, 64)
    center_x .+ radius * sin.(θ), center_y .+ radius * cos.(θ)
end

@userplot CourtPlot
@recipe function f(::CourtPlot)
    legend --> false
    framestyle --> :none
    grid --> false
    linecolor := :black
    linealpha := 0.3

    x, y = [], []

    # court boundary
    push!(x, [0, 94, 94, 0, 0])
    push!(y, [0, 0, 50, 50, 0])

    # baskets
    tmp = getCircle(4.0 + 0.75, 25.0, 0.75)
    push!(x, tmp[1])
    push!(y, tmp[2])
    tmp = getCircle(94 - (4.0 + 0.75), 25.0, 0.75)
    push!(x, tmp[1])
    push!(y, tmp[2])

    # three point lines
    push!(x, [0, 14])
    push!(y, [3, 3])
    push!(x, [0, 14])
    push!(y, [47, 47])
    tmp = getCircle(4 + 0.75, 25.0, 23.75, 0.126π, 0.874π)
    push!(x, tmp[1])
    push!(y, tmp[2])

    push!(x, [80, 94])
    push!(y, [3, 3])
    push!(x, [80, 94])
    push!(y, [47, 47])
    tmp = getCircle(94 - (4 + 0.75), 25.0, 23.75, 1.126π, 1.874π)
    push!(x, tmp[1])
    push!(y, tmp[2])
    
    # paint & free throw line
    push!(x, [0, 19])
    push!(y, [25.0 + 6.0, 25.0 + 6.0])
    push!(x, [0, 19])
    push!(y, [25.0 - 6.0, 25.0 - 6.0])
    push!(x, [0, 19])
    push!(y, [25.0 + 8.0, 25.0 + 8.0])
    push!(x, [0, 19])
    push!(y, [25.0 - 8.0, 25.0 - 8.0])
    push!(x, [19, 19])
    push!(y, [25.0 - 8.0, 25.0 + 8.0])

    push!(x, [75, 94])
    push!(y, [25.0 + 6.0, 25.0 + 6.0])
    push!(x, [75, 94])
    push!(y, [25.0 - 6.0, 25.0 - 6.0])
    push!(x, [75, 94])
    push!(y, [25.0 + 8.0, 25.0 + 8.0])
    push!(x, [75, 94])
    push!(y, [25.0 - 8.0, 25.0 - 8.0])
    push!(x, [75, 75])
    push!(y, [25.0 - 8.0, 25.0 + 8.0])

    tmp = getCircle(19.0, 25.0, 6.0, 0.0, 1π)
    push!(x, tmp[1])
    push!(y, tmp[2])
    tmp = getCircle(75.0, 25.0, 6.0, 1π, 2π)
    push!(x, tmp[1])
    push!(y, tmp[2])

    # center court
    push!(x, [47, 47])
    push!(y, [0.0, 50.0])
    tmp = getCircle(47.0, 25.0, 6.0)
    push!(x, tmp[1])
    push!(y, tmp[2])
    
    x, y
end

@userplot MomentPlot
@recipe function f(h::MomentPlot)
    legend --> false
    framestyle --> :none
    grid --> false
    seriestype := :scatter

    moment = h.args[1]

    x = [location.x for location in moment.locations]
    y = [location.y for location in moment.locations]

    @series begin
        markershape := :circle
        markersize := moment.locations[1].radius + 3
        markercolor := :orange
        x[1:1], y[1:1]
    end

    markersize := 5.0
    
    @series begin
        markershape := :circle
        markercolor := :red
        x[2:6], y[2:6]
    end

    @series begin
        markershape := :circle
        markercolor := :blue
        x[7:11], y[7:11]
    end

end

eventId = "17"
event_idx = only(findall(x -> x.eventId == eventId, game.events))
event = game.events[event_idx]

Plots.@gif for i ∈ 1:length(event.moments)
    courtplot()
    momentplot!(event.moments[i])
end

# Plots.gif(anim, "anim_fps15.gif", fps=15)

# TODO add names or an identifier to plot
# TODO deal with missing data somehow
