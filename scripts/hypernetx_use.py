import hypernetx as hnx
import pickle

def compress_hypergraph(input_file: str, output_file: str):
    """
    Reads a text file with hyperedges and saves a compressed HyperNetX hypergraph.
    Each line in the file should contain comma-separated integers representing a hyperedge.
    """
    edges = {}
    with open(input_file, 'r') as f:
        for i, line in enumerate(f):
            nodes = set(map(int, line.strip().split(',')))
            edge_id = f"e{i+1}"
            edges[edge_id] = nodes

    H = hnx.Hypergraph(edges)

    # Compress and save
    with open(output_file, 'wb') as out:
        pickle.dump(H, out)

    print(f"Compressed hypergraph saved to {output_file}")


def run_containment_queries(hypergraph_file: str, query_file: str, indicator_file:str):
    """
    Loads a compressed hypergraph and runs node-set containment queries from a query file.
    Each line in the query file should be a comma-separated list of integers.
    """
    successful = 1
    try:
        # Load compressed hypergraph
        with open(hypergraph_file, 'rb') as f:
            H = pickle.load(f)

        with open(query_file, 'r') as f:
            for line_num, line in enumerate(f, 1):
                query_nodes = set(map(int, line.strip().split(',')))
                matching_edges = [e for e in H.edges if query_nodes.issubset(H.edges[e])]
                print(f'Query {line_num} has {len(matching_edges)} results.')
    except Exception as e:
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
        # Load compressed hypergraph
        with open(hypergraph_file, 'rb') as f:
            H = pickle.load(f)

        with open(query_file, 'r') as f:
            for line_num, line in enumerate(f, 1):
                query_nodes = set(map(int, line.strip().split(',')))
                for e in H.edges:
                    if set(e) == query_nodes:
                        print(f'Query {line_num} has 1 results.')
                        break
                else:
                    print(f'Query {line_num} has 0 results.')
    except Exception as e:
        successful = 0
    with open(indicator_file, 'w') as f:
        f.write(str(successful))


