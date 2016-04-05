classdef StimulusGeneratorTests < matlab.unittest.TestCase
    
    methods (TestClassSetup)
        
        function classSetup(testCase)
            import matlab.unittest.fixtures.PathFixture;
            
            testPath = mfilename('fullpath');
            packageDir = fullfile(fileparts(testPath), '..');
            generatorsDir = fullfile(packageDir, 'Stimulus Generators');
            
            isWin64bit = strcmpi(getenv('PROCESSOR_ARCHITEW6432'), 'amd64') || strcmpi(getenv('PROCESSOR_ARCHITECTURE'), 'amd64');
            if isWin64bit
                symphonyDir = fullfile(getenv('PROGRAMFILES(x86)'), 'Symphony');
            else
                symphonyDir = fullfile(getenv('PROGRAMFILES'), 'Symphony');
            end
            
            utilitiesDir = fullfile(symphonyDir, 'Utilities');
            
            testCase.applyFixture(PathFixture(packageDir));
            testCase.applyFixture(PathFixture(generatorsDir));
            testCase.applyFixture(PathFixture(symphonyDir));
            testCase.applyFixture(PathFixture(utilitiesDir));
            
            addSymphonyAssembly('Symphony.Core');
        end
        
    end
    
    methods (Test)

        %% BinaryNoiseGenerator
        
        function binaryNoiseId(testCase)
            testCase.verifyId(BinaryNoiseGenerator());
        end
        
        
        function generatesBinaryNoise(testCase)
            import matlab.unittest.constraints.*;
            
            p = makeBinaryNoiseParams();
            gen = BinaryNoiseGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusAttributes(gen, stim);
            testCase.verifyEqual(System.Decimal.ToDouble(stim.SampleRate.QuantityInBaseUnit), gen.sampleRate);
            testCase.verifyEqual(char(stim.SampleRate.BaseUnit), 'Hz');
            testCase.verifyEqual(char(stim.Units), gen.units);
            
            [prePts, stimPts, tailPts] = getPts(p);
            segmentPts = toPts(p.segmentTime, p.sampleRate);
            stimData = getStimData(stim);
            
            testCase.verifyEqual(length(stimData), prePts+stimPts+tailPts);
            testCase.verifyEveryElementEqualTo(stimData(1:prePts), p.mean);
            
            numSegments = stimPts / segmentPts;
            for i = 1:numSegments
                segmentStartPt = prePts + 1 + (i - 1) * segmentPts;
                segment = stimData(segmentStartPt:segmentStartPt+segmentPts-1);
                
                testCase.verifyThat(segment(1), IsEqualTo(p.mean + p.amplitude) | IsEqualTo(p.mean - p.amplitude));
                testCase.verifyEqual(segment, ones(1, length(segment)) * segment(1));
            end
            
            testCase.verifyEveryElementEqualTo(stimData(prePts+stimPts+1:end), p.mean);
        end
        
        
        function generatesDifferentBinaryNoiseWithDifferentSeed(testCase)
            p1 = makeBinaryNoiseParams();
            p1.seed = 2;   
            gen1 = BinaryNoiseGenerator(p1);
            stim1 = gen1.generate();
            
            p2 = makeBinaryNoiseParams();
            p2.seed = 3;
            gen2 = BinaryNoiseGenerator(p2);
            stim2 = gen2.generate();
            
            stim1Data = getStimData(stim1);
            stim2Data = getStimData(stim2);
            
            testCase.verifyNotEqual(stim1Data, stim2Data);
        end
        
        
        function regeneratesBinaryNoise(testCase)
            p = makeBinaryNoiseParams();
            gen = BinaryNoiseGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusRegenerates(stim);
        end
        
        
        %% GaussianNoiseGenerator
        
        function gaussianNoiseId(testCase)
            testCase.verifyId(GaussianNoiseGenerator());
        end
        
        
        function generatesGaussianNoise(testCase)
            p = makeGaussianNoiseParams();
            gen = GaussianNoiseGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusAttributes(gen, stim);
            testCase.verifyEqual(System.Decimal.ToDouble(stim.SampleRate.QuantityInBaseUnit), gen.sampleRate);
            testCase.verifyEqual(char(stim.SampleRate.BaseUnit), 'Hz');
            testCase.verifyEqual(char(stim.Units), gen.units);
            
            [prePts, stimPts, tailPts] = getPts(p);
            stimData = getStimData(stim);
            
            testCase.verifyEqual(length(stimData), prePts+stimPts+tailPts);
            testCase.verifyEveryElementEqualTo(stimData(1:prePts), p.mean);
            testCase.verifyEqual(chi2gof(stimData(prePts+1:prePts+stimPts)), 0);
            testCase.verifyEqual(std(stimData(prePts+1:prePts+stimPts)), p.stDev, 'RelTol', 0.01);
            testCase.verifyEveryElementEqualTo(stimData(prePts+stimPts+1:end), p.mean);
        end
        
        
        function generatesDifferentGaussianNoiseWithDifferentSeed(testCase)
            p1 = makeGaussianNoiseParams();
            p1.seed = 2;   
            gen1 = GaussianNoiseGenerator(p1);
            stim1 = gen1.generate();
            
            p2 = makeGaussianNoiseParams();
            p2.seed = 3;
            gen2 = GaussianNoiseGenerator(p2);
            stim2 = gen2.generate();
            
            stim1Data = getStimData(stim1);
            stim2Data = getStimData(stim2);
            
            testCase.verifyNotEqual(stim1Data, stim2Data);
        end
        
        
        function generatesInvertedGaussianNoise(testCase)
            p1 = makeGaussianNoiseParams();
            p1.inverted = false;
            gen1 = GaussianNoiseGenerator(p1);
            stim1 = gen1.generate();
            
            p2 = makeGaussianNoiseParams();
            p2.inverted = true;
            gen2 = GaussianNoiseGenerator(p2);
            stim2 = gen2.generate();
            
            [prePts, stimPts, tailPts] = getPts(p1);
            stim1Data = getStimData(stim1);
            stim2Data = getStimData(stim2);
            
            testCase.verifyEqual(stim1Data(1:prePts), stim2Data(1:prePts));
            testCase.verifyEqual(stim1Data(prePts+1:prePts+stimPts) - p1.mean, -(stim2Data(prePts+1:prePts+stimPts) - p1.mean), 'AbsTol', 1e-12);
            testCase.verifyEqual(stim1Data(prePts+stimPts+1:end), stim2Data(prePts+stimPts+1:end));
        end
        
        
        function regeneratesGaussianNoise(testCase)
            p = makeGaussianNoiseParams();
            gen = GaussianNoiseGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusRegenerates(stim);
        end
        
    end
    
    methods
        
        function verifyEveryElementEqualTo(testCase, array, value)
            import matlab.unittest.constraints.*;
            testCase.verifyThat(EveryElementOf(array), IsEqualTo(value, 'Within', AbsoluteTolerance(1e-12)));
        end
        
        
        function verifyId(testCase, gen)
            split = regexp(gen.identifier, '\.', 'split');
            testCase.verifyEqual(split{end}, class(gen));
        end
        
        
        function verifyStimulusAttributes(testCase, gen, stim)
            testCase.verifyEqual(char(stim.StimulusID), gen.identifier);
            testCase.verifyEqual(stim.Parameters.Item('version'), gen.version);
        end
        
        
        function verifyStimulusRegenerates(testCase, stim, dur)
            if nargin < 3
                dur = stim.Duration.Item2;
            end
            
            stimParams = dictionaryToStruct(stim.Parameters);
            stimData = getStimData(stim, dur);
            
            split = regexp(char(stim.StimulusID), '\.', 'split');
            construct = str2func(split{end});
            
            gen = construct(stimParams);
            regen = gen.generate();
            regenParams = dictionaryToStruct(regen.Parameters);
            regenData = getStimData(regen, dur);
            
            testCase.verifyEqual(regenParams, stimParams);
            testCase.verifyEqual(regenData, stimData);
            testCase.verifyTrue(regen.SampleRate.Equals(stim.SampleRate));
            testCase.verifyTrue(regen.Duration.Equals(stim.Duration));
            testCase.verifyTrue(strcmp(char(regen.Units), char(stim.Units)));
        end
        
    end
    
end


function p = makeBinaryNoiseParams()
    p.preTime = 20;
    p.stimTime = 520.3;
    p.tailTime = 22.7;
    p.segmentTime = 11;
    p.amplitude = 20;
    p.mean = -40;
    p.seed = 1;
    p.sampleRate = 150;
    p.units = 'units';
end


function p = makeGaussianNoiseParams()
    p.preTime = 20;
    p.stimTime = 520.3;
    p.tailTime = 22.7;
    p.stDev = 2;
    p.mean = 1;
    p.freqCutoff = 60;
    p.numFilters = 0;
    p.seed = 1;
    p.sampleRate = 10000;
    p.units = 'units';
end


function d = getStimData(stim, dur)
    if nargin == 1
        dur = stim.Duration.Item2;
    end

    block = NET.invokeGenericMethod('System.Linq.Enumerable', 'First', {'Symphony.Core.IOutputData'}, stim.DataBlocks(dur));
    d = double(Symphony.Core.Measurement.ToBaseUnitQuantityArray(block.Data));
end


function [pre, stim, tail] = getPts(params)
    pre = toPts(params.preTime, params.sampleRate);
    stim = toPts(params.stimTime, params.sampleRate);
    tail = toPts(params.tailTime, params.sampleRate);
end


function p = toPts(t, rate)
    p = round(t * 1e-3 * rate);
end