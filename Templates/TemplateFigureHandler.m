classdef TemplateFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Template Figure Handler'
    end
    
    properties
        
    end
    
    methods
        
        function obj = TemplateFigureHandler(protocolPlugin, varargin)           
            ip = inputParser;
            ip.KeepUnmatched = true;
            % ip.addParamValue('GroupByParams', {}, @(x)iscell(x) || ischar(x));
            ip.parse(varargin{:});
            
            % Call base class method.
            obj = obj@FigureHandler(protocolPlugin, ip.Unmatched);
            
        end
        
        
        function handleEpoch(obj, epoch)
            % Handle complete epoch.
            
        end
        
        
        function clearFigure(obj)
            % Call base class method.
            clearFigure@FigureHandler(obj);
            
        end
        
    end
end