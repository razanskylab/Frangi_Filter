% Class to perform frangi filtering, returns scales and combined frangi filtered
% images, can also generate overlay maskes of frangi scales.

classdef Frangi_Filter < handle

  properties
    x; y; % plot vectors with units (mm)

    % original xy map, as first input into class, never changed internally
    raw(:, :) single {mustBeNumeric, mustBeFinite};
    % xy map after frangi filtering
    filt(:, :) single {mustBeNumeric, mustBeFinite};
    % images of seperate frangi scales
    filtScales(:, :, :) single {mustBeNumeric, mustBeFinite};
    % seperate frangi scales
    fusedFrangi(:, :) single {mustBeNumeric, mustBeFinite};
    % combination of frangiFilt & raw

    % frangi filtering options ---------------------------------------------------
    % frangi scales in micrometer
    startScale double {mustBeNumeric, mustBeFinite} = 5;
    stopScale double {mustBeNumeric, mustBeFinite} = 500;
    nScales double {mustBeNumeric, mustBeFinite} = 6;

    % sensitivity used for matlab filtering
    sensitivity single {mustBeNumeric, mustBeFinite} = 0.05;

    % betaOne and Two used for older filtering
    betaOne = 2; % seems to have little impact for fixed betaTwo
    betaTwo = 0.11; % smaller values = more "vessels"

    showScales {mustBeNumericOrLogical} = false;
    invert {mustBeNumericOrLogical} = false;

    % output control
    colorMap = 'gray'; % use for simple plotting
    verboseOutput {mustBeNumericOrLogical} = false;
    showHisto {mustBeNumericOrLogical} = false; % default don't show histo for xy-plots
  end

  % gui related properties
  properties
    GUI; % handle to optional GUI (FF.Open_GUI);
    ProgBar;
  end

  properties (SetAccess = private)
    % step sizes, calculated automatically from x,y,z using get methods, can't be set!
    dX; dY;
    dR; % average x-y pixels size

    autoScales; % when not manually selected, we calculate the autoScales
    useScales; % these scales are used for the actual filtering, can be manually
    % entered or automatically
    allEffectiveScales;
  end

  properties (Hidden = true)
    % used only for CLAHE when showing frangi scales
    claheDistr = 'exponential'; % 'uniform''rayleigh''exponential' Desired histogram shape
    claheNBins = 256; % histogram bins used for contrast enhancing transformation
    claheLim = 0.02; % enhancement limit, [0, 1], higher limits result in more contrast
    claheNTiles = [32 32]; % image divided into M x N tiles, 'NumTiles' = [M N]
  end

  events
    FiltUpdated; % used to update Maps class
  end

  % Methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods
    % class constructor - needs to be in here!
    % note that if first input arg when creating new instance of class is a
    % Maps object then we will create a deep copy of the data, this is neccesary
    % because a simple copy of a handle object only creates a shallow copy
    % and if we don't make it a handle class then things lile F.Norm don't work
    % and we would have to write M = F.Norm which makes things messy again...
    function newFrangi = Frangi_Filter(varargin)
      className = class(newFrangi);

      if nargin

        if isa(varargin{1}, className)
          % Construct a new object based on a deep copy of an old object
          oldMap = varargin{1}; % copy data from this "old" Map
          props = properties(oldMap); % get all properties
          % turn off warnigs during deep copy to ignore methods
          % that compalain that there is no data when queried later...
          preWarnSettings = warning();
          warning('off')

          for i = 1:length(props)
            newFrangi.(props{i}) = oldMap.(props{i});
          end

          warning(preWarnSettings);
        elseif isa(varargin{1}, 'Maps')% construct from Maps class
          mapClass = varargin{1};
          newFrangi.x = mapClass.x;
          newFrangi.y = mapClass.y;
          newFrangi.filt = mapClass.xy;
          newFrangi.verboseOutput = mapClass.verboseOutput;
        elseif isnumeric(varargin{1})% 2d array
          % calculate raw MIPs directly from 3d dataset
          newFrangi.filt = varargin{1};
          % assign vectors as well if provided
          if nargin == 3
            newFrangi.x = varargin{2};
            newFrangi.y = varargin{3};
          end

        end

      end

    end

    function saveFrangi = saveobj(FF)
      % don't save empty objects...
      if isempty(FF.filt)
        saveFrangi = [];
      else
        saveFrangi = FF;
      end

    end

    % convenience function for plotting
    function P(FF, varargin)
      FF.Plot(varargin{:});
    end

    % Open GUI and hand over this class
    function Open_GUI(FF)
      FrangiGui(FF);
    end

  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % XY and related set/get functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods

    % get position vectos, always return as double! ----------------------------
    function x = get.x(F)

      if ~isempty(F.x)
        x = double(F.x);
      elseif ~isempty(F.filt)
        nX = size(F.filt, 2);
        x = 1:nX;
      elseif ~isempty(F.raw)
        nX = size(F.raw, 2);
        x = 1:nX;
      else
        x = [];
      end

    end

    function y = get.y(F)

      if ~isempty(F.y)
        y = double(F.y);
      elseif ~isempty(F.filt)
        nY = size(F.filt, 1);
        y = 1:nY;
      elseif ~isempty(F.raw)
        nY = size(F.raw, 1);
        y = 1:nY;
      else
        y = [];
      end

    end

    % calculate step sizes based on x and y vectors ----------------------------
    function dX = get.dX(F)

      if isempty(F.x)
        dX = 1;
      else
        dX = mean(diff(F.x));
      end

    end

    function dY = get.dY(F)

      if isempty(F.x)
        dY = 1;
      else
        dY = mean(diff(F.y));
      end

    end

    % calculate an avearge xy step size, warn if error large -------------------
    function dR = get.dR(F)

      if isempty(F.dX) || isempty(F.dY)
        dR = 1;
      else
        stepSize = mean([F.dX, F.dY]);
        stepSizeDiff = 100 * abs(F.dX - F.dY) / stepSize; % [in% compared to avarage step size]
        allowedStepsizeDiff = 10; % [in%]

        if stepSizeDiff > allowedStepsizeDiff
          fprintf('\n'); % close line
          warnMessage = sprintf(...
            'Large difference in step size between x (%2.1fum) and y (%2.1fum)!', ...
            F.dX * 1e3, F.dY * 1e3);
          short_warn(warnMessage);
        end

        dR = stepSize;
      end

    end

    % get all scales (these are transformed into effective scales below)
    function autoScales = get.autoScales(F)
      autoScales = linspace(F.startScale, F.stopScale, F.nScales);
    end

    % effective scales are scales scaled by the pixel density and then some...
    function allEffectiveScales = get.allEffectiveScales(F)
      pixelDensity = 1 / F.dR * 1e3;
      allEffectiveScales = F.autoScales .* pixelDensity * 1e-5;
    end

    function set.filt(F, map)
      % set raw map on first asginement of xy map
      if isempty(F.filt) && isempty(F.raw)
        F.raw = map;
      end

      F.filt = map;
    end

  end % end of methods definition

  %<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  methods (Static)

  end % end of methods(Static)

end % end of class definition
