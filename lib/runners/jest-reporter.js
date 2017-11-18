
class Reporter {

    constructor(globalConfig, options) {
        this._globalConfig = globalConfig;
        this._options = options;
    }

    onRunStart() {
        console.log('[jest] START RUN');
    }
    
    onTestStart(contexts) {
        console.log('[jest] START SUITE:', contexts.path);
    }
    
    onTestResult(contexts, results) {
        console.log('[jest] RESULT:', JSON.stringify(results, null, 4));
    }
  
    onRunComplete(contexts, results) {
        console.log('[jest] RUN COMPLETE:', JSON.stringify(results, null, 4));
    }

    getLastError() {
        if (this._shouldFail) {
            return new Error('There was an error!');
        }
    }
  }
  
  module.exports = Reporter;
