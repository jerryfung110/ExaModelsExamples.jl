module ExaModelsExamples

import JLD2
import Downloads
import ExaModels: ExaModels, NLPModels
import PowerModels: PowerModels, silence

include("opf.jl")
include("luksanvlcek.jl")
include("distillation.jl")
include("quadrotor.jl")
include("goddard.jl")

const NAMES = filter(names(ExaModelsExamples; all = true)) do x
    str = string(x)
    endswith(str, "model") && !startswith(str, "#")
end

for name in filter(names(ExaModelsExamples; all = true)) do x
    endswith(string(x), "model")
end
    @eval export $name
end

function __init__()
    if haskey(ENV, "EXA_MODELS_DEPOT")
        global TMPDIR = ENV["EXA_MODELS_DEPOT"]
    else
<<<<<<< HEAD
        global TMPDIR = tempname()
        mkdir(TMPDIR)
=======
        global TMPDIR = joinpath(@__DIR__,"..","data")
        mkpath(TMPDIR)
>>>>>>> 569fd3a (separate changes)
    end
    PowerModels.silence()
end

end # module ExaModelsExamples
