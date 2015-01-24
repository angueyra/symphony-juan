classdef TemplateStageProtocol < StageProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.TemplateStageProtocol'
        version = 1
        displayName = 'Template Stage Protocol'
    end
    
    properties
        amp
        preTime = 100
        stimTime = 500
        tailTime = 100
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    methods
        
        function prepareRun(obj)
            % Call the base class method.
            prepareRun@StageProtocol(obj);
            
            % obj.openFigure('Response', obj.amp);
        end
        
        
        function preparePresentation(obj, presentation)
            % Call the base class method.
            preparePresentation@StageProtocol(obj, presentation);
            
            spot = Ellipse();
            spot.position = obj.canvasSize/2;
            
            presentation.addStimulus(spot);
        end
        
        
        function keepGoing = continueRun(obj)
            % Call the base class method.
            keepGoing = continueRun@StageProtocol(obj);
            
            if keepGoing
                % keepGoing = obj.numEpochsCompleted < obj.numberOfAverages;
            end
        end
        
        
        function completeRun(obj)
            % Call the base class method.
            completeRun@StageProtocol(obj);
            
            
        end
        
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
    end
end