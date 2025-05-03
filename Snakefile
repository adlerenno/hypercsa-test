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
    'hypercsa'
]
DATA_SETS = [
    ''
]

FILES = [f'indicators/{file}.{approach}'
         for approach in APPROACHES
         for file in DATA_SETS
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
        from scripts.collect_benchmark import combine
        combine(FILES, DATA_SETS, APPROACHES, output.bench)

rule get_query_results:
    input:
        set = FILES
    output:
        bench = 'results/query_benchmark.csv'
    run:
        from scripts.collect_benchmark import combine
        combine(, DATA_SETS, APPROACHES, output.bench)


rule clean:
    shell:
        """
        rm -rf ./bench
        rm -rf ./source
        rm -rf ./split
        rm -rf ./data
        rm -rf ./data_bwt
        rm -rf ./indicators
        rm -rf ./tmp
        rm -rf ./result
        """

rule hypercsa:
    input:
        script = 'hypercsa/build/hypercsa-cli',
        source = 'data/{filename}'
    output:
        indicator = 'indicators/{filename}.divsufsort'
    params:
        threads = NUMBER_OF_PROCESSORS
    benchmark: 'bench/{filename}.divsufsort.csv'
    shell:
        """if {input.script} -i {input.source} -o compressed/hypercsa/{wildcards.filename}; then 
        echo 1 > {output.indicator}
        else
        echo 0 > {output.indicator}
        fi"""

rule build_hypercsa:
    output:
        script = 'hypercsa/build/hypercsa-build'
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