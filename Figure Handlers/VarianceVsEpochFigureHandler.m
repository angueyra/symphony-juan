% Property Descriptions:
%
% MarkerColor (ColorSpec)
%   Color of the plotted markers. The default is blue.
%
% StartPt (integer)
%   The point in the response data to begin the variance calculation. The default is 1.
%
% EndPt (integer)
%   The point in the response data to end the variance calculation. The default is the end of the response.

classdef VarianceVsEpochFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Variance vs. Epoch'
    end
    
    properties
        deviceName
        markerColor
        startPt
        endPt
        plotHandle
        windowPos=[565,0,560,350];
    end
    
    methods
        
        function obj = VarianceVsEpochFigureHandler(protocolPlugin, deviceName, varargin)
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
            
            % Plot any stored variances.
            variances = obj.storedVariances();
            if ~isempty(variances)
                obj.plotHandle = plot(obj.axesHandle(), 1:length(variances), variances, 'o', ...
                    'MarkerEdgeColor', obj.markerColor, ...
                    'MarkerFaceColor', obj.markerColor);
                xlabel(obj.axesHandle(), 'epoch');
                xlim(obj.axesHandle(), [0.5 length(variances) + 0.5]);
            end
        end
        
        
        function handleEpoch(obj, epoch)
            responseData = epoch.response(obj.deviceName);
            
            if obj.endPt == 0
                variance = var(responseData(obj.startPt:end));
            else
                variance = var(responseData(obj.startPt:obj.endPt));
            end
            
            variances = obj.storedVariances();
            variances(end + 1) = variance;
            obj.storedVariances(variances);
            
            if isempty(obj.plotHandle)
                obj.plotHandle = plot(obj.axesHandle(), 1:length(variances), variances, 'o', ...
                    'MarkerEdgeColor', obj.markerColor, ...
                    'MarkerFaceColor', obj.markerColor);
                xlabel(obj.axesHandle(), 'epoch');
            else
                set(obj.plotHandle, 'XData', 1:length(variances), 'YData', variances);
            end
            
            set(obj.axesHandle(), 'XLim', [0.5 length(variances) + 0.5]);
        end
        
        
        function clear(obj, hObject, eventData) %#ok<INUSD>
            % Clear stored variances.
            
            cla(obj.axesHandle());
            xlim(obj.axesHandle(), [0.5 1.5]);
            
            obj.storedVariances([]);
            obj.plotHandle = [];
        end
        
        
        function clearFigure(obj)
            % Do nothing.
        end
        
        function moveWindow(obj)
            set(obj.figureHandle(), 'position', obj.windowPos);
        end
    end
    
    methods (Static)
        
        function variances = storedVariances(variances)
            % This method stores variances across figure handlers.
            
            persistent stored;
            if nargin > 0
                stored = variances;
            end
            variances = stored;
        end
        
    end
    
end