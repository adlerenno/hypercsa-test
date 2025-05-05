from collections import defaultdict
import sys


def convert_to_adjacency_hypergraph(input_path, output_path):
    vertex_to_hyperedges = defaultdict(list)
    hyperedges = []

    with open(input_path, 'r') as f:
        for hyperedge_id, line in enumerate(f):
            nodes = [int(x) - 1 for x in line.strip().split()]
            hyperedges.append(nodes)
            for node in nodes:
                vertex_to_hyperedges[node].append(hyperedge_id)

    nv = max(vertex_to_hyperedges.keys()) + 1
    nh = len(hyperedges)

    # Sort vertex IDs to ensure correct order
    vertex_ids = list(range(nv))

    # Vertex offset and ev
    ov = []
    ev = []
    offset = 0
    for v in vertex_ids:
        ov.append(offset)
        incident = vertex_to_hyperedges[v]
        ev.extend(incident)
        offset += len(incident)

    # Hyperedge offset and eh
    oh = []
    eh = []
    offset = 0
    for he in hyperedges:
        oh.append(offset)
        eh.extend(he)
        offset += len(he)

    mv = len(ev)
    mh = len(eh)

    with open(output_path, 'w') as out:
        out.write("AdjacencyHypergraph\n")
        out.write(f"{nv}\n{mv}\n{nh}\n{mh}\n")
        out.writelines(f"{x}\n" for x in ov)
        out.writelines(f"{x}\n" for x in ev)
        out.writelines(f"{x}\n" for x in oh)
        out.writelines(f"{x}\n" for x in eh)

    print(f"Conversion complete: {output_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python convert_hypergraph.py input.txt output.txt")
    else:
        convert_to_adjacency_hypergraph(sys.argv[1], sys.argv[2])
