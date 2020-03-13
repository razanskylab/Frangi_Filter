function Plot_Frangi(FF, scaleOnly, selectedScale)

  try

    if nargin == 1
      scaleOnly = false;
      selectedScale = 1;
    elseif nargin == 2
      selectedScale = 1;
    end

    if ~scaleOnly
      FF.Update_ProgBar('Updating plots');
      if ~isempty(FF.raw)
        set(FF.FigHandles.InIm, 'cdata', FF.raw);
      end

      if ~isempty(FF.filtScales)
        set(FF.FigHandles.ScaleIm, 'cdata', squeeze(FF.filtScales(:, :, selectedScale)));
      end

      if ~isempty(FF.filt)
        set(FF.FigHandles.FrangiIm, 'cdata', FF.filt);
      end

      if ~isempty(FF.fusedFrangi)
        set(FF.FigHandles.CombiIm, 'cdata', FF.fusedFrangi);
      end

    else
      % no progress bar if we just update the single plot, as it's faaast
      if ~isempty(FF.filtScales)
        plotAx = FF.FigHandles.ScaleIm;
        set(plotAx, 'cdata', squeeze(FF.filtScales(:, :, selectedScale)));
      end

    end

    drawnow;
    FF.ProgBar = [];

  catch me
    rethrow(me);
  end

end
