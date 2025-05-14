import numpy as np

# import hypernetx as hnx

def compress_hypergraph(input_file: str, output_file: str):
    """
    Reads a text file with hyperedges and saves a compressed HyperNetX hypergraph.
    Each line in the file should contain comma-separated integers representing a hyperedge.
    """
    edges = {}
    max_node = 0
    with open(input_file, 'r') as f:
        for i, line in enumerate(f):
            nodes = set(map(int, line.strip().split(',')))
            edge_id = f"e{i+1}"
            edges[edge_id] = nodes
            max_node = max(max_node, max(nodes))

    H = hnx.Hypergraph(edges)

    incidence_matrix = np.zeros((max_node, len(edges)), dtype=np.uint8)

    for edge, nodes_in_edge in H.incidence_dict.items():
        for node in nodes_in_edge:
            incidence_matrix[node, edge] = 1
    np.savez_compressed(output_file,
                        incidence_matrix=incidence_matrix)

    print(f"Compressed hypergraph saved to {output_file}")


def run_containment_queries(hypergraph_file: str, query_file: str, indicator_file:str):
    """
    Loads a compressed hypergraph and runs node-set containment queries from a query file.
    Each line in the query file should be a comma-separated list of integers.
    """
    successful = 1
    try:
        data = np.load(hypergraph_file, allow_pickle=True)
        matrix = data['incidence_matrix']

        with open(query_file, 'r') as f:
            for line_num, line in enumerate(f, 1):
                query_nodes = set(map(int, line.strip().split(',')))
                # The all(map(... tests all matrix positions to be 1
                matching_edges = [e for e in range(len(matrix)) if all(map(lambda node: matrix[e][node], query_nodes))]
                print(f'Query {line_num} has {len(matching_edges)} results.')
    except Exception as e:
        print(e)
        successful = 0
    with open(indicator_file, 'w') as f:
        f.write(str(successful))


def run_exact_queries(hypergraph_file: str, query_file: str, indicator_file:str):
    """
    Loads a compressed hypergraph and runs node-set containment queries from a query file.
    Each line in the query file should be a comma-separated list of integers.
    """
    successful = 1
    try:
        data = np.load(hypergraph_file, allow_pickle=True)
        matrix = data['incidence_matrix']

        with open(query_file, 'r') as f:
            for line_num, line in enumerate(f, 1):
                query_nodes = set(map(int, line.strip().split(',')))
                for e in range(len(matrix)):
                    if set(matrix[e]) == query_nodes:
                        print(f'Query {line_num} has 1 results.')
                        break
                else:
                    print(f'Query {line_num} has 0 results.')
    except Exception as e:
        print(e)
        successful = 0
    with open(indicator_file, 'w') as f:
        f.write(str(successful))


