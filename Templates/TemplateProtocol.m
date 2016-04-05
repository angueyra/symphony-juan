classdef TemplateProtocol < PulsedProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.TemplateProtocol'
        version = 1
        displayName = 'Template Protocol'
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
            prepareRun@PulsedProtocol(obj);
            
            % obj.openFigure('Response', obj.amp);
        end
        
        
        function prepareEpoch(obj, epoch)
            % Call the base class method.
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            % p = PulseGenerator();
            % p.preTime = obj.preTime;
            % p.stimTime = obj.stimTime;
            % p.tailTime = obj.tailTime;
            % p.amplitude = obj.amp2PulseSignal - obj.amp2HoldSignal;
            % p.mean = obj.amp2HoldSignal;
            % p.sampleRate = obj.sampleRate;
            % if strcmp(obj.rigConfig.multiClampMode(obj.amp2), 'VClamp')
            %     p.units = 'mV';
            % else
            %     p.units = 'pA';
            % end
            % stim = p.generate();
            % epoch.addStimulus(obj.amp, stim);
        end
        
        
        function completeEpoch(obj, epoch)
            % Call the base class method.
            completeEpoch@PulsedProtocol(obj, epoch);
            
            
        end
        
        
        function keepQueuing = continueQueuing(obj)
            % Call the base class method.
            keepQueuing = continueQueuing@PulsedProtocol(obj);
            
            if keepQueuing
                % keepQueuing = obj.numEpochsQueued < obj.numberOfAverages;
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % Call the base class method.
            keepGoing = continueRun@PulsedProtocol(obj);
            
            if keepGoing
                % keepGoing = obj.numEpochsCompleted < obj.numberOfAverages;
            end
        end
        
        
        function completeRun(obj)
            % Call the base class method.
            completeRun@PulsedProtocol(obj);
            
            
        end
        
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
    end
end