module SpringLayout
export spring_layout, spring_layout_step!, norm, init_circle

using Graphs, MetaGraphs

"""
    spring_layout(g,k,temp=4.0,iters=60)

Apply the Fruchterman-Reingold layout algorithm to the abstract graph 'g'.

For algorithm details see "Graph drawing by force-directed placement" by Thomas M. J. Fruchterman and Edward M. Reingold. For efficiency, the implementation evenly plots points along a circle before applying the algorithm.
"""
function spring_layout(g::AbstractGraph, k;
    temp = [4.0],
    iters = 60)

    # Variables
    MIN_ATT_DIST = 3.5
    MAX_REP_DIST = 10.0
    TEMP_MIN = 0.5

    # Comput useful constants
    nvg = nv(g)
    adj_mat = adjacency_matrix(g)

    # Position nodes evenly along circle
    pos_x, pos_y = init_circ(g)

    # Main loop of Fruchterman-Reingold layout algorithm
    for i in 1:iters
        spring_layout_step!(pos_x , pos_y, k, nvg, adj_mat, temp, MIN_ATT_DIST=MIN_ATT_DIST, MAX_REP_DIST=MAX_REP_DIST, TEMP_MIN=TEMP_MIN)
    end

    return pos_x, pos_y
end

"""
    spring_layout_step!()

Main stepping function for the spring_layout
"""
function spring_layout_step!(pos_x, pos_y, k, nvg, adj_mat, temp;
    MIN_ATT_DIST = 3.5,
    MAX_REP_DIST = 10.0,
    TEMP_MIN = 0.0,
    TEMP_REDUCTION = 0.5)

    # Initialize displacement vectors
    disp_x = zeros(nvg)
    disp_y = zeros(nvg)

    # loop over all nodes
    for v in 1:nvg-1
        for u in v+1:nvg
            # Skip if u == v
            u == v && continue

            # Compute distance between nodes
            delta_x = pos_x[v] - pos_x[u]
            delta_y = pos_y[v] - pos_y[u]
            distance = norm(delta_x,delta_y)

            # Compute repulsion force for neighboring nodes
            if distance < MAX_REP_DIST
                # Repulsion force
                rep = (k^2)/distance
                scaler_x = delta_x / distance * rep
                scaler_y = delta_y / distance * rep

                # Apply to v
                disp_x[v] += scaler_x
                disp_y[v] += scaler_y

                # Appy to u
                disp_x[u] -= scaler_x
                disp_y[u] -= scaler_y
            end

            # Compute attractive force
            if isone(adj_mat[v,u])
                # Ignore nodes which are close enough
                distance < MIN_ATT_DIST && continue

                # Attraction force
                att = distance^2 / k
                scaler_x = delta_x / distance * att
                scaler_y = delta_y / distance * att

                # Apply to v
                disp_x[v] -= scaler_x
                disp_y[v] -= scaler_y

                # Appy to u
                disp_x[u] += scaler_x
                disp_y[u] += scaler_y
            end
        end
    end

    # Limit net movement by temperature
    capped_disp_x = zeros(nvg)
    capped_disp_y = zeros(nvg)
    for v in 1:nvg
        disp_norm = norm(disp_x[v], disp_y[v])

        # Ignore overlapping nodes (unlikely to occur)
        disp_norm < 0.0001 && continue
        max_disp = min(disp_norm, temp[1])

        # Compute capped displacement
        capped_disp_x[v] = disp_x[v] / disp_norm * max_disp
        capped_disp_y[v] = disp_y[v] / disp_norm * max_disp

        # Apply forces to node
        pos_x[v] += capped_disp_x[v]
        pos_y[v] += capped_disp_y[v]

    end

    # Cool down the temperature
    temp[1] > TEMP_MIN ? temp[1] *= TEMP_REDUCTION : nothing
end

"""
    norm(a,b)

Compute the norm of the scalers 'a' and 'b'.
"""
function norm(a,b)
    return sqrt(a^2 + b^2)
end

"""
    init_circle(g::AbstractGraph)

Align the verticies along a circle.
"""
function init_circle(g::AbstractGraph)
    # Position nodes evenly along circle
    nvg = nv(g)
    pos_x = zeros(nvg)
    pos_y = zeros(nvg)
    for i in 1:nvg
        pos_x[i] = 10*cos(i/nvg * 6.28)
        pos_y[i] = 10*sin(i/nvg * 6.28)
    end
    return pos_x, pos_y
end

end # module
