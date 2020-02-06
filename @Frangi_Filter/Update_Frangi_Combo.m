function Update_Frangi_Combo(FF)
  % FF.Update_Frangi_Combo() Combine selected frangi scales and apply to image
  % Needs already calculated FF.filtScales, then used the max-amp projection
  % of those to form frangi filtered image...

  FF.Update_ProgBar('Fusing Frangi and Raw');

  % calculate overall frangi filtered image by taking max of all scales...
  if ~isempty(FF.filtScales)
    % only take selected scales into account
    selectedScales = [FF.GUI.ScaleTable.Data{:, 2}];
    FF.filt = squeeze(max(FF.filtScales(:, :, selectedScales), [], 3));

    % check if we contrast adjust the individual scales...
    doClahe = FF.GUI.CLAHEFiltCheckBox.Value; % clahe each scale?
    doContrast = FF.GUI.ContrastFiltCheckBox.Value; % adj contr. each scale?
    if doClahe || doContrast
      IMF = Image_Filter(); % init Image filter class
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

  % combines Frangi & processes map to "filtered image";
  % TODO have different options on how to do this
  if ~isempty(FF.raw) &&~isempty(FF.filt)
    FF.fusedFrangi = normalize(FF.raw) .* FF.filt;
  else
    FF.fusedFrangi = [];
  end

  % TODO
  % implement non-linear comb using:
  % fitModel = '1/(1+exp(b*(c-x)))'; % b = spread, c = x0, x = frangi value

  % use image guided filtering here to combine raw and frangi!
  % we either use the frangi filtered image as our guide image
  % if FF.GUI.FrangiGuidedCheckBox.Value
  %   % calculate frangi filtered image if we don't have one already...
  %   if isempty(FF.frangiFilt)
  %     FF.Apply_Frangi(FF.IMF.filt);
  %   end

  %   FF.IMF.Guided_Filtering(FF.frangiFilt);
  %   % or we use the image itself...
  % end

  FF.ProgBar = [];

end
