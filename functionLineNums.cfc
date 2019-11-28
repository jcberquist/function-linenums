component {

    variables.CFSCRIPT = [
        'line_comment',
        'multiline_comment',
        'function_declaration',
        'curly_brackets',
        'parentheses',
        'square_brackets',
        'string_single',
        'string_double',
        'tag_comment'
    ];
    variables.CFTAGS = [
        'tag_comment',
        'cfscript_tag',
        'cffunction_start',
        'cffunction_end',
        'cftag'
    ];
    variables.cfscriptStart = '(?=^\s*(?:/\*|//|import\b|(?:component|abstract\s*component|final\s*component|interface)(?:\s+|\{)))';
    variables.RangeDefinitions = {
        cfml: [
            '(?=.)',
            '\Z',
            [ 'cfscript', 'cftags' ],
            'first'
        ],
        cfscript: [
            cfscriptStart,
            '(?=\Z)',
            CFSCRIPT,
            'first'
        ],
        cftags: [ '(?=\S)', '(?=\Z)', CFTAGS, 'first' ],
        cfscript_tag: [
            '<' & 'cfscript>',
            '</' & 'cfscript>',
            CFSCRIPT,
            'first'
        ],
        cffunction_start: [
            '<' & 'cffunction',
            '>',
            [ 'cffunction_name', 'string_single', 'string_double' ],
            'first'
        ],
        cffunction_name: [
            'name\s*=\s*["''][^"'']+["'']',
            '(?=.)',
            [ ],
            'first'
        ],
        cffunction_end: [
            '</' & 'cffunction',
            '>',
            [ 'string_single', 'string_double' ],
            'first'
        ],
        cftag: [
            '</?' & 'cf\w+',
            '>',
            [ 'string_single', 'string_double' ],
            'first'
        ],
        curly_brackets: [ '\{', '\}', CFSCRIPT, 'first' ],
        escaped_double_quote: [ '""', '(?=.)', [ ], 'first' ],
        escaped_hash: [ '####', '(?=.)', [ ], 'first' ],
        escaped_single_quote: [ '''''', '(?=.)', [ ], 'first' ],
        function_declaration: [
            '\bfunction\s+\w+\b|\b[\w.]+\s*=\s*function\b',
            '(?=\s*\()',
            [ ],
            'first'
        ],
        hash: [ '##', '##', CFSCRIPT, 'first' ],
        line_comment: [ '//', '\n', [ ], 'first' ],
        multiline_comment: [ '/\*', '\*/', [ ], 'first' ],
        parentheses: [ '\(', '\)', CFSCRIPT, 'first' ],
        square_brackets: [ '\[', '\]', CFSCRIPT, 'first' ],
        string_double: [
            '"',
            '"',
            [ 'escaped_hash', 'hash', 'escaped_double_quote' ],
            'last'
        ],
        string_single: [
            '''',
            '''',
            [ 'escaped_hash', 'hash', 'escaped_single_quote' ],
            'last'
        ],
        tag_comment: [ '<!---', '--->', [ ], 'first' ]
    };

    function init() {
        variables.cache = { };
        variables.regex = initRegex();
        return this;
    }

    /**
     * Convenience method that takes a tag context item from an exception
     * and returns the name of the currently executing function at that item
     * @tagContextItem struct from CFML exception tag context array - expected to have `template` and `line` keys
     */
    function findTagContextFunction( required struct tagContextItem ) {
        return findFunction( tagContextItem.template, tagContextItem.line );
    }

    /**
     * Given a source file path and a line number, returns the name of the function that line number is in, if any
     * @filePath full file path to a CFML source file
     * @lineNum line number in that file to check and see what function it is contained in
     */
    function findFunction( required string filePath, required numeric lineNum ) {
        var funcName = '';
        for ( var func in getFunctionRanges( filePath ) ) {
            if ( func.startLine > lineNum ) {
                break;
            }
            if ( func.endLine >= lineNum ) {
                funcName = func.name;
            }
        }
        return funcName;
    }

    /**
     * Given a source file path returns an array of structs containing info about all functions
     * and their locations in that file
     * @filePath full file path to a CFML source file
     */
    function getFunctionRanges( required string filePath ) {
        if ( !variables.cache.keyExists( filePath ) ) {
            try {
                variables.cache[ filePath ] = walk( fileRead( filePath ) );
            } catch ( any e ) {
                // if unable to parse, avoid dying and just log this to the console
                // cache an empty array to ensure we don't repeat the exception
                var message = 'functionLineNums unable to parse #filePath#: #e.message#';
                createObject( 'java', 'java.lang.System' ).out.println( message );
                variables.cache[ filePath ] = [ ];
            }
        }
        return variables.cache[ filePath ];
    }

    /**
     * Given cfml source code return an array of structs containing info about all functions
     * and their locations in that code
     * @src CFML source code
     */
    function walk( required string src ) {
        // start by normalizing the line endings
        // if a file has CR characters with no LF characters
        // convert those to LF characters - this will not
        // change the size of the file
        src = src.reReplace( '\r(?=[^\n]|$)', chr( 10 ), 'all' );

        var funcs = [ ];
        var name = 'cfml';
        var pos = 0;
        var rangeToWalk = srcRange( name, pos );
        var currentRange = rangeToWalk;

        while ( !isNull( currentRange ) ) {
            var matcher = regex.range[ currentRange.name ].end.matcher( src );

            if ( !matcher.find( pos ) ) {
                currentRange.end = len( src );
                while ( !isNull( currentRange.parent ) ) {
                    currentRange.parent.end = len( src );
                    currentRange = currentRange.parent;
                }
                break;
            }

            var name = groupName( regex.range[ currentRange.name ].names, matcher );
            pos = matcher.end();

            if ( name == 'pop' ) {
                currentRange.end = pos;
                currentRange = !isNull( currentRange.parent ) ? currentRange.parent : javacast( 'null', '' );
            } else {
                var childRange = srcRange( name, matcher.start() );
                childRange.parent = currentRange;
                currentRange.children.append( childRange );
                currentRange = childRange;

                if ( name == 'function_declaration' || name == 'cffunction_start' ) {
                    funcs.append( currentRange );
                }
            }
        }

        return funcs.map( function( f ) {
            return funcParse( src, f );
        } );
    }

    private function srcRange( name, start ) {
        return {
            id: createUUID(),
            name: name,
            start: start,
            end: -1,
            children: [ ],
            parent: javacast( 'null', '' )
        };
    }

    private function groupName( names, matcher ) {
        for ( var i = 1; i <= names.len(); i++ ) {
            if ( !isNull( matcher.group( javacast( 'int', i ) ) ) ) {
                return names[ i ];
            }
        }
    }

    private function funcParse( src, func ) {
        var parsed = {
            name: '',
            start: func.start,
            end: func.end,
            startLine: lineNum( src, func.start ),
            endLine: 0
        };
        var end_name = '';

        switch ( func.name ) {
            case 'function_declaration':
                end_name = 'curly_brackets';
                var matcher = regex.funcname.script.matcher(
                    mid( src, func.start + 1, func.end - func.start )
                );
                if ( matcher.lookingAt() ) {
                    for ( var i = 1; i <= 2; i++ ) {
                        var func_name = matcher.group( javacast( 'int', i ) );
                        if ( !isNull( func_name ) ) {
                            parsed.name = func_name;
                            break;
                        }
                    }
                }
                break;
            case 'cffunction_start':
                end_name = 'cffunction_end';
                for ( var child in func.children ) {
                    if ( child.name == 'cffunction_name' ) {
                        var matcher = regex.funcname.tag.matcher(
                            mid( src, child.start + 1, child.end - child.start )
                        );
                        if ( matcher.lookingAt() ) {
                            parsed.name = matcher.group( javacast( 'int', 1 ) );
                        }
                    }
                }
                break;
        }

        // determine end line
        var funcSeen = false;
        for ( var i = 1; i <= arrayLen( func.parent.children ); i++ ) {
            if ( funcSeen ) {
                parsed.end = func.parent.children[ i ].end;
                if ( func.parent.children[ i ].name == end_name ) break;
            } else if ( func.id == func.parent.children[ i ].id ) {
                funcSeen = true;
            }
        }
        parsed.endLine = lineNum( src, parsed.end );

        // before returning - CFML pos index starts at 1
        parsed.start += 1;
        parsed.end += 1;

        return parsed;
    }

    private function lineNum( src, pos ) {
        return pos ? left( src, pos ).listLen( chr( 10 ), true ) : 1;
    }

    private function initRegex() {
        // NOTE `34` is the bitOr of the flags DOTALL and CASE_INSENSITIVE
        var patternClass = createObject( 'java', 'java.util.regex.Pattern' );
        var regexMap = {
            range: { },
            funcname: {
                script: patternClass.compile( 'function\s+(\w+)|([\w.]+)\s*=\s*function', 34 ),
                tag: patternClass.compile( 'name\s*=\s*["'']([^"'']+)["'']', 34 )
            }
        };

        var expandedRD = variables.RangeDefinitions.map( function( k, v ) {
            return {
                start: v[ 1 ],
                end: v[ 2 ],
                child_ranges: v[ 3 ],
                pop: v[ 4 ]
            };
        } );

        for ( var name in expandedRD ) {
            rd = expandedRD[ name ];
            regexMap.range[ name ] = { start: patternClass.compile( rd.start, 34 ) };

            var patterns = [ ];
            var names = [ ];

            for ( var cr in rd.child_ranges ) {
                var crd = expandedRD[ cr ];
                names.append( cr );
                patterns.append( '(#crd.start#)' );
            }

            if ( rd.pop == 'first' ) {
                names.prepend( 'pop' );
                patterns.prepend( '(#rd.end#)' );
            } else {
                names.append( 'pop' );
                patterns.append( '(#rd.end#)' );
            }

            regexMap.range[ name ].end = patternClass.compile( patterns.toList( '|' ), 34 );
            regexMap.range[ name ].names = names;
        }

        return regexMap;
    }

}
