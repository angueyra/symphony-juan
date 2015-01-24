% Property Descriptions:
%
% MarkerColor1 (ColorSpec)
%   Color of the plotted markers for device1. The default is blue.
%
% MarkerColor2 (ColorSpec)
%   Color of the plotted markers for device2. The default is red.
%
% StartPt (integer)
%   The point in the response data to begin the mean calculation. The default is 1.
%
% EndPt (integer)
%   The point in the response data to end the mean calculation. The default is the end of the response.

classdef DualMeanVsEpochFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Dual Mean vs. Epoch'
    end
    
    properties
        axesHandle1
        plotHandle1
        deviceName1
        markerColor1
        
        axesHandle2
        plotHandle2
        deviceName2
        markerColor2
        
        startPt
        endPt
    end
    
    methods
        
        function obj = DualMeanVsEpochFigureHandler(protocolPlugin, deviceName1, deviceName2, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addRequired('deviceName1', @(x)ischar(x));
            ip.addParamValue('MarkerColor1', 'b', @(x)ischar(x) || isvector(x));
            ip.addRequired('deviceName2', @(x)ischar(x));
            ip.addParamValue('MarkerColor2', 'r', @(x)ischar(x) || isvector(x));
            ip.addParamValue('StartPt', 1, @(x)isscalar(x));
            ip.addParamValue('EndPt', 0, @(x)isscalar(x));
            ip.parse(deviceName1, deviceName2, varargin{:});
            
            obj = obj@FigureHandler(protocolPlugin, ip.Unmatched);
            obj.deviceName1 = ip.Results.deviceName1;
            obj.markerColor1 = ip.Results.MarkerColor1;
            obj.deviceName2 = ip.Results.deviceName2;
            obj.markerColor2 = ip.Results.MarkerColor2;
            obj.startPt = ip.Results.StartPt;
            obj.endPt = ip.Results.EndPt;
            
            set(obj.figureHandle, 'Name', [obj.protocolPlugin.displayName ': ' obj.deviceName1 ' & ' obj.deviceName2 ' ' obj.figureType]);
            
            % We don't need the superclass axes.
            % TODO: Remove axes creation from the superclass.
            delete(obj.axesHandle());
            
            obj.axesHandle1 = axes('Position', [0.1 0.575 0.85 0.375]);
            obj.axesHandle2 = axes('Position', [0.1 0.1 0.85 0.375]);
            
            % Create button.
            uicontrol( ...
                'Parent', obj.figureHandle, ...
                'Units', 'points', ...
                'Position', [2 1 40 14], ...
                'BackgroundColor', get(obj.figureHandle, 'Color'), ...
                'Callback', @(h,d)clear(obj, h, d), ...
                'String', 'Clear');
            
            % Plot any stored means.
            averages1 = obj.storedAverages1();
            if ~isempty(averages1)
                obj.plotHandle1 = plot(obj.axesHandle1, 1:length(averages1), averages1, 'o', ...
                    'MarkerEdgeColor', obj.markerColor1, ...
                    'MarkerFaceColor', obj.markerColor1);
                xlabel(obj.axesHandle1, 'epoch');
                xlim(obj.axesHandle1, [0.5 length(averages1) + 0.5]);
            end
            
            averages2 = obj.storedAverages2();
            if ~isempty(averages2)
                obj.plotHandle2 = plot(obj.axesHandle2, 1:length(averages2), averages2, 'o', ...
                    'MarkerEdgeColor', obj.markerColor2, ...
                    'MarkerFaceColor', obj.markerColor2);
                xlabel(obj.axesHandle2, 'epoch');
                xlim(obj.axesHandle2, [0.5 length(averages2) + 0.5]);
            end
        end
        
        
        function handleEpoch(obj, epoch)
            responseData1 = epoch.response(obj.deviceName1);
            responseData2 = epoch.response(obj.deviceName2);
            
            if obj.endPt == 0
                average1 = mean(responseData1(obj.startPt:end));
                average2 = mean(responseData2(obj.startPt:end));
            else
                average1 = mean(responseData1(obj.startPt:obj.endPt));
                average2 = mean(responseData2(obj.startPt:obj.endPt));
            end
            
            averages1 = obj.storedAverages1();
            averages1(end + 1) = average1;
            obj.storedAverages1(averages1);
            
            if isempty(obj.plotHandle1)
                obj.plotHandle1 = plot(obj.axesHandle1, 1:length(averages1), averages1, 'o', ...
                    'MarkerEdgeColor', obj.markerColor1, ...
                    'MarkerFaceColor', obj.markerColor1);
                xlabel(obj.axesHandle1, 'epoch');
            else
                set(obj.plotHandle1, 'XData', 1:length(averages1), 'YData', averages1);
            end
            
            set(obj.axesHandle1, 'XLim', [0.5 length(averages1) + 0.5]);
            
            averages2 = obj.storedAverages2();
            averages2(end + 1) = average2;
            obj.storedAverages2(averages2);
            
            if isempty(obj.plotHandle2)
                obj.plotHandle2 = plot(obj.axesHandle2, 1:length(averages2), averages2, 'o', ...
                    'MarkerEdgeColor', obj.markerColor2, ...
                    'MarkerFaceColor', obj.markerColor2);
                xlabel(obj.axesHandle2, 'epoch');
            else
                set(obj.plotHandle2, 'XData', 1:length(averages2), 'YData', averages2);
            end
            
            set(obj.axesHandle2, 'XLim', [0.5 length(averages2) + 0.5]);
        end
        
        
        function clear(obj, hObject, eventData) %#ok<INUSD>
            % Clear stored averages.
            
            cla(obj.axesHandle1);
            xlim(obj.axesHandle1, [0.5 1.5]);
            obj.storedAverages1([]);
            obj.plotHandle1 = [];
            
            cla(obj.axesHandle2);
            xlim(obj.axesHandle2, [0.5 1.5]);
            obj.storedAverages2([]);
            obj.plotHandle2 = [];
        end
        
        
        function clearFigure(obj)
            % Do nothing.
        end
        
    end
    
    methods (Static)
        
        function averages = storedAverages1(averages)
            % This method stores mean across figure handlers for device1.
            
            persistent stored;
            if nargin > 0
                stored = averages;
            end
            averages = stored;
        end
        
        
        function averages = storedAverages2(averages)
            % This method stores means across figure handlers for device2.
            
            persistent stored;
            if nargin > 0
                stored = averages;
            end
            averages = stored;
        end
        
    end
    
end