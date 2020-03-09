function Setup_Frangi_Figure(FF)

  % setup UI axis for images
  fHandle = figure('Name', 'Frangi Processing', 'NumberTitle', 'off');
  % make figure fill half the screen
  set(fHandle, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 1]);
  % move figure over a little to the right of the vessel GUI
  fHandle.Units = 'pixels';
  fHandle.OuterPosition(1) = FF.GUI.UIFigure.Position(1) + FF.GUI.UIFigure.Position(3);
  FigHandles.MainFig = fHandle; 
  FigHandles.TileLayout = tiledlayout(2, 2);
  FigHandles.TileLayout.Padding = 'compact'; % remove uneccesary white space...

  % close the app if user closes either the app or the processing window
  FigHandles.MainFig.UserData = FF.GUI; % need that in Gui_Close_Request callback
  FigHandles.MainFig.CloseRequestFcn = @Gui_Close_Request;

  emptyImage = nan(size(FF.raw));

  FigHandles.InPlot = nexttile;
  FigHandles.InIm = imagesc(FF.y,FF.x,emptyImage);
  axis image;
  axis tight;
  axis off; % no need for axis labels in these plots
  colormap('gray');
  title('Frangi Input');

  FigHandles.ScalePlot = nexttile;
  FigHandles.ScaleIm = imagesc(FF.y,FF.x,emptyImage);
  axis image;
  axis tight;
  axis off; % no need for axis labels in these plots
  colormap('gray');
  title('Frangi Scale');

  FigHandles.FrangiPlot = nexttile;
  FigHandles.FrangiIm = imagesc(FF.y,FF.x,emptyImage);
  axis image;
  axis tight;
  axis off; % no need for axis labels in these plots
  colormap('gray');
  title('Frangi Filtered Image');

  FigHandles.CombiPlot = nexttile;
  FigHandles.CombiIm = imagesc(FF.y,FF.x,emptyImage);
  axis image;
  axis tight;
  axis off; % no need for axis labels in these plots
  colormap('gray');
  title('Cleaned Binarized Image');


  linkaxes([FigHandles.InPlot, ...
            FigHandles.ScalePlot, ...
            FigHandles.FrangiPlot, ...
            FigHandles.CombiPlot ...
            ], 'xy');
  FF.FigHandles = FigHandles;
end
