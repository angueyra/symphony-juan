% Generates a sinusoidal stimulus.

classdef SineGenerator < StimulusGenerator
    
    properties (Constant)
        identifier = 'edu.washington.rieke.GaussianNoiseGenerator'
        version = 1
    end
    
    properties
        preTime             % Leading duration (ms)
        stimTime            % Noise duration (ms)
        tailTime            % Trailing duration (ms)
        freq                % Noise frequency cutoff for smoothing (Hz)
        phase               % Phase of the sinusoid in degrees
        wcontrast           % Weber contrast of sine modulation
        mean                % Mean amplitude (units)
        
        
        sampleRate          % Sample rate of generated stimulus (Hz)
        units               % Units of generated stimulus
    end
    
    methods
        
        function obj = SineGenerator(params)
            if nargin == 0
                params = struct();
            end
            
            obj = obj@StimulusGenerator(params);
        end
        
    end
    
    methods (Access = protected)
        
        function stim = generateStimulus(obj)
            import Symphony.Core.*;
            
            timeToPts = @(t)(round(t / 1e3 * obj.sampleRate));
            
            prePts = timeToPts(obj.preTime);
            stimPts = timeToPts(obj.stimTime);
            tailPts = timeToPts(obj.tailTime);
            
            fPts= obj.freq / obj.sampleRate;
            phaseRad=deg2rad(obj.phase);
            
            wcontrast=obj.wcontrast/100;
            
            sinewave=sin(2*pi*fPts*[1:stimPts]+phaseRad);
            sinewave = (sinewave*wcontrast*obj.mean) + obj.mean;
            
            data = ones(1, prePts + stimPts + tailPts) * obj.mean;
            data(prePts + 1:prePts + stimPts) = sinewave;
            
            
            measurements = Measurement.FromArray(data, obj.units);
            rate = Measurement(obj.sampleRate, 'Hz');
            output = OutputData(measurements, rate);
            stim = RenderedStimulus(obj.identifier, obj.stimulusParameters, output);
        end
        
    end
    
end