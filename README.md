# DANT: Density-based Across-day Neuron Tracking

[![View DANT on GitHub](https://img.shields.io/badge/GitHub-DANT-blue.svg)](https://github.com/jiumao2/DANT)
[![Documentation Status](https://app.readthedocs.org/projects/dant/badge/)](https://dant.readthedocs.io/en/latest/)

**DANT** is a MATLAB toolbox designed for the robust, longitudinal tracking of neurons across multiple recording sessions using high-density probes.

---

### 📄 Preprint
**[Density-based longitudinal neuron tracking in high-density electrophysiological recordings](https://www.biorxiv.org/content/10.64898/2025.12.19.695632v1)**

📚 **[Read the Documentation](https://dant.readthedocs.io/en/latest/)**

🐍 **[Check out the Python version (pyDANT)](https://github.com/jiumao2/pyDANT)**

---

## ⚙️ Installation

DANT operates primarily in MATLAB but utilizes a lightweight Python environment to run the HDBSCAN clustering algorithm efficiently. 

### 1. Download DANT
Clone or download the repository to your local machine:
```bash
git clone [https://github.com/jiumao2/DANT.git](https://github.com/jiumao2/DANT.git)
```

### 2. MATLAB Prerequisites
Development is based on **MATLAB R2022b**. Ensure the following toolboxes are installed in your MATLAB environment:
* Statistics and Machine Learning Toolbox
* Optimization Toolbox
* Parallel Computing Toolbox

### 3. Python Environment Setup
DANT requires Python (3.9 – 3.11) with the `scikit-learn` and `hdbscan` packages. We highly recommend using Anaconda to manage this environment.

Open your Anaconda prompt or terminal and run:

```bash
conda create -n hdbscan python=3.10
conda activate hdbscan
pip install scikit-learn hdbscan
```

### 4. Configure DANT
Finally, link your new Python environment to DANT by updating the `settings.json` file in your DANT directory.

Specify the absolute path to the Python executable in your `hdbscan` environment:

```json
"path_to_python": "C:\\path_to_anaconda\\anaconda3\\envs\\hdbscan\\python.exe"
```

> **Note for Mac/Linux users:** Your path will typically look like `/Users/username/anaconda3/envs/hdbscan/bin/python`. You can easily find the exact path by running `conda info --envs` in your terminal.

## 🚀 Getting Started

To help you get familiar with the pipeline, we have provided an example dataset and a step-by-step walkthrough.

1. **Download the Data:** [Example Dataset for DANT (Figshare)](https://figshare.com/articles/dataset/Example_Dataset_for_DANT/30596258)
2. **Run the Pipeline:** Follow our comprehensive [Tutorial](https://dant.readthedocs.io/en/latest/Tutorials.html) to run the example data or process your own recordings.

If you encounter any bugs, have questions, or want to suggest a feature, please [open an issue](https://github.com/jiumao2/DANT/issues). We look forward to your feedback!

## 📝 Citation

If you use DANT in your research, please cite our preprint:

```bibtex
@article {Huang2025DANT,
    author = {Huang, Yue and Wang, Hanbo and Cao, Jiaming and Chen, Yu and Wang, Xuanning and Zhao, Yujie and Ren, Hengkun and Zheng, Qiang and Yu, Jianing},
    title = {Density-based longitudinal neuron tracking in high-density electrophysiological recordings},
    year = {2025},
    doi = {10.64898/2025.12.19.695632},
    publisher = {Cold Spring Harbor Laboratory},
    URL = {https://www.biorxiv.org/content/early/2025/12/23/2025.12.19.695632},
    journal = {bioRxiv}
}
```

## 📚 References & Acknowledgements

DANT builds upon and integrates several excellent open-source tools. We extend our gratitude to the authors of the following packages:

* **[HDBSCAN](https://scikit-learn.org/stable/modules/clustering.html#hdbscan):** Hierarchical Density-Based Spatial Clustering of Applications with Noise. (Campello et al., 2013; McInnes & Healy, 2017).
* **[Kilosort](https://github.com/MouseLand/Kilosort):** Fast spike sorting with drift correction. (Pachitariu et al., 2024).
* **[DREDge](https://github.com/evarol/DREDge):** Robust online multiband drift estimation in electrophysiology data. (Windolf et al., 2025).
* **[EasyPlot](https://github.com/jiumao2/EasyPlot):** A MATLAB package for generating clean scientific figures.
* **[npy-matlab](https://github.com/kwikteam/npy-matlab):** Functions to read/write NumPy `.npy` files in MATLAB.
* **[JSON+C parsing for MATLAB](https://github.com/seanbone/matlab-json-c):** A simple parser for JSON with Comments written in MATLAB.
* **[MatlabProgressBar](https://github.com/JAAdrian/MatlabProgressBar):** A smart `tqdm`-style progress bar optimized for MATLAB and parallel computing.

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

