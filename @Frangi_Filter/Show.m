function [] = Show(F)
  % handle figures
  if F.verboseOutput
    fprintf('[Frangi] Plotting frangi filtered images ...');
  end

  figure('Name', 'Frangi Scale Overview') % always create scales in seperate figure
  tiledlayout('flow', 'TileSpacing', 'compact');
  t = {};
  % find number of scales for plotting
  % always plot raw image that was used for filtering
  t{end + 1} = nexttile();
  imagescj(F.raw);
  title('Unfiltered raw image');

  t{end + 1} = nexttile();
  imagescj(F.filt);
  title('Frangi result');

  for iPlot = 1:size(F.filtScales, 3)
    % fprintf(['    Plotting frangi scale ', num2str(iPlot) , '...\n']);
    filtImage = F.filtScales(:, :, iPlot);
    filtImage = normalize(filtImage);
    filtImage = adapthisteq(filtImage, 'Distribution', F.claheDistr, 'NBins', F.claheNBins, ...
      'ClipLimit', F.claheLim, 'NumTiles', F.claheNTiles);
    [~, montage] = im_overlay(F.raw, filtImage);

    t{end + 1} = nexttile();
    imshow(montage);
    % don't create new figures for each scale, we have subplots for that
    % but we have to change the F.newFigPlotting settings as it's used in Overlay_Mask
    titleStr = sprintf('Scale:%i (%2.0f Px)', iPlot, F.useScales(iPlot));
    title(titleStr);
  end

  linkaxes([t{3:end}]);
  linkaxes([t{1:2}]);

  if F.verboseOutput
    done();
  end

end
