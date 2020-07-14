in_channel = 10
out_channel = 5
num_V = 6
num_E = 7
adj = [0. 1. 0. 0. 0. 0.;
       1. 0. 0. 1. 1. 1.;
       0. 0. 0. 0. 0. 1.;
       0. 1. 0. 0. 1. 0.;
       0. 1. 0. 1. 0. 1.;
       0. 1. 1. 0. 1. 0.] |> gpu
ne = [[2], [1,4,5,6], [6], [2,5], [2,4,6], [2,3,5]]

struct NewCudaLayer <: MessagePassing
    weight
end
NewCudaLayer(m, n) = NewCudaLayer(randn(m,n))
@functor NewCudaLayer

(l::NewCudaLayer)(X) = propagate(l, X, :add)

X = rand(in_channel, num_V) |> gpu
E = rand(in_channel, num_E) |> gpu
M = rand(out_channel, num_V) |> gpu
fg = FeaturedGraph(adj, X)
l = NewCudaLayer(out_channel, in_channel) |> gpu

@testset "cuda/msgpass" begin
    GeometricFlux.message(l::NewCudaLayer, x_i, x_j, e_ij) = x_j
    GeometricFlux.update(l::NewCudaLayer, m, x) = m
    @testset "no message or update" begin
        fg_ = l(fg)

        @test graph(fg_) === adj
        @test size(node_feature(fg_)) == (in_channel, num_V)
        @test size(edge_feature(fg_)) == (in_channel, 2*num_E)
        @test size(global_feature(fg_)) == (0,)
        @test typeof(graph(fg_)) == CuArray{Float32,2,Nothing}
        @test typeof(node_feature(fg_)) == CuArray{Float32,2,Nothing}
        @test typeof(edge_feature(fg_)) == CuArray{Float32,2,Nothing}
    end

    GeometricFlux.message(l::NewCudaLayer, x_i, x_j, e_ij) = l.weight * x_j
    @testset "message function" begin
        fg_ = l(fg)

        @test graph(fg_) === adj
        @test size(node_feature(fg_)) == (out_channel, num_V)
        @test size(edge_feature(fg_)) == (out_channel, 2*num_E)
        @test size(global_feature(fg_)) == (0,)
    end

    GeometricFlux.message(l::NewCudaLayer, x_i, x_j, e_ij) = x_j.^2
    @testset "gradient of update_batch_edge" begin
        E_ = gradient(Y -> sum(GeometricFlux.update_batch_edge(l, ne, Y, X)), E)
        @test isnothing(E_[1])
        X_ = gradient(Y -> sum(GeometricFlux.update_batch_edge(l, ne, E, Y)), X)
        @test X_[1] == cu([1 4 1 2 3 3]) .* 2X
    end

    GeometricFlux.message(l::NewCudaLayer, x_i, x_j, e_ij) = l.weight * x_j
    GeometricFlux.update(l::NewCudaLayer, m, x) = l.weight * x + m
    @testset "message and update" begin
        fg_ = l(fg)

        @test graph(fg_) === adj
        @test size(node_feature(fg_)) == (out_channel, num_V)
        @test size(edge_feature(fg_)) == (out_channel, 2*num_E)
        @test size(global_feature(fg_)) == (0,)
    end

    GeometricFlux.update(l::NewCudaLayer, m, x) = l.weight * x + m
    @testset "gradient of update_batch_vertex" begin
        M_ = gradient(Y -> sum(GeometricFlux.update_batch_vertex(l, Y, X)), M)
        @test M_[1] == ones(size(M))
        X_ = gradient(Y -> sum(GeometricFlux.update_batch_vertex(l, M, Y)), X)
        @test X_[1] ≈ l.weight'*cu(ones(out_channel, num_V))
    end
end
