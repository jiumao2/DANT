Installation
=======================

To install DANT, follow these steps:

- Download the code from `DANT <https://github.com/jiumao2/DANT>`_

- Development is based on MATLAB R2022b. The following toolboxes are required:

    - Statistics and Machine Learning Toolbox
    - Optimization Toolbox
    - Parallel Computing Toolbox

- Python 3.9 ~ 3.11 with ``scikit-learn`` and ``hdbscan`` packages installed (`Anaconda <https://www.anaconda.com/download>`_ recommended).

.. code-block:: python
   :linenos:

    conda create -n hdbscan python=3.10
    conda activate hdbscan
    pip install scikit-learn
    pip install hdbscan
 

- Specify the Python executable path in ``settings.json``

.. code-block:: json

    "path_to_python": "path_to_anaconda\\anaconda3\\envs\\hdbscan\\python.exe"

You can get the path by running the following command in the Anaconda prompt:

.. code-block:: bash

    conda info --envs

