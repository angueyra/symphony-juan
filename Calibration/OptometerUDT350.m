classdef OptometerUDT350 < handle
    
    properties (Constant)
        outputMax = 100 % mV
        gainMax = 10^3
        gainMin = 10^-3
        gainStepMultiplier = 10
        microwattPerMillivolt = 1 / 10;
    end
    
    properties
        gain
    end
    
    methods
        
        function obj = OptometerUDT350(initialGain)
            obj.gain = initialGain;
        end
        
        
        function increaseGain(obj)
            obj.gain = obj.gain * OptometerUDT350.gainStepMultiplier;
        end
        
        
        function decreaseGain(obj)
            obj.gain = obj.gain / OptometerUDT350.gainStepMultiplier;
        end
        
        
        function set.gain(obj, gain)
            if gain == obj.gain
                return;
            end
            
            gainExponent = single(log(gain) / log(obj.gainStepMultiplier));
            if mod(gainExponent, 1) ~= 0
                error('OptometerUDT350:BadGain', 'Bad gain value.');
            end
            
            if gain > OptometerUDT350.gainMax || gain < OptometerUDT350.gainMin
                error('OptometerUDT350:GainOutOfBounds', 'Requested gain is out of bounds.');  
            end
            
            waitfor(msgbox(['Set optometer gain to ' num2str(OptometerUDT350.gainStepMultiplier) '^' num2str(gainExponent)], 'Optometer'));
            obj.gain = gain;
        end
        
    end
end