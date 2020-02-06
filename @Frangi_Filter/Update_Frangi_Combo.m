function Update_Frangi_Combo(FF)
  % FF.Update_Frangi_Combo()
  % Combine selected frangi scales (with contrast adjustments) and apply to image
  % Needs already calculated FF.filtScales, then used the max-amp projection
  % of those to form frangi filtered image...
  % that is combined by various ways of linear and nonlinear combination
  try

    if isempty(FF.raw) || isempty(FF.filt)
      FF.fusedFrangi = []; % nothing to here really...
      return;
    end

    FF.Update_ProgBar('Fusing Frangi and Raw');
    IMF = Image_Filter(); % init Image filter class, we use it a lot here...
    % takes 0.05s to create, so rather get a "new one" every time...

    % calculate overall frangi filtered image by taking max of all scales...
    % then apply potential contrast adjustments %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isempty(FF.filtScales)
      % only take selected scales into account
      selectedScales = [FF.GUI.ScaleTable.Data{:, 2}];
      FF.filt = squeeze(max(FF.filtScales(:, :, selectedScales), [], 3));

      % check if we contrast adjust the individual scales...
      doClahe = FF.GUI.CLAHEFiltCheckBox.Value; % clahe each scale?
      doContrast = FF.GUI.ContrastFiltCheckBox.Value; % adj contr. each scale?

      if doClahe || doContrast
        IMF.filt = FF.filt; % transfer image to IMF class

        if doClahe
          % setup solid default clahe settings
          IMF.claheNBins = 256;
          IMF.claheLim = 0.02;
          IMF.claheNTiles = [32 32];
          IMF.Apply_CLAHE();
        end

        if doContrast
          % setup solid default contrast settings
          IMF.imadLimOut = [0 1];
          IMF.imadAuto = true;
          IMF.imadGamme = 1.20;
          IMF.Adjust_Contrast();
        end

        FF.filt = IMF.filt; % transfer image data back...
      end
    end

    % we loose all quantitativeness when we combine frangi and raw, so 
    % we normalize here to make them easier to combine
    FF.filt = normalize(FF.filt);
    FF.raw = normalize(FF.raw);

    % combines Frangi & processes map to fusedFrangi
    % TODO have different options on how to do this
    switch FF.GUI.FusingTechDropDown.Value
      case 'Frangi Only'
        FF.fusedFrangi = FF.filt;
      case 'Linear Combination'

        if strcmp(FF.GUI.LinCombDropDown.Value, 'sum')
          FF.fusedFrangi = FF.raw .* FF.GUI.RawEditField.Value + ...
            FF.filt .* FF.GUI.FrangiEditField.Value;
        elseif strcmp(FF.GUI.LinCombDropDown.Value, 'prod')
          FF.fusedFrangi = FF.raw .* FF.GUI.RawEditField.Value .* ...
            FF.filt .* FF.GUI.FrangiEditField.Value;
        end

      case 'Non - Linear Combination'
        % fitModel = '1/(1+exp(b*(c-x)))'; % b = spread, c = x0, x = frangi value
      case 'Image Guided Filter'
        % filters baseIM using the guided filter, guided by guideIm
        if FF.GUI.FlipCheckBox.Value
          baseIM = FF.filt;
          guideIm = FF.raw;
        else % non-flipped
          baseIM = FF.raw;
          guideIm = FF.filt;
        end

        IMF.filt = baseIM;
        IMF.imGuideNhoodSize = FF.GUI.nbhEditField.Value;
        IMF.imGuideSmoothValue = FF.GUI.smoothEditField.Value;
        IMF.Guided_Filtering(guideIm);
        % guided filter images tend to be grayish...give em some contrast back
        IMF.imadLimOut = [0 1];
        IMF.imadAuto = true;
        IMF.imadGamme = 1.20;
        IMF.Adjust_Contrast();
        FF.fusedFrangi = IMF.filt;

      case 'Binarized Frangi'
        % threshold + potential gaussian filter...
    end

    if ~isempty(FF.fusedFrangi)
      plotAx = FF.GUI.imFrangiFused.Children(1);
      set(plotAx, 'cdata', FF.fusedFrangi);
    end

    drawnow();
    FF.ProgBar = [];
  catch ME
    FF.ProgBar = [];
    rethrow(ME);
  end

end
