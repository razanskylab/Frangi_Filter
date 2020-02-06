function Plot_Frangi(FF, scaleOnly, selectedScale)

  try
    FF.Update_ProgBar('Updating Frangi plots...');

    if nargin == 1
      scaleOnly = false;
      selectedScale = 1;
    elseif nargin == 2
      selectedScale = 1;
    end

    if ~scaleOnly

      if ~isempty(FF.raw)
        plotAx = FF.GUI.imFrangiFiltIn.Children(1);
        set(plotAx, 'cdata', FF.raw);
      end

      if ~isempty(FF.filtScales)
        plotAx = FF.GUI.imFrangiScale.Children(1);
        set(plotAx, 'cdata', squeeze(FF.filtScales(:, :, selectedScale)));
      end

      if ~isempty(FF.filt)
        plotAx = FF.GUI.imFrangiFilt.Children(1);
        set(plotAx, 'cdata', FF.filt);
      end

      if ~isempty(FF.fusedFrangi)
        plotAx = FF.GUI.imFrangiFused.Children(1);
        set(plotAx, 'cdata', FF.fusedFrangi);
      end

    else

      if ~isempty(FF.filtScales)
        plotAx = FF.GUI.imFrangiScale.Children(1);
        set(plotAx, 'cdata', squeeze(FF.filtScales(:, :, selectedScale)));
      end

    end

    drawnow;
    FF.ProgBar = [];

  catch me
    rethrow(me);
  end

end
