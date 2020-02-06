function Apply_Frangi(FF, unFilt)

  try
    
    % check if we actually have data to work with
    if nargin == 1
      unFilt = FF.raw;
    end
    
    if isempty(unFilt)
      return;
    end

    % check if app is acutally open / visible
    FF.Update_ProgBar('Frangi Filtering:',0);

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
      FF.filtScales(:, :, iScale) = iFilt;
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
