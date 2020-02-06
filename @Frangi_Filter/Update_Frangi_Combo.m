function Update_Frangi_Combo(FF)
  % FF.Update_Frangi_Combo() Combine selected frangi scales and apply to image

  FF.Update_ProgBar('Fusing Frangi and Raw');

  % Needs already calculated FF.filtScales, then used the max-amp projection
  % of those to form frangi filtered image...
  %
  % See also Update_Frangi_Scales(), Apply_Frangi(), Apply_Image_Processing()

  % only take selected scales into account
  if ~isempty(FF.filtScales)
    selectedScales = [FF.GUI.ScaleTable.Data{:, 2}];
    FF.filt = squeeze(max(FF.filtScales(:, :, selectedScales), [], 3));
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
