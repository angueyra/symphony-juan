% Property Descriptions:
%
% LineColor1 (ColorSpec)
%   Color of the device1 response line. The default is blue.
%
% LineColor2 (ColorSpec)
%   Color of the device2 response line. The default is red.

classdef DualResponseFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Dual Response'
    end
    
    properties
        axesHandle1
        plotHandle1
        deviceName1
        lineColor1
        
        axesHandle2
        plotHandle2
        deviceName2
        lineColor2
    end
    
    methods
        
        function obj = DualResponseFigureHandler(protocolPlugin, deviceName1, deviceName2, varargin)            
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addRequired('deviceName1', @(x)ischar(x)); 
            ip.addParamValue('LineColor1', 'b', @(x)ischar(x) || isvector(x));
            ip.addRequired('deviceName2', @(x)ischar(x)); 
            ip.addParamValue('LineColor2', 'r', @(x)ischar(x) || isvector(x));
            ip.parse(deviceName1, deviceName2, varargin{:});
            
            obj = obj@FigureHandler(protocolPlugin, ip.Unmatched);
            obj.deviceName1 = ip.Results.deviceName1;
            obj.lineColor1 = ip.Results.LineColor1;
            obj.deviceName2 = ip.Results.deviceName2;
            obj.lineColor2 = ip.Results.LineColor2;          
            
            set(obj.figureHandle, 'Name', [obj.protocolPlugin.displayName ': ' obj.deviceName1 ' & ' obj.deviceName2 ' ' obj.figureType]);
                  
            % We don't need the superclass axes.
            % TODO: Remove axes creation from the superclass.
            delete(obj.axesHandle());
                        
            obj.axesHandle1 = axes('Position', [0.1 0.575 0.85 0.375]);
            obj.axesHandle2 = axes('Position', [0.1 0.1 0.85 0.375]);

            obj.initPlots();
        end
        
        
        function initPlots(obj)
            obj.plotHandle1 = plot(obj.axesHandle1, 1:100, zeros(1, 100), 'Color', obj.lineColor1);
            xlabel(obj.axesHandle1, 'sec');
            set(obj.axesHandle1, 'XTickMode', 'auto'); 
            
            obj.plotHandle2 = plot(obj.axesHandle2, 1:100, zeros(1, 100), 'Color', obj.lineColor2);
            xlabel(obj.axesHandle2, 'sec');
            set(obj.axesHandle2, 'XTickMode', 'auto'); 
        end
        
        
        function handleEpoch(obj, epoch)
            % Update the figure title with the epoch number and any parameters that are different from the protocol default.
            epochParams = obj.protocolPlugin.epochSpecificParameters(epoch);
            paramsText = '';
            if ~isempty(epochParams)
                for field = sort(fieldnames(epochParams))'
                    paramValue = epochParams.(field{1});
                    if islogical(paramValue)
                        if paramValue
                            paramValue = 'True';
                        else
                            paramValue = 'False';
                        end
                    elseif isnumeric(paramValue)
                        paramValue = num2str(paramValue);
                    end
                    paramsText = [paramsText ', ' humanReadableParameterName(field{1}) ' = ' paramValue]; %#ok<AGROW>
                end
            end
            set(get(obj.axesHandle1, 'Title'), 'String', ['Epoch #' num2str(obj.protocolPlugin.numEpochsCompleted) paramsText]);
            
            % Plot response1
            [responseData1, sampleRate1, units1] = epoch.response(obj.deviceName1);
            if isempty(responseData1)
                text(0.5, 0.5, 'no response data available', 'Parent', obj.plotHandle1, 'FontSize', 12, 'HorizontalAlignment', 'center');
            else
                set(obj.plotHandle1, 'XData', (1:numel(responseData1))/sampleRate1, ...
                                     'YData', responseData1);
                ylabel(obj.axesHandle1, units1);
            end
            
            % Plot response2
            [responseData2, sampleRate2, units2] = epoch.response(obj.deviceName2);            
            if isempty(responseData2)
                text(0.5, 0.5, 'no response data available', 'Parent', obj.plotHandle2, 'FontSize', 12, 'HorizontalAlignment', 'center');
            else
                set(obj.plotHandle2, 'XData', (1:numel(responseData2))/sampleRate2, ...
                                     'YData', responseData2);
                ylabel(obj.axesHandle2, units2);
            end
        end      
        
        
        function clearFigure(obj)
            clearFigure@FigureHandler(obj);
                        
            obj.initPlots();
        end
        
    end
    
end

