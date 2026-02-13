# Clawpack_tutorial
Files for Chapter 8 (the Saint-Venant equations with a source term)

1. The dambreak problem for a frictionless sloping bed
2. The dambreak problem for a Coulomb material on a horizontal bottom
3. The dambreak problem for a Coulomb material on a slping bed

The code is based on GeoClaw 1D. It can be run using the jupyter notebook (calling a module with some additional functions). Two folders (1bis and 3bis) contain the material for solving the Saint-Venant equations for an inviscid fluid (1bis) or a Coulomb fluid (3bis) on a sloping bed using GeoClaw 2D. The geometry is the same as the one studied in folders 1 and 3, but there is an additional space dimension. The scripts can be run using the jupyter notebook called reading.ipynb. Changes to the configuration file can be made directly in the configuration dictionary in this notebook.
