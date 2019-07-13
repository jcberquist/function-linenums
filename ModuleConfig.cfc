component {

    this.title = 'function-linenums';
    this.author = 'John Berquist';
    this.webURL = 'https://github.com/jcberquist/function-linenums';
    this.description = 'Utility module for computing function names from source paths and line numbers.';

    function configure() {
        
    }

    function onLoad() {
        binder.map( 'functionLineNums@funclinenums' )
            .to( '#moduleMapping#.functionLineNums' )
            .asSingleton();
    }

}
