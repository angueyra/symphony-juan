% Generates a single rectangular pulse stimulus.
% See details on the <a href="matlab:web('https://github.com/Symphony-DAS/Symphony/wiki/Standard-Stimulus-Generators#pulsegenerator')">Symphony wiki</a>.

classdef DoublePulseGenerator < StimulusGenerator
    
    properties (Constant)
        identifier = 'angueyra.DoublePulseGenerator'
        version = 1
    end
    
    properties
        preTime     % Leading duration (ms)
        stimTimeL   % First pulse duration (ms)
        stimTimeR   % Second pulse duration (ms)
        tailTime    % Trailing duration (ms)
        amplitudeL  % First pulse amplitude (units)
        amplitudeR  % Second pulse amplitude (units)
        mean        % Mean amplitude (units)
        sampleRate  % Sample rate of generated stimulus (Hz)
        units       % Units of generated stimulus
    end
    
    methods
        
        function obj = DoublePulseGenerator(params)
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
            stimPtsL = timeToPts(obj.stimTimeL);
            stimPtsR = timeToPts(obj.stimTimeR);
            tailPts = timeToPts(obj.tailTime);
            
            data = ones(1, prePts + stimPtsL + stimPtsR + tailPts) * obj.mean;
            data(prePts + 1:prePts + stimPtsL) = obj.amplitudeL + obj.mean;
            data(prePts + stimPtsL + 1:prePts + stimPtsL + stimPtsR) = obj.amplitudeR + obj.mean;
            
            measurements = Measurement.FromArray(data, obj.units);
            rate = Measurement(obj.sampleRate, 'Hz');
            output = OutputData(measurements, rate);
            
            stim = RenderedStimulus(obj.identifier, obj.stimulusParameters, output);
        end
        
    end
    
end