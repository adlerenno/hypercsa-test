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
    'incidence_matrix',
    'plain_list',
    #'itr',
    'reordering_unordering',
    'reordering_vertices',
    'reordering_hyperedges',
    'reordering_vertices_hyperedges',
    'incidence_list'
]
APPROACHES_QUERIES = [
    'hypercsa',
    'incidence_matrix',
    'plain_list'
    #'itr'
]
APPROACHES_QUERIES_ONLY_1 = [
    'reordering_unordering',
    'reordering_vertices',
    'reordering_hyperedges',
    'reordering_vertices_hyperedges',
    'incidence_list'
]

if len(set(APPROACHES_QUERIES) - set(APPROACHES)):
    print('There are approaches in queries that are not in files --> would not work.')
    print(set(APPROACHES_QUERIES) - set(APPROACHES))
    exit(1)


DATA_SETS = [
    'amazon-reviews.txt',
    'house-bills.txt',
    'house-committees.txt',
    'mathoverflow-answers.txt',
    'senate-committees.txt',
    'senate-bills.txt',
    'stackoverflow-answers.txt',
    'trivago-clicks.txt',
    'walmart-trips.txt',
    'com-orkut.txt',
    'com-friendster.txt',
]
QUERY_LENGTH_OF_DATA_SET = {
    'amazon-reviews.txt':15,
    'house-bills.txt':15,
    'house-committees.txt':15,
    'mathoverflow-answers.txt':15,
    'senate-committees.txt':15,
    'senate-bills.txt':15,
    'stackoverflow-answers.txt':150,
    'trivago-clicks.txt':15,
    'walmart-trips.txt':15,
    'com-orkut.txt':20,
    'com-friendster.txt':25,
}
OMITTED_COMBINATIONS = [
    ('incidence_matrix', 'amazon-review.txt'),
    ('incidence_matrix', 'stackoverflow-answers.txt'),
    ('incidence_matrix', 'com-orkut.txt'),
    ('incidence_matrix', 'com-friendster.txt'),
    ('itr', 'mathoverflow-answers.txt'),
    #('itr', 'house-bills.txt'),
    ('itr', 'amazon-reviews.txt'),
    ('itr', 'stackoverflow-answers.txt'),
    ('itr', 'com-friendster.txt'),
    ('itr', 'com-orkut.txt'),
    #('reordering_vertices', 'senate-bills.txt'),
    #('reordering_hyperedges', 'senate-bills.txt'),  # Took more than 5 hours
    #('reordering_vertices_hyperedges', 'senate-bills.txt')  # Must take more than 5 hours, cause it uses _vertices
]# + [
#    (approach, dataset)
#    for approach in ('reordering_vertices', 'reordering_vertices_hyperedges')
#    for dataset in ('amazon-reviews.txt',
    #'house-bills.txt',
#    'stackoverflow-answers.txt',
#    'com-orkut.txt')
#]
OMITTED_QUERY_COMBINATIONS = [
    ('incidence_matrix', 'com-orkut.txt', 'exact'),
]

FILES = [f'indicators/{file}.{approach}'
         for approach in APPROACHES
         for file in DATA_SETS
         if not (approach, file) in OMITTED_COMBINATIONS
         ]
FILES_QUERIES = [
    f'indicators/{file}.{approach}.exact'
    for approach in APPROACHES_QUERIES
    for file in DATA_SETS
    if not (approach, file) in OMITTED_COMBINATIONS
    if not (approach, file, 'exact') in OMITTED_QUERY_COMBINATIONS
] + [
    f'indicators/{file}.{approach}.contains.{k}'
    for approach in APPROACHES_QUERIES
    for file in DATA_SETS
    for k in range(1, QUERY_LENGTH_OF_DATA_SET[file])
    if not (approach, file) in OMITTED_COMBINATIONS
    if not (approach, file, k) in OMITTED_QUERY_COMBINATIONS
] + [
    f'indicators/{file}.{approach}.contains.1'
    for approach in APPROACHES_QUERIES_ONLY_1
    for file in DATA_SETS
    if not (approach, file) in OMITTED_COMBINATIONS
    if not (approach, file, 1) in OMITTED_QUERY_COMBINATIONS
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
        combine_comp(DATA_SETS, APPROACHES, output.bench)

rule get_query_results:
    input:
        set = FILES_QUERIES
    output:
        bench = 'results/query_benchmark.csv'
    run:
        from scripts.collect_benchmark import combine_query
        combine_query(DATA_SETS, APPROACHES_QUERIES + APPROACHES_QUERIES_ONLY_1, QUERY_LENGTH_OF_DATA_SET, output.bench)


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
        if {input.script} -i compressed/hypercsa/{wildcards.filename} -t 0 -f {input.queries}; then 
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
        if {input.script} -i compressed/hypercsa/{wildcards.filename} -t 1 -f {input.queries}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi
        """

rule itr_exact_queries:
    input:
        script = 'itr/build/cgraph-cli',
        source = 'indicators/{filename}.itr',
        queries = 'queries/{filename}_e'
    output:
        indicator = 'indicators/{filename}.itr.exact'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.itr.exact.csv'
    shell:
        """
        if {input.script} --query-file {input.queries} --exact-query --exist-query compressed/itr/{wildcards.filename}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi
        """

rule itr_contains_queries:
    input:
        script = 'itr/build/cgraph-cli',
        source = 'indicators/{filename}.itr',
        queries = 'queries/{filename}_c_{k}'
    output:
        indicator = 'indicators/{filename}.itr.contains.{k}'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.itr.contains.{k}.csv'
    shell:
        """
        if {input.script} --query-file {input.queries} compressed/itr/{wildcards.filename}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi
        """


rule plain_list_exact_queries:
    input:
        source = 'indicators/{filename}.plain_list',
        queries = 'queries/{filename}_e'
    output:
        indicator = 'indicators/{filename}.plain_list.exact'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.plain_list.exact.csv'
    run:
        from scripts.plain_list import run_exact_queries
        run_exact_queries(f'compressed/plain_list/{wildcards.filename}', input.queries, output.indicator)

rule plain_list_contains_queries:
    input:
        source = 'indicators/{filename}.plain_list',
        queries = 'queries/{filename}_c_{k}'
    output:
        indicator = 'indicators/{filename}.plain_list.contains.{k}'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.plain_list.contains.{k}.csv'
    run:
        from scripts.plain_list import run_containment_queries
        run_containment_queries(f'compressed/plain_list/{wildcards.filename}', input.queries, output.indicator)


rule incidence_matrix_exact_queries:
    input:
        source = 'indicators/{filename}.incidence_matrix',
        queries = 'queries/{filename}_e'
    output:
        indicator = 'indicators/{filename}.incidence_matrix.exact'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.incidence_matrix.exact.csv'
    run:
        from scripts.incidence_matrix import run_exact_queries
        run_exact_queries(f'compressed/incidence_matrix/{wildcards.filename}', input.queries, output.indicator)

rule incidence_matrix_contains_queries:
    input:
        source = 'indicators/{filename}.incidence_matrix',
        queries = 'queries/{filename}_c_{k}'
    output:
        indicator = 'indicators/{filename}.incidence_matrix.contains.{k}'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.incidence_matrix.contains.{k}.csv'
    run:
        from scripts.incidence_matrix import run_containment_queries
        run_containment_queries(f'compressed/incidence_matrix/{wildcards.filename}', input.queries, output.indicator)

rule reordering_unordering_contains_queries:
    input:
        script = 'reordering-cli/build/reordering',
        source = 'indicators/{filename}.reordering_unordering',
        queries = 'queries/{filename}_c_1'
    output:
        indicator = 'indicators/{filename}.reordering_unordering.contains.1'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.reordering_unordering.contains.1.csv'
    shell:
        """
        if {input.script} -i compressed/reordering_unordering/{wildcards.filename} -t unorder -q {input.queries}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi
        """

rule reordering_vertices_contains_queries:
    input:
        script = 'reordering-cli/build/reordering',
        source = 'indicators/{filename}.reordering_vertices',
        queries = 'queries/{filename}_c_1'
    output:
        indicator = 'indicators/{filename}.reordering_vertices.contains.1'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.reordering_vertices.contains.1.csv'
    shell:
        """
        if {input.script} -i compressed/reordering_vertices/{wildcards.filename} -t reV -q {input.queries}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi
        """

rule reordering_hyperedges_contains_queries:
    input:
        script = 'reordering-cli/build/reordering',
        source = 'indicators/{filename}.reordering_hyperedges',
        queries = 'queries/{filename}_c_1'
    output:
        indicator = 'indicators/{filename}.reordering_hyperedges.contains.1'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.reordering_hyperedges.contains.1.csv'
    shell:
        """
        if {input.script} -i compressed/reordering_hyperedges/{wildcards.filename} -t reH -q {input.queries}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi
        """

rule reordering_vertices_hyperedges_contains_queries:
    input:
        script = 'reordering-cli/build/reordering',
        source = 'indicators/{filename}.reordering_vertices_hyperedges',
        queries = 'queries/{filename}_c_1'
    output:
        indicator = 'indicators/{filename}.reordering_vertices_hyperedges.contains.1'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.reordering_vertices_hyperedges.contains.1.csv'
    shell:
        """
        if {input.script} -i compressed/reordering_vertices_hyperedges/{wildcards.filename} -t reVH -q {input.queries}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi
        """

rule incidence_list_contains_queries:
    input:
        script = 'reordering-cli/build/reordering',
        source = 'indicators/{filename}.incidence_list',
        queries = 'queries/{filename}_c_1'
    output:
        indicator = 'indicators/{filename}.incidence_list.contains.1'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.incidence_list.contains.1.csv'
    shell:
        """
        if {input.script} -i compressed/incidence_list/{wildcards.filename} -t inc -q {input.queries}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi
        """

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

rule itr:
    input:
        script = 'itr/build/cgraph-cli',
        source = 'data/{filename}'
    output:
        indicator = 'indicators/{filename}.itr'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.itr.csv'
    shell:
        """if {input.script} {input.source} compressed/itr/{wildcards.filename} --overwrite; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi"""

rule ligra:
    input:
        script = 'ligra/apps/hyper/hypergraphEncoder',
        source = 'data/{filename}.hygra'
    output:
        indicator = 'indicators/{filename}.ligra'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.ligra.csv'
    shell:
        """if {input.script} {input.source} compressed/ligra/{wildcards.filename}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi"""

rule plain_list:
    input:
        source = 'data/{filename}'
    output:
        indicator = 'indicators/{filename}.plain_list'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.plain_list.csv'
    shell:
        """
        if cp {input.source} compressed/plain_list/{wildcards.filename}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi
        """

rule incidence_list:
    input:
        source = 'data/{filename}'
    output:
        indicator = 'indicators/{filename}.incidence_list'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.incidence_list.csv'
    shell:
        """
        if cp {input.source} compressed/incidence_list/{wildcards.filename}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi
        """

rule incidence_matrix:
    input:
        source = 'data/{filename}'
    output:
        indicator = 'indicators/{filename}.incidence_matrix'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.incidence_matrix.csv'
    run:
        from scripts.incidence_matrix import compress_hypergraph
        try:
            compress_hypergraph(input.source, f'compressed/incidence_matrix/{wildcards.filename}')
            with open(output.indicator, 'w') as out:
                out.write('1')
        except Exception as e:
            print(e)
            with open(output.indicator, 'w') as out:
                out.write('0')


rule reordering_unordering:
    input:
        script = 'reordering-cli/build/reordering',
        source = 'data/{filename}'
    output:
        indicator = 'indicators/{filename}.reordering_unordering'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.reordering_unordering.csv'
    shell:
        """if {input.script} -i {input.source} -o compressed/reordering_unordering/{wildcards.filename} -t "unorder"; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi"""

rule reordering_vertices:
    input:
        script = 'reordering-cli/build/reordering',
        source = 'data/{filename}'
    output:
        indicator = 'indicators/{filename}.reordering_vertices'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.reordering_vertices.csv'
    shell:
        """if {input.script} -i {input.source} -o compressed/reordering_vertices/{wildcards.filename} -t "reV"; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi"""

rule reordering_hyperedges:
    input:
        script = 'reordering-cli/build/reordering',
        source = 'data/{filename}'
    output:
        indicator = 'indicators/{filename}.reordering_hyperedges'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.reordering_hyperedges.csv'
    shell:
        """if {input.script} -i {input.source} -o compressed/reordering_hyperedges/{wildcards.filename} -t "reH"; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi"""


rule reordering_vertices_hyperedges:
    input:
        script = 'reordering-cli/build/reordering',
        source = 'data/{filename}'
    output:
        indicator = 'indicators/{filename}.reordering_vertices_hyperedges'
    params:
        threads = NUMBER_OF_PROCESSORS,
        temp_dir = TEMP
    benchmark: 'bench/{filename}.reordering_vertices_hyperedges.csv'
    shell:
        """if {input.script} -i {input.source} -o compressed/reordering_vertices_hyperedges/{wildcards.filename} -t "reVH" -x {params.temp_dir}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi"""

rule build_hypercsa:
    output:
        script = 'hypercsa/build/hypercsa-cli'
    shell:
        """
        rm -rf sdsl-lite
        rm -rf hypercsa
        git clone https://github.com/simongog/sdsl-lite.git
        cp ./scripts/install.sh ./sdsl-lite/install.sh
        cd sdsl-lite
        ./install.sh /usr/local/
        cd ..
        git clone https://github.com/adlerenno/hypercsa
        cd hypercsa
        mkdir -p build
        cd build
        cmake ..
        make
        """

rule build_itr:
    output:
        script = 'itr/build/cgraph-cli'
    shell:
        """
        rm -rf itr
        git clone https://github.com/adlerenno/itr
        cd itr
        mkdir -p build
        cd build
        cmake -DCMAKE_BUILD_TYPE=Release -DOPTIMIZE_FOR_NATIVE=on -DWITH_RRR=on ..
        make
        """

rule build_ligra:
    output:
        script = 'ligra/apps/hyper/hypergraphEncoder'
    shell:
        """
        rm -rf ligra
        git clone https://github.com/jshun/ligra
        cd ligra/apps
        make -j$(nproc)
        cd hyper
        make -j$(nproc)
        """

rule build_reordering:
    output:
        script = 'reordering-cli/build/reordering'
    shell:
        """
        rm -rf reordering-cli
        git clone https://github.com/adlerenno/reordering-cli
        cd reordering-cli
        mkdir -p build
        cd build
        cmake ..
        make
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
        generate_queries(input.hypergraph_file, output.e_queries_file, 100)


rule generate_contains_queries: # Collector.
    # Mostly does nothing, because the requirement is satisfied on first invocation.
    input:
        hypergraph_file = 'data/{file}'
    output:
        c_queries_file = 'queries/{file}_c_{k}'
    run:
        from scripts.generate_queries import generate_queries_k
        l = QUERY_LENGTH_OF_DATA_SET[wildcards.file]
        generate_queries_k(input.hypergraph_file, output.c_queries_file, 1000//l, int(wildcards.k))


rule download_orkut:
    output:
        out_file = 'data/com-orkut.txt'
    shell:
        """
        cd data
        URL="https://snap.stanford.edu/data/bigdata/communities/com-orkut.all.cmty.txt.gz"
        FILENAME="com-orkut.all.cmty.txt.gz"
        TXT_FILE="com-orkut.all.cmty.txt"
        CSV_FILE="com-orkut.txt"
        if [ ! -f "$FILENAME" ]; then
            curl -O "$URL"
        else
            echo "$FILENAME already exists. Skipping download."
        fi
        
        # Unzip the file
        if [ -f "$FILENAME" ]; then
            if [ -f "$TXT_FILE" ]; then
                echo "$TXT_FILE exists. Skipping decompression."
            else
                gunzip -k "$FILENAME"  # Use -k to keep the original .gz file
            fi
        else
            echo "Error: $FILENAME not found!"
        fi
        python3 ../scripts/normalize_to_csv.py "$TXT_FILE" "$CSV_FILE" "\t"
        """

rule download_friendster:
    output:
        out_file = 'data/com-friendster.txt'
    shell:
        """
        cd data
        URL="https://snap.stanford.edu/data/bigdata/communities/com-friendster.all.cmty.txt.gz"
        FILENAME="com-friendster.all.cmty.txt.gz"
        TXT_FILE="com-friendster.all.cmty.txt"
        CSV_FILE="com-friendster.txt"
        if [ ! -f "$FILENAME" ]; then
            curl -O "$URL"
        else
            echo "$FILENAME already exists. Skipping download."
        fi
        
        # Unzip the file
        if [ -f "$FILENAME" ]; then
            if [ -f "$TXT_FILE" ]; then
                echo "$TXT_FILE exists. Skipping decompression."
            else
                gunzip -k "$FILENAME"  # Use -k to keep the original .gz file
            fi
        else
            echo "Error: $FILENAME not found!"
        fi
        python3 ../scripts/normalize_to_csv.py "$TXT_FILE" "$CSV_FILE" "\t"
        """

rule download_other_data_sets:
    output:
        'data/amazon-reviews.txt',
        'data/house-bills.txt',
        'data/house-committees.txt',
        'data/mathoverflow-answers.txt',
        'data/senate-committees.txt',
        'data/senate-bills.txt',
        'data/stackoverflow-answers.txt',
        'data/trivago-clicks.txt',
        'data/walmart-trips.txt'
    shell:
        """
        cd data
        if [ -d "datasets-hypercsa-test" ]; then
            echo "datasets-hypercsa-test exists. Skipping download."
        else
            git clone https://git.cs.uni-paderborn.de/eadler/datasets-hypercsa-test
        fi
        python3 ../scripts/normalize_to_csv.py datasets-hypercsa-test/hyperedges-amazon-reviews.txt amazon-reviews.txt ","
        python3 ../scripts/normalize_to_csv.py datasets-hypercsa-test/hyperedges-house-bills.txt house-bills.txt ","
        python3 ../scripts/normalize_to_csv.py datasets-hypercsa-test/hyperedges-house-committees.txt house-committees.txt ","
        python3 ../scripts/normalize_to_csv.py datasets-hypercsa-test/hyperedges-mathoverflow-answers.txt mathoverflow-answers.txt ","
        python3 ../scripts/normalize_to_csv.py datasets-hypercsa-test/hyperedges-senate-bills.txt senate-bills.txt ","
        python3 ../scripts/normalize_to_csv.py datasets-hypercsa-test/hyperedges-senate-committees.txt senate-committees.txt ","
        python3 ../scripts/normalize_to_csv.py datasets-hypercsa-test/hyperedges-stackoverflow-answers.txt stackoverflow-answers.txt ","
        python3 ../scripts/normalize_to_csv.py datasets-hypercsa-test/hyperedges-trivago-clicks.txt trivago-clicks.txt ","
        python3 ../scripts/normalize_to_csv.py datasets-hypercsa-test/hyperedges-walmart-trips.txt walmart-trips.txt ","
        """
