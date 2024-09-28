# Minimize the sum of the inverse weighted mean ratio of the elements in a fixed–boundary
# tetrahedral mesh by adjusting the locations of the free vertices.

#  This is problem 19 in the COPS (Version 3) collection of 
#   E. Dolan and J. More
#   see "Benchmarking Optimization Software with COPS"
#   Argonne National Labs Technical Report ANL/MCS-246 (2004)

include(joinpath("..", "data", "tetra.jl"))

function tetra_model(x0 = xe_tetra, TETS::Vector{Int64} = Tets_tetra, Const::Vector{Int64} = Constants_tetra,;T = Float64, backend = nothing, kwargs...)
    τ = 0.0
    n = length(x0)
    N = round(Int, n / 3)
    E = round(Int, length(TETS) / 4)

    lvar = fill(-Inf, n)
    lvar[Const] .= x0[Const]
    lvar[Const .+ N] .= x0[Const .+ N]
    lvar[Const .+ 2 * N] .= x0[Const .+ 2 * N]

    uvar = fill(Inf, n)
    uvar[Const] .= x0[Const]
    uvar[Const .+ N] .= x0[Const .+ N]
    uvar[Const .+ 2 * N] .= x0[Const .+ 2 * N]
    obj_array = [(TETS[e], TETS[e + E], TETS[e + 2*E], TETS[e + 3*E], TETS[e]+N, TETS[e]+2*N, TETS[e + E]+N, TETS[e + E]+2*N, TETS[e + 2*E]+N, TETS[e + 2*E]+2*N, TETS[e + 3*E]+N, TETS[e + 3*E]+2*N) for e in 1:E]
    c1_array = [(e, TETS[e], TETS[e] + N * i, TETS[e] + N * mod(i + 1, 3), TETS[e] + N * mod(i - 1, 3), 
                TETS[e + E] + N * i, 
                TETS[e + 2E] + N * mod(i + 1, 3), TETS[e + 2E] + N * mod(i - 1, 3),
                TETS[e + 3E] + N * mod(i + 1, 3), TETS[e + 3E] + N * mod(i - 1, 3)) for i in 0:2 for e in 1:E]

    c = ExaModels.ExaCore(T; backend = backend)

    x = ExaModels.variable(c, n; lvar = lvar, uvar = uvar, start = x0)

    ExaModels.objective(
        c,
        (
            (1 * x[TETS_E] - x[TETS])^2 + ((2 * x[TETS_2E] - x[TETS_E] - x[TETS])^2) / 3 +
            ((3 * x[TETS_3E] - x[TETS_2E] -x[TETS_E] - x[TETS])^2) / 6 +
            (1 * x[TETS_E_N] - x[TETS_N])^2 + ((2 * x[TETS_2E_N] - x[TETS_E_N] - x[TETS_N])^2) / 3 +
            ((3 * x[TETS_3E_N] - x[TETS_2E_N] - x[TETS_E_N] - x[TETS_N])^2) / 6 +
            (1 * x[TETS_E_2N] - x[TETS_2N])^2 + ((2 * x[TETS_2E_2N] - x[TETS_E_2N] - x[TETS_2N])^2) / 3 +
            ((3 * x[TETS_3E_2N] - x[TETS_2E_2N] - x[TETS_E_2N] - x[TETS_2N])^2) / 6 
        ) / (
            3 *
            ((
                (x[TETS_E] - x[TETS]) *
                (
                    (x[TETS_2E_N] - x[TETS_N]) *
                    (x[TETS_3E_2N] - x[TETS_2N]) -
                    (x[TETS_2E_2N] - x[TETS_2N]) *
                    (x[TETS_3E_N] - x[TETS_N])
                ) +
                (x[TETS_E_N] - x[TETS_N]) *
                (
                    (x[TETS_2E_2N] - x[TETS_2N]) *
                    (x[TETS_3E] - x[TETS]) -
                    (x[TETS_2E] - x[TETS]) *
                    (x[TETS_3E_2N] - x[TETS_2N])
                ) +
                (x[TETS_E_2N] - x[TETS_2N]) *
                (
                    (x[TETS_2E] - x[TETS]) *
                    (x[TETS_3E_N] - x[TETS_N]) -
                    (x[TETS_2E_N] - x[TETS_N]) *
                    (x[TETS_3E] - x[TETS])
                )) *
                sqrt(2)
            )^(2 / 3) 
        ) for (TETS, TETS_E, TETS_2E, TETS_3E, TETS_N, TETS_2N, TETS_E_N, TETS_E_2N, TETS_2E_N, TETS_2E_2N, TETS_3E_N, TETS_3E_2N) in obj_array
    )

    c1 = ExaModels.constraint(
        c,
        E;
        lcon = τ,
        ucon = Inf 
    )

    ExaModels.constraint!(
        c,
        c1,
        e =>    (x[TETS_E_N] - x[TETS_N]) *
                (
                    (x[TETS_2E_plus] - x[TESTS_N_plus]) *
                    (x[TETS_3E_minus] - x[TETS_N_minus]) -
                    (x[TETS_2E_minus] - x[TETS_N_minus]) *
                    (x[TETS_3E_plus] - x[TESTS_N_plus])
                ) *
                sqrt(2) 
                for (e, TETS, TETS_N, TESTS_N_plus, TETS_N_minus, TETS_E_N, TETS_2E_plus, TETS_2E_minus, TETS_3E_plus, TETS_3E_minus) in c1_array
    )
    
    return ExaModels.ExaModel(c; kwargs...)
end

tetra_duct12_model(; T = Float64, backend = nothing) = tetra_model(xe_duct12, TETS_duct12, Const_duct12; T = T, backend = backend)
tetra_duct15_model(; T = Float64, backend = nothing) = tetra_model(xe_duct15, TETS_duct15, Const_duct15; T = T, backend = backend)
tetra_duct20_model(; T = Float64, backend = nothing) = tetra_model(xe_duct20, TETS_duct20, Const_duct20; T = T, backend = backend)
tetra_hook_model(; T = Float64, backend = nothing) = tetra_model(xe_hook, TETS_hook, Const_hook; T = T, backend = backend)
tetra_foam5_model(; T = Float64, backend = nothing) = tetra_model(xe_foam5, TETS_foam5, Const_foam5; T = T, backend = backend)
tetra_gear_model(; T = Float64, backend = nothing) = tetra_model(xe_gear, TETS_gear, Const_gear; T = T, backend = backend)

