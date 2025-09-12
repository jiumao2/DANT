# DANT: Density-based Across-day Neuron Tracking

[![View DANT on GitHub](https://img.shields.io/badge/GitHub-DANT-blue.svg)](https://github.com/jiumao2/DANT)
[![Documentation Status](https://app.readthedocs.org/projects/dant/badge/)](https://dant.readthedocs.io/en/latest/)

A MATLAB toolbox for tracking the neurons across days.

Check out the Python version of DANT [here](https://github.com/jiumao2/pyDANT)!  

Read the [documentation](https://DANT.readthedocs.io/en/latest/) for more details.

## Installation

To install DANT, follow these steps:

- Download the code from the [DANT](https://github.com/jiumao2/DANT)

- Development is based on MATLAB R2022b. The following toolboxes are required:

    - Statistics and Machine Learning Toolbox
    -   Optimization Toolbox
    -   Parallel Computing Toolbox

- Python 3.9 \~ 3.11 with `scikit-learn` and `hdbscan` packages installed ([Anaconda](https://www.anaconda.com/download) recommended).

```python
conda create -n hdbscan python=3.10
conda activate hdbscan
pip install scikit-learn
pip install hdbscan
```

- Specify the Python executable path in `settings.json`

```json
"path_to_python": "path_to_anaconda\\anaconda3\\envs\\hdbscan\\python.exe"
```

You can get the path by running the following command in the Anaconda prompt:

```bash
conda info --envs
```

## How to use it

Please follow the [tutorial](https://dant.readthedocs.io/en/latest/Tutorials.html) to run your dataset.  

Please raise an issue if you meet any bugs or have any questions. We are looking forward to your feedback!

## References

> [HDBSCAN](https://scikit-learn.org/stable/modules/clustering.html#hdbscan)  
> HDBSCAN - Hierarchical Density-Based Spatial Clustering of Applications with Noise. Performs DBSCAN over varying epsilon values and integrates the result to find a clustering that gives the best stability over epsilon. This allows HDBSCAN to find clusters of varying densities (unlike DBSCAN), and be more robust to parameter selection.
> 
> Campello, R.J.G.B., Moulavi, D., Sander, J. (2013). Density-Based Clustering Based on Hierarchical Density Estimates. In: Pei, J., Tseng, V.S., Cao, L., Motoda, H., Xu, G. (eds) Advances in Knowledge Discovery and Data Mining. PAKDD 2013. Lecture Notes in Computer Science(), vol 7819. Springer, Berlin, Heidelberg. Density-Based Clustering Based on Hierarchical Density Estimates  
>
> L. McInnes and J. Healy, (2017). Accelerated Hierarchical Density Based Clustering. In: IEEE International Conference on Data Mining Workshops (ICDMW), 2017, pp. 33-42. Accelerated Hierarchical Density Based Clustering

> [Kilosort](https://github.com/MouseLand/Kilosort)  
> Fast spike sorting with drift correction  
> 
> Pachitariu, Marius, Shashwat Sridhar, Jacob Pennington, and Carsen Stringer. “Spike Sorting with Kilosort4.” Nature Methods 21, no. 5 (May 2024): 914–21. https://doi.org/10.1038/s41592-024-02232-7.

> [DREDge](https://github.com/evarol/DREDge)  
> Robust online multiband drift estimation in electrophysiology data  
> 
> Windolf, Charlie, Han Yu, Angelique C. Paulk, Domokos Meszéna, William Muñoz, Julien Boussard, Richard Hardstone, et al. “DREDge: Robust Motion Correction for High-Density Extracellular Recordings across Species.” Nature Methods, March 6, 2025. https://doi.org/10.1038/s41592-025-02614-5.

> [EasyPlot](https://github.com/jiumao2/EasyPlot)  
> A MATLAB package for making scientific figures easily

> [npy-matlab](https://github.com/kwikteam/npy-matlab)  
> Experimental code to read/write NumPy .NPY files in MATLAB

> [JSON+C parsing for MATLAB](https://github.com/seanbone/matlab-json-c/releases/tag/v1.1)  
> A simple parser for JSON with Comments written in MATLAB

> [MatlabProgressBar](https://github.com/JAAdrian/MatlabProgressBar)  
> This MATLAB class provides a smart progress bar like tqdm in the command window and is optimized for progress information in simple iterations or large frameworks with full support of parallel parfor loops provided by the MATLAB Parallel Computing Toolbox.  

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

