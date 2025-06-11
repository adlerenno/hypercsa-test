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

