% Property Descriptions:
%
% LineColor (ColorSpec)
%   Color of the mean response line. The default is blue.
%
% StoredLineColor (ColorSpec)
%   Color of the stored mean response line. The default is dark red.
%
% GroupByParams (string | cell array of strings)
%   List of epoch parameters whose values are used to group mean responses. The default is all current epoch parameters.

classdef MeanResponseFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Mean Response'
    end
    
    properties
        deviceName
        lineColor
        meanPlots   % array of structures to store the properties of each class of epoch.
        meanParamNames
        storedLineColor
        windowPos=[5,5,1300,390];%[0,0,560,380];
        lpf_freq=60;
    end
    
    methods
        
        function obj = MeanResponseFigureHandler(protocolPlugin, deviceName, varargin)           
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addParamValue('LineColor', [0 0 1], @(x)ischar(x) || isvector(x));
            ip.addParamValue('StoredLineColor', [0.75 0 0], @(x)ischar(x) || isvector(x));
            ip.addParamValue('GroupByParams', {}, @(x)iscell(x) || ischar(x));
            
            % Allow deviceName to be an optional parameter.
            % inputParser.addOptional does not fully work with string variables.
            if nargin > 1 && any(strcmp(deviceName, ip.Parameters))
                varargin = [deviceName varargin];
                deviceName = [];
            end
            if nargin == 1
                deviceName = [];
            end
            
            ip.parse(varargin{:});
            
            obj = obj@FigureHandler(protocolPlugin, ip.Unmatched);
            obj.deviceName = deviceName;
            obj.lineColor = ip.Results.LineColor;
            obj.storedLineColor = ip.Results.StoredLineColor;
            
            if iscell(ip.Results.GroupByParams)
                obj.meanParamNames = ip.Results.GroupByParams;
            else
                obj.meanParamNames = {ip.Results.GroupByParams};
            end
            
            if ~isempty(obj.deviceName)
                set(obj.figureHandle, 'Name', [obj.protocolPlugin.displayName ': ' obj.deviceName ' ' obj.figureType]);
            end
            
            obj.moveWindow();
            set(obj.figureHandle, 'MenuBar', 'None');
            xlabel(obj.axesHandle(), 'time (s)');
            set(obj.axesHandle(), 'XTickMode', 'auto');
            
            % Create buttons.
            uicontrol( ...
                'Parent', obj.figureHandle, ...
                'Units', 'points', ...
                'Position', [2 1 40 14], ...
                'BackgroundColor', get(obj.figureHandle, 'Color'), ...
                'Callback', @(h,d)store(obj, h, d), ...
                'String', 'Store');
            
            uicontrol( ...
                'Parent', obj.figureHandle, ...
                'Units', 'points', ...
                'Position', [43 1 40 14], ...
                'BackgroundColor', get(obj.figureHandle, 'Color'), ...
                'Callback', @(h,d)clear(obj, h, d), ...
                'String', 'Clear');
            
            obj.resetPlots();
            
            % Plot any stored mean plots.
            hold(obj.axesHandle(), 'on');
            plots = obj.storedPlots();
            for i = 1:numel(plots)
                plots(i).plotHandle = plot(obj.axesHandle(), (1:length(plots(i).data)) / plots(i).sampleRate, plots(i).data, 'Color', obj.storedLineColor);
            end
            hold(obj.axesHandle(), 'off');
            
            obj.storedPlots(plots);
        end
        
        
        function handleEpoch(obj, epoch)
            if isempty(obj.deviceName)
                % Use the first device response found if no device name is specified.
                [responseData, sampleRate, units] = epoch.response();
            else
                [responseData, sampleRate, units] = epoch.response(obj.deviceName);
            end
            
            % Get the parameters for this "class" of epoch.
            % An epoch class is defined by a set of parameter values.
            if isempty(obj.meanParamNames)
                % Automatically detect the set of parameters.
                epochParams = obj.protocolPlugin.epochSpecificParameters(epoch);
            else
                % The protocol has specified which parameters to use.
                for i = 1:length(obj.meanParamNames)
                    epochParams.(obj.meanParamNames{i}) = epoch.getParameter(obj.meanParamNames{i});
                end
            end
            
            % Check if we have existing data for this class of epoch.
            meanPlot = struct([]);
            for i = 1:numel(obj.meanPlots)
                if isequal(obj.meanPlots(i).params, epochParams)
                    meanPlot = obj.meanPlots(i);
                    break;
                end
            end
            
            baselineSub=@(x,stpt,endpt)(x-mean(x(stpt:endpt)));
            
            if isempty(meanPlot)
                % This is the first epoch of this class to be plotted.
                meanPlot = {};
                meanPlot.params = epochParams;
%                 meanPlot.data = responseData;
                meanPlot.data = baselineSub(responseData,1,epoch.parameters.preTime/1e3*epoch.parameters.sampleRate);
                meanPlot.sampleRate = sampleRate;
                meanPlot.units = units;
                meanPlot.count = 1;                                              
                hold(obj.axesHandle(), 'on');
                % Baseline subtracted mean
                meanPlot.plotHandle(1) = plot(obj.axesHandle(), (1:length(meanPlot.data)) / sampleRate, meanPlot.data, 'Color', whithen(obj.lineColor,0.5));
                %Low Pass filtered version
                lpfdata = lowPassFilter(meanPlot.data,obj.lpf_freq,1/sampleRate);
                meanPlot.plotHandle(2) = plot(obj.axesHandle(), (1:length(meanPlot.data)) / sampleRate, lpfdata, 'Color', obj.lineColor);
                
                obj.meanPlots(end + 1) = meanPlot;
            else
                % This class of epoch has been seen before, add the current response to the mean.
                % TODO: Adjust response data to the same sample rate and unit as previous epochs if needed.
                % TODO: if the length of data is varying then the mean will not be correct beyond the min length.
%                 meanPlot.data = (meanPlot.data * meanPlot.count + responseData) / (meanPlot.count + 1);
                meanPlot.data = (meanPlot.data * meanPlot.count + baselineSub(responseData,1,epoch.parameters.preTime/1e3*epoch.parameters.sampleRate)) / (meanPlot.count + 1);
                meanPlot.count = meanPlot.count + 1;
                set(meanPlot.plotHandle(1), 'XData', (1:length(meanPlot.data)) / sampleRate, ...
                                         'YData', meanPlot.data);
                lpfdata = lowPassFilter(meanPlot.data,obj.lpf_freq,1/sampleRate);
                set(meanPlot.plotHandle(2), 'XData', (1:length(meanPlot.data)) / sampleRate, ...
                                         'YData', lpfdata);
                obj.meanPlots(i) = meanPlot;
            end
            
            % Update the y axis with the units of the response.
            ylabel(obj.axesHandle(), units);
            
            if isempty(epochParams)
                titleString = 'All epochs';
            else
                paramNames = fieldnames(epochParams);
                titleString = ['Grouped by ' humanReadableParameterName(paramNames{1})];
                for i = 2:length(paramNames) - 1
                    titleString = [titleString ', ' humanReadableParameterName(paramNames{i})];
                end
                if length(paramNames) > 1
                    titleString = [titleString ' and ' humanReadableParameterName(paramNames{end})];
                end
            end
            title(obj.axesHandle(), titleString);
        end
        
        
        function store(obj, hObject, eventData) %#ok<INUSD>
            % Store the current set of mean plots.
            
            obj.clear();
            plots = obj.meanPlots;
            
            for i = 1:numel(plots)
                plots(i).plotHandle = copyobj(obj.meanPlots(i).plotHandle, obj.axesHandle());
                set(plots(i).plotHandle(1), 'Color', whithen(obj.storedLineColor,0.5));
                set(plots(i).plotHandle(2), 'Color', obj.storedLineColor);
            end
            
            obj.storedPlots(plots);
        end
        
        
        function clear(obj, hObject, eventData) %#ok<INUSD>
            % Clear stored mean plots.
            
            plots = obj.storedPlots();
            for i = 1:numel(plots)
                delete(plots(i).plotHandle);
            end
            
            obj.storedPlots([]);
        end
        
        
        function clearFigure(obj)
            % Hide the stored mean plots before clearing the axes.
            plots = obj.storedPlots();
            for i = 1:numel(plots)
                set(plots(i).plotHandle, 'HandleVisibility', 'off');
            end
            
            clearFigure@FigureHandler(obj);
            
            % Unhide the stored mean plots now the the axes has been cleared.
            for i = 1:numel(plots)
                set(plots(i).plotHandle, 'HandleVisibility', 'on');
            end
            
            obj.resetPlots();
        end
        
        
        function resetPlots(obj)
            obj.meanPlots = struct('params', {}, ...        % The params that define this class of epochs.
                                   'data', {}, ...          % The mean of all responses of this class.
                                   'sampleRate', {}, ...    % The sampling rate of the mean response.
                                   'units', {}, ...         % The units of the mean response.
                                   'count', {}, ...         % The number of responses used to calculate the mean reponse.
                                   'plotHandle', {});       % The handle of the plot for the mean response of this class.
        end
       
        
    end
    
    methods (Static)
        
        function plots = storedPlots(plots)
            % This method stores plots across mean response figure handlers.
            
            persistent stored;
            if nargin > 0
                stored = plots;
            end
            plots = stored;
        end 
    end
    
end