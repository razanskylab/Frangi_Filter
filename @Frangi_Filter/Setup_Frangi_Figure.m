function Setup_Frangi_Figure(FF)

  FH.cbar = gray(256);

  % setup UI axis for images
  fHandle = figure('Name', 'Figure: Vesselness', 'NumberTitle', 'off');
  % make figure fill half the screen
  set(fHandle, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 1]);
  % move figure over a little to the right of the vessel GUI
  fHandle.Units = 'pixels';
  fHandle.OuterPosition(1) = FF.GUI.UIFigure.Position(1) + FF.GUI.UIFigure.Position(3);
  FH.MainFig = fHandle; 
  FH.TileLayout = tiledlayout(2, 2);
  FH.TileLayout.Padding = 'compact'; % remove uneccesary white space...

  % close the app if user closes either the app or the processing window
  FH.MainFig.UserData = FF.GUI; % need that in Gui_Close_Request callback
  FH.MainFig.CloseRequestFcn = @Gui_Close_Request;

  emptyImage = nan(size(FF.raw));

  FH.InPlot = nexttile;
  FH.InIm = imagesc(FF.y,FF.x,emptyImage);
  axis(FH.InPlot,'image');
  axis(FH.InPlot,'tight');
  axis(FH.InPlot,'off');
  colormap(FH.InPlot,FH.cbar);
  title(FH.InPlot,'Frangi Input');

  FH.ScalePlot = nexttile;
  FH.ScaleIm = imagesc(FH.ScalePlot,FF.y,FF.x,emptyImage);
  axis(FH.ScalePlot, 'image');
  axis(FH.ScalePlot, 'tight');
  axis(FH.ScalePlot, 'off');
  colormap(FH.ScalePlot, FH.cbar);
  title(FH.ScalePlot,'Frangi Scale');

  FH.FrangiPlot = nexttile;
  FH.FrangiIm = imagesc(FH.FrangiPlot,FF.y, FF.x, emptyImage);
  axis(FH.FrangiPlot, 'image');
  axis(FH.FrangiPlot, 'tight');
  axis(FH.FrangiPlot, 'off');
  colormap(FH.FrangiPlot, FH.cbar);
  title(FH.FrangiPlot, 'Frangi Filtered Image');

  FH.CombiPlot = nexttile;
  FH.CombiIm = imagesc(FH.CombiPlot,FF.y, FF.x, emptyImage);
  axis(FH.CombiPlot, 'image');
  axis(FH.CombiPlot, 'tight');
  axis(FH.CombiPlot, 'off');
  colormap(FH.CombiPlot, FH.cbar);
  title(FH.CombiPlot, 'Cleaned Binarized Image');


  linkaxes([FH.InPlot, ...
            FH.ScalePlot, ...
            FH.FrangiPlot, ...
            FH.CombiPlot ...
            ], 'xy');
  FF.FigHandles = FH;
end
