function [filtIm] = Apply_Full(FF, unFilt)
  % applies Frangi filtering in the same way as the GUI does, but does
  % not require the GUI.
  % Difference vs. simple .Apply :
  %

  try
    % check if we actually have data to work with
    if nargin == 1
      unFilt = FF.raw;
    end

    if isempty(unFilt)
      return;
    end

    % get basic data we always need for frangi filtering
    unFilt = normalize(unFilt);

    % useScales in micrometer / pixels
    sigmas = sort(FF.useScales);
    sigmas = double(sigmas);
    nSigmas = length(sigmas);

    if FF.verboseOutput
      fprintf('[Frangi] Frangi filtering (scales %i-%i)...',minmax(sigmas));
      tic;
    end

    % NOTE for the scale filtering, we only use default values, they work fine
    if FF.doClaheScales || FF.doContrastScales
      IMF = Image_Filter(); % init Image filter class
      % setup solid default clahe settings
      IMF.claheNBins = 256;
      IMF.claheLim = FF.claheSensitivity;
      IMF.claheNTiles = [32 32];
      % setup solid default contrast settings
      IMF.imadLimOut = [0 1];
      IMF.imadAuto = true;
      IMF.imadGamme = FF.contrastGamma;
    end

    FF.filt = zeros(size(unFilt), 'like', unFilt); % filtered image
    FF.filtScales = zeros([size(unFilt) nSigmas], 'like', unFilt); % fitlered scales

    % Actual Frangi Filtering happening here... %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for iScale = 1:nSigmas
      iSigma = sigmas(iScale) / 6; % FIXME why the 6 here???

      iFilt = imgaussfilt(unFilt, iSigma, 'FilterSize', 2 * ceil(3 * iSigma) + 1);
      iFilt = builtin("_fibermetricmex", iFilt, FF.sensitivity, ~FF.invert, iSigma);

      % iFilt can be all zeros depending on filter, if that is the case,
      % continue as filtScales is already initialized with zeros...
      if ~any(iFilt(:))
        continue;
      end

      % we have data, do something with it...
      if FF.doClaheScales
        IMF.filt = iFilt;
        iFilt = IMF.Apply_CLAHE();
      end

      if FF.doContrastScales
        IMF.filt = iFilt;
        iFilt = IMF.Adjust_Contrast();
      end

      FF.filtScales(:, :, iScale) = iFilt;
    end

    % Postprocessing of Frangi-Filtered images ..%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % calculate overall frangi filtered image by taking max of all scales...
    % then apply potential contrast adjustments
    % NOTE more advanced combinations of Frangi and Raw @ .Update_Frangi_Combo.

    if ~isempty(FF.filtScales)
      % only take selected scales into account
      FF.filt = squeeze(max(FF.filtScales, [], 3));
      FF.filt = normalize(FF.filt);

      if FF.doPostClahe || FF.doPostContrast
        FF.filt = IMF.filt; % transfer image data back ...

        if doClahe
          % setup solid default clahe settings
          IMF.Apply_CLAHE();
        end

        if doContrast
          % setup solid default contrast settings
          IMF.Adjust_Contrast();
        end

        FF.filt = IMF.filt; % transfer image data back ...
        FF.filt = normalize(FF.filt);
      end

    end

    if FF.verboseOutput
      done(toc);
    end

    if FF.verbosePlotting
      FF.Show();
    end

    if nargout
      filtIm = FF.filt;
    end

  catch me
    rethrow(me);
  end

end
