
# coding: utf-8

import matplotlib.pyplot as plt
import numpy as np
import scipy.interpolate
from scipy.optimize import curve_fit
from matplotlib.ticker import LinearLocator, FormatStrFormatter



filter_max_capacity = 1300

x = np.arange(0,1800,1)

y_ini = np.zeros(1299)
y_ini2 = np.ones(501)
y = np.append(y_ini, y_ini2)

def func_sigmoidal(xdata, b,c):
#    a/(1+e^(-x+b)*c)
    return 1/(1+np.exp(-xdata+b)*c)

parameters_sigmoidal, cov_sigmoidal = curve_fit(func_sigmoidal, x, y, p0=(1300,1))

plt.plot(x, y)
plt.scatter(x, func_sigmoidal(x, *parameters_sigmoidal), s=10, color="k", marker="+")
#plt.scatter(x, func_sigmoidal(x, 100.82001131, 0.00000000001), s=10, color="k", marker="+")
#plt.legend(loc='lower right')
#plt.xlim([-0.0001,0.008])
#plt.ylim([-0.004,0.01])
#plt.xlabel("Thermodynamic model")
#plt.ylabel("Response surface model")
#plt.savefig("pareto_RMS.pdf")