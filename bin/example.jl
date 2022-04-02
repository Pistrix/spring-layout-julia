# External Modules
#=using Plots, Graphs, MetaGraphs

# Local Modules
include("..\\src\\SpringLayout.jl")
using .SpringLayout=#

function create_canvas!()
    plot(xlims = (-RANGE,RANGE), ylims = (-RANGE,RANGE), background_color = RGB(0.2, 0.2, 0.2), axis = nothing, border=:none, legend=:none)
end

function add_line!(x1,x2,y1,y2)
    plot!([x1,x2], [y1,y2], linecolor=RGB(128/255, 128/255, 128/255))
end

function add_nodes!(x,y)
    plot!(x, y, seriestype = :scatter, markercolor=RGB(135/255,206/255,235/255))
end

# Creat a graph and set variables
EXAMPLE = 3

if EXAMPLE == 1
    g = barbell_graph(6,10)
    temperature = [0.35]
    k = 5
    TEMP_REDUCTION = 0.96
    RANGE = 13.5
elseif EXAMPLE == 2
    g = erdos_renyi(100, 40)
    temperature = [1.4]
    k = 5
    TEMP_REDUCTION = 0.95
    RANGE = 50
elseif EXAMPLE == 3
    g = watts_strogatz(100, 3, 0.2, seed=123)
    temperature = [1.0]
    k = 4
    TEMP_REDUCTION = 0.98
    RANGE = 50
end

# Comput useful constants
nvg = nv(g)
adj_mat = adjacency_matrix(g)

# Position nodes evenly along circle
x, y = init_circle(g)

# Create Canvas
create_canvas!()

# Plot Edges
for j in 1:nvg-1
    for k in j+1:nvg
        if isone(adj_mat[j,k])
            add_line!(x[j],x[k],y[j],y[k])
        end
    end
end

# Plot nodes
add_nodes!(x,y)

# Creat animation and add init frame
anim = Animation()
frame(anim)

# Main loop of Fruchterman-Reingold layout algorithm
for i in 1:300
    spring_layout_step!(x, y, k, nvg, adj_mat, temperature, TEMP_REDUCTION = TEMP_REDUCTION)

    # Create Plot
    create_canvas!()

    # Plot Edges
    for j in 1:nvg-1
        for k in j+1:nvg
            if isone(adj_mat[j,k])
                add_line!(x[j],x[k],y[j],y[k])
            end
        end
    end

    # Plot nodes
    add_nodes!(x,y)

    # Add to frame
    frame(anim)
end

gif(anim, "example_$(EXAMPLE).gif", fps = 30)
