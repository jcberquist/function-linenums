# function-linenums

**function-linenums** is a utility module for use with CFML exception `TagContext` arrays. Given a template and a line number it computes CFML function names - as tag context items do not include original CFML function names in them.

## Installation
Install this module via CommandBox:

```
$ install funclinenums
```

Alternatively the git repository can be cloned into the desired directory.

### ColdBox Module

You can leverage the module via the injection DSL: `functionLineNums@funclinenums`:

```cfc
property name="functionLineNums" inject="functionLineNums@funclinenums";
```

### Standalone Usage

Alternatively, the `functionLineNumbers` component can be instantiated directly:

```cfc
functionLineNums = new funclinenums.functionLineNums();
```

## Available methods

The following methods are available:

```cfc
// pass in a TagContext item directly
functionName = functionLineNums.findTagContextFunction( tagContextItem );
```

```cfc
// pass in a full path to a CFML source file and a line number
functionName = functionLineNums.findFunction( fullPath, lineNum );
```

```cfc
// pass in a full path to a CFML source file
functionArray = functionLineNums.getFunctionRanges( fullPath );
/*
returns an array of structs:
[
    {
        "name": "funcName", 
        "start": 1, 
        "end": 104, 
        "startline": 1,
        "endline": 9
    }
]
*/
```

```cfc
// pass in source code directly
functionArray = functionLineNums.walk( srcCode );
/*
returns an array of structs:
[
    {
        "name": "funcName", 
        "start": 1, 
        "end": 104, 
        "startline": 1,
        "endline": 9
    }
]
*/
```
