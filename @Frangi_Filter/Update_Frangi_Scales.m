function Update_Frangi_Scales(FF)
  % FF.ProgBar = uiprogressdlg(FF.GUI.UIFigure, 'Title', 'Updating Frangi scales...');
  % updating very fast, no need to put progress bar for that...
  
  if strcmp(FF.GUI.ScalesDropDown.Value, 'manual')
    FF.useScales = str2double(strsplit(FF.GUI.ScalesTextField.Value));
  else
    FF.startScale = FF.GUI.StartEditField.Value;
    FF.stopScale = FF.GUI.StopEditField.Value;
    FF.nScales = FF.GUI.nScalesEditField.Value;
    FF.useScales = FF.autoScales;
  end

  if strcmp(FF.GUI.UnitsDropDown.Value, 'pixel')
    FF.startScale = round(FF.startScale);
    FF.stopScale = round(FF.stopScale);
    FF.useScales = round(FF.useScales);
  end

  FF.useScales = sort(unique(FF.useScales)); % make sure we don't double scale ;-)
  FF.nScales = numel(FF.useScales);
  FF.GUI.nScalesEditField.Value = FF.nScales;
  FF.GUI.StartEditField.Value = FF.startScale;
  FF.GUI.StopEditField.Value = FF.stopScale;

  FF.GUI.ScaleTable.RowName = 'numbered';
  tdata = table(FF.useScales', true(FF.nScales, 1));
  FF.GUI.ScaleTable.Data = tdata;

end
