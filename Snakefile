import os

# sudo snakemake --rerun-triggers mtime --cores 1
# sudo snakemake --touch --cores 1

MAX_MAIN_MEMORY = 128
NUMBER_OF_PROCESSORS = 32

DIR = "./"
INPUT = './data/'
TEMP = './tmp/'
OUTPUT = './compressed/'
INDICATORS = './indicators/'
BENCHMARK = './bench/'
RESULT = './results/'

APPROACHES = [
    'hypercsa',
    'ligra',
    'hypernetx'
]
APPROACHES_QUERIES = [
    'hypercsa',
    'hypernetx'
]

DATA_SETS = [
    'hyperedges-senate-committees.txt',
    'com-orkut.txt',
    'com-friendster.txt',
    'hyperedges-stackoverflow-answers.txt',
    'hyperedges-walmart-trips.txt'
]
QUERY_LENGTH_OF_DATA_SET = {
    'hyperedges-senate-committees.txt':15,
    'com-orkut.txt':100,
    'com-friendster.txt':100,
    'hyperedges-stackoverflow-answers.txt':150,
    'hyperedges-walmart-trips.txt':15,
}

FILES = [f'indicators/{file}.{approach}'
         for approach in APPROACHES
         for file in DATA_SETS
         ]
FILES_QUERIES = [
    f'indicators/{file}.{approach}.exact'
    for approach in APPROACHES_QUERIES
    for file in DATA_SETS
] + [
    f'indicators/{file}.{approach}.contains.{k}'
    for approach in APPROACHES_QUERIES
    for file in DATA_SETS
    for k in range(1, QUERY_LENGTH_OF_DATA_SET[file])
]

for path in [BENCHMARK, INPUT, TEMP, OUTPUT, INDICATORS, RESULT] + [OUTPUT + approach for approach in APPROACHES]:
    os.makedirs(path, exist_ok=True)


rule target:
    input:
        comp_bench = 'results/comp_benchmark.csv',
        query_bench = 'results/query_benchmark.csv'

rule get_comp_results:
    input:
        set = FILES
    output:
        bench = 'results/comp_benchmark.csv'
    run:
        """
        python3 scripts/collect_benchmarks.py bench {output.bench}
        """
        from scripts.collect_benchmark import combine_comp
        combine_comp(FILES, DATA_SETS, APPROACHES, output.bench)

rule get_query_results:
    input:
        set = FILES_QUERIES
    output:
        bench = 'results/query_benchmark.csv'
    run:
        from scripts.collect_benchmark import combine_query
        combine_query(FILES_QUERIES, DATA_SETS, APPROACHES, output.bench)


rule clean:
    shell:
        """
        rm -rf ./bench
        rm -rf ./source
        rm -rf ./split
        rm -rf ./compressed
        rm -rf ./indicators
        rm -rf ./tmp
        rm -rf ./result
        """

rule hypercsa_exact_queries:
    input:
        script = 'hypercsa/build/hypercsa-cli',
        source = 'indicators/{filename}.hypercsa',
        queries = 'queries/{filename}_e'
    output:
        indicator = 'indicators/{filename}.hypercsa.exact'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.hypercsa.exact.csv'
    shell:
        """
        if {input.script} -i {input.source} -t 0 -f {input.queries}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi
        """

rule hypercsa_contains_queries:
    input:
        script = 'hypercsa/build/hypercsa-cli',
        source = 'indicators/{filename}.hypercsa',
        queries = 'queries/{filename}_c_{k}'
    output:
        indicator = 'indicators/{filename}.hypercsa.contains.{k}'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.hypercsa.contains.{k}.csv'
    shell:
        """
        if {input.script} -i {input.source} -t 1 -f {input.queries}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi
        """


rule hypernetx_exact_queries:
    input:
        indicator='indicators/hypernetx_installed',
        source = 'indicators/{filename}.hypernetx',
        queries = 'queries/{filename}_e'
    output:
        indicator = 'indicators/{filename}.hypernetx.exact'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.hypernetx.exact.csv'
    run:
        from hypernetx_use import run_containment_queries
        run_containment_queries(f'compressed/hypernetx/{wildcards.filename}', input.queries)

rule hypernetx_contains_queries:
    input:
        indicator='indicators/hypernetx_installed',
        source = 'indicators/{filename}.hypernetx',
        queries = 'queries/{filename}_c_{k}'
    output:
        indicator = 'indicators/{filename}.hypernetx.contains.{k}'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.hypernetx.contains.{k}.csv'
    run:
        from hypernetx_use import run_containment_queries
        run_containment_queries(f'compressed/hypernetx/{wildcards.filename}', input.queries)

rule hypercsa:
    input:
        script = 'hypercsa/build/hypercsa-cli',
        source = 'data/{filename}'
    output:
        indicator = 'indicators/{filename}.hypercsa'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.hypercsa.csv'
    shell:
        """if {input.script} -i {input.source} -o compressed/hypercsa/{wildcards.filename}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi"""

rule ligra:
    input:
        script = 'ligra/apps/hypergraphEncoder',
        source = 'data/{filename}.hygra'
    output:
        indicator = 'indicators/{filename}.ligra'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.hygra.csv'
    shell:
        """if {input.script} {input.source} compressed/ligra/{wildcards.filename}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi"""

rule hypernetx:
    input:
        indicator = 'indicators/hypernetx_installed',
        source = 'data/{filename}'
    output:
        indicator = 'indicators/{filename}.hypernetx'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.hypernetx.csv'
    run:
        from hypernetx_use import compress_hypergraph
        try:
            compress_hypergraph(input.source, f'compressed/hypernetx/{wildcards.filename}')
            with open(output.indicator, 'w') as out:
                out.write('1')
        except Exception as e:
            with open(output.indicator, 'w') as out:
                out.write('0')

rule build_hypercsa:
    output:
        script = 'hypercsa/build/hypercsa-cli'
    shell:
        """
        rm -rf hypercsa
        git clone https://github.com/adlerenno/hypercsa
        cd hypercsa
        mkdir -p build
        cd build
        cmake ..
        make
        """

rule build_ligra:
    output:
        script = 'ligra/apps/hypergraphEncoder'
    shell:
        """
        git clone https://github.com/jshun/ligra
        cd ligra/apps
        make -j$(nproc)
        """

rule hypernetx_build:
    output:
        indicator = 'indicators/hypernetx_installed'
    shell:
        """
        pip install hypernetx
        echo 1 > {output.indicator}
        """

rule generate_ligra_files:
    input:
        file = 'data/{filename}'
    output:
        ofile = 'data/{filename}.hygra'
    run:
        from scripts.to_hygra_format import convert_to_adjacency_hypergraph
        convert_to_adjacency_hypergraph(input.file, output.ofile)

rule generate_exact_queries:
    input:
        hypergraph_file = 'data/{file}'
    output:
        e_queries_file = 'queries/{file}_e',
    run:
        from scripts.generate_queries import generate_queries
        generate_queries(input.hypergraph_file, output.e_queries_file, 1000, QUERY_LENGTH_OF_DATA_SET[wildcards.file])


rule generate_contains_queries: # Collector.
    # Mostly does nothing, because the requirement is satisfied on first invocation.
    input:
        e_queries_file = 'queries/{file}_e',
    output:
        c_queries_file = 'queries/{file}_c_{k}'
    run:
        pass # Are generated by the exact queries.


rule download_orkut:
    output:
        out_file = 'data/com-orkut.txt'
    shell:
        """
        cd data
        URL="https://snap.stanford.edu/data/bigdata/communities/com-orkut.ungraph.txt.gz"
        FILENAME="com-orkut.ungraph.txt.gz"
        TXT_FILE="com-orkut.ungraph.txt"
        CSV_FILE="com-orkut.txt"
        if [ ! -f "$FILENAME" ]; then
            curl -O "$URL"
        else
            echo "$FILENAME already exists. Skipping download."
        fi
        
        # Unzip the file
        if [ -f "$FILENAME" ]; then
            gunzip -k "$FILENAME"  # Use -k to keep the original .gz file
        else
            echo "Error: $FILENAME not found!"
        fi
        grep -v '^#' "$TXT_FILE" | tr '\t' ',' > "$CSV_FILE"
        """

rule download_friendster:
    output:
        out_file = 'data/com-friendster.txt'
    shell:
        """
        cd data
        URL="https://snap.stanford.edu/data/bigdata/communities/com-friendster.ungraph.txt.gz"
        FILENAME="com-friendster.ungraph.txt.gz"
        TXT_FILE="com-friendster.ungraph.txt"
        CSV_FILE="com-friendster.txt"
        if [ ! -f "$FILENAME" ]; then
            curl -O "$URL"
        else
            echo "$FILENAME already exists. Skipping download."
        fi
        
        # Unzip the file
        if [ -f "$FILENAME" ]; then
            gunzip -k "$FILENAME"  # Use -k to keep the original .gz file
        else
            echo "Error: $FILENAME not found!"
        fi
        grep -v '^#' "$TXT_FILE" | tr '\t' ',' > "$CSV_FILE"
        """

rule download_other_data_sets:
    output:
        'data/hyperedges-senate-committees.txt',
        'data/hyperedges-stackoverflow-answers.txt',
        'data/hyperedges-walmart-trips.txt'
    shell:
        """
        cd data
        git clone https://git.cs.uni-paderborn.de/eadler/datase-ts-hypercsa-test.git
        """
