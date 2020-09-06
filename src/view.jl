using Base: IOBuffer
using JSExpr: @js_str
using BioStructures: ProteinStructure, 
                     collectatoms, 
                     writepdb,
                     AbstractAtom,
                     Atom

include("network_models.jl")

CANVAS_ID = 0

function create_structure_view(pdb_string::String,js::String)::HTML{String}
    template = """
    <script src="http://3Dmol.csb.pitt.edu/build/3Dmol-min.js""></script>
    <div class="pdb_data_$CANVAS_ID" style="display:none;">$pdb_string</div>
    <div id="container-$CANVAS_ID" class="mol-container" style="width:700px;height:500px"></div>
    <script>
        let element = \$("#container-$CANVAS_ID");
        let config = { backgroundColor: '#fefcf5' };
        let v = \$3Dmol.createViewer( element, config );
        let data = \$(".pdb_data_$CANVAS_ID").html();
        v.addModel( data, "pdb" );
        $js
        v.zoomTo(); 
        v.render();
        v.zoom(1.1, 750);
    </script>
    """
    return HTML(template)
end

function create_network_view(js::String)::HTML{String}
    template = """
    <script src="http://3Dmol.csb.pitt.edu/build/3Dmol-min.js""></script>
    <div id="container-$CANVAS_ID" class="mol-container" style="width:700px;height:500px"></div>
    <script>
        let element = \$("#container-$CANVAS_ID");
        let config = { backgroundColor: '#fefcf5' };
        let v = \$3Dmol.createViewer( element, config );
        $js
    </script>
    """
    return HTML(template)
end

function set_style(style::Dict; selection::Dict=Dict())::String
    # v.setStyle({},{cartoon:{color:"black"}});
    selection_js = js"$selection"
    style_js = js"$style"
    style_string = """
    v.setStyle($selection_js,$style_js);"""
    return style_string
end

function create_pdb_string(atoms::Array{AbstractAtom,1})::String
    io = IOBuffer()
    writepdb(io,atoms)
    pdb_string = String(take!(io))
    return pdb_string
end

function show_structure(ps::ProteinStructure; 
                        model::Int64=1,
                        chains::Array{String}=["A"],
                        style::Dict=Dict("cartoon"=>Dict("color"=>"#5e7ad3")))::HTML{String}
    pdb_string =  ps[model][chains...] |> collectatoms |> create_pdb_string
    style_string = set_style(style)
    global CANVAS_ID += 1
    view = create_structure_view(pdb_string,style_string)
    return view
end

function show_correlations(atoms::Array{AbstractAtom,1};mode::Int64=1,show_hinges::Bool=false)::HTML{String}
    ca_coords = collectatoms(atoms, calphaselector) |> get_coords 
    gnm = GNM(ca_coords) 
    corrs = mode_correlations(gnm,mode) |> (x) -> x[:,1]
    cₚ = findall(round.(corrs) .== 1.0) 
    cₙ = findall(round.(corrs) .== -1.0)
    cₚ_style = Dict("cartoon"=>Dict("color"=>"#5e7ad3"))
    cₙ_style = Dict("cartoon"=>Dict("color"=>"#f57464"))
    style_string = set_style(cₚ_style; selection=Dict("resi"=>cₚ))
    style_string *= set_style(cₙ_style; selection=Dict("resi"=>cₙ))
    if show_hinges
        hinges = get_hinge_indices(gnm)
        hinge_style = Dict("cartoon"=>Dict("color"=>"#ce7d0a"))
        style_string *= set_style(hinge_style;
                                  selection=Dict("resi"=>hinges))
    end
    pdb_string = create_pdb_string(atoms)
    global CANVAS_ID += 1
    structure_view = create_structure_view(pdb_string,style_string)
    return structure_view
end