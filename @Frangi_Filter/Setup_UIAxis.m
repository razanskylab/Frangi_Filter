function Setup_UIAxis(FF, UIAxis, showColorbar)

  if nargin < 3
    showColorbar = false;
  end

  disableDefaultInteractivity(UIAxis);
  UIAxis.Toolbar.Visible = 'off';
  axis(UIAxis, 'image');
  axis(UIAxis, 'tight');
  colormap(UIAxis, FF.GUI.ColormapDropDown.Value);
  cla(UIAxis); % clear axis, also removes all children
  imagesc(UIAxis, nan(1));

  if showColorbar
    c = colorbar(UIAxis);
    c.Location = 'southoutside';
  end

end
