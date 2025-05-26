
def run_containment_queries(hypergraph_file: str, query_file: str, indicator_file:str):
    """
    Loads a compressed hypergraph and runs node-set containment queries from a query file.
    Each line in the query file should be a comma-separated list of integers.
    """
    successful = 1
    try:
        edges = list()
        with open(hypergraph_file, 'r') as f:
            for i, line in enumerate(f):
                nodes = set(map(int, line.strip().split(',')))
                edges.append(nodes)

        with open(query_file, 'r') as f:
            for line_num, line in enumerate(f, 1):
                query_nodes = set(map(int, line.strip().split(',')))
                # The all(map(... tests all nodes are in the edge
                matching_edges = [e for e in edges if all(map(lambda node: node in e, query_nodes))]
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
        edges = list()
        max_node = 0
        with open(hypergraph_file, 'r') as f:
            for i, line in enumerate(f):
                nodes = set(map(int, line.strip().split(',')))
                edges.append(nodes)
                max_node = max(max_node, max(nodes))

        with open(query_file, 'r') as f:
            for line_num, line in enumerate(f, 1):
                query_nodes = set(map(int, line.strip().split(',')))
                for e in edges:
                    if all(map(lambda node: node in e, query_nodes)):
                        if all(map(lambda node: node in query_nodes, e)):
                            print(f'Query {line_num} has 1 results.')
                            break
                else:
                    print(f'Query {line_num} has 0 results.')
    except Exception as e:
        print(e)
        successful = 0
    with open(indicator_file, 'w') as f:
        f.write(str(successful))


