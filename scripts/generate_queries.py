import random
import os
from math import floor


def read_hypergraph(file_path):
    hyperedges = set()
    all_nodes = set()

    with open(file_path, 'r') as file:
        for line in file:
            edge = tuple(sorted(map(int, line.strip().split(','))))
            hyperedges.add(edge)
            all_nodes.update(edge)

    return list(hyperedges), list(all_nodes)


def generate_queries(input_graph, output_path, num_queries, max_query_len):
    hyperedges, all_nodes = read_hypergraph(input_graph)
    half = num_queries // 2
    exact_matches = random.choices(hyperedges, k=half)

    non_matches = set(hyperedges)
    fake_queries = set()

    attempts = 0
    max_attempts = num_queries * 10  # Avoid infinite loop

    while len(fake_queries) < half and attempts < max_attempts:
        size = random.choice([len(edge) for edge in hyperedges])
        candidate = tuple(sorted(random.sample(all_nodes, size)))
        if candidate not in non_matches:
            fake_queries.add(candidate)
        attempts += 1

    # Combine and shuffle for randomness
    all_queries = exact_matches + list(fake_queries)
    random.shuffle(all_queries)

    # Write to output file
    with open(output_path, 'w') as out:
        for query in all_queries:
            out.write(','.join(map(str, query)) + '\n')

    print(f"Generated {len(exact_matches)} matching queries and {len(fake_queries)} non-matching queries into {output_path}")
    queries_per_length = num_queries // max_query_len

    for k in range(1, max_query_len + 1):
        queries = set()
        attempts = 0
        max_attempts = queries_per_length * 10

        while len(queries) < queries_per_length and attempts < max_attempts:
            edge = random.choice(hyperedges)
            if len(edge) >= k:
                subset = tuple(sorted(random.sample(edge, k)))
                queries.add(subset)
            attempts += 1

        file_path = output_path + f'_c_{k}.txt'
        with open(file_path, 'w') as f:
            for query in queries:
                f.write(','.join(map(str, query)) + '\n')

        print(f"Generated {len(queries)} queries of length {k} into {file_path}")