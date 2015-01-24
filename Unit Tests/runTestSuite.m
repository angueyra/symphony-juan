function result = runTestSuite()
    import matlab.unittest.TestSuite;
    
    filePath = mfilename('fullpath');
    testDir = fileparts(filePath);
    
    suite = TestSuite.fromFolder(testDir);
    result = run(suite);
end