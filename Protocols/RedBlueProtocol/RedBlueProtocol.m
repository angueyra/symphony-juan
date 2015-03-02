classdef RedBlueProtocol < PulsedProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.frieke.RedBlueProtocol'
        version = 1
        displayName = 'Red-Blue Protocol'
    end
    
    properties
        preTime = 100
        stimTime = 10
        tailTime = 400
        led1
        Amplitude1 = 1
        Mean1 = 1
        led2
        Amplitude2 = 1
        Mean2 = 1
        amp
    end
            
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties
        amp2HoldSignal = 0
    end
        
    methods

        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            switch parameterName
                case {'led1', 'led2'}
                    p.defaultValue = obj.rigConfig.deviceNames('led');
                    p.description = 'select corresponding LED from rig configuration';
                case {'Amplitude1', 'Mean1', 'Amplitude2','Mean2'}
                    p.units = 'V';
                case 'interpulseInterval'
                    p.units = 's';
            end
        end        
        
        function prepareRun(obj)
            % Call the base class method.
            prepareRun@PulsedProtocol(obj);
            
            % Open figure handlers.
            if obj.rigConfig.numMultiClampDevices() > 1
                obj.openFigure('Dual Response', obj.amp, obj.amp2);
                obj.openFigure('Dual Mean Response', obj.amp, obj.amp2);
            else
                obj.openFigure('Response', obj.amp);
                obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'PlotGroup'});
            end
            
        end
        
        function stim = ledStimulus(obj,LED,cnt)
            % Main LED stimulus.
            p = PulseGenerator();
            
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            if (cnt == 1)
                led1mean = 0;
                led2mean = obj.Mean2;
            else
                led1mean = obj.Mean1;
                led2mean = 0;
            end
            
            switch LED
                case 1
                    p.mean = led1mean;
                    p.amplitude = obj.Amplitude1;
                case 2
                    p.mean = led2mean;
                    p.amplitude = obj.Amplitude2;
            end
            
            p.sampleRate = obj.sampleRate;
            p.units = 'V';
            
            stim = p.generate();
            
        end
           
        function stimuli = sampleStimuli(obj)
            
            % Return LED stimulus for display in the edit parameters window.
            stimuli{1} = obj.ledStimulus(1, 1);
            stimuli{2} = obj.ledStimulus(2, 1); 
            stimuli{3} = obj.ledStimulus(1, 2); 
            stimuli{4} = obj.ledStimulus(2, 2); 
            
        end
         
        function completeEpoch(obj, epoch)
            % Call the base class method.
            completeEpoch@PulsedProtocol(obj, epoch);   
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            cnt = rem(obj.numEpochsQueued, 2) + 1;
            epoch.addParameter('PlotGroup', cnt);
            LEDs = {'led1', 'led2'};
            for LED = 1:2
                epoch.addStimulus(obj.(LEDs{LED}), obj.ledStimulus(LED, cnt));
            end
            
        end
        
        function keepQueuing = continueQueuing(obj)
            % Call the base class method.
            keepQueuing = continueQueuing@PulsedProtocol(obj);
            
            if keepQueuing
%                  keepQueuing = obj.numEpochsQueued < obj.numberOfAverages;
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % Call the base class method.
            keepGoing = continueRun@PulsedProtocol(obj);
            
            if keepGoing
%                  keepGoing = obj.numEpochsCompleted < obj.numberOfAverages;
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