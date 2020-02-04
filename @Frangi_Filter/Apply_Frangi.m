function Apply_Frangi(FF, unFilt)

  % check if we actually have data to work with
  if nargin == 1
    unFilt = FF.raw;
  end

  if isempty(unFilt)
    return;
  end

  try
    unFilt = normalize(unFilt);
    FF.ProgBar = uiprogressdlg(FF.GUI.UIFigure, 'Title', 'Frangi Filtering ');

    sensitivity = FF.GUI.SensitivityEditField.Value;
    inverted = ~FF.GUI.InvertedCheckBox.Value;

    % useScales in micrometer / pixels
    sigmas = sort(FF.useScales);

    if strcmp(FF.GUI.UnitsDropDown.Value, 'physical')
      % convert to pixel (rounding done later in for loop)
      sigmas = sigmas ./ FF.dR;
    end

    nSigmas = length(sigmas);

    sigmas = double(sigmas);
    FF.filt = zeros(size(unFilt), 'like', unFilt); % filtered image
    FF.filtScales = zeros([size(unFilt) nSigmas], 'like', unFilt); % fitlered scales

    for iScale = 1:nSigmas
      FF.ProgBar.Value = iScale ./ nSigmas; % update progress bar
      FF.ProgBar.Message = sprintf('Filtering scale %i/%i...', iScale, nSigmas);
      % iSigma = sigmas(iScale);
      iSigma = sigmas(iScale) / 6; % FIXME why the 6 here???
      iFilt = imgaussfilt(unFilt, iSigma, 'FilterSize', 2 * ceil(3 * iSigma) + 1);
      iFilt = builtin("_fibermetricmex", iFilt, sensitivity, inverted, iSigma);
      FF.filtScales(:, :, iScale) = iFilt;
    end

    % combine frangi filtered and original image
    FF.Update_Frangi_Combo();

    % plot scale,  etc...
    FF.Plot_Frangi();

  catch me
    close(FF.ProgBar);
    rethrow(me);
  end

end
