Installation (Python)
===========================

This page describes installation of the Python version of DANT.

Install with Anaconda
-------------------------

Anaconda is recommended for managing the pyDANT environment.

.. code-block:: bash
   :linenos:

    conda create -n pyDANT python=3.11
    conda activate pyDANT
    pip install pyDANT

Install from Python Package Index (PyPI)
--------------------------------------------

You can also install pyDANT directly from PyPI:

.. code-block:: bash
   :linenos:

    pip install pyDANT

Install from Source
-----------------------

If you prefer to install from source, clone the repository and install it manually:

.. code-block:: bash
   :linenos:

    git clone https://github.com/jiumao2/pyDANT.git
    cd pyDANT
    pip install -e .
