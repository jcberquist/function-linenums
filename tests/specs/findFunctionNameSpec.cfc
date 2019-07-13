component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        functionLineNums = new funclinenums.FunctionLineNums();
        dataPath = expandPath( '/tests/data/' );
    }

    function run() {
        describe( 'The findFunction() method', function() {
            it( 'locates function names in script', function() {
                var srcPath = dataPath & 'input/scripttest.cfc'; 
                expect( functionLineNums.findFunction( srcPath, 4 ) ).toBe( 'scriptfunc' );
                expect( functionLineNums.findFunction( srcPath, 14 ) ).toBe( 'nested' );
                expect( functionLineNums.findFunction( srcPath, 19 ) ).toBe( 'assigned' );

                var srcPath = dataPath & 'input/BaseSpec.cfc'; 
                expect( functionLineNums.findFunction( srcPath, 1089 ) ).toBe( 'debug' );
                expect( functionLineNums.findFunction( srcPath, 1303 ) ).toBe( 'sliceTagContext' );
            } );
            it( 'locates function names in tags', function() {
                var srcPath = dataPath & 'input/tagtest.cfc'; 
                expect( functionLineNums.findFunction( srcPath, 6 ) ).toBe( 'tagFunction' );
            } );
            it( 'locates function names in templates', function() {
                var srcPath = dataPath & 'input/template.cfm'; 
                expect( functionLineNums.findFunction( srcPath, 5 ) ).toBe( 'nested' );
                expect( functionLineNums.findFunction( srcPath, 7 ) ).toBe( 'tagfunc' );
            } );
        } );
    }

}
