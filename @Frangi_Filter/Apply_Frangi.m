function Apply_Frangi(FF, unFilt)
  % applies Frangi filtering using the GUI

  % make sure gui is running, if not, ask user what to do...
  if isempty(FF.GUI) || (~isvalid(FF.GUI))
    answer = questdlg('Apply_Frangi requires a running GUI window, which was not opened!', ...
      'Dessert Menu', ...
      'Open GUI', 'Run Without GUI', 'Cancel', 'Open GUI');
    % Handle response
    switch answer
      case 'Open GUI'
        FF.Open_GUI();
      case 'Run Without GUI'
        short_warn('You can just run .Apply() instead of .Apply_Frangi()!');
        FF.Apply();
        return;
      case 'Cancel'
        return;
    end

  else % GUI exist, make it visible
    FF.GUI.UIFigure.Visible = 'on';
  end

  try

    % check if we actually have data to work with
    if nargin == 1
      unFilt = FF.raw;
    end

    if isempty(unFilt)
      return;
    end

    if isempty(FF.FigHandles) ||~ishandle(FF.FigHandles.MainFig)
      FF.Setup_Frangi_Figure();
    else
      figure(FF.FigHandles.MainFig); % bring figure to foreground
      figure(FF.GUI.UIFigure); % bring figure to foreground
    end

    % check if we contrast adjust the individual scales...
    doClahe = FF.GUI.CLAHEScalesCheckBox.Value; % clahe each scale?
    doContrast = FF.GUI.ContrastScalesCheckBox.Value; % adj contr. each scale?

    if doClahe || doContrast
      IMF = Image_Filter(); % init Image filter class
      % setup solid default clahe settings
      IMF.claheNBins = 256;
      IMF.claheLim = 0.02;
      IMF.claheNTiles = [32 32];
      % setup solid default contrast settings
      IMF.imadLimOut = [0 1];
      IMF.imadAuto = true;
      IMF.imadGamme = 1.20;
    end

    % check if app is acutally open / visible
    FF.Update_ProgBar('Frangi Filtering:', 0);

    unFilt = normalize(unFilt);
    sensitivity = FF.GUI.SensitivityEditField.Value;
    inverted = ~FF.GUI.InvertedCheckBox.Value;

    % useScales in micrometer / pixels
    sigmas = sort(FF.useScales);

    if strcmp(FF.GUI.UnitsDropDown.Value, 'physical')
      % convert to pixel (rounding done later in for loop)
      sigmas = sigmas ./ (FF.dR * 1e3);
    end

    nSigmas = length(sigmas);

    sigmas = double(sigmas);
    FF.filt = zeros(size(unFilt), 'like', unFilt); % filtered image
    FF.filtScales = zeros([size(unFilt) nSigmas], 'like', unFilt); % fitlered scales

    for iScale = 1:nSigmas
      progMessage = sprintf('Filtering scale %i/%i...', iScale, nSigmas);
      FF.Update_ProgBar(progMessage, iScale ./ nSigmas);
      iSigma = sigmas(iScale) / 6; % FIXME why the 6 here???
      iFilt = imgaussfilt(unFilt, iSigma, 'FilterSize', 2 * ceil(3 * iSigma) + 1);
      iFilt = builtin("_fibermetricmex", iFilt, sensitivity, inverted, iSigma);
      % iFilt can be all zeros depending on filter, then we don't adjust
      if any(iFilt(:))

        if doClahe
          IMF.filt = iFilt;
          iFilt = IMF.Apply_CLAHE();
        end

        if doContrast
          IMF.filt = iFilt;
          iFilt = IMF.Adjust_Contrast();
        end

        FF.filtScales(:, :, iScale) = iFilt;
      end

    end

    % combine frangi filtered and original image
    FF.Update_Frangi_Combo();

    if ~FF.isBackground
      % plot scale,  etc...
      FF.Plot_Frangi();
    end

    FF.ProgBar = [];
  catch me
    FF.ProgBar = [];
    rethrow(me);
  end

end
