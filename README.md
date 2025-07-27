# hypercsa-test

This repository contains the [Snakefile](https://snakemake.github.io) to perform the tests of the [HyperCSA](https://www.arxiv.org/abs/2506.05023) paper. 
The snakefile will download all necessary repositories, 
install all necessary libraries ([SDSL](https://github.com/simongog/sdsl-lite), [divsufsort](https://github.com/y-256/libdivsufsort/tree/master)) 
and download the test datasets from [ARB](https://www.cs.cornell.edu/~arb/data/) and [SNAP](https://snap.stanford.edu). 
The order of steps might differ due to order in which the rules are performed. 


## Preparation

Install [Snakemake](https://snakemake.github.io), 
you can of course use any package systems for installation.
Then, clone this GitHub project and run snakemake:

```
pip install snakemake
git clone https://github.com/adlerenno/hypercsa-test.git
cd hypercsa-test
snakemake --cores 1
```

You can increase the number of cores to run the test in parallel. 
However, note that concurrent processes conflict for resources and the results may be less accurate.
We give no guarantee that this script will work.
Please open a request if you spot any errors or need advice on retesting.
If you intend to include your own approach in the test environment, feel free to message us;
we like to include it as well.

## Approaches

### CHGL

A reviewer claimed that CHGL is the state of the art for hypergraph processing. 
As to their current documentation (https://pnnl.github.io/chgl/installation_guide.html), CHGL needs Chapel 1.20.
Chapel has to the time of my testing the version 2.5. CHGL does not compile anymore with this version.
I get the following errors more than 100 times in total: 
- unknown pragma "no doc"
- syntax error: near '>' 
- syntax error: near 'return'
- error: operators cannot be declared without the operator keyword
- error: attempt to redefine reserved word 'these'
- syntax error: near '}'
- error: cannot find module or enum named 'Memory'
- In method 'isIncident':
- error: cannot find 'badArgs' in module 'Debug'
- error: statement references variable '_this' before it is defined

Trying to build chapel-1.20 from scratch requires diskutil, which is deprecated since Python 3.10 and removed in Python 3.12.
As I needed to install diskutil via my package manager, I could not get it to work with pyenv.
Therefore, I claim CHGL deprecated here, because the effort to get it running is too high. 
Also, it uses just an AdjacencyDict as data structure, something I already have included in my comparison.

## Data sets

This project contains most of the tested data sets. They are publicly available, but not downloadable via script (if you know a way, we would be happy to include them not directly in this repository.) Thus, we provide a table of links here that point to the origin of these data sets.

| Data set              | Origin                                                                |
|-----------------------|-----------------------------------------------------------------------|
| senate-committees     | https://www.cs.cornell.edu/~arb/data/senate-committees/index.html     |
| house-committees      | https://www.cs.cornell.edu/~arb/data/house-committees/index.html      |
| senate-bills          | https://www.cs.cornell.edu/~arb/data/senate-bills/index.html          |
| house-bills           | https://www.cs.cornell.edu/~arb/data/house-bills/index.html           |
| stackoverflow-answers | https://www.cs.cornell.edu/~arb/data/stackoverflow-answers/index.html |
| mathoverflow-answers  | https://www.cs.cornell.edu/~arb/data/mathoverflow-answers/index.html  |
| walmart-trips         | https://www.cs.cornell.edu/~arb/data/walmart-trips/index.html         |
| amazon-reviews        | https://www.cs.cornell.edu/~arb/data/amazon-reviews/index.html        |
| trivago-clicks        | https://www.cs.cornell.edu/~arb/data/trivago-clicks/index.html        |
| com-friendster        | https://snap.stanford.edu/data/com-Friendster.html (\*.all.cmty.\*)   |
| com-orkut             | https://snap.stanford.edu/data/com-Orkut.html (\*.all.ctmy.\*)        |

