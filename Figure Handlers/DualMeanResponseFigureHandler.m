% Property Descriptions:
%
% LineColor1 (ColorSpec)
%   Color of the device1 response line. The default is blue.
%
% StoredLineColor1 (ColorSpec)
%   Color of the device1 stored response line. The default is magenta.
%
% LineColor2 (ColorSpec)
%   Color of the device2 response line. The default is red.
%
% StoredLineColor2 (ColorSpec)
%   Color of the device2 stored response line. The default is magenta.
%
% GroupByParams (string | cell array of strings)
%   List of epoch parameters whose values are used to group mean responses. The default is all current epoch parameters.

classdef DualMeanResponseFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Dual Mean Response'
    end
    
    properties
        axesHandle1
        plotHandle1
        deviceName1
        lineColor1
        storedLineColor1
        
        axesHandle2
        plotHandle2
        deviceName2
        lineColor2
        storedLineColor2
        
        meanPlots       % array of structures to store the properties of each class of epoch.
        meanParamNames
    end
    
    methods
        
        function obj = DualMeanResponseFigureHandler(protocolPlugin, deviceName1, deviceName2, varargin)           
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addRequired('deviceName1', @(x)ischar(x)); 
            ip.addParamValue('LineColor1', 'b', @(x)ischar(x) || isvector(x));
            ip.addParamValue('StoredLineColor1', 'm', @(x)ischar(x) || isvector(x));
            ip.addRequired('deviceName2', @(x)ischar(x)); 
            ip.addParamValue('LineColor2', 'r', @(x)ischar(x) || isvector(x));
            ip.addParamValue('StoredLineColor2', 'm', @(x)ischar(x) || isvector(x));
            ip.addParamValue('GroupByParams', {}, @(x)iscell(x) || ischar(x));
            ip.parse(deviceName1, deviceName2, varargin{:});
            
            obj = obj@FigureHandler(protocolPlugin, ip.Unmatched);
            obj.deviceName1 = ip.Results.deviceName1;
            obj.lineColor1 = ip.Results.LineColor1;
            obj.storedLineColor1 = ip.Results.StoredLineColor1;
            obj.deviceName2 = ip.Results.deviceName2;
            obj.lineColor2 = ip.Results.LineColor2;
            obj.storedLineColor2 = ip.Results.StoredLineColor2;
            
            if iscell(ip.Results.GroupByParams)
                obj.meanParamNames = ip.Results.GroupByParams;
            else
                obj.meanParamNames = {ip.Results.GroupByParams};
            end
            
            set(obj.figureHandle, 'Name', [obj.protocolPlugin.displayName ': ' obj.deviceName1 ' & ' obj.deviceName2 ' ' obj.figureType]);
                  
            % We don't need the superclass axes.
            % TODO: Remove axes creation from the superclass.
            delete(obj.axesHandle());
                        
            obj.axesHandle1 = axes('Position', [0.1 0.575 0.85 0.375]);
            xlabel(obj.axesHandle1, 'sec');
            set(obj.axesHandle1, 'XTickMode', 'auto');
            
            obj.axesHandle2 = axes('Position', [0.1 0.1 0.85 0.375]);
            xlabel(obj.axesHandle2, 'sec');
            set(obj.axesHandle2, 'XTickMode', 'auto');
            
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
            hold(obj.axesHandle1, 'on');
            hold(obj.axesHandle2, 'on');
            plots = obj.storedPlots();
            for i = 1:numel(plots)
                plots(i).plotHandle1 = plot(obj.axesHandle1, (1:length(plots(i).data1)) / plots(i).sampleRate1, plots(i).data1, 'Color', obj.storedLineColor1);
                plots(i).plotHandle2 = plot(obj.axesHandle2, (1:length(plots(i).data2)) / plots(i).sampleRate2, plots(i).data2, 'Color', obj.storedLineColor2);
            end
            hold(obj.axesHandle1, 'off');
            hold(obj.axesHandle2, 'off');
            
            obj.storedPlots(plots);
        end
        
        
        function handleEpoch(obj, epoch)
            [responseData1, sampleRate1, units1] = epoch.response(obj.deviceName1);
            [responseData2, sampleRate2, units2] = epoch.response(obj.deviceName2);
            
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
            
            if isempty(meanPlot)
                % This is the first epoch of this class to be plotted.
                meanPlot = {};
                meanPlot.params = epochParams;
                
                meanPlot.data1 = responseData1;
                meanPlot.sampleRate1 = sampleRate1;
                meanPlot.units1 = units1;
                hold(obj.axesHandle1, 'on');
                meanPlot.plotHandle1 = plot(obj.axesHandle1, (1:length(meanPlot.data1)) / sampleRate1, meanPlot.data1, 'Color', obj.lineColor1);
                
                meanPlot.data2 = responseData2;
                meanPlot.sampleRate2 = sampleRate2;
                meanPlot.units2 = units2;
                hold(obj.axesHandle2, 'on');
                meanPlot.plotHandle2 = plot(obj.axesHandle2, (1:length(meanPlot.data2)) / sampleRate2, meanPlot.data2, 'Color', obj.lineColor2);
                
                meanPlot.count = 1;
                obj.meanPlots(end + 1) = meanPlot;
            else
                % This class of epoch has been seen before, add the current response to the mean.
                % TODO: Adjust response data to the same sample rate and unit as previous epochs if needed.
                % TODO: if the length of data is varying then the mean will not be correct beyond the min length.
                meanPlot.data1 = (meanPlot.data1 * meanPlot.count + responseData1) / (meanPlot.count + 1);
                set(meanPlot.plotHandle1, 'XData', (1:length(meanPlot.data1)) / sampleRate1, ...
                          'YData', meanPlot.data1);
                
                meanPlot.data2 = (meanPlot.data2 * meanPlot.count + responseData2) / (meanPlot.count + 1);
                set(meanPlot.plotHandle2, 'XData', (1:length(meanPlot.data2)) / sampleRate2, ...
                                          'YData', meanPlot.data2);
                                      
                meanPlot.count = meanPlot.count + 1;
                obj.meanPlots(i) = meanPlot;
            end
            
            % Update the y axis with the units of the response.
            ylabel(obj.axesHandle1, units1);
            ylabel(obj.axesHandle2, units2);
            
            if isempty(epochParams)
                titleString = 'All epochs grouped together.';
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
            title(obj.axesHandle1, titleString);
        end
        
        
        function store(obj, hObject, eventData) %#ok<INUSD>
            % Store the current set of mean plots.
            
            obj.clear();
            plots = obj.meanPlots;
            
            for i = 1:numel(plots)
                plots(i).plotHandle1 = copyobj(obj.meanPlots(i).plotHandle1, obj.axesHandle1);
                set(plots(i).plotHandle1, 'Color', obj.storedLineColor1);
                
                plots(i).plotHandle2 = copyobj(obj.meanPlots(i).plotHandle2, obj.axesHandle2);
                set(plots(i).plotHandle2, 'Color', obj.storedLineColor2);
            end
            
            obj.storedPlots(plots);
        end
        
        
        function clear(obj, hObject, eventData) %#ok<INUSD>
            % Clear stored mean plots.
            
            plots = obj.storedPlots();
            for i = 1:numel(plots)
                delete(plots(i).plotHandle1);
                delete(plots(i).plotHandle2);
            end
            
            obj.storedPlots([]);
        end
        
        
        function clearFigure(obj)
            % Hide the stored mean plots before clearing the axes.
            plots = obj.storedPlots();
            for i = 1:numel(plots)
                set(plots(i).plotHandle1, 'HandleVisibility', 'off');
                set(plots(i).plotHandle2, 'HandleVisibility', 'off');
            end
            
            clearFigure@FigureHandler(obj);
            
            % Unhide the stored mean plots now the the axes has been cleared.
            for i = 1:numel(plots)
                set(plots(i).plotHandle1, 'HandleVisibility', 'on');
                set(plots(i).plotHandle2, 'HandleVisibility', 'on');
            end
            
            obj.resetPlots();
        end
        
        
        function resetPlots(obj)
            obj.meanPlots = struct('params', {}, ...        % The params that define this class of epochs.
                                   'data1', {}, ...         % The mean of all device1 responses of this class.
                                   'sampleRate1', {}, ...   % The sampling rate of the device1 mean response.
                                   'units1', {}, ...        % The units of the device1 mean response.
                                   'plotHandle1', {}, ...   % The handle of the plot for the device1 mean response of this class.
                                   'data2', {}, ...         % The mean of all device2 responses of this class.
                                   'sampleRate2', {}, ...   % The sampling rate of the device2 mean response.
                                   'units2', {}, ...        % The units of the device2 mean response.
                                   'plotHandle2', {}, ...   % The handle of the plot for the device2 mean response of this class.
                                   'count', {});            % The number of responses used to calculate the mean reponse.
                               
            ylabel(obj.axesHandle1, '');
            ylabel(obj.axesHandle2, '');
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