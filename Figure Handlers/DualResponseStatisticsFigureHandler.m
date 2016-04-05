classdef DualResponseStatisticsFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Dual Response Statistics'
        plotColors = 'rbykmc';
    end
    
    properties
        axesHandle1
        statsCallback1
        statPlots1
        
        axesHandle2
        statsCallback2
        statPlots2
    end
    
    methods
        
        function obj = DualResponseStatisticsFigureHandler(protocolPlugin, varargin)
            obj = obj@FigureHandler(protocolPlugin);
            
            ip = inputParser;
            ip.addParamValue('StatsCallback1', [], @(x)isa(x, 'function_handle'));
            ip.addParamValue('StatsCallback2', [], @(x)isa(x, 'function_handle'));
            ip.parse(varargin{:});
            
            if isempty(ip.Results.StatsCallback1) || isempty(ip.Results.StatsCallback2)
                obj.close();
                error 'The StatsCallback1 and StatsCallback2 parameters must be supplied for Response Statistics figures.'
            end
            
            obj.statsCallback1 = ip.Results.StatsCallback1;
            obj.statsCallback2 = ip.Results.StatsCallback2;
            
            % We don't need the superclass axes.
            % TODO: Remove axes creation from the superclass.
            delete(obj.axesHandle());
            
            obj.axesHandle1 = axes('Position', [0.1 0.575 0.85 0.375]);
            xlabel(obj.axesHandle1, 'epoch');
            
            obj.axesHandle2 = axes('Position', [0.1 0.1 0.85 0.375]);
            xlabel(obj.axesHandle2, 'epoch');
            %set(obj.axesHandle1, 'XTickMode', 'auto');
            
            obj.statPlots1 = struct;
            obj.statPlots2 = struct;
        end


        function handleEpoch(obj, epoch)
            % Ask the callback for the statistics
            stats1 = obj.statsCallback1(obj.protocolPlugin, epoch);
            obj.statPlots1 = obj.addStats(stats1, obj.axesHandle1, obj.statPlots1);
            
            stats2 = obj.statsCallback2(obj.protocolPlugin, epoch);
            obj.statPlots2 = obj.addStats(stats2, obj.axesHandle2, obj.statPlots2);
        end
        
        
        function statPlots = addStats(obj, stats, axesHandle, statPlots)
            statNames = fieldnames(stats);
            for i = 1:numel(statNames)
                statName = statNames{i};
                stat = stats.(statName);

                if isfield(statPlots, statName)
                    statPlots.(statName).xData(end + 1) = obj.protocolPlugin.numEpochsCompleted;
                    statPlots.(statName).yData(end + 1) = stat;
                    set(statPlots.(statName).plotHandle, 'XData', statPlots.(statName).xData, ...
                                                         'YData', statPlots.(statName).yData);
                    set(axesHandle, 'XTickMode', 'auto');
                else
                    statPlot = {};
                    statPlot.xData = obj.protocolPlugin.numEpochsCompleted;
                    statPlot.yData = stat;
                    plotColor = obj.plotColors(numel(fieldnames(statPlots)) + 1);
                    hold(axesHandle, 'on');
                    statPlot.plotHandle = plot(axesHandle, statPlot.xData, statPlot.yData, 'o', ...
                                               'MarkerEdgeColor', plotColor, ...
                                               'MarkerFaceColor', plotColor);
                    statPlots.(statName) = statPlot;
                end
                
                set(axesHandle, 'XTick', 1:obj.protocolPlugin.numEpochsCompleted, ...
                                'XLim', [0.5 obj.protocolPlugin.numEpochsCompleted + 0.5]);
            end 
        end
        
        
        function clearFigure(obj)
            obj.statPlots1 = struct;
            obj.statPlots2 = struct;
            
            clearFigure@FigureHandler(obj);
        end
        
    end
    
end