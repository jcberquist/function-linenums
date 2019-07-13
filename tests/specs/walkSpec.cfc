component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        functionLineNums = new funclinenums.FunctionLineNums();
        dataPath = expandPath( '/tests/data/' );
    }

    function run() {
        describe( 'The walk() method', function() {
            it( 'parses tag components', function() {
                var input = loadInput( 'tagtest.cfc' );
                var output = loadOutput( 'tagtest.json' );
                var funcArray = functionLineNums.walk( input );
                expect( funcArray ).toBe( output );
            } );
            it( 'parses script components', function() {
                var input = loadInput( 'scripttest.cfc' );
                var output = loadOutput( 'scripttest.json' );
                var funcArray = functionLineNums.walk( input );
                expect( funcArray ).toBe( output );
            } );
            it( 'parses cfm templates', function() {
                var input = loadInput( 'template.cfm' );
                var output = loadOutput( 'template.json' );
                var funcArray = functionLineNums.walk( input );
                expect( funcArray ).toBe( output );
            } );
        } );
    }

    function loadInput( path ) {
        return fileRead( dataPath & 'input/' & path ).replace( chr( 13 ), '', 'all' );
    }

    function loadOutput( path ) {
        return deserializeJSON( fileRead( dataPath & 'output/' & path ) );
    }


}
