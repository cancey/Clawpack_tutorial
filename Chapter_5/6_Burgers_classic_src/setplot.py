
""" 
Set up the plot figures, axes, and items to be done for each frame.

This module is imported by the plotting routines and then the
function setplot is called to set the plot parameters.
    
""" 

#--------------------------
def setplot(plotdata):
#--------------------------
    
    """ 
    Specify what is to be plotted at each frame.
    Input:  plotdata, an instance of clawpack.visclaw.data.ClawPlotData.
    Output: a modified version of plotdata.
    
    """ 

    plotdata.clearfigures()  # clear any old figures,axes,items data

    

    # Figure for q[0]
    plotfigure = plotdata.new_plotfigure(name='Density', figno=1)

    # Set up for axes in this figure:
    plotaxes = plotfigure.new_plotaxes(name='Density')
    plotaxes.xlimits = 'auto'
    plotaxes.ylimits = [-0.05,1.5]
    plotaxes.title = 'Density'

    # Set up for item on these axes:
    plotitem = plotaxes.new_plotitem(name='Density', plot_type='1d')
    plotitem.plot_var = 0
    plotitem.plotstyle = '-o'
    plotitem.color = 'b'
    plotitem.show = True       # show on plot?
    

    # Parameters used only when creating html and/or latex hardcopy
    # e.g., via clawpack.visclaw.frametools.printframes:

    plotdata.printfigs = True                # print figures
    plotdata.print_format = 'png'            # file format
    plotdata.print_framenos = 'all'          # list of frames to print
    plotdata.print_fignos = 'all'            # list of figures to print
    plotdata.html = True                     # create html files of plots?
    plotdata.latex = True                    # create latex file of plots?
    plotdata.latex_figsperline = 2           # layout of plots
    plotdata.latex_framesperline = 1         # layout of plots
    plotdata.latex_makepdf = False           # also run pdflatex?

    return plotdata

    
