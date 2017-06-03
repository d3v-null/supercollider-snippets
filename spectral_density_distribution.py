import numpy as np
from scipy.stats import norm
import matplotlib.pyplot as plt
# fig, ax = plt.subplots(1, 1)

GRAPHS = 10
OSCS = 7
BASE = 2

def main():
    linspace_x_line = np.linspace(-2 * np.pi, 2 * np.pi, 400)
    linspace_x_bar = np.linspace(-(OSCS-1)/2.0, (OSCS-1)/2.0, OSCS)

    fun = lambda x, s: norm.pdf(x, 0, s)

    for count, index in enumerate(np.linspace(-2, 3, GRAPHS)):
        axis = plt.subplot(GRAPHS, 1, count+1)
        axis.set_ylim([0, 1])
        x_scale = BASE ** (index)
        bar_y = fun(linspace_x_bar, x_scale)
        bar_y_norm = bar_y / sum(bar_y)
        plt.plot(linspace_x_line, fun(linspace_x_line, x_scale), 'r-')
        plt.bar(linspace_x_bar-0.4, bar_y_norm, fill=True)
        print "%3d ** %+.3f = %05.2f" % (BASE, index, x_scale), ["%+.0f" % y for y in  linspace_x_bar], ["%.2f" % y for y in  bar_y], "%.4f" % sum(bar_y), ["%.2f" % y for y in  bar_y_norm], sum(bar_y_norm)

    plt.show()

if __name__ == '__main__':
    main()
