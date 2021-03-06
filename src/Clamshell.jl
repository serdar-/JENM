module Clamshell

include("network_models.jl")
include("view.jl")

export AbstractNetworkModel,
       AnisotropicNetworkModel,
       GaussianNetworkModel,
       GNM,
       ANM,
       eigvals,
       eigvecs,
       get_calpha_coords,
       mode_correlations,
       get_hinge_indices,
       show_structure,
       show_correlations,
       show_network, 
       show_hinge_plane

end