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
    rawFactor = FF.GUI.RawEditField.Value;
    frangiFactor = FF.GUI.FrangiEditField.Value;

    % combines Frangi & processes map to fusedFrangi
    % TODO have different options on how to do this
    switch FF.GUI.FusingTechDropDown.Value
      case 'Frangi Only'
        FF.fusedFrangi = FF.filt;
      case 'Linear Combination'

        if strcmp(FF.GUI.LinCombDropDown.Value, 'sum')
          FF.fusedFrangi = FF.raw .* rawFactor + FF.filt .* frangiFactor;
        elseif strcmp(FF.GUI.LinCombDropDown.Value, 'prod')
          FF.fusedFrangi = FF.raw .* FF.filt;
        end

      case 'Non-Linear Combination'
        spread = FF.GUI.spreadEditField.Value;
        shift = FF.GUI.cutoffEditField.Value;
        FF.filt = log_fun(FF.filt, 1, spread, shift);
        FF.filt = normalize(FF.filt);
        if strcmp(FF.GUI.LinCombDropDown.Value, 'sum')
          FF.fusedFrangi = FF.raw .* rawFactor + FF.filt .* frangiFactor;
        elseif strcmp(FF.GUI.LinCombDropDown.Value, 'prod')
          FF.fusedFrangi = FF.raw .* FF.filt;
        end
      case 'Image Guided Filter'
        % filters baseIM using the guided filter, guided by guideIm
        baseIM = FF.raw;
        guideIm = FF.filt;

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

    % post processing, i.e. work on the combined image
    FF.fusedFrangi = normalize(FF.fusedFrangi);
    doPostClahe = FF.GUI.PostCLAHECheckBox.Value;
    doPostContrast = FF.GUI.PostContrastCheckBox.Value;
    if doPostClahe || doPostContrast
      IMF.filt = FF.fusedFrangi;
      if doPostClahe
        % setup solid default clahe settings
        IMF.claheNBins = 256;
        IMF.claheLim = FF.GUI.PostClaheClipLim.Value;
        IMF.claheNTiles = [32 32];
        IMF.Apply_CLAHE();
      end

      if doPostContrast
        % setup solid default contrast settings
        IMF.imadLimOut = [0 1];
        IMF.imadAuto = true;
        IMF.imadGamme = FF.GUI.ContrastGamma.Value;
        IMF.Adjust_Contrast();
      end
      FF.fusedFrangi = IMF.filt;
    end


    if ~isempty(FF.fusedFrangi)
      set(FF.FigHandles.CombiIm, 'cdata', FF.fusedFrangi);
    end
    if ~isempty(FF.fusedFrangi)
      set(FF.FigHandles.FrangiIm, 'cdata', FF.filt);
    end

    drawnow();
    FF.ProgBar = [];
  catch ME
    FF.ProgBar = [];
    rethrow(ME);
  end

end
