using MetaGraphs: AbstractMetaGraph


## Linear algebra API for AbstractMetaGraph

function degrees(mg::AbstractMetaGraph, T::DataType=eltype(mg); dir::Symbol=:out)
    degrees(adjacency_matrix(mg.graph, T; dir), T; dir)
end

function degree_matrix(mg::AbstractMetaGraph, T::DataType=eltype(mg); dir::Symbol=:out)
    degree_matrix(adjacency_matrix(mg.graph, T; dir), T; dir)
end

function inv_sqrt_degree_matrix(mg::AbstractMetaGraph, T::DataType=eltype(mg); dir::Symbol=:out)
    inv_sqrt_degree_matrix(adjacency_matrix(mg.graph, T; dir), T; dir)
end

function laplacian_matrix(mg::AbstractMetaGraph, T::DataType=eltype(mg); dir::Symbol=:out)
    laplacian_matrix(adjacency_matrix(mg.graph, T; dir), T; dir)
end

function normalized_laplacian(mg::AbstractMetaGraph, T::DataType=eltype(mg))
    normalized_laplacian(adjacency_matrix(mg.graph, T), T)
end


## Convolution layers accepting AbstractMetaGraph

GCNConv(g::AbstractMetaGraph, ch::Pair{<:Integer,<:Integer}, σ=identity; kwargs...) =
    GCNConv(g.graph, ch, σ; kwargs...)


ChebConv(g::AbstractMetaGraph, ch::Pair{<:Integer,<:Integer}, k::Integer; kwargs...) =
    ChebConv(g.graph, ch, k; kwargs...)


GraphConv(g::AbstractMetaGraph, ch::Pair{<:Integer,<:Integer}, aggr=:add; kwargs...) =
    GraphConv(g.graph, ch, aggr; kwargs...)


GATConv(g::AbstractMetaGraph, ch::Pair{<:Integer,<:Integer}; kwargs...) =
    GATConv(g.graph, ch; kwargs...)


GatedGraphConv(g::AbstractMetaGraph, out_ch::Integer, num_layers::Integer; kwargs...) =
    GatedGraphConv(g.graph, out_ch, num_layers; kwargs...)


EdgeConv(g::AbstractMetaGraph, nn; kwargs...) = EdgeConv(g.graph, nn; kwargs...)
