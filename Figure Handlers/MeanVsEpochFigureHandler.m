% Property Descriptions:
%
% MarkerColor (ColorSpec)
%   Color of the plotted markers. The default is blue.
%
% StartPt (integer)
%   The point in the response data to begin the mean calculation. The default is 1.
%
% EndPt (integer)
%   The point in the response data to end the mean calculation. The default is the end of the response.

classdef MeanVsEpochFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Mean vs. Epoch'
    end
    
    properties
        deviceName
        markerColor
        startPt
        endPt
        plotHandle
        windowPos
    end
    
    methods
        
        function obj = MeanVsEpochFigureHandler(protocolPlugin, deviceName, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addRequired('deviceName', @(x)ischar(x));
            ip.addParamValue('MarkerColor', 'b', @(x)ischar(x) || isvector(x));
            ip.addParamValue('StartPt', 1, @(x)isscalar(x));
            ip.addParamValue('EndPt', 0, @(x)isscalar(x));
            ip.parse(deviceName, varargin{:});
            
            obj = obj@FigureHandler(protocolPlugin, ip.Unmatched);
            obj.deviceName = ip.Results.deviceName;
            obj.markerColor = ip.Results.MarkerColor;
            obj.startPt = ip.Results.StartPt;
            obj.endPt = ip.Results.EndPt;
            if ispc %rig computer
                obj.windowPos=[5,880,560,170];
            else %simulation mode
                obj.windowPos=[5,880,400,170];
            end
            
            set(obj.figureHandle, 'Name', [obj.protocolPlugin.displayName ': ' obj.deviceName ' ' obj.figureType]);
            obj.moveWindow();
            set(obj.figureHandle, 'MenuBar', 'None');
            % Create button.
            uicontrol( ...
                'Parent', obj.figureHandle, ...
                'Units', 'points', ...
                'Position', [2 1 40 14], ...
                'BackgroundColor', get(obj.figureHandle, 'Color'), ...
                'Callback', @(h,d)clear(obj, h, d), ...
                'String', 'Clear');
            
            % Plot any stored means.
            averages = obj.storedAverages();
            if ~isempty(averages)
                obj.plotHandle = plot(obj.axesHandle(), 1:length(averages), averages, 'o', ...
                    'MarkerEdgeColor', obj.markerColor, ...
                    'MarkerFaceColor', obj.markerColor);
                xlabel(obj.axesHandle(), 'epoch');
                xlim(obj.axesHandle(), [0.5 length(averages) + 0.5]);
            end
        end
        
        
        function handleEpoch(obj, epoch)
            if ~epoch.containsParameter('RCepoch')%ignore AutoRC epochs
                responseData = epoch.response(obj.deviceName);
                
                if obj.endPt == 0
                    average = mean(responseData(obj.startPt:end));
                else
                    average = mean(responseData(obj.startPt:obj.endPt));
                end
                
                averages = obj.storedAverages();
                averages(end + 1) = average;
                obj.storedAverages(averages);
                
                if isempty(obj.plotHandle)
                    obj.plotHandle = plot(obj.axesHandle(), 1:length(averages), averages, 'o', ...
                        'MarkerEdgeColor', obj.markerColor, ...
                        'MarkerFaceColor', obj.markerColor);
                    xlabel(obj.axesHandle(), 'epoch');
                else
                    set(obj.plotHandle, 'XData', 1:length(averages), 'YData', averages);
                end
                
                set(obj.axesHandle(), 'XLim', [0.5 length(averages) + 0.5]);
            else %this is an RCepoch
                responseData = epoch.response(obj.deviceName);
                average = mean(responseData(1:epoch.parameters.RCpreTime/1e3*epoch.parameters.sampleRate));
                                
                averages = obj.storedAverages();
                averages(end + 1) = average;
                obj.storedAverages(averages);
                
                if isempty(obj.plotHandle)
                    obj.plotHandle = plot(obj.axesHandle(), 1:length(averages), averages, 'o', ...
                        'MarkerEdgeColor', obj.markerColor, ...
                        'MarkerFaceColor', obj.markerColor);
                    xlabel(obj.axesHandle(), 'epoch');
                else
                    set(obj.plotHandle, 'XData', 1:length(averages), 'YData', averages);
                end
                
                set(obj.axesHandle(), 'XLim', [0.5 length(averages) + 0.5]);
            end
        end
        
        
        function clear(obj, hObject, eventData) %#ok<INUSD>
            % Clear stored averages.
            
            cla(obj.axesHandle());
            xlim(obj.axesHandle(), [0.5 1.5]);
            
            obj.storedAverages([]);
            obj.plotHandle = [];
        end
        
        
        function clearFigure(obj)
            % Do nothing.
        end

        
    end
    
    methods (Static)
        
        function averages = storedAverages(averages)
            % This method stores means across figure handlers.
            
            persistent stored;
            if nargin > 0
                stored = averages;
            end
            averages = stored;
        end
        
    end
    
end