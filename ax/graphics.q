pcre2:use`kx.fusion:pcre2;

system "d .z.m.axpnull";
// @fileOverview Functions can have multiple projections layered on them.
// This re-apply a cached list of projections to a function
// @param function {function} A function to apply projections to
// @param list {()} A list of lists, where each sublist is a set of projections
// @returns {function} The input function with the lambdas applied
.z.m.axpnull.applyProjectionList:{[function; list]
    
    : function ./ list;
    }
// @fileOverview Returns how many arguments a function or projection takes,
// taking into account how many have already been projected in
// @param x {Function} A function or projection
// @returns {Long} The number of parameters the function is waiting on
.z.m.axpnull.arity:{ 
    $[100h ~ type x;   count value[x]1;
        101h ~ type x; 1;
        102h ~ type x; 2;
        103h ~ type x; 3;
        104h ~ type x; count[first 1_ value unprojectedFunction x] - count[v] - countMagicNulls v:raze projectionList x;
                        0N]
    }

// @param x {()} A list which could contain magic nulls
// @returns {Long} The number of magic nulls in the list
.z.m.axpnull.countMagicNulls:{[x]
    : sum (104h ~ type@) each (~)./: flip (x; x);
    }
// @fileOverview Gets all params of a given function.
// @param func {function} The function those parameters to get.
// @returns {symbol[]} Returns a list of parameter names. 
.z.m.axpnull.funcParams:{[func]
    
    getNeedProjParams: { (@[;1] value (100<>type@)(first value@)/x) where .z.m.axpnull.is each 1_value x };
    funcType: type func;
    
    if [not funcType in 100 104h;
        '"Function was not a custom function or projection"];
    
    result: $[funcType = 100h; value[func] 1;
              funcType = 104h; getNeedProjParams func;
              0#`];
    
    : $[` ~ first result;
        0#`;
        result];
    }
// @fileOverview Turns magic null to generic null.
//  Due to a kx bug, generic null can only sometimes be passed to a function
//  {[x;y] show x; show y}[1; (::)]    // returns 1
//  {[x;y] show x; show y}[1; $[0;1;]] // returns a projection
//  This is used to turn the bogus (::) from something like $[0;1;] into a real (::)
// @param x {*} Some value which could be generic null
// @returns {*}
.z.m.axpnull.handleGenericNull:{[x]
    : $[x ~ (::);
        (::);
        x];
    }
// @fileOverview Functions can have multiple sets of projections applied. This returns those lists.
// @param function {function} A function which may or may not have projected parameters
// @returns {()} A list of lists, where each sublist is one set of parameters
.z.m.axpnull.projectionList:{[function]
    
    : $[104h ~ type function;
        [   // If the function is a projection, recursivley stip the projected parameters
            functionDetails : value function;
            .z.s[first functionDetails] , enlist 1 _ functionDetails];
        
        ()];
    }
// @fileOverview Returns the function with all the projected arguments stripped away
// @param function {function}
// @returns {function}
.z.m.axpnull.unprojectedFunction:{[function]
    
    : $[104h ~ type function;
        
        .z.s first value function;
        
        function];
    }
.z.m.axpnull.is:104h ~ type {1b}@
/{[x] `projection ~ typeSymbol first (~) ./: flip (enlist x; enlist x)};
system "d .z.m";

system "d .z.m.axq";
// @fileOverview
// Casts data from any type into a GUID. This function does
// not follow the convention of the other as functions when
// given a string. If given a string input then asGUID will
// attempt to parse it into a GUID
//
// @example Bytes to GUID 
// .z.m.axq.asGUID 0x5a580fb6656b5e69d445417ebfe71994
// /=> 5a580fb6-656b-5e69-d445-417ebfe71994
//
// @example Number to GUID
// .z.m.axq.asGUID 1504055322709753856f
// /=> 00000000-0000-0000-14df-7a58e0a68000
//
// @example Parse String to GUID
// .z.m.axq.asGUID "580d8c87-e557-0db1-3a19-cb3a44d623b1"
// /=> 580d8c87-e557-0db1-3a19-cb3a44d623b1
//
// @param data {*} Any data type to convert to a GUID
//
// @returns {*} Input converted to GUIDs with a preserved shape
.z.m.axq.asGUID:{[data]
    : $[2h ~ i.truetype data; ::; i.cast["g"; "h"$()] i.asGUID ] data
    }
// @fileOverview
// Converts the given input to a list. Refer to the following chart for
// behavior definitions based on input type
//
// |   Input Type   |                Behavior              |
// | -------------- | ------------------------------------- |
// | atom           | enlist                                |
// | vector         | identity                              |
// | table          | ((column name; column content); ...)  |
// | keyed table    | ((column name; column content); ...)  |
// | dictionary     | ((key; value); ...)                   |
//
// @example Atom to List
// .z.m.axq.asList "a"
// /=> ,"a"
//
// @example Table to List
// .z.m.axq.asList ([] x: til 5; y: "abcde")
// /=> `x 0 1 2 3 4
// /=> `y "abcde"  
//
// @example Dictionary to List
// .z.m.axq.asList `a`b!(1 2 3; "abc")
// /=> `a 1 2 3
// /=> `b "abc"
//
// @param data {*} Any input to convert to a list
//
// @returns {any[]} A list from the given input
.z.m.axq.asList:{[data]
    : $[data ~ (::);
            ();
        isTable data;
            flip (cols data; (0!data) cols data);
        isDictionary data;
            flip (key data; value data); 
        isList data;
            data;
            enlist data
            ]
    }
// @fileOverview
// Converts the given input to a minute data type
//
// @example Number to Minute
// .z.m.axq.asMinute 10
// /=> 00:10
// 
// @example Date to Minute
// .z.m.axq.asMinute 2010.05.22
// /=> 00:00
//
// @example Time to Minute
// .z.m.axq.asMinute 12:34:56.789
// /=> 12:34
//
// @param data {*} Any data to convert to a minute data type
//
// @returns {minute} Data with same shape of minute type
.z.m.axq.asMinute:{[data]
    ty: i.truetype data;
    
    : $[ty in i.NUMBER_TYPES; 
            "u"$data; 
        ty ~ 10h;
            "u"$data;
            "u"$asTimestamp data
            ]
    }
// @fileOverview
// Converts the given input to a month data type
//
// @example Number to Month
// .z.m.axq.asMonth 10
// /=> 2000.11m
// 
// @example Date to Month
// .z.m.axq.asMonth 2010.05.22
// /=> 2010.05m
//
// @example Time to Minute
// .z.m.axq.asMonth 12:34:56.789
// /=> 2000.01m
//
// @param data {*} Any data to convert to a month data type
//
// @returns {month} Data with same shape of month type
.z.m.axq.asMonth:{[data]
    ty: i.truetype data;
    
    : $[ty in i.NUMBER_TYPES; 
            "m"$data; 
        ty ~ 10h;
            "m"$data;
            "m"$asDate data
            ]
    }

// @fileOverview
// Converts the given input to a second data type
//
// @example Number to Second
// .z.m.axq.asSecond 10
// /=> 00:00:10
// 
// @example Date to Second
// .z.m.axq.asSecond 2010.05.22
// /=> 00:00:00
//
// @example Time to Second
// .z.m.axq.asSecond 12:34:56.789
// /=> 12:34:56
//
// @param data {*} Any data to convert to a second data type
//
// @returns {second} Data with same shape of second type
.z.m.axq.asSecond:{[data]
    ty: i.truetype data;
    
    : $[ty in i.NUMBER_TYPES; 
            "v"$data; 
        ty ~ 10h;
            "v"$data;
            "v"$asTimestamp data
            ]
    }
// @fileOverview
// Converts the given input to a string. This is similar to the behavior
// of the `string` keyword. .z.m.axq.asString differs from `string` when the input
// is a string type. In this case, the input is simply returned.
//
// @example Number to String
// .z.m.axq.asString 10
// /=> "10"
//
// @example Vector to String
// .z.m.axq.asString `AAPL`GOOG`MSFT`AMZN
// /=> "AAPL"
// /=> "GOOG"
// /=> "MSFT"
// /=> "AMZN"
//
// @param data {*} Data to cast to a string
//
// @returns {string} String representation of data with same shape
.z.m.axq.asString:{[data]
    : $[0 ~ count data;
            $[isVector data; ""; string data];
        isGeneral data;
            .z.s each data;
        isTable data;
            .z.s each data;
        isDict data;
            .z.s each data;
        -10h ~ type data;
            string data;
        10h ~ i.truetype data;
            data;
            string data
        ]
    }


// @fileOverview
// Converts the given input to a symbol
//
// @example Number to Symbol
// .z.m.axq.asSymbol 12
// /=> `12
// 
// @example String to Symbol
// .z.m.axq.asSymbol ("AAPL"; "GOOG"; "MSFT"; "AMZN")
// /=> `AAPL`GOOG`MSFT`AMZN
//
// @param data {*} Data to cast to a symbol
//
// @returns {symbol} Symbolic data with same shape
.z.m.axq.asSymbol:{[data]
    ty: i.truetype data; 
    
    : $[11h ~ ty; 
            data;
        (data ~ "") | data ~ (::);
            `;
        ty >= 98h;
            "S"$asString data;
        isEmpty data; 
            `$(); 
        0h ~ ty; 
            .z.s each data;
            "S"$asString data
            ]
    }

// @fileOverview
// Converts the given input to a time data type
//
// @example Number to Time
// .z.m.axq.asTime 10
// /=> 00:00:00.010
// 
// @example Date to Time
// .z.m.axq.asTime 2010.05.22
// /=> 00:00:00.000
//
// @example Time to Time
// asTime 12:34:56.789
// /=> 12:34:56.789
//
// @param data {*} Any data to convert to a time data type
//
// @returns {time} Data with same shape of time type
.z.m.axq.asTime:{[data]
    ty: i.truetype data;
    
    : $[ty in i.NUMBER_TYPES; 
            "t"$data; 
        ty ~ 10h;
            "t"$data;
            "t"$asTimestamp data
            ]
    }
// @fileOverview
// Converts the given input to a timespan data type
//
// @example Number to Timespan
// .z.m.axq.asTimespan 10
// /=> 0D00:00:00.000000010
// 
// @example Date to Timespan
// .z.m.axq.asTimespan 2010.05.22
// /=> 3794D00:00:00.000000000
//
// @example Time to Timespan
// .z.m.axq.asTimespan 12:34:56.789
// /=> 0D12:34:56.789000000
//
// @param data {*} Any data to convert to a timespan data type
//
// @returns {timespan} Data with same shape of timespan type
.z.m.axq.asTimespan:{[data]
    ty: i.truetype data;
    
    : $[ty in i.NUMBER_TYPES; 
            "n"$data; 
        ty ~ 10h;
            "n"$data;
            asTimestamp[data] - 2000.01.01D00:00:00.000
            ]
    }
// @fileOverview
// Dynamically dispatches to the desired as* function and applies
// the cast function to the input data
//
// @example Number to Time
// .z.m.axq.asType[100; `time]
// /=> 00:00:00.100
//
// @example Symbols to Strings
// .z.m.axq.asType[`AAPL`GOOG`MSFT`AMZN; `string]
// /=> "AAPL"
// /=> "GOOG"
// /=> "MSFT"
// /=> "AMZN"
//
// @param data  {*}         Data to cast
// @param ty    {symbol}    Type to cast to
//
// @returns {*} Data with same shape of desired type
.z.m.axq.asType:{[data; ty] 
    : get[i.lookup["as"; asString ty]] data  / dnl
    }

// @fileOverview
// Catch provides protected evaluation. The form is simple:
//
//    .z.m.axq.catch [fn; args; expression]
//
// where fn is a function, args is the single argument or an argument list for the function
// and expression should be a lambda (i.e., { ... }) to be evaluated should function fn fail.
// If the expression has an error the catch itself will fail.
// 
// @example Catch an Error in a Lambda
// myFn: {$[x < 0; '"type"; x]};
// .z.m.axq.catch[myFn; -1; {x}]
// /=> "type"
//
//
// @param fn    {function}  Function to run protected
// @param args  {*}         Arguments to pass to function
// @param expr  {function}  Expression to be executed upon failure
//
// @returns {*} Return from function upon success or expr upon failure
.z.m.axq.catch:{[fn; args; expr]
    ty : type fn;

    monadic:   $[ty in -6 -7h       ; 1b;                       // Integer socket or file handle
                 100h = ty          ; 2 > count value[fn] 1;    // Regular function
                 101h = ty          ; 1b;                       // Unary primitive
                 102h = ty          ; 0b;                       // Binary primitive
                 103h = ty          ; 0b;                       // Ternary operator
                 10h  = type args   ; 1b;                       // For a string we have only one parameter
                 (104h = type fn) and (100h = type .z.m.axpnull.unprojectedFunction fn); 1 = .z.m.axpnull.arity fn; 
                 isList args        ; 0b;
                    1b];
    
    : $[monadic;  @[fn; args; expr]; .[fn; args; expr]];
    
    
    }

// @fileOverview 
// Checks if a qualified variable name is defined. This only works on
// qualified variable names because local vars/params are always defined
// 
// @param name {symbol} A qualified variable name
// @returns {boolean} 1b if the variable is defined
.z.m.axq.defined:{[name]
    : (in) . (last;{$[1<count x; key ` sv -1_x;`]})@\:` vs asSymbol name
    }
// @private
//
// @fileOverview
// Performs cast of castable data to date type
//
// @param data {*} Castable data type
//
// @returns {date|date[]|*[]} Date data with same shape
.z.m.axq.i.asDate:{[data]
    ty: i.truetype data;
    
    : $[ty in 17 18 19h; 
            i.remap[2000.01.01; data];
        ty ~ 16h;
            "d"$"p"$"j"$data;
            "d"$data
            ]; 
    } 

// @private
//
// @fileOverview
// Performs cast of castable datetime to date type
//
// @param data {*} Castable data type
//
// @returns {datetime|datetime[]|*[]} Datetime data with same shape
.z.m.axq.i.asDatetime:{[data]
    ty : i.truetype data;
    
    : $[ty ~ 16h;
            "z"$"p"$"j"$data;
        ty ~ 13h;
            "z"$"p"$data;
        ty in 17 18 19h;
            "z"$"p"$1000000*"j"$"t"$data;
            "z"$data
            ];
    }
// @private
//
// @fileOverview
// Performs the underlying cast operation of isGUID
//
// @param data {*} Data to convert to a GUID
//
// @returns {GUID|GUID[]|*[]} Data of same shape converted to GUIDs
.z.m.axq.i.asGUID:{[data]
    ty: i.truetype data;

    : $[isNull data;
            0ng;
        ty ~ 2h;
            data;
        ty ~ 4h;
            $[isCompound data; .z.s each data; 0x0 sv i.lpad[16; 0x0; data]];
        ty ~ 10h;
            "G"$data;
        isList data;
            $[0=count data; `guid$(); .z.s each data];
            0x0 sv i.lpad[16; 0x0] 0x0 vs asLong data
            ]
    }
// @private
//
// @fileOverview
// Performs cast of castable data to timestamp type
//
// @param data {*} Castable data type
//
// @returns {timestamp|timestamp[]|*[]} Timestamp data with same shape
.z.m.axq.i.asTimestamp:{[data]
    ty : i.truetype data;
    
    : $[ty ~ 16h;
            "p"$"j"$data;
        ty in 17 18 19h;
            "p"$1000000*"j"$"t"$data;        
            "p"$data
            ];
    }
// @private
//
// @fileOverview
// Performs a cast on data types from any input type to a desired 
// output type by running a recast function on it. The behaviour
// of cast changes based on the suffix of the desired type as well
// as the type of the data. The following casting rules are applied
// when determining behaviour
//
// 
// |  Input Data Type  |     Behaviour     |
// | ----------------- | ----------------- |
// | atom              | recast data       |
// | vector            | recast data       |
// | general list      | recast each data  |
// | table             | recast each data  |
// | dictionary        | recast each data  |
// | general null      | null of type      |
// 
// 
// |   Special Cases   |     Behaviour     |
// | ----------------- | ----------------- |
// | guid              | recast or null    |
// | symbol            | recast or null    |
//
// @param suffix {char}     Type suffix of desired output type (used for null)
// @param ignore {short|short[]} Data types to handle differently
// @param recast {function} Casting function to transform atoms and vectors
// @param data   {*}        Data to cast
//
// @returns {*} Data with same shape re-mapped to desired type
//
// @throws 'type - If input is of unknown type
.z.m.axq.i.cast:{[suffix; ignore; recast; data]
    
    ty: i.truetype data;
    
    : $[ty in i.CAST_TYPES except ignore;
            recast data;
        
        ty in ignore; 
            i.remap[i.null suffix; data];
        
        ty in 0 98 99h;
        
            $[0 ~ count data; 
                recast data;
            ty ~ 98h;
                flip .z.s[suffix; ignore; recast] each flip data;
                .z.s[suffix; ignore; recast] each data
                ];
        
        data ~ (::);
            i.null suffix;
        
            '"type: unsupported cast operation from ",string[typeOf data], " to given type"
        ];
    }

// @qlintsuppress UNUSED_INTERNAL
// @private
//
// @fileOverview
// Fetches a type function that uses the given prefix from the .axq namespace
//
// @param prefix    {string}    Prefix of named type function
// @param datamap   {dict}      A data mapping record
//
// @returns {function} Fetched function relating to prefix and mapped data
.z.m.axq.i.get:{[prefix; datamap]
    : get i.name[prefix; string datamap`name]
    }

// @private
//
// @fileOverview
// Performs a lookup to find a typed function using the following set of 
// special naming rules
//
// |        Name        |         Behaviour         |
// | ------------------ | ------------------------- |
// | Ends with "s"      | Trailing "s" is removed   |
// | "general"          | Finds name "string"       |
// | "guid"             | Replaced with "GUID"      |
// | ""                 | Replaced with "symbol"    |
//
// @param prefix    {string} Prefix of typed function
// @param name      {string} Name of type to lookup
//
// @returns {string} Constructed name of function to return
.z.m.axq.i.lookup:{[prefix; name]
    name: $["s" ~ last name; -1 _ name; name];
    
    : $[name like "[tT]ype"; /dnl
            ""; 
        name ~ "general";  /dnl
            ".z.m.axq.", prefix, "String"; /dnl
        name ~ "guid"; /dnl
            ".z.m.axq.", prefix, "GUID"; /dnl
        name ~ "";
            ".z.m.axq.", prefix, "Symbol"; /dnl
        ("S"$raze N:prefix, (upper; ::) @' 0 1 cut name) in key `.axq;
            raze ".z.m.axq.", N; /dnl
            '"type: unrecognized type - ", name
            ];
        
        }

// @private
//
// @fileOverview
// Left pads the given input data with a fil value until
// the data is of the desired length.
//
// @param len   {long}  Length of vector to return
// @param fill  {*}     Value to left pad with
// @param data  {*}     Vector to left pad
//
// @returns {*} Input 'data' of length 'len' padded with 'fill'
.z.m.axq.i.lpad:{[len; fill; data]
    : $[len < count data; len # data; ((len-count data)#fill),data]
    }

/=>  .z.M.axq.asSymbol
//
// @param prefix {string} Function prefix
// @param suffix {string} Function suffix
//
// @returns {symbol} Qualified function name
.z.m.axq.i.name:{[prefix; suffix]
    : ("S"$raze ".z.m.axq.", prefix, (upper;::)@'0 1 cut suffix) /dnl
    }
// @private
//
// @fileOverview
// Given a type suffix, return the correct null value
//
// @example
// .z.m.axq.i.null "z"
// /=> 0Nz
//
// .z.m.axq.i.null "c"
// /=> " "
//
// @param x {char} Type suffix identifier
//
// @returns {*} Null value for desited type
.z.m.axq.i.null:{first exec nil from i.DATA_MAP where suffix = lower x}

// @private
//
// @fileOverview
// Attempts to parse the given input data if it is a string. If the
// data is not parsable then try to cast the data. Finally, if the
// data is of an unknown type then throw an error. 
//
// @param suffix    {char}      Type suffix of target type
// @param reparse   {function}  Parsing function for converting string data
// @param recast    {function}  Casting function for converting unparsable data
// @param data      {*}         Data to convert
// 
// @returns {*} Converted data to the desired type
.z.m.axq.i.parse:{[suffix; reparse; recast; data]
  
    ty: i.truetype data;
    
    : $[ty ~ 11h;
            reparse .z.m.axq.asString data;
        ty ~ 10h;
            reparse data;
        ty ~ 0h;
            $[all 10h = type each data; 
                reparse data; 
                .z.s[suffix; reparse; recast] each data
                ];
        ty in 0 98 99h;
            $[0 ~ count data; 
                recast data;
                .z.s[suffix; reparse; recast] each data
                ];
        ty in i.PARSE_TYPES;
            recast data;
        data ~ (::);
            i.null suffix;
            '"type: unsupported parse operation for ",string[typeOf data]," to given type" /dnl
        ];
    
    }

// @private
//
// @fileOverview
// Maps the data in a data structure to be a static value. This
// function maintains the shape of the input data.
//
// @param value_    {*} Static value to populate data with
// @param data      {*} Data to remap
//
// @returns {*} Input data remapped to contain only value_
.z.m.axq.i.remap:{[value_; data]
    : $[isCompound data; .z.s[value_] each data; 0 > type data; value_; count[data]#value_]
    }

// @qlintsuppress UNUSED_INTERNAL
// @private
//
// @fileOverview
// Sets a type function that uses the given prefix from the .axq namespace.
//
// @param prefix    {string}    Prefix of named type function
// @param runnable  {function}  Runnable function to project datamap into 
// @param datamap   {dict}      A data mapping record
//
// @returns {symbol} Name of bound function
.z.m.axq.i.set:{[prefix; runnable; datamap]
    : i.name[prefix; string datamap`name] set runnable datamap
    }

// @private
//
// @fileOverview
// Returns the absolute type of the input data. If the
// type is compound then the simple vector type is returned
//
// @param data {*} Data to determine type of
//
// @returns {short} Type of input data
.z.m.axq.i.truetype:{[data]
    : $[77h < p:abs type data; $[p < 98h; "h"$-77 + p; p]; 77h ~ p; abs type first data; p]
    }

// @fileOverview
// Returns true if the input is an atom
//
// @example Checking isAtom
// .z.m.axq.isAtom 1
// /=> 1b
//
// .z.m.axq.isAtom til 10
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is an atom
.z.m.axq.isAtom:{(0 > type x)|99<type x}
// @fileOverview
// Returns true if the input is a boolean atom
//
// @example Checking isBoolean
// .z.m.axq.isBoolean 0b
// /=> 1b
//
// .z.m.axq.isBoolean 1
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a boolean atom
.z.m.axq.isBoolean:{-1h ~ type x}
// @fileOverview
// Returns true if the input is a byte atom
//
// @example Checking isByte
// .z.m.axq.isByte 0x12
// /=> 1b
//
// .z.m.axq.isByte 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a byte atom
.z.m.axq.isByte:{-4h ~ type x}
// @fileOverview
// Returns true if the input is a char atom
//
// @example Checking isChar
// .z.m.axq.isChar "a"
// /=> 1b
//
// .z.m.axq.isChar 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a char atom
.z.m.axq.isChar:{-10h ~ type x}
// @fileOverview
// Returns true if the input is a compound data type
//
// @example Checking isCompound
// .z.m.axq.isCompound ("abc"; "def")
// /=> 0b
//
// .z.m.axq.isCompound get `:v set ("abc"; "def")
// /=> 1b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is compound data 
.z.m.axq.isCompound:{ type[x] within 77 97 }
// @fileOverview
// Returns true if the input is a date atom
//
// @example Checking isDate
// .z.m.axq.isDate 2015.05.22
// /=> 1b
//
// .z.m.axq.isDate 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a date atom
.z.m.axq.isDate:{-14h ~ type x}

// @fileOverview
// Returns true if the input is a datetime atom
//
// @example Checking isDatetime
// .z.m.axq.isDatetime 2015.05.22T12:34:56.789
// /=> 1b
//
// .z.m.axq.isDatetime 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a datetime atom
.z.m.axq.isDatetime:{-15h ~ type x}
// @fileOverview
// Returns true if the given input is a dictionary
// 
// @example Checking isDictionary
// .z.m.axq.isDictionary `a`b!(1 2 3; "abc")
// /=> 1b
//
// .z.m.axq.isDictionary flip `a`b!(1 2 3; "abc")
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a dictionary
.z.m.axq.isDictionary:{99h ~ type x}
// @fileOverview
// Returns true if the given input has a count of 0
//
// @example Checking isEmpty
// .z.m.axq.isEmpty ([] ())
// /=> 1b
// 
// .z.m.axq.isEmpty 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input has a count of 0
.z.m.axq.isEmpty:{0 ~ count x}
// @fileOverview
// Returns true if the input is an enumeration
//
// @example Checking isEnum
// .z.m.axq.isEnum 1 2 3 4
// /=> 0b
//
// .z.m.axq.isEnum `sym?`a`b`c
// /=> 1b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is an enumerated value
.z.m.axq.isEnum:{abs[type x] within 20 76}
// @fileOverview
// Returns true if the input is a float atom
//
// @example Checking isFloat
// .z.m.axq.isFloat 12.0
// /=> 1b
//
// .z.m.axq.isFloat 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a float atom
.z.m.axq.isFloat:{-9h ~ type x}

// @fileOverview
// Returns true if the input is a function
//
// @example Checking isFunction
// .z.m.axq.isFunction sum
// /=> 1b
//
// .z.m.axq.isFunction 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a function
.z.m.axq.isFunction:{99h < type x}
// @fileOverview
// Returns true if the input is a guid atom
//
// @example Checking isGUID
// .z.m.axq.isGUID first 1?0ng
// /=> 1b
//
// .z.m.axq.isGUID 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a GUID atom
.z.m.axq.isGUID:{-2h ~ type x}
// @fileOverview
// Returns true if the input is a general type
//
// @example Checking isGeneral
// .z.m.axq.isGeneral ()
// /=> 1b
//
// .z.m.axq.isGeneral 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a general type
.z.m.axq.isGeneral:{0h ~ type x}
// @fileOverview
// Returns true if the input value is an atom and is considered
// to be an infinity for its respective type
//
// @example Checking isInfinity
// .z.m.axq.isInfinity 1b
// /=> 1b
//
// .z.m.axq.isInfinity 0W
// /=> 1b
//
// .z.m.axq.isInfinity 0N
// /=> 0b
//
// @param x {*} Data value to check
// 
// @returns {boolean} If the input is an atom and is infinite
.z.m.axq.isInfinity:{$[0>type x; x in INFINITY; 0b]}

// @fileOverview
// Returns true if the input is an int atom
//
// @example Checking isInt
// .z.m.axq.isInt 12i
// /=> 1b
//
// .z.m.axq.isInt 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is an int atom
.z.m.axq.isInt:{-6h ~ type x}
// @fileOverview
// Returns true if the input is a dictionary and both
// the key and the value of the dictionary are tables
//
// @example Checking isKeyedTable
// .z.m.axq.isKeyedTable ([x: til 5] y: "abcde")
// /=> 1b
//
// .z.m.axq.isKeyedTable ([] x: til 5; y: "abcde")
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a keyed table
.z.m.axq.isKeyedTable:{$[99h ~ type x; all 98h = type each (key x;value x); 0b]} 




// @fileOverview
// Returns true if the input is an enumeration that is not 
// symbolic but is linked to another vector.
//
// @example Checking isLinked
// .z.m.axq.isLinked 1 2 3 4
// /=> 0b
//
// v: 100?10;
// x: `v!v?100?10;
// .z.m.axq.isLinked x
// /=> 1b
//
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a linked vector
.z.m.axq.isLinked:{$[isEnum x; @[{11h <> type get key x};x;0b]; 0b]}

// @fileOverview
// Returns true if the given data is a list of data
//
// @example Checking isList
// .z.m.axq.isList "Hello, World!"
// /=> 1b
//
// .z.m.axq.isList 1b
// /=> 0b
//
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a list
.z.m.axq.isList:{type[x] within 0 97}

// @fileOverview
// Returns true if the input is a long atom
//
// @example Checking isLong
// .z.m.axq.isLong 12
// /=> 1b
//
// .z.m.axq.isLong 12.0
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a long atom
.z.m.axq.isLong:{-7h ~ type x}
// @fileOverview
// Returns true if the input is a minute atom
//
// @example Checking isMinute
// .z.m.axq.isMinute 12:34
// /=> 1b
//
// .z.m.axq.isMinute 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a minute atom
.z.m.axq.isMinute:{-17h ~ type x}
// @fileOverview
// Returns true if the input is a month atom
//
// @example Checking isMonth
// .z.m.axq.isMonth 2015.05m
// /=> 1b
//
// .z.m.axq.isMonth 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a month atom
.z.m.axq.isMonth:{-13h ~ type x}
// @fileOverview
// Returns true if the input value is an atom and is considered
// to be null for its respective type
//
// @example Checking isNull
// .z.m.axq.isNull " "
// /=> 1b
//
// .z.m.axq.isNull 0N
// /=> 1b
//
// .z.m.axq.isNull 0W
// /=> 0b
//
// @param x {*} Data value to check
// 
// @returns {boolean} If the input is an atom and is null
.z.m.axq.isNull:{$[0 > type x;null x;x ~ (::)]}


// @fileOverview
// Returns true if the input value is an atom and is numeric.
// Numeric types include the following types:
//
// - boolean
// - byte
// - short
// - int
// - long
// - real
// - float
//
// @example Checking isNumber
// .z.m.axq.isNumber 12
// /=> 1b
//
// .z.m.axq.isNumber 0xff
// /=> 1b
//
// .z.m.axq.isNumber 2015.05.22
// /=> 0b
//
// @param x {*} Data value to check
// 
// @returns {boolean} If the input is an atom and is a number
.z.m.axq.isNumber:{neg[type x] in i.NUMBER_TYPES}

// @fileOverview
// Returns true if the input is a real atom
//
// @example Checking isReal
// .z.m.axq.isReal 12.0e
// /=> 1b
//
// .z.m.axq.isReal 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a real atom
.z.m.axq.isReal:{-8h ~ type x}
// @fileOverview
// Returns true if the input is a second atom
//
// @example Checking isSecond
// .z.m.axq.isSecond 12:34:56
// /=> 1b
//
// .z.m.axq.isSecond 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a second atom
.z.m.axq.isSecond:{-18h ~ type x}
// @fileOverview
// Returns true if the input is a short atom
//
// @example Checking isShort
// .z.m.axq.isShort 12h
// /=> 1b
//
// .z.m.axq.isShort 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a short atom
.z.m.axq.isShort:{-5h ~ type x}
// @fileOverview
// Returns true if the input is a char vector
//
// @example Checking isString
// .z.m.axq.isString "Hello, World!"
// /=> 1b
//
// .z.m.axq.isString `APPL
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a char vector
.z.m.axq.isString:{10h ~ type x}
// @fileOverview
// Returns true if the input is a symbol atom
//
// @example Checking isSymbol
// .z.m.axq.isSymbol `AAPL
// /=> 1b
//
// .z.m.axq.isSymbol "Hello, World!"
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a symbol atom
.z.m.axq.isSymbol:{-11h ~ type x}
// @fileOverview
// Returns true if the input is a table
//
// @example Checking isTable
// .z.m.axq.isTable ([] x: til 5; y: "abcde")
// /=> 1b
//
// .z.m.axq.isTable `a`b!(1 2 3; "abc")
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a table
.z.m.axq.isTable:{$[98h ~ type x; 1b;isKeyedTable x]}
// @fileOverview
// Returns true if the input is a time atom
//
// @example Checking isTime
// .z.m.axq.isTime 12:34:56.789
// /=> 1b
//
// .z.m.axq.isTime 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a time atom
.z.m.axq.isTime:{-19h ~ type x}
// @fileOverview
// Returns true if the input is a timespan atom
//
// @example Checking isTimespan
// .z.m.axq.isTimespan 0D12:34:56.789
// /=> 1b
//
// .z.m.axq.isTimespan 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a timespan atom
.z.m.axq.isTimespan:{-16h ~ type x}
// @fileOverview
// Returns true if the input is a timestamp atom
//
// @example Checking isTimestamp
// .z.m.axq.isTimestamp 2015.05.22D12:34:56.789
// /=> 1b
//
// .z.m.axq.isTimestamp 12
// /=> 0b
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a timestamp atom
.z.m.axq.isTimestamp:{-12h ~ type x}
// @fileOverview
// Dynamically dispatches to the desired is* function to check the type
//
// @example Checking isType
// .z.m.axq.isType[`APPL; `symbol]
// /=> 1b
//
// .z.m.axq.isType[2015.05.22; `date]
// /=> 1b
//
// .z.m.axq.isType[12.0; `long]
// /=> 0b
//
// @param data  {*}         Data to type check
// @param ty    {symbol}    Type to check
//
// @returns {boolean} If the input is of the correct type
.z.m.axq.isType:{[data; ty]
    : get[i.lookup["is"; string ty]] data  /dnl
    }
// @fileOverview
// Returns true if the given data is a simple list
// of atoms that are all the same type
//
// @example Checking isList
// .z.m.axq.isVector "Hello, World!"
// /=> 1b
//
// .z.m.axq.isVector (1; `APPL; 2015.05.22)
// /=> 0b
//
//
// @param x {*} Data to type check
// 
// @returns {boolean} If the input is a vector
.z.m.axq.isVector:{type[x] within 1 19}
// @fileOverview
// Dynamically dispatches to the desired parse* function
// to parse some data
//
// @example String to Number
// .z.m.axq.parseType["100"; `long]
// /=> 100
//
// @example String to Time
// "12:34:56.789" parseType `time
// /=> 12:34:56.789
//
// @param data  {*}         Data to parse
// @param ty    {symbol}    Type to parse to
//
// @returns {*} Data with same shape of desired type
.z.m.axq.parseType:{[data; ty]
    : get[i.lookup["parse"; string ty]] data  /dnl
    }

// @fileOverview
// Returns the name of the type of the input as a symbol
//
// @example Checking typeOf 
// .z.m.axq.typeOf 12
// /=> `long
//
// .z.m.axq.typeOf 12:34:56.789
// /=> `time
//
// .z.m.axq.typeOf typeOf
// /=> `lambda
//
// @param x {*} Data to get type of
//
// @returns {symbol} Name of type of data
.z.m.axq.typeOf:{$[0>type x; .z.m.axq.i_PRIMCODE neg type x; .z.m.axq.i_NONPRIMCODE type x]}
    
// @fileOverview
// Returns the name of the type of the input as a symbol
//
// @deprecated
//
// @param x {*} Data to get type of
//
// @returns {symbol} Name of type of data
//
// @see typeOf
// ***WARNING*** - presence of this function is used as a test in the kickstarter
.z.m.axq.typeSymbol:{ typeOf x } 
// @fileOverview
// Returns a set of numbers in a range from [x,y) 
//
// @example Using until
// .z.m.axq.until[1; 5]
// /=> 1 2 3 4
//
// .z.m.axq.until[5; 10]
// /=> 5 6 7 8 9
//
// @param x {number} Base index for list
// @param y {number} Upper limit of list
//
// @returns {long[]} From x inclusive to y exclusive
.z.m.axq.until:{$[y < x; `long$(); x + til y - x]}



// @fileOverview
// Returns the exclusive or of two inputs
//
// @example Finding Differences
// .z.m.axq.xor[101b; 111b]
// /=> 010b
//
// @example Inverting Values
// .z.m.axq.xor[1b; 0101b]
// /=> 1010b
//
// @param x {boolean | boolean[]}   Left list to xor with
// @param y {boolean | boolean[]}   Right list to xor with
//
// @returns {boolean | boolean[]} Exclusive or of the inputs 
.z.m.axq.xor:{(x & not y) | not[x] & y}
.z.m.axq.asTimestamp:i.cast["p"; 2 11h; i.asTimestamp]
.z.m.axq.asShort:i.cast["h"; 2 11h; $["h"]]
.z.m.axq.asReal:i.cast["e"; 2 11h; $["e"]]
.z.m.axq.asLong:i.cast["j"; 2 11h; $["j"]]

.z.m.axq.asInt:i.cast["i"; 2 11h; $["i"]]
.z.m.axq.asFloat:i.cast["f"; 2 11h; $["f"]]
.z.m.axq.asDatetime:i.cast["z"; 2 11h; i.asDatetime]
.z.m.axq.asDate:i.cast["d"; 2 11h; i.asDate]
.z.m.axq.asChar:i.cast["c"; 2h; {$[-11h ~ type x; first string x; 11h ~ type x; "c"$first each string x; "c"$x]}]

.z.m.axq.asByte:i.cast["x"; 2 11h; $["x"]]
.z.m.axq.asBoolean:i.cast["b"; 2 11h; $["b"]]
.z.m.axq.i.DATA_MAP:([]
    name    : `general`boolean`guid`byte`short`int`long`real`float`char`symbol`timestamp`month`date`datetime`timespan`minute`second`time;
    id      : `s#0 1 2 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19h;
    suffix  : " bgxhijefcspmdznuvt"; /dnl
    nil     : (::; 0b;                                        0Ng;  0x0; 0Nh; 0Ni; 0N; 0Ne; 0n;     " "; `; 0Np; 0Nm; 0Nd; 0Nz; 0Nn; 0Nu; 0Nv; 0Nt);
    infinity: (::; 1b; "G"$"FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"; 0xff; 0Wh; 0Wi; 0W; 0We; 0w;  "\000"; `; 0Wp; 0Wm; 0Wd; 0Wz; 0Wn; 0Wu; 0Wv; 0Wt)  /dnl
    )
.z.m.axq.parseTimestamp:i.parse["P"; $["P"]; asTimestamp]
.z.m.axq.parseTimespan:i.parse["N"; $["N"]; asTimespan]
.z.m.axq.parseTime:i.parse["T"; $["T"]; asTime]
.z.m.axq.parseSymbol:asSymbol
.z.m.axq.parseString:asString
.z.m.axq.parseShort:i.parse["H"; $["H"]; asShort]
.z.m.axq.parseSecond:i.parse["V"; $["V"]; asSecond]
.z.m.axq.parseReal:i.parse["E"; $["E"]; asReal]
.z.m.axq.parseMonth:i.parse["M"; $["M"]; asMonth]
.z.m.axq.parseMinute:i.parse["U"; $["U"]; asMinute]
.z.m.axq.parseLong:i.parse["J"; $["J"]; asLong]
.z.m.axq.parseInt:i.parse["I"; $["I"]; asInt]
.z.m.axq.parseGUID:i.parse["G"; $["G"]; asGUID] 
.z.m.axq.parseFloat:i.parse["F"; $["F"]; asFloat]
.z.m.axq.parseDatetime:i.parse["Z"; $["Z"]; asDatetime]
.z.m.axq.parseDate:i.parse["D"; $["D"]; asDate]
.z.m.axq.parseChar:asChar
.z.m.axq.parseByte:i.parse["X"; $["X"]; asByte]

.z.m.axq.parseBoolean:i.parse["B"; $["B"]; asBoolean]
.z.m.axq.isDict:.z.m.axq.isDictionary
.z.m.axq.i.PARSE_TYPES:`s#"h"$1 + til 19
.z.m.axq.i.NUMBER_TYPES:`s#1 4 5 6 7 8 9h 

.z.m.axq.i.ENUM_TYPES:`s#"h"$20 + til $[.z.K >= 3.6; 77; 78] - 20
.z.m.axq.i.COMPOUND_TYPES:`s#"h"$77 + til 97 - 77
.z.m.axq.i.CAST_TYPES:`s#"h"$(1 + til 19)
.z.m.axq.NULL:exec name!nil from i.DATA_MAP where not name in ``general

.z.m.axq.INFINITY:exec name!infinity from i.DATA_MAP where not name in `general`guid`char`symbol
// @private
//
// @fileOverview
// Helper function constants 
// A set of dictionaries that have names that are easier to remember and read.
// @returns {null}
.z.m.axq.onLoad:{[]
    
    


    i_PRIMCODE       :: 21#`undefined;
    i_NONPRIMCODE    :: 113#`undefined;


    
    i_PRIMCODE [1 2 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]  :: `boolean`guid`byte`short`int`long`real`float`char`symbol`timestamp`month`date`datetime`timespan`minute`second`time`enum;



    i_NONPRIMCODE [0 1 2 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19]::`general`booleans`guids`bytes`shorts`ints`longs`reals`floats`chars`symbols`timestamps`months`dates`datetimes`timespans`minutes`seconds`times;
    

    i_NONPRIMCODE [20+til 77-20]                                 ::`enum;
    
    
    i_NONPRIMCODE [77 +til 21]                                   :: `${"compound",upper [first x],1_x} each string i_PRIMCODE; /dnl
    i_NONPRIMCODE [77]                                           :: `compoundGeneral;


    i_NONPRIMCODE [98 99 100 101 102 103 104 105]                ::`table`dictionary`lambda`unary`binary`ternary`projection`composition;


    i_NONPRIMCODE [106 107 108 109 110 111]                      :: `$("f'";"f/";"f\\";"f':";"f/:";"f\\:");


    i_NONPRIMCODE [112]                                          :: `dynamicload;

    API :: key[.z.M.axq] except ``i`ks;
    }

.z.m.axq.onLoad[];
system "d .z.m";

system "d .z.m.ax";

// @fileOverview
// This function loads code from a shared library based on symbolic function name + arg count.
// @param dir {string} The path to the shared library folder
// @param lib {symbol} The name of the shared library
// @param fnSym {symbol} The name of the function to load (must be of type K)
// @param argc {long} The arg count of the function
// @returns {function} code 
.z.m.ax.rt.i.sharedLoad:{[dir;lib;fnSym;argc]
    if[not -11h = type fnSym;' `nyiu];
    if[argc < 1;argc:1]; //Argc cannot be 0 or negative (0 args are technically 1 because generic null is passed)
    soPath:`$(dir,string[lib]);
    :.[{[soPath;fnSym;argc] :soPath 2:(fnSym;argc)};
        (soPath;fnSym;argc);
        {[x;lib;fnSym;argc] 
            -2 err:"Error loading ",string[lib]," ",string[fnSym],":", x;
            p:{[x;a0;a1;a2;a3;a4;a5;a7] 'x}[err;]; 
            :$[argc < 7;:p . (7 - argc)#(::);:p]; 
            }[;lib;fnSym;argc]
        ];
    }

// @fileOverview Load c api in bulk, erroring only once
// @param dir {string} directory to clib
// @param lib {symbol} library name (`` `q_skia ``)
// @param toLoad {any[][]} list of triples of (q name to set; c function to load; c rank)[]
// @returns {Type} 0 on success, 1 on error
.z.m.ax.rt.i.sharedLoadBulk:{[dir;lib;toLoad]
    loadOne: {[lib; failed; args]
        : .[{ x set y 2: z; 0b }; 
            (args 0; lib; args 1 2);
            {[failed; lib; f; c; err] 
                err  : "Error loading ",string[lib],": ", err;
                err ,: "\nPlease ensure all dependencies have been installed and environment variables have been set";
                
                if [not failed;
                    -2 err];

                p: {[x;a0;a1;a2;a3;a4;a5;a7] 'x} err;
                f set $[c < 7; p . (7 - c)#(::); p];

                1b
                }[failed;lib;args 0;args 2]];
        };
    
    toLoad[;2] |: 1;
    : 0b loadOne[`$dir,string lib]/toLoad;
    }


// @fileOverview Enter a description here...
// @returns {Type} Enter a Return description here...
.z.m.ax.rt.onLoad:{[]
    rt.sharedLoad:      rt.i.sharedLoad[(.Q.rp "::../lib"),"/",string[.z.o],"/";;;];
    rt.sharedLoadBulk:  rt.i.sharedLoadBulk[(.Q.rp "::../lib"),"/",string[.z.o],"/";;];
    }

.z.m.ax.rt.onLoad[];
system "d .z.m";


system "d .z.m.axds";
// @fileOverview Return true if left
// @param d {dict} 
// @returns {boolean}
.z.m.axds.opt.isLeft:{[d]
    if [not 99h ~ type d;                   : 0b]; /dnl
    if [not all `isLeft`value in\: key d;   '"Given non option in isLeft"];     /dnl
    : d`isLeft;
    }

// @fileOverview Return true if right
// @param d {dict} 
// @returns {boolean}
.z.m.axds.opt.isRight:{[d]
    if [not 99h ~ type d;                  '"Given non dictionary in isRight"];  /dnl
    if [not all `isLeft`value in\: key d;  '"Given non option in isRight"];      /dnl
    : not d`isLeft
    }

// @fileOverview Build a left dictionary (failure)
// @param val {any} 
// @returns {dict}
.z.m.axds.opt.left:{[val] `isLeft`value!(1b; val) }

// @fileOverview Build a right dictionary (success)
// @param val {any} 
// @returns {dict}
.z.m.axds.opt.right:{[val] `isLeft`value!(0b; val) }

// @fileOverview Retrieve the enclosed value
// @param d {dict} 
// @returns {any}
.z.m.axds.opt.val:{[d]
    if [not 99h ~ type d;
        '"Given non dictionary in val"];
    if [not all `isLeft`value in\: key d;
        '"Given non option in val"];
    : d`value;
    }
system "d .z.m";

system "d .z.m.axpc";
.z.m.axpc.utl.clean:{[s]
    ssr[;"\n";"\\n"]
        ssr[;"\t";"\\t"]
        ssr[;"\r";"\\r"]
        "c"$raze s
    }
system "d .z.m";

system "d .z.m.axpc";
// @fileOverview Apply a function to the result of a parser. If the function errors, the parser fails
// @param f {function} function to apply to the produced tokens
// @param p {function} parser to produce the tokens for the function
// @returns {function} A parser to apply f to the tokens output from p
//
// @example 
// .z.m.axpc.prs[.z.m.axpc.char "a"] "a"
// => "a"
//
// @example 
// .z.m.axpc.prs[.z.m.axpc.a[`$] .z.m.axpc.char "a"] "a"
// => `a
//
// @example reserved words
// reserved: ("if";"then";"else");
// .z.m.axpc.prs[.z.m.axpc.oneOf (.z.m.axpc.a[{if [x in reserved; '"reserved word: ",x];x}] .z.m.axpc.identifier; "else")] "else"
// => Error parsing at line 1, column 4: application error: reserved word: else
//
// @example reserved words with backtracking
// reserved: ("if";"then";"else");
// .z.m.axpc.prs[.z.m.axpc.oneOf (.z.m.axpc.a[{if [x in reserved; '"reserved word: ",x];x}] .z.m.axpc.identifier; "else")] "else"
// => "else"
//
.z.m.axpc.a:{[f; p] 
    : {[f; p; state]
        r: p state;
        : $[i.safe[.z.m.axds.opt.isLeft; r; state]; 
            r; 
            @[{[r;f] .z.m.axds.opt.right (f .z.m.axds.opt.val[r]0; .z.m.axds.opt.val[r]1)} r; f;
                {[r;x] .z.m.axds.opt.left (enlist `type`value!(`apply;x); .z.m.axds.opt.val[r]1) } r]]
        }[f; i.wrap p]
    }

// @fileOverview Similar to .z.m.axpc.a, this function applies a function to the result of a parser.
//               Unlike .z.m.axpc.a, this function also accepts the start and end positions of the parsed text
//               in the original string (along with the parsed text).
//               The start position represents the index of the first character in the text. 
//               The end position represents 1 + the index of the final character in the test.
//               This can be useful if additional post-processing is required that makes use of a tokens position.
//               If the function errors, the parser fails
// @param f {function} function to apply to the produced tokens. This function must accept three arguments, the first one
//                     is the parsed text, and the second is the start position in the string. 
//                     The third is the end position in the string (equals 1 + the index of the final character in the parsed text).
// @param p {function} parser to produce the tokens for the function
// @returns {function} A parser to apply f to the tokens output from p
//
// @example 
// .z.m.axpc.prs[.z.m.axpc.a[`$] .z.m.axpc.char "a"] "a"
// => `a
//
// @example 
// .z.m.axpc.prs[.z.m.axpc.aPos[{ enlist (`$x;y;z)}] .z.m.axpc.char "a"] "a"
// => `a 0 1
//
.z.m.axpc.aPos:{[f; p] 
    : {[f; p; state]
        r: p state;
        : $[.z.m.axpc.i.safe[.z.m.axds.opt.isLeft; r; state]; 
            r; 
            @[{[r;f;start] 
                    txt : .z.m.axds.opt.val[r]0;
                    .z.m.axds.opt.right (f[txt;start;.z.m.axds.opt.val[r][1]`pos]; .z.m.axds.opt.val[r] 1)}[;;state`pos] r; f;
                {[r;x] .z.m.axds.opt.left (enlist `type`value!(`apply;x); .z.m.axds.opt.val[r]1) } r]]
        }[f; .z.m.axpc.i.wrap p]
    }
// @fileOverview 
// A parser matching any single character
// @returns {dict}
// @example 
// .z.m.axpc.prs[.z.m.axpc.anyChar] "a"
// => "a"
// @example 
// .z.m.axpc.prs[.z.m.axpc.anyChar] "b"
// => "b"
.z.m.axpc.anyChar:{[state]
    c: i.grab1 state;
    if [i.safe[.z.m.axds.opt.isLeft; c; state]; : c];
    : .z.m.axds.opt.right (c; @[state;`pos`consumed;+;1]);
    }

// @fileOverview 
// A parser matching any characters in the set of characters given
// @param a {char|string} Characters to accept
// @return {function}
// @example
// .z.m.axpc.prs[.z.m.axpc.anyOf "abcd"] "a"
// //=> "a"
// .z.m.axpc.prs[.z.m.axpc.anyOf "abcd"] "z"
// 'Error parsing at line 1, column 0: Expected one of "abcd" but read "z"
.z.m.axpc.anyOf:{[a]
    : {[a; state] 
        c: i.grab1 state;
        if [i.safe[.z.m.axds.opt.isLeft; c; state]; : c];
        
        : $[c in a;
                .z.m.axds.opt.right (c; @[state;`pos`consumed;+;1]);
                .z.m.axds.opt.left (enlist `type`value!(`expected;i.errorStr(`.axpc_oneOfError;utl.clean each a)); state)];
        } a
    }

// @fileOverview
// A parser of three parsers: beginning, middle, and end. Only the value parsed by the middle parser is returned,
// but all three parsers must succeed in sequence.
// @param p1 {function} first parser in the sequence, skipped
// @param p2 {function} second parser in the sequence, output
// @param p3 {function} thrid parser in the sequence, skipped
// @returns {function}
// @example String parser
// .z.m.axpc.prs[.z.m.axpc.between[.z.m.axpc.char"\""; .z.m.axpc.many .z.m.axpc.notAny"\""; .z.m.axpc.char"\""]] "\"this is a string\""
// //=> "this is a string"
.z.m.axpc.between:{[p1; p2; p3]
    : {[p1; p2; p3; state]
        
        r1 : p1 state;
        if [i.safe[.z.m.axds.opt.isLeft; r1; state]; 
            : r1];
        
        r2 : p2 i.state r1;
        if [i.safe[.z.m.axds.opt.isLeft; r2; i.state r1] or not i.backtrack r2; 
            : r2];
        
        r3 : p3 i.state r2;
        if [i.safe[.z.m.axds.opt.isLeft; r3; i.state r2];
            : r3];
        
        : .z.m.axds.opt.right (i.item r2; i.state r3)
        
        }[i.wrap p1; i.wrap p2; i.wrap  p3]
    
    }

.z.m.axpc.casestr:{[s]
    : lexeme i.str[{y;1b};1b] s
    }  
// @fileOverview
// Parser for a single character
// @param a {char} Character to parse
// @returns {function}
// @example
// .z.m.axpc.prs[.z.m.axpc.ch"a"] "a"
// //=> "a"
// @example
// .z.m.axpc.prs[.z.m.axpc.ch"a"] "b"
// //=> 'Error parsing at line 1, column 0: Expected "a" but read "b"
.z.m.axpc.ch:{[a]
    : {[a; state]
        c: i.grab1 state;
        if [i.safe[.z.m.axds.opt.isLeft; c; state]; 
            : c];
  
        : $[a ~ c;
            .z.m.axds.opt.right (a; @[state;`pos`consumed;+;1]);
            .z.m.axds.opt.left  (enlist`type`value!(`expected;"\"",utl.clean[a],"\""); state)];
        } a
    }

// @fileOverview
// Parser for a single character
// @param a {char} Character to parse
// @returns {function}
// @example
// .z.m.axpc.prs[.z.m.axpc.char"a"] "a"
// //=> "a"
// @example
// .z.m.axpc.prs[.z.m.axpc.char"a"] "b"
// //=> 'Error parsing at line 1, column 0: Expected "a" but read "b"
// @deprecated
// @see axpc.ch
.z.m.axpc.char:{[a]
    : .z.m.axpc.ch a
    }

// @fileOverview Delay a parser to runtime to aid in defintions of recursive parsers
// @returns {function}
.z.m.axpc.delay:{[name]
    : `type`name!(`delayed; name)
    }

.z.m.axpc.dot:{[] notAny "\n" }

.z.m.axpc.ed:{ .z.m.axpc.a[enlist x .] y }
.z.m.axpc.em:{ .z.m.axpc.a[enlist x@] y }

// @fileOverview Parser for the end of an input stream
// @returns {dict}
// @example
// .z.m.axpc.prs[.z.m.axpc.end] ""
// //=> `PC_EOF
.z.m.axpc.end:{[state]
    : $[state[`pos] = count state`input;
        .z.m.axds.opt.right (EOF; state);
        .z.m.axds.opt.left (enlist `type`value!(`expected;"EOF"); state)];  /dnl
    }

.z.m.axpc.extend:{[ext;p]
    : options[ext`extension; p]
    }

.z.m.axpc.i.backtrack:{[r]r[`value][1]`backtrack}

.z.m.axpc.i.compress:{[x]
    z : where   0h = type each x;
    s : where  10h = type each x;
    c : where -10h = type each x;
    : (raze i.compress each x z),x[c],x s
    }
// @fileOverview Generate an error message
.z.m.axpc.i.error:{[r]
    lc: linecol r 1;
    msg:     i.errorStr(`.axpc_errorPre; i.fmtlinecol lc );

    specific : i.specificError r;

    if [r[1]`safe; 
        -1 "";
        -1 msg;
        -1 "        with content {{", utl.clean[r[1][`input] ii where count[r[1] `input] > ii:r[1][`pos]+til 10] , "}} ";
        -1 "        error: ", specific];
    
    : msg , specific;
    }
// @qlintsuppress UNUSED_INTERNAL
// TODO - is this used by external languages?
// @fileOverview Returns an error message with line and column as a dictionary
//               This can facilitate further processing of the error messages
// @param r {any[]}
// @returns {dict (line : long; col : long; error : string)}
//
// @example
// prs[char"a"] .z.m.axpc.options[enlist[`onerror]!enlist i.errorPos] "b"
// //=> line  | 1
// //=> column| 0
// //=> error | "expected one of \"a\""
.z.m.axpc.i.errorPos:{[r]
    lc: linecol r 1;
    : `line`column`error!(lc `line;lc `column; i.specificError r)
    }
.z.m.axpc.i.errorStr:{[args]
    
    error: first args;

    if [error ~ `.axpc_expected;
        args: first 1_args;
        : "expected ",$[`1~args`typ;"one of ";""],args`choice];
    
    if [error in key[messages] where not "{" in/: value messages;
        : messages error];
    
    args: first 1_args;
    if [not 99 = type args;
        k: `$messages[error] 1_where "b"$sums (-). "{}"=\:messages error;
        args: enlist[k]!enlist args];
    
    : {[m;k;v] ssr[m;"{",string[k],"}";.z.m.axq.asString v] }/[messages error; key args; value args]
    
    
    }
.z.m.axpc.i.fmtlinecol:{[o]i.errorStr(`.axpc_lineCol; `line`column!(string o`line; string o`column))}

// @fileOverview 
// Eat a single character from the input stream. If there are no characters left for consumption, 
// fail.
// @param state {dict} current parser state
// @returns {dict}
.z.m.axpc.i.grab1:{[state]
    : $[state[`pos] >= count state`input;
        .z.m.axds.opt.left (enlist `type`value!(`exhausted;""); state);
        state[`input] state`pos];
    }

.z.m.axpc.i.item:{[r].z.m.axds.opt.val[r]0}

.z.m.axpc.i.itemsFromList:{[state; list]
    $[state`nest; {x where not 0 = count each x} i.item each list; raze i.item each list]
    }

.z.m.axpc.i.safe:{[f; r; state]
    : $[state`safe; 
        @[f; r; {[s;x] 'i.error (enlist `type`value!(`safe; x); s)} state];
        f r]; 
    }

// @fileOverview Formats the error into a specific error message
// @param r {any[]}
// @returns {string}
.z.m.axpc.i.specificError:{[r]
    e: first r 0;
    
    : $[(0 = count e`value) and `expected ~ e`type; 
            i.errorStr`.axpc_exhaustedInput;
        `expected ~ e`type;
            i.errorStr(`.axpc_expected; `typ`choice!(`$string 10h ~ type e`value; $[10h ~ type e`value;e`value;", " sv i.compress e`value]));
        `eof ~ e`type;
            i.errorStr`.axpc_unexpectedEnd;
        `exhausted ~ e`type;
            i.errorStr`.axpc_exhaustedInput;
        `rejected ~ e`type;
            i.errorStr(`.axpc_rejected;e`value);
        `apply ~ e`type;
            i.errorStr(`.axpc_applyError;e`value);
        `safe ~ e`type;
            i.errorStr(`.axpc_safeError;e`value);
        "uncaught"] /dnl
    }
.z.m.axpc.i.state:{[r].z.m.axds.opt.val[r]1}

.z.m.axpc.i.str:{[f;caseinsensitive; s]     
    if [-10h ~ type s; s: raze s];
    : {[f; ci; str; state]
                
        c: count str;
        if [count[state`input] < state[`pos] + c;
            : .z.m.axds.opt.left (enlist `type`value!(`eof;""); state)];
        
        read : state[`input] state[`pos] + til c;
       
        : $[f[str;state] & $[ci; lower[read] ~ lower str; read ~ str];
            .z.m.axds.opt.right (read; @[state;`pos`consumed;+;c]);
            .z.m.axds.opt.left  (enlist `type`value!(`expected; "\"",utl.clean[str],"\""); state)];
        
        }[f; caseinsensitive; s]
    
    }
// @fileOverview Map a parser or a string/char to a parser
// @returns {function}
.z.m.axpc.i.wrap:{[p]
    t: type p;
    $[(0 = t) & 10 = type first p;     i.wrap first p;
      (0 = t) & 0 = type first p;      i.wrap first p;
      0    = t;                        i.wrapList p;
      10   = abs t;                    str p; 
      105  = t;                        ignore i.wrap value[value[p]0]1;
      99   = t;                        i.wrapref p`name;  
      -11h = t;                        i.wrapref p;  
                                       p]
    }
// @fileOverview 
// | means oneOf
// , means sepBy
// * means many
// + means many1
// > means seq
// ? means options
// % means between
// @ means a
// ~ means lookahead
// < means try
// @param l {any} Potential to wrap 
// @returns {fn} Parser
.z.m.axpc.i.wrapList:{[l]
    o:   first l;
    ops: (!) . flip (
        (|; { oneOf i.wrap each 1_x });
        (,; { sepBy[; i.wrap x 1] first i.wrap  2_x });
        (*; { many  first i.wrap  1_x });
        (+; { many1 first i.wrap  1_x });
        (>; { seq i.wrap each 1_x });
        (?; { optional  i.wrap 1_x });
        (%; { between[ i.wrap x 1; ; i.wrap 2_x] first i.wrap 3_x });
        (@; { a[x 1] first i.wrap 2_x });
        (~; { lookahead[i.wrap x 1] first i.wrap 2_x});
        (<; { try first i.wrap 1_x})
        );
    
    $[$[102 = type o;o in key ops;0b]; ops[o]l; o]
    }
.z.m.axpc.i.wrapref:{[x;y]
    if [y`safe; -1  (60$string x) , "{{" , (utl.clean y[`input] ii where count[y `input] > ii:y[`pos] + til 20) , "}}"];
    $[99 = type y`namespace; 
        [ if [not x in key y`namespace; '"Unknown rule: ",string x]; i.wrap[y[`namespace]x] y ];
        i.wrap[value $[`~y`namespace;x;` sv y[`namespace],x]]y] 
    }
// A parser where the value is always () rather than the string that was consumed
//
// Note that a q "composition" will be treated as an ignored parser. See examples below.
// @param p {function} A parser
// @returns {function}
// @example Fully explicit parser ignoring "hello"
// .z.m.axpc.prs[.z.m.axpc.seq[(.z.m.axpc.ignore .z.m.axpc.str "hello"; .z.m.axpc.str ", world")]] "hello, world"
// //=> ", world"
// @example Implicit string (lexeme) parsers
// .z.m.axpc.prs[.z.m.axpc.seq[(.z.m.axpc.ignore "hello"; ", world")]] "hello, world"
// //=> ", world"
// @example Overloading compositions to ignore select parsers
// .z.m.axpc.prs[.z.m.axpc.seq[("hello"--; ", world")]] "hello, world"
// //=> ", world"
.z.m.axpc.ignore:{[p]
    : a[{()}] i.wrap p;
    }

.z.m.axpc.lexeme:{[p]
    : {[p; state]
        r: p state;
        if [i.safe[.z.m.axds.opt.isLeft; r; state]; 
            : r];
        
        r2: $[state`consumews; ws[] i.state r; r];
        : .z.m.axds.opt.right (i.item r; i.state r2)
        } i.wrap p
    }


.z.m.axpc.linecol:{[state]
    lines : where (state`pos) > n:where "\n" = state`input; 
    col   : state[`pos] - 0^n last lines;
    line  : 1 + count lines;
    : `line`column!(line;col);
    }

// @fileOverview 
// Lookahead parser for use with the `oneOf` parser. 
// Backtracking only occurs if `p1` fails. If `p1`
// succeeds, the parser is committed and no backtracking
// Will occur if `p2` fails. The state is rolled back to
// before `p1` when parsing `p2`, and only the result of
// `p2` is returned.
// Acts like `try seq (a; b)`, but the try only applies
// to `a`. Once `b` is entered, any errors will ot trigger 
// a backtrack.
// @param p1 {function} lookahead parser 
// @param p2 {function} parser to proceed after lookahead 
// @returns {function} combined parser
//
// @example Lookahead succeds so following parser returns
// .z.m.axpc.prs[.z.m.axpc.oneOf (.z.m.axpc.lookahead["1"] "12"; "13")] "12"
// => "12"
//            
// @example No backtracking since the lookahead succeeds
// .z.m.axpc.prs[.z.m.axpc.oneOf (.z.m.axpc.lookahead["1"] "12"; "13")] "13"
// => 'Error parsing at line 1, column 1: expected one of "12"
//            
// @example Backtracking since the lookahead parser fails
// .z.m.axpc.prs[.z.m.axpc.oneOf (.z.m.axpc.lookahead["1"] "12"; "23")] "23"
// => "23"
//
.z.m.axpc.lookahead:{[p1; p2]
    : {[p1;p2;state]
        
        r: try[p1] state; 
        if [i.safe[.z.m.axds.opt.isLeft; r; state]; 
            : r];
        
        r2: p2 state;
        : $[i.safe[.z.m.axds.opt.isLeft; r2; state];
            .z.m.axds.opt.left (i.item r2; i.state r);
            r2]
        
        }[i.wrap p1; i.wrap p2]
    }

// This is to save writing .z.m.axpc.a[{: enlist (`text; x)}] or something similar through out the grammar
// @param tokenType {Symbol}
// @returns {Function} A combinator that converts the input into a pair like (`text; " found in file ")
.z.m.axpc.makeToken:{[tokenType]
    f: {[tokenType; val]  enlist (tokenType; val) }tokenType;
    : a f;
    };
// @fileOverview
// A parser matching zero or more of the given parser. The results of each is returned in an array.
// @param p {function} parser to repeat
// @returns {function}
// @example
// .z.m.axpc.prs[.z.m.axpc.many .z.m.axpc.char"a"] "aaaaaaa"
// //=> "aaaaaaa"
// .z.m.axpc.prs[.z.m.axpc.many .z.m.axpc.char"a"] ""
// //=> ()
.z.m.axpc.many:{[p]
    if [not any 99 100 104 105 0 10 -10 11 -11h ~\: type p;
        'i.errorStr`.axpc_manyTypeError];
    
    : {[p; state]
        r: .z.m.axds.opt.right ((); state);
        results: enlist[::];
         
        while [i.safe[.z.m.axds.opt.isRight; r; state]; 
            state: i.state r;
            r: p state;
            if [i.safe[.z.m.axds.opt.isRight; r; state]; 
                results ,: i.item r]];
        
        : $[i.safe[.z.m.axds.opt.isLeft; r; state] and state[`consumed] < i.state[r]`consumed;
            r;
            .z.m.axds.opt.right (1_results; state)];
        
        } i.wrap p;
    }

// @fileOverview
// A parser matching one or more of the given parser. The results of each is returned in an array.
// @param p {function} parser to repeat
// @returns {function}
// @example
// .z.m.axpc.prs[.z.m.axpc.many1 .z.m.axpc.char"a"] "aaaaaaa"
// //=> "aaaaaaa"
// .z.m.axpc.prs[.z.m.axpc.many1 .z.m.axpc.char"a"] ""
// //=> 'Error parsing at line 1, column 0: Exhausted input
.z.m.axpc.many1:{[p]

    if [not any -11 99 100 104 105 0 10 -10 11 -11h ~\: type p;
        'i.errorStr`.axpc_many1TypeError];
    : {[p; state]
        r: p state;
        if [.z.m.axds.opt.isLeft r; 
            : r];
        
        results: enlist[::] , i.item r;
        
        while [i.safe[.z.m.axds.opt.isRight; r; state]; 
            state: i.state r;
            r: p state;
            if [i.safe[.z.m.axds.opt.isRight; r; state]; 
                results ,: i.item r]];
        
        : $[i.safe[.z.m.axds.opt.isLeft; r; state] and state[`consumed] < i.state[r]`consumed;
            r;
            .z.m.axds.opt.right (1_results; state)];
        
        } i.wrap p;
    }

// @fileOverview 
// A parser matching any characters not in the set of characters given
// @param cs {char|string} Character(s) to avoid
// @return {function}
// @example
// .z.m.axpc.prs[.z.m.axpc.notAny "abcd"] "a"
// //=> 'Error parsing at line 1, column 0: Character in exclusion set
// .z.m.axpc.prs[.z.m.axpc.notAny "abcd"] "z"
// "z"
.z.m.axpc.notAny:{[cs]
    if [-10h ~ type cs; cs : enlist cs];
    : {[cs; state]
        c: i.grab1 state;
        if [i.safe[.z.m.axds.opt.isLeft; c; state]; : c];
        
        : $[c in cs; 
            .z.m.axds.opt.left  (enlist `type`value!(`rejected; utl.clean cs); state);
            .z.m.axds.opt.right (c; @[state;`pos`consumed;+;1])];
        
        } cs
    }

// @fileOverview 
// A choice parser, trying each parser it is given in turn. If a parser fails, the state backtracks to this point,
// and the next parser is tried. 
//
// If the parser that failed was committed, backtracking is disabled, and this parser fails.
//
// If any tokens were consumed by the current choice, that choice is committed. If it fails, the entire `oneOf` fails.
// @param ps {function[]} list of functions
// @returns {function}
// @example
// .z.m.axpc.prs[.z.m.axpc.oneOf (.z.m.axpc.char"a"; .z.m.axpc.char"z")] "a"
// //=> "a"
// .z.m.axpc.prs[.z.m.axpc.oneOf (.z.m.axpc.char"a"; .z.m.axpc.char"z")] "z"
// //=> "z"
// .z.m.axpc.prs[.z.m.axpc.oneOf (.z.m.axpc.char"a"; .z.m.axpc.char"z")] "g"
// //=> 'Error parsing at line 1, column 0: Expected "z" but read "g"
.z.m.axpc.oneOf:{[ps]     
    : {[ps; state]
      
        state  : @[state; `backtrack; :; 1b];
        r      : .z.m.axds.opt.left (enlist ""; state);
        i      : 0;
        errors : enlist `type`value!();
        
        while [i.backtrack[r] and .z.m.axds.opt.isLeft[r] and i < count ps;
            r:  ps[i] state;
            if [i.safe[.z.m.axds.opt.isLeft; r; state] and state[`consumed] < i.state[r]`consumed;
                : r];
            if [i.safe[.z.m.axds.opt.isLeft; r; state]; 
                errors ,: i.item r];
            i+:1];

        error : distinct @\:[;`value] (1_errors) where `expected = 1_errors`type;
        
        : $[i.safe[.z.m.axds.opt.isRight; r; state]; 
            r;
            .z.m.axds.opt.left (enlist `type`value!(`expected; error); i.state r)]; 
        
        } i.wrap each ps
    
    } 

// @fileOverview
// An optional parser, whether the parser matches or not, this parser succeeds.
// @param p {function} A parser
// @returns {function}
// @example 
// .z.m.axpc.prs[.z.m.axpc.optional .z.m.axpc.str"hi"] "hi"
// //=> "hi"
// @example 
// .z.m.axpc.prs[.z.m.axpc.optional .z.m.axpc.str"hi"] ""
// //=> ""
.z.m.axpc.optional:{[p]
    : oneOf (i.wrap p; str"");
    }

.z.m.axpc.options:{[opts; input]
    : $[10 = type input;
            `options`input!(opts; input);
        -10 = type input;
            `options`input!(opts; enlist input);
            `options`input!(input[`options],opts; input`input)]
    }
// @fileOverview Run a given parser on a string
// @param parser {function} parser to run
// @param input {string} string to run the parser on
// @return {any}
// @example
// .z.m.axpc.prs[.z.m.axpc.seq (.z.m.axpc.a[{`a`b!1 2}]"a";"b")] "ab"
// //=> "a"
// @example Tracking nesting
// .z.m.axpc.prs[.z.m.axpc.seq (.z.m.axpc.a[{`a`b!1 2}]"a";"b")] .z.m.axpc.options[``nest!11b]"ab"
// //=> "a"
.z.m.axpc.prs:{[parser; input]
    options: ``nest`safe`namespace`consumews`whitespace`onerror!(::;0b;0b;`;1b;regex.whitespace;{'i.error x});
 
    if [99h ~ type input; 
        options: options , input`options;
        input:   input`input];
    
    if [-10h ~ type input; input: enlist input];
    
    state: options , `consumed`backtrack`pos`input!(0; 1b; 0; input);
    r:     i.wrap[parser] state;
    
    : $[i.safe[.z.m.axds.opt.isRight; r; state]; 
        
        [   if [count[input] > .z.m.axds.opt.val[r][1]`pos;
                'i.errorStr(`.axpc_prsError; .Q.s1 i.state[r][`input] i.state[r]`pos)];
            first .z.m.axds.opt.val r]; 
        
        options[`onerror] .z.m.axds.opt.val r];
    }


.z.m.axpc.recur:{[f]
    : {[f; state]
        : f[recur f] state;
        } f
    }

.z.m.axpc.roll1:{ {[f;x;y] $[99 = type y; x y; 1 = count y; x first y; f x each y] } x }
// @fileOverview A parser of two parsers. Results of the first parser are accumulated, and seprated by the second parser.
// @param p {function} parser to output
// @param sep {function} parser to skip
// @return {function}
// @example
// .z.m.axpc.prs[.z.m.axpc.sepBy[.z.m.axpc.ws .z.m.axpc.integer; .z.m.axpc.char","]] "1, 2, 3, 4, 5"
// //=> 1 2 3 4 5
.z.m.axpc.sepBy:{[p; sep]   
    p:   i.wrap p; 
    sep: i.wrap sep;

    if [not any 0 100 104 105h ~\: type p;
        'i.errorStr`.axpc_sepbyTypeError];
    if [not any 0 100 104 105h ~\: type sep;
        'i.errorStr`.axpc_sepbyTypeError];
    : {[p; sep; state]        
        r: p state;
        if [i.safe[.z.m.axds.opt.isLeft; r; state]; 
            : r];
        
        results: enlist[::] , i.item r;
        
        while [i.safe[.z.m.axds.opt.isRight; r; state]; 
            state: i.state r;
            r: sep state;
            if [i.safe[.z.m.axds.opt.isRight; r; state]; 
                state : i.state r;
                r: p state;
                if [i.safe[.z.m.axds.opt.isRight; r; state]; 
                    results,: i.item r]]];
        
        : .z.m.axds.opt.right (1_results; state)
        
        }[ p; sep]
    
    }

// @fileOverview Sequence a list of parsers. The sequence fails if any one parser fails.
// @param ps {function[]} list of parsers to sequence
// @return {function}
// @example
//      .z.m.axpc.prs[.z.m.axpc.seq (.z.m.axpc.char"h"; .z.m.axpc.char"i")] "hi"
//      //=> "hi"
//      .z.m.axpc.prs[.z.m.axpc.seq (.z.m.axpc.char"h"; .z.m.axpc.char"i")] "zz"
//      //=> 'Error parsing at line 1, column 0: Expected "h" but read "z"
//      .z.m.axpc.prs[.z.m.axpc.seq (.z.m.axpc.char"h"; .z.m.axpc.char"i")] "hz"
//      //=> 'Error parsing at line 1, column 1: Expected "i" but read "z"
.z.m.axpc.seq:{[ps]
    : {[ps; state]        
        r: .z.m.axds.opt.right ((); state);
        i: 0;
        results: ();
        
        while [i.safe[.z.m.axds.opt.isRight; r; state] and i < count ps;
            state: i.state r;
            r:  ps[i] state;
            if [.z.m.axds.opt.isRight r; 
                results ,: enlist r];
            i+:1];
        
        : $[i.safe[.z.m.axds.opt.isRight; r; state]; 
            .z.m.axds.opt.right (i.itemsFromList[state] results; i.state r); 
            r]; 
        
        } i.wrap each ps
    }
// @fileOverview 
// Repeatedly skip the given characters. These characters do not count toward the consumed tokens count.
// This means that even if tokens were matched, if the next parser fails, it is as if skipmany has not run at all (see .z.m.axpc.oneOf).
// @param c {char|string} Character(s) to skip
// @returns {function}
// @example
//      .z.m.axpc.prs[.z.m.axpc.skipmany " \r\n\t"] "     \t\t\n   \n "
//      //=> ()
.z.m.axpc.skipmany:{[c]
    if [not any 10 -10h ~\: type c;
        'i.errorStr`.axpc_skipmanyTypeError];
    if [-10h ~ type c;
        c:enlist c];
    
    : {[c;state]
        
        while [1b;
            r: i.grab1 state;
            if [i.safe[.z.m.axds.opt.isLeft; r; state];  : .z.m.axds.opt.right ( (); state )];
            if [not r in c;                        : .z.m.axds.opt.right ( (); state )];
            state[`pos]+:1];        
        
        } c
    
    }

.z.m.axpc.st:{[f;p]
    : {[f;p;state]
        r: p state;
        : $[i.safe[.z.m.axds.opt.isLeft; r; state]; 
            r; 
            @[{[s;r;f] .z.m.axds.opt.right (f[.z.m.axds.opt.val[r]0;s;.z.m.axds.opt.val[r]1]; .z.m.axds.opt.val[r]1) }[state;r]; 
                f;
                {[r;x] .z.m.axds.opt.left  (enlist `type`value!(`apply;x); .z.m.axds.opt.val[r]1) } r]]
        }[f;i.wrap p]
    }

// @fileOverview A parser for matching a string of characters
// @param s {string} The expected string
// @return {function}
// @example
// .z.m.axpc.prs[.z.m.axpc.str"hi there"] "hi there"
// //=> "hi there"
// @example
// .z.m.axpc.prs[.z.m.axpc.str"h"] "h"
// //=> "h"
.z.m.axpc.str:{[s]
    : lexeme i.str[{y;1b};0b] s
    }   
// @fileOverview A parser for a string of characters, wherein the result is converted to a symbol
// @param s {string} The expected string
// @returns {function}
// @example
// .z.m.axpc.prs[.z.m.axpc.symbol"asymbol"] "asymbol"
// //=> `asymbol
.z.m.axpc.symbol:{[s]: a[`$] str s}

// @fileOverview Helper to create a ast node from parser result
// @param typ {symbol} name of the node or rule
// @param labels {symbol[] | null} names of the labels in the resulting node
// @returns {table} resulting node as a table to avoid mismatch errors
// @example
//
//     .z.m.axpc.prs[ .z.m.axpc.t[`name; `labela`labelb] .z.m.axpc.seq("a";"b") ] "ab"
//     //=> type labela labelb
//     //=> ------------------
//     //=> name a      b     
// 
//     .z.m.axpc.prs[ .z.m.axpc.t[`name; ::] "h"] "h"
//     //=> type val
//     //=> --------
//     //=> name h  
// 
.z.m.axpc.t:{[typ; labels]
    a { $[0 = count z; (); enlist (`type,$[(::)~y;`val;y])! x,$[(1<>count z)&(::)~y;enlist z;z]] }[typ; labels]
    }

.z.m.axpc.then:{[p; p2]
    : .z.m.axpc.seq (p; p2)
    }

// This is to save writing .z.m.axpc.a[{: enlist (`text; x)}] or something similar through out the grammar
// @param tokenType {Symbol}
// @returns {Function} A combinator that converts the input into a pair like (`text; " found in file ")
// @see axpc.makeToken
.z.m.axpc.tok:{[tokenType]
    : makeToken tokenType
    }

// @fileOverview Transform an ast by walking its nodes. Default is to evaluate the `` `val ``.
// @param m {dict} Mapping from node types to function taking a tranform step and the node 
// @param n {any} Current node
// @returns {any} Result of the transform action
//
// @example
//     .z.m.axpc.transform[(!) . flip (
//         (`literal;  {x y`val});
//         (`term;     {x y`val})
//         )] ast
.z.m.axpc.transform:{[m;n]
    transformStateful[{ {[f;x;y;z] f[x y;z] }x } each m; ::; n]
    };   
// @fileOverview Transform an ast by walking its nodes. Default is to evaluate the `` `val ``.
// @param m {dict} Mapping from node types to function taking a tranform step and the node 
// @param s {any} State
// @param n {any} Current node
// @returns {any} Result of the transform action
//
// @example
//     .z.m.axpc.transform[(!) . flip (
//         (`literal;  {x y`val});
//         (`term;     {x y`val})
//         )] ast
.z.m.axpc.transformStateful:{[m;s;n]
    $[(::) ~ n;                            n;
     (98 = type n) & `table__ in key m;    m[`table__][.z.s m; s] n; 
     98 = type n;                          .z.s[m; s] each n;
     not type[n] in 0 99h;                 n;
     0 = type n;                           .z.s[m;s] each n;
     n[`type] in key m;                    .[m n`type;(.z.s m; s; n`val);{[n;x]'string[n`type],": ",x}n];
     `default__ in key m;                  m[`default__][.z.s m; s] n`val;
     `type`val ~ key n;                    .z.s[m; s] n`val;
     `default_multi__ in key m;            m[`default_multi__][.z.s m; s] n;
                                           (1_key n)!.z.s[m; s] each value `type _ n] 
    }; 
// @fileOverview
// If a parser fails, replace the failing state with the state before the parser was run.
//
// This is useful paired with .z.m.axpc.oneOf to avoid failing if tokens were consumed.
// @param p {function} parser
// @returns {function}
//
// @example Without .z.m.axpc.try
//     .z.m.axpc.prs[.z.m.axpc.oneOf (
//         .z.m.axpc.then[.z.m.axpc.char"a"]
//                  .z.m.axpc.char"a"; 
//         .z.m.axpc.then[.z.m.axpc.char"a"]
//                  .z.m.axpc.char"b")] "ab"
//     //=> 'Error parsing at line 1, column 1: Expected "a" but read "b"
//
// @example With .z.m.axpc.try
//     .z.m.axpc.prs[.z.m.axpc.oneOf (
//         .z.m.axpc.try .z.m.axpc.then[.z.m.axpc.char"a"]
//                          .z.m.axpc.char"a"; 
//         .z.m.axpc.then[.z.m.axpc.char"a"]
//                  .z.m.axpc.char"b")] "ab"
//     //=> "ab"
.z.m.axpc.try:{[p]
    : {[p;state]        
        r : p state;
        if [i.safe[.z.m.axds.opt.isLeft; r; state]; 
            r[`value;1]: state];
        : r;        
        } i.wrap p 
    
    }

// @fileOverview Read values of parser 1 until parser 2 succeeds.
// @return {dict}
.z.m.axpc.whileNot:{[p;p2]
    : {[p; p2; state]
        results : enlist[::];

        r2 : p2 state;
        if [i.safe[.z.m.axds.opt.isRight; r2; state]; 
            : .z.m.axds.opt.right ((); i.state r2)];
        
        r : p i.state r2;
        if [i.safe[.z.m.axds.opt.isRight; r; i.state r2]; 
            results ,: i.item r];
        
        while [i.safe[.z.m.axds.opt.isRight; r; i.state r] and i.safe[.z.m.axds.opt.isLeft; r2; i.state r];
            r2 : p2 i.state r;
            if [i.safe[.z.m.axds.opt.isRight; r2; i.state r]; 
                : .z.m.axds.opt.right (1_results; i.state r)];

            r : p i.state r2;
            if [i.safe[.z.m.axds.opt.isRight; r; i.state r2]; 
                results ,: i.item r]];
            
        : r;
        
        }[i.wrap p;i.wrap p2]
    }

.z.m.axpc.whitespace:{[state]
    r: state[`whitespace] state; 
    $[i.safe[.z.m.axds.opt.isLeft; r; state];
        r;
        .z.m.axds.opt.right (.z.m.axds.opt.val[r]0; @[i.state r;`consumed;:;state`consumed])]
    }
// Consume whitespace without adding to consumed token count
// @param p {function|null} A function, or generic null
// @returns {function}
.z.m.axpc.ws:{[p] 
    : $[p ~ (::); 
        ignore whitespace;
        seq (ignore whitespace; p)];
    }
.z.m.axpc.messages:(!) . flip (      
            (`.axpc_manyTypeError; "type - .z.m.axpc.many should be given a single parser");
            (`.axpc_many1TypeError; "type - .z.m.axpc.many1 should be given a single parser");
            (`.axpc_sepbyTypeError; "type - .z.m.axpc.sepBy should be given two parsers");
            (`.axpc_skipmanyTypeError; "type - .z.m.axpc.skipmany should be given a character or string");
            (`.axpc_prsError; "Expected end of input, but found {error}");            
            (`.axpc_expected; "expected {typ, select, 1 {one of} other {}} {choice}");  
            (`.axpc_lineCol; "line {line}, column {column}");
            (`.axpc_errorPre; "Error parsing at {linecol}: ");
            (`.axpc_oneOfError; "one of \"{choices}\"");
            (`.axpc_unexpectedEnd; "unexpected end of input");
            (`.axpc_exhaustedInput; "exhausted input");
            (`.axpc_applyError; "application error: {msg}");
            (`.axpc_safeError; "safe mode: {msg}");
            (`.axpc_rejected; "read character from rejected set \"{set}\"")
        )
.z.m.axpc.i.globals:.z.m.axpc.i.whitespace : " \r\n\t";

.z.m.axpc.EOF : `PC_EOF;  

.z.m.axpc.pwhitespace : many anyOf i.whitespace;

.z.m.axpc.regex.whitespace : many anyOf" \r\n\t";
.z.m.axpc.float      : lexeme seq(oneOf(a[,:]str"0";seq(oneOf (str"-"; str"");anyOf 1_.Q.n;many anyOf .Q.n));str".";many anyOf .Q.n);
.z.m.axpc.integer    : lexeme oneOf(a[,:]str"0";seq (oneOf (str"-"; str"");anyOf 1_.Q.n;many anyOf .Q.n));
.z.m.axpc.identifier : lexeme seq(anyOf .Q.a,.Q.A; many anyOf .Q.an);
.z.m.axpc.upperAlpha : oneOf .Q.A;
.z.m.axpc.lowerAlpha : oneOf .Q.a;
.z.m.axpc.alpha      : anyOf .Q.a,.Q.A;
.z.m.axpc.digit      : anyOf .Q.n;

.z.m.axpc.vshort : a["H"$] integer; 
.z.m.axpc.vint   : a["I"$] integer;
.z.m.axpc.vlong  : a["J"$] integer; 
.z.m.axpc.vreal  : a["E"$] float;
.z.m.axpc.vfloat : a["F"$] float;





system "d .z.m";

system "d .z.m.axlocalize";
.z.m.axlocalize.current.lang:`en
system "d .z.m";

system "d .z.m.axlocalize";
// @fileOverview This takes an ICU message and returns a function that, when given a dictionary of arguments,
// writes the message, evaluating placeholders based on the arguments passed in.
// @param language {Symbol} A language code
// @param translationKey {Symbol} A symbol to identify this localization
// @param text {String} An ICU message 
// @returns {Function} A function to print the message
.z.m.axlocalize.icu.asFunc:{[language; translationKey; text]
    
    if [.z.m.axq.isChar text;
        text: string text];
    
    : $[not "{" in text;
        
        {[msg; args]
            : msg;
            }[ssr[text;"''";"'"]];
        
        [   errorHandler: {[language; translationKey; errorMsg]
                ' "Error parsing " ,  string[language] , " message " , string[translationKey] , ": " , errorMsg
                }[language; translationKey];
            
            tree: @['[icu.i.parse[language]; icu.i.tokenize]; text; errorHandler];

            icu.i.write[ ; "#"; tree]]];
    }

// @fileOverview  It would be slow to process the token 'list' each time the message is evaluated,
// so this creates a message format that can be evaluated quickly
// @param lang {Symbol} A language code
// @param tree {(*)} A token 'list' (a tree), produced by icu.i.tokenize
// @returns {Dictionary[]} The ICU message in a format that can be quickly processed by the i.write funciton
.z.m.axlocalize.icu.i.parse:{[lang; tree]
    
    : $[
        `text ~ first tree;
            `type`val!(`text; tree 1);
        
        `apostrophe ~ first tree;
            `type`val!(`escaped; "'");

        `escapedRange ~ first tree;
            `type`val!(`escapedRange; tree 1);
        
        `escapedChar ~ first tree;
            `type`val!(`escapedChar; tree 1);
        
        `varName ~ first first tree;
            $[  // For placeholders that just contain a variable name
                1 ~ count tree;
                    `type`val!(`simple; `$tree[0;1]);
            
                2 ~ count tree;
                    `type`val!`$tree[1 0; 1];
                
                tree[1;1] in ("plural"; "select"; "selectordinal"); /dnl
                    icu.i.parseCases[lang; tree];
            
                3 ~ count tree;
                    `type`val`style!`$tree[1 0 2; 1];
            
                    ];

            icu.i.parse[lang] each tree];
    }

// @fileOverview plural, select and selectordinal can use the same logic for handling cases
// @param lang {Symbol} A language code
// @param tree {(*)} The parse tree
// @returns {dictionary}
.z.m.axlocalize.icu.i.parseCases:{[lang; tree]
    
    cases: tree[where tree[;0] = `case; 1];
    
    cases[;1]: icu.i.parse[lang] each cases[;1];
    
    cases[;0]: icu.i.parseCondition each cases[;0];
            
    cases: cases[;0] ! cases[;1];
    offset: $[  `offset ~ first tree 2;
                .z.m.axq.parseLong tree[2;1];
                0];
    
    caseType: `$tree[1;1];
    
    if [caseType in `plural`selectordinal;
        icu.i.validateCases[lang; key cases; caseType]];
    
    : (!) . flip (
        (`val; `$tree[0;1]);
        (`type; caseType);
        (`offset; offset);
        (`cases; cases)
        );
    }

// @fileOverview Turn a token into something that can be used as a key in a dictionary easily
// @param x {(*)} A token, as a ({Symbol} token type; {String} value) pair
// @returns {Long|Symbol}
.z.m.axlocalize.icu.i.parseCondition:{[x]
    : $[`number ~ first x;
        .z.m.axq.parseLong last x;
        `$last x];
    }
// @fileOverview Used to turn symbols and numbers to strings
// @param x {Any}
// @returns {String}
.z.m.axlocalize.icu.i.toString:{[x]
    
    inputType: .z.m.axq.typeOf x;
    
    : $[inputType ~ `chars;
            x;
        inputType ~ `char;
            enlist x;
        inputType ~ `symbol;
            string x;
        (inputType ~ `symbols) and 1 ~ count x;
            string first x;
        (inputType ~ `general) and (1 ~ count x) and (.z.m.axq.isString first x);
            first x;
        .Q.s1 x];
    }
// @fileOverview Tokenizes text as an ICU message.
// This actually does a bit more than tokenizing, as it puts tokens into a tree structure
// @param text {String}
// @returns {(*)}
.z.m.axlocalize.icu.i.tokenize:{[text]
    : .z.m.axpc.prs[icu.message;  text];
    }


// @fileOverview Throws an error if a case is missing, or not required for the language
// @param lang {symbol} The language code
// @param cases {symbol[]} The cases present in the placeholder
// @param caseType {symbol} The type of the placeholder
// @returns {null}
.z.m.axlocalize.icu.i.validateCases:{[lang; cases; caseType]
    
    cases @: where -11h = type each cases;
    
    cases: .z.m.axq.asSymbol cases;
    
    expected: icu.i.langData[lang] $[caseType ~ `plural; `plurals; `ordinals];
    
    invalid: cases except expected;
    if [count invalid;
        ' "Invalid case for " , string[lang] , ": " , ", " sv string invalid];
        
    missing: expected except cases;
    if [count missing;
        ' "Missing case required for " , string[lang] , ": " , ", " sv string missing];
    }
// @fileOverview Create a string from a message dictionary
// @param args {Dictionary}
// @param outerVal {*} The value of the wrapping placeholder, used to replace #
// @param msg {(*)}
// @returns {string}
.z.m.axlocalize.icu.i.write:{[args; outerVal; msg]
    
    : $[msg ~ ();
            "";
        
        .z.m.axq.isDictionary msg;
            icu.i.writeDictionary[args; outerVal; msg];
        
            raze .z.s[args; outerVal] each msg];
    }
// @fileOverview Create a string from a message dictionary
// @param args {Dictionary}
// @param outerVal {*} The value of the wrapping placeholder, used to replace #
// @param msg {(*)}
// @returns {string}
.z.m.axlocalize.icu.i.writeDictionary:{[args; outerVal; msg]
    
    if [`escapedChar ~ msg `type;
        : 1 _ msg `val];

    if [`escapedRange ~ msg `type;
        : -1 _ 1 _ msg `val];

    if [`text ~ msg `type;
        : $["#" in msg `val;
            ssr[msg `val; "#"; icu.i.toString outerVal];
            msg `val]];

    val: $[ .z.m.axq.isDictionary args;
            [   // Check that the placeholder's variable is in arg
                if [not msg[`val] in key args;
                    ' "Localization error: Placeholder key not found in input"];
                args msg `val];
            args];

    : $[
        `simple ~ msg `type;
            icu.i.toString val;

        `select ~ msg `type;
            $[  val in key msg `cases;
                icu.i.write[args; val; msg[`cases; val]];
                icu.i.write[args; val; msg[`cases; `other]]];

        msg[`type] in `plural`selectordinal;
            $[  any val ~/: key msg `cases;
            
                icu.i.write[args; val; msg[`cases; val]];

                [   val -: msg `offset;
                
                    keyword: $[`plural ~ msg `type;
                        icu.i.langData[.z.m.axlocalize.current.lang; `pluralKeyword] val;
                        icu.i.langData[.z.m.axlocalize.current.lang; `ordinalKeyword] val]; 
                    
                    icu.i.write[args; val; msg[`cases] keyword]]];
        
        ];
    }

.z.m.axlocalize.icu.i.langData:(!) . flip (
    (`en;   (!) . flip (
        (`plurals; `one`other);
        (`pluralKeyword; {
            : $[x in 1 -1;
                `one;
                `other];
            });
        (`ordinals; `one`two`few`other);
        (`ordinalKeyword;  {[x]
            x: abs x;
            : $[(1 ~ x mod 10) and not (11 ~ x mod 100);
                    `one;
                (2 ~ x mod 10) and not (12 ~ x mod 100);
                    `two;
                (3 ~ x mod 10) and not (13 ~ x mod 100);
                    `few;
                    `other];
            })));

    (`de;   (!) . flip (
        (`plurals; `one`other);
        (`pluralKeyword; {
            : $[x in 1 -1;
                `one;
                `other];
            });
        (`ordinals; `other);
        (`ordinalKeyword; {`other})));

    (`fr;   (!) . flip (
        (`plurals; `one`other);
        (`pluralKeyword; {
            : $[x within -1 1;
                `one;
                `other];
            });
        (`ordinals; `zero`one`other);
        (`ordinalKeyword; {
            : $[x ~ 0;
                    `zero;
                abs[x] ~ 1;
                    `one;
                    `other];
            })));

    (`ja;   (!) . flip (
        (`plurals; `other);
        (`pluralKeyword; {`other});
        (`ordinals; `other);
        (`ordinalKeyword; {`other}))))

.z.m.axlocalize.icu.i.grammar:icu.placeholder: {[state]
    
    : (.z.m.axpc.a[{enlist x}] .z.m.axpc.seq ( 
            icu.openBrace;
            .z.m.axpc.ws[];
            icu.varName;
            .z.m.axpc.ws[];
            .z.m.axpc.optional .z.m.axpc.seq   (.z.m.axpc.ws[];
                                    .z.m.axpc.ignore .z.m.axpc.ch ",";
                                    .z.m.axpc.ws[];
                                    icu.placeholderType;
                                    .z.m.axpc.ws[]);
            icu.closeBrace)) 
        state;
    };
  


icu.message : .z.m.axpc.many .z.m.axpc.oneOf   (.z.m.axpc.makeToken[`apostrophe] .z.m.axpc.str "''";
                                     .z.m.axpc.oneOf(  // If a range is enclosed in apostrophes
                                                .z.m.axpc.makeToken[`escapedRange] .z.m.axpc.try .z.m.axpc.seq (  .z.m.axpc.oneOf  (.z.m.axpc.try .z.m.axpc.then[.z.m.axpc.ch"'";.z.m.axpc.ch"#"];
                                                                                                            .z.m.axpc.try .z.m.axpc.then[.z.m.axpc.ch"'";.z.m.axpc.ch"{"]);
                                                                                                .z.m.axpc.many .z.m.axpc.oneOf (.z.m.axpc.str "''";
                                                                                                                    .z.m.axpc.notAny "'");
                                                                                                .z.m.axpc.ch "'");
                                                .z.m.axpc.makeToken[`escapedChar] .z.m.axpc.oneOf  (.z.m.axpc.try .z.m.axpc.then[.z.m.axpc.ch"'"; .z.m.axpc.ch"#"];
                                                                                        .z.m.axpc.try .z.m.axpc.then[.z.m.axpc.ch"'"; .z.m.axpc.ch"{"]));
                                    .z.m.axpc.makeToken[`text] .z.m.axpc.ch "'";
                                    .z.m.axpc.makeToken[`text] .z.m.axpc.many1 .z.m.axpc.notAny "{}'";
                                    icu.placeholder);




icu.wrappedMessage: {[]
    : .z.m.axpc.a[{enlist x}] .z.m.axpc.seq(icu.openBrace;
                                icu.message;
                                icu.closeBrace; .z.m.axpc.ws[]); 
    };
 
icu.openBrace: .z.m.axpc.ignore .z.m.axpc.ch "{";
icu.closeBrace: .z.m.axpc.ignore .z.m.axpc.ch "}";

icu.integer: .z.m.axpc.many1 .z.m.axpc.anyOf .Q.n;

icu.varName: .z.m.axpc.makeToken[`varName] .z.m.axpc.many1 .z.m.axpc.anyOf .Q.an;

icu.genericStyle: .z.m.axpc.makeToken[`style] .z.m.axpc.oneOf .z.m.axpc.str each ("narrow"; "short"; "medium"; "long"; "full"; "integer"; "currency"; "percent"); /dnl

icu.genericType: .z.m.axpc.makeToken[`type] .z.m.axpc.oneOf .z.m.axpc.str each ("number"; "date"; "time"; "ordinal"; "duration"; "spellout"); /dnl

icu.amount:  .z.m.axpc.makeToken[`amount] .z.m.axpc.oneOf .z.m.axpc.str each ("zero"; "one"; "two"; "few"; "many"; "other"); /dnl

icu.offset: .z.m.axpc.try .z.m.axpc.seq  (.z.m.axpc.ws[];
                                    .z.m.axpc.ignore .z.m.axpc.str "offset"; /dnl
                                    .z.m.axpc.ws[];
                                    .z.m.axpc.ignore .z.m.axpc.ch ":";
                                    .z.m.axpc.ws[];
                                    .z.m.axpc.makeToken[`offset] icu.integer);

icu.pluralEnd:  .z.m.axpc.seq(.z.m.axpc.ws[];
                        .z.m.axpc.many1 .z.m.axpc.makeToken[`case] .z.m.axpc.seq (
                            .z.m.axpc.ws[];
                            .z.m.axpc.oneOf  (icu.amount;
                                        .z.m.axpc.seq(.z.m.axpc.ignore .z.m.axpc.ch "="; // no whitespace is allowed between the = and the number
                                                .z.m.axpc.makeToken[`number] icu.integer));
                            .z.m.axpc.ws[];
                            icu.wrappedMessage[]));
 
icu.genericStyle: .z.m.axpc.seq  (.z.m.axpc.ws[];
                            .z.m.axpc.ignore .z.m.axpc.ch ",";
                            .z.m.axpc.ws[];
                            icu.genericStyle);

icu.selectEnd: .z.m.axpc.seq (.z.m.axpc.ws[];
                        .z.m.axpc.ignore .z.m.axpc.ch ",";
                        .z.m.axpc.many1 .z.m.axpc.makeToken[`case] .z.m.axpc.seq (
                            .z.m.axpc.ws[];
                            icu.varName;
                            .z.m.axpc.ws[];
                            icu.wrappedMessage[]));
 
icu.placeholderType: .z.m.axpc.oneOf (.z.m.axpc.seq(icu.genericType;
                                        .z.m.axpc.optional icu.genericStyle);
    
                                .z.m.axpc.seq(.z.m.axpc.makeToken[`type] .z.m.axpc.oneOf (.z.m.axpc.str "plural"; /dnl
                                                                        .z.m.axpc.str "selectordinal"); /dnl
                                        .z.m.axpc.ws[];
                                        .z.m.axpc.ignore .z.m.axpc.ch ",";
                                        .z.m.axpc.optional icu.offset;
                                        icu.pluralEnd);
        
                                .z.m.axpc.seq(.z.m.axpc.makeToken[`type] .z.m.axpc.str "select"; /dnl
                                        icu.selectEnd)); 
system "d .z.m";

system "d .z.m.axlocalize";
// @fileOverview This is the function components call to add their translations to the translations table
// @param newTranslations {Dictionary}
// @returns {Null}
.z.m.axlocalize.addTranslations:{[newTranslations]
     
    languages: key newTranslations;
    
    translationFuncs: languages!{[newTranslations; lang]
        
        : (key newTranslations lang)!.z.m.axlocalize.icu.asFunc[lang] ./: flip (key newTranslations lang; value newTranslations lang);
        }[newTranslations] each languages;
    
    .z.m.axlocalize.translations[key translationFuncs] ,: value translationFuncs;
    }

// @fileOverview This modifies a string such that it will be obvious if a string hasn't been modified,
// but the string should still be readable.
// This is useful for finding text that hasn't been translated
// Text ends up looking like this: "T̶̳h̶̳i̶̳s̶̳ ̶̳i̶̳s̶̳ ̶̳a̶̳ ̶̳t̶̳e̶̳s̶̳t̶̳"
// @param text {String}
// @returns {String}
.z.m.axlocalize.pseudotranslate:{[text]
    : raze text ,\: `char$0xCCB3CCB6;
    }
// @fileOverview Get the localized message for a given key and arguments
// @param input {Symbol|(*)}
//  If this is a symbol, it is the translation key.
//  If it is a pair, it is the translation key, and the translation's arguments
// @returns {String} The localized string
.z.m.axlocalize.t:{[input]
    
    keyName: $[ .z.m.axq.isSymbol input;
                input;
                first input];
    
    args: $[.z.m.axq.isSymbol input;
            ();
            last input];
    
    : $[ // If the language is missing, throw a helpful error.
        not .z.m.axlocalize.current.lang in key .z.m.axlocalize.translations;
            "`" , string[.z.m.axlocalize.current.lang] , " is not in .z.m.axlocalize.translations"; /dnl
        
        keyName in  key .z.m.axlocalize.translations .z.m.axlocalize.current.lang;
            .z.m.axlocalize.translations[.z.m.axlocalize.current.lang; keyName] args;
        
        keyName in key .z.m.axlocalize.translations `en;
            .z.m.axlocalize.translations[`en; keyName] args;
        
            "Missing translation: " , string keyName]; /dnl
    }

.z.m.axlocalize.emptyTranslations:(enlist `)!(enlist ())
// @fileOverview Define the initial localize state
// @returns {Null}
.z.m.axlocalize.onLoad:{[]
    if [not `translations in key `.axlocalize;
        .z.m.axlocalize.translations: .z.m.axlocalize.emptyTranslations];

    }

.z.m.axlocalize.onLoad[];
system "d .z.m";

system "d .z.m.gg";
// @fileOverview 
// Create a new etable element from a geometry and 
// drawing settings.
// @param geometry {symbol} see etable.i.geometries 
// @param settings {dict} settings for the geometry (keys vary based on geom)
//
// @returns {dict} etable element
.z.m.gg.etable.el:{[geometry; settings]
    if [0 = count settings;
        : ()];

    : enlist `geometry`settings!(geometry; settings);
    }

// @fileOverview 
// Return all elements of the etable of the given
// geometry type
// @param typ {symbol} etable geometry type 
// @param etab {table} etable
// @returns {table} etable
.z.m.gg.etable.every:{[typ; etab]
    : $[() ~ etab;
            ();
        98h ~ type etab;
            select from etab where geometry = typ;
            $[typ ~ etab`geometry; etab; etable.EMPTY]]
    }
 
// @fileOverview 
// Extract the geometry component from an etable element
// @param el {dict} etable element
// @returns {symbol} geometry see etable.i.geometries
.z.m.gg.etable.geom:{[el]
    : el`geometry
    }

.z.m.gg.etable.qualify:{[e]
    t: {$[0h ~ type x; raze x; x]} etable.settings e;
    
    if [(not () ~ t) & not 98h ~ type t;
        t: (etable.i.keys etable.geom first e) #/: ((key[etable.defaults] inter etable.i.keys etable.geom first e)#etable.defaults) ,/: t];

    if [98h ~ type t;
        if [`colour in cols t;
            if [4h ~ type first t`colour;
                t[`colour]: 0x0 sv' t`colour]];
        if [`strokecolour in cols t;
            t[`strokecolour]: $[4h ~ type first t`strokecolour; 0x0 sv' t`strokecolour;
                4h ~ type first first t`strokecolour; 0x0 sv/:/: t`strokecolour;
                t`strokecolour]]];
    
    : t;
    }

// @fileOverview 
// Replace all geometries of one kind with another
// @param old {symbol} 
// @param new {symbol} 
// @param etab {table} table of etable elements
//
// @returns {table} updated table of elements
.z.m.gg.etable.replace:{[old; new; etab]
    : $[0 = count etab;
        etab;
        update geometry:new from etab where geometry = old];
    }

// @fileOverview 
// Extract the settings from an etable element
// @param el {dict} etable element
// 
// @returns {dict} settings
.z.m.gg.etable.settings:{[el]
    if [0 = count el; : ()];
    : el`settings
    }

.z.m.gg.etable.i.geometries:etable.g.POINT:`point;
etable.g.TRIANGLE:`triangle;
etable.g.SQUARE:`square;
etable.g.LINE:`line;
etable.g.ATEXTL:`atextL;
etable.g.ATEXTM:`atextM;
etable.g.ATEXTR:`atextR;
etable.g.RECT:`rect;
etable.g.RECT4:`rect4;
etable.g.PATH:`path;
etable.g.POINT3D:`point3D;
etable.g.LINE3D:`line3D;
etable.g.ATEXTL3D:`atextL3D;
etable.g.ATEXTM3D:`atextM3D;
etable.g.ATEXTR3D:`atextR3D;
etable.g.PATH3D:`path3D;
etable.g.POLARPATH:`polarpath;
.z.m.gg.etable.defaults:(!) . flip (
    (`strokewidth; 0N);
    (`strokecolour; 0Ni);
    (`angle; 0);
    (`bold; 0b);
    (`italic; 0b);
    (`offsetx; 0);
    (`offsety; 0);
    (`dashed; 0b);
    (`maxChars; 100);
    (`fontfamily; "sans-serif")
    )
.z.m.gg.etable.EMPTY:()
.z.m.gg.etable.onLoad:{[]
    etable.i.keys: (!) . flip (
        (etable.g.POINT;     `x`y`colour`size`angle`strokewidth`strokecolour);
        (etable.g.TRIANGLE;  `x`y`colour`size`angle`angle`strokewidth`strokecolour);
        (etable.g.SQUARE;    `x`y`colour`size`angle`strokewidth`strokecolour);
        (etable.g.LINE;      `x1`y1`x2`y2`colour`size`dashed);
        (etable.g.ATEXTL;    `x`y`text`angle`fontsize`colour`fontfamily`bold`italic`offsetx`offsety`maxChars);
        (etable.g.ATEXTM;    `x`y`text`angle`fontsize`colour`fontfamily`bold`italic`offsetx`offsety`maxChars);
        (etable.g.ATEXTR;    `x`y`text`angle`fontsize`colour`fontfamily`bold`italic`offsetx`offsety`maxChars);
        (etable.g.RECT;      `x`y`w`h`colour`strokewidth`strokecolour);
        (etable.g.RECT4;     `x1`y1`x2`y2`colour`strokewidth`strokecolour);
        (etable.g.PATH;      `xs`ys`close`colour`strokewidth`strokecolour);
        (etable.g.POINT3D;   `x`y`z`colour`size`angle`strokewidth`strokecolour);
        (etable.g.LINE3D;    `x1`y1`z1`x2`y2`z2`colour`size`dashed);
        (etable.g.ATEXTL3D;  `x`y`z`text`angle`fontsize`colour`fontfamily`bold`italic`offsetx`offsety`maxChars);
        (etable.g.ATEXTM3D;  `x`y`z`text`angle`fontsize`colour`fontfamily`bold`italic`offsetx`offsety`maxChars);
        (etable.g.ATEXTR3D;  `x`y`z`text`angle`fontsize`colour`fontfamily`bold`italic`offsetx`offsety`maxChars);
        (etable.g.PATH3D;    `xs`ys`zs`close`colour`strokewidth`strokecolour);
        (etable.g.POLARPATH; `xs`ys`close`colour`strokewidth`strokecolour`samples)
        );
    }

.z.m.gg.etable.onLoad[];
system "d .z.m";

system "d .z.m.gg";
// @fileOverview 
// Reflect an etable about the line y=x
// @param etable {table} talbe of etable element 
.z.m.gg.i.transforms.flipy:{[etable]
    : raze i.transforms.i.flipyElement each etable;
    }

// @fileOverview 
// Reflect a line
// @param element {dict} 
.z.m.gg.i.transforms.i.flipy.line:{[element]
    settings : etable.settings element;
    settings[`x1]: 1 - settings`x1;
    settings[`x2]: 1 - settings`x2;
    : etable.el[etable.g.LINE; settings];
    }

// @fileOverview 
// Reflect a text geometry
// @param g {symbol} which text geometry 
// @param element {dict} 
.z.m.gg.i.transforms.i.flipy.text:{[g; element]
    
    settings     : etable.settings element;
    settings[`x] : 1 - settings`x;

    : etable.el[g; settings];

    }

// @fileOverview 
// Reflect a single element.
// Note - this interrogates every element. Should only
// be used on small graphics (due to increased runtime)
// @param element {dict} 
.z.m.gg.i.transforms.i.flipyElement:{[element]
    g : etable.geom element;
    : $[  etable.g.LINE    ~ g;  i.transforms.i.flipy.line   element;
        etable.g.ATEXTM    ~ g;  i.transforms.i.flipy.text[.z.m.gg.etable.g.ATEXTM] element;
        etable.g.ATEXTR    ~ g;  i.transforms.i.flipy.text[.z.m.gg.etable.g.ATEXTL] element;
        etable.g.ATEXTL    ~ g;  i.transforms.i.flipy.text[.z.m.gg.etable.g.ATEXTR] element;
        etable.g.POINT     ~ g;  i.transforms.i.flipy.point  element;
        etable.g.TRIANGLE  ~ g;  i.transforms.i.flipy.point  element;
        etable.g.SQUARE    ~ g;  i.transforms.i.flipy.point  element;
            enlist element
        ];
    }

// @fileOverview 
// Reflect a line
// @param element {dict} 
.z.m.gg.i.transforms.i.reflect.line:{[element]
    settings : etable.settings element;
    temp : settings`x1;
    settings[`x1]: settings`y1;
    settings[`y1]: temp;
    temp : settings`x2;
    settings[`x2]: settings`y2;
    settings[`y2]: temp;
    : etable.el[etable.g.LINE; settings];
    }

// @fileOverview 
// Reflect a point
// @param element {dict} 
.z.m.gg.i.transforms.i.reflect.point:{[element]
    settings : etable.settings element;
    temp: settings`x;
    settings[`x]: settings`y;
    settings[`y]: temp;
    : etable.el[etable.g.POINT; settings];
    }

// @fileOverview 
// Reflect a rectangle
// @param element {dict} 
.z.m.gg.i.transforms.i.reflect.rect:{[element]
    settings : etable.settings element;
    temp : settings`w;
    settings[`w]: settings`h;
    settings[`h]: temp;
    
    temp : settings`x;
    settings[`x] : settings[`y] - settings`w;
    settings[`y] : temp + settings`h;
    
    : etable.el[etable.g.RECT; settings]
    }

// @fileOverview 
// Reflect a text geometry
// @param g {symbol} which text geometry 
// @param element {dict} 
.z.m.gg.i.transforms.i.reflect.text:{[g; element]
    
    settings     : etable.settings element;
    temp         : settings`x;
    settings[`x] : settings`y;
    settings[`y] : temp;

    : etable.el[g; settings];

    }

// @fileOverview 
// Reflect a single element.
// Note - this interrogates every element. Should only
// be used on small graphics (due to increased runtime)
// @param element {dict} 
.z.m.gg.i.transforms.i.reflectElement:{[element]
    g : etable.geom element;
    
    : $[  etable.g.LINE    ~ g;  i.transforms.i.reflect.line   element;
        etable.g.RECT      ~ g;  i.transforms.i.reflect.rect   element;
        etable.g.POINT     ~ g;  i.transforms.i.reflect.point  element;
        etable.g.TRIANGLE  ~ g;  i.transforms.i.reflect.point  element;
        etable.g.SQUARE    ~ g;  i.transforms.i.reflect.point  element;
        etable.g.ATEXTM    ~ g;  i.transforms.i.reflect.text[etable.g.ATEXTM] element;
        etable.g.ATEXTR    ~ g;  i.transforms.i.reflect.text[etable.g.ATEXTR] element;
        etable.g.ATEXTL    ~ g;  i.transforms.i.reflect.text[etable.g.ATEXTL] element;
            enlist element
        ];
    }

// @fileOverview 
// Reflect an etable about the line y=x
// @param etable {table} talbe of etable element 
.z.m.gg.i.transforms.reflect:{[etable]
    : raze i.transforms.i.reflectElement each etable;
    }

system "d .z.m";

system "d .z.m.axdatatype";
// @fileOverview
// Create a new datatype
// @param name {symbol}
// @param ks {symbol[]}
// @param ms {symbol[]}
// @returns {symbol}
.z.m.axdatatype.create:{[name; ks; ms]
    if[0b ~ @[get; name; 0b];
        name set enlist[`]!enlist (::);
        ];
    
    : i.new [name; `symbol$(); ks; ms];
    }

// @fileOverview 
// Extend a datatype with new field
// @example
//
//      .z.m.axdatatype.create[`.my.a; `a`b`c; `a`b];
//      .z.m.axdatatype.extend[`.my.b; `d`e; enlist `e; `.my.a];
//
//      item : .my.b.new 1 2 3 4 5
//      .my.b.is item;
//      .my.a.is item;
//      item : .my.b.with.a[0] .my.b.with.e[0] item;
//
// @param name {symbol} new datatype name
// @param ks {symbol[]} fields 
// @param ms {symbol[]} mutators
// @param oldname {symbol} datatype to inherit from
// @returns {symbol} 
.z.m.axdatatype.extend:{[name; ks; ms; oldname]
    if[0b ~ @[get; name; 0b];
        name set enlist[`]!enlist (::);
        ];
    
    : i.extend [name; ks; ms; oldname];
    }

// @fileOverview
// Extend a datatype from a namespace
// @param name {symbol}
// @param ks {symbol[]}
// @param ms {symbol[]}
// @param oldname {symbol}
// @returns {symbol}
// @see axdatatype.extend
// @deprecated
.z.m.axdatatype.extendFrom:{[name; ks; ms; oldname]
    show "Deprecated invocation of .z.m.axdatatype.extendFrom - Please use .z.m.axdatatype.extend"; 
    : extend[name; ks; ms; oldname];
    }

// @deprecated
// @fileOverview
// Create a new datatype from a namespace
// @param name {symbol}
// @param ks {symbol[]}
// @param ms {symbol[]}
// @returns {symbol}
.z.m.axdatatype.from:{[name; ks; ms]
    show "Deprecated invocation of .z.m.axdatatype.from - Please use .z.m.axdatatype.create";
    : create[name; ks; ms];
    }

// @fileOverview
// Extend a datatype
// @param name {symbol}
// @param ks {symbol[]}
// @param ms {symbol[]}
// @param oldname {symbol}
// @returns {symbol}
.z.m.axdatatype.i.extend:{[name; ks; ms; oldname]
    
    if [any ks in\: value[oldname][`i][`ks];
        '"Extender cannot use any fields of the extended"]; /dnl
    
    ks : value[oldname][`i][`ks] union ks;
    ms : value[oldname][`i][`ms] union ms;
    ps : oldname , value[oldname][`i][`ps];
    
    : i.new [name; ps; ks; ms];
    
    }

// @fileOverview
// Create a new datatype
// @param o {symbol}
// @param ps {symbol[]}
// @param ks {symbol[]}
// @param ms {symbol[]}
// @returns {symbol}
.z.m.axdatatype.i.new:{[o; ps; ks; ms]    
    
    if [not all ms in\: ks; '"Modifier set is not a subset of the fields"]; /dnl
    
    @[o;`i;:;``type`ps`ks`ms!(::;o;ps;ks;ms)];
    
    @[o; `is; :;
        {[name; item] 
            if [.z.m.axq.isKeyedTable item; : 0b];
            if [not 99h ~ type item; : 0b];
            if [not `i_.type in key item; : 0b];
            : name in (item `i_.type) , item`i_.extensions;
            }[o]];
    
    @[o; `check; :;
        {[name; item]
            if [not 99h ~ type item; '"type: expected dictionary"]; /dnl
            if [not `i_.type in key item; '"type: expected ", string name]; /dnl
            : item;
            }[o]];
    
    @[o; `new; :;
        {[ps; name; ks; xs]
            if [count[xs] < count[ks]; '"Not all arguments specified"]; /dnl
            if [count[xs] > count[ks]; '"Too many arguments specified"]; /dnl
            : (`i_.null`i_.type`i_.extensions!(::; name; ps)), ks!xs;
            }[ps; o; ks]];
    
    {[o;x] @[o;x;:; {[x;item] : item x }[x]]; }[o] each ks;
    
    mvs : {[o;x]
        : {[x;val;item]
            item[x]:val;
            : item;
            }[x];
        }[o] each ms;
    
    @[o;`with;:;(ms!mvs),(enlist[`]!enlist(::))];
    : o;
    }
system "d .z.m";

system "d .z.m.axutl";
// Inject deps into module
// deps is a dictionary argName!dep
.z.m.axutl.injeqt.i.injeqt:{[deps; moduleSym; targetSym] /moduleSym: `.wsState; deps:d; targetSym: `
    
    fns: k!ms @ k:key[ms] where value 100h = type each ms: get moduleSym;
    fnNames: key[fns] where m:raze any each key[deps] in/: ( value each  fns)[;1]; 
    uninjeqted: key[fns] where not m;

    uninjeqted: uninjeqted!ms @ uninjeqted;
    symbols: where `symbol = .z.m.axq.typeOf each deps;
    deps[symbols]: enlist each deps[symbols];
    
    injected: {[fns; msym; dep; name] 
        n: last value (;);
        argCount: count value[fns[name]][1]; 
        dPosns: (where argCount = d:key[dep]!  i: value[fns[name]][1] ? key[dep] );
        dPosns: dPosns _d;

        parseTree: argCount # (::);
        parseTree[value dPosns]: dep  @ key dPosns; 
        parseTree[til[argCount] except value dPosns]: n;
        parseTree:  (enlist `$ "." sv string (msym; name)) , parseTree;
        : eval parseTree;
        }[fns; moduleSym; deps;] each fnNames; / name: `b; dep:  deps; msym: moduleSym
    
    if [ targetSym =`;
            : uninjeqted, (fnNames ! injected)
            ];
    
    (`$ "." sv/: (string targetSym,/: fnNames)) set' injected;
    (`$ "." sv/: (string targetSym,/: key[uninjeqted])) set' value uninjeqted;
    
    : uninjeqted, (fnNames ! injected)
    }
.z.m.axutl.injeqt.injeqt:{[deps; moduleSym; targetSym]
    : injeqt.i.injeqt[ deps; moduleSym; targetSym];
    }

system "d .z.m";

system "d .z.m.axds";
// @fileOverview 
// Add a list of children nodes under
// a given node to a tree
// @param gapi {dict} DAG api 
// @param n {dict} the parent node 
// @param c {dict[]} list of child nodes 
// @param g {table} tree specification
// @returns {table} updated specification
.z.m.axds.tree.inject.add.children:{[gapi; n; c; g]
    gapi[`add][`children][n;c;g]
    }

// @fileOverview 
// Add a new root to an existing tree
// @param gapi {dict} DAG api 
// @param n {dict} the new root 
// @param g {table} tree specification
// @returns {table} updated specification
.z.m.axds.tree.inject.add.root:{[gapi; n; g]
    
    : $[gapi[`empty] g;
        
        gapi[`add][`node][n; g];
        
        [
            root : .z.m.axds.tree.inject.root[gapi; g];
            gapi[`add][`edge][n; root; g]]];
    
    }

// @fileOverview 
// Return all ancestor nodes from a given node
// in a tree
// @param gapi {dict} DAG api 
// @param n {dict} a node within the tree 
// @param g {table} tree specification
// @returns {table} all ancestors of the node in the tree
.z.m.axds.tree.inject.ancestors:{[gapi; n; g]    
    gapi[`ancestors][n;g]    
    }

// @fileOverview 
// Return all child nodes from a given node in a tree
// @param gapi {dict} DAG api 
// @param n {dict} a node within the tree 
// @param g {table} tree specification
// @returns {table} all children of the node in the tree
.z.m.axds.tree.inject.children:{[gapi; n; g] 
    gapi[`children] [n; g] 
    }
// @category Tree
//
// @fileOverview
// Clones all elements in a Tree to keep the same
// structure and payload with different node id's
//
// @param gapi {dict} 
// @param g {table<tree>} Tree to clone
//
// @returns {table<tree>} Cloned tree
.z.m.axds.tree.inject.clone:{[gapi; g]
    : gapi[`clone] g
    }
// @category Tree
// 
// @fileOverview 
// Connect multiple trees as children of the given node
// in a new tree
//
// @param gapi {dict} 
// @param r         {dict<tree.node>}   New root 
// @param treelist  {table[]}           List of tree specifications
//
// @returns {table<tree>} Merged tree specification
.z.m.axds.tree.inject.connect:{[gapi; r; treelist]
    
    if[0 ~ count treelist;
        : enlist r];
    
    g: raze treelist;
    
    s: gapi[`sources] g;
    
    r: gapi[`node][`with][`children] [s`id; r];    
    
    : (update parents: (parents,\:r`id) from g where id in s`id),r
    }

// @fileOverview 
// Return all descendants of a given node in a tree
// @param gapi {dict} DAG api 
// @param n {dict} node in the tree 
// @param g {table} tree specification
// returns {table} all descendants of the node
.z.m.axds.tree.inject.descendants:{[gapi;n;g]    
    gapi[`descendants][n;g]    
    }

// @fileOverview 
// Return a node given an id
// @param gapi {dict} DAG api 
// @param id {GUID} 
// @param g {table} tree specification 
// @returns {dict} tree node
.z.m.axds.tree.inject.find:{[gapi; id; g]    
    gapi[`find][id; g]    
    }

// @category Tree
//
// @fileOverview
// Folds over a function using the given directed graph and a list of nodes.
// The function to fold over must accept a single node as its first argument 
// and a tree as its second argument and return a tree
// 
// @param gapi {dict} 
// @param f {function}      Function to fold over
// @param s {table<tree>}    A list of tree nodes
// @param g {table<tree>}    tree to fold over
//
// @returns {table<tree>} The tree with f applied successively with each node
.z.m.axds.tree.inject.fold:{[gapi; f; s; g]
    : gapi[`fold] [f; s; g];
    }
// @fileOverview
// Inserts a directed edge and node between a parent and child in the tree
// NB: If p or c are not in dag then they will be added
//
// @param gapi {dict} DAG api 
// @param p {dict}  Parent node of n
// @param n {dict}  New node
// @param c {dict}  Child node of n
// @param t {table} A tree
//
// @returns {table} Updated tree
.z.m.axds.tree.inject.insert:{[gapi;p;n;c;t]
    : gapi[`insert][p;n;c;t];
    }

// @category Tree
// 
// @fileOverview
// Returns if the input has the correct schema to be a tree
//
// @param gapi {dict} 
// @param t {table<tree>}
// 
// @returns {boolean} If the input is a tree or not
//
// @see i.DAG
.z.m.axds.tree.inject.is:{[gapi; t] 
    : gapi[`is] t
    }

// @fileOverview 
// Modifies the item of a given node in g
// @param gapi {dict} DAG api 
// @param node {dict} a node in the tree 
// @param item {any} new item for the node 
// @param tree {table} tree specification
// @returns {table} updated tree specification
.z.m.axds.tree.inject.modify:{[gapi; node; item; tree]
    gapi[`modify][node; item; tree]
    }

// @fileOverview 
// Create a new tree
// @param gapi {dict} DAG api
// @returns {table} a new tree
.z.m.axds.tree.inject.new:{[gapi]
    gapi[`new][]
    }

// @fileOverview 
// Returns all of the children of a node by id
// @param gapi {dict} DAG api 
// @param node {dict} tree node
// @returns {GUID[]} list of children ids
.z.m.axds.tree.inject.node.children:{[gapi; node]
    gapi[`node][`children] node
    }

// @fileOverview 
// Returns this node's id
// @param gapi {dict} DAG api 
// @param node {dict} tree node
// @returns {GUID} Id of this node
.z.m.axds.tree.inject.node.id:{[gapi; node]
    gapi[`node][`id] node
    }

// @fileOverview 
// Extract the content of a node in the tree
// @param gapi {dict} DAG api 
// @param node {dict} tree node
// @returns {any} the content stored in the node
.z.m.axds.tree.inject.node.item:{[gapi; node]
    gapi[`node][`item] node
    }

// @fileOverview 
// Create a new tree node with the given content
// @param gapi {dict} DAG api 
// @param item {any} content of the node
// @returns {dict} tree node
.z.m.axds.tree.inject.node.new:{[gapi; item]
    gapi[`node][`new] item
    }
// @fileOverview 
// Update the given node to hold a new item
// @param gapi {dict} DAG api 
// @param item {any} the new content of the node 
// @param node {dict} a tree node to update
// @returns {dict} an updated tree node
.z.m.axds.tree.inject.node.with.item:{[gapi; item; node]
    gapi[`node][`with][`item][item; node]
    } 
// @fileOverview 
// Returns the parent of a given node
// @param gapi {dict} DAG api 
// @param node {dict} tree node 
// @param tree {table} tree specification
// @returns {dict|null}
.z.m.axds.tree.inject.parent:{[gapi; node; tree]
    parents : gapi[`parents][node; tree]; 
    : $[not 0 = count parents;
        first parents;
        (::)];
    }

// @fileOverview 
// 
// @param gapi {dict} 
// @param n {dict} 
// @param g {table} 
// @returns {table} 
.z.m.axds.tree.inject.remove.leaf:{[gapi;n;g]
    : gapi[`remove][`node][n;g];
    }

// @fileOverview 
// Return the root of the tree
// @param gapi {dict} DAG api 
// @param tree {table} tree specification
// @returns {dict} root node of the tree
.z.m.axds.tree.inject.root:{[gapi; tree]    
    first gapi[`sources][tree]    
    }

// @fileOverview 
// Returns the subtree of the given node in the graph
// @param gapi  {dict}  DAG api
// @param n     {dict}  A node within the tree 
// @param g     {table} Tree specification
// @returns     {dict}  The subtree
.z.m.axds.tree.inject.subtree:{[gapi; n; g]
    : enlist[n, enlist[`parents]!enlist ()], .z.m.axds.tree.descendants[n] g
    };

system "d .z.m";

system "d .z.m.axds";
// @category Directed Acyclic Graph - Add
//
// @fileOverview
// Adds a directed edges between a node and a set of children nodes
//
// @param n {#node}         The source DAG node
// @param c {#node | #dag}  New children of n
// @param g {#dag}
//
// @returns {#dag} Children of node in DAG
//
// @throws cycle If adding an edge creates a cycle
.z.m.axds.dag.add.children:{[n;c;g]
    : dag.fold[dag.add.edge n; $[dag.node.is c; enlist c; c]] g;
    }

// @category Directed Acyclic Graph - Add
//
// @fileOverview
// Adds a directed edge between a node and an endpoint in the given DAG.
// NB: If n or end are not in dag then they will be added
//
// @param n {#node}  Source DAG node
// @param c {#node}  New child of n
// @param g {#dag}   A DAG
//
// @returns {#dag} Updated DAG
//
// @throws dag      If dag is not a DAG
// @throws cycle    If adding the edge creates a cycle
.z.m.axds.dag.add.edge:{[n; c; g]
    
    n: $[dag.member[n] g; dag.find[n] g; n];
    c: $[dag.member[c] g; dag.find[c] g; c];
    
    $[  dag.node.id[n] ~ dag.node.id c;
            dag.throw.cin[];
        dag.member[c] dag.ancestors[n] g;
            dag.throw.cycle[];
        dag.member[n] dag.descendants[c] g;
            dag.throw.cycle[];       
            1b
         ];
    
    : dag.add.node[
        dag.node.with.children[distinct dag.node.children[n],enlist dag.node.id c] n] 
        dag.add.node[
            dag.node.with.parents[distinct dag.node.parents[c],enlist dag.node.id n] c] 
        g;
    }
// @category Directed Acyclic Graph - Add
//
// @fileOverview
// Adds a node to the DAG with no links. If the node
// already exists then do not add it but just update it
//
// @param n {#node}  DAG node to add
// @param g {#dag}   DAG to append to
//
// @returns {#dag} DAG with added node
.z.m.axds.dag.add.node:{[n; g]
    : $[  dag.member[n] g;
            -1 _ @[g,(first 0#g),enlist[`item]!enlist (); first where dag.node.id[n] = g`id; :; n];
            
            g,n    
        ];
    }

// @category Directed Acyclic Graph - Add
//
// @fileOverview
// Adds parents to a node in a dag. 
//
// @param n {#node}         The dag node to add
// @param p {#node | #dag}   The new parents of n
// @param g {#dag}               The dag to append to
//
// @returns {#dag} 
//
// @throws cycle If adding an edge creates a cycle
.z.m.axds.dag.add.parents:{[n;p;g]
    : dag.fold[dag.add.edge[;n]; $[98h ~ type p;p;enlist p]] g;
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Returns the set of all ancestors in a dag given a base node
// 
// @param n {#node}  Base node to search from
// @param g {#dag}   DAG to search
//
// @returns {#dag} A DAG containing the set of ancestors
.z.m.axds.dag.ancestors:{[n; g]
    : dag.nodes dag.find[;g] each distinct (raze dag.ids each dag.ancestors[;g] each p),dag.ids p:dag.parents[n] g;
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Returns the immediate children of the given node in the DAG
//
// @param n {#node}  Node to find the children of
// @param g {#dag}   DAG to search
//
// @returns {#dag} A set containing the children of n
.z.m.axds.dag.children:{[n; g]
    : dag.nodes dag.find[;g] each dag.node.children dag.find[n] g
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Clones all elements in a DAG to keep the same
// structure and payload with different node id's
//
// @param g {#dag} DAG to clone
//
// @returns {#dag} Cloned dag
.z.m.axds.dag.clone:{[g]
    : {[g; baseid]
        newid: first 1?0ng;
        
        g: update parents:  (newid,/:parents except\: baseid)   from g where baseid in/: parents;
        g: update children: (newid,/:children except\: baseid)  from g where baseid in/: children; 
        
        : update id:newid from g where id = baseid
        } over enlist[g], dag.ids g;
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Returns a set of nodes in g that is the complement of the set s
//
// @param s {#dag} Nodes to not include in the output
// @param g {#dag} Universe DAG
//
// @returns {#dag} All nodes of g that are not in s
.z.m.axds.dag.complement:{[s;g]
    : dag.nodes dag.find[;g] each dag.ids[g] except dag.ids s
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Returns the set of descendants of the given node
//
// @param n {#node}  Base node to search from
// @param g {#dag}   DAG to search
// 
// @returns {#dag} A set of all descendants of n
//
// @see ancestors
.z.m.axds.dag.descendants:{[n; g]    
    : dag.nodes dag.find[;g] each distinct (raze dag.ids each dag.descendants[;g] each c),dag.ids c:dag.children[n] g;
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Returns all edges connected to n as a DAG
//
// @param n {#node}  Node to return the edges for
// @param g {#dag}   DAG to search through
//
// @returns {#dag} A DAG of all edges to and from n
.z.m.axds.dag.edges:{[n; g]
    : dag.children[n;g],dag.parents[n:dag.find[n] g;g];
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Returns if this DAG is empty or not
//
// @param g {#dag} DAG to check
//
// @returns {boolean} If the DAG is empty
.z.m.axds.dag.empty:{[g] 
    : not count g;
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Returns a table with the id, parents and children column but if
// item is a list of dictionaries then there will be a column for each key
//
// @param g {#dag} DAG to expand
//
// @returns {table} Original DAG with the item expanded to be first class columns
.z.m.axds.dag.expand:{[g]
    if[0 ~ count g; : g];
    
    if[all 99h = type each g`item;
        keyz: distinct raze key each g`item;
        
        if[0 ~ count keyz;
            : g];
        
        : ?[g;();0b;c!c:`id`parents`children] ,'flip keyz!((enlist[`]!enlist (::)),/:g[`item])@\:/:keyz
        ];
    
    : g;
    
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Search for a node in the DAG. If the ID matches any nodes in the DAG then
// return that node
//
// @param n {#node | guid}   Node or the id of the node to find
// @param g {#dag}           DAG to search
//
// @returns {#node} The first match
.z.m.axds.dag.find:{[n; g]
    
    nodeid: $[-2h ~ type n; n; n`id];
    
    f:first select from g where id = nodeid;
    
    : (f; dag.NODE) 0ng ~ f`id;
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Folds over a function using the given directed graph and a list of nodes.
// The function to fold over must accept a single node as its first argument 
// and a DAG as its second argument and return a DAG
// 
// @param f {function}  Function to fold over
// @param s {#dag}      A list of DAG nodes
// @param g {#dag}      DAG to fold over
//
// @returns {#dag} The DAG with f applied successively with each node
.z.m.axds.dag.fold:{[f; s; g]
    : {[f; g; n] f[n] g }[f] over enlist[g], s;
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Returns a list of each node in a dag
//
// @param g {#dag} A DAG
//
// @returns {guids} The ids of each node in the dag
.z.m.axds.dag.ids:{[g]
    : dag.node.id each g 
    } 

// @fileOverview
// Inserts a directed edge and node between a parent and child in the given DAG.
// NB: If p or c are not in dag then they will be added
//
// @param p {#node}  Parent node of n
// @param n {#node}  New DAG node
// @param c {#node}  Child node of n
// @param g {#dag}   A DAG
//
// @returns {#dag} Updated DAG
//
// @throws dag      If dag is not a DAG
// @throws cycle    If adding the edge creates a cycle
.z.m.axds.dag.insert:{[p; n; c; g]
    p: $[dag.member[p] g; dag.find[p] g; p];
    n: $[dag.member[n] g; dag.find[n] g; n];
    c: $[dag.member[c] g; dag.find[c] g; c];
    
    $[  dag.node.id[p] ~ dag.node.id n;
            dag.throw.cin[];
        dag.node.id[p] ~ dag.node.id c;
            dag.throw.cin[];
        dag.node.id[n] ~ dag.node.id c;
            dag.throw.cycle[];
        dag.member[n] dag.ancestors[p] g;
            dag.throw.cycle[];
        dag.member[p] dag.descendants[n] g;
            dag.throw.cycle[];
            1b
         ];
    
    : dag.add.node[
        dag.node.with.children[distinct enlist[dag.node.id n] , dag.node.children[p] except dag.node.id c] p
        ] //p children: pc + n - c
        dag.add.node[
            dag.node.with.parents [distinct enlist[dag.node.id n] , dag.node.parents[c] except dag.node.id p] c
        ] //c parents: cp + n - p
        dag.add.node[
            dag.node.with.children[distinct dag.node.children[n],enlist dag.node.id c] //n children: nc + c
            dag.node.with.parents [distinct dag.node.parents[n],enlist dag.node.id p] n
        ] g; //n parents: np + p
    }

// @category Directed Acyclic Graph
// 
// @fileOverview
// Finds the intersection between two DAGs
//
// @param g1 {#dag} 
// @param g2 {#dag}
// 
// @returns {#dag} Intersection
.z.m.axds.dag.intersect:{[g1; g2] 
    : dag.nodes dag.find[;g1,g2] each dag.ids[g1] inter dag.ids[g2];
    }

// @category Directed Acyclic Graph
// 
// @fileOverview
// Returns if the input has the correct schema to be a DAG
//
// @param g {#dag} 
// 
// @returns {boolean} If the input is a DAG or not
//
// @see DAG 
.z.m.axds.dag.is:{[g] 
    : $[98h ~ type g; 
        all any cols[dag.DAG] ~\:/: cols g; 
        0b
        ];
    }

// @category Directed Acyclic Graph
// 
// @fileOverview
// Returns the union of nodes in two DAGs
//
// @param g1 {#dag}
// @param g2 {#dag}
// 
// @returns {#dag} Union
.z.m.axds.dag.join:{[g1; g2]
    : dag.nodes dag.find[;g1,g2] each dag.ids[g1] union dag.ids[g2];
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Returns if a DAG contains a node
//
// @param n {#node}  Node to check for
// @param g {#dag}   DAG to search in
//
// @returns {boolean} If n is a member of g
.z.m.axds.dag.member:{[n; g]
    : dag.node.id[n] in dag.nodes[g]`id;
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Modifies the item of a given node in g
//
// @param n {#node} Node to modify
// @param m {*}     New item for n
// @param g {#dag}  DAG to update
// 
// @returns {#dag} A DAG where n contains item
//
// @throws missing If n is not a member of g
.z.m.axds.dag.modify:{[n; m; g]
    if[not dag.member[n] g; dag.throw.missing[]];

    : 1 _ update item:sum[id = n`id]#enlist m from (dag.NODE,g) where id = n`id;
    }

// @category Directed Acyclic Graph
// 
// @fileOverview
// Returns a new directed acyclic graph table
//
// @returns {#dag}
// @see DAG
.z.m.axds.dag.new:{:dag.DAG}

// @category Directed Acyclic Graph - Node
//
// @fileOverview
// Returns the children of a node
//
// @param n {#node} A DAG node
//
// @returns {guid[]} The node's children
.z.m.axds.dag.node.children:{[n] : n`children }

// @category Directed Acyclic Graph - Node
//
// @fileOverview
// Given a dictionary that has the same keys as a DAG node but 
// possibly has the wrong types, convert it into a proper DAG node
//
// @param n0 {dict} A dictionary that has similar keys to a DAG node
//
// @returns {#node} A proper DAG node with the relevant information from n0
.z.m.axds.dag.node.decode:{[n0]
    
    n: dag.node.new n0`item;
    
    if[(not .z.m.axq.isNull n0`id) and 0 < count n0`id;
        n: n,enlist[`id]!enlist .z.m.axq.parseGUID n0`id
        ];
    
    if[(not .z.m.axq.isNull n0`parents) and 0 < count n0`parents;
        n: node.with.parents[.z.m.axq.parseGUID each n0`parents] n
        ];
    
    if[(not .z.m.axq.isNull n0`children) and 0 < count n0`children;
        n: dag.node.with.children[.z.m.axq.parseGUID each n0`children] n
        ];
    
    : n;
    }

// @category Directed Acyclic Graph - Node
//
// @fileOverview
// Returns the id of a node
//
// @param n {#node} A DAG node
//
// @returns {guid} The node's id
.z.m.axds.dag.node.id:{[n] : n`id }

// @category Directed Acyclic Graph - Node
//
// @fileOverview
// Returns the number of inbound edges from the given node
//
// @param n {#node} A dag node
//
// @returns {long} Indegree of this node
.z.m.axds.dag.node.indegree:{[n]
    : count dag.node.parents n;
    }

// @category Directed Acyclic Graph - Node
//
// @fileOverview
// Returns if the give node is a DAG node or not
//
// @param n {#node} A DAG node
//
// @returns {boolean} If the input is a DAG node  
// @see NODE
.z.m.axds.dag.node.is:{[n] 
    : $[99h ~ type n; 
        all any key[dag.NODE] ~\:/: key n;  
        0b
        ];
    }

// @category Directed Acyclic Graph - Node
//
// @fileOverview
// Returns the item element of a DAG node
//
// @param n {#node} A DAG node
//
// @returns {*} The payload of the node
// @see NODE
.z.m.axds.dag.node.item:{[n] 
    : dag.node.self[n]`item;
    }

// @category Directed Acyclic Graph - Node
// 
// @fileOverview
// Returns a new node dictionary
//
// @param item {*} Item that this node will hold
//
// @returns {#node}
// @see NODE
.z.m.axds.dag.node.new:{[item] 
    : dag.node.with.item[item] dag.NODE,enlist[`id]!enlist rand 0ng;
    }

// @category Directed Acyclic Graph - Node
//
// @fileOverview
// Returns the number of outbound edges from the given node
//
// @param n {#node} A dag node
//
// @returns {long} Outdegree of this node
.z.m.axds.dag.node.outdegree:{[n]
    : count dag.node.children n;
    }

// @category Directed Acyclic Graph - Node
//
// @fileOverview
// Returns the parents of a node
//
// @param n {#node} A DAG node
//
// @returns {guid[]} The node's parents
.z.m.axds.dag.node.parents:{[n] : n`parents }

// @category Directed Acyclic Graph - Node
//
// @fileOverview
// Confirms that the input is a node and returns it
//
// @param n {#node} A DAG node
//
// @returns {#node} If n is a DAG then return n
// @throws node If the input is not a DAG node
.z.m.axds.dag.node.self:{[n] 
    : $[not dag.node.is n; dag.throw.node[]; n]; 
    }

// @category Directed Acyclic Graph - Node
//
// @fileOverview
// Adds the given children to a node and returns the updated node
//
// @param c {guid[]}    New children of the node
// @param n {#node}     Node to modify
//
// @returns {#node} Updated node
// @see NODE
.z.m.axds.dag.node.with.children:{[c; n]
    : dag.node.self[n],enlist[`children]!enlist c;
    }

// @category Directed Acyclic Graph - Node
//
// @fileOverview
// Adds the given item to a node and returns the updated node
//
// @param item  {*}     New payload of the node
// @param n     {#node} Node to modify
//
// @returns {#node} Updated node
// @see NODE
.z.m.axds.dag.node.with.item:{[item; n] 
    : dag.node.self[n],enlist[`item]!enlist item; 
    }


// @category Directed Acyclic Graph - Node
//
// @fileOverview
// Adds the given parents to a node and returns the updated node
//
// @param p {guid[]} New parents of the node
// @param n {#node}  Node to modify
//
// @returns {#node} Updated node
// @see NODE
.z.m.axds.dag.node.with.parents:{[p; n]
    : dag.node.self[n],enlist[`parents]!enlist p;
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// The identity function for a dag. It checks that the input is a dag 
// and returns the dag
//
// @param g {#dag}
//
// @returns {#dag} 
// @throws dag if the input is not a dag
.z.m.axds.dag.nodes:{[g] 
    : $[
        () ~ g; 
            dag.new[]; 
        not dag.is g; 
            dag.throw.dag[]; 
            g
        ];
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Returns the immediate parents of node n in a DAG
//
// @param n {#node}  Base node
// @param g {#dag}   DAG to search
//
// @returns {#dag} A set of parents for n
.z.m.axds.dag.parents:{[n;g]
    : dag.nodes dag.find[;g] each dag.node.parents dag.find[n] g
    }

// @category Directed Acyclic Graph - Remove
//
// @fileOverview
// Removes all of the child nodes of n
//
// @param n {#node}  Base node to remove the children from
// @param g {#dag}   DAG to modify
//
// @returns {#dag} DAG where the chilren of n have been removed
.z.m.axds.dag.remove.children:{[n; g]
    : dag.fold[dag.remove.node; dag.children[n] g] g
    }

// @category Directed Acyclic Graph - Remove
//
// @fileOverview
// Removes the edge between n and e
//
// @param n {#node}  Parent node of the edge
// @param e {#node}  Child node of the edge
// @param g {#dag}   DAG to update
//
// @returns {#dag} A DAG without the edge from n to e
.z.m.axds.dag.remove.edge:{[n; e; g]
    g: dag.add.node[dag.node.with.parents[dag.node.parents[e] except dag.node.id n] e:dag.find[e] g]
        dag.add.node[dag.node.with.children[dag.node.children[n] except dag.node.id e] n:dag.find[n] g] g;
    
    : ![g; enlist (=; `id; 0ng); 0b; `symbol$()];
    }

// @category Directed Acyclic Graph - Remove
//
// @fileOverview
// Removes a node and all related edges from a DAG
//
// @param n {#node}  Node to remove
// @param g {#dag}   A DAG to remove n from
//
// @returns {#dag} The updated dag
.z.m.axds.dag.remove.node:{[n; g]
    g: dag.fold[dag.remove.edge n; dag.children[n] g] g;
        
    g: dag.fold[dag.remove.edge[;n]; dag.parents[n] g] g; 
    
    : ![g; enlist (in; `id; (0ng; dag.node.id n)); 0b; `symbol$()];
    }

// @category Directed Acyclic Graph - Remove
//
// @fileOverview
// Removes all of the parent nodes of n
//
// @param n {#node}  Base node to remove the parents from
// @param g {#dag}   DAG to modify
//
// @returns {#dag} DAG where the parents of n have been removed
.z.m.axds.dag.remove.parents:{[n; g]
    : dag.fold[dag.remove.node; dag.parents[n] g] g
    }

// @category Directed Acyclic Graph
//
// @fileOverview
// Returns all of the sinks in a dag. A sink is defined as a node
// where the outdegree is 0
//
// @param g {#dag} A DAG to search
//
// @returns {#dag} The set of all sinks in g
.z.m.axds.dag.sinks:{[g]
    : select from dag.nodes[g] where not count each children;
    }

// @category Directed Acyclic Graph
//
// @fileOverview 
// Returns all of the source nodes in g. A source is defined as a node
// where the indegree is 0
//
// @param g {#dag} The DAG to search
//
// @returns {#dag} The set of sources
.z.m.axds.dag.sources:{[g]    
    : select from dag.nodes[g] where not count each parents;
    }

// @category Directed Acyclic Graph - Error
//
// @fileOverview
// Throws a cycle error in the event that the given node
// is a child of itself
.z.m.axds.dag.throw.cin:{'"cycle: child is node"}

// @category Directed Acyclic Graph - Error
//
// @fileOverview
// Throws a generic cycle error
.z.m.axds.dag.throw.cycle:{'"cycle"}

// @category Directed Acyclic Graph - Error
//
// @fileOverview
// Throws a type error that the expected value was to be a DAG
.z.m.axds.dag.throw.dag:{'"type: expected dag"}

// @category Directed Acyclic Graph - Error
//
// @fileOverview
// Throws an error that the given node does not
// exist in this DAG
.z.m.axds.dag.throw.missing:{'"missing: node not a member of dag"}
// @category Directed Acyclic Graph - Error
//
// @fileOverview
// Throws a type error that the expected value was to be a DAG node
.z.m.axds.dag.throw.node:{'"type: expected dag node"}
.z.m.axds.dag.NODE:(!) . flip (
    (`id;       0ng);
    (`parents;  `guid$());
    (`children; `guid$());
    (`item;     ())
    )
.z.m.axds.dag.DAG:([]id:`guid$(); parents:(); children: (); item:())
.z.m.axds.dag.onLoad:{[]
    
    }
 
.z.m.axds.dag.onLoad[];
system "d .z.m";

system "d .z.m.axds";
.z.m.axds.tree.onLoad:{[]
    
    .z.m.axutl.injeqt.injeqt [enlist[`gapi]!enlist .z.m.axds.dag;  .z.M.axds.tree.inject;  .z.M.axds.tree];
    .z.m.axutl.injeqt.injeqt [enlist[`gapi]!enlist .z.m.axds.dag;  .z.M.axds.tree.inject.node;  .z.M.axds.tree.node];
    .z.m.axutl.injeqt.injeqt [enlist[`gapi]!enlist .z.m.axds.dag;  .z.M.axds.tree.inject.node.with;  .z.M.axds.tree.node.with];
    .z.m.axutl.injeqt.injeqt [enlist[`gapi]!enlist .z.m.axds.dag;  .z.M.axds.tree.inject.add;  .z.M.axds.tree.add];
    .z.m.axutl.injeqt.injeqt [enlist[`gapi]!enlist .z.m.axds.dag;  .z.M.axds.tree.inject.remove;  .z.M.axds.tree.remove];

    }

.z.m.axds.tree.onLoad[];
system "d .z.m";

system "d .z.m.axfs";
// @fileOverview
// Returns the drive name of a Windows file path
// @param p {string} path to return drive name for
// @return {string} name of drive indicated in file path
//
// @example Absolute path
// .z.m.axfs.path.nt.drive "C:/Users/demo/Desktop"
// /=> "C:"
//
// @example Virtual drive
// .z.m.axfs.path.nt.drive "\\\\remotedrive\\abc\\def"
// /=> "//remotedrive"
//
// @example Relative path
// .z.m.axfs.path.nt.drive ".\\abc\\def.txt"
// /=> ""
.z.m.axfs.path.nt.drive:{[p] 
    $["//" ~ 2#p; 
        "/" sv (3&count s)#s:"/" vs p; 
      (p?"/")>n:p?":";
        (1+n)#p; 
        ""]
    }

// @fileOverview
// Returns the home directory of the user running this q process
// @return {hsym} path to user's home directory
.z.m.axfs.path.nt.home:{hsym "S"$ssr[getenv `USERPROFILE; "\\"; "/"]}

// @fileOverview
// Returns if the given path is considered an absolute path on 
// a Windows system
// @param x {string} path to check
// @return {boolean} if the input path is considered to be absolute
.z.m.axfs.path.nt.isAbs:{not "" ~ path.nt.drive x}
.z.m.axfs.path.nt.SEP:"\\"
.z.m.axfs.path.nt.RESERVED:"<>:\"/|?*" 
.z.m.axfs.path.nt.DELIMITER:";"
system "d .z.m";

system "d .z.m.axfs";
// @fileOverview
// Returns the home directory of the user running this q process
// @return {hsym} path to user's home directory
.z.m.axfs.path.posix.home:{hsym "S"$getenv `HOME}

// @fileOverview
// Returns if the given path is considered an absolute path on 
// a POSIX system
// @param p {string} path to check
// @return {boolean} if the input path is considered to be absolute
.z.m.axfs.path.posix.isAbs:{[p] path.posix.SEP ~ first p}

.z.m.axfs.path.posix.SEP:"/"
.z.m.axfs.path.posix.DELIMITER:":"
system "d .z.m";

system "d .z.m.axfs";
// @fileOverview
// Returns an absolute copy of the input path using the pwd
// as the anchor for resolving the path
// @param p {#filepath} Path to resolve
// @return {hsym} Absolute version of file path
//
// @example Absolute path given a relative path
// system "cd"
// /=> "/home/demo"
// .z.m.axfs.path.abs "test/path"
// /=> `:/home/demo/test/path
//
// @example Absolute path given an absolute path
// .z.m.axfs.path.abs "/home/demo/kxinstall"
///=> `:/home/demo/kxinstall
.z.m.axfs.path.abs:{[p] 
    $[path.isAbs r:path.resolve p;
        r;
        path.resolve system["cd"], "/", path.unhsym p]
    }

// @fileOverview
// Returns a file path as a Windows style path using backslashes
// as directory separators
// @param p {#filepath} filepath to convert
// @return {string} Windows style file path
// @throws If input path contains invalid Windows path characters 
// @see axfs.path.nt.RESERVED
.z.m.axfs.path.asNT:{[p] 
    win: path.nt.SEP sv path.split p: path.unhsym p;
    $[any r:path.nt.RESERVED in\: count[path.nt.drive p] _ win;
        '"Windows path cannot contain reserved character: \"", path.nt.RESERVED[where r],"\"";
        win, ("";path.nt.SEP) last[p] in (path.nt.SEP; path.posix.SEP)]
    }

// @fileOverview
// Convert path to OS specific string path
// @param p {#filepath} File path to convert
// @return {string} OS specific version of path
.z.m.axfs.path.asOS:{[p] $[.z.o like "w*"; path.asNT p; path.asPOSIX p]}

// @fileOverview
// Returns a file path in its posix format
// @param p {#filepath} File path to convert
// @return {string} POSIX version of path
.z.m.axfs.path.asPOSIX:{[p] $[path.isNT p; count[path.nt.drive p] _ p:path.unhsym p; path.unhsym p]}

// @fileOverview
// Returns the last portion of the file path
// @param p {#filepath} Path to extract basename from
// @return {string} Base name from path
//
// @example Extract file name
// .z.m.axfs.path.basename `:/test/path/foo.txt
// /=> "foo.txt"
//
// @example Extract last directory
// .z.m.axfs.path.basename `:test/path/foo/
// /=> "foo"
.z.m.axfs.path.basename:{[p] $[0 = count s:path.split path.asPOSIX p; ""; last s] }

// @fileOverview
// Compares two file paths to equivalence accounting for os case sensitivity. 
// If either path is relative, it is resolved to be absolute to the current 
// working directory before comparison. Path comparison does not resolve 
// symlinks, refer to  .z.M.axfs.realpath` for resolving symlinks.
// @param p1 {#filepath}
// @param p2 {#filepath}
// @return {boolean} if the paths are equivalent
// @see realpath
.z.m.axfs.path.compare:{[p1; p2]
    p1: path.abs p1;
    p2: path.abs p2;
    : $[.z.o like "[wm]*"; (~) . lower (p1; p2); p1 ~ p2]
    }
// @fileOverview
// Returns if the first path is an ancestor of the second path
// @param base  {#filepath}
// @param child {#filepath}
// @return {boolean}
// @example An absolute path and a relative path 
// .z.m.axfs.path.contains[system "cd"; "./abc/def"]
// /=> 1b
// .z.m.axfs.path.contains[system "cd"; "../abc/def"]
// /=> 0b
// @example A path under the current directory
// .z.m.axfs.path.contains[system "cd"] .z.m.axfs.path.join (system "cd"; "abc/def")
// /=> 1b
.z.m.axfs.path.contains:{[base; child]
    base  : path.split path.abs base;
    child : path.split path.abs child;
    : $[count[base] > count child; 0b; base ~ count[base]#child]
    }

// @fileOverview
// Returns a resource's enclosing directory
// @param p {#filepath} Path of file to return directory for
// @return {string} Path without its basename
// @see path.basename
//
// @example Dirname given a file path
// .z.m.axfs.path.dirname `:test/path/file.txt
// /=> "test/path"
//
// @example Dirname given a folder path
// .z.m.axfs.path.dirname `:test/path/dir/
// /=> "test/path"
//
// @example Dirname given a root path
// .z.m.axfs.path.dirname "/"
// /=> "/"
.z.m.axfs.path.dirname:{[p] $[(t:path.trimSep p) ~ d:path.trimSep path.hsym path.drive p; path.unhsym d; "/" sv -1 _ path.split t] }

// @fileOverview
// Returns the drive that a path is pointing to. On POSIX type systems,
// this path will be "/" if the path is absolute or "" if not. If the
// path is a Windows style path, the drive name will be extracted.
// @param p {#filepath} Path to return drive name of
// @return {string} Drive path is referrring to
// @see path.nt.drive
.z.m.axfs.path.drive:{[p] $[path.isNT p; path.nt.drive path.unhsym p; (""; enlist path.posix.SEP) path.isAbs p]}

// @fileOverview
// Dynamically evaluate path's that refer to environment variables.
// Environment variables can be expressed using a `$VAR` or `${VAR}` 
// syntax.  
//
// @param p {#filepath} File path to evaluate containing expressions
// @return {hsym} Evaluated file path
// 
// @example Using an environment variable
// .z.m.axfs.path.evaluate "$AX_WORKSPACE/test/file.txt"
// /=> `:/home/user/analyst/data/workspace/user/ws/test/file.txt
//
// @example Using terminated environment variable
// .z.m.axfs.path.evaluate "${USER}_", ssr[string .z.d; "."; "-"] 
.z.m.axfs.path.evaluate:{[p]
    
    pe:{[p; x]
        $[(c:count x) > s:x?"$";
            [
                evar: "S"$x w + til e:c^first ((w:s + 1 + "{" = x s + 1) _ x) ss "[^a-zA-Z0-9_]";
                .z.s[p] raze  @[(0; s; c&e + w + "}" = x w + e) _ x; 1;:; getenv evar]
                ];
            p,enlist x
            ]
        }/[(); path.split p];
    
    : path.resolve "/" sv pe
    }
// @fileOverview
// Returns a file extension from a given path
// @param p {#filepath} Path to extract extension from
// @return {string} File extension
.z.m.axfs.path.ext:{[p] $["/" = last path.unhsym p; ""; any w:"." = s:1_last path.split p; last[where w] _ s; ""] }

// @fileOverview
// Returns the file name from a path without the file's extension
// @param p {#filepath} Path to return file name of
// @return {string} Name of file without the extension
.z.m.axfs.path.filename:{[p] neg[count path.ext p] _ path.basename p}

// @fileOverview
// Returns the home directory for the current OS user
// based on the operating system
// @return {hsym} Path to home directory
.z.m.axfs.path.home:{$[.z.o like "w*"; path.nt.home[]; path.posix.home[]]}

// @fileOverview
// Converts any input path to a normalized hsym using forward slashes
// @param p {#filepath} File path to normalized
// @return {hsym} Normalized file path
//
// @example Turning a string into an hsym
// .z.m.axfs.path.hsym "test/path"
// /=> `:test/path
//
// @example Normlizing path slashes
// .z.m.axfs.path.hsym "C:\\Users\\My Documents"
// /=> `:C:/Users/My Documents
.z.m.axfs.path.hsym:{[p] 
    $[path.TOO_LONG ~ p; 
        '"hsym path too long"; 
      () ~ p;
        p;
      (::) ~ p;
        `:;
        path.i.hsym path.i.normalize path.i.unhsym p] 
    }

// @private
// @fileOverview
// Converts a string or a symbol to an hsym'd symbol. Special care must be taken to
// preserve any whitespace characters at the end of a path when casting to a symbol. 
// To avoid dropping any characters, a trailing slash is added to the path, it is 
// converted to a symbol, then the slash is dropped with `vs`. This is the only way
// to avoid dropping whitespace at the end of a symbolic path
// @param p {string|symbol} Path to cast to a symbolic hsym
// @return {#hsym}
.z.m.axfs.path.i.hsym:{[p]
    if[-11h=type p; p:string p];
    if[not 10h=type p; '"type"];
    
    : first ` vs `$$[":"~first p; p;":",p],"/"; 
    }

// @private
// @fileOverview
// Converts all path separators to a normalized POSIX forward slash
// @param p {string} An "unhsym'd" file path
// @return {string} a normalized file path
.z.m.axfs.path.i.normalize:{[p] @[p; path.i.seps p; :; path.posix.SEP] }

// @private
// @fileOverview
// Resolved the components of a split file path
// @param p {string[]} path accumulator
// @param x {string} path component
// @return {string[]} parts of path
.z.m.axfs.path.i.resolve:{[p; x]
    isfirst: 0 = count p;
    $[isfirst & x ~ path.TILDE;
        path.split path.home[];
      (x ~ path.PARENT) & not (path.PARENT ~ last p) | isfirst;
        -1 _ p;
      not[isfirst] & x ~ path.CURRENT;
        p;
      ((1 < count p) | 0 < count first p) & 0 = count x;
        p;
        p,enlist x]
    }


// @private
// @fileOverview
// Returns the indices of the path separators in the inputs path
// @param p {#filepath} file path
// @return {long[]} indices of separators in path
.z.m.axfs.path.i.seps:{[p]
    : asc (c where not "\\" = p -1 + c:where p = "/"), c where not "/" = p 1 + c:where p = "\\"
    }
// @private
// @fileOverview
// Returns an unhsym version of the input without normalizing the slashes
// @param p {#filepath} 
// @return {string}
.z.m.axfs.path.i.unhsym:{[p] 
    s:$[-11h=type p; 
            string p; 
        10h=abs type p; 
            raze p;
            path.SEP sv path.i.unhsym each p];
    
    s: $[":" ~ first s; 1 _ s; s];
    s: $[s like "[a-zA-Z]:"; s,"/"; s];
    : s
    }

// @fileOverview
// Returns the intersection portion of two file paths. The intersection
// is defined by the leading components that overlap. Once the paths
// differ, the intersection is terminated.
//
// @param x {#filepath} first file path
// @param y {#filepath} second file path
// @return {#hsym} overlapping portion of file paths
//
// @example Overlapping Paths
// .z.m.axfs.path.inter[`:test/path/foo/bar; `:test/path/baz/bar]
// /=> `:test/path
//
// @example Non-overlapping Paths
// .z.m.axfs.path.inter[`:/test/path/foo/bar; `:other/path]
// /=> `:
.z.m.axfs.path.inter:{[x; y]
    px: path.split x;
    py: path.split y;
    m : min count each (px;py);
    ol: m^first where not (m#px)~'m#py;
    
    : path.join ol#py;
    }

// @fileOverview
// Returns if a path is considered absolute for its file system.
// The path is evaluated to be absolute depending on if the path
// is considered to be POSIX or NT style. To explicitly check if 
// a path is absolute on a given OS, call the appropriate file
// system implementation of isAbs.
// @param p {#filepath} Path to check if is absolute
// @return {boolean} If path is considered absolute for its file system
// @see path.isNT
// @see path.nt.isAbs
// @see path.posix.isAbs
.z.m.axfs.path.isAbs:{[p] $[path.isNT p:path.unhsym p; path.nt.isAbs p; path.posix.isAbs p]}

// @fileOverview
// Returns if a given path is considered to be a Windows NT path or not.
// This function uses the following heuristic to determine if a path
// should be treated as NT or not.
//
// 1. If the path contains an unescaped colon before a slash, return true
// 2. If the path has a prefix of two backslashes (a Windows Virtual Mount), return true
// 3. If the path contains an unescaped backslash, return true
// 4. return false
//
// @param p {#filepath} File path to check if is NT style
// @return {boolean} If the path is considered NT style
//
// @example A POSIX style path
// .z.m.axfs.path.isNT `:/test/path
// /=> 0b
//
// @example A Windows absolute path
// .z.m.axfs.path.isNT "C:\\Users"
// /=> 1b
//
// @example A Windows virtual mount
// .z.m.axfs.path.isNT "\\\\virtualdrive\\test\\path"
// /=> 1b
// 
// @example A relative Windows path
// .z.m.axfs.path.isNT "test\\path"
// /=> 1b
// // however, switching the direction of the slash changes the result
// .z.m.axfs.path.isNT "test/path"
// /=> 0b
// 
// @example A POSIX path with an escaped backslash
// .z.m.axfs.path.isNT "test\\/path"
// /=> 0b
.z.m.axfs.path.isNT:{[p]

    p:path.i.unhsym p;
    
    : $[
      ((p?"/") & p?"\\") > n:p?":";  
        not "\\" = p n-1; 
      "\\\\" ~ 2#p;    
        1b;
      any n:"\\" = p;
        not all (p 1 + where n) in\: path.ESCAPED; 
        0b
        ] 
    }

// @fileOverview
// Returns if a given file path is consider to be a POSIX file path.
// This function returns the negation of  .z.M.axfs.path.isNT`.
// @param p {#filepath} Path to check if is POSIX style
// @return {boolean} If the path is considered to be POSIX
// @see path.isNT
.z.m.axfs.path.isPOSIX:{[p] not path.isNT p }

// @fileOverview
// Returns if a path is considered to be a relative path. This
// is the negation of checking if the path is absolute.
// @param p {#filepath} Path to check
// @return {boolean} If the path is considered to be relative
// @see path.isAbs
.z.m.axfs.path.isRelative:{[p] not path.isAbs p}

// @fileOverview
// Returns if a path is considered to be in a fully resolved state or not.
// A path is considered to be resolved if it does not contain any path control
// characters. These characters include `~`, `.`, `..` and `//`.
// @param p {#filepath} Path to check if is resolved
// @return {boolean} If the path is considered to be in a resolved state
// @see path.resolve
.z.m.axfs.path.isResolved:{[p] 
    if[any raze (path.UNRESOLVED,path.TILDE) in\: p:path.unhsym p;
        s: path.split $["./" ~ 2#p; 2_p; p];
        : $[any 0 < where "" ~/: s; 0b; path.TILDE ~ first s; 0b; not any any each s ~\:/: path.UNRESOLVED]];
    : 1b;
    }
// @fileOverview
// Joins multiple path components into a single path and resolves the result.
// @param ps {#filepath[]} File path components to merge
// @return {hsym} A concatenated file path
//
// @example Joining multiple file paths formats
// .z.m.axfs.path.join (`:test/path; "abc\\def"; `file.txt)
// /=> `:test/path/abc/def/file.txt
//
// @example Joining paths with control characters
// .z.m.axfs.path.join ("~"; ".."; "abc/def")
// /=> `:/home/abc/def
//
// @example Joining multiple absolute paths
// // Join will take the last absolute file path component as the root
// // path and drop everything before it.
// .z.m.axfs.path.join (`:/test/path; `file.txt; `:/xyz/abc; `hello.txt)
// /=> `:/xyz/abc/hello.txt
.z.m.axfs.path.join:{[ps]
    parts: path.unhsym each $[any a:path.isAbs each ps; last[where a] _ ps; ps];
    parts: $[first[parts] ~ enlist "/"; enlist[""],1_parts; parts];
    parts: $[first[parts] ~ (); 1_parts; parts];
    : path.resolve "/" sv parts 
    }

// @fileOverview
// Returns the path of y relative to x. The following conditions 
// determine if a path is relative
// - If both x and y are absolute and share the same root, return the steps diff
// - If either x or y is relative but not the other, return y
// - If x is relative and y is relative, treat both x and y as if they
//    start at the same point and return the steps between
//
// @param x {#filepath} Base file path
// @param y {#filepath} Target file path
// @return {hsym} File path of y relative to x
.z.m.axfs.path.relativeTo:{[x; y]
    ax: path.isAbs x;
    ay: path.isAbs y;
    
    if[not[ax & ay] & ay | ax;
        : path.resolve y];
    
    sx  : path.split x;
    sy  : path.split y;
    ixy : path.inter[x; y];
    cxy : $[`: ~ ixy; 0; count path.split ixy];
    
    if[ax; sx: cxy _ sx; sy: cxy _ sy; cxy: "j"$`: ~ ixy];
    
    px : $[`:. ~ path.hsym x; 0;count[sx] - cxy]#enlist "..";
    py : cxy _ sy;
    
    : $[0 = count m:"/" sv px,py; `:.; path.i.hsym m]
    }
// @fileOverview
// Returns the input path by modifying it based on its control characters.
// The following table details control characters that will be resolved.
// 
// | Character | Name    | Description                                                                          |
// | --------- | ----    | -----------                                                                          |
// | `~`       | home    | If this character is the first  token, it is replaced with the user's home directory |
// | `.`       | current | Indicates a reference to the current directory, removed if not the first token       |
// | `..`      | parent  | References the parent directory, removes the last token from the path                |
//
// In addition to the above character replacements, duplicate path separators 
// will also be removed. However, to account for normalized Windows virtual mounts,
// duplicated leading path separators will not be modified.
// @param p {#filepath} Path to resolve
// @return {hsym} Resolved path
// @example Resolving a path with a home character
// // Note the second `~` character is not expanded, only
// // a leading `~` will be resolved 
// .z.m.axfs.path.resolve "~/test/../.././//~/foo/bar"
// /=> `:/home/~/foo/bar
// 
// @example Windows virtual mount
// .z.m.axfs.path.resolve each ("\\\\test\\mount"; `://test/mount);
// /=> `://test/mount`://test/mount
.z.m.axfs.path.resolve:{[p] $[(::) ~ p; `:.; path.isResolved p; path.hsym p; path.hsym "/" sv path.i.resolve/[(); path.split p]] }


// @fileOverview
// Returns the root of an absolute file path. The root of an absolute
// POSIX path will be `"/"`. The root of an absolute NT path will
// be the drive name (ex. `"C:"` or `"//testmount"`).
// @param p {#filepath} Path to extract root from
// @return {string} Root of file path
.z.m.axfs.path.root:{[p]
    $[path.isNT p; 
        $[path.isAbs p; path.nt.drive path.unhsym p; ""]; 
      "/" = first p:path.i.unhsym p; 
        (first[path.i.seps p]#p),"/"; 
        ""]
    }

// @fileOverview
// Sanitizes a file path by replacing all special characters with underscores.
// Only printable text characters will remain unsanitized.
// @param p {#filepath}
// @return {#filepath}
.z.m.axfs.path.sanitize:{[p]
    s: -11h ~ type p;
    p: $[s; string p; p];
    h: ":" ~ first p;
    r: $[h; 1 _ p; p];
    : $[h; path.i.hsym; s; "S"$; ::] ?[r in\: asc .Q.an,"-. "; r; "_"]
    }

// @fileOverview
// Returns the components of a file path split by the path separator.
// This function handles the case where a path contains escaped path
// separators.
// @param p {#filepath} The path of the file to split
// @return {string[]} The components of the path
.z.m.axfs.path.split:{[p]
    if[0 = count p; : ()];
    p: $[("\\" ~ last p) | "/" ~ last p:path.i.unhsym p; -1 _ p; p];
    : $[0 < count s:path.i.seps p; raze (1#;1_/:1_)@\: (0,s except count p) _ p; enlist p]
    }

// @fileOverview
// Returns the intermediate paths of a given file path. This returns
// qualified paths starting at the base path and concatenating each
// subfolder.
// @param p {#filepath} Path to break into steps
// @return {hsym[]} Incremental steps of path
// @example Steps of absolute path
// .z.m.axfs.path.steps `:/test/path/foo/bar.txt
// /=> `:/test`:/test/path`:/test/path/foo`:/test/path/foo/bar.txt
.z.m.axfs.path.steps:{[p] path.isAbs[p] _ {path.join (x;y)}\[();path.split p] }
// @fileOverview
// Trims trailing separator from a path
// @param p {#filepath} Path to trim separator from
// @return {hsym} Trimmed file path
.z.m.axfs.path.trimSep:{[p] 
    : $[(enlist["\\"]~ p) | enlist["/"] ~ p:path.unhsym p; 
        path.i.hsym p; 
        path.i.hsym neg[count[p] ~ 1 + last path.i.seps p] _ p] 
    }

// @fileOverview
// Converts a file path to a string representation without a
// leading colon. The returned file path will have normalized
// path separator characters
// @param p {#filepath} File path to normalize
// @return {string} File path without leading colon
.z.m.axfs.path.unhsym:{[p] 1 _ string path.hsym p}

// @fileOverview
// Adds a trailing separator to a path
// @param p {#filepath} Path to add a separator to
// @return {hsym} Path with trailing separator
.z.m.axfs.path.withSep:{[p] path.i.hsym $[count[p] = 1 + last path.i.seps p:path.unhsym p;p;p,"/"]}

.z.m.axfs.path.PARENT:".."
.z.m.axfs.path.CURRENT:enlist "."
.z.m.axfs.path.UNRESOLVED:(path.CURRENT; path.PARENT; 2#path.nt.SEP; 2#path.posix.SEP)
.z.m.axfs.path.TOO_LONG:hsym "S"$1000#"_"
.z.m.axfs.path.TILDE:enlist "~"
.z.m.axfs.path.SEP:$[.z.o like "w*"; path.nt.SEP; path.posix.SEP]
.z.m.axfs.path.ESCAPED:"!/\"#$&'()*,;<=>?[\\]^`{|}~-: "
.z.m.axfs.path.DELIMITER:$[.z.o like "w*"; path.nt.DELIMITER; path.posix.DELIMITER]
// @qlintsuppress MISSING_OVERVIEW MISSING_RETURNS
.z.m.axfs.path.onLoad:{[]
    }

.z.m.axfs.path.onLoad[];
system "d .z.m";

system "d .z.m.axfs";
// @fileOverview
// Returns a human readable representation of a resource's permissions
// @param x {number} File permissions where the last nine bits indicate permissions
// @return {string} Permissions in the form of "rwx" organized
//     into triples of owner, group, everyone permissions. A 
//     dash character `"-"` indicates that there is no permission.
.z.m.axfs.util.dperm:{?[-9#0b vs x;"rwxrwxrwx";"-"]}

// @fileOverview
// Returns a human readable display size of a number of bytes
// @param bytes {long} Number of bytes to print
// @return {string} Display representation of the byte count
// @example Displaying 1.2 gigabytes
// .z.m.axfs.util.dsize 1000000000 * 1.2
// /=> "1.2GB"
.z.m.axfs.util.dsize:{[bytes]
    if[null bytes; : "--"];
    suffix : key[util.DSIZES] -1 + first where bytes < value util.DSIZES; 
    : $[null suffix; string[bytes]," B";.Q.f[1;bytes % util.DSIZES suffix]," ",string suffix];
    }

// @fileOverview
// Returns a display type for the OS type of a given resource
// @param x {byte} OS resource type
// @return {symbol} Human readable display name for resource type
// @see util.DTYPES
.z.m.axfs.util.dtype:{util.DTYPES x}

// @fileOverview
// Runs a heuristic on a set of bytes to guess if they represent a binary file.
// This heuristic is an implementation of the algorithm used in PERL 
// https://perldoc.perl.org/functions/-X.html for their -T/-B check. If
// there is enough evidence that the bytes represent a binary source, return true
// otherwise return false. If no content is passed, return false. 
//
// @param bytes {byte[] | (byte[];float)} data to test
//    If a tuple is passed the second value is used as a threshold value which
//    is set to 0.3 (30%) by default
// @return {boolean}
.z.m.axfs.util.isBinary:{[bytes]
    threshold : $[0h = type bytes; last  bytes ; 0.3];
    bytes     : $[0h = type bytes; first bytes ; bytes];
    evidence  : "x"$bytes;
        
    if[0x00 in evidence; : 1b];
    
    evidence: evidence where not (evidence > 0x1F) & evidence < 0x7F;
    evidence: evidence except "x"$"\r\n\t";
    
    if[not count evidence; : 0b];
    
    evidence: first {[state]
        bytes    : last state;
        continue : $[bytes[0] within 0xc0df; 2; bytes[0] within 0xe0ef; 3; bytes[0] within 0xf0f7; 4; 0];
        valid    : $[continue; all (1_continue#bytes) within\: 0x80bf; 0b];
        $[valid; (first state; continue _ bytes); (first[state],(1&count bytes)#bytes; 1 _ bytes)]
        }/[(();evidence)];
    
    : count[evidence] >= threshold * count bytes;
    }

// @fileOverview
// Orders a collection of file stats by a critiera
// @param sort  {function} a function for sorting the grouped items
// @param prop  {symbol} Stat column to group by
// @param stats {table} List of stats
// @return {table} Ordered 
// @example Sort folders before files
// util.orderBy[`format] stat each ls "."
.z.m.axfs.util.orderBy:{[sort; prop; stats] 
    $[0=count stats; stats; stats raze sort group ?[stats; (); ();  prop]]
    }

.z.m.axfs.util.format:(!) . flip (
    (`; ::);
    (`NONE      ; 0x00);
    (`FIFO      ; 0x01);
    (`CDEVICE   ; 0x02);
    (`DIR       ; 0x04);
    (`BDEVICE   ; 0x06);
    (`FILE      ; 0x08);
    (`SYMLINK   ; 0x0a);
    (`SOCKET    ; 0x0c)
    )
.z.m.axfs.util.NAVIGABLE:0x0406
.z.m.axfs.util.DTYPES:(!) . flip (
    (0x0c; "S"$"socket");
    (0x0a; "S"$"symbolic link");
    (0x08; "S"$"file");
    (0x06; "S"$"block device");
    (0x04; "S"$"directory");
    (0x02; "S"$"character device");
    (0x01; "S"$"fifo")
    )
.z.m.axfs.util.DSIZES:(!) . flip (
    (`KB; 1e3);
    (`MB; 1e6);
    (`GB; 1e9);
    (`TB; 1e12);
    (`PB; 1e15);
    (`EB; 1e18);
    (`ZB; 1e21);
    (`YB; 1e24)
    )
system "d .z.m";

system "d .z.m.axenv";
// @fileOverview 
// Return the current system architecture. Note that unlike uname -m, 
// Windows just returns you the architecture of the running process.
// @returns {Symbol} Architecture
.z.m.axenv.arch:{[]

    if[.z.o like "w*";
        a : first trim system "echo %PROCESSOR_ARCHITECTURE%";
    
        : $[(a like "AMD64") | a like "IA64";
                `x64;
            a like "ARM64";
                `arm64;
            upper[a] like "X86";
                `x32;
               `$a]
        ];
    
    a: first system "uname -m";

    : $[(a like "aarch64*") | a like "armv8*";
            `arm64;
        a like "i[36]86";
            `x32;
        a like "x86_64";
            `x64;
            `$a]
    }
// @fileOverview 
// Returns if the user has configured this process to change directories
// when a workspace is loaded or not.
// @return {boolean} If the user has configued to change workspace automatically
.z.m.axenv.cdWSEnabled:{ "yes" ~ getenv `$ upper string[.z.m.ax.DEFINES`NAME],"_WORKSPACE_CD" }


// @fileOverview Return the build version
// @returns {string} 
.z.m.axenv.displayVersion:{[]
    @["" sv @[;`version`label] .j.k "\n" sv read0@; 
        .z.m.axfs.path.join (.z.m.axenv.path.releng[];"version.json"); 
        "unknown"]
    }

// @fileOverview 
// Return the distro and version q is running on.
// eg: 'rhel7', 'ubuntu16', etc.
// Note that centos will be reported as rhel.
// Also note that if this is run on Windows or Mac machines,
// the output will be 'win' and 'osx' respectively.
// Will return `unknown if this check fails to determine the machine type.
// @returns {symbol} The distro and version
.z.m.axenv.distro:{[]
    if [.z.o like "w*"; : `win];
    if [.z.o like "m*"; : `osx];
    
    : @[i.distro; (::); { : `unknown }];
    }

// @fileOverview 
// Returns the username for this process
// @returns {symbol} Symbolic username
.z.m.axenv.getUser:{[]
    : $[`uname in key  .z.M.ax.rt; .z.m.ax.rt.uname[]; null i.user; .z.u; i.user]
    }

// @fileOverview Parse the distro and version from either the redhat-release file or os-release file
// @returns {Symbol} Distro, in the format of <distro><major ver>, ie: `ubuntu18 or `rhel6
.z.m.axenv.i.distro:{[]
    rvf : `$":/etc/redhat-release";
    lvf : `$":/etc/os-release";
    
    dequote : {[s] s where not "\"" ~/: s };
    
    if [i.exists rvf;
        s      : "release ?";
        info   : first i.readfile rvf;
        major  : first last " " vs info (first info ss s) + til count s;
        :`$"rhel",major];
    
    if [i.exists lvf;
        info : (!) . flip "=" vs/: r where not "" ~/: r: i.readfile lvf;
        dist : dequote info["ID"];
        major: first "." vs dequote info["VERSION_ID"];
        :`$dist,major];
    
    :`unknown;
    }

// @fileOverview Check if a file exists. This is here so I can stub this in the tests.
// @param f {hsym} File to check 
// @returns {Boolean} If file exists
.z.m.axenv.i.exists:{[f] f ~ key f }

// @fileOverview
// Returns the version information for a platform install
// @return {dict (version: string; label: string; id: guid; timestamp: timestamp)}
.z.m.axenv.i.pver:{[]
    info: @[{(!) . "S=\n" 0: "c"$read1 x}; .z.m.axfs.path.join (path.home[];"..";"version.txt"); ::];
    
    if[10h ~ type info; : i.DEFAULT_VERSION];
    
    patch : first "P" vs info`incremental.version;
    label : $[0 < count p:last 1 _ "P" vs info`incremental.version; "P",p; ""];
    
    : (!) . flip (
        (`version   ; "." sv (info`major.version`minor.version),enlist patch);
        (`label     ; label);
        (`id        ; "G"$info`build.guid);
        (`timestamp ; "P"$"" sv("20";"-";"-";"T";":";":"),'2 cut info`build.time)
        )
    }
// @fileOverview Read a file as text. This is here so I can stub this in the tests.
// @param f {hsym} File to read 
// @returns {char[]} output of read0
.z.m.axenv.i.readfile:{[f] read0 f }

// @fileOverview
// Returns the version information for a standalone install
// @return {dict (version: string; label: string; id: guid; timestamp: timestamp)}
.z.m.axenv.i.sver:{[]
    info: @[{.j.k raze read0 x}; .z.m.axfs.path.hsym path.version[];::];
    
    if[10h = type info; : i.DEFAULT_VERSION];
    
    convert: (!) . flip (
        (`version   ; ::);
        (`label     ; ::);
        (`id        ; "G"$);
        (`timestamp ; {"P"$"" sv ("";"-";"-";":";":"),'"-" vs x})
        );
        
    : convert @' info;
    }

// @fileOverview
// Returns the system temporary directory
// @return {string}
.z.m.axenv.tmp:{[]
    p: $[.z.o like "m*" ; getenv`TMPDIR; getenv`TMP];
    if[not count p;
        p: $[.z.o like "w*"; getenv[`USERPROFILE],"\\AppData\\Local\\Temp"; "/tmp"]];
    : p                 
    }


system "d .z.m";

system "d .z.m.axfs";
// @fileOverview
// Closes a file handle if there is an open connection with this
// process. 
// @param h {int} Connection descriptor
// @return {null}
// @see hclose
// @see .z.W
.z.m.axfs.close:{[h] @[hclose; h; {::}] }

// @fileOverview
// Returns the OS device number of a resource on disk if it exists,
// otherwise throws an error
// @param p {#filepath} Path to resource
// @return {byte} OS device id
.z.m.axfs.device:{[p] i.stat[1 _ string checkAccess path.resolve p]`device }

// @fileOverview
// Returns the disk usage of a given path. If the path is a file, 
// this returns the size of the file. If the path is a directory,
// this returns the size of the directory plus all of its immediate
// contents.
// @param p {#filepath} Path to return disk usage of
// @return {long} Number of bytes used on disk for the given resource
.z.m.axfs.du:{[p] i.du ls p }

// @fileOverview
// Returns the disk usage of all descendants of a given path. 
// @param p {#filepath} Path to return disk usage of
// @return {long} Number of bytes used on disk for the given resource
// @see du
.z.m.axfs.dur:{[p] i.du lsr p }

// @fileOverview
// Returns if a given path exists on the current file system
// @param p {#filepath} File path to check for existance
// @return {boolean} If the path has an existing resource on the file system
.z.m.axfs.exists:{[p] @[{0x0 < i.format[0b] x}; checkAccess path.resolve p; 0b] }

// @private
// @fileOverview
// Limits access to directories above a specified base directory with a filter
// option for allow and deny directories. If a base directory is provided, only
// paths that are below the base directory will be accepted. This applies even
// if a directory above the base directory is in the allow list. The allow and
// deny options match file path patterns using `like` matching syntax. The 
// allow list is applied before the deny list enabling higher level directories
// to be allowed with lower level ones being denied. 
// @param base  {string}
// @param allow {string[]}
// @param deny  {string[]}
// @param p     {hsym} File path
// @return {hsym} Input file path if it can be accessed
.z.m.axfs.i.access:{[base; allow; deny; p]
    real   : @[realpath; p; path.abs p];
    prefix : {$["*"=x 0;x;":",x]};
    if[count base; 
        if[not real like prefix base,"*"; 
            '"access: attempt to read files above start directory"]];
    if[count allow;
        if[not any real like/: prefix each allow; 
            '"access: attempt to read files outside of allow list"]];
    if[count deny; 
        if[any real like/: prefix each deny;
            '"access: attempt to read files in deny list"]];
    : p
    }
// @private
// @fileOverview
// Returns the disk usage of a given set of resources
// @param x {#filepath[]}
// @return {long}
.z.m.axfs.i.du:{ $[0 < count x; sum (@[stat;;(1#`bytes)!enlist 0] each x)@'`bytes; 0] }

// @private
// @fileOverview
// Returns the format bit of the stat of a node on disk
// @param r {boolean} if true resolve symlinks 
// @param p {#hsym} resolved path 
// @return {byte}
.z.m.axfs.i.format:{[r; p] 
    f : @[{i.stat[x]`format}; 1 _ string p; 0x0];
    : $[r & util.format.SYMLINK ~ f; @[{i.statlink[x]`format};p;f]; f]
    }

// @private
// @fileOverview 
// Checks if a symlink has been completely resolved or if it needs
// to be resolved further
// @param links {#hsym[]} The symlinks that have been visited
// @return {boolean} if the current path still needs to be resolved
.z.m.axfs.i.linkfound:{[links]
    $[MAX_LINKS < count links;
        '"max symlink depth exhausted";
        not[last[links] in -1_links] & util.format.SYMLINK ~ i.stat[1 _ string last links]`format]
    }
// @private
// @fileOverview
// Returns the listing of a given path
// @param p {hsym}
// @return {symbol[]}
.z.m.axfs.i.ls:{[p]
    $[11h = type k:key checkAccess p;
        p,path.i.hsym each $["/"~last s:string p;s;s,"/"],/:string k; 
      -11h = type k; 
        enlist p;
      util.format.SYMLINK ~ i.stat[1 _ string p]`format;
        enlist p;
        ()]
    }
// @private
// @fileOverview
// Recursively resolves symlinks to determine if target is a directory. If a cycle
// is encounted, the first matching duplicate point is returned
// @param p {#hsym}
// @return {symbol[]}
.z.m.axfs.i.statlink:{[p]
    resolve: {x,enlist $[path.isAbs[ln]|0<count parent:path.dirname ln; path.join ("S"$parent),; ::] readlink ln:last x};
    : i.stat 1 _ string last resolve/[i.linkfound; enlist p];
    }

// @fileOverview
// Returns if the given path is a directory. This function will
// return true if given a symlink that points to a directory
// @param p {#filepath} File path to check
// @return {boolean} If input path is a directory
.z.m.axfs.isDir:{[p] util.format.DIR ~ i.format[1b] path.resolve p }

// @fileOverview
// Returns if the given path is a FIFO (named pipe) type (*nix systems only)
// @param p {#filepath} File path to check
// @return {boolean} If input path is a FIFO
.z.m.axfs.isFIFO:{[p] util.format.FIFO ~ i.format[1b] path.resolve p }

// @fileOverview
// Returns if the given path is a file
// @param p {#filepath} File path to check
// @return {boolean} If input path is a file
.z.m.axfs.isFile:{[p] util.format.FILE ~ i.format[1b] path.resolve p }

// @fileOverview
// Returns if the given path is a socket type (*nix systems only)
// @param p {#filepath} File path to check
// @return {boolean} If input path is a socket
.z.m.axfs.isSocket:{[p] util.format.SOCKET ~ i.format[1b] path.resolve p }
// @fileOverview
// Returns if the given path is a symlink (*nix systems only)
// @param p {#filepath} File path to check
// @return {boolean} If input path is a symlink
.z.m.axfs.isSymlink:{[p] util.format.SYMLINK ~ i.format[0b] path.resolve p }
// @fileOverview
// Lists the contents of a directory and returns the paths
// with the input path as a prefix including the path itself.
// @param p {#filepath} File path to list contents of
// @return {hsym[]} List of contents of path
//
// @example Listing on a directory
// t:([] a:til 10; b:10?10; c:10?.Q.a);
// `:t/ set t;
// .z.m.axfs.ls `:t
// /=> `:t`:t/.d`:t/a`:t/b`:t/c
//
// @example Listing on a file
// r:([] a:til 10; b:10?10; c:10?.Q.a);
// `:r set r;
// .z.m.axfs.ls `:r
// /=> `:r
.z.m.axfs.ls:{[p] $[exists p; i.ls path.trimSep path.resolve p; `symbol$()] }
// @fileOverview
// Recursively lists the contents of a directory and all of its 
// child directories.
// @param p {#filepath} Parent file directory to search under
// @return {hsym[]} Paths of child directories
// @see ls
.z.m.axfs.lsr:{[p] 
    if[not exists p; : `symbol$()];
    
    raze {[ps]
        r:raze 1 _/: i.ls each p where (11h = type key@) each p:last ps;
        $[0 < count r; ps,enlist r; ps] 
        }/[enlist enlist p:path.resolve path.trimSep p]
    }

// @fileOverview
// Moves a file or directory from a source location to a destination. 
// If the source and destination are on the same physical device, this
// operation is simply a rename of the resource. If the source and 
// destination paths differ, this operation is a copy from one to the 
// other and a removal of the original upon success.
//
// @param src  {#filepath} Path of source file or directory to move
// @param dest {#filepath} Location to move contents to
// @return {hsym} Destination path
// 
// @example Moving a file
// `:foo.csv 0: csv 0: ([] a:til 10; b:10?10; c:10?.Q.a);
// .z.m.axfs.mv[`:foo.csv; `:bar.csv];
// /=> `:bar.csv
// read0 `:bar.csv
// /=> "a,b,c"
// /=> "0,6,z"
// /=> "1,2,z"
// /=> ..
//
// @example Moving a directory
// `:t/ set ([] a:til 10; b:10?10; c:10?.Q.a);
// .z.m.axfs.mv[`:t; `:r];
// /=> `:r
// get `:r
// /=> a b c
// /=> -----
// /=> 0 4 t
// /=> 1 8 h
// /=> 2 4 b
// /=> ..
.z.m.axfs.mv:{[src; dest]
    destdir: {$["" ~ x; `:.; exists x; x; path.dirname x]} over path.dirname dest;
    $[device[src] ~ device destdir;
        rename[src; dest]; 
        [cp[src;dest]; rm src; path.hsym dest]]
    }
// @fileOverview
// Opens a handle to a file path
// @param p {#filepath} Path of file to open
// @return {int} File descriptor of open handle
.z.m.axfs.open:{[p] hopen checkAccess path.resolve p}

// @fileOverview
// Returns the present working directory of this process
// @return {hsym} Current working directory
.z.m.axfs.pwd:{ path.hsym system "cd" }
.z.m.axfs.isPOSIX:not .z.o like "w*"
.z.m.axfs.isNT:.z.o like "w*"
.z.m.axfs.MAX_LINKS:1024
// @qlintsuppress MISSING_OVERVIEW(1) MISSING_RETURNS(1)
.z.m.axfs.onLoad:{
  
    
    base  : $[1 ~ "J"$.Q.opt[.z.x]`u; .z.m.axenv.path.startdir[]; ""];
    allow : $[count allow: getenv `AXFS_ALLOW_LIST; "," vs allow; ()];
    deny  : $[count deny:  getenv `AXFS_DENY_LIST ; "," vs deny ; ()];

    .z.m.axfs.checkAccess: $[any count each (base; allow; deny);
        i.access . path.unhsym@''(base; allow; deny);
        (::)];  
    
    }

.z.m.axfs.onLoad[];
system "d .z.m";

system "d .z.m.table";
// @fileOverview
// Inserts the given data into an existing table
//
// @example Adding Data to a Memory Table
// t: ([] x: til 3; y: "abc");
// r: ([] x: til 3; y: "mno");
// .z.m.table.add[t; r]
// /=> x y
// /=> ---
// /=> 0 a
// /=> 1 b
// /=> 2 c
// /=> 0 m
// /=> 1 n 
// /=> 2 o
//
// @example Adding Data to a Splayed On Disk Table
// .z.m.table.write[`:t/] ([] x: til 3; y: "abc"; z:`a`b`c);
// r: ([] x: til 3; y: "mno"; z: `x`y`z);
// .z.m.table.add[`:t/; r]
// /=> `:t/
//
// .z.m.table.read[`:t/]
// /=> x y z
// /=> -----
// /=> 0 a a
// /=> 1 b b
// /=> 2 c c
// /=> 0 m x
// /=> 1 n y
// /=> 2 o z
//
// @param t     {#handle}    Base table to upsert into
// @param data  {table}     Table to insert (must have matching schema as base)
//
// @returns {#handle} The updated table
.z.m.table.add:{[t; data] : i.dispatch[t;data;`i`add] }

// @fileOverview
// Upserts the given data into an existing table. If the handle provided
// is a reference to a table, the table will be updated in place. If the
// handle provided is a literal table, then a new table will be returned.
//
// @example Appending Data to a Memory Table
// t: ([] x: til 3; y: "abc");
// r: ([] x: til 3; y: "mno");
// .z.m.table.append[t; r]
// /=> x y
// /=> ---
// /=> 0 a
// /=> 1 b
// /=> 2 c
// /=> 0 m
// /=> 1 n
// /=> 2 o
//
// @example Appending Data to a Splayed On Disk Table
// .z.m.table.write[`:t/] ([] x: til 3; y: "abc"; z:`a`b`c);
// r: ([] x: til 3; y: "mno"; z:`x`y`z);
// .z.m.table.append[`:t/; r]
// /=> `:t/
//
// .z.m.table.read[`:t/]      
// /=> x y z
// /=> -----
// /=> 0 a a
// /=> 1 b b
// /=> 2 c c
// /=> 0 m x
// /=> 1 n y
// /=> 2 o z
//
// @param t     {#handle}    Base table to upsert into
// @param data  {table}     Table to upsert (must have matching schema as base)
//
// @returns {#handle} The updated table
.z.m.table.append:{[t; data] : i.dispatch[t; data;`i`append] }

// @fileOverview
// Wraps a table transformation function to preserve table
// attributes. The wrapped function must take a single argument,
// the table to be modified and must return a table. The 
// attributes of the input table are then applied to the output
// table if possible.
//
// @example Preserving Attributes
// t: ([] x: `s#til 5);
// meta t
// /=> c| t f a
// /=> -| -----
// /=> x| j   s
// 
// meta (::)@'t
// /=> c| t f a
// /=> -| -----
// /=> x| j
//
// meta .z.m.table.attrsupport[{(::)@'x}] t
// /=> c| t f a
// /=> -| -----
// /=> x| j   s
//
// @param fn {fn (table) -> table}
//
// @returns {fn (table) -> table} Function with attribute preservation
.z.m.table.attrsupport:{[fn]
    : {[fn; t]
        : {[t; m]
            : $[ ` ~ m`a; t;
                .[modify; (t; (); 0b; enlist[m`c]!enlist (#; enlist m`a; m`c)); t] 
                ];
            } over enlist[fn[t]], 0!schema t;
        }[fn]
    }

// @fileOverview
// Updates the names of the columns of table t to the new specified columns.
// This function maps the current names of a table to a new set of names.
//
// @example Renaming Columns
// t: ([] x: til 5; y: "abcde"; z: `AAPL`GOOG`MSFT`AMZN`YHOO);
// .z.m.table.column.map[t; `x`z!`a`b]
// /=> a y b   
// /=> --------
// /=> 0 a AAPL
// /=> 1 b GOOG
// /=> 2 c MSFT
// /=> 3 d AMZN
// /=> 4 e YHOO
//
// @param t     {#handle}   Handle of table to with columns to rename
// @param cmap  {dict}      Column map of old names -> new names
// 
// @returns {#handle} Table with columns remapped
//
// @throws Errors when source columns do not exist
.z.m.table.column.map:{[t; cmap]
    if[not all key[cmap] in\: cs:columns t; 
        '"column(s): ", (", " sv string key[cmap] except cs), " do not exist"
        ];
    
    : column.name[t] {(y;x y)[y in key x]}[cmap] each cs;
    }
// @fileOverview
// Updates the names of the columns of the given table to the new 
// list of column names. This renames the columns based on the index
// of the column name.
//
// @example Renaming Columns
// t: ([] x: til 5; y: "abcde"; z: `AAPL`GOOG`MSFT`AMZN`YHOO);
// .z.m.table.column.name[t; `a`b]
// /=> a b z   
// /=> --------
// /=> 0 a AAPL
// /=> 1 b GOOG
// /=> 2 c MSFT
// /=> 3 d AMZN
// /=> 4 e YHOO
//
// @param t       {#handle}   Handle of table to with columns to rename
// @param cnames  {symbol[]}  New column names based on index
// 
// @returns {#handle} Table with columns renamed
.z.m.table.column.name:{[t; cnames] 
    : $[cnames ~ columns t; t; i.dispatch[t; cnames; `i`column`name] ]
    }
// @fileOverview
// Reorders column names to the given order. This operates in the same way
// as xcols except with added support for on disk tables.
// 
// @example Reordering Columns
// t: ([] x: til 5; y: "abcde"; z: `AAPL`GOOG`MSFT`AMZN`YHOO);
// .z.m.table.column.order[t; `y`z`x]
// /=> y z    x
// /=> --------
// /=> a AAPL 0
// /=> b GOOG 1
// /=> c MSFT 2
// /=> d AMZN 3
// /=> e YHOO 4
// 
// @example Reordering Splayed Tables
// t: ([] x: til 5; y: "abcde"; z: `AAPL`GOOG`MSFT`AMZN`YHOO);
// .z.m.table.write[`:t/] t;
// .z.m.table.column.order[`:t/; `y`z`x];
// .z.m.table.read[`:t/]
// /=> y z    x
// /=> --------
// /=> a AAPL 0
// /=> b GOOG 1
// /=> c MSFT 2
// /=> d AMZN 3
// /=> e YHOO 4
//
// @param t         {#handle}    Handle of table to with columns to rename
// @param corder    {symbol[]}  New column order from left to right
// 
// @returns {#handle} Table with columns reordered
.z.m.table.column.order:{[t; corder] i.dispatch[t; corder; `i`column`order] }
// @fileOverview
// Returns a list of columns for a given table
// 
// @param t {#handle} Table to return the columns of
//
// @returns {symbol[]} Columns of the table
.z.m.table.columns:{[t] : i.dispatch[t;t;`i`columns] }
// @fileOverview
// Creates an empty table either on disk or in memory. If the table being created
// is partitioned then there is one record added so there is at least 1 partition.
//
// @example Creating an In Memory Table
// .z.m.table.create[::; (`x`int; `y`char; `z`symbol)]
// /=> x y z
// /=> -----
// 
// meta .z.m.table.create[::; (`x`int; `y`char; `z`symbol)]
// /=> c| t f a
// /=> -| -----
// /=> x| i    
// /=> y| c    
// /=> z| s    
//
// @example Creating a Splayed Table
// .z.m.table.create[`:t/; (`a`guid; `b`byte; `c`time; `d`symbol)];
// meta `:t/
// /=> c| t f a
// /=> -| -----
// /=> a| g    
// /=> b| x    
// /=> c| t    
// /=> d| s 
//
// @param t {#handle}                    Handle of table to create
// @param c {(symbol; symbol)}  Pairs of column names and types
//
// @returns {#handle} Handle of the newly created table
.z.m.table.create:{[t; c]
    
    if[11h ~ type c; 
        c: enlist c];

    cnames : first each c;
    types  : last each c;
    
    output: cnames!{$[x like "*s";`$-1_string x; `general ~ x;(); x]$()} each types;
    
    if[`part ~ format t;
        output: 1#/:output,(enlist t[2])!(type output@t[2])$enlist 0
        ];
    
    : .z.m.table.write[t] flip output;
    }

// @private
// @fileOverview
// Given a file handle, return if the it is a directory
//
// @param t {#handle} Handle to check
// 
// @returns {boolean} If the given handle is a directory on disk
.z.m.table.directory.is:{[t] 
    if[-11h ~ type t; 
        if[":" ~ first string t; 
            t: i.path t;
            : (11h ~ type k) & not t ~ k:key t
            ]
        ]; 
    : 0b 
    }

// @fileOverview
// Deletes from a table either in memory or on disk using a functional delete. 
// Please note that either columns or clause can be present but not both.
//
// @param t         {#handle}   Handle of table to delete columns from
// @param clause    {any[]}     A functional where clause or () for empty
// @param grp       {boolean}   Unused but part of the functional delete. (Use 0b)
// @param aggrs     {symbol[]}  The columns to delete or () for none
// 
// @returns {#handle} Handle of modified table
.z.m.table.drop:{[t; clause; grp; aggrs]
    
    hasClause:not () ~ clause;
    
    if[hasClause and not 0 ~ count aggrs; 
        '"rank: only clause or columns allowed in functional delete"
        ];
    
    if[hasClause; 
        : modify[t; clause; 0b; `symbol$()] 
        ];
    
    aggrs: $[-11h ~ type aggrs;
            enlist aggrs; 
        11h ~ type aggrs;
            aggrs; 
            '"type: expected symbols"
        ];
   
    : i.dispatch[t; aggrs;`i`drop];
    }
// @fileOverview
// Enumerates all symbols in a table 
//
// @param d {symbol | #hsym} Enumeration location
// @param t {table}          Table to enumerate
//
// @returns {table} The input table with all symbols enumerated
.z.m.table.enum:{[d; t]
    
    $[":" ~ first string d; h:` sv d,s:`sym; h: s: d];
     
    en: flip {[s;h;v]
        : $[i.enum v;
                [h?distinct x:$[11h ~ abs type v; v; get v]; s?x];
            (0h ~ type v) & all i.enum each 10#v; 
                .z.s[s; h] each v;
                v
            ];
        } [s; h] each flip t;
    
    .[set; (last ` vs h; @[get; h; {`$()}]); {x}];
    
    : en;
    
    }
// @fileOverview
// Compares two tables for equality and determines if the tables have the same data
//
// @param t0 {#handle} Base table to compare
// @param t1 {#handle} Other table to compare
//
// @returns {boolean} If the tables match
.z.m.table.equals:{[t0; t1]
    
    if[ format[t0] in `pmem`part;
        t1: sort.asc[query[t1;();0b;()]] pdb.format pdb.handle t0  
        ];
    
    if[ format[t1] in `pmem`part;
        t0: sort.asc[query[t0;();0b;()]] pdb.format pdb.handle t1
        ];
    
    : $[t0 ~ t1;
            1b;
        rows[t0] <> rows[t1];
            0b;
        not asc[columns t0] ~ asc columns[t1];
            0b;
        not asc[pkeys t0] ~ asc pkeys t1;
            0b;
            all {
                $[type[x] in 0 99h; all .z.s each x; all x]
                } each simplify[symbolize query[t0; (); 0b; ()]] =' simplify symbolize query[t1; (); 0b; ()]
        
        
        ];
    }




// @fileOverview
// Checks a table exists at the given handle
//
// @param t {#handle} Table to search for
//
// @returns {boolean} If the table exists
.z.m.table.exists:{[t]
    if[(() ~ t) | ` ~ t; : 0b];
    
    : .[i.dispatch; (t;t;`i`exists); 0b];
    }
// @fileOverview
// Given a file handle, return if the it is a file
//
// @param t {#handle} Handle to check
// 
// @returns {boolean} If the given handle is a file on disk
.z.m.table.file.is:{[t] 
    : $[-11h ~ type t; $[":" ~ first string t: i.path t; : t ~ key t; 0b]; 0b] 
    }

// @fileOverview
// Determines the type of a table using as a symbolic name. The possible
// table types are outline in the table below.
//
//
// |  Format   |      Description      |       Type        |             Example           |
// | --------- | --------------------- | ----------------- | ----------------------------- |
// | mem       | Memory by Value       | table             | `([] a: til 10)`              |
// | hmem      | Memory by Reference   | symbol            | `` `myTable``                 |
// | keyed     | Keyed Table           | keyed table       | `([k:til 10] v:10?10)`        |
// | serial    | Serialized Table      | symbolic handle   | `` `:mySerial ``              |
// | skey      | Serialized Keyed Table| symbolic handle   | `` `:myKeyedTable ``          |
// | splay     | Splayed Table         | symbolic handle   | `` `:mySerialTable ``         |
// | pmem      | Mapped Partitioned    | table             | `myPartTable`                 |
// | part      | Partitioned Table     | symbolic list     | ```` `:pdbRoot`table`pcol ````|
//
//
// @param t {#handle} A table handle to check the format of
//
// @returns {symbol} The symbolic name of the table or ` if unknown 
.z.m.table.format:{[t]
    p:type t;

    : $[
        99h ~ p;
            $[(98h ~ type key t) & 98h ~ type value t;
                `keyed;
                `
                ];
        98h ~ p; 
            $[qp:.Q.qp t; 
                `pmem;
              0b ~ qp;
                `smem;
                `mem
            ];
        
        -11h ~ p;
            $[file.is t; 
                i.htype t;
            directory.is t;
                $[sdb.is t; `splay; pdb.is t; `part; `];
            ":" ~ first str:string i.path t; 
                $["/" ~ last str; `splay; `serial];
                $[` ~ r:@[{.z.m.table.format get x}; t; `hmem]; 
                    `hmem; 
                  `mem ~ r; 
                    `hmem;
                    r
                    ]
                ];            
                
                
        11h ~ p;
            $[(2 ~ count t) &":"~first string t[1]; 
                `splay; 
            ":" ~ first string t[0];
                `part;
                `
                ];
        i.hasExtendedOptions t;
            .z.s first t;
        `
        ];
    }

// @private
//
// @fileOverview
// Takes a table, a set of additional parameters, and a function name.
// Determines the type of the table and dispatches to the appropriate function
//
// @param t {#handle} 
// The table to operate on can be the in memory table or a symbolic reference to it
// 
// Memory
// Either a table pass by value or a symbol that points to a table. The symbol
// cannot be a symbolic file handle or it will be assumed that it is on disk
//
// Serialized
// A single file handle symbol with no trailing slash
//
// Splayed
// A single file handle symbol with a trailing slash. If there are symbols 
// in this table then there must be an enumeration file associated with this table.
// If the file handle is passed by itself then the file is assumed to be in the
// defualt location. To specify a different location, pass an array of symbols
// where the first is the path to the table and the second is another file
// handle that points to the directory where the symbol file is stored
//
// Partitioned
// An array of symbols where the first is the path to the table. The second
// is the name of the table. Some operations require the partition column 
// for the table, this will always be the third parameter in the array.
// To specify a special sym file directory add a file path as the last parameter 
//
// @param args {any} Extra param(s) to pass to the dispatched function (in
// addition to the table, which is always passed).
//
// @param route {symbol[]}  The symbolic name of the function to call.
// This value can be specified as an array of symbols if the desired
// function is a sub module (ex. `i`create translates to .z.m.table.i.create)
//
// @returns {#handle} Depending on t
.z.m.table.i.dispatch:{[t; args; route]
    
    if[(` ~ t) | (() ~ t); : args];
    
    if[not (i.hasExtendedOptions t) or (type t) in -11 11 98 99h; '`type];
    
    if[` ~ fmt:format t;
        'raze "could not determine type: ",string t];

    lambda: @[{.z.m.table@/x};route,fmt; (::)]; 
    
    if[(::) ~ lambda;
        $[  fmt in `smem`pmem`keyed`skey;
                lambda: @[{.z.m.table@/x};route,$[`skey ~ fmt; `keyed; -11h ~ type t;`hmem; `mem]; (::)];
            
                '"nyi"
            ];
        
        ];
    
    if[(::) ~ lambda; '"nyi"];

    : $[ 99h < type r:lambda[t]; r[args]; r];
    }

// @private
//
// @fileOverview
// Reports if a vector has nested symbols that need to be enumerated.
//
// @param x {any[]} Any value
//
// @returns {boolean} If the input needs to be enumerated
.z.m.table.i.enum:{(i.is.enum[x] | 11h ~ type x) & not i.is.linked x}

// @fileOverview Return true if 't' is a overloaded list of a table + options
// This can be "compression" or "encryption"
// As of kdb+ 4.0, the format is: 
//  (target filename; logical block size; compression/encryption algorithm; compression level)
// With the digit 16 for example being "encrypt"
// @param t {#handle} 
// @returns {boolean}
.z.m.table.i.hasExtendedOptions:{[t] (count[t] > 0) and 0h = type t}

// @private
//
// @fileOverview
// Determines the type of a handle without reading it entirely into memory
//
// @param h {symbol} Symbolic handle to file
//
// @returns {symbol} Type of handle
.z.m.table.i.htype:{[h]
    header:first (enlist "x";enlist 1) 1: (h; 1; 3); 
    
    : $[0x0162 ~ 2#header;
            `serial;
        0x016362 ~ 3#header;
            `skey;
        0x0163 ~ 2#header;
            `dictionary;
        0x01 ~ first header;
            `general;
            `        
        ];
    
    }

// @private
//
// @fileOverview
// Checks the given input to determine if it is an enumerated
// vector or not
//
// @param x {any[]} Data to check
//
// @returns {boolean} If the input is an enumerated value
.z.m.table.i.is.enum:{type[x] within 20 76}
// @private
//
// @fileOverview
// Returns if the given data is an enumerated value that
// is linked to another table
//
// @param x {any[]} Data to check
//
// @returns {boolean} If the input vector is linked to another table
.z.m.table.i.is.linked:{$[i.is.enum x; 11h <> type get key x; 0b]}
// @private
.z.m.table.i.path:{:$[-11h ~ type x; `$ssr[;"\\";"/"] string x; x]}

// @fileOverview Return options given to set
//  Resolves the path component of the options
//  while preserving the extended options
//
// @example options
// .z.m.table.i.setOpts `foo
// /=> `foo
// .z.m.table.i.setOpts `:path/to/db`tablename`partition
// /=> `:path/to/db
// .z.m.table.i.setOpts (`foo;17;2;6)
// /=> (`foo;17;2;6)
// .z.m.table.i.setOpts (`:path/to/db`tablename`partition;17;2;6)
// /=> (`:path/to/db;17;2;6)
//
// @param x {#handle} 
// @returns {#handle}
.z.m.table.i.setOpts:{[x]
    if[i.hasExtendedOptions x;
        x[0] : path x;
        :x];
    :path x;
    
    }

// @private
//
// @fileOverview
// Trims the trailing slash from a given path
//
// @param x {symbol} Path to trim
//
// @returns {symbol} The trimmed path
.z.m.table.i.trim.slash:{"S"$ $["/" ~ last s: string x; -1 _ s; s]}

// @fileOverview
// A wrapper for .Q.ind to work with any table type
//
// @param t     {#handle}   Table to query to query
// @param inds  {long[]}    Desired indices from table
//
// @returns {table} A table that has only the desired indices
.z.m.table.index:{[t; inds]
    : $[0 < count inds: raze inds; i.dispatch[t;inds;`i`index]; query[t;enlist (=; `i; -1);0b;()]];
    }

// @fileOverview
// Returns the true indices of a table given a clause to search by
// 
// @example Querying Matches
// t: ([] x: til 3; y: "abc");
// .z.m.table.indices[t] enlist (in; `y; "ac")
// /=> 0 2
//
// @param t         {#handle}   Table to query
// @param clause    {any[]}     A functional where clause
//
// @returns {long[]} The true indices of the table that met the where clause
.z.m.table.indices:{[t; clause] : i.dispatch[t; clause;`i`indices] }
// @fileOverview
// Inserts into a table after a specific index. 
// > Note: This has only been implemented for memory tables
//
// @param t     {#handle}           Table to insert into
// @param data  {table | dict}      Data to insert
// @param n     {long}              Index to insert before
//
// @returns {#handle} Updated table
//
// @see insertAt
.z.m.table.insertAfter:{[t; data; n] : insertAt[t; data; 1 + n] }
// @fileOverview
// Inserts into a table after a specific index.
// > Note: This has only been implemented for memory tables
//
// @example Inserting Into a Table
// t: ([] x: til 4; y: "abcd"; z: `AAPL`GOOG`MSFT`AMZN);
// .z.m.table.insertAt[t; `x`y`z!(5; "e"; `YHOO); 4]
// /=> x y z   
// /=> --------
// /=> 0 a AAPL
// /=> 1 b GOOG
// /=> 2 c MSFT
// /=> 3 d AMZN
// /=> 5 e YHOO
//
// @example Inserting Multiple Times
// t: ([] x: til 4; y: "abcd"; z: `AAPL`GOOG`MSFT`AMZN);
// .z.m.table.insertAt[t; `x`y`z!(5; "e"; `YHOO); 1 2]
// /=> x y z   
// /=> --------
// /=> 0 a AAPL
// /=> 5 e YHOO
// /=> 1 b GOOG
// /=> 5 e YHOO
// /=> 2 c MSFT
// /=> 3 d AMZN
//
// @param t     {#handle}           Table to insert into
// @param data  {table | dict}      Data to insert
// @param n     {long}              Index to insert at
//
// @returns {#handle} Updated table
.z.m.table.insertAt:{[t; data; n] : i.dispatch[t; (data; n);`i`insertAt] }

// @fileOverview
// Inserts into a table before a specific index.
// > Note: This has only been implemented for memory tables
//
// @param t     {#handle}           Table to insert into
// @param data  {table | dict}      Data to insert
// @param n     {long}              Index to insert after
//
// @returns {#handle} Updated table
//
// @see insertAt
.z.m.table.insertBefore:{[t; data; n] : insertAt[t; data; -1 + n] }

// @fileOverview
// Add key support to a function that does not support keyed tables
// and returns a function
//
// @param fn {function} Function to add key support to
//
// @returns {function} An equivalent function that handles keyed tables
.z.m.table.keysupport:{[fn]
    : {[fn; t]
        if[format[t] in `skey`keyed;
            r:fn 0!data: read[t];
            k: ok where (ok:keys[data]) in\: cols r;
            : write[t] k xkey r
            ];
        : fn t
        }[fn];
    }

// @fileOverview
// Loads the symbol file and overwrites the already existing enumeration
//
// @param t {#handle} Handle of table to load symbol file for
//
// @returns {boolean} If the sym file was loaded successfully
.z.m.table.loadsym:{[t]
    : $[format[t] in `splay`part;
        not 0b ~ @[load; ` sv symdir[t],`sym; 0b];
        0b
        ];
    }
// @fileOverview
// Given the path to a table on disk, load it into q. Single-file tables are loaded
// fully into memory, all others are memory-mapped. The table object is stored in a
// global in the current context, and its name is returned.
//
// @param t {#handle} Table to map into memory
//
// @returns {symbol} The loaded table
.z.m.table.map:{[t] 
    fmt:format[t]; 
    : $[`part ~ fmt;
            [loadsym t; pdb.load t]; 
        `splay ~ fmt; 
            [loadsym t; sdb.load t];
        fmt in `serial`skey;
            write[.Q.id name[t]] read t;
            name t
        ]
    }
// @fileOverview
// Returns if the given table handle can be memory mapped
//
// @param t {#handle} Handle to table
//
// @returns {boolean} If the given table handle can be mapped into memory
.z.m.table.mappable:{[t]
    : format[t] in `part`pmem`splay`smem;    
    }

// @fileOverview
// Returns if a given table is mapped or not
//
// @param t {#handle} Table handle to check
//
// @returns {boolean} If the given table handle is mapped
.z.m.table.mapped:{[t] : $[`pt in key .Q; $[name[t] in .Q.pt; @[{.Q.ind[get x;"j"$()];1b}; name t; 0b]; 0b]; 0b]; } 

// @fileOverview
// Performs an update on the given table. This is equivalent to the q functional
// update except with added support for on disk tables.
//
// @param t         {#handle}           Handle of table to update
// @param clause    {any[]}             A functional where clause or () for no filter
// @param grp       {dict | boolean}    Functional group by statement or 0b for no grouping
// @param aggrs     {dict}              Update aggregations to apply
//
// @returns {#handle} The updated table
.z.m.table.modify:{[t; clause; grp; aggrs]
    if[(` ~ t) | () ~ t; : t];
    : i.dispatch[t; (clause; grp; aggrs); `i`modify]
    }

// @fileOverview
// Returns a symbol representing the name of this table.
//
// @param t {#handle} Handle of table to determine name of
//
// @returns {symbol} The name of this table
.z.m.table.name:{[t]
    fmt: format t;
    
    if[i.hasExtendedOptions t; :.z.s first t];
    
    if[fmt ~ `pmem;
        if[-11h ~ type n:value flip $[-11h ~ type t; get t; t]; 
            : n
            ]
        ];
    
    : $[fmt ~ `part;
            t[1];
        fmt in `splay`serial`skey; 
            `$last " " vs trim 1 _ ssr[string hsym first[t];"/";" "];
        -11h ~ type t;
            t; 
            `
        ]; 
    }

// @private
// @fileOverview
// Returns the names of all tables in the workspace
//
// @returns {symbol[]} The names of all tables in the ws
.z.m.table.names.all:{[start]

    tnames: raze {[ns]
        
        tnames: @[{$[`~x;tables `.;` sv/: x,/:tables x]}; ns;`];
        
        if[` ~ tnames; : tnames];
        
        options: $[11h ~ type k:key ns; 
            $[(` in k) | ` ~ ns; 
                k; 
                enlist `
                ]; 
            enlist ` 
            ];
        
        children: 1 _ ` sv/: ns,/: options;
        
        cdata: children!@[get;;`] each children;
        childns: where 99h = type each cdata;
        childns: where 0h  = (type value @) each childns#cdata;
        childns: where 11h = (type key @)   each childns#cdata;
        
        : raze tnames,.z.s each childns
        
        }[$[(::) ~ start; `; start]];
    
    : tnames where not ` = tnames
  
    }

// @fileOverview
// Returns the path to the given table.
// 
// @param t {#handle} Handle of table to determine path of
//
// @returns {#hsym} The location of the given table 
.z.m.table.path:{[t]
    fmt: format[t];
    
    if[i.hasExtendedOptions t; :.z.s first t];
    
    : i.path $[`part ~ fmt;
            first t;
        `splay ~ fmt;   
            .z.m.axfs.path.withSep first t;
        `pmem ~ fmt;
            `:.;
        `smem ~ fmt;
            value flip $[-11h ~ type t; get t; t];
        fmt in `serial`skey;
            t;
        11h ~ type t;
            first t;
            name t
        ];
    }

// @fileOverview
// Given a list of partitions as symbols, return the partition vector
// as the correct type
// 
// @param parts {symbol[]} The partitions to cast
//
// @returns {any[]} The partitions casted to the correct type
.z.m.table.pdb.cast:{[parts]
    : pdb.map[pdb.i.format parts]$string parts;
    }
// @fileOverview
// Returns the unfiltered contents of a partitioned database.
// This is a list of all partitions in the pdb regardless of
// them containing the desired table.
//
// @param t {#handle} Partitioned database handle
//
// @returns {symbol[]} All partitions in the database
.z.m.table.pdb.contents:{[t]
    : c where (c: key path t) like "[0-9]*"; 
    }

// @fileOverview
// Adds tables that are missing to a partitioned database.
//
// @param t {#handle} Handle to partitioned database 
//
// @returns {symbol[]} The splayed tables that were created
.z.m.table.pdb.fill:{[t]
    splays: pdb.shandle[t] each pdb.contents[t] except pdb.parts[t];
    : write[;take[first pdb.splays t;0]] each splays,\:symdir t
    }

// @fileOverview
// Determines the partition type given the path to the partitioned table. 
// The return is the name of the partition column.
//
// @param t {#handle} Partitioned database handle
// 
// @returns {symbol} One of `date`year`month`int
.z.m.table.pdb.format:{[t] 
    
    if[i.hasExtendedOptions t; :.z.s first t];
    
    : $[`pmem ~ f:format t;
            $[`pf in key `.Q; .Q.pf; `];
        f in `mem`keyed`hmem;
            first exec c from meta read t where a = `p;
        3 <= count t; 
            last t; 
            pdb.i.format pdb.parts t
        ] 
    }
// @fileOverview
// Returns a handle for a loaded partitioned table.
//
// @param t {#handle} Partitioned database handle
//
// @returns {symbol[]} The handle to the partitioned db
.z.m.table.pdb.handle:{[t]
    : ($[all `pd`pt in\: key `.Q; $[name[t] in .Q.pt; first .Q.pd; path t]; path t]; name t; pdb.format t)
    }
// @private
// @fileOverview
// Determines the format of a parititoned database given the 
// partition column.
// 
// @param parts {symbol[]} The partitions of the db
//
// @returns {symbol} Either `date`month`year or `int
.z.m.table.pdb.i.format:{[parts]
    if[0 = count parts; : `];
        
    str: string 20?parts;
    dots: count each where each "." =/: str;
    : $[all[2 = dots] & not any 0nd = "D"$str; 
            `date; 
        all[1 = dots] & not any 0nm = "M"$str; 
            `month;
        avg["J"$str] within 1000 9999; 
            `year;
            `int
        ] 
    }

.z.m.table.pdb.i.write:{[f; t; d]
    d: symbolize $[`pmem ~ format d; select from d; 0!read d];
    p: pdb.format t;
    g: group ?[d;();();p];
    e: enum[symdir t; ![d;();0b;enlist p]];
    {[f;t;e;p;x] f[pdb.shandle[t;p];e x]}[f;t;e]'[key g; g];
    :$[i.hasExtendedOptions t;first t; t];
    }

// @fileOverview
// Returns if the given handle is a partitioned database that
// exists in the current file system.
// 
// @param t {#handle} Partitioned database handle
//
// @returns {boolean} If the handle is a partitioned table
.z.m.table.pdb.is:{[t]
    handles: .Q.dd[first t] each key first t;
    dirs: handles where directory.is each handles;
    
    if[0 ~ count dirs; 
        : 0b];
    
    splays: raze dirs .Q.dd\:/: key first dirs;
    : $[0 ~ count splays; 0b; all sdb.is each splays]
    }
// @fileOverview
// Loads a partitioned database and returns the given table.
//
// @param t {#handle} Partitioned database handle
//
// @returns {symbol[]} The loaded tables
.z.m.table.pdb.load:{[t]
    system "l ", 1_string i.trim.slash path t;
    : .Q.pt;
    }

// @fileOverview
// Returns all of the partitions in this partitioned database.
//
// @param t {#handle} Partitioned database handle
//
// @returns {symbol[]} The partitions in this table
.z.m.table.pdb.parts:{[t] 
    : c where {(11h~type c) & y in c:key ` sv x,z}[path t; name t] each c:pdb.contents t
    }

// @fileOverview
// Reloads a partitioned database or if none are loaded
// then loads a new one.
//
// @param t {#handle} Partitioned database handle
//
// @returns {table} The partitioned table
.z.m.table.pdb.reload:{[t]
    n: name[t];
    if[n in tables system "d";
        system "l .";
        : get n
        ];
    pdb.load[t];
    : get n;
    }

// @fileOverview
// Creates a splayed table handle given a partitioned 
// table handle and the partition it is for.
//
// @param t {#handle}   Partitioned database handle
// @param p {symbol}    The partition this handle is for
//
// @returns {#handle} For the specific splay of the pdb
.z.m.table.pdb.shandle:{[t;p]
    r:` sv (path[t]; $[-11h~type p; p; 10h~type p; `$p; `$string p]; name[t]; `);
    if[i.hasExtendedOptions t;
        t[0]:r;
        :t];
    :r;
    }

// @fileOverview
// Returns the handles for all splays in a pdb.
//
// @param t {#handle} Partitioned database handle
//
// @returns {symbol[]} Handles to each splay in the pdb
.z.m.table.pdb.splays:{[t]
    : pdb.shandle[t] each pdb.parts t;
    }

// @fileOverview
// Returns the names of all tables in a partitioned database.
//
// @param t {#handle} Partitioned database handle
//
// @returns {symbol[]} All of the tables that exist in the given partitioned database
.z.m.table.pdb.tables:{[t]
    : distinct raze key each .Q.dd[path t] each pdb.contents t
    }

// @fileOverview 
// Returns the partition vector as its native q type.
//
// @param t {#handle} Partitioned database handle
//
// @returns {*} The partitions in the correct type
.z.m.table.pdb.vector:{[t]
    : asc pdb.cast pdb.parts t
    }

// @private
// @fileOverview
// Given the arguments to a query over a partitioned table, select only the indices of 
// the partitions that will be required for the given operation.
//
// @param t     {#handle}   Partitioned database handle
// @param args  {*[]}      The q parse tree for a functional select or update
//
// @returns {*[]} The indicies of the partitions that are needed for this query
.z.m.table.pdb.which:{[t; args]
    
    tab: flip enlist[pdb.format t]!enlist pdb.vector t;
    
    clause: {[pcol; acc; clause] 
        $[pcol in clause; acc,enlist[clause]; acc] 
        }[first cols tab] over enlist[()], first args;
    
    : ?[tab; clause; (); first cols tab];
    }

// @fileOverview
// Applies a primary key to a table. This is equivalent to `xkey` with
// added support for splayed tables.
//
// @param t {#handle}   Handle of table to apply keys to  
// @param k {symbol[]}  Key to apply
//
// @returns {#handle} Updated keyed table
.z.m.table.pkey:{[t;k] 
    : $[distinct[raze k] ~ pkeys t; t; (0 ~ count[k]) & k ~ `; t; i.dispatch[t;k;`i`pkey]] 
    }

// @fileOverview
// Return the primary keys from a table. This is the same as `keys`
// with added support for splayed tables.
//
// @param t {#handle} Handle of table to query
//
// @returns {symbol[]} Primary keys
.z.m.table.pkeys:{[t] : i.dispatch[t;t;`i`pkeys]; }

// @private
// @fileOverview
// Given a parse tree, replace all references of one symbol literal with another.
//
// @param tree  {*}         A q parse tree
// @param old   {symbol}    Symbol to replace
// @param new   {symbol}    New symbol
//
// @returns {*} The input with tree where all references to old replaced with new
.z.m.table.pts.replace:{[tree; old; new]
    
    : $[99h ~ p:type tree;
            : (.z.s[;old;new] each key tree)!.z.s[;old;new] each value tree;
       -11h ~ p;
            $[old ~ tree; new; tree];
        0h ~ p;
            .z.s[;old;new] each tree;
            tree
        ];
        
    }

// @private
// @fileOverview
// Given a parse tree for a functional select, determine the
// columns that the tree references.
//
// @param args {*[]} The q functional select parse tree 
//
// @returns {symbol[]} All of the column names referenced in the given q parse tree 
.z.m.table.pts.syms:{[args]    
    : distinct {[acc; tree]
        : $[0h ~ type tree;
                acc,.z.s over enlist[()],tree;
            -11h ~ type tree;
                acc,enlist[tree];
            99h ~ type tree;
                acc,key[tree], .z.s over enlist[()],value tree;
                acc
            ]
        } over enlist[()],args;
    
    }


// @fileOverview
// Selects the specified criteria from a table without loading the entire table
//
// @example Selecting From a Table
// t: ([] a: til 100; b: 100?100; c: 100?`5; d: 100?.Q.a)
// 
// /=>  a b  c     d
// /=>  ------------
// /=>  0 8  aapik j
// /=>  1 14 aoonc h
// /=>  2 50 genak g
// /=>  3 94 hbhif r
// /=>  4 24 fneig w
// /=>  ..
// 
// select c, d from t where a > 50, b < 80
// 
// /=> c     d
// /=> -------
// /=> ndkeb y
// /=> bimpc b
// /=> dlcel b
// /=> kepac e
// /=> chfbl q
// /=> ..
// 
// parse "select c, d from t where a > 50, b < 80"
// 
// /=> ?
// /=> `t
// /=> ,((>;`a;50);(<;`b;80))
// /=> 0b
// /=> `c`d!`c`d
// 
// ?[`t; ((>;`a;50);(<;`b;80)); 0b; `c`d!`c`d]
// 
// /=> c     d
// /=> -------
// /=> ndkeb y
// /=> bimpc b
// /=> dlcel b
// /=> kepac e
// /=> chfbl q
// /=> ..
// 
// .z.m.table.query[`t; ((>;`a;50);(<;`b;80)); 0b; `c`d!`c`d]
// 
// /=> c     d
// /=> -------
// /=> ndkeb y
// /=> bimpc b
// /=> dlcel b
// /=> kepac e
// /=> chfbl q
// /=> ..
//
// @param t         {#handle}           Handle of table to update
// @param clause    {any[]}             A functional where clause or () for no filter
// @param grp       {dict | boolean}    Functional group by statement or 0b for no grouping
// @param aggrs     {dict}              Select aggregations to apply
//
// @returns {table} The selected table
.z.m.table.query:{[t; clause; grp; aggrs]
    if[(` ~ t) | () ~ t; : t];
    : i.dispatch[t; (clause; grp; aggrs); `i`query] 
    }
// @fileOverview
// Returns the value of the given table handle. If the table 
// is by value then return the input otherwise get the table.
//
// @param t {#handle} Handle of table to read
// 
// @returns {table} Loaded data
//
// @see write
.z.m.table.read:{[t] : i.dispatch[t;t;`i`read] }

// @fileOverview
// Deletes a table from memory or on disk. For memory mapped tables, removing the 
// table will also delete the table by name from the calling context.
//
//!!! warning "Calling remove is a destructive operation and cannot be undone"
// 
// @param t {#handle} Handle of table to remove
// @returns {#handle} Handle of deleted table
.z.m.table.remove:{[t] : $[exists t; i.dispatch[t; (); `i`remove]; t] }

// @fileOverview
// Returns the count of a table either on disk or in memory. If the table is on disk
// then it calculates the size of the table without loading the entire table.
//
// @param t {#handle} Handle of table to count records of
//
// @returns {long} The number of records in the table
.z.m.table.rows:{[t] : $[() ~ t; 0; i.dispatch[t;t;`i`rows]] }
// @fileOverview
// Returns the q meta table for the given input.
//
// @param t {#handle} Handle of the table to retrieve the schema of
//
// @returns {table} Meta table pertaining to the given table
.z.m.table.schema:{[t] : i.dispatch[t;t;`i`schema] }

// @fileOverview
// Determines if the given handle is a splayed table.
// 
// @param t {#handle} Handle of table to check
//
// @returns {boolean} If the given handle is a splayed table
.z.m.table.sdb.is:{[t] : `.d in key t }

// @fileOverview
// Loads a splayed table and returns the table name.
//
// @param t {#handle} Handle of table to load
//
// @returns {symbol} Name of the loaded table
.z.m.table.sdb.load:{[t]
    system "l ", 1_string i.trim.slash path t;
    : name t;
    }

// @fileOverview
// Sets an attribute on columns(s) of a table.
//
// @param t     {#handle}           Handle of table to add attributes to
// @param attr_ {symbol}            Attribute to apply (`s`g`p or `u)
// @param col   {symbol| symbol[]}  Column name(s) to apply the attribute to
//
// @returns {#handle} Handle of updated table
.z.m.table.setAttr:{[t; attr_; col] 
    : modify[t; (); 0b; c!(#;enlist attr_),/: c:$[-11h~type col;enlist col;col]] 
    }
// @fileOverview
// Given a table convert all compound values into general lists
// where each element is a list of the standard, non-compound type.
//
// @param t {table} The table expand compound data from
//
// @returns {table} A table of the same shape with all compound columns simplified
.z.m.table.simplify:{[t] 
    if[format[t] ~ `pmem; : t];
    : .Q.ft[{flip {$[within[p:type x; 78 97h]; ("h"$p-77)$x;77h~p;abs[type first x]$x;x]} each flip x}] read t 
    }
// @fileOverview
// Sorts a table in ascending order on the column specified. 
// The table can either be in memory or on disk.
//
// @param t {#handle}   Table to sort in ascending order
// @param c {symbol}    Column to sort data on
//
// @returns {#handle} The sorted table
.z.m.table.sort.asc:{[t;c] : i.dispatch[t;c;`i`sort`asc]}
// @fileOverview
// Sorts a table in descending order on the column specified. 
// The table can either be in memory or on disk.
//
// @param t {#handle}   Table to sort in descending order
// @param c {symbol}    Column to sort data on
//
// @returns {#handle} The sorted table
.z.m.table.sort.desc:{[t;c] : i.dispatch[t;c;`i`sort`desc] }
// @fileOverview
// Given a table convert all of the enumerated symbolic columns into symbols.
//
// @param t {table} A table by value
//
// @returns {table} A table of the same shape with all enumerated columns converted to symbols
.z.m.table.symbolize:{[t] 
    if[format[t] in `pmem`smem; : t];
   
    syms: {[t]
        flip {[col]
            : $[type[col] within 20 76h;
                get col;
            (type[col] in 0 77h) & type[first col] within 20 76h;
                get each col; 
                col]
            } each flip t
        };
    
    : $[0 ~ rows t; t; .Q.ft[syms] read t]
    }

// @fileOverview
// Returns the path to the sym file directory for a splayed or partitioned table.
// 
// @param t {#handle} Table handle to return the handle of
//
// @returns {#handle} The path of the sym directory
.z.m.table.symdir:{[t]
    fmt: format[t];
    
    if[i.hasExtendedOptions t; :.z.s first t];
    
    : $[`part ~ fmt;
            i.path  hsym $[count[t] in 2 3; first; last]@t;
        `splay ~ fmt;
            hsym $[1 ~ count t; first ` vs `$-1_string i.path t;last i.path t];
        fmt in `smem`pmem;
            `:.;
        fmt in `keyed`skey`hmem`mem`serial;
            t;
            first ` vs `$-1_string path t
        ];
    }

// @fileOverview
// Takes the desired number of rows from a table with no repeat.
//
// @param t {#handle}   Table to select from
// @param n {long}      Number of records to take
//
// @returns {table} A table with n records
.z.m.table.take:{[t; n] 
    : $[0 > n; n#read t; i.dispatch[t; n; `i`take]] 
    }

// @fileOverview
// Removes any keys from a table. 
//
// @example Unkey a Table
// t: ([a: til 100; b: 100?100] c: 100?`5; d: 100?100.0)
// /=> a  b | c     d        
// /=> -----| ---------------
// /=> 0  30| fbach 94.52199 
// /=> 1  96| gokpi 70.92423 
// /=> 2  27| pkefa 0.2184472
// /=> 3  27| jjfjn 6.670537 
// /=> 4  21| cbnki 69.18339 
// /=> ..
//
// .z.m.table.unkey t
// /=> a  b  c     d        
// /=> ---------------------
// /=> 0  30 fbach 94.52199 
// /=> 1  96 gokpi 70.92423 
// /=> 2  27 pkefa 0.2184472
// /=> 3  27 jjfjn 6.670537 
// /=> 4  21 cbnki 69.18339 
// /=> ..
//
// @param t {#handle} Table to unkey
//
// @returns {#handle} An unkeyed table
.z.m.table.unkey:{[t] : i.dispatch[t; `; `i`unkey] }

// @fileOverview
// Returns a column from the given table as its content vector.
//
// @example Extract a Column From a Splayed Table
// // Create a table with some random data
// t: ([] a: til 100; b: 100?`5; c: 100?.Q.an; d: 100?10.0)
// 
// /=> a  b     c d        
// /=> --------------------
// /=> 0  agpmi S 1.780839 
// /=> 1  nfbcj P 3.017723 
// /=> 2  faebp Q 7.85033  
// /=> 3  klikn 8 5.347096 
// /=> 4  pjljc U 7.111716 
// /=> ..
// 
// // Write the data to a splayed on disk table
// .z.m.table.write[`:t/; t];
//
// // Extract the c column from the on disk table
// .z.m.table.vector[`:t/; `c]
// /=> "SPQ8Uvzx71g_N3uegQj.."
//
// @param t     {#handle}   Handle of table to read from
// @param col   {symbol}    Name of the column to return
//
// @returns {any[]} The desired column from t
.z.m.table.vector:{[t; col] : i.dispatch[t; col; `i`vector] }

// @fileOverview
// Similar behavior to `set`, `write` puts the given table data
// into the output location. If the output location is splaying data
// on disk, the output table will be automatically enumerated.
//
// @example Writing to a Splayed Table
// // Create a table with some random data
// t: ([] a: til 100; b: 100?`5; c: 100?.Q.an; d: 100?10.0)
// 
// /=> a  b     c d         
// /=> ---------------------
// /=> 0  bkljh T 5.078787  
// /=> 1  lainf r 6.978551  
// /=> 2  ocalh _ 9.352689  
// /=> 3  glnni Y 9.081387  
// /=> 4  dendh F 0.6839882 
// /=> ..
// 
// // Using .z.m.table.write will automatically enumerate symbols
// .z.m.table.write[`:t/; t];
//
// // Select from the splayed table is simple and can be done
// // by referencing the table path.
// select a, b, d from `:t where d > 1.0
// 
// /=> a  b     d       
// /=> -----------------
// /=> 0  bkljh 5.078787
// /=> 1  lainf 6.978551
// /=> 2  ocalh 9.352689
// /=> 3  glnni 9.081387
// /=> 5  fndlj 8.182305
// /=> ..
//
// @param t     {#handle}   Handle of output location
// @param table {table}     Table to write to disk
//
// @returns {#handle} Handle of the output table
.z.m.table.write:{[t; table] 
    : $[(() ~ t) | (::) ~ t;
            table;
        (`part ~ format t) & 2 ~ count t;
            '"no partition column specified"; 
            i.dispatch[t;table; `i`write]
        ] 
    }

.z.m.table.pdb.map:`date`month`year`int!"DMJJ" /dnl 
.z.m.table.i.write:(!) . flip (
    (`mem;      {y});
    (`hmem;     set);
    (`pmem;     { write[pdb.handle[x]] y });
    (`keyed;    {$[-11h~type x; x set y; y]} );
    (`serial;   { i.setOpts[x] set y });
    (`splay;    { i.setOpts[x] set enum[symdir x] symbolize read y});
    (`part;     {pdb.i.write[set; x; y]})
    )  
.z.m.table.i.vector:(!) . flip (
    (`mem;      {?[x; (); (); y]});
    (`hmem;     {?[x; (); (); y]});
    (`keyed;    {?[x; (); (); y]});
    (`pmem;     {?[;();();y] ?[$[-11h~type x;x:get x;x];();0b;c!c:$[pdb.format[x] in y; `i,y; raze y]]});
    (`serial;   {?[path x; (); (); y]});
    (`splay;    {?[path x; (); (); y]});
    (`part; 
        {[t; col]
            : raze $[col ~ t[2];
                (.z.m.table.rows each pdb.splays[t]) #' pdb.vector t;
                ?[;();();col] each pdb.splays[t]
                ]
            }
        )
    ) 
.z.m.table.i.unkey:(!) . flip (
    (`mem;      ![0]);
    (`hmem;     ![0]);
    (`keyed;    ![0]);
    (`skey;     {x set 0!get x});
    (`smem;     {x});
    (`pmem;     {x});
    (`serial;   {x});
    (`splay;    {x});
    (`part;     {x})
    ) 
.z.m.table.i.take:(!) . flip (
    (`mem;      { y#x });
    (`hmem;     { y#get x });
    (`pmem;     { t:$[-11h ~ type x; get x; x]; $[0 = y; ?[t;enlist (=;`i;-1);0b;()]; y = count t; t; y#.Q.ind[t] til min (y; count t)] });
    (`keyed;    { y#read x });
    (`serial;   { y#get path x});
    (`splay;    { y#get path x});
    (`part;     {[t; n]
        parts   : where n >= (+\) 0, -1 _ rows each s:pdb.splays t; 
        pcol    : flip enlist[pdb.format t]!enlist pdb.vector[t] parts;

        : n#raze pcol {key[x] xcols ![get y;();0b;x]}' s parts
        })
    ) 

.z.m.table.i.sort.desc:(!) . flip (
    (`mem;      {xdesc[y;x]});
    (`hmem;     {xdesc[y;x]});
    (`keyed;    {xdesc[y;x]});
    (`pmem;     {sort.desc[pdb.handle[x];y]});
    (`smem;     {xdesc[y; path x]});
    (`skey;     {path[x] set xdesc[y;get path x]});
    (`serial;   {path[x] set xdesc[y;get path x]});
    (`splay;    {xdesc[y;first path x]});
    (`part;     {$[pdb.format[x] in y;'"par";xdesc[y] each pdb.splays[x]];x})
    ) 
.z.m.table.i.sort.asc:(!) . flip (
    (`mem;      {xasc[y;x]});
    (`hmem;     {xasc[y;x]});
    (`pmem;     {sort.asc[pdb.handle[x];y]});
    (`smem;     {xasc[y; path x]});
    (`keyed;    {xasc[y;x]});
    (`skey;     {path[x] set xasc[y;get path x]});
    (`serial;   {path[x] set xasc[y;get path x]});
    (`splay;    {xasc[y;path x]});
    (`part;     {$[pdb.format[x] in y;'"par";xasc[y] each pdb.splays[x]];x})
    )
 
.z.m.table.i.schema:(!) . flip (
    (`mem;      meta);
    (`hmem;     meta);
    (`pmem;     {i.schema.part (path x;name x)});
    (`keyed;    meta);
    (`skey;     {meta get path x});
    (`serial;   {meta get path x});
    (`splay;    {meta path x});
    (`part;     
        {
            : (`c xkey enlist `c`t`f`a!(fmt; lower pdb.map fmt:pdb.format x; `; `)), meta last pdb.splays[x];
            }    
        )
    )

     
.z.m.table.i.rows:(!) . flip (
    (`mem;      count);
    (`hmem;     {count get x});
    (`smem;     {count $[-11h~type x; get x; x]});
    (`pmem;     {count $[-11h~type x; get x; x]});
    (`keyed;    {count read x});
    (`serial;   {count get path x});
    (`splay;    {count get ` sv path[x], first cols path x});
    (`part;     {$[() ~ s:sum .z.m.table.i.rows.splay each pdb.splays[x];0;s]})
    ) 
.z.m.table.i.remove:(!) . flip (
    (`mem;      { 0#x });
    (`hmem;     { ![$[1~count h:` vs x;system "d"; ` sv -1_h]; (); 0b; enlist last ` vs x];x});
    (`pmem;     { '"nyi" });
    (`smem;     { ![system "d"; (); 0b; enlist name x]; .z.m.axfs.rm path x; x}); 
    (`skey;     { .z.m.axfs.rm  path x; x}); 
    (`serial;   { .z.m.axfs.rm  path x; x}); 
    (`splay;    { ![system "d"; (); 0b; enlist name x]; .z.m.axfs.rm  path x; x}); 
    (`part;     { ![system "d"; (); 0b; enlist name x]; .z.m.axfs.rm  path x; x})
    ) 

.z.m.table.i.read:(!) . flip (
    (`mem;      {x} );
    (`hmem;     get );
    (`pmem;     {$[-11h~type x;get x;x]});
    (`keyed;    {$[-11h~type x;get x;x]});
    (`serial;   { get path x });
    (`splay;    { get path x });
    (`part; {[t]        
        : raze (flip enlist[pdb.i.format parts]!enlist pdb.cast parts:pdb.parts t) {key[x] xcols ![get y;();0b;x]}' pdb.splays t          
        })           

    )
 
.z.m.table.i.query:(!) . flip (
    (`mem;      { (?) . enlist[x],y });
    (`hmem;     { (?) . enlist[x],y });
    (`keyed;    { (?) . enlist[x],y });
    (`serial;   { (?) . enlist[path x],y });
    (`pmem;     { (?) . enlist[$[-11h~type x;get x; x]],y});
    (`splay;    { (?) . enlist[path x],y });
    (`part;
        
        {[t; args]
            
            args[2]: $[
                () ~ args[2];
                    $[99h ~ type args[1]; _[key args[1]]; ::] c!c:columns[t];
                    args[2]
                ];

            : raze {[fmt; t; args; ptn]
                : $[0 < count data: get pdb.shandle[t; ptn]; (?) . enlist[(enlist[fmt]!enlist ptn),/:data], args; ()];
                }[pdb.format t; t; args] each pdb.which[t; args]
            
            }
        )
    ) 
.z.m.table.i.pkeys:(!) . flip (
    (`mem;      keys);
    (`hmem;     keys);
    (`keyed;    keys);
    (`skey;     {keys get path x});
    (`serial;   {keys get path x});
    (`smem;     {`symbol$()});
    (`pmem;     {`symbol$()});
    (`splay;    {`symbol$()});
    (`part;     {`symbol$()})    
    ) 
.z.m.table.i.pkey:(!) . flip (
    (`mem;      {y xkey x});
    (`hmem;     {y xkey x});
    (`smem;     {x});
    (`pmem;     {x});
    (`keyed;    {y xkey x});
    (`skey;     {path[x] set y xkey get path x});
    (`serial;   {path[x] set y xkey get path x});
    (`splay;    {path x});
    (`part;     {x})
    ) 
.z.m.table.i.modify:(!) . flip (
    (`mem;          { (!) . enlist[x],y });
    (`hmem;         { (!) . enlist[x],y });
    (`smem;         { write[path x] (!) . enlist[read x],y });
    (`skey;         { write[x] (!) . enlist[get path x],y});
    (`serial;       { write[x] (!) . enlist[get path x],y });
    (`pmem;         { modify . enlist[pdb.handle x],y; pdb.reload[x] });
    (`splay;        
        {[t; args]
            h: path first t;
            year:month:date:int:last t;
            
            if[3~count t;t:-1_t];
            
            c:s where (s:pts.syms[args]) in\: columns[t];
                     
            cl: $[11h ~ type args[2];args[2];c!c];
            
            u:flip enum[symdir[t]] ![?[h;();0b;cl]; args[0]; args[1]; args[2]];
            
            if[99h ~ type args[2];
                d set distinct get[path d:` sv h,`.d],key args[2]
                ];
            
            key[u]{(` sv x,y) set z}[h]'value u;
            
            : t;
            });
    (`part; 
        {[t; args]
      
            if[99h ~ type args[2];
                $[  pdb.format[t] in key args[2];
                        '"par"; 
                    (not () ~ args[0]) and not all key[args[2]] in\: columns[t];
                        '"part";
                        1b
                    ]
                ];
            
            ws: pdb.which[t; args];
            handles: pdb.shandle[t] each ws;
            
            i.modify.splay[;args] each handles,'symdir[t],/:ws;
            
            
            : t;
            })
    )
 
.z.m.table.i.insertAt:(!) . flip (
    (`mem       ; { {y,x,z}[first y] over (0,last y) _ x});
    (`hmem      ; {x set {y,x,z}[first y] over (0,last y) _ get x});
    (`keyed     ; {'"nyi"});
    (`serial    ; {'"nyi"});
    (`splay     ; {'"nyi"});
    (`pmem      ; {'"nyi"});
    (`part      ; {'"nyi"})
    ) 
.z.m.table.i.indices:(!) . flip (
    (`mem;      { ?[x; y; (); `i] });
    (`hmem;     { ?[x; y; (); `i] });
    (`smem;     { ?[x; y; (); `i] });
    (`pmem;     { indices[ pdb.handle x; y] });
    (`keyed;    { ?[x; y; (); `i] });
    (`serial;   { ?[path x; y; (); `i] });
    (`splay;    { ?[path x; y; (); `i] });
    (`part;   
        {[t;clause]
            splays: pdb.splays[t];

            offsets: (+\) 0, -1 _ rows each splays;

            : raze offsets + ?[; clause; (); `i] each splays;
            }
        )
    ) 
.z.m.table.i.index:(!) . flip (
    (`mem;      { x[y] });
    (`hmem;     { get[x][y] });
    (`pmem;     { .Q.ind[$[-11h~type x;get x; x]; y] });
    (`keyed;    { key[t][y]!value[t:read[x]][y]});
    (`serial;   { get[path x][y]});
    (`splay;    { flip c!{ get[path ` sv x,z][y] }[x;y] each c:columns x });
    (`part;     
        {[t; inds]
            trueinds: 0,-1 _ (+\) rows each pdb.splays[t];
            bininds: trueinds bin inds;
            fmt: pdb.format[t];
            
            bins: neg[trueinds] + {[acc; rec]
                : @[acc;last rec;:;acc[last rec],enlist first rec];
                } over enlist[count[trueinds]#enlist `long$()],inds,'bininds;
            
            : raze pdb.vector[t] {[t;fmt;c;ptn;inds]
                flip (fmt,c)!ptn,{ get[` sv x,z][y] }[pdb.shandle[t;ptn];inds] each c
                }[t;fmt;columns[t] except fmt ]' bins;
            }
        )
    
    ) 
.z.m.table.i.exists:(!) . flip (
    (`mem;      {not (::) ~ x});
    (`hmem;     {$[98h ~ type t:get x; 1b; 99h ~ type t; (98 98h) ~ type each (key t; value t); 0b] });
    (`keyed;    {$[-11h~type x;not 0b ~ @[get; x; 0b];1b]});
    (`skey;     {path[x] ~ key path x});
    (`serial;   {path[x] ~ key path x});
    (`splay;    {`.d in key path x});
    (`part;     
        {
            $[0 < count key x[0];
                (0 < count s) & all {`.d in key x} each s:pdb.splays x;
                0b]
            }
        )
    
    ) 
.z.m.table.i.drop:(!) . flip (
    (`mem;      {![x; (); 0b; y]});
    (`hmem;     {![x; (); 0b; y]});
    (`keyed;    {![x; (); 0b; y]});
    (`pmem;     { drop . (pdb.handle x;();0b;y); pdb.reload[x] });
    (`smem;     {path[x] set ![x; (); 0b; y]});
    (`skey;     {path[x] set ![get path x; (); 0b; y]});
    (`serial;   {path[x] set ![get path x; (); 0b; y]});
    (`splay;
        { 
            x: path x;
            {$[x ~ key x; hdel x; `]} each ` sv/: x,/: raze { x,`$string[x],/:("#";"##") } each y;
            first ` vs  d set (get d:` sv x,`.d) except y
            }
        );
    
    (`part;
        {
            $[pdb.format[x] in y; 
                '"par: cannot delete partitioned column"; 
                .z.m.table.i.drop.splay[;y] each pdb.splays[x]
                ];
            :x;
            }
        )    
    
    )
 
.z.m.table.i.columns:(!) . flip (
    (`mem;      cols);
    (`hmem;     cols);
    (`keyed;    {cols read x});
    (`serial;   {cols get path x});
    (`splay;    {cols path x});
    (`part;     {pdb.format[x],$[0 ~ count s:pdb.splays x;`symbol$();cols last s]})
    )

 
.z.m.table.i.column.order:(!) . flip (
    (`mem;          {y xcols x});
    (`hmem;         {x set y xcols get x});
    (`pmem;         {column.order[pdb.handle[x];y]; pdb.reload[x]});
    (`keyed;        {$[-11h ~ type x; x set .Q.ft[xcols[y]] get x; .Q.ft[xcols[y]] x]});
    (`serial;       {path[x] set y xcols get path x});
    (`splay; 
        {
            $[all y in\: c:get d: path ` sv x,`.d; 
                first ` vs d set y,c except y; 
                '"column(s) do not exist: ", ", " sv string y except c
                ]
            }
        );
    (`part; 
        {
            $[not pdb.format[x] ~ first y; 
                '"par: cannot reorder the parition column"; 
                i.column.order.splay[;1_y] each pdb.splays[x]
                ];
            : x;        
            }
        )
    ) 
.z.m.table.i.column.name:(!) . flip (
    (`mem;          { y xcol x});
    (`hmem;         {x set y xcol get x});
    (`keyed;        {$[-11h~type x;x set y xcol get x;y xcol x]});
    (`serial;       {x set y xcol get path x});
    (`smem;         { i.column.name.splay[path x; y]; : pdb.reload[x]});
    (`pmem;         { i.column.name.part[pdb.handle x; y]; : pdb.reload[x]});
    (`splay;    
        {
            x: path x;
            c {[t; orig; new]
                if[(not orig ~ new) and not () ~ key ` sv t,orig;
                    dir:1 _ string[hsym t],"/";
                    
                    if[not () ~ key hsym `$ cmpfile: dir,string[orig],"#";
                        .z.m.axfs.mv[cmpfile; dir,string[new],"#"]
                        ];
                    
                    .z.m.axfs.mv[dir,string orig; dir,string new]
                    ]
                }[x]' colz: y,(count y) _ c: columns hsym x; 
            
            : first ` vs (` sv x,`.d) set colz
            });
    (`part;
         {
            $[  not pdb.format[x] ~ first y; 
                    '"par: cannot rename the parition column"; 
                    i.column.name.splay[;1_y] each pdb.splays[x]
                ];
            : x;
            }
        )
    )
 
.z.m.table.i.append:(!) . flip (
    (`mem;      {x upsert read y});
    (`hmem;     {x upsert read y});
    (`keyed;    {x upsert read y});
    (`pmem;     {append[pdb.handle x;y]});
    (`smem;     {path[x] upsert enum[symdir x] read y});
    (`serial;   {path[x] upsert read y});
    (`splay;    {path[x] upsert enum[symdir x] read y});
    (`part;     {pdb.i.write[upsert; x; y]})
    )
 
.z.m.table.i.add:(!) . flip (
    (`mem;      {x, read y});
    (`hmem;     {x set get[x], read y});
    (`pmem;     {add[pdb.handle x;y]});
    (`smem;     {add[path x;y]});
    (`keyed;    {x,read y});
    (`skey;     {$[0 = count read y; path x; x set get[path x], read y]});
    (`serial;   {$[0 ~ count read y; path x; x set get[path x], read y]});
    (`splay;    {$[0 ~ count read y; path x; x set get[path x], enum[symdir x] read y]});
    (`part;  
        {[t; data]
            if[0 ~ count data; : t];
            
            key[g]{[t; ptn; data]                
                $[exists h: pdb.shandle[t;first value ptn];  
                    insert[h] flip data;
                    h set flip data
                    ]
                }[t]'g:pdb.format[t] xgroup enum[symdir t] read data;
            : t;
            })
    )
 
.z.m.table.i.ENUM_TYPES:"h"$20+til 77-20 
.z.m.table.onLoad:{
    
    
    }

.z.m.table.onLoad[];
system "d .z.m";

system "d .z.m.axstr";
// @fileOverview Colour a string that will be printed to stdout
// @param c   {symbol} The colour to make the string - see i.COLOURS
// @param str {string} The string to colourize
// @returns   {string} The string with colourizing characters
.z.m.axstr.colour:{[c; str] 
    : $[not c in key i.COLOURS;
        str;
        i.COLOURS[c],str,i.COLOURS`clear];
    }
// @fileOverview
// Takes in a string and outputs a string with all the tabs replaced 
// with appropriate spacing using blanks only so as to preserve tabification
// as defined by the tab size specified
// @param str {String}
// @param tabSize {Long}
// @returns {String}
.z.m.axstr.detabify:{[str; tabSize]
    tab : "\t";
    size: count str;
    ii  : 0;
    new : "";
    lst : 0;	/* location of last non-tab
    while [ii < size;
        lst: (count new);
        $[  str[ii] = tab;
            new,: (tabSize  - (lst mod tabSize)) # " ";
            new,: str ii]; 
        ii +: 1];
    
    : new;
    }

// @fileOverview Sanitizes a user provided argument to the system command
// @param arg {string} The user input to sanitize
// @returns {string} The sanitized user input
.z.m.axstr.escape:{[arg]
    arg     : .z.m.axq.asString arg;
    quote   : $[.z.o like "w*"; "\""; "'"];
    escapes : $[.z.o like "w*"; ESCAPE_WIN; ESCAPE_NIX];
    
    arg: {[arg; e] ssr[arg; e[0]; e[1]] } over enlist[arg],escapes;
    : quote,arg,quote;
    }

// @fileOverview Takes a string and modifies it to remove any regexs that could be recognized by like or ss
// @param s {string} the original string
// @returns {string} the escaped string
.z.m.axstr.escapeRegex:{[s]
    sl : enlist each s;
    rp : where s in "[]*?";
    sl[rp] : "[",/:sl[rp],\:"]";
    : raze sl
    }

// @fileOverview 
// Sort strings, handling numbers semantically
// so values will be ordered "1", "2", "100", instead of "1", "100", "2" as in asciibetical sorting
// @param x {string[]}
// @returns {long[]} indicies of natural sort
.z.m.axstr.inatsort:{iasc {$[0=count x;"x"$x;?[null r;"x"$c;0x0 vs/:r:"J"$c:where[differ x in\:.Q.n]_x]]} each lower .z.m.axq.asString each x}

// @fileOverview
// Inserts a character or string at a given index
// 
//
// @param x {string} Base string to insert into
// @param y {string} String to insert
// @param z {long}   Index to insert at
//
// @returns {string} Updated string 
//
// @example
//
// .z.m.axstr.insertAt["all time"; " the"; 3]
// /=> "all the time"
//
.z.m.axstr.insertAt:{{y,x,z}[y] over (0, z) _ x}
// @fileOverview 
// Evaluate a string literal with one or more placeholders. The placeholders
// should be of the form {0}, {1}, ... {n}. Each placeholder will be replaced by
// the corresponding string in args.
//
// @param str {string} The string literal 
// @param args {string[]} A list of strings to inject into the placeholder
//
// @returns {string} The interpolated string
//
// @example
//      .z.m.axstr.interp["The {0} brown {1} jumped"] ("quick"; "fox");
//          => "The quick brown fox jumped"
.z.m.axstr.interp:{[str; args]
    e: (til count args),' enlist each args;
    : {[str; param]
        c: string param[0];
        v: .z.m.axq.asString param[1];
        
        if [v like "{*}"; '"Cannot interpolate string"];
        : ssr[str; "{",c,"}"; v];
        }/[str;e]
    }

// @fileOverview Return 1b if a string is valid UTF8
// @param text {String|char}
// @returns {Boolean}
.z.m.axstr.isValidUTF8:{[text]
    
    if [not `acceptAnything in key  .z.M.axstr.i; 
        compiled:.z.m.pcre2.compile[".?";`utf];
        i.acceptAnything:.z.m.pcre2.match[compiled;;::]];
    
    : (count i.acceptAnything .z.m.axq.asString text) >= 0;
    }

// @fileOverview
// Trims all types of whitespace from the front of a string. This 
// extends on the basic trimming from ltrim by trimming all characters
// in the list below
// 
// - tab
// - line feed
// - vertical tab
// - form feed
// - carriage return
// - space
//
// @param x {string} String to trim
//
// @returns {string} Trimmed string
.z.m.axstr.ltrimWhitespace:{[x]
    whitespace: `char$(9 10 11 12 13 32);				
    : $[0 = type x;   
            .z.s each x;
        .z.m.axq.isString x;  
            (sum &\[x in whitespace]) _ x;
            $[any x~/:whitespace;""; x]
        ];
    }


// @fileOverview Makes multiple replacements in a string
// Replacements take the form of 3-tuples (start index; end index; text)
// The replacement is from the start index to the position before end index with the text given
// If the start = the end, then it is just an insertion, not a replacement
// Insertions are always done after replacements, which is necessary,
// as (5 9 "replacement) would overwrite (5 5 ": ") if it were done the other way round
// @param text {String} The text that the replacements are occuring in
// @param toReplace {()} A list of the replacements
// @returns {String} The text with the replacements done
.z.m.axstr.multireplace:{[text; toReplace]
    
    : {[text;toReplace]
        (toReplace[0] # text) , toReplace[2] , (toReplace[1]) _ text
        }/[text; toReplace idesc toReplace[;0 1]];
    }

// @fileOverview 
// Sort strings, handling numbers semantically
// so values will be ordered "1", "2", "100", instead of "1", "100", "2" as in asciibetical sorting
// @param x {string[]}
// @returns {string[]}
.z.m.axstr.natsort:{ x inatsort x }

// @fileOverview
// Trims all types of whitespace from the end of a string. This 
// extends on the basic trimming from rtrim by trimming all characters
// in the list below
// 
// - tab
// - line feed
// - vertical tab
// - form feed
// - carriage return
// - space
//
// @param x {string} String to trim
//
// @returns {string} Trimmed string
.z.m.axstr.rtrimWhitespace:{:$[0 = type x; reverse each ltrimWhitespace reverse each x; reverse ltrimWhitespace reverse x]};
// @fileOverview 
// Strip all \r characters to change \r\n line-endings to \n line endings
// @param str {String} A string containing either \r\n or \n newlines
// @returns {String} A string using only \r\n newlines
.z.m.axstr.stripCR:{[str]
    : str where str <> "\r";
    }

// @fileOverview
// Returns a substring of the input
// 
// @param text  {string} The text to take a substring of
// @param start {number} The index to start the substring at
// @param end   {number} The index after the last one included in the substring
//  
// @returns {string} The substring
// 
// @example
// .z.m.axq.substring["A test of substring is a test"; 2; 6];
// /=> "test"
.z.m.axstr.substring:{[text; start; end]
    : start _ end # text;
    }
// @fileOverview
// Converts string data to lowercase text
//
// @param data {*} Data to convert to lowercase
// Data can be string or symbolic. Any other types
// will be ignored
//
// @returns {*} Lowercase version of input data  
.z.m.axstr.toLower:{[data]
    ty: abs type data;
    
    : $[ty in 10 11 87 88h; 
            lower data;
        ty in 0 77h;
            .z.s each data;
            data
        ];
    }

// @fileOverview
// Converts string data to titlecase text
//
// @param data {*} Data to convert to titlecase
// Data can be string or symbolic. Any other types
// will be ignored
//
// @returns {*} Titlecase version of input data
.z.m.axstr.toTitle:{[data]
    ty: type data;
    
    : $[ty in 11 88h; 
            "S"$.z.s each string data;
        -11h ~ ty;
            "S"$.z.s string data;
        10h ~ ty;
            raze {(upper[x 0],lower 1 _ x)} each (0,1 + where " " = data) _ data;
        -10h ~ ty;
            upper data;
        ty in 0 77 87h;
            .z.s each data;
            data
            ];
    
    }

// @fileOverview
// Converts string data to uppercase text
//
// @param data {*} Data to convert to uppercase
// Data can be string or symbolic. Any other types
// will be ignored
//
// @returns {*} Uppercase version of input data
.z.m.axstr.toUpper:{[data]
    ty: abs type data;
    
    : $[ty in 10 11 87 88h; 
            upper data;
        ty in 0 77h;
            .z.s each data;
            data
        ];
    }

// @fileOverview
// Trims all types of whitespace from the start and end of a string. This 
// extends on the basic trimming from trim by trimming all characters
// in the list below
// 
// - tab
// - line feed
// - vertical tab
// - form feed
// - carriage return
// - space
//
// @param x {string} String to trim
//
// @returns {string} Trimmed string
.z.m.axstr.trimWhitespace:{ltrimWhitespace rtrimWhitespace x}
// @fileOverview
// Truncate a string to a given number of characters, rather than a given number of bytes.
// This treats strings as UTF8, and counts multi-byte characters as single chars,
// as well as counting a character and any associated combining characters as a single character
//
// @param text {string} A string, which gets treated as UTF8
// @param maxLength {long} The number of characters that won't be truncated
// @returns {string} The truncated string
.z.m.axstr.truncate:{[text; maxLength]
    
    if [(maxLength ~ 0) or text ~ "";
        : ""];
    
    if [not `splitUTF8 in key  .z.M.axstr.i; 
         .z.M.axstr.i.splitUTF8 set {[x]
            :1_/:@[;`x0].z.m.pcre2.match["\\X"; x; ::];
            }];
    
    text: .z.m.axq.asString text;
    
    ranges: .z.m.axstr.i.splitUTF8 text;
    end: -1 + min (count ranges; maxLength);
    : ranges[end; 1]#text;
    }


.z.m.axstr.i.COLOURS:(!) . flip (
    (`black;  "\033[30m");
    (`red;    "\033[31m");
    (`green;  "\033[32m");
    (`yellow; "\033[33m");
    (`blue;   "\033[34m");
    (`purple; "\033[35m");
    (`cyan;   "\033[36m");
    (`white;  "\033[37m");
    (`clear;  "\033[0m")
    )


.z.m.axstr.ESCAPE_WIN:(
    ("\\\""; "");   // Remove \" as it will allow the use of & and other operators after it
    ("\""; "\"\"")  // Escape double quotes by using another one
    );
.z.m.axstr.ESCAPE_NIX:enlist
    ("'"; "'\\''") // Replace instances of ' with the escaped '\''
system "d .z.m";

system "d .z.m.axskia";
.z.m.axskia.convertColour:{[c]
    : $[SUPPORTS`integers;
        $[4h ~ type c; 0x0 sv c;  6h = abs type c; c;                            '"Unsupported colour format"];
        $[4h ~ type c; c;        -6h ~ type c; 0x0 vs c; 6h ~ type c; 0x0 vs' c; '"Unsupported colour format"]]
    }

// @fileOverview Throws an error if the input is not valid UTF8
// @param text {String|Symbol}
// @returns {null}
.z.m.axskia.errorOnInvalidUTF8:{[text]
    
    if [not .z.m.axstr.isValidUTF8 text;
        ' `InvalidUTF8];
    }

.z.m.axskia.SUPPORTS:`integers`pixmap`multigeom!111b;
// @qlintsuppress MISSING_OVERVIEW(1) MISSING_RETURNS(1)

([.z.m.axskia.init;.z.m.axskia.new;.z.m.axskia.delete;.z.m.axskia.addCircle;.z.m.axskia.addLine;.z.m.axskia.addDashedLine;.z.m.axskia.addPath;.z.m.axskia.addRect;.z.m.axskia.multiFillCircle;.z.m.axskia.multiStrokeCircle;.z.m.axskia.setFontFace;.z.m.axskia.i.addText;.z.m.axskia.i.addTextMiddleAnchor;.z.m.axskia.i.addTextLeftAnchor;.z.m.axskia.i.addTextRightAnchor;.z.m.axskia.setBackgroundColour;.z.m.axskia.i.setFillColour;.z.m.axskia.i.setStrokeColour;.z.m.axskia.setStrokeWidth;.z.m.axskia.toPNG;.z.m.axskia.setFontSize;.z.m.axskia.textWidth;.z.m.axskia.rotate;.z.m.axskia.restore;.z.m.axskia.multiFillRect;.z.m.axskia.multiStrokeRect;.z.m.axskia.multiLine;.z.m.axskia.multiFillPath;.z.m.axskia.multiStrokePath;.z.m.axskia.addPixels;.z.m.axskia.toRGB]):use`..skia;

.z.m.axskia.addText : {[skia; x; y; text]
    .z.m.axskia.errorOnInvalidUTF8 text;
    : i.addText[skia; x; y; text];
    };

.z.m.axskia.addTextMiddleAnchor : {[skia; x; y; text]
    errorOnInvalidUTF8 text;
    : i.addTextMiddleAnchor[skia; x; y; text];
    };
    
.z.m.axskia.addTextLeftAnchor : {[skia; x; y; text]
    errorOnInvalidUTF8 text;
    : i.addTextLeftAnchor[skia; x; y; text];
    };

.z.m.axskia.addTextRightAnchor : {[skia; x; y; text]
    errorOnInvalidUTF8 text;
    : i.addTextRightAnchor[skia; x; y; text];
    };

@[.z.m.axskia.init; .Q.rp "::../"; {}];
 
.z.m.axskia.setFillColour:   i.setFillColour;
.z.m.axskia.setStrokeColour: i.setStrokeColour;
            
system "d .z.m";

system "d .z.m.gg";
// @subcategory Data Abstraction
// @fileOverview 
// If given a table, return the table. If given a tbl.ty,
// return the proper subset of the table defined in the type.
// @param table {table|#.z.m.gg.tbl.ty}
// @returns {table}
.z.m.gg.tbl.apply:{[table]
    table : tbl.box table;
    if [h.null tbl.ty.index table;
        : tbl.unbox table];
    
    : .z.m.table.index[tbl.unbox table; tbl.ty.index table]
    }

// @subcategory Data Abstraction
// @fileOverview 
// Index into a table abstraction by relative index
// @param table {table|#.z.m.gg.tbl.ty} 
// @param indices {long[]} 
// @returns {table}
.z.m.gg.tbl.at:{[table; indices]
    table   : tbl.box table;
    indices : $[h.null tbl.ty.index table; indices; (tbl.ty.index table) indices];
    : .z.m.table.index[0!tbl.ty.raw table; indices];
    }

// @subcategory Data Abstraction
// @fileOverview 
// Box a table if it is not already boxed
// @param t {table|#.z.m.gg.tbl.ty}
// @returns {#.z.m.gg.tbl.ty}
.z.m.gg.tbl.box:{[t]
    : $[tbl.ty.is t; t; tbl.new t];
    }

// @subcategory Data Abstraction
// @fileOverview 
// Return the columns names of the table
// @param table {table|#.z.m.gg.tbl.ty} 
// @returns {symbol[]} column names
.z.m.gg.tbl.colnames:{[table]
    : cols tbl.unbox table;
    }

// @subcategory Data Abstraction
// @fileOverview 
// Return the column from a table at any indices specified by the abstraction
// @param table {table|#.z.m.gg.tbl.ty} 
// @param column {symbol} column name
// @returns {any[]} indexed column values
.z.m.gg.tbl.column:{[table; column]
    : $[tbl.ty.is table;
        [   val : h.column[tbl.unbox table; column];
            $[h.null ii:tbl.ty.index table; val; val ii]];
            h.column[table; column]];
    }

// @subcategory Data Abstraction
// @fileOverview 
// Return the indices of the visible table
// @param table {table|#.z.m.gg.tbl.ty} 
// @returns {long[]}
.z.m.gg.tbl.indices:{[table]
    table : tbl.box table;
    : $[h.null tbl.ty.index table; til count tbl.unbox table; tbl.ty.index table];
    }

// @subcategory Data Abstraction
// @fileOverview 
// Return the indices of a given value from a given table
// @param table {table|#.z.m.gg.tbl.ty} 
// @param column {symbol} 
// @param val {any}
// @returns {long[]}
.z.m.gg.tbl.indicesOf:{[table; column; val]
    table : tbl.box table;
    col   : tbl.column[table; column];
    : h.indicesOf[([]x:col); `x; val];
    }

// @subcategory Data Abstraction
// @fileOverview 
// Return whether a table is empty
// @param table {table|#.z.m.gg.tbl.ty} 
// @returns {boolean}
.z.m.gg.tbl.isempty:{[table]
    table : tbl.box table;
    : $[h.null tbl.ty.index table;
        0 = count tbl.unbox table;
        0 = count tbl.ty.index table];
    }

// @subcategory Data Abstraction
// @fileOverview 
// Return the meta for a table
// @param table {table|#.z.m.gg.tbl.ty} 
// @returns {table}
.z.m.gg.tbl.metainfo:{[table]
    : meta tbl.unbox table;
    }

// @subcategory Data Abstraction
// @fileOverview 
// Return the meta letter for a column in a table
// @param table {table|#.z.m.gg.tbl.ty} 
// @param column {symbol}
// @returns {char}
.z.m.gg.tbl.metatype:{[table; column]
    : h.metatype[tbl.unbox table; column];
    }

// @subcategory Data Abstraction
// @fileOverview 
// Create a new table abstraction from a source table
// @param raw {table}
// @returns {#tbl.ty}
.z.m.gg.tbl.new:{[raw]
    : tbl.ty.new (raw; ::; 1b);
    }

// @subcategory Data Abstraction
// @fileOverview 
// Return the count of the table
// @param table {table|#.z.m.gg.tbl.ty}
// @returns {long}
.z.m.gg.tbl.nrecords:{[table]
    table : tbl.box table;
    : $[h.null tbl.ty.index table; count tbl.unbox table; count tbl.ty.index table];
    }

// @subcategory Data Abstraction
// @fileOverview 
// Set the index list on the table abstraction with the given relative indices
// @param table {table|#.z.m.gg.tbl.ty} 
// @param index {long[]} 
// @returns {#.z.m.gg.tbl.ty}
.z.m.gg.tbl.rindex:{[table; index]
    table : tbl.box table;
    index : $[h.null tbl.ty.index table; index; (tbl.ty.index table) index];
    : tbl.ty.with.index[index; table];
    }

// @subcategory Data Abstraction
// @fileOverview Return whether a table is meant to be transformed or not
// @param table {table|#tbl.ty} 
// @returns {boolean} 
.z.m.gg.tbl.transform:{[table] tbl.ty.transform tbl.box table }

// @subcategory Data Abstraction
// @fileOverview 
// Get the source table out of an abstraction
// @param table {table|#.z.m.gg.tbl.ty} 
// @returns {table}
.z.m.gg.tbl.unbox:{[table]
    : $[tbl.ty.is table; tbl.ty.raw table; table];
    }

// @subcategory Data Abstraction
.z.m.gg.tbl.onLoad:{[]
    
    
    .z.m.axdatatype.create[ .z.M.gg.tbl.ty; `raw`index`transform; `index`transform];
    
    }

.z.m.gg.tbl.onLoad[];
system "d .z.m";

system "d .z.m.axutl";
// @fileOverview
// Check if a version is above or below a required version
//
// @param m {symbol} `` `min `` or `` `max ``, implies which check will be used
// @param required {string} The required version ("x.x.x")
// @param given {string} The given version ("x.x.x")
//
// @returns {null}
.z.m.axutl.checkVersion:{[m; required; given]
    required : "J"$ "." vs required;
    given    : "J"$ "." vs given;
    comp     : $[`min ~ m; (>;<); (<;>)];
    k        : 0;
    
    if[any 3 <> count each (required;given); 'string[m],"Version malformed, should be in the format X.X.X"];

    while[k<3;
        if [comp[0][given[k]] required k; : 1b];
        if [comp[1][given[k]] required k; : 0b];
        k+:1];
    
    : 1b;
    }

// @fileOverview decodes a base64 encoded string
// For details on base64 see: http://en.wikipedia.org/wiki/Base64
// @param x {String} The string to decode
// @returns {String} The base64 decoded string
.z.m.axutl.decode64:{[x]
    
    if [x ~ "";
        : ""];
    
    encoding : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"!(til 64); /dnl
    exponents: {2 xexp x} each (18; 12; 6; 0);
     
    str1: `int$sum each (encoding each (4 cut x)) *\: exponents;
    str : raze reverse each `char$flip (1 256 65536) {(y div x) mod 256}\: str1;

    pad : count where ("=" = reverse [x] [til 3]);
    : (neg pad)_str;
    }

// @fileOverview encodes a string using base64 encoding
// For details on base64 see: http://en.wikipedia.org/wiki/Base64
// @param x {String} The string to encode
// @returns {String} The base64 encoded string
.z.m.axutl.encode64:{[x]
    
    if [x ~ "";
        : ""];
    
    encoding : (til 64)!"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"; /dnl

	
    pad : (0; 2; 1)[(count x) mod 3];
  
    exp1 : (65536; 256; 1); 
    bits : sum each ((each [`int$] 3 cut x,(pad#"")) *\: exp1);
    exp2 : (1; 64; 4096; 262144); // 2 xexp (0; 6; 12; 18);
    bytes: reverse (bits div/: exp2) mod 64; // {(x div y) mod 64}/: exponents;
    str  : raze flip encoding [bytes];
  
    if [pad = 1; 
        str [(count str) - 1]: "="];
    
    if [pad = 2; 
        str [(count str) - (1 2)]: "="];
	
    : str;
    }
// @fileOverview 
// Run a system command safely, sanitizing and escaping user inputs. Note that this means
// that relative paths won't work as expected, and will be taken literally
//
// @param cmd {string} The command to inject the sanitized arguments into
// @param args {string[]} The arguments to sanitize and inject into the command
// @returns {*} The output of the system command
// 
// @example
//      .z.m.axutl.execute["ls {0}"] enlist "~";  
//          => runs system "ls '~'"
//
//      .z.m.axutl.execute["cp {0} {1}"] ("/tmp/test.file"; "/tmp/new/"); 
//          => runs system "cp '/tmp/test.file' '/tmp/new/'"
//
//      .z.m.axutl.execute["ls {0}"] enlist "'; echo \"unsafe!\"; '"
//          => runs system "ls ''\\''; echo \"unsafe!\"; '\\'''"
//
.z.m.axutl.execute:{[cmd; args]
    args: .z.m.axstr.escape each args;
   
    safe: .z.m.axstr.interp[cmd; args];

    : system safe;
    }

// @fileOverview Retrieves the literals from a function, regardless of kdb version
// @param fn {function}
// @returns {any[]} 
.z.m.axutl.getFuncLiterals:{[fn]
    :$[.z.K > 3.4;-5;-1]_4_value fn
    }

// @fileOverview
// Takes a symbol representing an object in the namespace and 
// extracts its context
//
// @example 
// .z.m.axutl.getNS `.abc.def
// /=> `.abc
//
// @example works for root context
// .z.m.axutl.getNS `abc.def
// /=> `.
//
// @param data {symbol | symbol[]} Symbols and symbol lists
//
// @returns {symbol | symbol[]} The context
.z.m.axutl.getNS:{[data]
    if[11h <> abs type data;'"type"];
    if [wasAtom:.z.m.axq.isSymbol data;
        data:enlist data];
    root: where not data like ".*";
    ctx: ` sv/: 2#/:` vs/: data;
    ctx[root]:`.;
    :$[wasAtom;first;::] ctx
    }
// @fileOverview
// Generates globally unique ids without overlap even when called
// in quick succession. This function circumvents the kdb+ issue
// where invoking `-1?0ng` in rapid succession results in duplicate
// ids.
// @param n {long} Number of ids to generate
// @return {guid[]} Globally unique ids
.z.m.axutl.guid:{[n] 
    delete from  .z.M.axutl.i.guids where time < .z.p - 0D00:00:01.000;
    cache : raze i.guids`guids;
    size  : abs n;
    n     : neg size; // ensure n is negative
    ids   : ();

    while[size > count ids; ids,:(n?0ng) except cache];
    ids: size#ids; // we may generate more than the required number of ids, drop the rest
    
     .z.M.axutl.i.guids upsert `time`guids!(.z.p; ids); 
    
    : ids;
    }

// @private
// @fileOverview Heuristic that determines whether or not files are binary.
// Git already provides this for files it controls. We provide this for workspace entities (i.e uncommited revisions)
// using the same algorithm implemented in q instead of c.
// Note libgit2 and native git differ in how the compute what is binary. Git only check if  files contain a null in the first 8000 bytes
// @param c {string[]}
// @returns {boolean[]}
.z.m.axutl.isBinary:{[c]
    co:count each c;
    co[where co > 8000] : 8000;
    ci:co#'c;
    
    hasNull:(`byte$0) in/: ci;
    
    
    allowlist:`byte$"\n\t\r";
    v:(allowlist[0] = ci) or (allowlist[1] = ci) or (allowlist[2] = ci)
        or
        (ci <> 0x7f) and (ci > 0x1f) and not hasNull;
    printable:sum each v;
    nonprintable: co - printable;
    
    :(printable % 128) < nonprintable;
    }

// @fileOverview Tokenizes the input and strips comments
// @param text {String} A string of q code
// @returns {String[]} The token list
.z.m.axutl.tokenize:{[text]
    
    parsed: -4!text;
    
    cmtInd: where ((1 < count each parsed) & parsed[;0] in "/ \t\n") & not  parsed ~\: "/:";
    
    parsed[cmtInd] : (parsed[cmtInd]?\:"/")#'parsed[cmtInd];

    :parsed where (0 <> count each parsed)
    }
.z.m.axutl.METATYPES:" bgxhijefcCspmdznuvt"!`general`boolean`guid`byte`short`int`long`real`float`char`compoundChar`symbol`timestamp`month`date`datetime`timespan`minute`second`time /dnl
.z.m.axutl.onLoad:{[]
 
    i.guids: ([] time: `timestamp$(); guids: ());
    
    }

.z.m.axutl.onLoad[];
system "d .z.m";

system "d .z.m.gg";
// @fileOverview 
// Short-circuiting "and"
// @param d {any} 
// @param fx {fn} first function against d 
// @param fy {fn} second fn against d (only run if fx[d] is true) 
// @returns {bool} 
.z.m.gg.h.and:{[d; fx; fy]
    if [fx d; if [fy d; : 1b]];
    : 0b;
    }

// @fileOverview 
// Apply a list of functions to a list of lists of arguments for each functions
// @param fs {fn[]} 
// @param xs {any[][]} 
.z.m.gg.h.applyeach:{[fs; xs]
    fs .' flip xs
    }

// @fileOverview 
// Find the arity of a function
// @param f {fn} 
// @returns {long} arity 
.z.m.gg.h.arity:{[f]
    : count (value f) 1
    }

.z.m.gg.h.asString:{[data]
    : $[0 ~ count data;             "";
        0 ~ type data;              .z.s each data;
        -10h ~ type data;           string data;
        10h ~ type data;            data;
        type[data] within 0 96;     .z.s each data;
                                    string data ]
    }

// @fileOverview 
// Throw an error if a column cannot be found in the table
// @param table {table} 
// @param col {symbol}
// @throws "column x not found"
// @throws "column argument must be a symbol"
.z.m.gg.h.assert.colExists:{[table; col]
    table : tbl.box table;
    if [not -11h ~ type col;
        '"Invalid bin configuration: " , .z.m.axlocalize.t`.gg_colNotSymbolError];
    if [not col in tbl.colnames table;
        '"Invalid bin configuration: " , .z.m.axlocalize.t(`.gg_colNotFoundError;string col)];
    }

// @fileOverview 
// Throw an error if the column type is not one of the valid types
// @param validTypes {char[]} 
// @param table {table} 
// @param col {symbol} column name
// @throws "column x of type y is not one of z"
.z.m.gg.h.assert.colType:{[validTypes; table; col]
    table    : tbl.box table;
    metatype : tbl.metatype[table; col];
    if [not metatype in validTypes;
        '.z.m.axlocalize.t(`.gg_colTypeMismatch; `column`found`expected!(string col; string h.METATYPES metatype; h.niceTypeStr validTypes))];
    }

// @fileOverview 
// Index into a list of dictionaries at a common key
// @param k {symbol} key 
// @param ds {dict[]} 
.z.m.gg.h.atAll:{[k; ds]
    : ds @\: k
    }

.z.m.gg.h.b64:{[x]
    encoding : til[64]!.Q.b6;
    pad  : 0 2 1 count[x] mod 3;
    exp1 : 65536 256 1;
    bits : sum each (3 cut x,pad#0x20) *\: exp1;
    exp2 : 1 64 4096 262144;
    bytes: reverse (bits div/: exp2) mod 64;
    str  : raze flip encoding bytes;
    
    if [pad = 1;  str [(count str) - 1     ]: "="];
    if [pad = 2;  str [(count str) - 1 2 ]: "="];
	
    : str;
    }

// @fileOverview 
// Return a list of bad indices (positions of nulls/infinities) in position columns
// @param aes {dict}
// @param scales {dict}
// @param pos {table} position table
// @returns {long[]} list of bad indices that should be removed from the table when displaying
.z.m.gg.h.badpos:{[aes; scales; pos]
    scales : (scales@\:`label) key[aes] group first reverse (key;value)@\:aes;
    
    : (union/) {[x;y;z]
            : "j"$$[(not x in "bxhijefpmdznuvt") or `categorical in z;
                ();
                (union) . ('[where;null]; h.infPos) @\: y]; // union of nulls and infinities
            }'[tbl.metatype[pos] each cols pos; pos cols pos; scales cols pos];
    }

// @fileOverview 
// Return the full column from a table
// @param table {table} 
// @param col {symbol} 
.z.m.gg.h.column:{[table; col]
    : $[not -11h ~ type col;
            (count table)#col;
        not col in cols table;
            (count table)#col;
            .z.m.table.vector[table; col]];
    }

// @fileOverview Consolidate a list of data to conforming types if possible
// @param data {any[]} 
// @returns {any[]}
.z.m.gg.h.consolidateTypes:{[data]
    if [all (ts:type each data) within 4 9h;
        data: max[(4 5 6 7 8 9h!4 5 6 7 9 9h) ts]$data];
    
    : data
    }

// @fileOverview Decode base 64 encoded string
.z.m.gg.h.d64:{[x]
    : "c"$except[;0x00]0b sv'{x where 8=count'[x]}0N 8#raze 2_'0b vs'"x"$.Q.b6?x except"="
    }

// @fileOverview
// xasc for settings dictionaries
// Sorts a dictionary in ascending order such that each list in the dictionary 
// is sorted by the given field's order (like a table), and atomic values are left unchanged
// @param k {symbol} key to sort by 
// @param d {dict} 
// @returns {dict} Sorted dictionary
.z.m.gg.h.dictAsc:{[k;d]
    : @[d; where 0h <= type each d ;@[;iasc d k]];
    }

// @fileOverview 
// Access records in a settings dictionary like a table
// If i is atomic, the dictionary returned contains all atomics
// If i is a list, the dictionary returned contains the same atomics, and the lists contain
// values from the given lists at the given indices.
// @returns {dict}
.z.m.gg.h.dictAt:{[d;ii]
    : @[d;where 0h <= type each d;@[;ii]];
    }

// @fileOverview
// xdesc for settings dictionaries
// Sorts a dictionary in descending order such that each list in the dictionary 
// is sorted by the given field's order (like a table), and atomic values are left unchanged
// @param k {symbol} key to sort by 
// @param d {dict} 
// @returns {dict} Sorted dictionary
.z.m.gg.h.dictDesc:{[k;d]
    : @[d; where 0h <= type each d ;@[;idesc d k]];
    }

// @fileOverview 
// If the argument is a symbol, enlist it
// @param x {any} 
.z.m.gg.h.enlistIfSymbol:{[x]
    $[-11h ~ type x; enlist x; x]
    }

// @fileOverview 
// Extend the left argument dict with default options from the right argument
// (prefers left)
// @param extended {dict} 
// @param extender {dict} 
.z.m.gg.h.extend:{[extended; extender]
    if [h.null extended;
        extended : ()!()];
    : extender , extended;
    }

// @fileOverview Find values within a categorical list
// @param v {any[]} 
// @param x {any[]} values to find in v
// @returns {long[]} index of first position of each value
.z.m.gg.h.findCat:{[v;x] $[type[v] within 1 19h; v?x; (first where@) each x ~/:\: v] }

.z.m.gg.h.geojson.linetable:{[file]
    json         : .j.k raze read0 file;
    featureTable : json`features;
    collapsed    : {(`properties`geometry`type _ x) , x[`properties] , x`geometry} each featureTable;
    polys        : ?[collapsed;enlist (like;`type;"LineString");0b;()];
    polys        : update id:til count polys, lon : first each/: coordinates, lat: last each/: coordinates from polys;
    polys        : ungroup `id xkey select id, lon, lat from  polys;
    multipolys   : ?[collapsed;enlist (like;`type;"MultiLineString");0b;()];
    multipolys   : ungroup `id xkey raze { flip `id`lon`lat!y,(first each/:;last each/:)@\: x`coordinates} '[ multipolys;count[polys]+til count multipolys];
    : multipolys , polys;
    }

.z.m.gg.h.geojson.polytable:{[file]
    json         : .j.k raze read0 file;
    featureTable : json`features;
    collapsed    : {(`properties`geometry`type _ x) , x[`properties] , x`geometry} each featureTable;
    polys        : ?[collapsed;enlist (like;`type;"Polygon");0b;()];
    polys        : update lon : first each first each coordinates, lat: last each first each coordinates from polys;
    polys        : (`type`coordinates _ polys) ,' {`lon`lat!(first each;last each) @\: first x`coordinates} each polys;
    multipolys   : ?[collapsed;enlist (like;`type;"MultiPolygon");0b;()];
    multipolys   : raze {(`coordinates`type _ x) ,/: flip `lon`lat!(first each;last each)@\:(first each;last each)@\:/:first each x`coordinates} each multipolys;
    : multipolys , polys;
    }
// @fileOverview 
// Return the indices of matching elements from a column
// @param t {table} 
// @param x {symbol} col name 
// @param xval {any} value to match on
// @returns {long[]} indicies of xval in t[x]
.z.m.gg.h.indicesOf:{[t; x; xval]
    match: $[(0h <= type xval) | not h.metatype[t;x] in .Q.a; ~\:; =];
    enlistIfGeneric: {$[0=type x;enlist x;x]};
    : .z.m.table.indices[t; enlist (match; x; enlistIfGeneric h.enlistIfSymbol xval)];
    }

// @fileOverview 
// Find the positions of infinities in the given vector
// @param vector {any[]} 
// @returns {long[]} 
.z.m.gg.h.infPos:{[vector]
    kind : h.METATYPES tbl.metatype[([]x:vector); `x];
    : $[kind in key h.INFINITY;
        where (h.INFINITY[kind] = vector) or neg[h.INFINITY kind] = vector;
        `long$()];
    }

// @fileOverview
// Inverse Mercator projection
// @param isLatitude {boolean} Lat and long are projected differently
// @param data {number[]} The latitude or longitude data
.z.m.gg.h.invMercator:{[isLatitude; data]
    PI  : 3.14159265359;
    W   : 820;
    H   : 820;
    : $[not isLatitude;
        (360 * data % W) - 180;
        (360 * (atan exp ((2 * PI) * data - H - H % 2) % W) - PI % 4) % PI];
    }
// @fileOverview 
// Get the pixel width of the widest string in the given list
// @param fontsize {long} 
// @param text {char[][]} list of strings to measure 
// @returns {long} width of the widest text 
.z.m.gg.h.maxTextWidth:{[fontsize; text]
    : max h.textWidth[fontsize; text]
    }

// @fileOverview
// Mercator projection
// @param isLatitude {boolean} Lat and long are projected differently
// @param data {number[]} The latitude or longitude data
.z.m.gg.h.mercator:{[isLatitude; data]
    
    W : 820f;
    H : 820f;
    
    if [9 <> abs type data;
        data : `float$data];
    
    $[  not isLatitude;
        
        data : (W % 360) * 180 + data;
        
        [   latIsList : .z.m.axq.isList data;
    
            $[  latIsList;
                [   data[where data >= 90] : 89.9999;
                    data[where data <= -90] : -89.9999];
                [   if [data >=  90; data: 89.9999];
                    if [data <= -90; data: -89.9999]]];

            PI      : 3.14159265359;
            data    : log tan (PI % 4) + data * PI % 360;
            data    : (H % 2) + data % 2 * PI % W;

            $[  latIsList;
                [   data[where data = 0w] : 0f;
                    data[where data = -0w]: H];
                [   if [data = 0w;  data: 0];
                    if [data = -0w; data: H]]]]];
    
    : data;
    }
// @fileOverview 
// Return the meta type associated with a column of a table
// @param table {table} 
// @param col {symbol} 
.z.m.gg.h.metatype:{[table; col]
    table: tbl.unbox table;
    : $[not -11h ~ type col;
            meta[([]x:raze col)][`x]`t;
        not col in cols table;
            meta[([]x:raze col)][`x]`t;
            meta[table][col]`t];
    }

// @fileOverview 
// Returns a nicely formatted/readable string describing a list of types
// given the types by their meta-code
// @param types {char[]} types
// @returns {char[]} formatted string
.z.m.gg.h.niceTypeStr:{[types]
    
    if [any 0 1 = count types;
        : raze h.asString h.METATYPES types];
    
    str : ();
    
    if [all (ns:"bxhijef") in\: types; /dnl
        str,: enlist .z.m.axlocalize.t`.gg_numeric;
        types : types except ns];

    if [all (ns:"pmdznmvut") in\: types; /dnl
        str,: enlist .z.m.axlocalize.t`.gg_temporal;
        types : types except ns];
    
    if [0 < count types;
        str ,: enlist ", " sv string h.METATYPES @/: types];
    
    : ", " sv str;
    
    }

.z.m.gg.h.null:{$[0 > type x; null x; x ~ (::)]}
// @fileOverview 
// Convert a value into a string
// @param x {any} the item to print
// @return {string}
.z.m.gg.h.print:{[x]
    
    if [type[x] in -8 -9h;
        x: h.tryInteger x];
    
    p : $[h.null x; .Q.s1; .Q.s2];
    : $[10h ~ type x; x; raze p x];
    }
// @fileOverview 
// Convert a value into a string preserving any Qisms of the printed string
// @param x {any} 
.z.m.gg.h.print2:{[x] : raze .Q.s1 x;  }

// @fileOverview 
// Converts the argument to a printable string. IF the argument is an integer,
// print the integer separated by commas
// @param printF {function} function to convert any value to a string -- any-> char[]
// @param precision {long|null} precision of the resulting string, null to use system precision
// @param x {any} 
// @returns {char[]} 
.z.m.gg.h.printNum:{[printF; precision; x]
    sysP : system "P";
    if [not h.null precision;
        system "P ",string precision];
    
    y: printF x;
    
    if [type[x] in -5 -6 -7 -8 -9h;
        y: printF h.tryInteger x;
        if [not "e" in lower -1_y;
            typeChar : $[(last y) in "hijef"; [l:last y;y:-1_y;l]; ""]; /dnl
            start : $["-" ~ y 0; "-"; ""];
            end : $["." in y; last "." vs y; ""];
            middle : $["." in y; first "." vs y; y];
            y: start , (reverse ","sv (0N;3)#reverse middle except "-") , $[0 < count end; ".",end;""] , typeChar]];
    
    system "P ",string sysP;
    
    : y;
    
    }
// @fileOverview 
// Promote an integer to a long
// @param x {any} 
.z.m.gg.h.promote:{[x]
    : $[type[x] in -4 -5 -6 -7h; "j"$; (::)] x;
    }

// @fileOverview 
// Determine the range between two numbers. If the numbers are integers,
// they are promoted to longs.
// @param minMax {(number;number)} 
.z.m.gg.h.range:{[minMax]
    : (-). reverse h.promote each minMax;
    }
// @fileOverview 
// Remove infinity values from a vector
// @param vector {number[]} num vector
// @returns {number[]} subset of vector without infinities
.z.m.gg.h.removeInfs:{[vector]
    kind : .z.m.axq.typeOf first vector;
    if [kind in key h.INFINITY;
        idx : h.infPos vector;
        if [not 0 = count idx;
            vector @: (til count vector) except idx]];
    : vector;
    }

// @fileOverview 
// Round n up to the nearest multiple of m
// @param n {number} 
// @param m {number}
// @returns {number}
.z.m.gg.h.roundup:{[n; m]
    : $[0 = m;
            n;
        0 = r:n mod m;
            n;
            n + m - r]
    }

// @fileOverview 
// Determine the range between two numbers. If the
// range calculation overflows, throw an error
// @param minMax {(number;number)}
//
// @throws '"Range overflow"
.z.m.gg.h.safeRange:{[minMax]
    errorMsg: .z.m.axlocalize.t`.gg_rangeOverflow;
    
    r: h.range minMax;
    
    if [(r < minMax 1) <> minMax[0] > 0;
        'errorMsg];
    
    if [.z.m.axq.isInfinity r;
        'errorMsg];
    
    : r;
    
    }

// @fileOverview 
// Given a list if column names, santize them (convert non-symbols to symbols, etc)
// @param names {any[]}
// @returns {symbol[]} column names
.z.m.gg.h.sanitize:{[names]
    names : (::),names;
    : 1_@[names; where not -11h = type each names; :; `const__];
    }

// @fileOverview 
// Return the text width of a list of strings at a given fontsize
// @param fontsize {long} 
// @param text {char[][]} 
// @returns {long[]} 
.z.m.gg.h.textWidth:{[fontsize; text]
    : $[$[not `skia in key `; 1b; not `textWidth in key `.axskia];
        
        "j"$0.66 * fontsize * count each text;
        
        [
            if [not all 10h = type each text; '`type];
            p: .z.m.axskia.new [100;100];
            .z.m.axskia.setFontSize [p; fontsize];
            w: .z.m.axskia.textWidth [p] each text;
            .z.m.axskia.delete p;
            w]];
    }

.z.m.gg.h.trim:{[chars; text]
    text   : h.asString text;
    c      : count text;
    chars  : min (c; chars);
    result : .z.m.axstr.truncate[text; chars];
    : $[chars < c; result , ".."; result];
    }
// @fileOverview If a number can be an integer, make it one
// @param x {number} 
// @returns {number}
.z.m.gg.h.tryInteger:{[x]
    if [-8 < type x; : x];
    : $[x = floor x; floor x; x];
    }
.z.m.gg.h.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.gg_colNotSymbolError; "column argument must be a symbol");
        (`.gg_colNotFoundError; "column `{col}` not found");
        (`.gg_colTypeMismatch; "column `{column}` of type {found} not one of {expected}");
        (`.gg_rangeOverflow; "Range overflow")))
.z.m.gg.h.TEMPORALS:`date`month`year`hh`minute`second`time`timestamp`datetime
.z.m.gg.h.METATYPES:.z.m.axutl.METATYPES
.z.m.gg.h.INFINITY:(`boolean`byte`short _ .z.m.axq.INFINITY) , enlist[`month]!enlist 0Wm
system "d .z.m";

system "d .z.m.gg";
.z.m.gg.i.wilkinson.i.dbase:{[base]
    : $[base = -4; 0.0001;
        base = -3; 0.001;
        base = -2; 0.01;
        base = -1; 0.1;
        base =  1; 10;
        base =  2; 100;
        base =  3; 1000;
        base =  4; 10000;
        base =  5; 100000;
        base =  6; 1000000;
            10 xexp base];
    }

// @category Visual Inspector
//
// @param   dmin {number} data min
// @param   dmax {number} data max
// @param   m {number} ideal tick count
.z.m.gg.i.wilkinson.i.scale:{[dmin; dmax; m]
    mrange      : "j"$(1|floor m * .5; ceiling 6 * m);
    k           : {x+til y-x} . mrange;
    Q           : "f"$enlist[10f] , i.wilkinson.Q;
    delta       : (dmax - dmin) % k-1;
    base        : floor 10 xlog delta;
    dbase       : i.wilkinson.i.dbase each base;
    dbase       : ("j"$dbase = floor dbase)'[dbase; "j"$dbase];
    tdelta      : Q *\: dbase;
    tmin        : (abs type dmin)$tdelta * floor dmin % tdelta;
    tmax        : (abs type dmax)$tmin + (k-1) */: tdelta;
    ticks       : "j"$(tmax - tmin) % tdelta;
    granularity : 1 - abs[k - m] % m + 1;
    simplicity  : 1 - (til[count Q] - (tmin <= 0) & tmax >= 0) % count i.wilkinson.Q;
    coverage    : (dmax - dmin) % tmax - tmin;
    tnice       : granularity +/: simplicity + coverage;
    tnice      +: (tmin = neg tmax) | (tmin = 0) | (tmax = 1) | tmax = 100;
    tnice      +: ((tmin = 0) & tmax = 1) | (tmin = 0) & tmax  = 100;
    tnice      *: (not 2 > ticks) & ((tmin <= dmin) & tmax >= dmax) & coverage > i.wilkinson.mincoverage;
    dims        : (count tnice; count first tnice);
    c           : (dims vs til prd dims) @\:/: where {x = max x} raze tnice;

    : `lmin`lmax`lstep`score!/:(tmin;tmax;tdelta;tnice) .\:/: c
    }
// @category Visual Inspector
// @fileOverview
// Implements Wilkinson's Labelling Algorithm
.z.m.gg.i.wilkinson.scale:{[dmin; dmax; m]
    results : i.wilkinson.i.scale[dmin; dmax; m];
    
    if [0 = count results;
        : enlist `lmin`lmax`lstep`score!(dmin; dmax; (dmax - dmin) % m; 0)];
    
    bad : where 2 >= exec floor (lmax-lmin)%lstep from results;
    
    if [count[bad] = count results;
        bad: ()];

    : results (til count results) except bad;
    }


.z.m.gg.i.wilkinson.mincoverage:0.85
.z.m.gg.i.wilkinson.Q:(1j; 5j; 2j; 2.5f; 3j; 4j; 1.5f; 7j; 6j; 8j; 9j)
system "d .z.m";

system "d .z.m.axbits";
// @fileOverview onLoad function
// @returns {null}

([k_bit_and;k_bit_or;k_bit_ls]):use`..bitops;
.z.m.axbits.i.and:k_bit_and;
.z.m.axbits.i.or:k_bit_or;
.z.m.axbits.i.ls:k_bit_ls;

.z.m.axbits.and:{$[0=count x;x;0=count y;y;(0>type x)&0>type y;.z.m.axbits.i.and[x;y];(0<type x)&0<type y;.z.m.axbits.i.and'[x;y];0>type x;.z.m.axbits.i.and[x;]each y;.z.m.axbits.i.and[;y] each x]};
.z.m.axbits.or:{$[0=count x;x;0=count y;y;(0>type x)&0>type y;.z.m.axbits.i.or[x;y];(0<type x)&0<type y;.z.m.axbits.i.or'[x;y];0>type x;.z.m.axbits.i.or[x;]each y;.z.m.axbits.i.or[;y] each x]};
.z.m.axbits.ls:{$[0=count x;x;(0>type x)&0>type y;.z.m.axbits.i.ls[x;y];(0<type x)&0<type y;.z.m.axbits.i.ls'[x;y];0>type x;.z.m.axbits.i.ls[x;]each y;.z.m.axbits.i.ls[;y] each x]};

system "d .z.m";

system "d .z.m.gg";

.z.m.gg.colour.brewer:{[palette; n]
    if [not palette in key colour.i.BREWER;   '.z.m.axlocalize.t`.gg_noColourPalette];
    if [not n in key colour.i.BREWER palette; '.z.m.axlocalize.t`.gg_outOfRangePalette];
    : colour.i.BREWER[palette;n];
    }



// @private
// @subcategory Colours
// @fileOverview
// If the colour is input as a 0xrrggbb, convert it to an integer
// @param c {byte[]|int} colour 0xrrggbb
// @returns {int} int representation of colour
.z.m.gg.colour.fromBytes:{[c]
    if [4h ~ type c;
        $[3 = count c;
            c: 0x0 sv 0x00,c;
          4 = count c;
            c: 0x0 sv c;
            '"Colour must be a 3-byte list of 0xrrggbb"]];
    : c
    }


.z.m.gg.colour.gradient:{[values_; min_; max_; color1; color2]
    if [-6h ~ type color1; color1: 1_0x0 vs color1];
    if [-6h ~ type color2; color2: 1_0x0 vs color2];
    
    values_ : raze values_;
    
    percents     : $[min_ ~ max_; (count values_)#0; (values_ - min_) % max_ - min_];
    
    resultReds   : .z.m.axbits.ls[; 16i] "i"$raze "x"$color1[0] + percents * color2[0] - color1 0;
    resultGreens : .z.m.axbits.ls[; 8i]  "i"$raze "x"$color1[1] + percents * color2[1] - color1 1;
    resultBlues  :                   "i"$raze "x"$color1[2] + percents * color2[2] - color1 2;
    
    : .z.m.axbits.or/[(resultReds; resultGreens; resultBlues)]
    
    }

// @subcategory Colours
// @private
// @fileOverview 
// Create a table describing a colour gradient between
// two colours.
// @param info {dict} gradient step and scale info
// @param fs {byte[][]} gradient colours
// @param c {long} number of gradient steps
// @returns {table}
// @example
// .z.m.gg.colour.gradientTable [
//     ``pos`limits!(::; 0 255; 0 255); 
//     0x0 sv' 0xff,/:.z.m.gg.colour.qualify each `red`blue;
//     5];
// // i size pos colour  
// // -------------------
// // 0 0.2  0   16711680
// // 1 0.2  0.2 13369395
// // 2 0.2  0.4 10027110
// // 3 0.2  0.6 6684825 
// // 4 0.2  0.8 3342540 
.z.m.gg.colour.gradientTable:{[info; fs; c]
    : {[info; c; fs; ii]
        pos: c * (info[`pos] - info[`limits;0]) % (-) . desc info`limits;
         : `i`size`pos`colour!(ii;1%c; ii%c; colour.vecgradient[ii; pos; fs]);
        }[info; c; fs] each til c;
    }

// @subcategory Colours
// @private
// @fileOverview Convert a single RGB colour to HSL
// @param rgb {byte[]}
// @example
// .z.m.gg.colour.hsl .z.m.gg.colour.SteelBlue
// 
// /=> 207.2727 44 49.01961
.z.m.gg.colour.hsl:{[rgb]
    v    : rgb % 255;
    cmax : max v;
    cmin : min v;
    d    : cmax - cmin;
    l    : (cmax + cmin) % 2;
    
    $[cmax = cmin;
        hh : s : 0;
        [   s  : d % 1 - abs -1 + 2 * l; 
            hh : $[cmax ~ v 0; ((v[1] - v 2) % d) + $[v[1] < v 2; 6; 0];
                   cmax ~ v 1; 2 + (v[2] - v 0) % d;
                               4 + (v[0] - v 1) % d];
            hh %: 6]];
    
    : (hh*360; s*100; l*100);
    }
// @qlintsuppress UNUSED_INTERNAL(1)
// @subcategory Colours
.z.m.gg.colour.i.qdformatter:{[r]
    : .qd.format.imageTag
            .qd.format.base64
            .[;`output`bytes]
            .z.m.gg.display[500;3500]
            .z.m.gg.new
            r
    }

.z.m.gg.colour.invGradient:{[colour_; min_; max_; colour1; colour2]
    
    p:{[colour_; colour1; colour2; x]
        c : colour_ x;
        c1: colour1 x;
        c2: colour2 x;
        : (c - c1) % c2 - c1;
        }[colour_; colour1; colour2];
    
    rpercent : p 0;
    gpercent : p 1;
    bpercent : p 2;
    : min_ + (max_ - min_) * max (rpercent; gpercent; bpercent);
    }

// @private
// @subcategory Colours
// @fileOverview Turn a colour or a word into a colour
// @param c {byte|byte[]|char[]|symbol} 
// @returns {byte[]} 0xrrggbb
.z.m.gg.colour.qualify:{[c]

    if [10h ~ type c; c: `$c];
    
    $[4h ~ type c;     c;
     -4h ~ type c;     3#c;
    -11h ~ type c;     colour k lower[k:key colour] ? c;
     -6h ~ type c;     1_0x0 vs c;
      6h ~ type c;     1_'0x0 vs'c;
                       0x000000]
    }

// @private
// @fileOverview Resolve a palette name and best-effort count
// to a list of colours
// @param palette {symbol} name of a palette to use
// @param c {long} count of colours in the palette
// @returns {byte[][]} A list of 0xrrggbb colours
.z.m.gg.colour.resolvePalette:{[palette; c]
    if [-11h ~ type palette;
        if [not palette in lower key colour.PALETTES;
            '"Palette ",string[palette]," is not a known colour palette"]];
    
    palettes: lower[key colour.PALETTES]!value colour.PALETTES;
    palette: palettes palette;
    : palette min[key palette] | max[key palette] & c;
    }

// @subcategory Colours
// @fileOverview 
// Return an RGB colour (`0xRRGGBB`) from an HSL colour
//
// @param hsl {float[]} 
// @returns {byte[]}
//
// @example
// 0x0070cd ~ .z.m.gg.colour.rgbFromHSL .z.m.gg.colour.hsl 0x0070cd
//
.z.m.gg.colour.rgbFromHSL:{[hsl]
    hh : hsl 0;
    l  : hsl[2] % 100;
    s  : hsl[1] % 100;
    c  : s * 1 - abs -1 + 2 * l;
    x  : c * 1 - abs -1 + (hh % 60) mod 2;
    m  : l - c % 2;
    r  : (!) . flip (
        ( (c;x;0); 0   );
        ( (x;c;0); 60  );
        ( (0;c;x); 120 );
        ( (0;x;c); 180 );
        ( (x;0;c); 240 );
        ( (c;0;x); 300 )
        );
    
    : "x"$255 * m + last where r <= hh;
    }
// @private
// @subcategory Colours
// @fileOverview Set alpha on a list of fills
// @param alpha {byte|int} 
// @param fill {int[]} 
// @returns {int[]} New ARGB colours
.z.m.gg.colour.setAlpha:{[alpha; fill]
    if [4 = abs type alpha; alpha: .z.m.axbits.ls["i"$alpha; 24i]];

    if [abs[type alpha] in 5 7 8 9h;
        alpha: .z.m.axbits.ls["i"$alpha; 24i]];
 
    .z.m.axbits.or[alpha; fill]
    }

// @subcategory Colours
// @private
// @fileOverview Sort a list of RGB colours
// @param rgbs {byte[][]}
// @example
//  .z.m.gg.colour.sort (
//     .z.m.gg.colour.SteelBlue; 
//     .z.m.gg.colour.White; 
//     .z.m.gg.colour.FireBrick; 
//     .z.m.gg.colour.Black)
// 
// /=> 0xffffff
// /=> 0x000000
// /=> 0xb22222
// /=> 0x4682b4
.z.m.gg.colour.sort:{[rgbs]
    hs : first each colour.hsl each rgbs;
    : rgbs iasc hs;
    }
// @private
// @fileOverview Return a gradient between two colours
.z.m.gg.colour.vecgradient:{[v;pos;fs]
    colour.gradient[v] . pos[ii] , fs ii: til[2] + (-2+count fs) & pos bin (type pos)$v
    }

.z.m.gg.colour.i.BREWER:(!) . flip (
    (`YlGn; (!). flip (
            (3; (0xf7fcb9;0xaddd8e;0x31a354));
            (4; (0xffffcc;0xc2e699;0x78c679;0x238443));
            (5; (0xffffcc;0xc2e699;0x78c679;0x31a354;0x006837));
            (6; (0xffffcc;0xd9f0a3;0xaddd8e;0x78c679;0x31a354;0x006837));
            (7; (0xffffcc;0xd9f0a3;0xaddd8e;0x78c679;0x41ab5d;0x238443;0x005a32));
            (8; (0xffffe5;0xf7fcb9;0xd9f0a3;0xaddd8e;0x78c679;0x41ab5d;0x238443;0x005a32));
            (9; (0xffffe5;0xf7fcb9;0xd9f0a3;0xaddd8e;0x78c679;0x41ab5d;0x238443;0x006837;0x004529))));
    (`YlGnBu; (!). flip (
            (3; (0xedf8b1;0x7fcdbb;0x2c7fb8));
            (4; (0xffffcc;0xa1dab4;0x41b6c4;0x225ea8));
            (5; (0xffffcc;0xa1dab4;0x41b6c4;0x2c7fb8;0x253494));
            (6; (0xffffcc;0xc7e9b4;0x7fcdbb;0x41b6c4;0x2c7fb8;0x253494));
            (7; (0xffffcc;0xc7e9b4;0x7fcdbb;0x41b6c4;0x1d91c0;0x225ea8;0x0c2c84));
            (8; (0xffffd9;0xedf8b1;0xc7e9b4;0x7fcdbb;0x41b6c4;0x1d91c0;0x225ea8;0x0c2c84));
            (9; (0xffffd9;0xedf8b1;0xc7e9b4;0x7fcdbb;0x41b6c4;0x1d91c0;0x225ea8;0x253494;0x081d58))));
    (`GnBu; (!). flip (
            (3; (0xe0f3db;0xa8ddb5;0x43a2ca));
            (4; (0xf0f9e8;0xbae4bc;0x7bccc4;0x2b8cbe));
            (5; (0xf0f9e8;0xbae4bc;0x7bccc4;0x43a2ca;0x0868ac));
            (6; (0xf0f9e8;0xccebc5;0xa8ddb5;0x7bccc4;0x43a2ca;0x0868ac));
            (7; (0xf0f9e8;0xccebc5;0xa8ddb5;0x7bccc4;0x4eb3d3;0x2b8cbe;0x08589e));
            (8; (0xf7fcf0;0xe0f3db;0xccebc5;0xa8ddb5;0x7bccc4;0x4eb3d3;0x2b8cbe;0x08589e));
            (9; (0xf7fcf0;0xe0f3db;0xccebc5;0xa8ddb5;0x7bccc4;0x4eb3d3;0x2b8cbe;0x0868ac;0x084081))));
    (`BuGn; (!). flip (
            (3; (0xe5f5f9;0x99d8c9;0x2ca25f));
            (4; (0xedf8fb;0xb2e2e2;0x66c2a4;0x238b45));
            (5; (0xedf8fb;0xb2e2e2;0x66c2a4;0x2ca25f;0x006d2c));
            (6; (0xedf8fb;0xccece6;0x99d8c9;0x66c2a4;0x2ca25f;0x006d2c));
            (7; (0xedf8fb;0xccece6;0x99d8c9;0x66c2a4;0x41ae76;0x238b45;0x005824));
            (8; (0xf7fcfd;0xe5f5f9;0xccece6;0x99d8c9;0x66c2a4;0x41ae76;0x238b45;0x005824));
            (9; (0xf7fcfd;0xe5f5f9;0xccece6;0x99d8c9;0x66c2a4;0x41ae76;0x238b45;0x006d2c;0x00441b))));
    (`PuBuGn; (!). flip (
            (3; (0xece2f0;0xa6bddb;0x1c9099));
            (4; (0xf6eff7;0xbdc9e1;0x67a9cf;0x02818a));
            (5; (0xf6eff7;0xbdc9e1;0x67a9cf;0x1c9099;0x016c59));
            (6; (0xf6eff7;0xd0d1e6;0xa6bddb;0x67a9cf;0x1c9099;0x016c59));
            (7; (0xf6eff7;0xd0d1e6;0xa6bddb;0x67a9cf;0x3690c0;0x02818a;0x016450));
            (8; (0xfff7fb;0xece2f0;0xd0d1e6;0xa6bddb;0x67a9cf;0x3690c0;0x02818a;0x016450));
            (9; (0xfff7fb;0xece2f0;0xd0d1e6;0xa6bddb;0x67a9cf;0x3690c0;0x02818a;0x016c59;0x014636))));
    (`PuBu; (!). flip (
            (3; (0xece7f2;0xa6bddb;0x2b8cbe));
            (4; (0xf1eef6;0xbdc9e1;0x74a9cf;0x0570b0));
            (5; (0xf1eef6;0xbdc9e1;0x74a9cf;0x2b8cbe;0x045a8d));
            (6; (0xf1eef6;0xd0d1e6;0xa6bddb;0x74a9cf;0x2b8cbe;0x045a8d));
            (7; (0xf1eef6;0xd0d1e6;0xa6bddb;0x74a9cf;0x3690c0;0x0570b0;0x034e7b));
            (8; (0xfff7fb;0xece7f2;0xd0d1e6;0xa6bddb;0x74a9cf;0x3690c0;0x0570b0;0x034e7b));
            (9; (0xfff7fb;0xece7f2;0xd0d1e6;0xa6bddb;0x74a9cf;0x3690c0;0x0570b0;0x045a8d;0x023858))));
    (`BuPu; (!). flip (
            (3; (0xe0ecf4;0x9ebcda;0x8856a7));
            (4; (0xedf8fb;0xb3cde3;0x8c96c6;0x88419d));
            (5; (0xedf8fb;0xb3cde3;0x8c96c6;0x8856a7;0x810f7c));
            (6; (0xedf8fb;0xbfd3e6;0x9ebcda;0x8c96c6;0x8856a7;0x810f7c));
            (7; (0xedf8fb;0xbfd3e6;0x9ebcda;0x8c96c6;0x8c6bb1;0x88419d;0x6e016b));
            (8; (0xf7fcfd;0xe0ecf4;0xbfd3e6;0x9ebcda;0x8c96c6;0x8c6bb1;0x88419d;0x6e016b));
            (9; (0xf7fcfd;0xe0ecf4;0xbfd3e6;0x9ebcda;0x8c96c6;0x8c6bb1;0x88419d;0x810f7c;0x4d004b))));
    (`RdPu; (!). flip (
            (3; (0xfde0dd;0xfa9fb5;0xc51b8a));
            (4; (0xfeebe2;0xfbb4b9;0xf768a1;0xae017e));
            (5; (0xfeebe2;0xfbb4b9;0xf768a1;0xc51b8a;0x7a0177));
            (6; (0xfeebe2;0xfcc5c0;0xfa9fb5;0xf768a1;0xc51b8a;0x7a0177));
            (7; (0xfeebe2;0xfcc5c0;0xfa9fb5;0xf768a1;0xdd3497;0xae017e;0x7a0177));
            (8; (0xfff7f3;0xfde0dd;0xfcc5c0;0xfa9fb5;0xf768a1;0xdd3497;0xae017e;0x7a0177));
            (9; (0xfff7f3;0xfde0dd;0xfcc5c0;0xfa9fb5;0xf768a1;0xdd3497;0xae017e;0x7a0177;0x49006a))));
    (`PuRd; (!). flip (
            (3; (0xe7e1ef;0xc994c7;0xdd1c77));
            (4; (0xf1eef6;0xd7b5d8;0xdf65b0;0xce1256));
            (5; (0xf1eef6;0xd7b5d8;0xdf65b0;0xdd1c77;0x980043));
            (6; (0xf1eef6;0xd4b9da;0xc994c7;0xdf65b0;0xdd1c77;0x980043));
            (7; (0xf1eef6;0xd4b9da;0xc994c7;0xdf65b0;0xe7298a;0xce1256;0x91003f));
            (8; (0xf7f4f9;0xe7e1ef;0xd4b9da;0xc994c7;0xdf65b0;0xe7298a;0xce1256;0x91003f));
            (9; (0xf7f4f9;0xe7e1ef;0xd4b9da;0xc994c7;0xdf65b0;0xe7298a;0xce1256;0x980043;0x67001f))));
    (`OrRd; (!). flip (
            (3; (0xfee8c8;0xfdbb84;0xe34a33));
            (4; (0xfef0d9;0xfdcc8a;0xfc8d59;0xd7301f));
            (5; (0xfef0d9;0xfdcc8a;0xfc8d59;0xe34a33;0xb30000));
            (6; (0xfef0d9;0xfdd49e;0xfdbb84;0xfc8d59;0xe34a33;0xb30000));
            (7; (0xfef0d9;0xfdd49e;0xfdbb84;0xfc8d59;0xef6548;0xd7301f;0x990000));
            (8; (0xfff7ec;0xfee8c8;0xfdd49e;0xfdbb84;0xfc8d59;0xef6548;0xd7301f;0x990000));
            (9; (0xfff7ec;0xfee8c8;0xfdd49e;0xfdbb84;0xfc8d59;0xef6548;0xd7301f;0xb30000;0x7f0000))));
    (`YlOrRd; (!). flip (
            (3; (0xffeda0;0xfeb24c;0xf03b20));
            (4; (0xffffb2;0xfecc5c;0xfd8d3c;0xe31a1c));
            (5; (0xffffb2;0xfecc5c;0xfd8d3c;0xf03b20;0xbd0026));
            (6; (0xffffb2;0xfed976;0xfeb24c;0xfd8d3c;0xf03b20;0xbd0026));
            (7; (0xffffb2;0xfed976;0xfeb24c;0xfd8d3c;0xfc4e2a;0xe31a1c;0xb10026));
            (8; (0xffffcc;0xffeda0;0xfed976;0xfeb24c;0xfd8d3c;0xfc4e2a;0xe31a1c;0xb10026));
            (9; (0xffffcc;0xffeda0;0xfed976;0xfeb24c;0xfd8d3c;0xfc4e2a;0xe31a1c;0xbd0026;0x800026))));
    (`YlOrBr; (!). flip (
            (3; (0xfff7bc;0xfec44f;0xd95f0e));
            (4; (0xffffd4;0xfed98e;0xfe9929;0xcc4c02));
            (5; (0xffffd4;0xfed98e;0xfe9929;0xd95f0e;0x993404));
            (6; (0xffffd4;0xfee391;0xfec44f;0xfe9929;0xd95f0e;0x993404));
            (7; (0xffffd4;0xfee391;0xfec44f;0xfe9929;0xec7014;0xcc4c02;0x8c2d04));
            (8; (0xffffe5;0xfff7bc;0xfee391;0xfec44f;0xfe9929;0xec7014;0xcc4c02;0x8c2d04));
            (9; (0xffffe5;0xfff7bc;0xfee391;0xfec44f;0xfe9929;0xec7014;0xcc4c02;0x993404;0x662506))));
    (`Purples; (!). flip (
            (3; (0xefedf5;0xbcbddc;0x756bb1));
            (4; (0xf2f0f7;0xcbc9e2;0x9e9ac8;0x6a51a3));
            (5; (0xf2f0f7;0xcbc9e2;0x9e9ac8;0x756bb1;0x54278f));
            (6; (0xf2f0f7;0xdadaeb;0xbcbddc;0x9e9ac8;0x756bb1;0x54278f));
            (7; (0xf2f0f7;0xdadaeb;0xbcbddc;0x9e9ac8;0x807dba;0x6a51a3;0x4a1486));
            (8; (0xfcfbfd;0xefedf5;0xdadaeb;0xbcbddc;0x9e9ac8;0x807dba;0x6a51a3;0x4a1486));
            (9; (0xfcfbfd;0xefedf5;0xdadaeb;0xbcbddc;0x9e9ac8;0x807dba;0x6a51a3;0x54278f;0x3f007d))));
    (`Blues; (!). flip (
            (3; (0xdeebf7;0x9ecae1;0x3182bd));
            (4; (0xeff3ff;0xbdd7e7;0x6baed6;0x2171b5));
            (5; (0xeff3ff;0xbdd7e7;0x6baed6;0x3182bd;0x08519c));
            (6; (0xeff3ff;0xc6dbef;0x9ecae1;0x6baed6;0x3182bd;0x08519c));
            (7; (0xeff3ff;0xc6dbef;0x9ecae1;0x6baed6;0x4292c6;0x2171b5;0x084594));
            (8; (0xf7fbff;0xdeebf7;0xc6dbef;0x9ecae1;0x6baed6;0x4292c6;0x2171b5;0x084594));
            (9; (0xf7fbff;0xdeebf7;0xc6dbef;0x9ecae1;0x6baed6;0x4292c6;0x2171b5;0x08519c;0x08306b))));
    (`Greens; (!). flip (
            (3; (0xe5f5e0;0xa1d99b;0x31a354));
            (4; (0xedf8e9;0xbae4b3;0x74c476;0x238b45));
            (5; (0xedf8e9;0xbae4b3;0x74c476;0x31a354;0x006d2c));
            (6; (0xedf8e9;0xc7e9c0;0xa1d99b;0x74c476;0x31a354;0x006d2c));
            (7; (0xedf8e9;0xc7e9c0;0xa1d99b;0x74c476;0x41ab5d;0x238b45;0x005a32));
            (8; (0xf7fcf5;0xe5f5e0;0xc7e9c0;0xa1d99b;0x74c476;0x41ab5d;0x238b45;0x005a32));
            (9; (0xf7fcf5;0xe5f5e0;0xc7e9c0;0xa1d99b;0x74c476;0x41ab5d;0x238b45;0x006d2c;0x00441b))));
    (`Oranges; (!). flip (
            (3; (0xfee6ce;0xfdae6b;0xe6550d));
            (4; (0xfeedde;0xfdbe85;0xfd8d3c;0xd94701));
            (5; (0xfeedde;0xfdbe85;0xfd8d3c;0xe6550d;0xa63603));
            (6; (0xfeedde;0xfdd0a2;0xfdae6b;0xfd8d3c;0xe6550d;0xa63603));
            (7; (0xfeedde;0xfdd0a2;0xfdae6b;0xfd8d3c;0xf16913;0xd94801;0x8c2d04));
            (8; (0xfff5eb;0xfee6ce;0xfdd0a2;0xfdae6b;0xfd8d3c;0xf16913;0xd94801;0x8c2d04));
            (9; (0xfff5eb;0xfee6ce;0xfdd0a2;0xfdae6b;0xfd8d3c;0xf16913;0xd94801;0xa63603;0x7f2704))));
    (`Reds; (!). flip (
            (3; (0xfee0d2;0xfc9272;0xde2d26));
            (4; (0xfee5d9;0xfcae91;0xfb6a4a;0xcb181d));
            (5; (0xfee5d9;0xfcae91;0xfb6a4a;0xde2d26;0xa50f15));
            (6; (0xfee5d9;0xfcbba1;0xfc9272;0xfb6a4a;0xde2d26;0xa50f15));
            (7; (0xfee5d9;0xfcbba1;0xfc9272;0xfb6a4a;0xef3b2c;0xcb181d;0x99000d));
            (8; (0xfff5f0;0xfee0d2;0xfcbba1;0xfc9272;0xfb6a4a;0xef3b2c;0xcb181d;0x99000d));
            (9; (0xfff5f0;0xfee0d2;0xfcbba1;0xfc9272;0xfb6a4a;0xef3b2c;0xcb181d;0xa50f15;0x67000d))));
    (`Greys; (!). flip (
            (3; (0xf0f0f0;0xbdbdbd;0x636363));
            (4; (0xf7f7f7;0xcccccc;0x969696;0x525252));
            (5; (0xf7f7f7;0xcccccc;0x969696;0x636363;0x252525));
            (6; (0xf7f7f7;0xd9d9d9;0xbdbdbd;0x969696;0x636363;0x252525));
            (7; (0xf7f7f7;0xd9d9d9;0xbdbdbd;0x969696;0x737373;0x525252;0x252525));
            (8; (0xffffff;0xf0f0f0;0xd9d9d9;0xbdbdbd;0x969696;0x737373;0x525252;0x252525));
            (9; (0xffffff;0xf0f0f0;0xd9d9d9;0xbdbdbd;0x969696;0x737373;0x525252;0x252525;0x000000))));
    (`PuOr; (!). flip (
            (3; (0xf1a340;0xf7f7f7;0x998ec3));
            (4; (0xe66101;0xfdb863;0xb2abd2;0x5e3c99));
            (5; (0xe66101;0xfdb863;0xf7f7f7;0xb2abd2;0x5e3c99));
            (6; (0xb35806;0xf1a340;0xfee0b6;0xd8daeb;0x998ec3;0x542788));
            (7; (0xb35806;0xf1a340;0xfee0b6;0xf7f7f7;0xd8daeb;0x998ec3;0x542788));
            (8; (0xb35806;0xe08214;0xfdb863;0xfee0b6;0xd8daeb;0xb2abd2;0x8073ac;0x542788));
            (9; (0xb35806;0xe08214;0xfdb863;0xfee0b6;0xf7f7f7;0xd8daeb;0xb2abd2;0x8073ac;0x542788));
            (10; (0x7f3b08;0xb35806;0xe08214;0xfdb863;0xfee0b6;0xd8daeb;0xb2abd2;0x8073ac;0x542788;0x2d004b));
            (11; (0x7f3b08;0xb35806;0xe08214;0xfdb863;0xfee0b6;0xf7f7f7;0xd8daeb;0xb2abd2;0x8073ac;0x542788;0x2d004b))));
    (`BrBG; (!). flip (
            (3; (0xd8b365;0xf5f5f5;0x5ab4ac));
            (4; (0xa6611a;0xdfc27d;0x80cdc1;0x018571));
            (5; (0xa6611a;0xdfc27d;0xf5f5f5;0x80cdc1;0x018571));
            (6; (0x8c510a;0xd8b365;0xf6e8c3;0xc7eae5;0x5ab4ac;0x01665e));
            (7; (0x8c510a;0xd8b365;0xf6e8c3;0xf5f5f5;0xc7eae5;0x5ab4ac;0x01665e));
            (8; (0x8c510a;0xbf812d;0xdfc27d;0xf6e8c3;0xc7eae5;0x80cdc1;0x35978f;0x01665e));
            (9; (0x8c510a;0xbf812d;0xdfc27d;0xf6e8c3;0xf5f5f5;0xc7eae5;0x80cdc1;0x35978f;0x01665e));
            (10; (0x543005;0x8c510a;0xbf812d;0xdfc27d;0xf6e8c3;0xc7eae5;0x80cdc1;0x35978f;0x01665e;0x003c30));
            (11; (0x543005;0x8c510a;0xbf812d;0xdfc27d;0xf6e8c3;0xf5f5f5;0xc7eae5;0x80cdc1;0x35978f;0x01665e;0x003c30))));
    (`PRGn; (!). flip (
            (3; (0xaf8dc3;0xf7f7f7;0x7fbf7b));
            (4; (0x7b3294;0xc2a5cf;0xa6dba0;0x008837));
            (5; (0x7b3294;0xc2a5cf;0xf7f7f7;0xa6dba0;0x008837));
            (6; (0x762a83;0xaf8dc3;0xe7d4e8;0xd9f0d3;0x7fbf7b;0x1b7837));
            (7; (0x762a83;0xaf8dc3;0xe7d4e8;0xf7f7f7;0xd9f0d3;0x7fbf7b;0x1b7837));
            (8; (0x762a83;0x9970ab;0xc2a5cf;0xe7d4e8;0xd9f0d3;0xa6dba0;0x5aae61;0x1b7837));
            (9; (0x762a83;0x9970ab;0xc2a5cf;0xe7d4e8;0xf7f7f7;0xd9f0d3;0xa6dba0;0x5aae61;0x1b7837));
            (10; (0x40004b;0x762a83;0x9970ab;0xc2a5cf;0xe7d4e8;0xd9f0d3;0xa6dba0;0x5aae61;0x1b7837;0x00441b));
            (11; (0x40004b;0x762a83;0x9970ab;0xc2a5cf;0xe7d4e8;0xf7f7f7;0xd9f0d3;0xa6dba0;0x5aae61;0x1b7837;0x00441b))));
    (`PiYG; (!). flip (
            (3; (0xe9a3c9;0xf7f7f7;0xa1d76a));
            (4; (0xd01c8b;0xf1b6da;0xb8e186;0x4dac26));
            (5; (0xd01c8b;0xf1b6da;0xf7f7f7;0xb8e186;0x4dac26));
            (6; (0xc51b7d;0xe9a3c9;0xfde0ef;0xe6f5d0;0xa1d76a;0x4d9221));
            (7; (0xc51b7d;0xe9a3c9;0xfde0ef;0xf7f7f7;0xe6f5d0;0xa1d76a;0x4d9221));
            (8; (0xc51b7d;0xde77ae;0xf1b6da;0xfde0ef;0xe6f5d0;0xb8e186;0x7fbc41;0x4d9221));
            (9; (0xc51b7d;0xde77ae;0xf1b6da;0xfde0ef;0xf7f7f7;0xe6f5d0;0xb8e186;0x7fbc41;0x4d9221));
            (10; (0x8e0152;0xc51b7d;0xde77ae;0xf1b6da;0xfde0ef;0xe6f5d0;0xb8e186;0x7fbc41;0x4d9221;0x276419));
            (11; (0x8e0152;0xc51b7d;0xde77ae;0xf1b6da;0xfde0ef;0xf7f7f7;0xe6f5d0;0xb8e186;0x7fbc41;0x4d9221;0x276419))));
    (`RdBu; (!). flip (
            (3; (0xef8a62;0xf7f7f7;0x67a9cf));
            (4; (0xca0020;0xf4a582;0x92c5de;0x0571b0));
            (5; (0xca0020;0xf4a582;0xf7f7f7;0x92c5de;0x0571b0));
            (6; (0xb2182b;0xef8a62;0xfddbc7;0xd1e5f0;0x67a9cf;0x2166ac));
            (7; (0xb2182b;0xef8a62;0xfddbc7;0xf7f7f7;0xd1e5f0;0x67a9cf;0x2166ac));
            (8; (0xb2182b;0xd6604d;0xf4a582;0xfddbc7;0xd1e5f0;0x92c5de;0x4393c3;0x2166ac));
            (9; (0xb2182b;0xd6604d;0xf4a582;0xfddbc7;0xf7f7f7;0xd1e5f0;0x92c5de;0x4393c3;0x2166ac));
            (10; (0x67001f;0xb2182b;0xd6604d;0xf4a582;0xfddbc7;0xd1e5f0;0x92c5de;0x4393c3;0x2166ac;0x053061));
            (11; (0x67001f;0xb2182b;0xd6604d;0xf4a582;0xfddbc7;0xf7f7f7;0xd1e5f0;0x92c5de;0x4393c3;0x2166ac;0x053061))));
    (`RdGy; (!). flip (
            (3; (0xef8a62;0xffffff;0x999999));
            (4; (0xca0020;0xf4a582;0xbababa;0x404040));
            (5; (0xca0020;0xf4a582;0xffffff;0xbababa;0x404040));
            (6; (0xb2182b;0xef8a62;0xfddbc7;0xe0e0e0;0x999999;0x4d4d4d));
            (7; (0xb2182b;0xef8a62;0xfddbc7;0xffffff;0xe0e0e0;0x999999;0x4d4d4d));
            (8; (0xb2182b;0xd6604d;0xf4a582;0xfddbc7;0xe0e0e0;0xbababa;0x878787;0x4d4d4d));
            (9; (0xb2182b;0xd6604d;0xf4a582;0xfddbc7;0xffffff;0xe0e0e0;0xbababa;0x878787;0x4d4d4d));
            (10; (0x67001f;0xb2182b;0xd6604d;0xf4a582;0xfddbc7;0xe0e0e0;0xbababa;0x878787;0x4d4d4d;0x1a1a1a));
            (11; (0x67001f;0xb2182b;0xd6604d;0xf4a582;0xfddbc7;0xffffff;0xe0e0e0;0xbababa;0x878787;0x4d4d4d;0x1a1a1a))));
    (`RdYlBu; (!). flip (
            (3; (0xfc8d59;0xffffbf;0x91bfdb));
            (4; (0xd7191c;0xfdae61;0xabd9e9;0x2c7bb6));
            (5; (0xd7191c;0xfdae61;0xffffbf;0xabd9e9;0x2c7bb6));
            (6; (0xd73027;0xfc8d59;0xfee090;0xe0f3f8;0x91bfdb;0x4575b4));
            (7; (0xd73027;0xfc8d59;0xfee090;0xffffbf;0xe0f3f8;0x91bfdb;0x4575b4));
            (8; (0xd73027;0xf46d43;0xfdae61;0xfee090;0xe0f3f8;0xabd9e9;0x74add1;0x4575b4));
            (9; (0xd73027;0xf46d43;0xfdae61;0xfee090;0xffffbf;0xe0f3f8;0xabd9e9;0x74add1;0x4575b4));
            (10; (0xa50026;0xd73027;0xf46d43;0xfdae61;0xfee090;0xe0f3f8;0xabd9e9;0x74add1;0x4575b4;0x313695));
            (11; (0xa50026;0xd73027;0xf46d43;0xfdae61;0xfee090;0xffffbf;0xe0f3f8;0xabd9e9;0x74add1;0x4575b4;0x313695))));
    (`Spectral; (!). flip (
            (3; (0xfc8d59;0xffffbf;0x99d594));
            (4; (0xd7191c;0xfdae61;0xabdda4;0x2b83ba));
            (5; (0xd7191c;0xfdae61;0xffffbf;0xabdda4;0x2b83ba));
            (6; (0xd53e4f;0xfc8d59;0xfee08b;0xe6f598;0x99d594;0x3288bd));
            (7; (0xd53e4f;0xfc8d59;0xfee08b;0xffffbf;0xe6f598;0x99d594;0x3288bd));
            (8; (0xd53e4f;0xf46d43;0xfdae61;0xfee08b;0xe6f598;0xabdda4;0x66c2a5;0x3288bd));
            (9; (0xd53e4f;0xf46d43;0xfdae61;0xfee08b;0xffffbf;0xe6f598;0xabdda4;0x66c2a5;0x3288bd));
            (10; (0x9e0142;0xd53e4f;0xf46d43;0xfdae61;0xfee08b;0xe6f598;0xabdda4;0x66c2a5;0x3288bd;0x5e4fa2));
            (11; (0x9e0142;0xd53e4f;0xf46d43;0xfdae61;0xfee08b;0xffffbf;0xe6f598;0xabdda4;0x66c2a5;0x3288bd;0x5e4fa2))));
    (`RdYlGn; (!). flip (
            (3; (0xfc8d59;0xffffbf;0x91cf60));
            (4; (0xd7191c;0xfdae61;0xa6d96a;0x1a9641));
            (5; (0xd7191c;0xfdae61;0xffffbf;0xa6d96a;0x1a9641));
            (6; (0xd73027;0xfc8d59;0xfee08b;0xd9ef8b;0x91cf60;0x1a9850));
            (7; (0xd73027;0xfc8d59;0xfee08b;0xffffbf;0xd9ef8b;0x91cf60;0x1a9850));
            (8; (0xd73027;0xf46d43;0xfdae61;0xfee08b;0xd9ef8b;0xa6d96a;0x66bd63;0x1a9850));
            (9; (0xd73027;0xf46d43;0xfdae61;0xfee08b;0xffffbf;0xd9ef8b;0xa6d96a;0x66bd63;0x1a9850));
            (10; (0xa50026;0xd73027;0xf46d43;0xfdae61;0xfee08b;0xd9ef8b;0xa6d96a;0x66bd63;0x1a9850;0x006837));
            (11; (0xa50026;0xd73027;0xf46d43;0xfdae61;0xfee08b;0xffffbf;0xd9ef8b;0xa6d96a;0x66bd63;0x1a9850;0x006837))));
    (`Accent; (!). flip (
            (3; (0x7fc97f;0xbeaed4;0xfdc086));
            (4; (0x7fc97f;0xbeaed4;0xfdc086;0xffff99));
            (5; (0x7fc97f;0xbeaed4;0xfdc086;0xffff99;0x386cb0));
            (6; (0x7fc97f;0xbeaed4;0xfdc086;0xffff99;0x386cb0;0xf0027f));
            (7; (0x7fc97f;0xbeaed4;0xfdc086;0xffff99;0x386cb0;0xf0027f;0xbf5b17));
            (8; (0x7fc97f;0xbeaed4;0xfdc086;0xffff99;0x386cb0;0xf0027f;0xbf5b17;0x666666))));
    (`Dark2; (!). flip (
            (3; (0x1b9e77;0xd95f02;0x7570b3));
            (4; (0x1b9e77;0xd95f02;0x7570b3;0xe7298a));
            (5; (0x1b9e77;0xd95f02;0x7570b3;0xe7298a;0x66a61e));
            (6; (0x1b9e77;0xd95f02;0x7570b3;0xe7298a;0x66a61e;0xe6ab02));
            (7; (0x1b9e77;0xd95f02;0x7570b3;0xe7298a;0x66a61e;0xe6ab02;0xa6761d));
            (8; (0x1b9e77;0xd95f02;0x7570b3;0xe7298a;0x66a61e;0xe6ab02;0xa6761d;0x666666))));
    (`Paired; (!). flip (
            (3; (0xa6cee3;0x1f78b4;0xb2df8a));
            (4; (0xa6cee3;0x1f78b4;0xb2df8a;0x33a02c));
            (5; (0xa6cee3;0x1f78b4;0xb2df8a;0x33a02c;0xfb9a99));
            (6; (0xa6cee3;0x1f78b4;0xb2df8a;0x33a02c;0xfb9a99;0xe31a1c));
            (7; (0xa6cee3;0x1f78b4;0xb2df8a;0x33a02c;0xfb9a99;0xe31a1c;0xfdbf6f));
            (8; (0xa6cee3;0x1f78b4;0xb2df8a;0x33a02c;0xfb9a99;0xe31a1c;0xfdbf6f;0xff7f00));
            (9; (0xa6cee3;0x1f78b4;0xb2df8a;0x33a02c;0xfb9a99;0xe31a1c;0xfdbf6f;0xff7f00;0xcab2d6));
            (10; (0xa6cee3;0x1f78b4;0xb2df8a;0x33a02c;0xfb9a99;0xe31a1c;0xfdbf6f;0xff7f00;0xcab2d6;0x6a3d9a));
            (11; (0xa6cee3;0x1f78b4;0xb2df8a;0x33a02c;0xfb9a99;0xe31a1c;0xfdbf6f;0xff7f00;0xcab2d6;0x6a3d9a;0xffff99));
            (12; (0xa6cee3;0x1f78b4;0xb2df8a;0x33a02c;0xfb9a99;0xe31a1c;0xfdbf6f;0xff7f00;0xcab2d6;0x6a3d9a;0xffff99;0xb15928))));
    (`Pastel1; (!). flip (
            (3; (0xfbb4ae;0xb3cde3;0xccebc5));
            (4; (0xfbb4ae;0xb3cde3;0xccebc5;0xdecbe4));
            (5; (0xfbb4ae;0xb3cde3;0xccebc5;0xdecbe4;0xfed9a6));
            (6; (0xfbb4ae;0xb3cde3;0xccebc5;0xdecbe4;0xfed9a6;0xffffcc));
            (7; (0xfbb4ae;0xb3cde3;0xccebc5;0xdecbe4;0xfed9a6;0xffffcc;0xe5d8bd));
            (8; (0xfbb4ae;0xb3cde3;0xccebc5;0xdecbe4;0xfed9a6;0xffffcc;0xe5d8bd;0xfddaec));
            (9; (0xfbb4ae;0xb3cde3;0xccebc5;0xdecbe4;0xfed9a6;0xffffcc;0xe5d8bd;0xfddaec;0xf2f2f2))));
    (`Pastel2; (!). flip (
            (3; (0xb3e2cd;0xfdcdac;0xcbd5e8));
            (4; (0xb3e2cd;0xfdcdac;0xcbd5e8;0xf4cae4));
            (5; (0xb3e2cd;0xfdcdac;0xcbd5e8;0xf4cae4;0xe6f5c9));
            (6; (0xb3e2cd;0xfdcdac;0xcbd5e8;0xf4cae4;0xe6f5c9;0xfff2ae));
            (7; (0xb3e2cd;0xfdcdac;0xcbd5e8;0xf4cae4;0xe6f5c9;0xfff2ae;0xf1e2cc));
            (8; (0xb3e2cd;0xfdcdac;0xcbd5e8;0xf4cae4;0xe6f5c9;0xfff2ae;0xf1e2cc;0xcccccc))))
    ;
    (`Set1; (!). flip (
            (3; (0xe41a1c;0x377eb8;0x4daf4a));
            (4; (0xe41a1c;0x377eb8;0x4daf4a;0x984ea3));
            (5; (0xe41a1c;0x377eb8;0x4daf4a;0x984ea3;0xff7f00));
            (6; (0xe41a1c;0x377eb8;0x4daf4a;0x984ea3;0xff7f00;0xffff33));
            (7; (0xe41a1c;0x377eb8;0x4daf4a;0x984ea3;0xff7f00;0xffff33;0xa65628));
            (8; (0xe41a1c;0x377eb8;0x4daf4a;0x984ea3;0xff7f00;0xffff33;0xa65628;0xf781bf));
            (9; (0xe41a1c;0x377eb8;0x4daf4a;0x984ea3;0xff7f00;0xffff33;0xa65628;0xf781bf;0x999999))));
    (`Set2; (!). flip (
            (3; (0x66c2a5;0xfc8d62;0x8da0cb));
            (4; (0x66c2a5;0xfc8d62;0x8da0cb;0xe78ac3));
            (5; (0x66c2a5;0xfc8d62;0x8da0cb;0xe78ac3;0xa6d854));
            (6; (0x66c2a5;0xfc8d62;0x8da0cb;0xe78ac3;0xa6d854;0xffd92f));
            (7; (0x66c2a5;0xfc8d62;0x8da0cb;0xe78ac3;0xa6d854;0xffd92f;0xe5c494));
            (8; (0x66c2a5;0xfc8d62;0x8da0cb;0xe78ac3;0xa6d854;0xffd92f;0xe5c494;0xb3b3b3))))
    ;
    (`Set3; (!). flip (
            (3; (0x8dd3c7;0xffffb3;0xbebada));
            (4; (0x8dd3c7;0xffffb3;0xbebada;0xfb8072));
            (5; (0x8dd3c7;0xffffb3;0xbebada;0xfb8072;0x80b1d3));
            (6; (0x8dd3c7;0xffffb3;0xbebada;0xfb8072;0x80b1d3;0xfdb462));
            (7; (0x8dd3c7;0xffffb3;0xbebada;0xfb8072;0x80b1d3;0xfdb462;0xb3de69));
            (8; (0x8dd3c7;0xffffb3;0xbebada;0xfb8072;0x80b1d3;0xfdb462;0xb3de69;0xfccde5));
            (9; (0x8dd3c7;0xffffb3;0xbebada;0xfb8072;0x80b1d3;0xfdb462;0xb3de69;0xfccde5;0xd9d9d9));
            (10; (0x8dd3c7;0xffffb3;0xbebada;0xfb8072;0x80b1d3;0xfdb462;0xb3de69;0xfccde5;0xd9d9d9;0xbc80bd));
            (11; (0x8dd3c7;0xffffb3;0xbebada;0xfb8072;0x80b1d3;0xfdb462;0xb3de69;0xfccde5;0xd9d9d9;0xbc80bd;0xccebc5));
            (12; (0x8dd3c7;0xffffb3;0xbebada;0xfb8072;0x80b1d3;0xfdb462;0xb3de69;0xfccde5;0xd9d9d9;0xbc80bd;0xccebc5;0xffed6f))))
    )
.z.m.gg.colour.cat20:(0x1f77b4;0xaec7e8;0xff7f0e;0xffbb78;0x2ca02c;0x98df8a;0xd62728;0xff9896;0x9467bd;0xc5b0d5;0x8c564b;0xc49c94;0xe377c2;0xf7b6d2;0x7f7f7f;0xc7c7c7;0xbcbd22;0xdbdb8d;0x17becf;0x9edae5)

.z.m.gg.colour.cat10:(0x1f77b4;0xff7f0e;0x2ca02c;0xd62728;0x9467bd;0x8c564b;0xe377c2;0x7f7f7f;0xbcbd22;0x17becf)

.z.m.gg.colour.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.gg_noColourPalette; "Colour palette not found");
        (`.gg_outOfRangePalette; "Palette does not have specified colours");
        (`.gg_layerErrorSquareType; "layer init error: square scales must be of the same scale type")))
    
.z.m.gg.colour.i.colour:colour.Aquamarine:0x7FFFD4;
colour.Azure:0xF0FFFF;
colour.Beige:0xF5F5DC;
colour.Bisque:0xFFE4C4;
colour.Black:0x000000;
colour.BlanchedAlmond:0xFFEBCD;
colour.Blue:0x0000FF;
colour.BlueViolet:0x8A2BE2;
colour.Brown:0xA52A2A;
colour.BurlyWood:0xDEB887;
colour.CadetBlue:0x5F9EA0;
colour.Chartreuse:0x7FFF00;
colour.Chocolate:0xD2691E;
colour.Coral:0xFF7F50;
colour.CornflowerBlue:0x6495ED;
colour.Cornsilk:0xFFF8DC;
colour.Crimson:0xDC143C;
colour.Cyan:0x00FFFF;
colour.DarkBlue:0x00008B;
colour.DarkCyan:0x008B8B;
colour.DarkGoldenRod:0xB8860B;
colour.DarkGray:0xA9A9A9;
colour.DarkGrey:0xA9A9A9;
colour.DarkGreen:0x006400;
colour.DarkKhaki:0xBDB76B;
colour.DarkMagenta:0x8B008B;
colour.DarkOliveGreen:0x556B2F;
colour.DarkOrange:0xFF8C00;
colour.DarkOrchid:0x9932CC;
colour.DarkRed:0x8B0000;
colour.DarkSalmon:0xE9967A;
colour.DarkSeaGreen:0x8FBC8F;
colour.DarkSlateBlue:0x483D8B;
colour.DarkSlateGray:0x2F4F4F;
colour.DarkSlateGrey:0x2F4F4F;
colour.DarkTurquoise:0x00CED1;
colour.DarkViolet:0x9400D3;
colour.DeepPink:0xFF1493;
colour.DeepSkyBlue:0x00BFFF;
colour.DimGray:0x696969;
colour.DimGrey:0x696969;
colour.DodgerBlue:0x1E90FF;
colour.FireBrick:0xB22222;
colour.FloralWhite:0xFFFAF0;
colour.ForestGreen:0x228B22;
colour.Fuchsia:0xFF00FF;
colour.Fuscia:0xFF00FF;
colour.Gainsboro:0xDCDCDC;
colour.GhostWhite:0xF8F8FF;
colour.Gold:0xFFD700;
colour.GoldenRod:0xDAA520;
colour.Gray:0x808080;
colour.Grey:0x808080;
colour.Green:0x008000;
colour.GreenYellow:0xADFF2F;
colour.HoneyDew:0xF0FFF0;
colour.HotPink:0xFF69B4;
colour.IndianRed :0xCD5C5C;
colour.Indigo :0x4B0082;
colour.Ivory:0xFFFFF0;
colour.Khaki:0xF0E68C;
colour.Lavender:0xE6E6FA;
colour.LavenderBlush:0xFFF0F5;
colour.LawnGreen:0x7CFC00;
colour.LemonChiffon:0xFFFACD;
colour.LightBlue:0xADD8E6;
colour.LightCoral:0xF08080;
colour.LightCyan:0xE0FFFF;
colour.LightGoldenRodYellow:0xFAFAD2;
colour.LightGray:0xD3D3D3;
colour.LightGrey:0xD3D3D3;
colour.LightGreen:0x90EE90;
colour.LightPink:0xFFB6C1;
colour.LightSalmon:0xFFA07A;
colour.LightSeaGreen:0x20B2AA;
colour.LightSkyBlue:0x87CEFA;
colour.LightSlateGray:0x778899;
colour.LightSlateGrey:0x778899;
colour.LightSteelBlue:0xB0C4DE;
colour.LightYellow:0xFFFFE0;
colour.Lime:0x00FF00;
colour.LimeGreen:0x32CD32;
colour.Linen:0xFAF0E6;
colour.Magenta:0xFF00FF;
colour.Maroon:0x800000;
colour.MediumAquaMarine:0x66CDAA;
colour.MediumBlue:0x0000CD;
colour.MediumOrchid:0xBA55D3;
colour.MediumPurple:0x9370D8;
colour.MediumSeaGreen:0x3CB371;
colour.MediumSlateBlue:0x7B68EE;
colour.MediumSpringGreen:0x00FA9A;
colour.MediumTurquoise:0x48D1CC;
colour.MediumVioletRed:0xC71585;
colour.MidnightBlue:0x191970;
colour.MintCream:0xF5FFFA;
colour.MistyRose:0xFFE4E1;
colour.Moccasin:0xFFE4B5;
colour.NavajoWhite:0xFFDEAD;
colour.Navy:0x000080;
colour.OldLace:0xFDF5E6;
colour.Olive:0x808000;
colour.OliveDrab:0x6B8E23;
colour.Orange:0xFFA500;
colour.OrangeRed:0xFF4500;
colour.Orchid:0xDA70D6;
colour.PaleGoldenRod:0xEEE8AA;
colour.PaleGreen:0x98FB98;
colour.PaleTurquoise:0xAFEEEE;
colour.PaleVioletRed:0xD87093;
colour.PapayaWhip:0xFFEFD5;
colour.PeachPuff:0xFFDAB9;
colour.Peru:0xCD853F;
colour.Pink:0xFFC0CB;
colour.Plum:0xDDA0DD;
colour.PowderBlue:0xB0E0E6;
colour.Purple:0x800080;
colour.Red:0xFF0000;
colour.RosyBrown:0xBC8F8F;
colour.RoyalBlue:0x4169E1;
colour.SaddleBrown:0x8B4513;
colour.Salmon:0xFA8072;
colour.SandyBrown:0xF4A460;
colour.SeaGreen:0x2E8B57;
colour.SeaShell:0xFFF5EE;
colour.Sienna:0xA0522D;
colour.Silver:0xC0C0C0;
colour.SkyBlue:0x87CEEB;
colour.SlateBlue:0x6A5ACD;
colour.SlateGray:0x708090;
colour.SlateGrey:0x708090;
colour.Snow:0xFFFAFA;
colour.SpringGreen:0x00FF7F;
colour.SteelBlue:0x4682B4;
colour.Tan:0xD2B48C;
colour.Teal:0x008080;
colour.Thistle:0xD8BFD8;
colour.Tomato:0xFF6347;
colour.Turquoise:0x40E0D0;
colour.Violet:0xEE82EE;
colour.Wheat:0xF5DEB3;
colour.White:0xFFFFFF;
colour.WhiteSmoke:0xF5F5F5;
colour.Yellow:0xFFFF00;
colour.YellowGreen:0x9ACD32;
.z.m.gg.colour.PALETTES:update
    Cat10: enlist[10]!enlist colour.cat10,
    Cat20: enlist[20]!enlist colour.cat20
    from colour.i.BREWER

.z.m.gg.colour.COLOURS:(::)



system "d .z.m";

system "d .z.m.gg";
.z.m.gg.scale.i.data.TYPES:scale.i.data.types.numeric:0;
scale.i.data.types.categorical:1;
scale.i.data.types.temporal:2;
scale.i.data.types.colour:3;
.z.m.gg.scale.i.data.TEMPORALMAP:(!) . flip (
    "dj";
    "zf";
    "uj";
    "mj";
    "vj";
    "tj";
    "nj";
    "pj")

.z.m.gg.scale.i.data.TEMPORALINTERVALS:(!) . flip (
    (`year; 1 2 5 10 20 25 50 100);
    (`month; 1 2 3 4 6);
    (`day; 1 2 7 14)
    )
.z.m.gg.scale.i.data.SCALEGEOMS:scale.i.data.g.DEF_POINT  : `DEFAULT_POINT;
scale.i.data.g.DEF_LINE   : `DEFAULT_LINE;
scale.i.data.g.DEF_RECT   : `DEFAULT_RECT;
.z.m.gg.scale.i.data.PRINTPRECISION:6
.z.m.gg.scale.i.data.MAXCHARS:12
.z.m.gg.scale.i.data.DEFAULTS:(!) . flip (
    (`cat; (::;::));
    (`default; (::;::));
    (`compose; (::;::));
    (`base; ())
    )
.z.m.gg.scale.i.data.DAYS:`Monday`Tuesday`Wednesday`Thursday`Friday`Saturday`Sunday
// @qlintsuppress UNUSED_INTERNAL(1)
.z.m.gg.scale.i.data.onLoad:{[]
    
    
    .z.m.axdatatype.create[ .z.M.gg.scale.base;

        `empty`initialized`label`validateF`initF`breaksF`applyType`applyF
        ,`inverseType`inverseF`guideF`domainF`formatF`breaks`limits`geom_limits
        ,`true_limits`maxChars`extension`extend`square`i_hasLimits`i_hasBreaks`i_orig`i_origScale;

        `empty`initialized`breaks`limits`geom_limits`true_limits`formatF
        ,`maxChars`extension`extend`square`i_hasLimits`i_hasBreaks`i_orig`i_origScale];
    
    
    .z.m.axdatatype.extend[ .z.M.gg.scale.ty.cat; `i_odistinct`i_distinct; `i_odistinct`i_distinct;  .z.M.gg.scale.base];
    
    
    .z.m.axdatatype.extend[ .z.M.gg.scale.ty.default; `i_type`i_scale; `label`inverseType`applyType`i_type`i_scale;  .z.M.gg.scale.base];
    
    
    .z.m.axdatatype.extend[ .z.M.gg.scale.ty.compose; `i_f`i_g; `i_f`i_g;  .z.M.gg.scale.base];
    
    }

.z.m.gg.scale.i.data.onLoad[];
system "d .z.m";

system "d .z.m.gg";
.z.m.gg.fmt.date:`chars`formatF!(
    30;
    {[d]
        d: "d"$d;
        ms : ``Jan`Feb`Mar`Apr`May`Jun`Jul`Aug`Sep`Oct`Nov`Dec;
        ps : "." vs string d;
        : (string ms value ps 1), " ", ps[2], "\n", ps 0;
        })

.z.m.gg.fmt.timestamp:`chars`formatF!(
    30;
    {[d]
        d     : "p"$d;
        ps    : "D" vs string d;
        time  : "." vs ps 1;
        nanos : $[all"0" = time 1; ""; "." , time[1] , "\n"];
        : nanos , time[0] , "\n", fmt.date[`formatF] value ps 0;
        })

.z.m.gg.fmt.timespan:`chars`formatF!(
    30;
    {[d]
        d     : "n"$d;
        ps    : "D" vs string d;
        time  : "." vs ps 1;
        nanos : $[all"0" = time 1; ""; "." , time[1] , "\n"];
        : nanos , time[0] , "\n", ps[0] , "D";
        })

.z.m.gg.fmt.month:`chars`formatF!(
    30;
    {[x]
        m  : "m"$x;
        ms : ``Jan`Feb`Mar`Apr`May`Jun`Jul`Aug`Sep`Oct`Nov`Dec;
        ps : "." vs string m;
        : (string ms value ps 1), "\n", ps 0
        })
.z.m.gg.fmt.datetime:`chars`formatF!(
    30;
    {[d]
        d: "z"$d;
        ps : "T" vs string d;
        : ps[1], "\n", fmt.date[`formatF] value ps 0;
        })

system "d .z.m";

system "d .z.m.gg";
// @fileOverview 
// Returns the counter-clockwise angle from the x-axis of the given vector
// @param v {(float;float)} 2D vector
// @returns {float} angle in radians
.z.m.gg.proj.angle:{[v]
    pi: proj.PI;
    v:  proj.normalize v;
    if[0=v 0;:(pi%2*v 1) mod 2*pi];
    if[0=v 1;:((3*pi%2)+pi%2*v 0) mod 2*pi];

    : ($[0<v 0;0;pi]+atan v[1]%v 0) mod 2*pi
    }

// @fileOverview Cross product of 2 vectors. Vectors must have the same count.
// @param v1 {number[]}
// @param v2 {number[]}
// @returns {number[]} cross product
.z.m.gg.proj.crossProduct:{[v1;v2]
    : (
        (v1[1]*v2 2) - v1[2]*v2 1;
        (v1[2]*v2 0) - v1[0]*v2 2;
        (v1[0]*v2 1) - v1[1]*v2 0
        );
    };
// @fileOverview Dot product of 2 vectors. Vectors must have same count.
// @param v1 {number[]}
// @param v2 {number[]}
// @returns {number} Dot product
.z.m.gg.proj.dot:{[v1;v2]
    :sum v1*v2;
    }
// @fileOverview 
// Determines whether a 2D point is in the geom drawing area
// @returns {bool}
.z.m.gg.proj.inDrawingArea:{[b1;b2;pt]
    n: proj.crossProduct[b1;b2];
    :$[any {[b1;b2;n;pt;idx;xi] // Check non-boundary plane collisions
            if[0=n idx;:0b];
            s: (xi-(pt[0]*b1 idx)+pt[1]*b2 idx)%n idx;
            : all (r<1) and 1<1+r: _[;idx] (s*n) + (pt[0]*b1) + pt[1]*b2;
            }[b1;b2;n;pt] .' 0 1 2 cross 0 1;
        1b;
        3<sum {[b1;b2;n;pt;idx;xi]
            if[0=n idx;:0b];
            s: (xi-(pt[0]*b1 idx)+pt[1]*b2 idx)%n idx;
            : all (r<=1) and 1<=1+r: _[;idx] (s*n) + (pt[0]*b1) + pt[1]*b2;
            }[b1;b2;n;pt] .' 0 1 2 cross 0 1;
        1b;
        0b];
    }

// @fileOverview 
// Project a list of 3D points onto their closest points on a 2D plane
// Both basis vectors are assumed to be normalized
// @param b1 {(number;number;number)} first basis vector of the plane
// @param b2 {(number;number;number)} second basis vector of the plane
// @param v {(number;number;number)[]} list of points to project to the plane
// @returns {(float;float)[]} list of 2D points in the plane's basis
.z.m.gg.proj.multi.planeProjection:{[b1;b2;v]
    : flip (3_) each -1_ proj.rref flip (b1;b2;proj.crossProduct[b1;b2]),v;
    }

// @fileOverview 
// Return the index of the nearest element in one dimension
// to the given point
// @param point {number} 
// @param circles {number[]} 
// @returns {dict} the indices of the nearest elements and the distance to that element
.z.m.gg.proj.nearest1D:{[point; circles]
    distance : abs point - circles;
    m : min distance;
    : `idx`distance!(where m = distance; m);
    }
// @fileOverview 
// Return the nearest element to a point in two dimensions
// @param pointX {number} 
// @param pointY {number} 
// @param circleX {number[]} 
// @param circleY {number[]} 
.z.m.gg.proj.nearest2D:{[pointX; pointY; circleX; circleY]
    sqr     : {x*x};
    dcenter : sqrt sqr[pointX - circleX] + sqr pointY - circleY;
    m       : min dcenter;
    : `idx`distance!(where m = dcenter; m);
    }
// @fileOverview Normalizes a vector, i.e. sets it's length to one without modifying direction
// @param v {number[]} vector
// @returns {number[]} normalized vector
.z.m.gg.proj.normalize:{[v]
    :v % sqrt sum v*v;
    }

// @fileOverview 
// Project 3D points onto their closest point on a 2D plane
// Both basis vectors are assumed to be normalized
// @param b1 {(float;float;float)} first basis vector of the plane
// @param b2 {(float;float;float)} second basis vector of the plane
// @param v {(float;float;float) | (float[];float[];float[])} point(s) to project to the plane
// @returns {(float;float) | (float[];float[])} 2D point(s) in the plane's basis
.z.m.gg.proj.planeProjection:{[b1;b2;v]
    : proj.splitRref[flip (b1;b2;proj.crossProduct[b1;b2]);v][1;0 1];
    };

// @fileOverview Return distance from point to line
// @param x {number} pt x
// @param y {number} pt y
// @param x1 {number} line x1
// @param y1 {number} line y1
// @param x2 {number} line x2
// @param y2 {number} line y2
// @returns {number}
.z.m.gg.proj.pointLineDistance:{[x;y;x1;y1;x2;y2]
    ii: neg (( (x1-x)*x2-x1 )+ (y1-y)*y2-y1 ) % {x*x}[x2-x1] + {x*x}y2-y1;
    d2: {[x;y;x1;y1;x2;y2] abs[((x2-x1)*y1-y) - (y2-y1)*x1-x] % sqrt {x*x}[x2-x1] + {x*x}y2-y1};
    : $[ii within 0 1;
        d2[x;y;x1;y1;x2;y2];
        min (sqrt {x*x}[x2-x] + {x*x}y2-y; sqrt {x*x}[x1-x] + {x*x}y1-y)]
    }
// @fileOverview 
// Whether a point is with given bounds
// @param pt {(number;number)} 
// @param bs {((number;number);(number;number))} (xmin and ymin;xmax and ymax)
.z.m.gg.proj.pointWithin:{[pt; bs]
    : (pt[0] within bs 0) and pt[1] within bs 1
    }

// @fileOverview 
// Project a set of values from a src range to a dest range
// @param src {(number;number)} min and max source 
// @param dest {(number;number)} min and max destination 
// @param v {number[]} values to project (assumed within source range)
// @returns {number[]}
//
// @example
//      proj.proj[0 1; 0 500; 0.5] 
//      /=> 250
.z.m.gg.proj.proj:{[src; dest; v]
    sr : src[1]  - src 0;
    dr : dest[1] - dest 0;
    : dest[0] + (dr % sr) * v - src 0
    }

// @fileOverview 
// Returns the quadrant which vector v belongs to. The quadrants are ordered
// counter-clockwise, numbered 0-3, and quadrant 0 is centered around the x-axis.
// @returns {int} number of the quadrant
.z.m.gg.proj.quadrant:{[v]
    : floor ((proj.angle[v]+proj.PI%4)%proj.PI%2) mod 4;
    }
// @fileOverview 
// Calculates the row echelon form of a matrix
// @param m {float[][]} a rectangular matrix
// @returns {float[][]} the row echelon form of the given matrix
.z.m.gg.proj.ref:{[m]
    :last .[{[r;c;m](r<count m) and c<count m 0};] .[{[r;c;m]
            if[0=count rows:r+where 0<>r _ m[;c];:(r;c+1;m)];
            m[s,r]: m r,s: rows l?max l:abs m[rows;c];
            m[r]%:m[r;c];
            m: @[m;r+1+til (count m)-r+1;{[mr;c;row] @[row-mr*row c;c;:;0f]}[m r;c]];
            :(r+1;c+1;m);
            };]/(0;0;m);
    }


// @fileOverview 
// Calculates the reduced row echelon form of a matrix
// @param m {float[][]} a rectangular matrix
// @returns {float[][]} the reduced row echelon form of the given matrix
.z.m.gg.proj.rref:{[m]
    m: proj.ref m;
    : last .[{[r;m]0<=r};] .[{[r;m]
            if[h.null c:first where 1=m r;:(r-1;m)];
            m: @[m;reverse til r;{[mr;c;row] @[row-mr*row c;c;:;0f]}[m r;c]];
            :(r-1;m);
            };]/(-1+count m; m);
    }
// @fileOverview 
// Calculates the row echelon form of a matrix, applying identical
// row operations to a second matrix.
// Row reduction of a matrix (A|B).
// @param A {float[][]} a rectangular matrix
// @param B {float[][]} a rectangular matrix with the same number of rows as A
// @returns {float[][]} the row echelon form of the given matrix
.z.m.gg.proj.splitRef:{[A;B]
    if[not count[A]=count B;
        '"splitRef: matrices must have the same number of rows"];
    : -2#.[{[r;c;A;B](r<count A) and c<count A 0};] .[{[r;c;A;B]
            if[0=count rows:r+where 0<>r _ A[;c];:(r;c+1;A;B)];
            A[s,r]: A r,s: rows l?max l:abs A[rows;c];
            B[s,r]: B r,s;
            A[r]%: d: A[r;c];
            B[r]%: d;
            
            is: r+1+til (count A)-r+1;
            A[is]-: (A[r]*) each ks: A[is;c];
            B[is]-: (B[r]*) each ks;
            A[is;c]: 0f;
            
            :(r+1;c+1;A;B);
            };]/(0;0;"f"$A;"f"$B);
    }

// @fileOverview 
// Calculates the reduced row echelon form of a matrix, applying identical
// row operations to a second matrix.
// Row reduction of a matrix (A|B).
// @param A {float[][]} a rectangular matrix
// @param B {float[][]} a rectangular matrix with the same number of rows as A
// @returns {float[][]} the row echelon form of the given matrix
.z.m.gg.proj.splitRref:{[A;B]
    AB: proj.splitRef[A;B];
    : -2# .[{[r;A;B]0<=r};] .[{[r;A;B]
            if[h.null c:first where 1=A r;:(r-1;A;B)];
            is: reverse til r;
            A[is]-: (A[r]*) each ks: A[is;c];
            B[is]-: (B[r]*) each ks;
            A[is;c]: 0f;
            :(r-1;A;B);
            };]/(-1+count A),AB;
    }

.z.m.gg.proj.PI:4*atan 1
system "d .z.m";

system "d .z.m.gg";
// @subcategory Scales
// @fileOverview 
// Return an alpha (opacity) scale between the min and max alpha arguments.
// Note - alpha scales can only map numeric variables. An error will be thrown if
// a categorical variable is given.
// @param minAlpha {long} between 0 and 255 
// @param maxAlpha {long} between 0 and 255
// @returns {dict} scale
// @example A scale from 50 to 255 (max) opacity
// .z.m.gg.scale.alpha[50;255] 
.z.m.gg.scale.alpha:{[minAlpha; maxAlpha]
    
    if [minAlpha >= maxAlpha;             '.z.m.axlocalize.t(`.gg_scaleErrorInverted;"alpha")]; /dnl
    if [(minAlpha < 0) or minAlpha > 255; '.z.m.axlocalize.t(`.gg_scaleErrorMinRange;"alpha")]; /dnl
    if [(maxAlpha < 0) or maxAlpha > 255; '.z.m.axlocalize.t(`.gg_scaleErrorMaxRange;"alpha")]; /dnl
    
    : scale.new [`base; scale.i.data.DEFAULTS`base] (
        `alpha;
        {[v]
            .[scale.i.validate; (v;"bxhijefpmdznuvt"); {'.z.m.axlocalize.t[(`.gg_scaleErrorPre;"alpha")],x}]; /dnl
            : 1b;
            };
        scale.i.initContinuous;
        {[sc]
            if [not h.null scale.base.breaks sc; '.z.m.axlocalize.t(`.gg_scaleErrorExplicitBreaks;"alpha")]; /dnl
            : scale.i.initContinuousBreaks sc;
            };
        scale.i.data.types.numeric;
        {[m;M;s;x]
            colour.setAlpha[;0i] proj.proj[s`limits; (m;M)]
                $[s[`i_orig] in "bxhijef"; x; scale.i.data.TEMPORALMAP[s`i_orig]$x]  /dnl
            }[minAlpha;maxAlpha];
        scale.i.data.types.numeric;
        scale.i.inverseContinuous;
        {[s]
            grad: colour.gradientTable [``pos`limits!(::;0 255;0 255); 2#0x0 sv 0xff,colour.Black; 255];
            alimits : first each 0x0 vs' scale.apply [s; s`limits];
            : etable.el [scale.i.data.g.DEF_RECT] {[c; m; M; grad; ii]
                x: grad ii;
                : `x`y`w`h`colour!(x`pos; 1; x`size; 0.15; colour.setAlpha[m + (M - m) * ii % c] first x`colour);
                }[255; alimits 0; alimits 1; grad] each til count grad;
            };
        {[s] scale.apply[s;s`true_limits] }
        );
    }

// @subcategory Scales
// @fileOverview 
// Apply a scale to a vector of data
// @param s {dict} scale 
// @param v {any[]} data
// @returns {any[]} scaled data
// @see gg.scale.init
.z.m.gg.scale.apply:{[s; v] (scale.base.applyF s)[s;v] }
// @subcategory Scales
// @private
// @fileOverview 
// Extend a scales geometry limits by the `extension percent
// @param s {dict} scale
// @returns {dict} updated scale
.z.m.gg.scale.applyExtension:{[s]
    if [0 = scale.base.extension s;
        : s];
    
    gl : scale.base.geom_limits s;
    e  : %[;2] (max 0,scale.base.extension s) * h.safeRange gl;
    
    candidates : (gl[0] - e; gl[1] + e);
    
    limits: (min;max) @' candidates ,' gl;
    
    : scale.base.with.geom_limits[limits] s;
    }
 
// @subcategory Scales
// @private
// @fileOverview 
// Apply a format function to a scale and value
// @param s {dict} scale 
// @param v {any} scale value
// @returns {symbol}
.z.m.gg.scale.applyFormat:{[s; v] (scale.base.formatF s) v }
// @subcategory Scale Settings
// @fileOverview 
// Specify the break points (ticks) that should be used for
// the scale. This will override the generated breakpoints
// for the scale.
// @param breaks {any[]} list of break points in the domain on the scale 
// @param s {dict} scale
// @returns {dict} extended scale
// @example A scale with default breaks
// .z.m.gg.scale.linear
// @example A scale with explicit breaks at 0 50 60 65 and 100
// .z.m.gg.scale.breaks[0 50 60 65 100] .z.m.gg.scale.linear
// @example A scale with no breaks
// .z.m.gg.scale.breaks[()] .z.m.gg.scale.linear
.z.m.gg.scale.breaks:{[breaks; s] $[(::)~s; ::; scale.base.with.breaks[breaks] s] }
// @subcategory Scales
// @fileOverview 
// Create a scale for a categorical variable (any data type).
// If given a numeric variable, the distinct numbers will be treated
// as independent categories, and will be evenly spaced along the axis.
// See .z.m.gg.scale.linear for a linear numeric scale.
// 
// The scale can *optionally* be initialized with a sorting function. This
// function can reorder the categories so they display in any given order. By
// default, the categories are sorted ascending. For default sorting behaviour,
// provide no argument:  .z.M.gg.scale.categorical[]`.
//
// Note - the sort function is a function from the domain to the ordered domain.
// Elements can be injected or removed. Whatever is returned from the function
// will be displayed on the scale. To restrict a specific order to only the visible
// records, intersect the specific order with the domain as in the last example below.
// This allows drilldown to maintain the ordering while only displaying visible categories.
//
// @see gg.scale.linear
// @returns {dict} scale
// @example Default ascending categorical scale
// .z.m.gg.scale.categorical[]
// @example Descending categorical scale
// .z.m.gg.scale.categorical[desc]
// @example Specific ordering in categorical scale
// .z.m.gg.scale.categorical[{`IF`VVS1`VVS2`VS1`VS2`SI1`SI2`I1 inter x}]
.z.m.gg.scale.categorical:{[sortF]
    : scale.new [`cat; .z.m.gg.scale.i.data.DEFAULTS`cat] (
        `categorical;
        {[v]1b};
        
        {[sortF; s; vector]
            if [(not h.null sortF) & 100 > type sortF;
                '"Error applying categorical scale: argument must be a sort function"];
            d : $[h.null sortF; scale.i.defaultSort; sortF] distinct vector;
            m : 0;
            M : count[d] - 1;
            trueLimits : (m;M);
            if [m = M;
                m -: 1;
                M +: 1];
            limits : $[not h.null scale.base.limits s;
                (m;M)^d?scale.base.limits s;
                (m;M)];
            : scale.base.with.limits         [limits]
                scale.base.with.true_limits  [trueLimits]
                scale.ty.cat.with.i_distinct [d] s;
            } sortF;
        
        scale.i.initCatBreaks;
        scale.i.data.types.numeric;
        
        {[sortF;s;x]
            : scale.i.applyCat[sortF; s; x]
            } sortF;
        
        scale.i.data.types.categorical;
        {[s;x] (scale.ty.cat.i_distinct s) "j"$x };
        {[s]'`noguide};
        scale.ty.cat.i_distinct
        );
    }

// @subcategory Scales
// @fileOverview 
// Create a circle area scale, scaling to areas between the given max and min.
// This scale is a good candidate for coupling with a size aesthetic mapping on a 
// point geometry.
// @see qp.point
// @see qp.s.aes
// @see gg.scale.circle.radius
// @param m {long} min area 
// @param M {long} max area 
// @example Circle area scale
// .z.m.gg.scale.circle.area[5;50]
.z.m.gg.scale.circle.area:{[m;M]
    
    if [m >= M;  '.z.m.axlocalize.t(`.gg_scaleErrorInverted;"circle area")];  /dnl
    if [m < 0;   '.z.m.axlocalize.t(`.gg_scaleErrorMinRange2;"circle area")]; /dnl
    if [M < 0;   '.z.m.axlocalize.t(`.gg_scaleErrorMaxRange2;"circle area")]; /dnl
    
    : scale.new [`base; scale.i.data.DEFAULTS`base] (
        `circle.area;
        {[v]
            .[scale.i.validate; (v;"bxhijefpmdznuvt"); {'.z.m.axlocalize.t[(`.gg_scaleErrorPre;"circle area")],x}]; /dnl
            : 1b;
            };
        scale.i.initContinuous;
        {[sc]
            if [not h.null scale.base.breaks sc; '.z.m.axlocalize.t(`.gg_scaleErrorExplicitBreaks;"circle area")]; /dnl
            : scale.i.initContinuousBreaks sc;
            };
        scale.i.data.types.numeric;
        {[m;M;s;x] sqrt proj.proj[s`limits; (m;M); $[s[`i_orig] in "bxhijef"; x; scale.i.data.TEMPORALMAP[s`i_orig]$x]] % acos -1 }[m;M]; /dnl
        scale.i.data.types.numeric;
        scale.i.inverseContinuous;
        {[m;M;s]
            xs : proj.proj[s`limits; 0 1] s`breaks;
            rs : "f"$sqrt proj.proj[s`limits; (m;M); s`breaks] % acos -1;
            : etable.el[scale.i.data.g.DEF_POINT] {[x;r]
                : `x`y`colour`size!(x; 1 - 0.10; 0xff,colour.Black; r);
                }'[xs; rs];
            }[m;M];
        {[s] scale.inverse[s;s`true_limits] }
        );
    }

// @subcategory Scales
// @fileOverview 
// Create a circle radius scale, scaling to radii between the given max and min.
// This scale is a good candidate for coupling with a size aesthetic mapping on a 
// point geometry, however, the points will grow quicker than their underlying value.
// For a linear growth, see  .z.M.gg.scale.circle.area`.
// @see qp.point
// @see qp.s.aes
// @see gg.scale.circle.area
// @param m {long} min area 
// @param M {long} max area 
// @example Circle area scale
// .z.m.gg.scale.circle.radius[2;6]
.z.m.gg.scale.circle.radius:{[m;M]
    
    if [m >= M;  '.z.m.axlocalize.t(`.gg_scaleErrorInverted;"circle radius")];  /dnl
    if [m < 0;   '.z.m.axlocalize.t(`.gg_scaleErrorMinRange2;"circle radius")]; /dnl
    if [M < 0;   '.z.m.axlocalize.t(`.gg_scaleErrorMaxRange2;"circle radius")]; /dnl
    
    : scale.new [`base; scale.i.data.DEFAULTS`base] (
        `circle.radius;
        {[v]
            .[scale.i.validate; (v;"bxhijefpmdznuvt"); {'.z.m.axlocalize.t[(`.gg_scaleErrorPre;"circle radius")],x}]; /dnl
            : 1b;
            };
        scale.i.initContinuous;
        {[sc]
            if [scale.base.i_hasBreaks sc; '.z.m.axlocalize.t(`.gg_scaleErrorExplicitBreaks;"circle radius")]; /dnl
            : scale.i.initContinuousBreaks sc;
            };
        scale.i.data.types.numeric;
        {[m;M;s;x] proj.proj[s`limits; (m;M); $[s[`i_orig] in "bxhijef"; x; scale.i.data.TEMPORALMAP[s`i_orig]$x]] }[m;M]; /dnl
        scale.i.data.types.numeric;
        scale.i.inverseContinuous;
        {[m;M;s]
            xs : proj.proj[s`limits; 0 1] s`breaks;
            rs : proj.proj[s`limits; (m;M)] s`breaks;
            : {[x;r]
                : etable.el[scale.i.data.g.DEF_POINT] `x`y`colour`size!(x; 1 - 0.10; 0xff,colour.Black; r);
                }'[xs; rs];
            }[m;M];
        {[s] scale.inverse[s;s`true_limits] }
    );
    }

// @subcategory Scales
// @fileOverview 
// Create a new categorical color scale using the list 
// of colours given. If there are more values in the list
// than colours given, then the colours will wrap to include
// all values (note, values will not have unique colors if
// this is the case).
//
// For example:
//
// `` .z.m.gg.scale.colour.cat `green`red ``
// // or
// `` .z.m.gg.scale.colour.cat (.z.m.gg.colour.Green; .z.m.gg.colour.Red) ``
// // or
// `` .z.m.gg.scale.colour.cat `blues `` to use a named colour palette
//
// Alternatively, a dictionary of categories to colours can be provided
// to make the colour mapping explicit. For example, if there are two 
// categories in the domain: `` `pass`fail ``, we can assign `` `pass `` to
// green and `` `fail `` to red with:
//
// `` .z.m.gg.scale.colour.cat `pass`fail!(.z.m.gg.colour.Green; .z.m.gg.colour.Red) ``
//
// See .z.m.gg.colour.COLOURS for available colours.
// @see gg.colour.COLOURS
// @param colours {byte[][]} list of colours (0xrrggbb)
// @returns {dict} categorical colour scale
// @example Colour scale with 3 built-in colours
// .z.m.gg.scale.colour.cat (.z.m.gg.colour.SteelBlue; .z.m.gg.colour.FireBrick; .z.m.gg.colour.Green)
// @example Colour scale with 3 built-in colours by symbol
// .z.m.gg.scale.colour.cat `steelblue`firebrick`green
// @example Colour scale with 4 RGB colours
// .z.m.gg.scale.colour.cat (0x336699; 0x669933; 0x993366; 0x558899)
// @example Colour scale with 4 RGB colours and explicit mapping
// .z.m.gg.scale.colour.cat `a`b`c`d!(0x336699; 0x669933; 0x993366; 0x558899)
// @example Colour scale using a best-effort number of red colours from the Reds palette
// .z.m.gg.scale.colour.cat `reds
.z.m.gg.scale.colour.cat:{[colours]
    
    $[not -11h ~ type colours;
        colours: colour.qualify each colours;
        colours: lower colours];
    
    errors: `badlist`baddict!(.z.m.axlocalize.t`.gg_colourErrorBadList; .z.m.axlocalize.t`.gg_colourErrorBadDict);
    
    if [0h ~ type colours;
        if [not all 4h = type each colours; 'errors`badlist];
        if [not all 3 = count each colours; 'errors`badlist]];
    
    if [99h ~ type colours;
        if [not all 4h = type each value colours; 'errors`baddict];
        if [not all 3 = count each value colours; 'errors`baddict]];
    
    : scale.new [`cat; scale.i.data.DEFAULTS`cat] (
        `fillCat;
        {[colours;v]
            if [99h ~ type colours;
                if [not abs[type v] ~ abs type key colours;
                    '.z.m.axlocalize.t`.gg_colourErrorDomain]];
            : 1b;
            } colours;
        
        {[s; vector]
            d: reverse scale.i.defaultSort distinct vector;
            trueLimits : (0; count d);
            limits : $[not h.null scale.base.limits s;
                d?scale.base.limits s;
                (0; count d)];
            if [limits[0] = limits 1;
                limits[0] -: 1;
                limits[1] +: 1];
            odistinct : $[not h.null scale.ty.cat.i_odistinct s;
                (scale.ty.cat.i_odistinct s) , d except scale.ty.cat.i_odistinct s;
                d];
            : scale.base.with.limits            [limits]
                scale.base.with.true_limits     [trueLimits]
                scale.ty.cat.with.i_distinct    [d]
                scale.ty.cat.with.i_odistinct   [odistinct]  s;
            };
        
        scale.i.initCatBreaks;
        scale.i.data.types.numeric;
        
        {[colours; s; x]
            if [-11h ~ type colours;
                colours: colour.resolvePalette[colours; count scale.ty.cat.i_distinct s]];
                
            colours: 0x0 sv'0x0,/:colours;
            $[  .z.m.axq.isList[x] and $[99h~type colours; not type[x] ~ type first key colours; 0b];
                    @[c;ii;:;(count ii:where 0 = count each c:colours x)#enlist 0x0 sv 0x00,.z.m.gg.colour.Black];
                h.and[colours; '[99h ~; type]; {x in key y} x];
                    colours x;
                99h ~ type colours;
                    0x0 sv 0x00,.z.m.gg.colour.Black;
                    colours h.findCat[scale.ty.cat.i_odistinct s;x] mod count colours]
            } colours;
        
        scale.i.data.types.categorical;
        {[s;x] (scale.ty.cat.i_distinct s) "j"$x };
        
        {[colours;s]
            if [-11h ~ type colours;
                colours: colour.resolvePalette[colours; count scale.ty.cat.i_distinct s]];
            colours: 0x0 sv'0x0,/:colours;
            grad : colour.gradientTable [
                ``pos`limits!(::;0 255;0 255);
                2#0x0 sv 0xff,colour.Black;
                count scale.ty.cat.i_distinct s];
            : etable.el[etable.g.RECT] {[s;x]
                : `x`y`w`h`colour!(
                        x`pos; 1; x`size; 0.15; colour.setAlpha[0xff] first .z.m.gg.scale.apply[s;enlist (scale.ty.cat.i_distinct s) x`i])
                }[s] each grad;
            } colours;
        scale.ty.cat.i_distinct
        );
    }

.z.m.gg.scale.colour.gradient:{[minFill; maxFill]
    : scale.colour.gradientN[::; (minFill;maxFill)]
    }


.z.m.gg.scale.colour.gradient2:{[midpoint; minFill; middleFill; maxFill]
    : scale.colour.gradientN[midpoint; (minFill;middleFill;maxFill)]
    }


.z.m.gg.scale.colour.gradientN:{[midpoints; fill]
    
    if [-11h ~ type fill;
        palettes: (lower key colour.PALETTES)!value colour.PALETTES;
        fill: {x max key x} palettes lower fill];
    
    fill: colour.qualify each fill;

    { if [not 4h ~ type  x; '.z.m.axlocalize.t(`.gg_colourGradErrorType1;"colour gradient")]; } each fill;
    { if [not 3 = count x;  '.z.m.axlocalize.t(`.gg_colourGradErrorType2;"colour gradient")]; } each fill;
    
    : scale.new [`base; scale.i.data.DEFAULTS`base] (
        `gradient;
        all{[m;v]
            .[scale.i.validate; (v;"bxhijefpmdznuvt"); {'.z.m.axlocalize.t[(`.gg_scaleErrorPre;"colour gradient")],x}]; /dnl
            if [(not m ~ (::)) & not  h.metatype[([]x:enlist m); `x] ~ h.metatype[([]x:v); `x];
                '.z.m.axlocalize.t`.gg_colourGrad2ErrorDomain];
            : 1b;
            }'[midpoints]enlist@;
        scale.i.initContinuous;
        {[sc]
            if [scale.base.i_hasBreaks sc; '.z.m.axlocalize.t(`.gg_scaleExplicitBreaks;"colour gradient")]; /dnl
            : scale.i.initContinuousBreaks sc;
            };
        scale.i.data.types.numeric;
        {[fs;ms;s;x]
            info: scale.i.gradInfo[count fs; ms; s];
            : first each colour.vecgradient[; info`pos; fs] each x
            }[fill;midpoints];
        scale.i.data.types.colour;
        scale.i.inverseContinuous;
        {[fs;ms;s]
             info: scale.i.gradInfo[count fs; ms; s];
             t: colour.gradientTable [info;;255] scale.apply[s; info`pos];
             : etable.el[etable.g.RECT] { `x`y`w`h`colour!(x`pos; 1; x`size; 0.15; colour.setAlpha[0xff] first x`colour) } each t;
             }[fill;midpoints];
        {[s] scale.inverse[s;s`true_limits] });
    }

// @subcategory Scales
// @private
// @returns {dict} scale
.z.m.gg.scale.colour.i.default:{[dark; light]
    dark:  colour.qualify dark;
    light: colour.qualify light;
    
    : scale.new [`default; .z.m.gg.scale.i.data.DEFAULTS`default] (
        `colour.default;
        {[v]1b};
        
        {[dark; light; scale; vector]
            t : $[vector ~ (); "j"; h.metatype[([]x:vector); `x]];
            sc : $[t in "bxhijefpmdznuvt"; /dnl
                scale.colour.gradient[dark; light];
                scale.colour.cat10[]];
            : scale.ty.default.with.i_type[t]
                scale.ty.default.with.i_scale[sc]
                    scale.init[sc; vector];
            }[dark; light];
        
        {[s] scale.initBreaks scale.ty.default.i_scale s };
        scale.i.data.types.numeric;
        {[s;x] scale.apply[scale.ty.default.i_scale s; x] };
        scale.i.data.types.colour;
        {[s;x] scale.inverse[scale.ty.default.i_scale s; x] };
        {[s] scale.guide scale.ty.default.i_scale s };
        {[s] scale.inverse[s; scale.base.true_limits s] }
        );
    }


.z.m.gg.scale.colour.i.default2:{[gradients; categories]
    
    : scale.new [`default; .z.m.gg.scale.i.data.DEFAULTS`default] (
        `colour.default;
        {[v]1b};
        
        {[gradients; categories; scale; vector]
            t : $[vector ~ (); "j"; h.metatype[([]x:vector); `x]];
            sc : $[t in "bxhijefpmdznuvt"; /dnl
                scale.colour.gradientN[::] gradients;
                scale.colour.cat categories];
            : scale.ty.default.with.i_type[t]
                scale.ty.default.with.i_scale[sc]
                    scale.init[sc; vector];
            }[gradients; categories];
        
        {[s] scale.initBreaks scale.ty.default.i_scale s };
        scale.i.data.types.numeric;
        {[s;x] scale.apply[scale.ty.default.i_scale s; x] };
        scale.i.data.types.colour;
        {[s;x] scale.inverse[scale.ty.default.i_scale s; x] };
        {[s] scale.guide scale.ty.default.i_scale s };
        {[s] scale.inverse[s; scale.base.true_limits s] }
        );
    }

// @subcategory Scales
// @fileOverview
// Compose takes two scales f and g and returns a new scale of the composition f . g
// @param f {dict} f scale
// @param g {dict} g scale
// @returns {dict} scale of f . g
// @example A log log scale
// .z.m.gg.scale.compose[.z.m.gg.scale.log; .z.m.gg.scale.log]
// @example A log fill scale
// .z.m.gg.scale.compose[.z.m.gg.scale.colour.cat10; .z.m.gg.scale.log]
.z.m.gg.scale.compose:{[f; g]
    : scale.new [`compose; scale.i.data.DEFAULTS`compose] (
        f`label;
        {[g; s; v] scale.validate[g; v] } g;
        {[f; g; s; v]
            g : scale.init[g; v];
            v : scale.apply[g; v];
            f : scale.init[f; v];
            : scale.ty.compose.with.i_f[f]
                scale.ty.compose.with.i_g[g]
                    s , `applyF`breaksF`applyType`inverseType`guideF`domainF _ f;
            }[f;g];
        {[s] (scale.ty.default.breaksF scale.ty.compose.i_f s) scale.ty.compose.i_f s };
        scale.ty.default.applyType g;
        {[s;x] scale.apply[scale.ty.compose.i_f s] scale.apply[scale.ty.compose.i_g s] x };
        scale.ty.default.inverseType f;
        {[s;x] scale.inverse[scale.ty.compose.i_g s] scale.inverse[scale.ty.compose.i_f s] x };
        {[s] scale.guide scale.ty.compose.i_f s };
        {[s] scale.domain scale.ty.compose.i_g s }
        );
    }

// @subcategory Scales
// @private
// @fileOverview 
// Return the domain function from the scale 
// @param s {dict} scale
// @returns {function} domain function 
.z.m.gg.scale.domain:{[s] (scale.base.domainF s) s }
// @subcategory Scale Settings
// @fileOverview 
// Turn on/off the auto-extend that certain scales have (i.e., numeric scales)
// @param bool {boolean} on or off 
// @param sc {dict} scale
// @returns {dict} updated scale
// @example Scale with default extension
// .z.m.gg.scale.linear
// @example Scale with max and min identical to the data max and min
// .z.m.gg.scale.extend[0b] .z.m.gg.scale.linear
.z.m.gg.scale.extend:{[bool; sc] scale.base.with.extend[bool] sc }
// @subcategory Scale Settings
// @fileOverview 
// Set the extension on a scale.
//
// The extension is a percent value. The limits
// of the scale will be extended by the given percent
// of the domain. The effect is an amount of padding between
// the edges of the frame and the chart itself.
//
// Note - the extension will *not* be disabled when drilling down. 
// The result of the drilldown will have the same padding percent.
// @param p {float} percent (.05 for 5%)
// @param s {dict} scale 
// @returns {dict} updated scale
// @example A default scale
// .z.m.gg.scale.linear
// @example A scale with 3% extension
// .z.m.gg.scale.extension[0.03] .z.m.gg.scale.linear
// @example A scale with 30% extension
// .z.m.gg.scale.extension[0.3] .z.m.gg.scale.linear
.z.m.gg.scale.extension:{[p; s] scale.base.with.extension[p] s }

// @subcategory Scale Settings
// @fileOverview 
// Add a format function to a scale.
//
// A format function is a function from data values to tick label string.
//
// Note - newlines can appear in the format output by inserting `"\n"` in the string.
// @see gg.scale.breaks
// @param f {fn} (scale, value) -> symbol
// @param s {dict} scale 
// @returns {dict} updated scale
// @example A scale with default tick formats
// .z.m.gg.scale.linear
// @example A scale with custom breaks and ticks
//  .z.m.gg.scale.format[{
//     $[10 ~ x;   "ten";
//      100 ~ x;   "one hundred";
//      1000 ~ x;  "one thousand";
//                 ""]
//     }] .z.m.gg.scale.breaks[10 100 1000] .z.m.gg.scale.linear
.z.m.gg.scale.format:{[f; s]
    if [100h ~ type f;
        s: scale.base.with.formatF[f] s];
    if [99h ~ type f;
        s: scale.base.with.maxChars[f`chars] scale.base.with.formatF[f`formatF] s];
    : s;
    }

// @subcategory Scales
// @localize dnl-file
// @fileOverview 
// Return a scale for a column based on a tables meta type
// @param collapse {boolean} whether compound values should be collapsed (e.g., for a polygon chart)
// @param typec {char} meta type character
// @returns {dict} scale
// @example 
// .z.m.gg.scale.fromMeta "j"
.z.m.gg.scale.fromMeta:{[collapse;typec]
    : $[typec in "xhijef";  scale.linear; 
        typec in "bcCsg";   scale.categorical[];
        typec ~ "d";        scale.format[fmt.date] scale.date;
        typec ~ "p";        scale.format[fmt.timestamp] scale.timestamp;
        typec ~ "m";        scale.format[fmt.month] scale.month;
        typec ~ "z";        scale.format[fmt.datetime] scale.datetime;
        typec ~ "n";        scale.format[fmt.timespan] scale.timespan;
        typec ~ "t";        scale.time;
        typec ~ "v";        scale.second;
        typec ~ "u";        scale.minute;
        typec in "XHIJEF";  $[collapse; scale.linear; scale.categorical[]];  // Collapse complex columns
        scale.categorical[]] // Works on distinct values
    }

// @subcategory Scales
// @private
// @fileOverview 
// Extract the guide drawing function from a scale
// @param s {dict} scale
// @returns {fn}
.z.m.gg.scale.guide:{[s] (scale.base.guideF s) s }
.z.m.gg.scale.i.applyCat:{[sortF; s; x]
    : $[h.null sortF;
            [   dx : distinct x;
                $[scale.i.defaultSort[dx] ~ scale.ty.cat.i_distinct s;
                        h.findCat[scale.ty.cat.i_distinct s; x];
                    [
                        adistinct : scale.i.defaultSort distinct (scale.ty.cat.i_distinct s) , dx;
                        en : adistinct ? scale.ty.cat.i_distinct s;
                        en bin h.findCat[adistinct; x]]]];
            h.findCat[scale.ty.cat.i_distinct s; x]];
    }

// @fileOverview 
// A default scale that morphs into an appropriate scale based on the 
// type of the data provided during initialization
// @returns {dict} scale
.z.m.gg.scale.i.default:{[]
    : scale.new [`default; scale.i.data.DEFAULTS`default] (
        `default;
        {[v]1b};
        {[scale; vector]
            t : $[vector ~ (); "j"; h.metatype[([]x:vector); `x]];
            sc : scale.base.with.extend[scale.base.extend scale] scale.fromMeta[0b] t;
            if [not h.null scale.base.limits scale;
                sc : scale.base.with.limits[scale.base.limits scale] sc];
            if [not h.null scale.base.breaks scale;
                sc : scale.base.with.breaks[scale.base.breaks scale] sc];
            maxChars : scale.base.maxChars $[scale.i.data.MAXCHARS <> scale.base.maxChars scale; scale; sc];
            : scale.ty.default.with.i_type            [t]
                scale.ty.default.with.label           [scale.base.label sc]
                scale.ty.default.with.i_scale         [sc]
                scale.ty.default.with.applyType       [scale.base.applyType sc]
                scale.ty.default.with.inverseType     [scale.base.inverseType sc]
                scale.base.with.extension       [scale.base.extension scale]
                scale.base.with.maxChars        [maxChars]
                    scale.init[sc; vector];
            };
        {[s] scale.initBreaks scale.ty.default.i_scale s };
        ::;
        {[s;x] scale.apply[scale.ty.default.i_scale s; x] };
        ::;
        {[s;x] scale.inverse[scale.ty.default.i_scale s; x] };
        {[s] scale.guide scale.ty.default.i_scale s };
        {[s] scale.domain scale.ty.default.i_scale s }
        );
    }
.z.m.gg.scale.i.defaultSort:{ $[all 10h = type each .z.m.axq.asString x; .z.m.axstr.natsort x; x] }
// @fileOverview Return step and limit information for a gradient
// @param n {long} number of colours in the gradient
// @param ms {any|null} midpoints for inner steps
// @param s {dict} scale
// @returns {dict} gradient info
.z.m.gg.scale.i.gradInfo:{[n;ms;s]
    p: asc min[s`limits] + til[n] * %[;-1+n] (-) . desc s`limits;
    if [not ms ~ (::); p: first[p] , (type[p]$ms) , last p];
    : `pos`limits!(p;s`limits)
    }
// @fileOverview 
// Initialize categorical breaks
// @param s {dict} categorical scale
// @returns {any[]} breaks
.z.m.gg.scale.i.initCatBreaks:{[s]
    d: scale.ty.cat.i_distinct s;
    breaks: $[scale.base.i_hasBreaks s; d?scale.base.breaks s; til count d];
    : breaks @ where breaks within scale.base.limits s;
    }

// @fileOverview 
// Initialize the limits and original type flag on continuous scales (without extension)
// @param sc {dict} scale 
// @param vector {any[]} domain vector
// @returns {dict} limits and original type flag
.z.m.gg.scale.i.initContinuous:{[sc; vector]
    
    origType : $[vector ~ (); "j"; h.metatype[([]x:vector); `x]];
    
    init : $[origType in "bxhijef";   /dnl
                    scale.i.initNumeric[sc; 0; vector; 1b; ::; ::];
             origType in "pmdznuvt";  /dnl
                    scale.i.initTemporal[scale.i.data.TEMPORALMAP origType; sc; vector; $[scale.i.data.TEMPORALMAP origType]];
                    '.z.m.axlocalize.t[`.gg_unsupportedType], origType];
    
    : scale.base.with.i_orig[origType] init;
    };
// @fileOverview 
// Initialize the breaks of a continuous scale
// @param sc {dict} scale
// @returns {dict} limits and original type flag
.z.m.gg.scale.i.initContinuousBreaks:{[sc]
    : $[sc[`i_orig] in "bxhijef";  scale.i.initNumericBreaks sc; /dnl
        sc[`i_orig] in "pmdznuvt"; scale.i.initTemporalBreaks[scale.i.data.TEMPORALMAP sc`i_orig; sc]; /dnl
          '.z.m.axlocalize.t`.gg_unsupportedTypeBreaks];
    };
// @fileOverview
// Initialize a generic numeric scale limits and breaks
// @param sc {dict} the scale being initialized 
// @param default {number} default value
// @param vector {number[]} data for the scale to operate on 
// @param extend {boolean} whether the limits can be extended past the end of the data 
// @param filterF {fn} function from vector to vector removing invalid entries 
// @param applyF {fn} function to apply a transformation on values
// @returns {dict} limits for the scale
.z.m.gg.scale.i.initNumeric:{[sc; default; vector; extend; filterF; applyF]
    
    origType : h.metatype[([]x:vector); `x];
    vector   : h.removeInfs vector;
    if [not count[vector] ~ count ii : where not null vector;
        vector : vector ii];
    dom : filterF vector;
    
    empty : 0 = count dom;
    
    if [empty;
        dom : enlist default];
    
    m: h.promote applyF min dom;
    M: h.promote applyF max dom;
    
    trueLimits : (m;M);

    if [m = M;
        m -: 1;
        M +: 1];
    
    limits: $[not h.null scale.base.limits sc;
        asc (m;M)^applyF scale.base.limits sc;
        asc (m;M)];

    clean : scale.i.nice . limits;

    if [extend and h.null scale.base.limits sc;
        limits: clean`limits];
    
    : scale.base.with.empty[empty]
        scale.base.with.limits[limits]
        scale.base.with.true_limits[trueLimits]
        scale.base.with.i_orig[origType]
        sc;
    }

// @fileOverview 
// Initialize a numeric scales breaks
// @param sc {dict} scale
// Returns {num[]} breaks
.z.m.gg.scale.i.initNumericBreaks:{[sc]
    
    clean : scale.i.nice . scale.base.geom_limits sc;

    if [0 = count where clean[`breaks] within scale.base.geom_limits sc;
        clean[`breaks]: scale.base.limits sc];
    
    breaks : $[scale.base.i_hasBreaks sc;
        scale.apply[sc; scale.base.breaks sc];
        clean`breaks];
    
    : breaks @ where breaks within scale.base.geom_limits sc;
    }

// @fileOverview 
// Initialize a temporal scale given a type to convert the
// temporal values to.
// @param toType {char} numeric type character to convert domain to 
// @param sc {dict} temporal scale 
// @param vector {any[]} domain 
// @param applyF {fn} domain -> range 
// @returns {dict} limits and true limits for the scale
.z.m.gg.scale.i.initTemporal:{[toType; sc; vector; applyF]
    origType : h.metatype[([]x:vector); `x];
    vector   : h.removeInfs vector;
    if [not count[vector] ~ count ii : where not null vector;
        vector : vector ii];

    empty : 0 = count vector;
    
    if [0 = count vector; vector : enlist 0];

    m: toType$min vector;
    M: toType$max vector;
    trueLimits : (m;M);
    
    if [m = M;
        m -: 1;
        M +: 1];

    limits : $[not h.null scale.base.limits sc;
        (m;M)^applyF sc`limits;
        (m;M)];
    
     : scale.base.with.empty        [empty]
        scale.base.with.limits      [limits]
        scale.base.with.true_limits [trueLimits]
        scale.base.with.i_orig      [origType]
            sc;
    };
// @fileOverview 
// Initialize temporal breaks
// @param toType {char} type to convert the domain to 
// @param sc {dict} scale
// @returns {number[]} breaks in the range of the scale
.z.m.gg.scale.i.initTemporalBreaks:{[toType;sc]
    range  : h.safeRange scale.base.geom_limits sc;
    
    $[scale.base.i_hasBreaks sc;
        breaks : toType$scale.base.breaks sc;
        
        [   breaks : toType$(first scale.base.limits sc) + (range % 5) * til 5;
            if [(scale.base.i_orig sc) in "md"; /dnl
                breaks : toType$scale.i.niceDate sc]]];

    : breaks @ where breaks within scale.base.geom_limits sc;
    }
// @fileOverview 
// Inverse values on a continuous scale
// @param sc {dict} continuous scale 
// @param x {any[]} range
// @returns {any[]} domain
.z.m.gg.scale.i.inverseContinuous:{[sc;x]
    : $[sc[`i_orig] in "bxhijef";  x; /dnl
        sc[`i_orig] in "pmdznuvt"; sc[`i_orig]$x; /dnl
          '.z.m.axlocalize.t`.gg_unsupportedTypeInverse];
    }
// @fileOverview 
// Return "nice" breaks and limits for data between
// a given max and min
// @param m {number} min value 
// @param M {number} max value 
.z.m.gg.scale.i.nice:{[m; M]
    wilk : first i.wilkinson.scale[m;M;5];
    m: wilk`lmin;
    M: wilk`lmax;
    range : h.safeRange (m;M);
    intervals : floor range%wilk`lstep;
    
    if [h.null intervals;
        : `breaks`limits!(enlist m; (m;M))];
    
    breaks : m+wilk[`lstep] * til 1+intervals;
    : `breaks`limits!(breaks; (m;M))
    }

// @fileOverview 
// Return the "nicest" breaks for a date temporal (dates, months, etc)
// @param sc {dict} scale
// @returns {any[]} temporal scale breaks
.z.m.gg.scale.i.niceDate:{[sc]
      
    orig           : scale.base.i_orig sc;
    origRange      :  orig$scale.base.geom_limits sc;
    maxticks       : 12;
    prefferedTicks : 5;
    candidates     : ();
    
    yearTrys    : scale.i.tryDate[`year$origRange 0; `year$origRange 1; maxticks] each scale.i.data.TEMPORALINTERVALS`year;
    scores      : abs prefferedTicks - count each yearTrys;
    years       : last yearTrys where scores = min scores;
    
    candidates ,: enlist {value string[x],".01.01"} each years where years < 2291;
    
    monthTrys   : scale.i.tryDate["m"$origRange 0; "m"$origRange 1; maxticks] each scale.i.data.TEMPORALINTERVALS`month;
    scores      : abs prefferedTicks - count each monthTrys;
    candidates ,: enlist "m"$last monthTrys where scores = min scores;
    
    if [not sc[`i_orig] ~ "m";
        dayTrys     : scale.i.tryDate["d"$origRange 0; "d"$origRange 1; maxticks] each scale.i.data.TEMPORALINTERVALS`day;
        scores      : abs prefferedTicks - count each dayTrys;
        candidates ,: enlist "d"$last dayTrys where scores = min scores];
    
    scores : abs prefferedTicks - count each candidates;
    : distinct orig$first candidates where scores = min scores;
    
    }

// @fileOverview 
// Create a temporal scale 
// @param f {char} type to cast from 
// @param t {char} type to cast to (numeric)
// @returns {dict} scale for a temporal type (f)
.z.m.gg.scale.i.temporal:{[f; t]
    : scale.new [`base; scale.i.data.DEFAULTS`base] (
        `temporal;
        
        {[f;v]
            .[scale.i.validate; (v;enlist f); {[f;x]'.z.m.axlocalize.t[`.gg_scaleErrorPre],x} f];
            : 1b;
            } f;
        
        scale.i.initTemporal[t;;;t$];
        scale.i.initTemporalBreaks t;
        scale.i.data.types.numeric;
        
        {[f;t;s;x]
            c:t$f$x;
            ii    : h.infPos x;
            c[ii] : h.INFINITY h.METATYPES t;
            : @[c; ii where not 0 < x ii; neg]
            }[f;t];
        
        scale.i.data.types.temporal;
        {[f; s; x]f$x} f;
        {[s]'`noguide};
        {[s] scale.inverse[s] scale.base.true_limits s }
        );
    }

// @fileOverview 
// Return the ticks for the given tick count and interval 
// @param m {any} min data 
// @param M {any} max data 
// @param ticks {long} number of ticks 
// @param interval {number} tick interval
// @returns {number[]} ticks
.z.m.gg.scale.i.tryDate:{[m; M; ticks; interval]
    jm : "j"$m;
    jM : "j"$M;
    tm : h.roundup[jm; interval];
    ticks : tm + interval * til ticks;
    : distinct ticks where ticks within (jm;jM);
    }

// @fileOverview 
// Validate that the column applied to a scale will succeed
// @param v {any[]} data 
// @param types {char[]} list of valid types for the scale
// @returns {boolean} the application is valid
// 
// @throws "column type x not one of y"
.z.m.gg.scale.i.validate:{[v; types]

    kind : h.metatype[([]x:v); `x];
    
    if [not kind in types;
        '.z.m.axlocalize.t(`.gg_scaleValidationError; `found`expected!(string h.METATYPES kind; h.niceTypeStr types))];
    
        
    : 1b;
    
    }

// @subcategory Scales
// @fileOverview 
// Initialize a scale on provided data
// @param s {dict} scale 
// @param v {any[]} data
// @returns {dict} initialized scale
//
// @throws validation errors
// @example
// .z.m.gg.scale.init[.z.m.gg.scale.linear] til 1000
.z.m.gg.scale.init:{[s; v]
    
    orig: s;
    
    if [not scale.base.is s; '.z.m.axlocalize.t`.gg_invalidScaleError];
    
    if [scale.base.initialized s; : s];

    s: scale.base.with.i_hasLimits[not h.null scale.base.limits s]
       scale.base.with.i_hasBreaks[not h.null scale.base.breaks s] s;
    
    : scale.base.with.initialized[1b]
         scale.base.with.geom_limits[scale.base.limits s2]
            scale.base.with.i_origScale[orig]
            s2 : (scale.base.initF s)[s; v];

    }

// @subcategory Scales
// @private
// @fileOverview 
// Given a scale, initialize the breaks on the scale
// @param s {dict} scale
// @returns {dict} scale
// @see gg.scale.breaks
.z.m.gg.scale.initBreaks:{[s] scale.base.with.breaks[distinct (scale.base.breaksF s) s] s }

// @subcategory Scales
// @private
// @fileOverview 
// Apply a scale's inverse function to a vector of data
// @param s {dict} scale 
// @param v {any[]} data
// @returns {any[]} inversed data
.z.m.gg.scale.inverse:{[s; v]  : (scale.base.inverseF s)[s; v] }

// @subcategory Scale Settings
// @fileOverview 
// Specify the limits (maximum and minimum) for a scale. This will override
// the generated limits for the scale. If either limit given is null, the max
// or min will be used as usual.
// The limits should be in the domain of the scale (float for a float scale, long for a long scale, etc).
// @param lims {any[]} the max and min data to use for the scale 
// @param s {dict} an uninitialized scale 
// @example A scale with default limits
// .z.m.gg.scale.linear
// @example Start a scale at 0 and used generated max value
// .z.m.gg.scale.limits[0 0N] .z.m.gg.scale.linear
// @example Restrict (or extend) a scale to be between 0 and 100
// .z.m.gg.scale.limits[0 100] .z.m.gg.scale.linear
.z.m.gg.scale.limits:{[lims;s]
    if [all null lims; '"Limits cannot both be null"];
    : scale.base.with.limits[{ @[x;where y;:;.z.m.axq.NULL .z.m.axq.typeOf first x where not y] }[lims] null lims] s
    }

// @subcategory Scales
// @fileOverview 
// Create a scale for the strokewidth of a line.
// @param m {long} min line size
// @param M {long} max line size
// @returns {dict} line size scale
// @example 
// .z.m.gg.scale.line.size[1;10]
.z.m.gg.scale.line.size:{[m;M]
    
    if [m >= M;  '.z.m.axlocalize.t(`.gg_scaleErrorInverted;"line size")];  /dnl
    if [m < 0;   '.z.m.axlocalize.t(`.gg_scaleErrorMinRange2;"line size")]; /dnl
    if [M < 0;   '.z.m.axlocalize.t(`.gg_scaleErrorMaxRange2;"line size")]; /dnl
    
    : scale.new [`base; scale.i.data.DEFAULTS`base] (
        `line.size;
        {[v]
            .[scale.i.validate; (v;"bxhijefpmdznuvt"); {'.z.m.axlocalize.t[(`.gg_scaleErrorPre;"line size")],x}]; /dnl
            : 1b;
            };
        scale.i.initContinuous;
        {[sc]
            if [not h.null scale.base.breaks sc; '.z.m.axlocalize.t(`.gg_scaleErrorExplicitBreaks;"line size")]; /dnl
            : scale.i.initContinuousBreaks sc
            };
        scale.i.data.types.numeric;
        {[m;M;s;x] proj.proj[scale.base.limits s; (m;M); $[(scale.base.i_orig s) in "bxhijef"; x; scale.i.data.TEMPORALMAP[scale.base.i_orig s]$x]] }[m;M]; /dnl
        scale.i.data.types.numeric;
        scale.i.inverseContinuous;
        {[m;M;s]
            xs : proj.proj[scale.base.limits s; 0 1] scale.base.breaks s;
            rs : proj.proj[scale.base.limits s; (m;M)] scale.base.breaks s;
            : etable.el[scale.i.data.g.DEF_LINE] {[x;r]
                : `x1`y1`x2`y2`colour`size!(x; 1 - 0.15; x;1; 0xff,colour.Black; r);
                }'[xs; rs];
            }[m;M];
        {[s] scale.inverse[s] scale.base.true_limits s }
    );
    }

// @subcategory Scale Settings
// @fileOverview 
// Set the max characters that appear in a scale's tick labels
// @param n {long} the max number of characters to use
// @param s {dict} scale
// @returns {dict} updated scale
// @example Set the scale ticks to truncate after 20 characters
// .z.m.gg.scale.maxChars[20] .z.m.gg.scale.categorical[]
// @throws "Maximum characters on a scale must be specified in integers"
.z.m.gg.scale.maxChars:{[n; s]
    if [not type[n] in -5 -6 -7h; '.z.m.axlocalize.t`.gg_maxCharsTypeError];
    : scale.base.with.maxChars["j"$n] s;
    }
// @subcategory Scales
// @fileOverview 
// Create a Mercator scale. Useful for geo data.
// @param isLat {boolean} Whether the applied data is latitude
// @returns {dict} a Mercator scale
// @example Longitude scale
// .z.m.gg.scale.mercator[0b]
// @example Latitude scale
// .z.m.gg.scale.mercator[1b]
.z.m.gg.scale.mercator:{[isLat]
    : scale.new [`base; scale.i.data.DEFAULTS`base] (
        `mercator;
        {[v]
            .[scale.i.validate; (v;"bxhijef"); {'.z.m.axlocalize.t[(`.gg_scaleErrorPre;"mercator")],x}]; /dnl
            : 1b;
            };
        {[scale; vector] scale.i.initNumeric [scale; 0; vector; 0b; {x}; scale.apply scale] };
        scale.i.initNumericBreaks;
        scale.i.data.types.numeric;
        {[isLat;s;x] h.mercator[isLat; x] } isLat;
        scale.i.data.types.numeric;
        {[isLat;s;x] h.invMercator[isLat; x] } isLat;
        {[s]'`noguide};
        {[s] scale.inverse[s] scale.ty.default.true_limits s }
        );
    }


.z.m.gg.scale.new:{[ty; extension; args]
    
    newF : $[`base ~ ty;     .z.m.gg.scale.base.new;
             `cat ~ ty;      .z.m.gg.scale.ty.cat.new;
             `default ~ ty;  .z.m.gg.scale.ty.default.new;
             `compose ~ ty;  .z.m.gg.scale.ty.compose.new;
                             .z.m.gg.scale.base.new];
    
    : newF 0b , 0b , args , (
        h.printNum[h.print;scale.i.data.PRINTPRECISION];
        ::;
        ::; ::; ::;
        scale.i.data.MAXCHARS;
        0;
        1b;
        0b;
        ::; ::; ::; ::) , extension;
      
    }

// @subcategory Scales
// @fileOverview 
// Create a power scale. Each value will be raised to the given power.
// @param e {number} exponent for the power
// @returns {dict} power scale
// @example A power(2) scale
// .z.m.gg.scale.power[2]
// @example A square root scale
// .z.m.gg.scale.power[0.5]
.z.m.gg.scale.power:{[e]
    : scale.new [`base; scale.i.data.DEFAULTS`base] (
        `power;
        {[v]
            .[scale.i.validate; (v;"bxhijef"); {'.z.m.axlocalize.t[(`.gg_scaleErrorPre;"power")],x}]; /dnl
            : 1b;
            };
        $[e = 0;
            scale.log`initF;
            {[scale; vector] scale.i.initNumeric[scale; 0; vector; scale`extend; {x}; scale.apply scale] }];
        scale.i.initNumericBreaks;
        scale.i.data.types.numeric;
        $[e = 0; scale.log`applyF; {[e;s;x] {[e;x]$[x<0;neg;::] (abs x) xexp e}[e] each x} e];
        scale.i.data.types.numeric;
        $[e = 0; scale.log`inverseF; {[e;s;x] {[e;x]$[x<0;neg;::] (abs x) xexp 1%e}[e] each x} e];
        {[s]'`noguide};
        {[s] scale.inverse[s] s`true_limits }
    );
    }


.z.m.gg.scale.reassemble:{[scales]
    
    scales : scales where not h.null each scales;
    
    nonempty : where not scale.base.empty each scales;
    
    sc : first scales;
    
    if [not 0 = count nonempty;
        scales : scales where not scale.base.empty each scales];
    
    if [0 = count scales; :()];
    
    doms : h.consolidateTypes scale.domain each scales;
    
    scale.validate[sc] each doms;
    
    extend : not any not scale.base.extend each scales;
    
    n: scale.init [.z.m.gg.scale.extend[extend] scale.reset sc] raze doms;

    : n;
    
    }

// @subcategory Scales
// @private
// @fileOverview 
// Reset a scale to its pre-initialization state
// @param s {dict} scale
// @returns {dict} reset scale
.z.m.gg.scale.reset:{[s]

    if[h.null s; : s];
    if[not 99h ~ type s; : s];
    if[not scale.base.initialized s; : s];
    
    n: scale.base.i_origScale s;
    n: scale.base.with.geom_limits[::] scale.base.with.true_limits[::] n;
    
    if [scale.ty.cat.is n;
        n: scale.ty.cat.with.i_odistinct[scale.ty.cat.i_odistinct s] n];
    
    : n;
    
    }
// @private
// @fileOverview 
// Hard reset the x and y scales of each layer in the list of layers
// @param ls {dict[]} list of layers
// @returns {dict[]} updated list of layers
.z.m.gg.scale.resetScales:{[ls]
    : scale.setDefaultScales {[x]
        s: scale.reset each x`scales;
        x[`scales]: s;
        if [`x in key x`scales;
            x[`scales;`x]: scale.extend[0b] x[`scales] `x];
        if [`y in key x`scales;
            x[`scales;`y]: scale.extend[0b] x[`scales] `y];
        :  x;
        } each ls;
    }
// @private
// @fileOverview If any scale fails to validate, reset it to use 
// a default scale
// @param lyrs {dict[]} 
// @returns {dict} Updated scales
.z.m.gg.scale.setDefaultScales:{[lyrs]
    : {[lyr]
        used: where (first each lyr[`coord][`dims]#lyr`aes) in .z.m.gg.tbl.colnames lyr `data;

        updated: used!{[lyr; x]
            col: .z.m.gg.tbl.column[lyr`data; lyr[`aes] x];

            .[{ .z.m.gg.scale.validate[x] y; x }; (lyr[`scales]x; col); .z.m.gg.scale.default]
            }[lyr] each used;

        : @[lyr;`scales;:;lyr[`scales] , updated]
        } each lyrs;
    }
// @subcategory Scales
// @fileOverview 
// Given an X or Y scale, ensure that the other (X or Y)
// scale has the same range (useful for maps).
//
// Note - Only one of the scales needs to be marked square for this effect.
// @param sc {dict}
// @returns {dict}
// @example Square longitude scale
// .z.m.gg.scale.square .z.m.gg.scale.mercator[0b]
.z.m.gg.scale.square:{[sc] scale.base.with.square[1b] sc }

// @subcategory Scales
// @private
// @fileOverview 
// Convert a vector of temporal data (with a date component) into weekday symbols
// @param vector {date[]} vector of temporal data
// @returns {symbol[]} list of weekdays
// @example
// .z.m.gg.scale.toWeekday 10?.z.d
.z.m.gg.scale.toWeekday:{[vector]
    today : `Thursday;
    ref   : 2015.08.27;
    : ((days?today)rotate days) (neg ref - "d"$vector) mod count days: `Sunday`Monday`Tuesday`Wednesday`Thursday`Friday`Saturday;
    }

// @subcategory Scales
// @private
// @fileOverview 
// Validate a scale based on a domain
// @param s {dict} scale to validate against the domain
// @param dom {any[]} data to validate against
// @returns {boolean}
//
// @throws *
.z.m.gg.scale.validate:{[s; dom] (scale.base.validateF s) dom }

.z.m.gg.scale.weekday:scale.new [`base; scale.i.data.DEFAULTS`base] (
        `weekday;
        {[v]
            .[scale.i.validate; (v;"dpz"); {'.z.m.axlocalize.t[(`.gg_scaleErrorPre;"weekday")],x}]; /dnl
            : 1b;
            };
        {[s; v]
            m: "f"$ $[not h.null scale.base.limits s; scale.i.data.DAYS?first scale.base.limits s; 0];
            M: "f"$ $[not h.null scale.base.limits s; scale.i.data.DAYS?last scale.base.limits s; count[scale.i.data.DAYS] - 1];
            trueLimits : (m;M);
            if [m = M;
                m -: 1;
                M +: 1];
            limits : (m;M);
            : scale.base.with.limits[limits]
                scale.base.with.true_limits[trueLimits] s;
            };
        {[s]
            breaks : $[not h.null scale.base.breaks scale; scale.i.data.DAYS?scale.base.breaks; til count scale.i.data.DAYS];
            : breaks @ where breaks within scale.base.limits scale;
            };
        scale.i.data.types.numeric;
        {[s;x] scale.i.data.DAYS?scale.toWeekday x };
        scale.i.data.types.categorical;
        {[s;x] scale.i.data.DAYS "j"$x };
        {[s]'`noguide};
        {[s] scale.i.data.DAYS {x+til y-x} . (::;1+)@'scale.base.true_limits s }
        );
.z.m.gg.scale.timestamp:scale.i.temporal["p"; scale.i.data.TEMPORALMAP"p"] 
.z.m.gg.scale.timespan:scale.i.temporal["n"; scale.i.data.TEMPORALMAP"n"] 
.z.m.gg.scale.time:scale.i.temporal["t"; scale.i.data.TEMPORALMAP"t"]
.z.m.gg.scale.second:scale.i.temporal["v"; scale.i.data.TEMPORALMAP"v"]
.z.m.gg.scale.month:scale.i.temporal["m"; scale.i.data.TEMPORALMAP"m"]
.z.m.gg.scale.minute:scale.i.temporal["u"; scale.i.data.TEMPORALMAP"u"] 
.z.m.gg.scale.log:scale.new [`base; scale.i.data.DEFAULTS`base] (
    `log;
    {[v]
        .[scale.i.validate; (v;"xhijef"); {'.z.m.axlocalize.t[(`.gg_scaleErrorPre;"log")],x}]; /dnl
        : 1b;
        };
    {[scale; vector] scale.i.initNumeric [scale; 1; vector; scale.ty.default.extend scale; {x where 0 < x}; scale.apply scale] };
    scale.i.initNumericBreaks;
    scale.i.data.types.numeric;
    {[s;x]10 xlog x};
    scale.i.data.types.numeric;
    {[s;x]10 xexp x};
    {[s]'`noguide};
    {[s] scale.inverse[s] scale.ty.default.true_limits s }
    )
.z.m.gg.scale.linear:scale.new [`base; scale.i.data.DEFAULTS`base] (
    `linear;
    {[v]
        .[scale.i.validate; (v;"bxhijef"); {'.z.m.axlocalize.t[(`.gg_scaleErrorPre;"linear")],x}]; /dnl
        : 1b;
        }; 
    {[sc; v] scale.i.initNumeric [sc; 0; v; sc`extend; {x}; scale.apply sc] };
    {[scale] scale.i.initNumericBreaks scale };
    scale.i.data.types.numeric;
    {[s;v]v};
    scale.i.data.types.numeric;
    {[s;v]v};
    {[s]'`noguide};
    {[s] s`true_limits }
    )
.z.m.gg.scale.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.gg_scaleValidationError; "column type ({found}) not supported. Must be one of {expected}");
        (`.gg_scaleErrorPre; "{type} scale error: ");
        (`.gg_scaleErrorInverted; "{type} scale error: min {type} must be less than max {type}");
        (`.gg_scaleErrorMinRange; "{type} scale error: min {type} must be between 0 and 255");
        (`.gg_scaleErrorMaxRange;"{type} scale error: max {type} must be between 0 and 255");
        (`.gg_scaleErrorExplicitBreaks; "{type} scale error: cannot set explicit breaks");
        (`.gg_scaleErrorMinRange2; "{type} scale error: min {type} must be greater than 0");
        (`.gg_scaleErrorMaxRange2; "{type} scale error: max {type} must be greater than 0");
        (`.gg_colourErrorBadList; "cat colour scale error: colours must be either list of colours (0xRRGGBB) or dictionary of data to colours");
        (`.gg_colourErrorBadDict; "cat colour scale error: colour mapping value must be valid colours (0xRRGGBB)");
        (`.gg_colourErrorDomain; "cat colour scale error: domain of colour mapping does not match type of data");
        (`.gg_colourGradErrorType1; "{type} scale error: fill arguments must be a 3-element byte array (0xRRGGBB)");
        (`.gg_colourGradErrorType2; "{type} scale error: fill arguments must be a 3-element byte array (0xRRGGBB)");
        (`.gg_colourGrad2ErrorDomain; "colour gradient2 scale error: midpoint must be of same type as domain");
        (`.gg_unsupportedType; "initialized on unsupported type ");
        (`.gg_unsupportedTypeBreaks; "breaks on unsupported type");
        (`.gg_unsupportedTypeInverse; "inverse on unsupported type");
        (`.gg_invalidScaleError; "Scale argument must be a valid scale");
        (`.gg_maxCharsTypeError; "Maximum characters on a scale must be specified in integers")
    ))
.z.m.gg.scale.datetime:scale.i.temporal["z"; scale.i.data.TEMPORALMAP"z"]
.z.m.gg.scale.date:scale.i.temporal["d"; scale.i.data.TEMPORALMAP"d"]
.z.m.gg.scale.colour.cat20:scale.colour.cat colour.cat20  
.z.m.gg.scale.colour.cat10:scale.colour.cat colour.cat10   
// @subcategory Scales
// @private
.z.m.gg.scale.onLoad:{[]
    scale.default : scale.i.default[]; 
    scale.colour.default : scale.colour.i.default;
    }

.z.m.gg.scale.onLoad[];
system "d .z.m";

system "d .z.m.gg";
// @fileOverview 
// Add all components from a frame dictionary to a specification tree
// as children of the given node
// @param frame {dict} dictionary of specification nodes 
// @param node {dict} node of the specification tree 
// @param sp {table} specification tree
//
// @returns {table} updated specification tree
//
// @throws "can only add a frame to stack and layer nodes"
.z.m.gg.spec.add.frame:{[frame; node; sp]

    entry: spec.ty.component.entry .z.m.axds.tree.node.item node;
    kind : $[spec.ty.stack.is entry;  spec.ty.stack;
             spec.ty.layer.is entry;  spec.ty.layer;
             spec.ty.split.is entry;  spec.ty.split;
                                      '.z.m.axlocalize.t`.gg_specFrameError];
    
    if [not h.null frame`legends;
        frame[`legends]: raze frame`legends];

    atoms : key[frame] where not {.z.m.axq.isTable[x] or .z.m.axq.isList x} each value frame;
    frame[atoms] : enlist each frame atoms;
    
    : .z.m.axds.tree.modify[
        node; 
        spec.ty.component.with.entry[kind[`with][`frame][frame; entry]] .z.m.axds.tree.node.item node;
        sp];
    }

// @fileOverview 
// Returns the first ancestor of the given type, or null if there is none
// If the given node is of the given type, returns that node
// @param kind {dict} specification component (eg spec.ty.layer) 
// @param sp {table} 
// @param node {dict} 
// @returns {dict | null} first ancestor of the given type or null
.z.m.gg.spec.ancestor:{[kind;sp;node]
    : spec.ancestorWhere[kind[`is];sp;node];
    }

// @fileOverview 
// Returns the first ancestor who's entry passes the predicate
// @param sp {table} 
// @param node {dict} 
// @returns {dict | null} first ancestor which passes or null
.z.m.gg.spec.ancestorWhere:{[pred;sp;node]
    f: {[pred;node]
        if[h.null node`id; : 0b];
        : not pred spec.ty.component.entry .z.m.axds.tree.node.item node;
        } pred;
    
    rNode: f { .z.m.axds.tree.find[;x] first y`parents }[sp]/ .z.m.axds.tree.find[;sp] first .z.m.axds.tree.find[node;sp]`parents; // while

    : $[h.null rNode`id; ::; rNode];
    }

// @fileOverview Return all layers 'associated' with a set of layers.
// An associated layer is one which is participating in the same 
// (possibly nested) stack - a single frame.
// @param sp {table} gg spec 
// @param nodes {table} subset of the spec 
// @returns {table} associated layer nodes
.z.m.gg.spec.associatedLayers:{[sp; nodes]
    : distinct spec.every[spec.ty.layer] raze .z.m.axds.tree.descendants[;sp] each
        spec.associatedStacks[sp; nodes];
    }

// @fileOverview Return all stacks 'associated' with a set of layers.
// An associated layer is one which is participating in the same 
// (possibly nested) stack - a single frame.
// @param sp {table} gg spec 
// @param nodes {table} subset of the spec 
// @returns {table} associated stack nodes
.z.m.gg.spec.associatedStacks:{[sp; nodes]
    : raze spec.every[spec.ty.stack] each .z.m.axds.tree.ancestors[;sp] each nodes;
    }

// @fileOverview 
// Return all the axis nodes of the specification tree that contain the given point
// @param pt {(number;number)} 
// @param spec {table} initialized (sized) specification tree
//
// @returns {dict[]} list of layer nodes
.z.m.gg.spec.axesFromPt:{[pt; spec]
    axesHit : {[pt; node]
        x : y : 0b;
        xframe : first @[;`xaxis] frame : spec.pluck[`frame] node;
        yframe : first @[;`yaxis] frame;
        if [not h.null xframe;
            x : proj.pointWithin[pt] spec.toBounds xframe];
        if [not h.null yframe;
            y : proj.pointWithin[pt] spec.toBounds yframe];
        : $[x; `xaxis; y; `yaxis; `];
        }[pt] each layerNodes : spec.every [spec.ty.layer; spec];
    
    w : where not null axesHit;
    : ([] axis : axesHit w; node : layerNodes w );
    
    }

// @fileOverview 
// Return all children of the node in the tree
// @param node {dict} specification node 
// @param spec {table} specification tree
//
// @returns {dict[]} list of specification nodes
.z.m.gg.spec.children:{[node; spec]
    : .z.m.axds.tree.find[;spec] each .z.m.axds.tree.node.children node;
    }


.z.m.gg.spec.collect:{[kinds; node; spec]
    parent : .z.m.axds.tree.parent[node; spec];
    entry  : spec.ty.component.entry .z.m.axds.tree.node.item node;
        
    d: $[any h.atAll[`is; kinds] @\: entry; entry`get; ()!()];
    
    : $[h.null parent;
        d , enlist[`]!enlist(::);
        spec.collect[kinds;parent;spec] , d , enlist[`]!enlist(::)];
    }

// @fileOverview 
// Create a new instance of a specification component
// @param origin {(number;number)} 
// @param w {number} 
// @param h {number} 
// @param entry {dict} 
.z.m.gg.spec.component:{[origin; w; h; entry]
    .z.m.axds.tree.node.new spec.ty.component.new (
        $[h.null origin; origin; "f"$origin];
        $[h.null w; w; "f"$w];
        $[h.null h; h; "f"$h];
        entry)
    }

.z.m.gg.spec.every:{[kind; spec]
    : spec where kind[`is] each spec.ty.component.entry each .z.m.axds.tree.node.item each spec;
    }

.z.m.gg.spec.facetGrid:{[weights; speclist]
    : spec.i.addlayout[`facetGrid; weights; speclist];
    }

// @fileOverview
// Finds the node representing the canvas
// This node is either the first canvas node ancestor with splitframe=1b, or the root node
// @param sp {table} gg spec
// @param node {dict}
// @returns {dict} renderer node
.z.m.gg.spec.findAncestorCanvasNode:{[sp; node]
    node: .z.m.axds.tree.find[node;sp];
    
    f: {[root;node]
        : not spec.ty.canvas.is[spec.ty.component.entry .z.m.axds.tree.node.item node]
            or root[`id] ~ node`id;
        } root: .z.m.axds.tree.root sp;
    
    rNode: f { .z.m.axds.tree.find[;x] first y`parents }[sp]/ node; // while
    
    if[h.and[rNode;
            {spec.ty.canvas.is spec.ty.component.entry .z.m.axds.tree.node.item x};
            {not spec.ty.canvas.splitframe spec.ty.component.entry .z.m.axds.tree.node.item x}];
        rNode: root];

    : rNode;
    }


.z.m.gg.spec.frame.all:{[sizes; g; components; th; co; node]

    if [h.null g;
        g : spec.frame.canvas  [sizes; components; th; co; node]];
    
    frame   : spec.frame.frame   [sizes; components; th; co; node];
    bg      : spec.frame.canvas  [sizes; components; th; co; node];
    legends : spec.frame.legends [components; th; co; node; g];
    xaxis   : spec.frame.xaxis   [components; th; co; node; g];
    yaxis   : $[not h.null components`yaxis; 
        spec.frame.yaxis[sizes`y; components; th; co; node; g];
        ::];
    yaxis2  : $[`yaxis2 in key components;
        spec.frame.yaxis2[components; th; co; node; g];
        ::];
    
    spec.i.checkSize[node; g];
    spec.i.checkSize[node; xaxis];
    if [not h.null yaxis;   spec.i.checkSize[node; yaxis]];
    if [not h.null legends; spec.i.checkSize[node] each legends[;1]];
    
    : `xaxis`yaxis`yaxis2`geom`legends`background`frame!(xaxis;yaxis;yaxis2;g;legends;bg;frame);
    }

// @fileOverview 
// Frame a canvas/geom
// @param sizes {dict}
// @param components {dict} dictionary of components 
// @param th {dict} 
// @param co {dict} coordinate system 
// @param node {dict} specification node acting as parent
//
// @returns {dict} frame component for geom/canvas
.z.m.gg.spec.frame.canvas:{[sizes; components; th; co; node]

    component   : .z.m.axds.tree.node.item node;
    yAxisWidth  : 1|spec.frame.i.axisSize [$[h.null components`yaxis; 0; sizes`y]; th; co; `y];
    xAxisWidth  : 1|spec.frame.i.axisSize [sizes`x; th; co; `x];
    legendW     : 1|spec.frame.i.legendSize [th; components];
    yaxis2Width : $[`yaxis2 in key components; th[`axis_size_y]^sizes`y2; 0];
    origin      : spec.ty.component.origin component;
    
    wth    : 1|-[;yaxis2Width] -[;legendW] (spec.ty.component.w component) - yAxisWidth +  sum th`plot_margin_left`plot_margin_right`padding_left`padding_right`axis_offset;
    hgt    : 1|(spec.ty.component.h component) - xAxisWidth + sum th`plot_margin_top`plot_margin_bottom`padding_top`padding_bottom`axis_offset;
    left   : th[`axis_offset] + th[`padding_left] + th[`plot_margin_left] + origin[0] + yAxisWidth;
    top    : th[`padding_top] + th[`plot_margin_top] + origin 1;
    
    if [`square ~ th`aspect_ratio;
        v     : min (wth;hgt);
        left +: (wth-v)%2;
        top  +: (hgt-v)%2;
        wth : hgt : v];
    
    if [`mercator ~ th`aspect_ratio;
        nh : wth % 1.65;
        nw : hgt * 1.65;
        $[nh < h;
            [top  +: (hgt - nh) % 2;   hgt: nh];
            [left +: (wth - nw) % 2;   wth: nw]]];
    
    : spec.component [0|(left; top); wth; hgt; ::];
    
    }

// @fileOverview 
// Frame a canvas/geom
// @param sizes {dict}
// @param components {dict} dictionary of components 
// @param th {dict} 
// @param co {dict} coordinate system 
// @param node {dict} specification node acting as parent
//
// @returns {dict} frame component for geom/canvas
.z.m.gg.spec.frame.frame:{[sizes; components; th; co; node]
    component : .z.m.axds.tree.node.item node;
    origin    : spec.ty.component.origin component;
    
    wth    : 1|(spec.ty.component.w component) - sum th`plot_margin_left`plot_margin_right;
    hgt    : 1|(spec.ty.component.h component) - sum th`plot_margin_top`plot_margin_bottom;
    left   : th[`plot_margin_left] + origin 0;
    top    : th[`plot_margin_top]  + origin 1;
    
    : spec.component [0|(left; top); wth; hgt; ::];
    
    }

// @fileOverview 
// Determine the size of an axis. Size refers to height for
// y axes and width for x axes
// @param forceSize {boolean}
// @param th {dict} 
// @param co {dict} coordinate system 
// @param axis {symbol} `x or `y 
//
// @returns {number} the size of the axis
.z.m.gg.spec.frame.i.axisSize:{[forceSize; th; co; axis]
    useAxis: spec.frame.useAxis[th; co; axis];
    : $[useAxis and not null forceSize;
            forceSize;
        
        useAxis;
            th`$"axis_size_",h.asString axis; /dnl
        
            0];
    }

// @fileOverview 
// Find the height of each legend
// @param canvasComponent {dict} canvas component (size information for canvas) 
// @param th {dict} 
// @param components {(dict;dict;dict)[]} list of (title;legend;scale) tuples
// @return {long[]} list of heights for the scale
.z.m.gg.spec.frame.i.legendHeights:{[canvasComponent; th; components]
    legends    : components`legends;
    scales     : last each legends;
    ii         : where not h.null each legends;
    minHeight  : min (th`legend_height; canvasComponent[`h] % count ii);
    hs         : count[ii]#minHeight;
    extraSpace : canvasComponent[`h] - sum hs;
    catii : where .z.m.gg.scale.colour.cat[][`label] = h.atAll[`label] scales ii;
    catn  : count each h.atAll[`i_distinct] scales[ii] catii;
    caths : {[m;l;n] hgt:max m,min(m+l 0;10*n); : (l[0]-hgt-m;l[1],hgt) }[minHeight] over enlist[(extraSpace;())],catn;
    hs[catii] : caths 1;
    : hs;
    }

// @fileOverview 
// Determine the size of the legend container
// @param th {dict} 
// @param components {dict} dictionary of etables for each component
//
// @returns {number} size of the legend container
.z.m.gg.spec.frame.i.legendSize:{[th; components]
    : $[not spec.frame.useLegend[th; components]; 0; th`legend_width];
    }

// @fileOverview 
// Frame a set of legends beside a given canvas node
// @param components {dict} dictionary of etables for all components 
// @param th {dict} 
// @param co {dict} coordinate system 
// @param node {dict} specification node acting as parent 
// @param canvasNode {dict} specification node representing the canvas position
// @returns {dict[]} list of title-legend node pairs
.z.m.gg.spec.frame.legends:{[components; th; co; node; canvasNode]
    
    item : spec.node.item canvasNode;
    if [not spec.frame.useLegend[th; components];
        : (::)];
    

    legendH : spec.frame.i.legendHeights[item; th; components];
    legendW : spec.frame.i.legendSize[th; components];

    : {[th; components; item; legendW; legendH; ii]
            origin : (th[`legend_padding_left] + item[`origin;0] + item[`w] + $[`yaxis2 in key components; th`axis_size_y; 0];
                      th[`legend_padding_top] + (sum legendH til ii) + item[`origin;1]);

            lines    : exec count "\n" vs string first raze settings@\:\:`text from components[`legends][ii]0 where geometry like "*text*";
            titleH   : lines * th`legend_title_size;
            wth      : legendW - th`legend_padding_right;
            hgt      : legendH[ii] - th[`legend_padding_top] + th`legend_padding_bottom;
            hgt      : hgt - th`legend_offset;
            title    : spec.component [origin; wth; titleH; ::];
            legend   : spec.component [(origin 0; origin[1] + titleH + th`legend_offset); wth; max 0 , hgt - titleH; ::];
            : (title; legend);

            }[th; components; item; legendW; legendH] each til count (components`legends) where not h.null each components`legends;

    }

// @fileOverview 
// Determine whether an x or y axis should be used
// @param th {dict} 
// @param co {dict} 
// @param axis {symbol} `x or `y 
//
// @returns {boolean}
.z.m.gg.spec.frame.useAxis:{[th; co; axis]
    : (axis in co`dims) and th`$"axis_use_",h.asString axis; /dnl
    }

// @fileOverview 
// Determine whether or not a legend should be included
// @param th {dict} 
// @param components {dict} dictionary of etables for all components 
//
// @returns {boolean}
.z.m.gg.spec.frame.useLegend:{[th; components]
    hasTheme: (1b ~ th`legend_use) | 11 = abs type th`legend_use;
    hasScale: not 0 = count components`legends;
    : hasTheme & hasScale
    }


.z.m.gg.spec.frame.xaxis:{[components; th; co; node; canvasNode]
    : co[`xaxisFrameF][components; th; co; node; canvasNode];
    }


.z.m.gg.spec.frame.yaxis:{[forceSize; components; th; co; node; canvasNode]
    : co[`yaxisFrameF][forceSize; components; th; co; node; canvasNode];
    }


.z.m.gg.spec.frame.yaxis2:{[components; th; co; node; canvasNode]
    : co[`yaxis2FrameF][components; th; co; node; canvasNode];
    }

// @fileOverview 
// Arrange the specification trees in agrid layout of a given dimension.
// @param weights {number[]}
// @param speclist {table[]} list of specifications to arrange
//
// @returns {table} arranged specification
.z.m.gg.spec.grid:{[weights; speclist]
    : spec.i.addlayout[`grid; weights; speclist];
    }

// @fileOverview 
// Arrange the specification trees in an horizontal layout
// @param speclist {table[]} list of specifications to arrange
//
// @returns {table} arranged specification
.z.m.gg.spec.hori:{[speclist]
    : spec.i.addlayout[`hori; ::; speclist];
    }

// @fileOverview 
// Arrange the specification trees in a horizontal layout using pixels. 
// @param pixels {number[]}
// @param speclist {table[]} list of specifications to arrange
// @returns {table} arranged specification
.z.m.gg.spec.hori_p:{[pixels; speclist]
    : spec.i.addlayout[`hori_p; (count speclist)#pixels; speclist];
    }

// @fileOverview 
// Arrange the specification trees in an horizontal layout. The 
// visual widths will be weighted by the given weights.
// @param weights {number[]}
// @param speclist {table[]} list of specifications to arrange
//
// @returns {table} arranged specification
.z.m.gg.spec.hori_w:{[weights; speclist]
    : spec.i.addlayout[`hori; (count speclist)#weights; speclist];
    }

// @fileOverview 
// Add a layout specification node as the parent of a list of specification trees
// @param layout {symbol} the layout type being added 
// @param weights {number[]}
// @param speclist {table[]} list of specification trees
//
// @returns {table} updated specification tree
.z.m.gg.spec.i.addlayout:{[layout; weights; speclist]
    root : spec.component [::; ::; ::; spec.ty.layout.new (layout; weights)];
    : .z.m.axds.tree.connect[root; speclist];
    }

// @fileOverview 
// Given a parent and child container, ensure that the parent bounds its child
// @param pnode {dict} specification node 
// @param node {dict} child specification node 
// @returns {bool} true on success
// @throws "resize error: canvas is not large enough to hold frame components"
.z.m.gg.spec.i.checkSize:{[pnode; node]

    errorMsg : .z.m.axlocalize.t`.gg_specSizeError;
    
    if [h.null node; : 1b];
    pc : spec.toBounds pnode;
    cc : spec.toBounds node;
    
    if [not all cc[0] within\: pc 0;  'errorMsg]; // Check width bounds 
    if [not all cc[1] within\: pc 1;  'errorMsg]; // Check height bounds
    
    : 1b;
    
    }
 
// @fileOverview Fit a number of canvases in a square grid. If `fill` is true,
// the first chart takes up any empty room at the start of the grid.
// @param fill {boolean} 
// @param origin {(float;float)} 
// @param w {float} width 
// @param hh {float} height
// @param root {dict} root node of the spec tree
// @param sp {table} spec tree
// @returns {table} spec tree with origin, width, and height set for each canvas under `root`
.z.m.gg.spec.i.grid:{[fill; origin; w; hh; root; sp]
    dim:        spec.ty.layout.weights spec.ty.component.entry spec.node.item root;
    component:  @[.z.m.axds.tree.node.item root; `origin`w`h; :;  (origin; 1|w; 1|hh)];
    root:       .z.m.axds.tree.node.with.item[component; root];
    children:   spec.children[root;sp];
    n:          count children;
    nulldims:   all null dim;
    
    if [0 = n; : root];
    if [2 <> count dim; dim: 0N 0N];
    if [nulldims; dim: (ceiling sqrt n; 0N)];
    
    dim: "j"$(ceiling n % first dim where not null dim)^dim;
    
    if [nulldims & hh > w % 2; dim: reverse dim];
    if [any null dim; if [not n <= prd dim; '.z.m.axlocalize.t`.gg_gridDimensionError]];
    
    w2:         w % dim 0;
    h2:         hh % dim 1;
    matrix:     reverse[dim]#(raze dim[1]#enlist til dim 0) ,' raze (dim[0]#) each til dim 1;
    xs:         origin[0] + matrix[;;0] * w2;
    ys:         origin[1] + matrix[;;1] * h2;
    origins:    (raze xs) ,' raze ys;

    : root , $[fill;
        spec.with.i.sizeAndPos[origins 0; (count[origins]-n-1)*w2; h2; children 0; sp] , 
            raze (spec.with.i.sizeAndPos[;w2;h2;;sp].) each (enlist each neg[n-1]#origins) ,' enlist each 1_children;
        
        raze (spec.with.i.sizeAndPos[;w2;h2;;sp].)     each (enlist each n#origins)        ,' enlist each children]
    }

// @fileOverview
// Inserts canvas nodes into a spec
// @param sp {dict} specification tree
// @param root {dict} node currently acting as root
// @returns {table} updated specification tree
.z.m.gg.spec.i.insertCanvasNodes:{[sp; root]
    : $[
        spec.ty.layout.is spec.ty.component.entry .z.m.axds.tree.node.item root;
        {[root;sp;child]
            node: spec.component[::; ::; ::; spec.ty.canvas.new (1b; 0b; 0b)];
            : $[0 = count spec.every[spec.ty.layout] .z.m.axds.tree.subtree[child; sp];
                .z.m.axds.tree.insert[root; node; child; sp];
                spec.i.insertCanvasNodes[sp; child]];
            }[root]/[sp; reverse spec.children[root;sp]]; // .z.m.axds.tree.insert prepends children, so reverse children to preserve child order
        spec.i.insertCanvasNodes/[sp;spec.children[root;sp]]
        ]
    }
// @fileOverview Return the calculated sizes of each frame in a linear layout
// @param typ {symbol} type of layout size to use (pixels or weights)
// @param size {float} total size to fill
// @param root {dictionary} layout node
// @returns {float[]} size for each frame in the layout
.z.m.gg.spec.i.linearLayout:{[weights; typ; size; root]
    w: "f"$weights;                                  // weights
    f: $[`pixels~typ; sum w; 0];                     // fixed pixel sizes
    p: $[0~f; w%sum w; (1%count where null w)^w];    // percent sizes
    '["j"$(0~f)|null w] . (w;) p*size-f              // choose from percents or fixed
    }

// @fileOverview Utility to perform an update on a spec, transforming both
// layer *and* stack nodes 'associated' with a set of ids.
// @param sp {table} gg spec
// @param ids {guid[]} layers of interest
// @param stateF {fn (table[]) -> any} state capturing function
// @param layerF {fn (any;table) -> table} layer transform function (called on each layer)
// @param stackF {fn (any;dict) -> dict}  stack transform function (called on each stack node)
// @returns {table} new gg spec
.z.m.gg.spec.i.sharedNodes:{[sp; ids; stateF; layerF; stackF]
    nodes       : .z.m.axds.tree.find[; sp] each ids;
    layers      : spec.pluck[`defn] spec.every[spec.ty.layer] nodes;
    state       : stateF layers;
    stackLayers : spec.associatedLayers[sp; nodes];
    nodes       : nodes , stackLayers;
    layers      : layerF[state] each layers , spec.pluck[`defn] stackLayers;
    sp          : spec.updateLayers[sp; nodes; layers; ::];
    
    : {[state; stackF; sp; node]
        : spec.modify[node; stackF[state; node]; sp]
        }[state; stackF]/[sp; spec.associatedStacks[sp; nodes]]
    }

// @fileOverview 
// If the renderer node for the given node is a canvas node, returns it's dirty field
// Else, returns true
// @param sp {table} gg spec
// @param node {dict}
// @returns {bool}
.z.m.gg.spec.isDirty:{[sp; node]
    rNode: spec.findAncestorCanvasNode[sp;node];
    : not h.and[rNode; {spec.ty.canvas.is spec.ty.component.entry .z.m.axds.tree.node.item x}; {not spec.ty.canvas.dirty spec.ty.component.entry .z.m.axds.tree.node.item x}];
    }

// @fileOverview 
// Return all the layer nodes of the specification tree that contain the given point
// @param pt {(number;number)} 
// @param sp {table} initialized (sized) specification tree
//
// @returns {dict[]} list of layer nodes
.z.m.gg.spec.layersFromPt:{[pt; sp]
    : layerNodes where {[pt; node]
        : proj.pointWithin[pt] spec.toBounds first @[;`geom] spec.pluck[`frame] node;
        }[pt] each layerNodes : spec.every [spec.ty.layer; sp];
    }

// @fileOverview 
// Given a node, find its ancestor canvas node (if it exists), 
// and its descendant canvas nodes (if they exists), and dirty it
// @param sp {table} specification table
// @param node {dict} 
// @returns {table} updated spec
.z.m.gg.spec.makeDirty:{[sp;node]
    rNode: spec.findAncestorCanvasNode[sp;node];
    
    if[not rNode[`id] ~ .z.m.axds.tree.root sp;
        sp: .z.m.axds.tree.modify[rNode; ;sp] spec.update[`dirty; 1b; rNode]`item;
        ];
    
    canvasNodes: spec.every[spec.ty.canvas] .z.m.axds.tree.descendants[node;sp];
    : {[sp;node]
        : .z.m.axds.tree.modify[node;;sp] spec.update[`dirty; 1b; node]`item;
        }/[sp; canvasNodes];
    }

// @fileOverview 
// Change the item contained by the given node in a specification tree
// @param node {dict} node of the specification tree 
// @param item {dict} new item for the node
// @param spec {table} specification tree
//
// @returns {table} updated specification tree
.z.m.gg.spec.modify:{[node; item; spec]
    : .z.m.axds.tree.modify[node; item; spec];
    }

// @fileOverview 
// Extract the contained item from a specification node
// @param node {dict} specification node
//
// @returns {dict} the item contained by the node
.z.m.gg.spec.node.item:{[node]
    : .z.m.axds.tree.node.item node;
    }

// @fileOverview 
// Create a new copy of the node with
// an updated item
// @param item {dict} 
// @param node {dict} specification node
//
// @returns {dict} updated specification node
.z.m.gg.spec.node.with.item:{[item; node]
    : .z.m.axds.tree.node.with.item[item;node];
    }

// @fileOverview 
// Retrieve a field from a specific component from each tree node
// If the field is null, the component itself is returned
// If the speclist is a single node, a single value is given back
// @param field {symbol|null} the field to retrieve 
// @param speclist {table} specfication table (or subset)
// @returns {any[]} list of values associated with the field
.z.m.gg.spec.pluck:{[field; speclist]
    
    isDict : 99h ~ type speclist;
    
    if [isDict;
        speclist : enlist speclist];
    
    if [0 = count speclist;
        : ()];
    
    partial : $[all spec.ty.component.is each speclist;
        spec.ty.component.entry each speclist;
        spec.ty.component.entry each spec.node.item each speclist];
    
    result : $[h.null field; partial; h.atAll[field] partial];
    
    : $[isDict; first result; result]
    }

// @fileOverview 
// Collect all defaults and setting for a layer from all ancestors 
// (preferring depth) from the layer node
// @param layerNode {dict} layer node of the specification tree
// @param spec {table} specfication tree
//
// @returns {dict} fully qualified layer
.z.m.gg.spec.qualify:{[layerNode; spec]
    defaults : spec.collect[enlist spec.ty.defaults; layerNode; spec];
    defaults[`scales] : h.extend[defaults`scales] enlist[`]!enlist (::);
    : defaults , spec.pluck[`defn] layerNode;
    }

// @fileOverview 
// Remove the empty frame components from a specification
// @param spec {table} specification table (displayed) 
// @returns {table} updated specification table 
.z.m.gg.spec.removeFrames:{[spec]
    toRemove : select from spec where .z.m.gg.h.null each .z.m.gg.spec.ty.component.entry each .z.m.gg.spec.node.item each spec;
    : .z.m.axds.dag.fold[.z.m.axds.tree.remove.leaf; toRemove; spec];
    }

// @fileOverview 
// Find the renderer node for the given node, and returns it's origin
// This origin represents the global position of the renderers origin
// @param sp {table} gg spec 
// @param node {dict}  
// @returns {(float;float)} renderer origin
.z.m.gg.spec.rendererOrigin:{[sp; node]
    : spec.ty.component.origin .z.m.axds.tree.node.item spec.findAncestorCanvasNode[sp;node];
    }

// @fileOverview 
// Return the root node of the tree
// @param spec {table} specification tree
// @returns {dict}
.z.m.gg.spec.root:{[spec]  .z.m.axds.tree.root spec }

// @fileOverview 
// Rotate the aesthetics on the provided layer so the next (or last)
// aes is used for each mapping
// @param lyr {dict} layer
// @returns {dict} list of updated (rotated, unitialized) layer
.z.m.gg.spec.rotateLayer:{[lyr]
    lyr[`aes]: {1_raze x,last x} each lyr`origAes;
    : lyr;
    }

// @fileOverview Return a dictionary of the share dependencies in a gg spec
// @param sp {table} gg spec
// @returns {dict} Map from label/axis name pairs to a list of the IDs of layers which share that axis
.z.m.gg.spec.shareMap:{[sp]
    shares: {x[`id]!spec.pluck[`defn][x]@\:`share} spec.every[spec.ty.layer; sp];
    shares: key[shares][where not (::) ~/: value shares]#shares;
    shares: raze {(x,/:flip (key;value)@\:y)}'[key shares;value shares];
    : shares[;0] group shares[;2 1]
    }

// @fileOverview 
// Promote a layer to a specification
// @param lyr {dict}
//
// @returns {table} specification table containing the layer
.z.m.gg.spec.single:{[lyr]
    item : spec.component [::; ::; ::; spec.ty.layer.new (::; lyr)];
    : .z.m.axds.tree.add.root[item] .z.m.axds.tree.new[];
    }


.z.m.gg.spec.split:{[left; right]
    if [0 < count (,/) spec.every [spec.ty.layout] right;    '.z.m.axlocalize.t`.gg_specSplitLayoutRight];
    if [0 < count (,/) spec.every [spec.ty.layout] left;     '.z.m.axlocalize.t`.gg_specSplitLayoutLeft];
    : .z.m.axds.tree.new , .z.m.axds.tree.connect [spec.component [::; ::; ::; spec.ty.split.new (::;()!())]] (left; right);
    }

// @fileOverview
// Returns a spec where each frame is renderered seperately
// @param sp {table}
// @returns {table} updated specification tree
.z.m.gg.spec.splitFrames:{[sp]
    : spec.i.insertCanvasNodes[sp; spec.root sp];
    }

// @fileOverview 
// Arrange the layers in the specification list in a square grid layout
// @param speclist {table[]} list of specification trees
//
// @returns {table} composed specification tree
.z.m.gg.spec.square:{[speclist]
    : .z.m.axds.tree.new, spec.i.addlayout[`square; (count speclist)#1; speclist];
    }


.z.m.gg.spec.stack:{[speclist;post]
    if [0 < count (,/) spec.every [spec.ty.layout] each speclist; '.z.m.axlocalize.t`.gg_specStackLayout];
    : .z.m.axds.tree.new , .z.m.axds.tree.connect [spec.component [::; ::; ::; spec.ty.stack.new (::;()!();post)]] speclist;
    }

// @fileOverview 
// Return all unerrored layers under a (stack) node
// @param sp {table} specification tree 
// @param root {dict} specification node
// 
// @returns {dict[]} list of layer nodes
.z.m.gg.spec.stackLayers:{[sp; root]
    layers: spec.every[spec.ty.layer] select from .z.m.axds.tree.descendants[root;sp] where not null id;
    : layers where .z.m.gg.h.null each .z.m.gg.h.atAll[`error] .z.m.gg.spec.pluck[`defn] layers;
    }

// @fileOverview 
// Return a fully qualified theme (prefering depth)
// @param node {dict} specification node (acting leaf) 
// @param spec {table} specification tree
//
// @returns {dict} fully qualified theme
.z.m.gg.spec.theme:{[node; spec]
    : .z.m.gg.theme.default , spec.collect [enlist spec.ty.theme; node; spec]
    }

// @fileOverview 
// Convert a node to it's bounds specification of the form:
//     ``  ( (xmin; xmax); (ymin; ymax) ) ``
// @param node {dict} specification node (sized) 
// @returns {number[][]} bounds list
.z.m.gg.spec.toBounds:{[node]
    c   : spec.node.item node;
    o   : spec.ty.component.origin c;
    wth : spec.ty.component.w c;
    hgt : spec.ty.component.h c;
    
    : ( (o 0; o[0] + wth); (o 1; o[1] + hgt) );
    }

// @fileOverview 
// Sets a field of a specific component from each tree node
// If the spec is a single node, a single value is given back
// @param field {symbol} the field to update
// @param values {any[]} new values to set 
// @param sp {table} specification table
// @returns {table} specification table 
.z.m.gg.spec.update:{[field; values; sp]

    isDict : 99h ~ type sp;
    
    if [isDict;
        sp     : enlist sp;
        values : enlist values];
    
    if [0 = count sp;
        : ()];

    result: .[;(`item;`entry;field);:;]'[sp;values];
    
    : $[isDict; first result; result]
    }

// @fileOverview Utility to update a list of layers with new items
// @param sp {table} gg spec
// @param nodes {table} layer nodes to update
// @param layers {table} new layer values to update to
// @param options {dict} options
// @desc options.rollup {boolean} whether the spec should be reconstructed into a single table (default: 1b)
// @desc options.dirty  {boolean} whether the updated layers should be dirtied (default: 0b). Only used when rollup is 1b
// @returns {table} either the new spec (`rollup:1b`) or a list of new layer nodes (`rollup:0b`)
.z.m.gg.spec.updateLayers:{[sp; nodes; layers; options]
    options: (``rollup`dirty!(::;1b;0b)), $[(::) ~ options; ()!(); options];
    
    newNodes: {[layerNode; lyr]
        component : spec.ty.component.with.entry[spec.ty.layer.new (::; lyr)] spec.node.item layerNode;
        : spec.node.with.item[component] layerNode;
        }'[nodes; layers];
    
    if [not options`rollup;
        : newNodes];
    
    : $[options`dirty; spec.makeDirty/[;newNodes]; ::]
        spec.updateNodes[sp; newNodes];
    }

// @fileOverview 
// Updates the spec with the given nodes
// @param sp {table} gg specification tree
// @param nodes {table} list of nodes to update in the spec
// @returns {table} updated spec tree
.z.m.gg.spec.updateLinkables:{[sp;nodes]
    
    layers    : spec.every[spec.ty.layer]    nodes;
    externals : spec.every[spec.ty.external] nodes;
    
    : spec.updateLayers[; layers; spec.rotateLayer each scale.resetScales spec.pluck[`defn] layers; ``dirty!(::;1b)]
        spec.makeDirty/[;externals] spec.updateNodes[sp; externals]; // Update/dirty externals
    }
// @fileOverview 
// Given a list of changed components, update all linked components with the same data as the changed component
// Dirties canvas nodes of linked components
// @param changedCs {table} specification subset of changed components 
// @param sp {table} full specification
// @returns {table} updated specification
.z.m.gg.spec.updateLinks:{[changedCs; sp]
    linkedIdx: where not h.null each h.atAll[`linkid] spec.pluck[`defn] changedCs;
    allLinkableCs : spec.every[spec.ty.layer;sp], spec.every[spec.ty.external;sp];
    
    : {[allLinkableCs; sp; changedLinkable]
        
        changedDefn : spec.pluck[`defn] changedLinkable;
        linkid      : changedDefn`linkid;
        
        linked     : linkid ~/: h.atAll[`linkid] spec.pluck[`defn] allLinkableCs;
        notChanged : not changedLinkable[`id] = allLinkableCs`id;
        toUpdate   : allLinkableCs where linked and notChanged;
        
        : {[data; sp; node]
            defn: @[;`data;:;data] spec.pluck[`defn] node;
            if[isLayer: spec.ty.layer.is spec.ty.component.entry spec.node.item node;
                defn: first scale.resetScales enlist defn];
            
            newComponent: $[isLayer;
                spec.ty.component.with.entry[spec.ty.layer.new (::; defn)] spec.node.item node;
                spec.update[`defn; defn; node]`item];
            
            : spec.modify[node; newComponent] spec.makeDirty[sp;node];
            }[changedDefn`data]/[sp; toUpdate];
        
        }[allLinkableCs]/[sp; changedCs linkedIdx];
    }

// @fileOverview Replace nodes with matching ids in the spec
// @param sp {table} old spec 
// @param nodes {dict[]} spec nodes to update 
// @returns {table} new spec
.z.m.gg.spec.updateNodes:{[sp;nodes] sp { spec.modify[y; y`item; x] }/nodes }

// @fileOverview 
// Updates the spec with the given nodes, and updates layer and external nodes which are linked to an updated layer/external node
// @param sp {table} gg specification tree
// @param nodes {table} list of nodes to update in the spec
// @returns {table} updated spec tree
.z.m.gg.spec.updateSpec:{[sp;nodes]
    : spec.updateLinks[nodes] spec.updateLinkables[sp;nodes]
    }
// @fileOverview 
// Compose the specification trees in a vertical layout
// @param speclist {table[]} list of specifications to compose
// @returns {table} updated specification tree
.z.m.gg.spec.vert:{[speclist]
    : spec.i.addlayout[`vert; ::; speclist];
    }

// @fileOverview 
// Arrange the specification trees in a vertical layout using pixels. 
// @param pixels {number[]}
// @param speclist {table[]} list of specifications to arrange
// @returns {table} arranged specification
.z.m.gg.spec.vert_p:{[pixels; speclist]
    : spec.i.addlayout[`vert_p; (count speclist)#pixels; speclist];
    }

// @fileOverview 
// Arrange the specification trees in a vertical layout. The 
// visual heights will be weighted by the given weights.
// @param weights {number[]}
// @param speclist {table[]} list of specifications to arrange
// @returns {table} arranged specification
.z.m.gg.spec.vert_w:{[weights; speclist]
    : spec.i.addlayout[`vert; (count speclist)#weights; speclist];
    }

// @fileOverview 
// Add a dictionary of defaults for all descendant layers to inherit
// @param defaults {dict} dictionary of default settings 
// @param spec {table} specification tree
// @returns {table} updated specification tree
.z.m.gg.spec.with.defaults:{[defaults; spec]
    item : spec.component [::; ::; ::; spec.ty.defaults.new enlist defaults];
    : .z.m.axds.tree.add.root [item] spec;
    }

// @fileOverview 
// Add a facet node to a specification tree
// @param column {symbol} 
// @param spec {table} specification tree
// @returns {table} updated specification tree
.z.m.gg.spec.with.facet:{[column; spec]
    item : spec.component [::; ::; ::; spec.ty.facet.new enlist column];
    : .z.m.axds.tree.add.root [item] spec;
    }

// @fileOverview 
// Turn an unsized specification tree into a sized tree. All components
// are given an absolute origin, width, and height.
// @param origin {(number;number)} parent origin 
// @param w {number} 
// @param h {number} 
// @param root {dict} current specification node 
// @param sp {table} specification tree
// @returns {table} fully sized specification tree
.z.m.gg.spec.with.i.sizeAndPos:{[origin; w; h; root; sp]
    origin : "f"$origin;
    w      : "f"$w;
    hh     : "f"$h;
    entry  : spec.ty.component.entry spec.node.item root;
    
    sizeLayout: {[origin; w; h; root; sp]
        vertSize: {[typ; origin; w; h; root; sp]
            component:  @[.z.m.axds.tree.node.item root; `origin`w`h; :; (origin; 1|w; 1|h)];
            root:       .z.m.axds.tree.node.with.item[component; root];
            children:   spec.children[root;sp];
            weights:    spec.ty.layout.weights spec.ty.component.entry spec.node.item root;
            if [(::) ~ weights; weights: count[children]#1f];
            h2:         spec.i.linearLayout[weights; typ;h;root];
            origins:    origin[0],/:origin[1]+0,sums -1_h2;
            if [0 = count children; : root];
            root , raze spec.with.i.sizeAndPos[;1|w;;;sp]'[origins; 1|h2; children] };
        horiSize: {[typ; origin; w; hh; root; sp]
            component:  @[.z.m.axds.tree.node.item root; `origin`w`h; :;  (origin; 1|w; 1|hh)];
            root:       .z.m.axds.tree.node.with.item[component; root];
            children:   spec.children[root;sp];
            weights:    spec.ty.layout.weights spec.ty.component.entry spec.node.item root;
            if [(::) ~ weights; weights: count[children]#1f];
            w2:         spec.i.linearLayout[weights; typ;w;root];
            origins:    (origin[0]+0,sums -1_w2),\:origin 1;
            if [0 = count children; : root];
            root , raze spec.with.i.sizeAndPos[;;1|hh;;sp]'[origins; 1|w2; children] };
         facetGridSize: {[origin; w; h; root; sp]
            th:         spec.theme[root;sp];
            dim:        spec.ty.layout.weights spec.ty.component.entry spec.node.item root;
            component:  @[.z.m.axds.tree.node.item root; `origin`w`h; :;  (origin; 1|w; 1|h)];
            root:       .z.m.axds.tree.node.with.item[component; root];
            children:   spec.children[root;sp];
            if [2 <> count dim; '.z.m.axlocalize.t`.gg_gridNumError];
            if [any null dim; '"Dimensions must not be null"];
            hoffset:    sum each th `bottom`top!(`axis_offset`padding_top`plot_margin_top;   `padding_bottom`plot_margin_bottom);
            woffset:    sum each th `left`right!(`axis_offset`padding_left`plot_margin_left; `padding_right`plot_margin_right);
            coord:      @[;`coord] spec.pluck[`defn] first spec.every[spec.ty.layer] sp;
            hoffset[`bottom] +: spec.frame.i.axisSize[0N; th; coord; `x];
            woffset[`left]   +: spec.frame.i.axisSize[0N; th; coord; `y];
            n:          count children;
            ws:         1| .[;(::;dim[0]-1);woffset[`right]+] .[;(::;0);woffset[`left]+] reverse[dim]#(w - sum woffset) % dim 0;
            hs:         1| @[;dim[1]-1;hoffset[`bottom]+]     @[;0;hoffset[`top]+]       reverse[dim]#(h - sum hoffset) % dim 1;
            xs:         sums each -1_'origin[0] ,' ws;
            ys:         sums flip -1_'origin[1] ,' flip hs;
            origins:    n#(raze xs) ,' raze ys;
            root , raze spec.with.i.sizeAndPos[;;;;sp]'[origins;raze ws;raze hs;children] };
        gridSize: spec.i.grid 0b;
        fillGridSize: spec.i.grid 1b;
        squareSize: {[origin; w; h; root; sp]
            squares:    (1 + til 20) * 1 + til 20;
            component:  @[.z.m.axds.tree.node.item root; `origin`w`h; :; (origin; 1|w; 1|h)];
            root:       .z.m.axds.tree.node.with.item[component; root];
            children:   spec.children[root;sp];
            n:          count children;
            size:       "j"$sqrt first squares where squares > n;
            w2:         w % size;
            h2:         h % 1 + first where n <= size * 1 + til size;
            matrix:     (size;size)#(raze size#enlist til size) ,' raze (size#) each til size;
            xs:         origin[0] + matrix[;;0] * w2;
            ys:         origin[1] + matrix[;;1] * h2;
            origins:    n#(raze xs) ,' raze ys;
            root , raze (spec.with.i.sizeAndPos[;1|w2;1|h2;;sp].) each (enlist each origins) ,' enlist each children };
        kind : spec.pluck[`type] root;
        : .z.m.axds.tree.new , $[kind ~ `vert;    vertSize      [`weights; origin; 1|w; 1|h; root; sp];
                           kind ~ `hori;      horiSize      [`weights; origin; 1|w; 1|h; root; sp];
                           kind ~ `vert_p;    vertSize      [`pixels;  origin; 1|w; 1|h; root; sp];
                           kind ~ `hori_p;    horiSize      [`pixels;  origin; 1|w; 1|h; root; sp];
                           kind ~ `square;    squareSize    [          origin; 1|w; 1|h; root; sp];
                           kind ~ `grid;      gridSize      [          origin; 1|w; 1|h; root; sp];
                           kind ~ `fillGrid;  fillGridSize  [          origin; 1|w; 1|h; root; sp];
                           kind ~ `facetGrid; facetGridSize [          origin; 1|w; 1|h; root; sp];
                               '"Invalid layout"];
        };
    sizeStack: {[origin; w; h; root; sp]
        component:  @[.z.m.axds.tree.node.item root; `origin`w`h; :; (origin;1|w;1|h)];
        root:       .z.m.axds.tree.node.with.item[component; root];
        children:   spec.children[root;sp];
        .z.m.axds.tree.new , root , raze spec.with.i.sizeAndPos[origin;1|w;1|h; ; sp] each children };
    sizeLayer: {[origin; w; h; root; sp]
        component:  @[.z.m.axds.tree.node.item root; `origin`w`h; :; (origin;1|w;1|h)];
        enlist .z.m.axds.tree.node.with.item[component; root] };
    sizeDefaults: {[origin; w; h; root; sp]
        component:  @[.z.m.axds.tree.node.item root; `origin`w`h; :; (origin;1|w;1|h)];
        root:       .z.m.axds.tree.node.with.item[component; root];
        children:   spec.children[root;sp];
        .z.m.axds.tree.new , root , raze spec.with.i.sizeAndPos[origin;1|w;1|h;;sp] each children };
    sizeTheme:{[origin; w; h; root; sp]
        component:  .z.m.axds.tree.node.item root;
        th:         spec.ty.theme.get spec.ty.component.entry .z.m.axds.tree.node.item root;
        position:   (origin;1|w;1|h);
        if [`margin_left   in key th; position[1] -: th`margin_left;    position[0;0] +: th`margin_left];
        if [`margin_right  in key th; position[1] -: th`margin_right];
        if [`margin_top    in key th; position[2] -: th`margin_top;     position[0;1] +: th`margin_top];
        if [`margin_bottom in key th; position[2] -: th`margin_bottom];
        component[`origin`w`h]: position;
        root:       .z.m.axds.tree.node.with.item[component; root];
        children:   spec.children[root; sp];
        .z.m.axds.tree.new , root , raze spec.with.i.sizeAndPos[position 0;position 1;position 2;;sp] each children };
    sizeTitle: {[origin; w; h; root; sp]
        th:             spec.theme[root; sp];
        titleHeight:    2*th`title_padding;
        childOrigin:    (origin 0; origin[1] + titleHeight);
        children:       spec.children[root;sp];
        origin          +: th`plot_margin_left`plot_margin_top;
        component:      @[.z.m.axds.tree.node.item root; `origin`w`h; :; (origin;
                1|w - sum th`plot_margin_left`plot_margin_right;
                1|titleHeight)];
        root:           .z.m.axds.tree.node.with.item[component; root];
        .z.m.axds.tree.new , root , raze spec.with.i.sizeAndPos[childOrigin;1|w;1|h - titleHeight;;sp] each children };
    sizeCanvas: {[origin; w; h; root; sp]
        component:      @[.z.m.axds.tree.node.item root; `origin`w`h; :; (origin;1|w;1|h)];
        root:           .z.m.axds.tree.node.with.item[component; root];
        children:       spec.children[root;sp];
        .z.m.axds.tree.new , root , raze spec.with.i.sizeAndPos[origin;1|w;1|h;;sp] each children 
        };
    
    sizeExternal: {[origin; w; h; root; sp] 
        component: @[.z.m.axds.tree.node.item root; `origin`w`h; :; (origin;1|w;1|h)];
        root     : .z.m.axds.tree.node.with.item[component; root];
        children : spec.children[root;sp];
        : .z.m.axds.tree.new , root , raze spec.with.i.sizeAndPos[origin;1|w;1|h;;sp] each children;
        };
    
    : $[    spec.ty.layout.is entry;   sizeLayout   [origin; 1|w; 1|hh; root; sp];
            spec.ty.defaults.is entry; sizeDefaults [origin; 1|w; 1|hh; root; sp];
            spec.ty.stack.is entry;    sizeStack    [origin; 1|w; 1|hh; root; sp];
            spec.ty.split.is entry;    sizeStack    [origin; 1|w; 1|hh; root; sp];
            spec.ty.layer.is entry;    sizeLayer    [origin; 1|w; 1|hh; root; sp];
            spec.ty.title.is entry;    sizeTitle    [origin; 1|w; 1|hh; root; sp];
            spec.ty.theme.is entry;    sizeTheme    [origin; 1|w; 1|hh; root; sp];
            spec.ty.facet.is entry;    spec.i.grid  [0b; origin; 1|w; 1|hh; root; sp];
            spec.ty.canvas.is entry;   sizeCanvas   [origin; 1|w; 1|hh; root; sp];
            spec.ty.external.is entry; sizeExternal [origin; 1|w; 1|hh; root; sp];
            ()];
    }

// @fileOverview 
// Starting at (0,0) (top-left), size a specification tree.
// Every node in the tree is given an absolute origin, width
// and height
// @param w {number} 
// @param h {number} 
// @param spec {table} specification tree
// @returns {table} sized specification table
.z.m.gg.spec.with.size:{[w; h; spec] spec.with.sizeAndPos[0 0; w; h; spec] }

// @fileOverview 
// Starting at a given postion, size a specification tree.
// Every node in the tree is given an absolute origin, width
// and height
// @param origin {(number;number)}
// @param w {number}
// @param h {number} 
// @param spec {table} specification tree
// @returns {table} sized specification table
.z.m.gg.spec.with.sizeAndPos:{[origin; w; h; spec]
    : spec.with.i.sizeAndPos[origin; w; h; spec.root spec; spec];
    }
// @fileOverview 
// Add a theme node to a specification tree
// @param th {dict} 
// @param spec {table} specification tree
// @returns {table} updated specification tree
.z.m.gg.spec.with.theme:{[th; spec]
    item : spec.component [::; ::; ::; spec.ty.theme.new enlist th];
    : .z.m.axds.tree.add.root [item] spec;
    }

// @fileOverview 
// Add a title node to a specification tree
// @param title {string} 
// @param spec {table} specification tree
// @returns {table} updated specification tree
.z.m.gg.spec.with.title:{[title; spec]
    item : spec.component [::; ::; ::; spec.ty.title.new enlist title];
    : .z.m.axds.tree.add.root [item] spec;
    }

.z.m.gg.spec.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.gg_gridNumError; "spec grid error: grid must have exactly two dimensions defined");
        (`.gg_gridNullError; "spec grid error: grid must have at least one non-null value");
        (`.gg_gridDimensionError; "spec grid error: grid specification does not hold all frames");
        (`.gg_specStackLayout; "spec stack error: stacks cannot contain other layouts");
        (`.gg_specSizeError; "resize error: canvas is not large enough to hold frame components");
        (`.gg_specFrameError; "frame spec error: can only add a frame to stack, split, and layer nodes");
        (`.gg_specSplitLayoutLeft; "spec split error: left splits cannot contain other layouts");
        (`.gg_specSplitLayoutRight; "spec split error: right splits cannot contain other layouts")))
 
.z.m.gg.spec.onLoad:{[]
        
    
    .z.m.axdatatype.create[ .z.M.gg.spec.ty.component; `origin`w`h`entry; `origin`w`h`entry];
    

    .z.m.axdatatype.create[ .z.M.gg.spec.ty.layer;    `frame`defn; `defn`frame];
    
    
    .z.m.axdatatype.create[ .z.M.gg.spec.ty.external; `defn`state`output; `defn`state`output];
    
    
    .z.m.axdatatype.create[ .z.M.gg.spec.ty.stack;    `frame`get`post; `frame`post];
    
    
    .z.m.axdatatype.create[ .z.M.gg.spec.ty.split;    `frame`get; enlist `frame];
    
    
    .z.m.axdatatype.create[ .z.M.gg.spec.ty.layout;   `type`weights; ()];
    
    
    .z.m.axdatatype.create[ .z.M.gg.spec.ty.title;    enlist `get; ()];
    
    
    .z.m.axdatatype.create[ .z.M.gg.spec.ty.defaults; enlist `get; ()];
    
    
    .z.m.axdatatype.create[ .z.M.gg.spec.ty.theme;    enlist `get; ()];
    
    
    .z.m.axdatatype.create[ .z.M.gg.spec.ty.facet;    enlist `get; ()];
    
    
    .z.m.axdatatype.create[ .z.M.gg.spec.ty.canvas;   `splitframe`dirty`resize; `dirty`resize];
    
    
    }

.z.m.gg.spec.onLoad[];
system "d .z.m";

system "d .z.m.gg";
// @fileOverview 
// Return a background fill etable
// @param f {byte[]} fill colour as 0xAARRGGBB
// @param s {byte[]} stroke colour as 0xAARRGGBB
// @returns {table} background fill etable
.z.m.gg.i.rules.background:{[f;s]
    useStroke: 0 = first s;
    : etable.el[etable.g.RECT] enlist `x`y`w`h`colour`strokewidth`strokecolour!(0;1;1;1;0x0 sv f;$[useStroke;0N;1];$[useStroke;0Ni;0x0 sv s]);
    }
// @fileOverview 
// Return a background fill etable for 3D plots
// @param b1 {(float;float;float)} basis vector
// @param b2 {(float;float;float)} basis vector
// @param f {byte[]} fill colour as 0xAARRGGBB
// @param s {byte[]} stroke colour as 0xAARRGGBB
// @returns {table} background fill etable
.z.m.gg.i.rules.background3D:{[b1;b2;f;s]
    centre: i.rules.i.gridCentre[b1;b2];
    polys: {[centre;x] @[centre;0 1 2 _ x;:;] each @[;2 3;:;l 3 2] l: 0 1 cross 0 1}[centre] each 0 1 2;
    : raze etable.el[etable.g.PATH3D] each {[f;s;centre;x] `xs`ys`zs`close`colour`strokewidth`strokecolour!
        flip[x],(1b;0x0 sv f;1;0x0 sv s)}[f;s;centre] each polys;
    }

// @fileOverview 
// Return an etable describing the grid of a plot
// @param th {dict} theme
// @param scales {dict}
//
// @returns {table} etable of a grid
.z.m.gg.i.rules.grid:{[th; scales]
    : raze (::;i.transforms.reflect) @' i.rules.i.grid[;th;]'[th`grid_style_x`grid_style_y; scales`x`y]
    }

// @fileOverview 
// Returns styled 3D-grid lines for a single scale
// @param b1 {(float;float;float)} basis vector
// @param b2 {(float;float;float)} basis vector
// @param th {dict} 
// @param scales {dict} 
// @returns {table} etable
.z.m.gg.i.rules.grid3D:{[b1;b2;th;scales]
    : raze i.rules.i.gridTo3D[b1;b2] .' flip (`x`y`z;) i.rules.i.grid[;th;]'[th`grid_style_x`grid_style_y`grid_style_z; scales`x`y`z]
    }

// @fileOverview 
// Return an abstract guide etable. This can be used to
// create components such as axes and legends.
// @param title {string|symbol} 
// @param scale {dict} 
// @param chars {number} number of chars max for each tick label
// @param th {dict}   (`line_strokewidth`line_fill`tick_size`tick_fill`label_size`label_fill)
//
// @returns {table} abstract etable describing a guide
.z.m.gg.i.rules.guide:{[title; scale; chars; th]
    
    etab : etable.EMPTY;
    
    etab ,: etable.el[i.rules.g.DOMLINE; enlist `x1`x2`y1`y2`colour`size!(0; 1; 1; 1; th`line_fill; th`line_strokewidth)];

    ticklabels : (,) over {[s;t;c;b]
        pb   : proj.proj[s`geom_limits;0 1; b];
        tick : etable.el[i.rules.g.TICK;  enlist `x1`x2`y1`y2`colour`size!(pb; pb; 1; "f"$1 - t`tick_length; t`line_fill; t`line_strokewidth)];
        lab  :  etable.el[i.rules.g.TICKLABEL; enlist (!) . flip (
                (`fontsize; t`tick_size);
                (`x;        pb);
                (`y;        t`tick_start);
                (`colour;   colour.fromBytes t`tick_fill);
                (`text;     `$h.print h.trim[i.rules.i.MAXYCHARS] scale.applyFormat[s] scale.inverse[s] b);
                (`angle;    0);
                (`bold;     t`tick_bold);
                (`italic;   t`tick_italic);
                (`maxChars; c))];
        : lab , tick
        }[scale;th;chars] each scale`breaks;
        
    etab ,: ticklabels;
    
    etab ,: etable.el[i.rules.g.LABEL; enlist (!) . flip (
            (`fontsize; th`label_size);
            (`x;        0.5);
            (`y;        0.1);
            (`colour;   colour.fromBytes th`label_fill);
            (`text;     `$h.print title);
            (`angle;    0);
            (`bold;     th`label_bold);
            (`italic;   th`label_italic) )];

    : etab;
    
    }

// @fileOverview 
// Returns styled grid lines for a single scale
// @param style {symbol} line style (`zebra, `lines, `dashed, `none)
// @param th {dict} 
// @param sc {dict} scale
// @returns {table} etable
.z.m.gg.i.rules.i.grid:{[style; th; sc]
    etab  : etable.EMPTY;
    etab ,: $[`zebra ~ style;
                    i.rules.i.zebra[th; sc];
              `lines ~ style;
                    i.rules.i.lines[`solid; th; sc];
              `dashed ~ style;
                    i.rules.i.lines[`dashed; th; sc];
              `none ~ style;
                    ();
                    ()];
    : etab;
    }

// @fileOverview 
// Find the point around which the background grid of a 3D plot should
// be centered around
// @param b1 {(float;float;float)} basis vector
// @param b2 {(float;float;float)} basis vector
// @returns {(float;float;float)} 
.z.m.gg.i.rules.i.gridCentre:{[b1;b2]
    verticals: where in [;1 3] proj.quadrant each proj.multi.planeProjection[b1;b2] @[3#0;;:;1] each 0 1 2;
    bounds: 0 1 cross 0 1 cross 0 1;
    centres: bounds where proj.inDrawingArea[b1;b2] each proj.multi.planeProjection[b1;b2] bounds;
    : $[0<count centres;
        centres p?max p:(proj.multi.planeProjection[b1;b2] .[centres;(::;verticals);:;0])[;1];
        0 0 0];
    }

// @fileOverview 
// Transforms an etable for a 2D grid into one for a 3D grid based on the provided axis
// @param axis {symbol} name of the target axis (x/y/z);
// @param grid {table} etable to transform
// @returns {table} etable for a 3D grid
.z.m.gg.i.rules.i.gridTo3D:{[b1;b2;axis;grid]
    if[0=count grid;:grid];
    axis: `x`y`z?axis;
    centre: i.rules.i.gridCentre[b1;b2];
    maps: (@[;;:;2] @[1 1 1;axis;:;0]) each 0 1 2_axis;
    transforms: .[{[map;d;lines]
        @[lines;`x1`x2`y1`y2`z1`z2;:;] raze
            (lines`x1`x2;lines`y1`y2;(2;count lines)#d) map
        }] each flip (maps;centre _ axis);

    : etable.replace[etable.g.LINE;etable.g.LINE3D] @[grid;`settings; {[transforms;lines]
            :raze @[;lines] each transforms;
            }[transforms] each]
    }

// @fileOverview 
// Returns line style grid lines for a single scale
// @param style {symbol} `dashed or `lines 
// @param th {dict} 
// @param sc {dict} scale
// @returns {table} etable
.z.m.gg.i.rules.i.lines:{[style; th; sc]
    etab  : etable.EMPTY;
    etab ,: i.rules.i.majorLine[style; th; ::; sc];
    etab ,: i.rules.i.minorLine[style; th; ::; sc];
    : etab;
    }

// @fileOverview 
// Returns major lines for a line-style grid for a single scale
// @param style {symbol} `dashed or `lines 
// @param th {dict} 
// @param coords {dict} coordinate system 
// @param sc {dict} 
// @returns {table} etable
.z.m.gg.i.rules.i.majorLine:{[style; th; coords; sc]
    : etable.el [etable.g.LINE] {[sty;s;t;b]
        pb: proj.proj[s`geom_limits;0 1; b];
        : `x1`x2`y1`y2`colour`size`dashed!(pb; pb; 0; 1; t`grid_majorLine_fill; t`grid_majorLine_strokewidth;sty~`dashed);
        }[style;sc;th] each sc`breaks;
    }

.z.m.gg.i.rules.i.maxChars:{[th; sc]
    $[th`dynamic_axes; i.rules.i.MAXYCHARS; sc`maxChars]
    }

// @fileOverview 
// Returns minor lines for a line-style grid for a single scale
// @param style {symbol} `dashed or `lines 
// @param th {dict} theme
// @param coords {dict} coordinate system 
// @param sc {dict} 
// @returns {table} etable
.z.m.gg.i.rules.i.minorLine:{[style; th; coords; sc]
    
    etab : etable.EMPTY;
    
    if [scale.i.data.types.numeric ~ sc`inverseType;
        intervals: %[;2] 1_deltas scale.inverse[sc] sc`breaks; // midpoints
        etab ,: etable.el[etable.g.LINE] {[sty;s;t;b]
            pb: proj.proj[s`geom_limits;0 1; scale.apply[s; b]];
            : `x1`x2`y1`y2`colour`size`dashed!(pb; pb; 0; 1; t`grid_minorLine_fill; t`grid_minorLine_strokewidth;sty~`dashed);
            }[style;sc;th] each (-1_scale.inverse[sc] sc`breaks) + intervals];
    
    : etab;
    
    }

// @fileOverview 
// Given a guide, angle all the tick labels by the specified amount,
// and apply the given text alignment
// @param angle {number} degrees 
// @param g {symbol} alignment `atextL `atextM or `atextR 
// @param guide {table} guide etable
// @returns {table} updated etable
.z.m.gg.i.rules.i.styleTickLabels:{[angle; g; guide]
    : raze {[angle; g; x]
        : $[not i.rules.g.TICKLABEL ~ etable.geom x; enlist x; etable.el[g; @[etable.settings x; `angle; :; angle]]];
        }[angle; g] each guide;
    }

// @fileOverview 
// Return an aligned text3D geometry given an alignment
// @param s {symbol}
// @returns {symbol}
.z.m.gg.i.rules.i.text3DFromAnchor:{[s]
    : $[s ~ `left;   etable.g.ATEXTL3D;
        s ~ `middle; etable.g.ATEXTM3D;
        s ~ `right;  etable.g.ATEXTR3D;
                     etable.g.ATEXTM3D];
    }

// @fileOverview 
// Return an aligned text geometry given an alignment
// @param s {symbol}
// @returns {symbol}
.z.m.gg.i.rules.i.textFromAnchor:{[s]
    : $[s ~ `left;   etable.g.ATEXTL;
        s ~ `middle; etable.g.ATEXTM;
        s ~ `right;  etable.g.ATEXTR;
                     etable.g.ATEXTM];
    }

.z.m.gg.i.rules.i.updateDefShapes:{[th; src; dst; legend]
    shapes: etable.qualify etable.every[src] legend;
    
    if [0 < count shapes;
        shapes[`colour] : 0x0 sv' (first each 0x0 vs' shapes`colour),\:-3#th`marker_default_fill;
        legend: update settings: enlist shapes from legend where geometry = src];
    
    : etable.replace [src; dst] legend;
    }

// @fileOverview 
// Return an etable describing a y axis. A y axis is simply a
// guide that has been reflected about y=x and text made right-aligned
// @param transformF {function} transform to run to create the axis 
// @param th {dict} 
// @param co {dict}
// @param title {char[]|symbol} 
// @param sc {dict} 
// @returns {table} etable description of a y axis
.z.m.gg.i.rules.i.yaxis:{[transformF; th; co; title; sc]
    guide : i.rules.guide[title; sc; i.rules.i.maxChars[th; sc];
        (!) . flip (
            (`line_strokewidth; th`axis_line_strokewidth);
            (`line_fill;        th`axis_line_fill);
            (`tick_size;        th`axis_tick_label_fontsize);
            (`tick_fill;        th`axis_tick_label_fill);
            (`tick_italic;      th`axis_tick_label_italic_y);
            (`tick_bold;        th`axis_tick_label_bold_y);
            (`label_size;       th`axis_label_fontsize);
            (`label_fill;       th`axis_label_fill);
            (`label_italic;     th`axis_label_italic);
            (`label_bold;       th`axis_label_bold);
            (`tick_length;      th`axis_tick_length_y);
            (`tick_start;       th`axis_tick_label_start_y)
            )];
    
    : transformF[th; co; title; sc; guide]
    }

// @fileOverview 
// Returns zebra-stripe style grid lines for a single scale
// @param th {dict} 
// @param sc {dict} scale
// @returns {table} etable
.z.m.gg.i.rules.i.zebra:{[th; sc]
    : etable.el [etable.g.RECT] {[s;t;b;i]
        pb1: proj.proj[s`geom_limits;0 1; b i];
        pb2: proj.proj[s`geom_limits;0 1; b i+1];
        : `x`w`y`h`colour!(pb1;pb2-pb1;1;1;t`grid_majorLine_fill);
        }[sc;th; sc`breaks] each ii where not 0 = mod[;2] ii: til max 0, -[;1] count sc`breaks;
    };
// @fileOverview 
// Return an etable description of a legend. A legend is just a 
// reflected guide with a title
// @param th {dict} 
// @param titlestr {string} 
// @param sc {dict}
// @returns {table[]} list of title and legend etables
.z.m.gg.i.rules.legend:{[th; titlestr; sc]
    
    chars   : sc`maxChars;
    legend  : i.rules.background . th`legend_background_fill`legend_background_stroke;
    legend ,: i.rules.guide [titlestr; sc; chars;
        (!) . flip (
            (`line_strokewidth; th`axis_line_strokewidth);
            (`line_fill;        th`axis_line_fill);
            (`tick_size;        th`axis_tick_label_fontsize);
            (`tick_fill;        th`axis_tick_label_fill);
            (`label_size;       th`axis_label_fontsize);
            (`label_fill;       th`axis_label_fill);
            (`label_bold;       th`legend_title_bold);
            (`label_italic;     th`legend_title_italic);
            (`tick_length;      th`legend_tick_length);
            (`tick_start;       th`legend_tick_label_start)
            )];
    
    if [scale.colour.cat[][`label] ~ sc`label;
        tickLabels: etable.qualify etable.every[.z.m.gg.i.rules.g.TICKLABEL] legend;
        if [0 < count tickLabels;
            tickLabels[`x] +: 1 % 2 * (-). reverse sc`limits;
            legend: update settings : enlist each tickLabels from legend where geometry = .z.m.gg.i.rules.g.TICKLABEL]];
    
    legend ,: scale.guide sc;
    legend  : etable.replace [i.rules.g.TICKLABEL; etable.g.ATEXTR] legend;
    legend  : i.rules.i.updateDefShapes [th; scale.i.data.g.DEF_POINT; etable.g.POINT; legend];
    legend  : i.rules.i.updateDefShapes [th; scale.i.data.g.DEF_LINE;  etable.g.LINE;  legend];
    legend  : i.rules.i.updateDefShapes [th; scale.i.data.g.DEF_RECT;  etable.g.RECT;  legend];
    
    legend  : i.transforms.reflect legend;
    
    lines   : count "\n" vs h.asString titlestr;
    title   : i.rules.background . th`legend_header_background_fill`legend_header_background_stroke;
    titleS  : @[;`settings] first select from legend where geometry = `LABEL;
    titleS[`x`y]: (0.5; 1 - 0.5 % lines);
    title  ,: etable.el[etable.g.ATEXTM] titleS;
    
    : (title; legend; sc);
    }

// @fileOverview 
// Return an etable describing an x axis. An x axis is simply a guide.
// @param th {dict} theme
// @param co {dict} coordinates
// @param title {char[]|symbol} 
// @param sc {dict} scale
// @returns {table} etable describing an x axis
.z.m.gg.i.rules.xaxis:{[th; co; title; sc]
    guide : i.rules.guide[title; sc; sc`maxChars;
        (!) . flip (
            (`line_strokewidth; th`axis_line_strokewidth);
            (`line_fill;        th`axis_line_fill);
            (`tick_size;        th`axis_tick_label_fontsize);
            (`tick_fill;        th`axis_tick_label_fill);
            (`tick_italic;      th`axis_tick_label_italic_x);
            (`tick_bold;        th`axis_tick_label_bold_x);
            (`label_size;       th`axis_label_fontsize);
            (`label_fill;       th`axis_label_fill);
            (`label_italic;     th`axis_label_italic);
            (`label_bold;       th`axis_label_bold);
            (`tick_length;      th`axis_tick_length_x);
            (`tick_start;       th`axis_tick_label_start_x)
            )];
    
    : co[`xaxisTransformF][th; co; title; sc; guide];
    }

// @fileOverview 
// Return an etable describing a y axis. A y axis is simply a
// guide that has been reflected about y=x and text made right-aligned
// @param th {dict} theme
// @param co {dict} coords
// @param title {char[]|symbol} 
// @param sc {dict} scale
// @returns {table} etable description of a y axis
.z.m.gg.i.rules.yaxis:{[th; co; title; sc]
    : i.rules.i.yaxis[co`yaxisTransformF; th; co; title; sc]
    }
// @fileOverview 
// Return an etable describing a y axis. A y axis is simply a
// guide that has been reflected about y=x and text made right-aligned
// @param th {dict} theme
// @param co {dict} coords
// @param title {char[]|symbol} 
// @param sc {dict} 
// @returns {table} etable description of a y axis
.z.m.gg.i.rules.yaxis2:{[th; co; title; sc]
    : i.rules.i.yaxis[co`yaxis2TransformF; th; co; title; sc]
    }

// @fileOverview 
// Return an etable describing a z axis.
// @param th {dict} theme
// @param co {dict} coords
// @param title {char[]|symbol} 
// @param sc {dict} scale
// @returns {table} etable describing an x axis
.z.m.gg.i.rules.zaxis:{[th; co; title; sc]
    guide : i.rules.guide[title; sc; sc`maxChars;
        (!) . flip (
            (`line_strokewidth; th`axis_line_strokewidth);
            (`line_fill;        th`axis_line_fill);
            (`tick_size;        th`axis_tick_label_fontsize);
            (`tick_fill;        th`axis_tick_label_fill);
            (`tick_italic;      th`axis_tick_label_italic_z);
            (`tick_bold;        th`axis_tick_label_bold_z);
            (`label_size;       th`axis_label_fontsize);
            (`label_fill;       th`axis_label_fill);
            (`label_italic;     th`axis_label_italic);
            (`label_bold;       th`axis_label_bold);
            (`tick_length;      th`axis_tick_length_z);
            (`tick_start;       th`axis_tick_label_start_z)
            )];

    : co[`zaxisTransformF][th; co; title; sc; guide];
    }

.z.m.gg.i.rules.i.guideGeoms:i.rules.g.DOMLINE:`DOMLINE;
i.rules.g.TICK:`TICK;
i.rules.g.TICKLABEL:`TICKLABEL;
i.rules.g.LABEL:`LABEL;

.z.m.gg.i.rules.i.MAXYCHARS:50
system "d .z.m";

system "d .z.m.gg";
// @fileOverview
// Transforms a 2D guide into a 3D guide
// @returns {table} etable describing a 3D guide
.z.m.gg.coords.i.cube.guideTransform:{[b1; b2; guide; opts]
    tickDiff:  coords.i.cube.i.tickDifference[b1;b2;opts`shift;opts`tick_length];
    labelDiff: coords.i.cube.i.tickDifference[b1;b2;opts`shift;opts`tick_label_start];
    shift: (neg opts`shift) rotate;
    offset: coords.i.cube.i.axisOffset[b1;b2] opts`shift;
    
    projTickDiff: proj.planeProjection[b1;b2] tickDiff;
    quadrant: proj.quadrant projTickDiff;
    if[all (quadrant in 1 3;0<projTickDiff 1);
        tickDiff: neg tickDiff;
        labelDiff: neg labelDiff];
    if[all (quadrant in 0 2;0<projTickDiff 0);
        tickDiff: neg tickDiff;
        labelDiff: neg labelDiff];
    
    geomIdxs: group guide`geometry;
    : @[;geomIdxs`TICK;
        {[sh;td;off;x]
            s: x`settings;
            :.[x;(`settings;`x2`y2`z2`x1`y1`z1);:;] raze off+/:(st+td;st: sh (s[`x1] 0;0f;0f));
            }[shift;tickDiff;offset]]
        @[;geomIdxs`DOMLINE;   {[sh;off;x]:.[x;(`settings;`x2`y2`z2`x1`y1`z1);:;] raze off+/: (sh 1 0 0f; 0 0 0)}[shift;offset]]
        @[;geomIdxs`TICKLABEL; {[sh;ld;off;x]:.[x;(`settings;`x`y`z);:;] off+ ld+ sh (x[`settings][`x] 0;0f;0f)}[shift;labelDiff;offset]]
        @[;geomIdxs`LABEL;     {[sh;ld;off;x]:.[x;(`settings;`x`y`z);:;] off+ (2*ld)+ sh 0.5 0 0}[shift;labelDiff;offset]]
        guide;
    }

// @fileOverview 
// Creates an orthonormal basis for a 2D plane from an azimuth and altitude.
// See https://en.wikipedia.org/wiki/Azimuth for an explanation of azimuth and altitude
// @param azimuth  {float} azimuth in radians
// @param altitude {float} altitude in radians
// @returns {((float;float;float);(float;float;float))} Pair of 3D vectors which make up the plane basis
.z.m.gg.coords.i.cube.i.anglesToBasis:{[azimuth;altitude]
    b1: 0 1 0; // Unrotated basis vectors
    b2: 0 0 1;
    u: coords.i.cube.i.rotateAround[b2;azimuth;b1];
    v: coords.i.cube.i.rotateAround[u;altitude;b2];
    : (u;v);
    }

// @fileOverview 
// Transform the 2D guide into a 3D guide and project it to a 2D plane
// @returns {table} x-axis etable
.z.m.gg.coords.i.cube.i.axis:{[b1; b2; th; coords; title; scale; guide]
    
    guide : coords.i.cube.guideTransform[b1; b2; guide; th];
    guide : etable.replace[i.rules.g.DOMLINE;   etable.g.LINE3D;    guide];
    guide : etable.replace[i.rules.g.TICK;      etable.g.LINE3D;    guide];
    guide : i.rules.i.styleTickLabels[th`tick_label_angle; i.rules.i.text3DFromAnchor th`tick_label_anchor; guide];
    guide : etable.replace[i.rules.g.TICKLABEL; etable.g.ATEXTM3D;  guide];
    guide : etable.replace[i.rules.g.LABEL;     etable.g.ATEXTM3D;  guide];
    : guide;
    }
// @fileOverview
// Determines the axis offset for drawing the given axis.
//
// Scales are drawn in a position which may differ from where the
// axis lies. To decide the offset for drawing these scales, first we 
// determine what quadrant they belong to when projected into 2D.
// For axes belonging to what we call horizontal quadrants 
// (quadrants 0 and 2), the scales are offset in a way
// which minimizes their y position in 2D without overlapping
// with the drawing area.
// For other axes, belonging to vertical quadrants, we draw these
// as far to the left as possible in 2D without overlapping with the
// drawing area, meaning we minimize their x position in 2D.
//
// @param b1 {(float;float;float)} basis vector
// @param b2 {(float;float;float)} basis vector
// @param axisIdx {int} axis index
// @returns {(float;float;float)} vector to offset the axis by when drawing
.z.m.gg.coords.i.cube.i.axisOffset:{[b1;b2;axisIdx]
    shift: (neg axisIdx) rotate;
    axis: shift 1 0 0;
    quadrant: proj.quadrant proj.planeProjection[b1;b2] axis;
    origins: shift each 0 ,/: 0 1 cross 0 1;
    origins: origins where not any each 2 cut proj.inDrawingArea[b1;b2] each
        proj.planeProjection[b1;b2] each raze {(y;y+x)}[axis] each origins;
    if[0=count origins;origins: shift each 0 ,/: 0 1 cross 0 1];
    : $[quadrant in 0 2;
        origins p?min p:(proj.multi.planeProjection[b1;b2] origins)[;1];
        origins p?min p:(proj.multi.planeProjection[b1;b2] origins)[;0]];
    }

// @fileOverview
// Rotate one 3D vector about another 3D vector
// Rotation is clockwise if looking along the direction 
// of the vector being rotated about
// @param r {(float;float;float)} vector to rotate about
// @param rads {float} radians to rotate
// @param v {(float;float;float)} vector to rotate
// @returns {(float;float;float)} rotated vector
.z.m.gg.coords.i.cube.i.rotateAround:{[r;rads;v]
    rMatrix: (3 3#1 0 0 0 1 0 0 0 1)+(sin[rads]*a)+(1-cos rads)*a mmu a:"f"$3 3#(0;-1*r 2;r 1;r 2;0;-1*r 0;-1*r 1;r 0;0);
    : proj.dot[v] each rMatrix;
    };

// @fileOverview
// Returns a 3D vector equal to the difference between the 
// tick start and the tick end
// Vector will always have length equal to l, and will be
// colinear to u and v, and perpendicular to e_i (a vector 
// with 1 at the ith position, and 0s elsewhere)
// @param u {(float;float;float)} first plane basis vector
// @param v {(float;float;float)} second plane basis vector
// @param ii {int} index of the dimension ticks are drawn for
// @param l {float} length of the ticks
// @returns {(float;float;float)} tick difference vector
.z.m.gg.coords.i.cube.i.tickDifference:{[u;v;ii;l]
    if [(0=u ii) and 0=v ii; : 0 0 0];
    if [u[ii]=0; t: v; v: u; u: t];
    sqr: {x*x};
    a: $[0=ii mod 2;neg;::] sqrt sqr[l]*sqr[v ii] % sqr[u ii] + sqr v ii;
    b: $[a=0; neg l; neg a*u[ii] % v ii];

    : (a*u) + b*v;
    }

// @fileOverview
// 0-1 normalization using the boundary points (0 1 cross 0 1 cross 0 1)
// for the ranges
// @param b1 {(float;float;float)}
// @param b2 {(float;float;float)}
// @param pts {(float[];float[])} list of xs and ys to normalize
// @returns {(float[];float[])} the normalized points
.z.m.gg.coords.i.cube.normalize:{[b1; b2; pts]
    boundaryPts: flip proj.multi.planeProjection[b1;b2] 0 1 cross 0 1 cross 0 1;
    bounds: `minX`maxX`minY`maxY!raze (min;max)@\:/:boundaryPts;
    
    : (proj.proj[bounds`minX`maxX;0 1;pts 0]; proj.proj[bounds`minY`maxY;0 1;pts 1]);
    }


    
    
// @fileOverview 
// Transform the 2D guide into a 3D guide and project it to a 2D plane
// @returns {table} x-axis etable
.z.m.gg.coords.i.cube.xaxis:{[b1; b2; th; co; title; sc; guide]
    th: (!) . flip (
        (`tick_length;       th`axis_tick_length_x);
        (`tick_label_start;  th`axis_tick_label_start_x);
        (`tick_label_angle;  th`axis_tick_label_angle_x);
        (`tick_label_anchor; th`axis_tick_label_anchor_x);
        (`shift;             0));
            
    : coords.i.cube.i.axis[b1; b2; th; co; title; sc; guide]
    }
// @fileOverview 
// Transform the 2D guide into a 3D guide and project it to a 2D plane
// @returns {table} x-axis etable
.z.m.gg.coords.i.cube.yaxis:{[b1; b2; th; co; title; sc; guide]
    th: (!) . flip (
        (`tick_length;       th`axis_tick_length_y);
        (`tick_label_start;  th`axis_tick_label_start_y);
        (`tick_label_angle;  th`axis_tick_label_angle_y);
        (`tick_label_anchor; th`axis_tick_label_anchor_y);
        (`shift;             1));
            
    : coords.i.cube.i.axis[b1; b2; th; co; title; sc; guide]
    }
// @fileOverview 
// Transform the 2D guide into a 3D guide and project it to a 2D plane
// @returns {table} x-axis etable
.z.m.gg.coords.i.cube.zaxis:{[b1; b2; th; co; title; sc; guide]
    th: (!) . flip (
        (`tick_length;       th`axis_tick_length_z);
        (`tick_label_start;  th`axis_tick_label_start_z);
        (`tick_label_angle;  th`axis_tick_label_angle_z);
        (`tick_label_anchor; th`axis_tick_label_anchor_z);
        (`shift;             2));
            
    : coords.i.cube.i.axis[b1; b2; th; co; title; sc; guide]
    }
// @fileOverview Linearly interpolate a line
// @returns {float[][]} list of interpolated points
.z.m.gg.coords.i.interp:{[n; a; b]
    xs: proj.proj[(0;n-1); first each (a;b); til n];
    ys: proj.proj[(0;n-1); first each 1_'(a;b); til n];
    : flip (xs; ys)
    }

// @fileOverview Convert a polar coordinate to a rectangular coordinate
// @returns {(float;float)} Rect coordinate
.z.m.gg.coords.i.polar.apply:{[p] : (p[0] * cos p 1; p[0] * sin p 1) }

// @fileOverview Return the yaxis frame for polar coordinates
// @returns {dict} frame component
.z.m.gg.coords.i.polar.frame.yaxis:{[forceSize; components; th; coords; node; canvasNode]
    item: spec.node.item canvasNode;
    
    size : $[not null forceSize; forceSize; th`axis_size_y];
    
    : $[not spec.frame.useAxis[th; coords; `y];
        ::;
        spec.component
                [(item[`origin;0] - size + th`axis_offset; item[`origin;1]);
                size;
                item[`h] % 2;
                    ::]];
    
    }

// @fileOverview Convert a 0-1 point from rect to polar
// @returns {number[]} converted point
.z.m.gg.coords.i.polar.inverse:{[p]
    quad   : coords.i.polar.quad p;
    offset : (0; acos -1; acos -1; 2 * acos -1) quad;
    : (sqrt sum xexp[;2] each p; offset + atan p[1] % p 0)
    }

.z.m.gg.coords.i.polar.line:{[n;x]
    s: (!) . flip (
        (`xs;           flip x`x1`x2);
        (`ys;           flip x`y1`y2);
        (`colour;       0i);
        (`strokecolour; x`colour);
        (`strokewidth;  x`size);
        (`close;        0b);
        (`samples;      n);
        (`source; `line));
    : etable.el[etable.g.POLARPATH] s;
    }

.z.m.gg.coords.i.polar.path:{[n;x]
    : etable.el[etable.g.POLARPATH] @[x;`samples`source;:;(n;`path)];
    }

.z.m.gg.coords.i.polar.point:{[shape;n;x]
    x[`y]: proj.proj[0 1; (0;2*acos -1); x`y];
    x[`x`y]: proj.proj[-1 1; 0 1] flip coords.i.polar.apply @' flip x`x`y;
    : etable.el[shape] x;
    }

// @fileOverview Determine which quadrant a point lies within
// @returns {long} 0-based quadrant
.z.m.gg.coords.i.polar.quad:{[p]
    : $[all 0 <= p;              0;
        (0 > p 0) and 0 <= p 1;  1;
        (0 > p 0) and 0 > p 1;   2;
                                 3];
    
    }

.z.m.gg.coords.i.polar.rect:{[n;x]
    s: (!) . flip (
        (`xs;           flip (0;x`w;x`w;0)         + x`x`x`x`x);
        (`ys;           flip (0;0;neg x`h;neg x`h) + x`y`y`y`y);
        (`colour;       x`colour);
        (`close;        0b);
        (`samples;      n);
        (`source;       `rect));
    if[`strokecolour in cols x; s[`strokecolour]: x`strokecolour];
    if[`strokewidth in cols x;  s[`strokewidth] : x`strokewidth];
    : etable.el[etable.g.POLARPATH] s;
    }
.z.m.gg.coords.i.polar.rect4:{[n;x]
    s: (!) . flip (
        (`xs;           flip x`x1`x2`x2`x1);
        (`ys;           flip x`y1`y1`y2`y2);
        (`colour;       x`colour);
        (`close;        0b);
        (`samples;      n);
        (`source; `rect4));
    if[`strokecolour in cols x; s[`strokecolour]: x`strokecolour];
    if[`strokewidth in cols x;  s[`strokewidth] : x`strokewidth];
    : etable.el[etable.g.POLARPATH] s;
    }

// @fileOverview Y axis etable for polar coordinates
// @returns {table} etable
.z.m.gg.coords.i.polar.yaxis:{[th; coords; title; scale; guide]

    subset : select from guide where geometry = .z.m.gg.i.rules.g.TICKLABEL;
    s: subset`settings;
    s: @[;`y;:;1f] each s;
    guide: update settings: s from guide where geometry = .z.m.gg.i.rules.g.TICKLABEL;
    
    guide : delete from guide where geometry = .z.m.gg.i.rules.g.DOMLINE;
    guide : delete from guide where geometry = .z.m.gg.i.rules.g.TICK;
    
    guide : i.rules.i.styleTickLabels[th`axis_tick_label_angle_y; i.rules.i.textFromAnchor th`axis_tick_label_anchor_y; guide];
    guide : etable.replace[etable.g.ATEXTR; etable.g.ATEXTM;  guide];

    subset : first select from guide where geometry = .z.m.gg.i.rules.g.LABEL;
    s:subset`settings;
    s[`y]: 1.1;
    s[`x]: 0.75;
    guide: update settings:enlist s from guide where geometry = .z.m.gg.i.rules.g.LABEL;
    guide : etable.replace[i.rules.g.LABEL; etable.g.ATEXTM; guide];
    
    guide : i.transforms.reflect guide;
    : guide
    }

// @fileOverview Return the xaxis frame for rect coordinates
// @returns {dict} frame component
.z.m.gg.coords.i.rect.frame.xaxis:{[components; th; coords; node; canvasNode]
    item : spec.node.item canvasNode;
    
    : $[not spec.frame.useAxis[th; coords; `x];
        ::;
        spec.component
                [(item[`origin] 0; th[`axis_offset]+item[`h]+item[`origin;1]);
                 item`w;
                 th`axis_size_x;
                    ::]];
    
    }

// @fileOverview Return the yaxis frame for rect coordinates
// @returns {dict} frame component
.z.m.gg.coords.i.rect.frame.yaxis:{[forceSize; components; th; coords; node; canvasNode]
    item: spec.node.item canvasNode;
    
    size : $[not null forceSize; forceSize; th`axis_size_y];
    
    : $[not spec.frame.useAxis[th; coords; `y];
        ::;
        spec.component
                [(item[`origin;0] - size + th`axis_offset; item[`origin;1]);
                size;
                item`h;
                    ::]];
    
    }
 
// @fileOverview Return the yaxis frame for rect coordinates
// @returns {dict} frame component
.z.m.gg.coords.i.rect.frame.yaxis2:{[components; th; coords; node; canvasNode]
    item: spec.node.item canvasNode;

    : $[not spec.frame.useAxis[th; coords; `y];
        ::;
        spec.component
                [(item[`origin;0] + item[`w] + th`axis_offset; item[`origin;1]);
                th`axis_size_y;
                item`h;
                    ::]];
    
    }

// @fileOverview Y axis etable for rect coordinates
// @returns {table} yaxis etable
.z.m.gg.coords.i.rect.i.yaxis:{[transformF; th; coords; title; scale; guide]
    guide : etable.replace[i.rules.g.DOMLINE;   etable.g.LINE;    guide];
    guide : etable.replace[i.rules.g.TICK;      etable.g.LINE;    guide];
    guide : i.rules.i.styleTickLabels[th`axis_tick_label_angle_y; i.rules.i.textFromAnchor th`axis_tick_label_anchor_y; guide];
    guide : etable.replace[i.rules.g.TICKLABEL; etable.g.ATEXTR;  guide];

    label : first select from guide where geometry = .z.m.gg.i.rules.g.LABEL;
    s     : label`settings;
    s[`angle]: -90;
    guide : update settings:enlist s from guide where geometry = .z.m.gg.i.rules.g.LABEL;
    
    : transformF etable.replace[i.rules.g.LABEL; etable.g.ATEXTM; guide];
    }

// @fileOverview X axis etable for rect coordinates
// @returns {table} xaxis etable
.z.m.gg.coords.i.rect.xaxis:{[th; co; title; sc; guide]
    guide : etable.replace[i.rules.g.DOMLINE;   etable.g.LINE;    guide];
    guide : etable.replace[i.rules.g.TICK;      etable.g.LINE;    guide];
    guide : i.rules.i.styleTickLabels[th`axis_tick_label_angle_x; i.rules.i.textFromAnchor th`axis_tick_label_anchor_x; guide];
    guide : etable.replace[i.rules.g.TICKLABEL; etable.g.ATEXTM;  guide];
    guide : etable.replace[i.rules.g.LABEL;     etable.g.ATEXTM;  guide];
    : guide;
    }

// @fileOverview Y axis etable for rect coordinates
// @returns {table} yaxis etable
.z.m.gg.coords.i.rect.yaxis:{[th; coords; title; sc; guide]
    : coords.i.rect.i.yaxis[i.transforms.reflect; th; coords; title; sc; guide];
    }

// @fileOverview Y axis etable for rect coordinates
// @returns {table} yaxis etable
.z.m.gg.coords.i.rect.yaxis2:{[th; coords; title; sc; guide]
    : coords.i.rect.i.yaxis[i.transforms.flipy i.transforms.reflect@; th; coords; title; sc; guide];
    }

// @subcategory Coordinate Systems
// @private
// @fileOverview 
// Create a new coordinate system
//
// - label - symbol identifying the coordinate system
// - applyF - function from a point `(num;num)` to a point
// - inverseF - function from a point to a point
// - dims - dimensions used `` `x`y ``
// - xaxisFrame - canvas for the x axis frame
// - xaxisFrameF - function to construct the X axis frame
// - xaxisTransformF - Transform function for the X axis guide
// - yaxisFrame
// - yaxisFrameF
// - yaxisTransformF
// - shapes etable transform functions for each etable shape
// @param x {any[]} coordinate system params
//
// @returns {dict} new coordinate system
.z.m.gg.coords.new:{[x]
    `label`applyF`inverseF`dims`xaxisFrame`xaxisFrameF`xaxisTransformF`yaxisFrame`yaxisFrame2`yaxisFrameF`yaxis2FrameF`yaxisTransformF`yaxis2TransformF`gridF`backgroundF`shapes!x
    }

// @subcategory Coordinate Systems
// @private
// @fileOverview Transform a shape table to a new coordinate system
// @returns {table} updated shapetable
.z.m.gg.coords.transform:{[co; etab]
    if [0=count etab; : etab];
    : etable.EMPTY ,/ {[co;etab;s]
        if[any (::) ~/: (s;co[`shapes;s]); :etable.EMPTY];
        t: etable.settings etable.every[s] etab;
        : $[all 98h = type each t;co[`shapes;s] raze t;raze co[`shapes;s] each t];
        }[co;etab] each value etable.g;
    }




.z.m.gg.coords.i.INTERP:100
.z.m.gg.coords.rect:coords.new (
    `rect;
    ::;
    ::;
    `x`y;
    `xaxis;
    coords.i.rect.frame.xaxis;
    coords.i.rect.xaxis;
    `yaxis;
    `yaxis2;
    coords.i.rect.frame.yaxis;
    coords.i.rect.frame.yaxis2;
    coords.i.rect.yaxis;
    coords.i.rect.yaxis2;
    i.rules.grid;
    i.rules.background;
    (!) . flip (
        (etable.g.PATH;      etable.el etable.g.PATH      );
        (etable.g.ATEXTM;    etable.el etable.g.ATEXTM    );
        (etable.g.ATEXTR;    etable.el etable.g.ATEXTR    );
        (etable.g.ATEXTL;    etable.el etable.g.ATEXTL    );
        (etable.g.LINE;      etable.el etable.g.LINE      );
        (etable.g.RECT4;     etable.el etable.g.RECT4     );
        (etable.g.RECT;      etable.el etable.g.RECT      );
        (etable.g.POINT;     etable.el etable.g.POINT     );
        (etable.g.TRIANGLE;  etable.el etable.g.TRIANGLE  );
        (etable.g.SQUARE;    etable.el etable.g.SQUARE    )
        )
    )
// @subcategory Coordinate Systems
.z.m.gg.coords.polarn:{[n]

    coords.new (
        `polarn;
        {x};
        {(::; proj.proj[(0;2*acos -1); 0 1]) @' coords.i.polar.inverse proj.proj[0 1; -1 1] x};
        `x`y;
        `yaxis;
        coords.i.polar.frame.yaxis 0n;
        coords.i.rect.yaxis;
        `geom;
        `; // unsupported
        coords.i.polar.frame.yaxis;
        {[components; theme; coords; node; canvasNode]'.z.m.axlocalize.t`.gg_coordsPolarErrorYSplit};
        coords.i.polar.yaxis;
        {[theme; coords; title; scale; guide]'.z.m.axlocalize.t`.gg_coordsPolarErrorYSplit};
        i.rules.grid;
        i.rules.background;
        (!) . flip (
            (etable.g.ATEXTM; {[n;x]
                    if [0 = count x; : x];
                    : etable.replace[etable.g.POINT;etable.g.ATEXTM] coords.i.polar.point[etable.g.ATEXTM; n] ::'[x]
                    } n);
            (etable.g.ATEXTR; {[n;x]
                    if [0 = count x; : x];
                    : etable.replace[etable.g.POINT;etable.g.ATEXTR] coords.i.polar.point[etable.g.ATEXTR; n] ::'[x]
                    } n);
            (etable.g.ATEXTL; {[n;x]
                    if [0 = count x; : x];
                    : etable.replace[etable.g.POINT;etable.g.ATEXTL] coords.i.polar.point[etable.g.ATEXTL; n] ::'[x]
                    } n);
            (etable.g.PATH;   {[n;x]
                    if [0 = count x; : x];
                    : coords.i.polar.path[n] ::'[x];
                    } n);
            (etable.g.LINE;  {[n;x]
                    if [0 = count x; : x];
                    : coords.i.polar.line[n] ::'[x];
                    } n);
            (etable.g.RECT4; {[n;x]
                    if [0 = count x; : x];
                    : coords.i.polar.rect4[n] ::'[x];
                    } n);
            (etable.g.RECT; {[n;x]
                    if [0 = count x; : x];
                    : coords.i.polar.rect[n] ::'[x];
                    } n);
            (etable.g.POINT; {[n;x]
                    if [0 = count x; : x];
                    : coords.i.polar.point[etable.g.POINT; n] ::'[x];
                    } n);
            (etable.g.TRIANGLE; {[n;x]
                    if [0 = count x; : x];
                    : coords.i.polar.point[etable.g.TRIANGLE; n] ::'[x];
                    } n);
            (etable.g.SQUARE; {[n;x]
                    if [0 = count x; : x];
                    : coords.i.polar.point[etable.g.SQUARE; n] ::'[x];
                    } n)
            )
        )
    }
.z.m.gg.coords.polar:coords.new (
    `polar;
    {x};
    {(::; proj.proj[(0;2*acos -1); 0 1]) @' coords.i.polar.inverse proj.proj[0 1; -1 1] x};
    `x`y;
    `yaxis;
    coords.i.polar.frame.yaxis 0n;
    coords.i.rect.yaxis;
    `geom;
    `; // unsupported
    coords.i.polar.frame.yaxis;
    {[components; theme; coords; node; canvasNode]'.z.m.axlocalize.t`.gg_coordsPolarErrorYSplit};
    coords.i.polar.yaxis;
    {[theme; coords; title; scale; guide]'.z.m.axlocalize.t`.gg_coordsPolarErrorYSplit};
    i.rules.grid;
    i.rules.background;
    (!) . flip (
        (etable.g.ATEXTM; {[x]
                if [0 = count x; : x];
                : etable.replace[etable.g.POINT;etable.g.ATEXTM] coords.i.polar.point[etable.g.ATEXTM; coords.i.INTERP] ::'[x]
                });
        (etable.g.ATEXTR; {[x]
                if [0 = count x; : x];
                : etable.replace[etable.g.POINT;etable.g.ATEXTR] coords.i.polar.point[etable.g.ATEXTR; coords.i.INTERP] ::'[x]
                });
        (etable.g.ATEXTL; {[x]
                if [0 = count x; : x];
                : etable.replace[etable.g.POINT;etable.g.ATEXTL] coords.i.polar.point[etable.g.ATEXTL; coords.i.INTERP] ::'[x]
                });
        (etable.g.PATH;   {[x]
                if [0 = count x; : x];
                : coords.i.polar.path[coords.i.INTERP] ::'[enlist @/:/: x];
                });
        (etable.g.LINE;  {[x]
                if [0 = count x; : x];
                : coords.i.polar.line[coords.i.INTERP] ::'[x];
                });
        (etable.g.RECT4; {[x]
                if [0 = count x; : x];
                : coords.i.polar.rect4[coords.i.INTERP] ::'[x];
                });
        (etable.g.RECT; {[x]
                if [0 = count x; : x];
                : coords.i.polar.rect[coords.i.INTERP] ::'[x];
                });
        (etable.g.POINT; {[x]
                if [0 = count x; : x];
                : coords.i.polar.point[etable.g.POINT; coords.i.INTERP] ::'[x];
                });
        (etable.g.TRIANGLE; {[x]
                if [0 = count x; : x];
                : coords.i.polar.point[etable.g.TRIANGLE; coords.i.INTERP] ::'[x];
                });
        (etable.g.SQUARE; {[x]
                if [0 = count x; : x];
                : coords.i.polar.point[etable.g.SQUARE; coords.i.INTERP] ::'[x];
                })
        )
    )
.z.m.gg.coords.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip
        enlist
        (`.gg_coordsPolarErrorYSplit;"polar coordinates do not support dual Y axes (splits)")
            )
// @subcategory Coordinate Systems
// @fileOverview
// 3D coordinate system
//
// 3D points are plotted via orthographic projection onto a 2D plane, which is tangential 
// to a point on the unit sphere defined by 2 angles, the azimuth, and the altitude.
//
// The azimuth is the angle between the point and the X axis along the X-Y plane.
// The altitude is the angle between the point and the X-Y plane.
// For more about azimuth/altitude, see: https://en.wikipedia.org/wiki/Azimuth
//
// @param azimuth {float}
// @param altitude {float}
// @see qp.s.coord
.z.m.gg.coords.cube:{[azimuth;altitude]
    basis: coords.i.cube.i.anglesToBasis[azimuth;altitude];
    :(coords.new (
        `cube;
        {[b1;b2;x]
            : coords.i.cube.normalize[b1;b2] proj.planeProjection[b1;b2] x;
            } . basis;
        ::;
        `x`y`z;
        `geom;
        {[components; theme; coords; node; canvasNode]}; // x-axis is drawn on `geom
        coords.i.cube.xaxis . basis;
        `geom;
        `geom;
        {[forceSize; components; theme; coords; node; canvasNode]}; // y-axis is drawn on `geom
        {[forceSize; components; theme; coords; node; canvasNode]}; // y-axis 2 is never used
        coords.i.cube.yaxis . basis;
        {[theme; coords; title; scale; guide] '"Can't use y-axis 2 in 3D"}; // y-axis 2 is never used
        i.rules.grid3D . basis;
        i.rules.background3D . basis;
        (!) . flip (

            (etable.g.POINT3D;  etable.el etable.g.POINT3D);
            (etable.g.LINE3D;   etable.el etable.g.LINE3D);
            (etable.g.ATEXTL3D; etable.el etable.g.ATEXTL3D);
            (etable.g.ATEXTM3D; etable.el etable.g.ATEXTM3D);
            (etable.g.ATEXTR3D; etable.el etable.g.ATEXTR3D);
            (etable.g.PATH3D;   etable.el etable.g.PATH3D);
            (etable.g.PATH;     {[x]
                    if[0=count x; :x];
                    '"Cannot transform PATH from cube coords"
                    });
            (etable.g.ATEXTM;   {[x]
                    if[0=count x; :x];
                    '"Cannot transform ATEXTM from cube coords"
                    });
            (etable.g.ATEXTR;   {[x]
                    if[0=count x; :x];
                    '"Cannot transform ATEXTR from cube coords"
                    });
            (etable.g.ATEXTL;   {[x]
                    if[0=count x; :x];
                    '"Cannot transform ATEXTL from cube coords"
                    });
            (etable.g.LINE;     {[x]
                    if[0=count x; :x];
                    '"Cannot transform LINE from cube coords"
                    });
            (etable.g.RECT4;    {[x]
                    if[0=count x; :x];
                    '"Cannot transform RECT4 from cube coords"
                    });
            (etable.g.RECT;     {[x]
                    if[0=count x; :x];
                    '"Cannot transform RECT from cube coords"
                    });
            (etable.g.POINT;    {[x]
                    if[0=count x; :x];
                    '"Cannot transform POINT from cube coords"
                    });
            (etable.g.TRIANGLE; {[x]
                    if[0=count x; :x];
                    '"Cannot transform TRIANGLE from cube coords"
                    });
            (etable.g.SQUARE;   {[x]
                    if[0=count x; :x];
                    '"Cannot transform SQUARE from cube coords"
                    })
            )
        )),
        (!) . flip (
            (`zaxisFrame;      `geom);
            (`zaxisTransformF; coords.i.cube.zaxis . basis);
            (`b1;              basis 0);
            (`b2;              basis 1)
        );
    }
system "d .z.m";

system "d .z.m.gg";
// @fileOverview 
// Apply a geometry draw function to appropriate arguments
// @param th {dict} theme
// @param g {dict} geometry 
// @param table {table} data being visualized 
// @param aes {dict}
// @param scales {dict}
//
// @returns {table} table of etable elements normalized to 0-1 positions
.z.m.gg.geom.apply:{[th; g; table; aes; scales]
    : (geom.ty.applyF g)[th; table; aes; scales]
    }

// @fileOverview 
// Area geometry - draws a line in horizontal order with a filled polygon
.z.m.gg.geom.area:{[settings]
    defaults : h.extend[settings] h.extend[`orientation`size`minSize`maxSize`decorations`areaAlpha!(`v; 1; 1; 15; 1b; 0x80)] geom.i.DEFAULTS;
    : geom.ty.new (
        `area;
        
        {[d;lyr]
            a : h.extend[lyr`aes; d];
            t : lyr`transformed;
            geom.i.validateAll["area"; lyr; a; `size`fill`alpha];
            if [geom.i.useStack[a; t];
                .[geom.i.validateStack; (t; a`y); {'geom.i.errPre[("area";"stack")],x}]]; /dnl
            } defaults;
        
        {[d; lyr]
            a : h.extend[lyr`aes; d];
            : geom.i.setStackLimits[`x; `y; lyr`transformed; a; lyr`scales];
            } defaults;
        
        {[d; th; t; a; s] // -> ETable    
            a : geom.i.defAes[th] h.extend[a; d];
            k : distinct asc geom.i.pos2D[s; t; a`x; a`y; ::]`x;
            : geom.i.group[k!count[k]#0f; t; a; {[acc; c; n; t; a; s; idxs]
                    ps: geom.i.pos2D[s; t; a`x; a`y; idxs];
                    if [0 = count ps`x; // Bail out if there are no points to process
                        : (etable.EMPTY; acc)];
                    
                    adj   : geom.i.posAdjust [`stack`stream; ps; c; n; t; a; s];
                    offset: 0;
                    
                    $[adj[`type] in `stack`stream;
                        [   ys : bs: acc;
                            l  : ps[`x]?key ys;
                            ii : l = count ps`x;
                            offset   : $[`stream ~ adj`type; value s[`y;`stack_offset]; 0];
                            ys[ps`x] : adj`pos;
                            gs: h.dictAsc[`x] `x`y`bs`idx!(key ys; offset + value ys; offset + value bs; @[l;where ii;:;0N])];
                        [   bs: type[ps`y]$(count ps`y)#0;
                            gs: h.dictAsc[`x] `x`y`bs`idx!(ps`x; ps`y; bs; ps`idx)]];
                    
                    o     : geom.i.options [t; a; s; ps`idx; `fill`alpha`stroke];
                    c     : .z.m.axbits.or[first o`alpha; o`fill];
                    xs    : gs[`x] , reverse gs`x;
                    ys    : gs[`y] , reverse gs`bs;
                    lines : `close`xs`ys`colour!(1b; xs; ys; .z.m.axbits.or[0x0 sv ("x"$a`areaAlpha),0x000000; first o`fill]);
                    points: update size: 2, colour: c from (gs @\: where not null gs`idx);
                    
                    if [not h.null o`stroke; lines : h.extend[lines] first each o`stroke];
                    
                    geoms: etable.el[etable.g.PATH] lines;
                    if [a`decorations;
                        outlines: geom.i.linetable[t; gs; a; s];
                        if [not outlines ~ ()!(); 
                            lineGeoms: etable.el[etable.g.LINE] update colour: .z.m.axbits.or[0x0 sv 0xff000000;first o`fill] from outlines;
                            geoms   ,: etable.el[etable.g.POINT][points] , lineGeoms]];
                    
                    : (geoms;
                        @[acc;gs`x;:;gs[`y]-$[adj[`type] in `stack`stream; offset; 0]]);
                    
                    }[; ; ; ; a; s]];
            } defaults;
        
        {[d; pt; t; lyr]
            a : h.extend[lyr`aes; d];
            : geom.i.nearest1D[`x; d; pt; t; a; lyr`scales];
            } defaults;
        
        enlist `x;
        
        enlist `y;
        
        {[pt1; pt2; t; a; s; lyr] geom.fromBound1D[`x; `x; pt1; pt2; t; a; s; lyr] }
        );
    }

// @fileOverview 
// Return the domain aes columns for the given dimension of the geometry
// @param geom {dict} geometry 
// @param xOrY {symbol} `x or `y dimension
// @returns {symbol[]} domain aes
.z.m.gg.geom.domain:{[geom; xOrY]
    : $[`x ~ xOrY; geom.ty.xdomain geom;
        `y ~ xOrY; geom.ty.ydomain geom;
                   '.z.m.axlocalize.t`.gg_domainDimError];
    }

// @fileOverview 
// Perform any necessary extensions to the domain outlined
// by a set of scales. Some geometries require expanding 
// the domain to make room for the geometry itself. For 
// example, a bar geometry expands the horizontal domain on
// both sides in order to make room for the bar itself.
//
// @param g {dict} geometry 
// @param lyr {dict} layer
//
// @returns {dict} extended scales
.z.m.gg.geom.extend:{[g; lyr]
    : (geom.ty.extendF g) lyr
    }

// @fileOverview 
// Return a list of indices of records in a table within two given points
// @param xOrY {symbol} `x or `y (the direction of the range) 
// @param flag {symbol} key of `a`
// @param pt1 {(number;number)} 0-1 normalized point 
// @param pt2 {(number;number)} 0-1 normalized point 
// @param t {table} 
// @param a {dict} aesthetic mappings 
// @param s {dict} scales
// @param lyr {dict} layer
// @returns {long[]} list of indices
.z.m.gg.geom.fromBound1D:{[xOrY; flag; pt1; pt2; t; a; s; lyr]
    : $[tbl.transform[t] & not a[flag] in layer.colmap lyr;
        til count tbl.indices t;
        [
            pre: layer.coltransform[lyr][a flag] tbl.column[t;a flag];
            v  : proj.proj[s[xOrY]`geom_limits; 0 1] scale.apply[s xOrY] pre;
            pt : asc (pt1; pt2) @\: $[`x ~ xOrY; 0; 1];
            .z.m.table.indices[([]x:v); (((';~:;<); `x; pt 0); ((';~:;>); `x; pt 1))]]];
    }

// @fileOverview 
// Return a list of indices of records in a table within a two-dimension bound
// defined by two 0-1 normalized points
// @param pt1 {(number;number)} 0-1 normalized point 
// @param pt2 {(number;number)} 0-1 normalized point 
// @param t {table} 
// @param a {dict} aesthetic mappings 
// @param s {dict} scales
// @returns {long[]} list of indices
.z.m.gg.geom.fromBound2D:{[pt1; pt2; t; a; s; lyr]
    : geom.fromBound1D[`x; `x; pt1; pt2; t; a; s; lyr] inter
      geom.fromBound1D[`y; `y; pt1; pt2; t; a; s; lyr];
    }

// @fileOverview 
// Horizontal bar geometry
.z.m.gg.geom.hbar:{[settings]
    defaults : h.extend[settings] h.extend[`orientation`align`gap`sortByValue!(`h; `middle; 0.01; 0b)] geom.i.DEFAULTS _ `size;
    : geom.ty.new (
        `hbar;
        {[d;lyr]
            a : h.extend[lyr`aes; d];
            t : lyr`transformed;
            geom.i.validateAll["hbar"; lyr; a; `fill`alpha`colour];
            if [`size in key a;
                .[geom.i.validateConst; (`size; a`size; "hijef"); {'geom.i.errPre[("hbar";"size")],x}]];   /dnl
            if [not h.null a`position;
                if [not (lyr . `scales`y`label) in `linear`default`categorical`temporal; 
                    '"Only able to use `position adjust` with categorical, temporal, or linear (default) scales"]];
            if [geom.i.useStack[a; t];
                if [not (lyr . `scales`x`label) in `linear`default; '"Only able to use `stack position` with linear (default) scales"];
                .[geom.i.validateStack; (t; a`x);                 {'geom.i.errPre[("hbar";"stack")],x}]];   /dnl 
            } defaults;
        {[d; lyr]
            s: lyr`scales;
            a: geom.i.defSize[s`y] h.extend[lyr`aes; d];
            voffset : geom.i.valign [a`align; a`size];
            s       : geom.i.setStackLimits[`y;`x;lyr`transformed;a;s];
            s[`y;`geom_limits]: (s[`y;`limits][0] - a[`size] - voffset; s[`y;`limits][1] + voffset);
            : geom.i.sortBars[a;lyr;s;`y;`x];
            } defaults;
        {[d; th; t; a; s]
            a: geom.i.defAes[th] geom.i.defSize[s`y] h.extend[a; d];
            : geom.i.group[::; t; a; {[acc; c; n; t; a; s; idxs]
                    ps     : geom.i.pos2D[s; t; a`x; a`y; idxs];
                    hs     : ps`x;
                    o      : geom.i.options [t; a; s; ps`idx; `fill`alpha`stroke];
                    adj    : geom.i.posAdjust [`id`dodge`stack; ps; c; n; t; a; s];
                    width  : a[`size] % (-). reverse s[`y]`geom_limits;
                    ps[`x] : count[hs]#0;
                    
                    if [width < 2*a`gap;  a[`gap]: 0];
                    width  -: a`gap;
                    offset  : 0;
                    voffset : geom.i.valign [a`align; a`size] % (-). reverse s[`y]`geom_limits;
                    
                    if [`stack ~ adj`type;
                        hs     : adj`size;
                        ps[`x] : adj[`pos] - hs];
                    
                    if [`dodge ~ adj`type;
                        width  : adj`h;
                        offset : adj`dy];

                    points : (!) . flip (
                        (`y     ; voffset + ps[`y] - offset + a[`gap] % 2);
                        (`x     ; ps`x);
                        (`h     ; count[hs]#width);
                        (`w     ; hs);
                        (`colour; .z.m.axbits.or[o`alpha; o`fill]));
                    
                    if[any 0 = count each points`x`y`h`w; : ()!()];
                    if [not h.null o`stroke; points,: o`stroke];
                    : ( etable.el[etable.g.RECT] h.dictDesc[`x] points;
                        acc)
                    }[; ; ; ; a; s]];
            } defaults;
        {[d; pt; t; lyr]
            s: lyr`scales;
            a: geom.i.defSize[s`y] h.extend[lyr`aes; d];
            height: $[`bottom ~ a`align; ::; `top ~ a`align; neg; {0}] 
                %[;2] a[`size] % (-). reverse s[`y]`geom_limits;
            pt[1] -: height;
            r: $[geom.i.useStack[a; t];
                geom.i.stackRollover[`y;`x;d;pt;t;s;a];
                geom.i.nearest1D[`y;d;pt;t;a;s]];
            r[`pt;1] +: height;
            : r;
            } defaults;
        enlist `x;
        enlist `y;
        {[d; pt1; pt2; t; a; s; lyr]
            geom.fromBound1D[`y; `y; pt1; pt2; t; geom.i.defSize[s`y] h.extend[a; d]; s; lyr]
            } defaults
        );
    }

// @fileOverview 
// Horizontal error bar geometry
.z.m.gg.geom.herrorbar:{[settings]
    
    defaults : h.extend[settings] h.extend[`align`gap`strokewidth!(`middle; 0.01; 1)] geom.i.DEFAULTS _ `size;
    
    : geom.ty.new (
    
        `herrorbar;
        
        {[d;lyr]
            a : h.extend[lyr`aes; d];
            geom.i.validateAll["herrorbar"; lyr; a; `fill`alpha];
            if [`size in key a;
                .[geom.i.validateConst; (`size; a`size; "hijef"); {'geom.i.errPre[("herrorbar";"size")],x}]];  /dnl
            } defaults;

        {[d; lyr]
            s       : lyr`scales;
            a       : geom.i.defSize[s`y] h.extend[lyr`aes; d];
            voffset : geom.i.valign [a`align; a`size];
            s[`y;`geom_limits]: (s[`y;`limits][0] - a[`size] - voffset; s[`y;`limits][1] + voffset);
            : s;
            } defaults;
        
        geom.i.errorbar[`align`px`py`x`y`xend`yend`w`dx`final!geom.i.halign,`y`x`x`y`xend`y`h`dy,enlist`y1`x1`y2`x2; defaults];

        {[d; pt; t; lyr]
            a : h.extend[lyr`aes; d];
            : `data`distance`pt#geom.i.nearestLine[pt; lyr`scales; t; a`x; a`y; a`xend; a`y];
            } defaults;

        `x`xend;
        
        1#`y;
        
        {[d; pt1; pt2; t; a; s; lyr]
            geom.fromBound1D[`y; `y; pt1; pt2; t; geom.i.defSize[s`y] h.extend[a; d]; s; lyr]
            } defaults

        );

    }

// @fileOverview 
// horizontal interval geometry
.z.m.gg.geom.hinterval:{[settings]
    defaults : h.extend[settings] h.extend[`align`gap`strokewidth`collapse`fillByValue!(`middle; 0.01; 1; 0b; 0b)] geom.i.DEFAULTS _ `size;
    : geom.ty.new (
        `hinterval;
        {[d;lyr]
            a : h.extend[lyr`aes; d];
            geom.i.validateAll["hinterval"; lyr; a; `colour`fill`alpha];
            if [`size in key a;
                .[geom.i.validateConst; (`size; a`size; "hijef"); {'geom.i.errPre[("hinterval";"size")]  ,x}]];  /dnl
            } defaults;
        {[d; lyr]
            a: lyr`aes;
            s: lyr`scales;
            a: geom.i.defSize[s`y] h.extend[a; d];
            voffset: geom.i.valign [a`align; a`size];
            s[`y;`geom_limits]: (s[`y;`limits][0] - a[`size] - voffset; s[`y;`limits][1] + voffset);
            if [geom.i.useFillByValue[s;a]; s[`fill]: geom.i.order[lyr`transformed; s`fill; a; `x]];
            : s;
            } defaults;
        {[d; th; t; a; s]
            a: geom.i.defAes[th] geom.i.defSize[s`y] h.extend[a; d];
            : geom.i.group[::; t; a; {[acc; c; n; t; a; s; idxs]
                    p1s     : geom.i.pos2D[s; t; a`x;    a`y; idxs];
                    p2s     : geom.i.pos2D[s; t; a`xend; a`y; idxs];
                    idx     : geom.i.resolveIdx[p1s; p2s];
                    o       : geom.i.options [t; a; s; idx; `fill`alpha`stroke];
                    xs      : geom.i.pidx[p1s; `x; idx];
                    xends   : geom.i.pidx[p2s; `x; idx];
                    ys      : geom.i.pidx[p1s; `y; idx];
                    ms      : xs &' xends;
                    Ms      : xs |' xends;
                    widths  : Ms -' ms;
                    adj     : geom.i.posAdjust [`id`dodge; `x`y!(Ms;ys); c; n; t; a; s];
                    height  : a[`size] % (-). reverse s[`y]`geom_limits;
                    voffset : geom.i.valign [a`align; a`size] % (-). reverse s[`y]`geom_limits;
                    if [height <= a`gap;  a[`gap]: 0];
                    cOffset : 0;
                    height  : adj`h;
                    if [a`collapse;
                        cOffset : adj[`h] % 2;
                        height  : 0.005];
                    points: `x`y`h`w`colour!(ms;voffset + (ys - adj[`dy] + a[`gap] % 2) - cOffset; count[widths]#height; widths; .z.m.axbits.or[o`alpha; o`fill]);
                    if[any 0 = count each points`x`y`h`w; : ()!()];
                    if [not h.null o`stroke; points,: o`stroke];
                    : (etable.el[etable.g.RECT] points;
                        acc);
                    }[; ; ; ; a; s]];
            } defaults;
        {[d; pt; t; lyr]
            a : h.extend[lyr`aes; d];
            : `data`distance`pt#geom.i.nearestLine[pt; lyr`scales; t; a`x; a`y; a`xend; a`y];
            } defaults;
        `x`xend;
        1#`y;
        {[pt1; pt2; t; a; s; lyr] geom.fromBound1D[`y; `y; pt1; pt2; t; a; s; lyr] }
        );
    }

// @fileOverview 
// Horizontal line geometry
.z.m.gg.geom.hline:{[settings]
    defaults : h.extend[settings] h.extend[`size`minSize`maxSize!1 1 15] geom.i.DEFAULTS;
    
    : geom.ty.new (
    
        `hline;
        
        {[d;lyr]
            geom.i.validateAll["hline"; lyr; h.extend[lyr`aes; d]; `size`fill`alpha];
            } defaults;

        {[lyr]lyr`scales};

        {[d; th; t; a; s]
            if [not `x in key s; '.z.m.axlocalize.t`.gg_hlineStackError];
            a      : geom.i.defAes[th]  h.extend[a; d];
            pys    : geom.i.pos1D [s`y; t; a`y; ::];
            if [0 = count pys`idx; : ()];
            pxs    : geom.i.pos1D [s`x; ([]x:.z.m.gg.scale.inverse[s`x] s[`x;`limits]); `x; ::];
            if [0 = count pxs`idx; : ()];
            gs     : `x xasc ([]x: pxs`ps; y:first pys`ps; idx:til count pxs`ps);
            : etable.el[etable.g.LINE] geom.i.linetable[t; gs; a; s]
            } defaults;

        {[d; pt; t; lyr]
            : `geom`data`distance`pt!(`hline;();0w;pt)
            } defaults;

        enlist `x;
        enlist `y;
        
        {[pt1; pt2; t; a; s; lyr]
            : geom.fromBound1D[`y; `y; pt1; pt2; t; a; s; lyr];
            }
        );
    }
.z.m.gg.geom.i.aes.bool:{[f; t; a; s; idx]
    : geom.i.param[t; a; f; s; idx; enlist -1h]  {[f; t; a; s; idx]
        : "b"$0^tbl.column[t; a f] idx;
        }f;
    }
// @fileOverview 
// Return the given field for each geometry
// @param f {symbol} field to extract (`angle, etc)
// @param t {table} data 
// @param a {dict} aes 
// @param s {dict} scales 
// @param idx {long[]} indices of valid rows
//
// @returns {byte[][]} field for each valid geometry
.z.m.gg.geom.i.aes.number:{[f; t; a; s; idx]
    : geom.i.param[t; a; f; s; idx; -5 -6 -7 -8 -9h]  {[f; t; a; s; idx]
        : "f"$tbl.column[t; a f] idx;
        }f;
    }

// @fileOverview 
// Return the alignment offset for 3-valued alignments (i.e., left, middle, right)
// @param options {symbol[]} 3 values as symbols (e.g., `left`right`middle)
// @param align {symbol} alignment (one of 3 given) 
// @param size {number} size of the geometry
// @returns {number}
.z.m.gg.geom.i.align:{[options; align; size]
    : $[options[0] ~ align; size; options[1] ~ align; 0; size % 2];
    }

// @fileOverview 
// Returns a list of alpha values to use for each geometry
// @param t {table} data 
// @param a {dict} aes 
// @param s {dict} scales 
// @param idx {long[]} indices of valid rows
//
// @returns {byte[]} alpha for each valid row
.z.m.gg.geom.i.alpha:{[t; a; s; idx]

    if [neg[type a`alpha] in 1 4 5 6 7 8 9h;
        a[`alpha]: colour.setAlpha[a`alpha; 0i]];

    : geom.i.param[t; a; `alpha; s; idx; enlist -6h; {[t; a; s; idx]
            column : tbl.column[t; a`alpha] idx;
            : colour.setAlpha[;0i] proj.proj[(min;max)@\: column; "j"$a`minAlpha`maxAlpha] column;
            }];
    }
.z.m.gg.geom.i.defAes:{[th; a]
    : geom.i.defColour[th] geom.i.defFill[th] a
    }

// @fileOverview Stub with default alignment
// @returns {dictionary} Updated aesthetics
.z.m.gg.geom.i.defAlign:{[s; k; a]
    if [s[`label] ~ scale.categorical[]`label;
        a[k]: `middle];
    : a;
    }

.z.m.gg.geom.i.defColour:{[th; a]
    if [`colour in key a;
        a[`colour]: colour.fromBytes a`colour];
    : a;
    }

// @fileOverview 
// Install a default fill from the theme if there
// was no fill declared explicitly.
// @param th {dict} theme 
// @param a {dict} aes
// @returns {dict} updated aes
.z.m.gg.geom.i.defFill:{[th; a]
    if [not `fill in key a;
        a[`fill]: th`marker_default_fill];
    
    a[`fill]: colour.fromBytes a`fill;
    : a;
    }

.z.m.gg.geom.i.defHeight:{[s; a]
    if [s[`label] ~ scale.categorical[]`label;
        a[`height]: 1];
    : a;
    }

.z.m.gg.geom.i.defSize:{[s; a]
    
    if [s[`label] ~ scale.categorical[]`label;
        a[`size]: 1;
        : a];
    
    if [`size in key a;
        : a];
    
    a[`size]:
        $[not `i_orig in key s;
            1;
        s[`i_orig] in "efpnz"; /dnl
            [r : h.range s`limits;
             r % 1000];
            1];
    
    : a;
    
    }

.z.m.gg.geom.i.defWidth:{[s; a]
    if [s[`label] ~ scale.categorical[]`label;
        a[`width]: 1];
    : a;
    }

.z.m.gg.geom.i.errPre:{[args] : .z.m.axlocalize.t (`.gg_geomErrorPre; `geom`aes!args) }

// @fileOverview Paramaterized error bar geometry. Written in the style
// of a vertical error bar. A horizontal error bar just inverts the x/y
// axes
// @param cs {dict}
// @desc cs.align {fn} alignment function
// @desc cs.x {symbol} pseudo-x column 
// @desc cs.y {symbol} pseudo-y column 
// @desc cs.xend {symbol}  pseudo-y column 
// @desc cs.yend {symbol}  pseudo-y column 
// @desc cs.px {symbol}  primary x column 
// @desc cs.py {symbol}  primary y column 
// @desc cs.w {symbol} width (w) or height (h)
// @desc cs.dx {symbol} x offset (dx) or y offset (dy)
// @desc cs.final {symbol[]} final line table column ordering 
// @returns {table} Line elements making uperror bars
.z.m.gg.geom.i.errorbar:{[cs; d; th; t; a; s]
    a: geom.i.defAes[th] geom.i.defSize[s cs`px] h.extend[a; d];
    : geom.i.group[::; t; a; {[acc; c; n; t; cs; a; s; idxs]
            p1s     : geom.i.pos2D [s; t; a cs`x;    a cs`y; idxs];
            p2s     : geom.i.pos2D [s; t; a cs`xend; a cs`yend; idxs];
            idx     : geom.i.resolveIdx[p1s; p2s];
            o       : geom.i.options [t; a; s; idx; `fill`alpha`dashed];
            xs      : geom.i.pidx[p1s;  cs`px; idx];
            y1      : geom.i.pidx[p1s;  cs`py; idx];
            y2      : geom.i.pidx[p2s;  cs`py; idx];
            adj     : geom.i.posAdjust [`id`dodge; ()!(); c; n; t; a; s];
            hoffset : cs[`align][a`align; a`size]  % (-). reverse s[cs`px]`geom_limits;
            width   : adj[cs`w] % 2;
            if [width <= a`gap;  a[`gap]: 0];

            x1: (xs + $[`x~cs`px;::;neg] width + adj[cs`dx] + a[`gap] % 2) - $[`x~cs`px;::;neg] hoffset;
            v : ([] x1; y1; x2:x1; y2; colour:.z.m.axbits.or[o`alpha; o`fill]; size:1; dashed:o`dashed);
            
            bm : ([] x1:v[`x1]-width%2; y1;    x2:v[`x1]+width%2; y2:y1; colour:v`colour; size:v`size; dashed:v`dashed);
            tp : ([] x1:bm`x1;          y1:y2; x2:bm`x2;          y2;    colour:v`colour; size:v`size; dashed:v`dashed);

            : (etable.el[etable.g.LINE] `x1`y1`x2`y2 xcols cs[`final] xcol v , bm , tp;
                acc);
            }[; ; ; ; cs; a; s]];
    }
// @fileOverview 
// Return the fill colour for each geometry
// @param t {table} data 
// @param a {dict} aes 
// @param s {dict} scales 
// @param idx {long[]} indices of valid rows
//
// @returns {byte[][]} fill colour for each valid geometry
.z.m.gg.geom.i.fill:{[t; a; s; idx]
    : geom.i.param[t; a; `fill; s; idx; enlist -6h;  {[t; a; s; idx]
            column : tbl.column[t; a`fill] idx;
            : colour.gradient[column; min column; max column; a`minFill; a`maxFill];
            }];
    }

// @fileOverview 
// Draw a geometry based on a group specification. If the group specification
// is null, then all geometries are drawn in order of appearance. Otherwise,
// the geometries are drawn in order of appearance, grouped by the appropriate
// column.
// @param acc {any} accumulator for group
// @param t {table} data 
// @param a {dict} aes 
// @param drawF {fn} function to draw the goemetry
//
// @returns {table} etable
.z.m.gg.geom.i.group:{[acc; t; a; drawF]
    gs : $[h.null a`group; enlist (::); distinct tbl.column[t; a`group]];
    n  : count gs;
    : raze first {[st; c; n; t; a; drawF; gs]
            idx : $[h.null a`group;
                    ::;
                    tbl.indicesOf[t; a`group; gs c]];

            r : drawF[st 1; c; n; t; idx]; // => (etable; acc)
        
            : (st[0],enlist r 0; r 1)
            }[;; n; t; a; drawF; gs]/[(();acc);] til n;
    }

// @fileOverview 
// Return the horizontal alignment offset (`left`right`middle)
// @param align {symbol} alignment (one of 3 given) 
// @param size {number} size of the geometry
// @returns {float}
.z.m.gg.geom.i.halign:{[align; size]
    : geom.i.align [`right`left`middle; align; size]
    }

.z.m.gg.geom.i.linetable:{[t; t2; a; s]
    pxs    : -1_'(t2`x; next t2`x);
    pys    : -1_'(t2`y; next t2`y);
    o      : geom.i.options [t; a; s; $[all null t2`idx; ::; t2`idx]; `fill`alpha`size`dashed];
    
    if [0 = count t2;
        : ([]x1:();x2:();y1:();y2:();size:0#0;colour:0#0i;dashed:0#0b)];
        
    o         : @[o;`fill`size`dashed;{$[0h <= type x; -1_x; x]}];
    o[`alpha] : $[0h <= type o`alpha; 1_; ::] o`alpha;
        
    points: (!) . flip (
        (`x1    ; pxs 0);
        (`x2    ; pxs 1);
        (`y1    ; pys 0);
        (`y2    ; pys 1);
        (`size  ; "f"$o`size);
        (`colour; .z.m.axbits.or[o`alpha; o`fill]);
        (`dashed; o`dashed));
    
    if[any 0 = count each points`x1`y1`x2`y2; : ()!()];
    : points;
    }
// @fileOverview 
// Return data associated with a pt based on 1D distance
// @param xOrY {symbol} `x or `y 
// @param defaults {dict} aes/geom defaults 
// @param pt {(number;number)} 0-1 normalized point
// @param t {table} data 
// @param a {dict} aes 
// @param s {dict} scales
//
// @returns {table} closest point to the x position of the pt
.z.m.gg.geom.i.nearest1D:{[xOrY; defaults; pt; t; a; s]
    a    : h.extend[a; defaults];
    v    : proj.proj[s[xOrY]`geom_limits; 0 1] scale.apply[s xOrY] tbl.column[t;a xOrY];
    n    : proj.nearest1D[pt $[`x ~ xOrY; 0; 1]; v];
    data : tbl.at[t; n`idx];
    
    pt2 : pt;
    d: 0n;
    if [0 < count data;
        p : first data;
        x : proj.proj[s[xOrY]`geom_limits; 0 1] scale.apply[s xOrY] enlist p a xOrY;
        pt2 : first each $[`x ~ xOrY; (x; 0n); (0n; x)];
        d   : first abs $[`x ~ xOrY; pt2[0]-pt 0; pt2[1] - pt 1];
        ];
    
    : `data`distance`pt!(data; d; pt2);
    };
// @fileOverview 
// Return the nearest data points to the pixel clicked
// @param pt {(number;number)} 0-1 normalized pt 
// @param s {dict} scales 
// @param t {table} data 
// @param x {symbol} x column 
// @param y {symbol} y column
//
// @returns {dict} a table of closest points and the distance score to those points
.z.m.gg.geom.i.nearest2D:{[pt; s; t; x; y]
    xs  : proj.proj[s[`x]`geom_limits; 0 1] scale.apply[s`x] tbl.column[t;x];
    ys  : proj.proj[s[`y]`geom_limits; 0 1] scale.apply[s`y] tbl.column[t;y];
    n   : proj.nearest2D[pt 0; pt 1; xs; ys];
    ps  : tbl.at[t; n`idx];
    pt2 : pt;
    if [0 < count ps;
        p:   first ps;
        pt2: first each (proj.proj[s[`x]`geom_limits; 0 1] scale.apply[s`x] enlist p x;
                         proj.proj[s[`y]`geom_limits; 0 1] scale.apply[s`y] enlist p y)];
    : `data`distance`pt!(ps; n`distance; pt2);
    
    }

.z.m.gg.geom.i.nearestLine:{[pt; s; t; x; y; x2; y2]
    
    if[not[tbl.ty.is t] and 99h ~ type t; t: flip (x;y;x2;y2)#t];
    
    x1  : proj.proj[s[`x]`geom_limits; 0 1] scale.apply[s`x] tbl.column[t;x];
    y1  : proj.proj[s[`y]`geom_limits; 0 1] scale.apply[s`y] tbl.column[t;y];
    x2  : proj.proj[s[`x]`geom_limits; 0 1] scale.apply[s`x] tbl.column[t;x2];
    y2  : proj.proj[s[`y]`geom_limits; 0 1] scale.apply[s`y] tbl.column[t;y2];
    
    ds: proj.pointLineDistance[pt 0;pt 1]'[x1;y1;x2;y2];
    
    m   : min ds;
    ii  : where m = ds;
    ps  : tbl.at[t; ii];
    pt2 : pt;
    if [0 < count ps;
        p : first ps;
        pt2: first each (proj.proj[s[`x]`geom_limits; 0 1] scale.apply[s`x] enlist p x;
                         proj.proj[s[`y]`geom_limits; 0 1] scale.apply[s`y] enlist p y)];
    
    : `idx`data`distance`pt!(ii;ps;m;pt2)
    }

.z.m.gg.geom.i.options:{[t; a; s; idx; ops]
    d : `fill`alpha`stroke`size`dashed`angle`offsetx`offsety`offsetz!(
            geom.i.fill;
            geom.i.alpha;
            geom.i.stroke;
            geom.i.size;
            geom.i.aes.bool`dashed;
            geom.i.aes.number`angle;
            geom.i.aes.number`offsetx;
            geom.i.aes.number`offsety;
            geom.i.aes.number`offsetz);
    
    :  ops ! d[ops] .\: (t; a; s; idx);
    }
// @fileOverview order the fill values by the y axis value
// @param t {table} 
// @param a {dict} aes 
// @param d {symbol} column to sort values by 
// @returns {dict} Updated fill scale
.z.m.gg.geom.i.order:{[t;s;a;d]
    sortF: {[a;t;d;v] (tbl.column[t;a`fill] iasc tbl.column[t;a d]) inter v }[a;t;d];
    order: distinct sortF tbl.column[t; a`fill];
    : s@[;;:;order]/`i_distinct`i_odistinct
    }

// @fileOverview 
// Determine the value of a draw parameter for each valid row of a table
// @param t {table} data 
// @param a {dict} aes 
// @param k {symbol} key of aes 
// @param s {dict} scales 
// @param idx {long[]} list of valid indices 
// @param kind {string} valid types for expressing the parameter by value 
// @param customF {fn} function to apply a custom parameter to a value
// 
// @returns {any[]} list of correct parameters for each valid row, or atomic value for single-valued lists
.z.m.gg.geom.i.param:{[t; a; k; s; idx; kind; customF]

    : $[(type a k) in kind;
            a k;
        
        (-11h ~ type a k) and k in key s;
            scale.apply[s k; tbl.column[t; a k] idx]; 

        -11h ~ type a k;
            customF[t; a; s; idx];
        
            geom.i.DEFAULTS k];
    }

// @fileOverview Index into a point position list
// @returns {float[]} Point positions
.z.m.gg.geom.i.pidx:{[p; k; idx]
    $[(::) ~ idx;
        $[99h ~ type p k; value p k; p k];
      (::) ~ p`idx;
        p[k] idx;
        (p[`idx]!p k) idx]
    }

// raycasting 
.z.m.gg.geom.i.pointInPoly:{[xs; ys; x; y]
    inregion : where not (~).'(,'). y > ys each (ii:til count xs; j:-1 rotate til count xs);
    isright  : where x < xs[ii] + ((xs[j] - xs ii) * y-ys ii) % ys[j]-ys ii;
    : 1 = mod[;2] count inregion inter isright;
    }

.z.m.gg.geom.i.pos1D:{[s; t; col; idxs]
    xs  : scale.apply [s] tbl.column [t;col] idxs;
    idx : (::);
    
    idxi: $[$[0 = count xs; 1b; (not any null xs) & all ((min;max) @\: xs) within s`limits];
        ::;
        idxi : where xs within s`limits];
    
    $[not (::) ~ idxs;
        [
            idx: idxs idxi;
            xs:  idx!proj.proj[s`geom_limits; 0 1] xs idxi];
        
        ((::) ~ idxs) & (not (::) ~ idxi) & count[idxi] <> tbl.nrecords t;
        [
            idx: idxi;
            xs:  idxi!proj.proj[s`geom_limits; 0 1] xs idxi];
        
            xs: proj.proj[s`geom_limits; 0 1] xs];
    
    : `ps`idx!(xs;idx);
    }

// @fileOverview 
// Determine the 0-1 normalized 2D position for two columns of a table
// @param s {dict} scales 
// @param t {table} data 
// @param c1 {symbol} first column of the table 
// @param c2 {symbol} second column
// @param idxs {float[]|null} list of indicies to position
//
// @returns {dict} 0-1 normalized positions and corresponding indices
// @private
.z.m.gg.geom.i.pos2D:{[s; t; c1; c2; idxs]
    xs  : geom.i.pos1D[s`x; t; c1; idxs];
    ys  : geom.i.pos1D[s`y; t; c2; idxs];
    
    idx : geom.i.resolveIdx[xs; ys];
    $[(::) ~ idx;
        `x`y`idx!(xs`ps; ys`ps; idx);
        `x`y`idx!(xs[`ps] idx; ys[`ps] idx; idx)]
    }

// @fileOverview 
// 0-1 normalizes 3D points
// @param s {dict} scales 
// @param t {table} data 
// @param c1 {symbol} first column of the table 
// @param c2 {symbol} second column
// @param c3 {symbol} third column
// @param idxs {float[]|null} list of indicies to position
//
// @returns {dict} 0-1 normalized positions and corresponding indices
// @private
.z.m.gg.geom.i.pos3D:{[s; t; c1; c2; c3; idxs]

    xs  : geom.i.pos1D[s`x; t; c1; idxs];
    ys  : geom.i.pos1D[s`y; t; c2; idxs];
    zs  : geom.i.pos1D[s`z; t; c3; idxs];

    idx : geom.i.resolveIdx3D[xs; ys; zs];
    : $[(::) ~ idx;
        `x`y`z`idx!(xs`ps; ys`ps; zs`ps; idx);
        `x`y`z`idx!(xs[`ps] idx; ys[`ps] idx; zs[`ps] idx; idx)];
    }
// @fileOverview 
// Apply a position adjustment if one was specified in the aesthetic
// mappings. If a adjustment was not specified, then 0 offsets are 
// returned.
// @param poss {symbol[]} position settings
// @param ps {float[][]} positions
// @param c {number} current group number 
// @param n {number} total number of groups 
// @param t {table} data 
// @param a {dict} aesthetic mappings 
// @param s {dict} scales (needs `x and `y)
// @returns {dict} `dx and `dy offsets
.z.m.gg.geom.i.posAdjust:{[poss; ps; c; n; t; a; s]
    : $[(`id in poss) and (h.null a`position) or not `position in key a;
            geom.i.posId [c;n;t;a;s];
        
        (`dodge in poss) and geom.i.useDodge[a; t];
            geom.i.posDodge [c; n; t; a; s];
        
        (`stack in poss) and geom.i.useStack[a; t];
            geom.i.posStack [ps; c; n; t; a; s];
        
        (`stream in poss) and geom.i.useStream[a; t];
            geom.i.posStream [ps; c; n; t; a; s];
        
        `id in poss;
            geom.i.posId [c;n;t;a;s];
        
            enlist[`type]!enlist `none];
    }
// @fileOverview 
// Dodge position adjustment. Works will when dodging
// on a categorical axis. 
// @param c {number} current group number 
// @param n {number} total number of groups 
// @param t {table} data 
// @param a {dict} aesthetic mappings (requires `size and `gap)
// @param s {dict} scales (needs `x and `y)
// @returns {dict} `dx and `dy offsets
.z.m.gg.geom.i.posDodge:{[c; n; t; a; s]
    sz : geom.i.posSize [a; s];
    dw : (sz[`w] - sz[`gaps] 0)  % n;
    dh : (sz[`h] - sz[`gaps] 1)  % n;
    : `type`w`h`dx`dy!(`dodge;max 0.001,dw; max 0.001,dh; dw * c; dh * c);
    
    }
// @fileOverview 
// Return the width and height over 1 unit intervals with no position shift
// @param c {number} current group index
// @param n {number} total number of groups 
// @param t {table} data 
// @param a {dict} aesthetic mappings 
// @param s {dict} scales
// @returns {dict} width, height, and offsets
.z.m.gg.geom.i.posId:{[c; n; t; a; s]
    sz : geom.i.posSize [a; s];
    : `type`w`h`dx`dy!(`id; sz[`w] - sz[`gaps] 0; sz[`h] - sz[`gaps] 1; 0; 0)
    }

// @fileOverview 
// Given a size and gap size, return the width and height
// spread over the geom limits of the x and y scales along
// 1 unit intervals.
// @param a {dict} aesthetic mappings (requires `gap and `size)
// @param s {dict} scales (requires `x and `y) 
// @returns {dict} `w`h`gaps width, height, and gaps for both
.z.m.gg.geom.i.posSize:{[a; s]
    cnts   : {[s;x](-). reverse s[x] `geom_limits}[s] each `x`y;
    wth    : a[`size] % cnts 0;
    hgt    : a[`size] % cnts 1;
    gaps   : {[a;x]$[x <= a`gap; 0; a`gap]}[a] each (wth; hgt);
    : `w`h`gaps!(wth;hgt;gaps);
    }

// @fileOverview 
// Stack overlapping bars. Assumes there is only one bar for each stack variable.
// @param ps {dict} calculated x/y positions 
// @param c {number} current group number (0-based)
// @param n {number} total number of groups 
// @param t {table} 
// @param a {dict} aesthetic mappings 
// @param s {dict} scales 
.z.m.gg.geom.i.posStack:{[ps; c; n; t; a; s]
    
    cs : (`y`x;`x`y) `v ~ a`orientation;

    xs : distinct tbl.column[t; a cs 0] ps`idx;
    
    gs : $[h.null a`group; enlist (::); distinct tbl.column[t; a`group]];
    
    currVals : gs til 1 + c;
    
    currSum : ?[tbl.apply t;enlist (in;a`group;enlist currVals); a cs 0; (sum;a cs 1)];
    
    scaled  : scale.apply [s cs 1] value[currSum] h.findCat[key currSum;xs]; 
    tops    : proj.proj[s[cs 1]`geom_limits; 0 1] scaled;
    valls   : proj.proj[0 1; s[cs 1]`geom_limits] ps cs 1;
    hs      : ps cs 1;
    
    if [not count[valls] ~ count scaled; '.z.m.axlocalize.t`.gg_posStackAggregateError];
    
    idx : where not valls ~' scaled;
    
    hs : @[hs; idx; :; @[;idx]
        proj.proj[s[cs 1]`geom_limits; 0 1]        // back to 0 1
        s[cs 1][`geom_limits][0] +
        proj.proj[0 1; s[cs 1]`geom_limits] hs];   // from 0-1
    
    : `type`pos`size!(`stack; tops; hs);
    }

.z.m.gg.geom.i.posStream:{[ps; c; n; t; a; s];
    : @[;`type;:;`stream] geom.i.posStack [ps; c; n; t; a; s];
    }

.z.m.gg.geom.i.resolveIdx:{[a; b]
    $[((::) ~ a`idx) & (::) ~ b`idx;
        ::;
    (::) ~ a`idx;
        b`idx;
    (::) ~ b`idx;
        a`idx;
        a[`idx] inter b`idx]
    }

// @fileOverview 
// Returns indexes shared by all 3 inputs. (::) matches all indexes.
// @returns {int[]} list of shared indexes
.z.m.gg.geom.i.resolveIdx3D:{[x;y;z]
    : geom.i.resolveIdx[x; (enlist `idx)!enlist geom.i.resolveIdx[y;z]];
    }


.z.m.gg.geom.i.setStackLimits:{[x;y;t;a;s]
    
    if [geom.i.useStack[a; t] | geom.i.useStream[a; t];
        col: tbl.column[t; a y];
        
        if [not count[col] ~ count ii : where not null col;
            col @: ii];
        
        if [any 0 > col;
            '.z.m.axlocalize.t (`.gg_geomErrorStackNeg; enlist[`axis]!enlist string a y)];
        
        extend             : $[s . y,`extend; @[;`limits] scale.i.nice .; ::];
        aggregated         : ?[tbl.apply t;();a x;(sum; a y)];
        clean              : extend (0; scale.apply[s y] max value aggregated);
        s[y;`stack_offset] : .5 - %[;2] aggregated % max value aggregated;
        s[y;`geom_limits]  :  clean];
    
    : s;
    }

// @fileOverview 
// Return the correct size parameter for each row of the table
// @param t {table} data 
// @param a {dict} aes 
// @param s {dict} scales 
// @param idx {long[]} list of valid indices
//
// @returns {long[]} size parameter for each valid row
.z.m.gg.geom.i.size:{[t; a; s; idx]
    : 1^geom.i.param[t; a; `size; s; idx; -5 -6 -7 -8 -9h; {[t; a; s; idx]
            column : tbl.column[t; a`size] idx;
            : proj.proj[(min;max)@\:column; a`minSize`maxSize] column;
            }];
    }

// @fileOverview 
// Sort a scale based on the value of a given axis
// Written in the context of a vbar
// @param a {dict} aes
// @param lyr {dict} layer
// @param s {dict} scales 
// @param xk {symbol} x or y
// @param yk {symbol} x or y
// @returns {dict} Updated scales
.z.m.gg.geom.i.sortBars:{[a;lyr;s;xk;yk]
    if [a[`sortByValue] & `categorical ~ s[xk]`label;
        sortF: {[xk;yk;a;t;v]
            sorted: .z.m.gg.tbl.column[t;a xk] idesc .z.m.gg.tbl.column[t;a yk];
            : .[inter; (sorted;v); {[sorted;v;err]
                    : .[{x where any x ~\:/: y}; (sorted; v); sorted]
                    }[sorted;v]];
            }[xk;yk;a;lyr`transformed];
        s[xk]: @[s xk;`i_distinct;:;distinct sortF .z.m.gg.tbl.column[lyr`transformed; a xk]];
        s[xk]: @[s xk;`applyF;:;value[s[xk]`applyF][0] sortF]];
    : s;
    }
// @fileOverview Utility for extracting the particular rect clicked in a stack of rects
// @returns {dict} tooltip data
.z.m.gg.geom.i.stackRollover:{[majorAxis; minorAxis; d; pt; t; s; a]
    r:      geom.i.nearest1D[majorAxis; d; pt; t; a; s];
    vals:   sums 0,@[;a minorAxis] sorted: a[`group] xasc r`data;
    pr:     proj.proj[0 1;s[minorAxis]`geom_limits] pt 0 1 `x~majorAxis;
    pos:    vals bin $[tbl.metatype[sorted;a minorAxis] in "xhij";floor;::] pr;
    r[`data]: enlist $[pos~count sorted; sorted pos-1; pos~-1;sorted 0; sorted pos];
    r
    }

// @fileOverview 
// Return the stroke parameter for each row of a table
// @param t {table} data 
// @param a {dict} aes 
// @param s {dict} scales 
// @param idx {long[]} list of valid indices
//
// @returns {byte[]} list of stroke parameters for each valid row
.z.m.gg.geom.i.stroke:{[t; a; s; idx]
    : $ [`colour in key a;
            `strokewidth`strokecolour!(a`strokewidth;colour.setAlpha[a`strokealpha]
                geom.i.param[t; a; `colour; s; idx; enlist -6h; {[t; a; s; idx]
                    column : tbl.column[t; a`colour] idx;
                    : colour.gradient[column; min column; max column; a`minColour; a`maxColour];
                    }]);
        ::];
    }
// @fileOverview 
// Text geometry
// @param g {symbol} preferred text to use (`textL, `textM, `textR)
.z.m.gg.geom.i.text:{[g; settings]
    defaults : h.extend[settings] h.extend[`align`size`minSize`maxSize`offsetx`offsety`bold`italic!(`left; 10; 5; 20; 0; 0; 0b; 0b)] geom.i.DEFAULTS;
    
    : geom.ty.new (
        g;
        
        {[g;d;lyr]
            geom.i.validateAll["text"; lyr; h.extend[lyr`aes; d]; `size`fill`alpha`color];
            }[g; defaults];
        
        {[lyr]: lyr`scales};
        
        {[g; d; th; t; a; s]
            a  : geom.i.defAes[th] h.extend[a; d];
            geoms: `left`middle`center`right!etable.g`ATEXTL`ATEXTM`ATEXTM`ATEXTR;
            if [g ~ etable.g.ATEXTL; g: geoms a`align];
            ps : geom.i.pos2D   [s; t; a`x; a`y; ::];
            o  : geom.i.options [t; a; s; ps`idx; `fill`alpha`angle`size];
            : etable.el[g] distinct ([]
                x:        ps`x;
                y:        ps`y;
                offsetx:  a`offsetx;
                offsety:  a`offsety;
                text:     h.print each tbl.column[t;a`label] ps`idx;
                angle:    o`angle;
                fontsize: ceiling o`size;
                colour:   .z.m.axbits.or[o`alpha; o`fill];
                bold:     a`bold;
                italic:   a`italic);
            }[g; defaults];
        
        {[d; pt; t; lyr]
            a : h.extend[lyr`aes; d];
            : geom.i.nearest2D[pt; lyr`scales; t; a`x; a`y];
            } defaults;
        
        enlist `x;
        enlist `y;
        {[pt1; pt2; t; a; s; lyr] geom.fromBound2D[pt1; pt2; t; a; s; lyr] }
        );
    }
.z.m.gg.geom.i.toPolyTables:{[aes; t]
    : flip (aes cls)!tbl.column[t] each aes cls: key[aes] inter `x`y`z`fill`colour`alpha;
    }

// @fileOverview 
// Return whether dodge should be used as a position adjustment
// @param a {dict} aesthetic mappings
// @param t {table}
// @returns {boolean}
.z.m.gg.geom.i.useDodge:{[a; t]
    : (`dodge ~ a`position) and (`size in key a) and not h.null a`group
    }

// @fileOverview Return whether fill labels should be ordered by value
// @param s {dict} all layer scales
// @param d {dict} geom settings
// @returns {boolean} 
.z.m.gg.geom.i.useFillByValue:{[s;d]
    hasFill: `fillCat ~ $[`fill in key s; s[`fill]`label; 0b];
    : hasFill & d`fillByValue;
    }

// @fileOverview
// Return whether stacking should be used as a position adjustment
// @param a {dict} aesthetic mappings 
// @param t {table}
// @returns {boolean}
.z.m.gg.geom.i.useStack:{[a; t]
    if [(`stack ~ a`position) and not h.null a`group;
        if [a[`group] in tbl.colnames t;
            : 1b]];
    
    : 0b;
    }

.z.m.gg.geom.i.useStream:{[a; t]
    : (`stream ~ a`position) and not h.null a`group;
    }

.z.m.gg.geom.i.validate:{[t; scales; a; flag; types]
    if [h.null a flag;          : 1b];  // Null values will be ignored when applying    
    if [not -11h ~ type a flag; : 1b];  // Invalid constant values will be ignored when applying
    if [not a[flag] in tbl.colnames t;
        '.z.m.axlocalize.t (`.gg_geomErrorMissingColumn; h.asString a flag)];
        
    kind : tbl.metatype[t; a flag];
    if [(not kind in types) and not flag in key scales;
        '.z.m.axlocalize.t (`.gg_geomErrorValidation; `found`expected`flag`aes!(string h.METATYPES kind; h.niceTypeStr types; string flag; string a flag))];
    
    : 1b;
    }

// @fileOverview Validate a geometry against a layer
.z.m.gg.geom.i.validateAll:{[n;l;a;asyms]
    {[n;t;l;a;asym]
        .[geom.i.validate; (t; l`scales; a; asym; "hijef");  {'geom.i.errPre[(y;h.asString x)],z}[asym;n]] /dnl
        }[n;l`transformed;l;a] each asyms;
    }

// @fileOverview 
// Validate a given constant is of a given type
// @param flag {symbol} description of the constant 
// @param val {any} 
// @param types {char[]} list of accepted types (i.e., "hijef" for numbers)
// @returns {boolean}
//
// @throws "x constant of type y not one of z"
.z.m.gg.geom.i.validateConst:{[flag; val; types]
    
    if [not (k:tbl.metatype[([]x:enlist val); `x]) in types;
        '.z.m.axlocalize.t(`.gg_geomValidationError; `expected`found`flag!(h.niceTypeStr types; string h.METATYPES k; string flag))];
    
    : 1b;
    }

// @fileOverview 
// Validate a stack specification
// @param t {table} 
// @param stackcol {symbol}
// @returns {boolean}
//
// @throws "Stack spec must be a column name"
// @throws "Stack column must appear in the table"
// @throws "Stack column must be numeric"
.z.m.gg.geom.i.validateStack:{[t; stackcol]
    if [not -11h ~ type stackcol;                    '.z.m.axlocalize.t`.gg_geomStackErrorCName];
    if [not stackcol in tbl.colnames t;              '.z.m.axlocalize.t`.gg_geomStackErrorExist];
    if [not tbl.metatype[t; stackcol] in "xhijef";   '.z.m.axlocalize.t`.gg_geomStackErrorType];  /dnl
    : 1b;
    }

// @fileOverview 
// Return the vertical alignment offset (`` `bottom`top`middle ``)
// @param align {symbol} alignment (one of 3 given) 
// @param size {number} size of the geometry
// @returns {number}
.z.m.gg.geom.i.valign:{[align; size]
    : geom.i.align [`bottom`top`middle; align; size]
    }

// @fileOverview 
// Line geometry - draws a line in horizontal order
.z.m.gg.geom.line:{[settings]
    defaults : h.extend[settings] h.extend[`size`minSize`maxSize`decorations`bankMinHeight`bankMaxAngle!(1;1;15;0b;60;90)] geom.i.DEFAULTS;
    
    : geom.ty.new (
        `line;
        
        {[d;lyr]
            geom.i.validateAll["line"; lyr; h.extend[lyr`aes; d]; `size`fill`alpha];
            } defaults;

        {[lyr]lyr`scales};

        {[d; th; t; a; s]
            a : geom.i.defAes[th]  h.extend[a; d];
            : geom.i.group[::; t; a; {[acc; c; n; t; a; s; idxs]
                    ps    : geom.i.pos2D [s; t; a`x; a`y; idxs];
                    gs    : `x xasc ([]x:ps`x; y:ps`y; idx:$[(::) ~ ps`idx; til count ps`x; ps`idx]);
                    lt    : geom.i.linetable[t; gs; a; s];
                    geoms : etable.el[etable.g.LINE] lt;
                    if [a[`decorations] & 0 < count lt;
                        geoms ,: etable.el[etable.g.POINT] p1: { (`x`y,2_key x)!value x} `x2`y2`dashed _ update size: 2 from lt;
                        geoms ,: etable.el[etable.g.POINT] cols[p1]#update x:x2, y:y2, size:2 from last each lt];
                    : (geoms; acc);
                    }[; ; ; ; a; s]];
            } defaults;

        {[d; pt; t; lyr]
            a: h.extend[lyr`aes; d];
            : geom.i.nearest2D[pt; lyr`scales; t; a`x; a`y];
            } defaults;

        1#`x;
        1#`y;
        
        {[pt1; pt2; t; a; s; lyr]  geom.fromBound1D[`x; `x; pt1; pt2; t; a; s; lyr] }
        );
    }

// @fileOverview 
// Path geometry - draws a line in order of appearance
.z.m.gg.geom.path:{[settings]
    defaults : h.extend[settings] h.extend[`size`minSize`maxSize!1 1 15] geom.i.DEFAULTS;
    : geom.ty.new (
        `path;
        
        {[d;lyr]
            geom.i.validateAll["path"; lyr; h.extend[lyr`aes; d]; `size`fill`alpha`colour];
            } defaults;
        
        {[lyr]lyr`scales};
        
        {[d; th; t; a; s]
            a : geom.i.defAes[th] h.extend[a; d];
            : geom.i.group[::; t; a; {[acc; c; n; t; a; s; idxs]
                    ps     : geom.i.pos2D[s; t; a`x; a`y; idxs];
                    pxs    : flip -1_flip (ps`x; 1_ps[`x],0);
                    pys    : flip -1_flip (ps`y; 1_ps[`y],0);
                    o      : geom.i.options [t; a; s; ps`idx; `fill`alpha`size];
                    
                    o         : @[o;`fill`size;{$[0h <= type x; -1_x; x]}];
                    o[`alpha] : $[0h <= type o`alpha; 1_; ::] o`alpha;

                    points    : (!) . flip (
                        (`x1    ; pxs 0);
                        (`x2    ; pxs 1);
                        (`y1    ; pys 0);
                        (`y2    ; pys 1);
                        (`size  ; o`size);
                        (`colour; .z.m.axbits.or[o`alpha; o`fill]));
                    if[any 0 = count each points`x1`y1`x2`y2; : ()!()];
                    : (etable.el[etable.g.LINE] points;
                        acc);
                    }[; ; ; ; a; s]];
            } defaults;
        
        {[d; pt; t; lyr]
            a : h.extend[lyr`aes; d];
            : geom.i.nearest2D[pt; lyr`scales; t; a`x; a`y];
            } defaults;
        
        enlist `x;
        enlist `y;
        
        {[pt1; pt2; t; a; s; lyr] geom.fromBound2D[pt1; pt2; t; a; s; lyr] }
        );
    }

// @fileOverview 
// Point geometry
.z.m.gg.geom.point:{[defaults]
    
    defaults : h.extend[defaults] h.extend[`shape`size`minSize`maxSize`angle`jitterx`jittery`strokealpha!(`circle;1.2;1;10;0;0;0;0xff)] geom.i.DEFAULTS;
    
    : geom.ty.new (
        `point;
        
        {[d;lyr]
            geom.i.validateAll["point"; lyr; h.extend[lyr`aes; d]; `size`fill`alpha`colour];
            } defaults;

        {[d;lyr]
            a: h.extend[lyr`aes; d];
            s: lyr`scales;
            if [not 0 = a`jitterx; s[`x]: .z.m.gg.scale.base.with.extension[s[`x;`extension]|2*a`jitterx] s`x];
            if [not 0 = a`jittery; s[`y]: .z.m.gg.scale.base.with.extension[s[`y;`extension]|2*a`jittery] s`y];
            : s;
            } defaults;

        {[d; th; t; a; s]
            a  : geom.i.defAes[th] h.extend[a; d];
            if [not a[`shape] in `circle`square`triangle; a[`shape]: `circle];
            sp : etable.g[`POINT`SQUARE`TRIANGLE] `circle`square`triangle?a`shape;
            ps : geom.i.pos2D   [s; t; a`x; a`y; ::];
            op : geom.i.options [t; a; s; ps`idx; `fill`alpha`size`stroke`angle];
            gs: `x`y`size`colour`angle!(ps`x;ps`y;"f"$op`size;.z.m.axbits.or[op`alpha; op`fill];op`angle);
            if[any 0 = count each gs`x`y; : ()!()];
            if [not 0 = a`jitterx; gs[`x] +: (neg .5*a`jitterx)+count[gs`x]?a`jitterx];
            if [not 0 = a`jittery; gs[`y] +: (neg .5*a`jittery)+count[gs`y]?a`jittery];
            if [not h.null op`stroke; gs,: op`stroke];
            : etable.el[sp] $[-11h ~ type a`size; h.dictDesc`size; ::] gs;
            } defaults;

        {[d; pt; t; lyr]
            a : h.extend[lyr`aes; d];
            : geom.i.nearest2D[pt; lyr`scales; t; a`x; a`y];
            } defaults;
        
        enlist `x;
        enlist `y;

        {[pt1; pt2; t; a; s; lyr] geom.fromBound2D[pt1; pt2; t; a; s; lyr] }
        )
    }

// @fileOverview 
// 3D Point geometry
.z.m.gg.geom.point3D:{[defaults]
    
    defaults : h.extend[defaults] h.extend[`shape`size`minSize`maxSize`angle`jitterx`jittery`strokealpha!(`circle;2;1;10;0;0;0;0xff)] geom.i.DEFAULTS;
    
    : geom.ty.new (
        `point3D;
        
        {[d;lyr]
            geom.i.validateAll["point3D"; lyr; h.extend[lyr`aes; d]; `size`fill`alpha`colour];
            } defaults;

        {[d;lyr]
            : lyr`scales;
            } defaults;

        {[d; th; t; a; s]
            a  : geom.i.defAes[th] h.extend[a; d];
            sp : etable.g`POINT3D;
            ps : geom.i.pos3D   [s; t; a`x; a`y; a`z;::];
            op : geom.i.options [t; a; s; ps`idx; `fill`alpha`size`stroke`angle];
            gs : (!) . flip (
                (`x     ; ps`x);
                (`y     ; ps`y);
                (`z     ; ps`z);
                (`size  ; op`size);
                (`colour; .z.m.axbits.or[op`alpha; op`fill]));
            if [not h.null op`stroke; gs,: op`stroke];
            : etable.el[sp] $[-11h ~ type a`size; h.dictDesc`size; ::] gs;
            } defaults;

        {[d; pt; t; lyr]
            a: h.extend[lyr`aes;d];
            normPts: geom.i.pos3D[lyr`scales; t; a`x; a`y; a`z;::];
            t2: flip `x`y!lyr[`coord;`applyF] normPts`x`y`z;
            closest: proj.nearest2D[pt 0; pt 1;t2`x;t2`y];
            : `data`distance`pt!(.z.m.gg.tbl.at[t;closest[`idx] 0];closest`distance;value t2 closest[`idx] 0);
            } defaults;
        
        enlist `x;
        
        enlist `y;
        
        {[d; pt1; pt2; t; a; s; lyr] '.z.m.axlocalize.t`.gg_geomErrorZoom3D } defaults
    
        )


    }
// @fileOverview 
// Area geometry - draws a line in horizontal order with a filled polygon
.z.m.gg.geom.polygon:{[settings]
    defaults : h.extend[settings] h.extend[enlist[`clip]!enlist 1b] geom.i.DEFAULTS;
    
    : geom.ty.new (
    
        `polygon;
        
        {[d;lyr]
            geom.i.validateAll["polygon"; lyr; h.extend[lyr`aes; d]; `size`fill`alpha];
            } defaults;

        {[lyr]lyr`scales};

        {[d; th; t; a; s] // -> ETable    
            a : geom.i.defAes[th] h.extend[origAes : a; d];
            
            if [not tbl.metatype[t; a`x] in "XHIJEF";  'geom.i.errPre[("polygon";"x")],.z.m.axlocalize.t (`.gg_geomErrorNested;"x")]; /dnl
            if [not tbl.metatype[t; a`y] in "XHIJEF";  'geom.i.errPre[("polygon";"y")],.z.m.axlocalize.t (`.gg_geomErrorNested;"y")]; /dnl
            
            r : etable.el[etable.g.PATH] {[d; t; a; s]
                t2     : ([] x:t a`x; y: t a`y);
                t      : flip enlist each t;
                ps     : geom.i.pos2D [s; t2; `x; `y; ::];
                o      : geom.i.options [t; a; s; ps`idx; `fill`alpha`stroke];
                if [0 = tbl.nrecords t; : ()];
                if [not count[ps`x] ~ count ps`y; 'geom.i.errPre[("polygon";"length")],.z.m.axlocalize.t`.gg_geomErrorLength]; /dnl
                points: `close`xs`ys`colour!(1b; ps`x; ps`y; .z.m.axbits.or[first o`alpha; first o`fill]);
                if [not h.null o`stroke; points : h.extend[points] o`stroke];
                : points;
                }[d; ; a; s] each geom.i.toPolyTables[origAes; t];
            
            : $[0 = count r; (); r];
            } defaults;

        {[d; pt; t; lyr]
            ii : where {[x;y;t;a;s]
                t2: ([] x:t a`x; y: t a`y);
                xs: proj.proj[s[`x]`geom_limits; 0 1] scale.apply[s`x] tbl.column[t2;`x];
                ys: proj.proj[s[`y]`geom_limits; 0 1] scale.apply[s`y] tbl.column[t2;`y];
                : geom.i.pointInPoly[xs; ys; x; y]
                }[pt 0; pt 1;; lyr`aes; lyr`scales] each geom.i.toPolyTables[lyr`aes; t];
            : `data`distance`pt!(tbl.at[t; ii]; 0N; pt)
            } defaults;
        
        enlist `x;
        enlist `y;
        
        {[d; pt1; pt2; t; a; s; lyr]
            : where {[clip;px;py;t;a;s]
                t2: ([] x:t a`x; y: t a`y);
                xs: proj.proj[s[`x]`geom_limits; 0 1] scale.apply[s`x] tbl.column[t2;`x];
                ys: proj.proj[s[`y]`geom_limits; 0 1] scale.apply[s`y] tbl.column[t2;`y];
                m: $[clip; all; max];
                : (m xs within\: px) and m ys within\: py;
                }[d`clip;asc (pt1;pt2)@\:0; asc (pt1;pt2)@\:1;; a; s] each geom.i.toPolyTables[a; t];
            } defaults
        );
    }

// @fileOverview 
// Rectangle geometry (xmin, mxax, ymin, ymax)
.z.m.gg.geom.rect:{[defaults]
 
    defaults : h.extend[defaults] geom.i.DEFAULTS;
    
    : geom.ty.new (
    
        `rect;
        
        {[d;lyr]
            geom.i.validateAll["rect"; lyr; h.extend[lyr`aes; d]; `colour`fill`alpha];
            } defaults;

        {[lyr]lyr`scales};

        {[d; th; t; a; s]
            a : geom.i.defAes[th]  h.extend[a; d];
            : geom.i.group[::; t; a; {[acc; c; n; t; a; s; idxs]
                    p1s    : geom.i.pos2D [s; t; a`x; a`y; idxs];
                    p2s    : geom.i.pos2D [s; t; a`xmax; a`ymax; idxs];
                    idx    : geom.i.resolveIdx[p1s; p2s];
                    o      : geom.i.options [t; a; s; idx; `fill`alpha`stroke];
                    points : (!) . flip (
                        (`x1    ; geom.i.pidx[p1s;`x;idx]);
                        (`x2    ; geom.i.pidx[p2s;`x;idx]);
                        (`y1    ; geom.i.pidx[p1s;`y;idx]);
                        (`y2    ; geom.i.pidx[p2s;`y;idx]);
                        (`colour; .z.m.axbits.or[o`alpha;o`fill]));
                    if[any 0 = count each points`x1`y1`x2`y2; : ()!()];
                    if [not h.null o`stroke; points,: o`stroke];
                    : (etable.el[etable.g.RECT4] points;
                        acc)
                    }[; ; ; ; a; s]];
            } defaults;

        {[d; pt; t; lyr]
            a    : h.extend[lyr`aes; d];
            s    : lyr`scales;
            x1s  : proj.proj[s[`x]`geom_limits; 0 1] scale.apply[s`x] tbl.column[t;a`x];
            y1s  : proj.proj[s[`y]`geom_limits; 0 1] scale.apply[s`y] tbl.column[t;a`y];
            x2s  : proj.proj[s[`x]`geom_limits; 0 1] scale.apply[s`x] tbl.column[t;a`xmax];
            y2s  : proj.proj[s[`y]`geom_limits; 0 1] scale.apply[s`y] tbl.column[t;a`ymax];
            wx   : pt[0] within' asc each flip (x1s;x2s);
            wy   : pt[1] within' asc each flip (y1s;y2s);
            ps   : tbl.at[t] where wx & wy;
            : `data`distance`pt!(ps;0;pt);
            } defaults;

        `x`xmax;
        `y`ymax;
        
        {[pt1; pt2; t; a; s; lyr] geom.fromBound2D[pt1; pt2; t; a; s; lyr] }
        )
    }
// @fileOverview 
// Vertical interval geometry
.z.m.gg.geom.ribbon:{[settings]
    
    defaults : h.extend[settings] h.extend[enlist[`size]!enlist 0] geom.i.DEFAULTS;
    
    : geom.ty.new (
    
        `ribbon;
        
        {[d;lyr]
            geom.i.validateAll["ribbon"; lyr; h.extend[lyr`aes; d]; `colour`fill`alpha];
            } defaults;

        {[lyr]:lyr`scales};
        
        {[d; th; t; a; s]
            a: geom.i.defAes[th] geom.i.defSize[s`x] h.extend[a; d];
            : geom.i.group[::; t; a; {[acc; c; n; t; a; s; idxs]
                    p1s  : geom.i.pos2D [s; t; a`x; a`y; idxs];
                    p2s  : geom.i.pos2D [s; t; a`x; a`yend; idxs];
                    idx  : geom.i.resolveIdx[p1s; p2s];
                    o    : geom.i.options [t; a; s; idx; `fill`alpha`stroke];
                    xs   : geom.i.pidx[p1s; `x; idx];
                    ys   : geom.i.pidx[p1s; `y; idx];
                    ys2  : geom.i.pidx[p2s; `y; idx];
                    if [0 = count xs; : ()];
                    t    : `xs xasc ([]xs;ys;ys2);
                    xs2  : t[`xs] , reverse t`xs;
                    ys2  : t[`ys] , reverse t`ys2;
                    g    : enlist`close`xs`ys`colour!(1b; xs2; ys2; .z.m.axbits.or[first o`alpha; first o`fill]);
                    if [not h.null o`stroke; g: g , first o`stroke];
                    : (etable.el[etable.g.PATH] g; acc)
                    }[; ; ; ; a; s]];
            } defaults;

        {[d; pt; t; lyr]
            a: lyr`aes;
            s: lyr`scales;
            : geom.i.nearest1D[`x; d; pt; t; geom.i.defSize[s`x] h.extend[a; d]; s];
            } defaults;

        enlist `x;
        `y`yend;
        
        {[d; pt1; pt2; t; a; s; lyr]
            geom.fromBound1D[`x; `x; pt1; pt2; t; geom.i.defSize[s`x] h.extend[a; d]; s; lyr]
            } defaults
        );
    }

// @fileOverview 
// Given a 0-1 normalized point, return the closest data
// to the point.
// @param g {dict} geometry 
// @param pt {(number;number)} 0-1 normalized point 
// @param t {table} data 
// @param lyr {dict} layer
// 
// @returns {table} closest data to the point
.z.m.gg.geom.rollover:{[g; pt; t; lyr]
    : (geom.ty.rolloverF g)[pt; t; lyr]
    }

// @fileOverview 
// Segment geometry - draw one disconnected line per row
.z.m.gg.geom.segment:{[settings]
    defaults : h.extend[settings] h.extend[`size`minSize`maxSize!1 1 15] geom.i.DEFAULTS;
    
    : geom.ty.new (
    
        `segment;
        
        {[d;lyr]
            geom.i.validateAll["segment"; lyr; h.extend[lyr`aes; d]; `size`fill`alpha];
            } defaults;

        {[lyr]lyr`scales};

        {[d; th; t; a; s]
            a  : geom.i.defAes[th] h.extend[a; d];
            : geom.i.group[::; t; a; {[acc; c; n; t; a; s; idxs]
                    p1s    : geom.i.pos2D [s; t; a`x; a`y; idxs];
                    p2s    : geom.i.pos2D [s; t; a`xend; a`yend; idxs];
                    idx    : geom.i.resolveIdx[p1s; p2s];
                    o      : geom.i.options [t; a; s; idx; `fill`alpha`size`dashed];
                    points: (!) . flip (
                        (`x1    ; geom.i.pidx[p1s; `x; idx]);
                        (`x2    ; geom.i.pidx[p2s; `x; idx]);
                        (`y1    ; geom.i.pidx[p1s; `y; idx]);
                        (`y2    ; geom.i.pidx[p2s; `y; idx]);
                        (`size  ; o`size);
                        (`colour; .z.m.axbits.or[o`alpha;o`fill]);
                        (`dashed; o`dashed));
                    
                    if[any 0 = count each points`x1`y1`x2`y2; : ()!()];
                       
                    : (etable.el[etable.g.LINE] points;
                        acc);
                    }[; ; ; ; a; s]];
            } defaults;

        {[d; pt; t; lyr]
            a : h.extend[lyr`aes; d];
            : `data`distance`pt#geom.i.nearestLine[pt; lyr`scales; t; a`x; a`y; a`xend; a`yend];
            } defaults;

        `x`xend;
        `y`yend;
        
        {[pt1; pt2; t; a; s; lyr]
            :  geom.fromBound1D[`x; `x; pt1; pt2; t; a; s; lyr] inter
               geom.fromBound1D[`y; `y; pt1; pt2; t; a; s; lyr] inter
               geom.fromBound1D[`x; `xend; pt1; pt2; t; a; s; lyr] inter
               geom.fromBound1D[`y; `yend; pt1; pt2; t; a; s; lyr];
            }
        );
    }
// @fileOverview 
// Left-aligned text geometry
.z.m.gg.geom.textL:{[settings]
    : geom.i.text[etable.g.ATEXTL; settings]
    }

// @fileOverview 
// Middle-aligned text geometry
.z.m.gg.geom.textM:{[settings]
    : geom.i.text[etable.g.ATEXTM; settings]
    }

// @fileOverview 
// Right-aligned text geometry
.z.m.gg.geom.textR:{[settings]
    : geom.i.text[etable.g.ATEXTR; settings]
    }

// @fileOverview
// Tile geometry (squares with width and height)
.z.m.gg.geom.tile:{[defaults]

    defaults : h.extend[defaults] h.extend[`width`height`gap`valign`halign!(1; 1; 0; `bottom; `left)] geom.i.DEFAULTS;

    : geom.ty.new (

        `tile;

        {[d;lyr]
            geom.i.validateAll["tile"; lyr; h.extend[lyr`aes; d]; `width`height`fill`colour`alpha];
            } defaults;

        {[defaults;  lyr]
            s       : lyr`scales;
            a       : geom.i.defAlign[s`x;`halign] geom.i.defAlign[s`y;`valign] geom.i.defHeight[s`y] geom.i.defWidth[s`x]  h.extend[lyr`aes; defaults];
            hoffset : geom.i.halign [a`halign; a`width];
            voffset : geom.i.valign [a`valign; a`height];
            s[`x;`geom_limits]: (s[`x;`limits][0] - hoffset; s[`x;`limits][1] + a[`width] - hoffset);
            s[`y;`geom_limits]: (s[`y;`limits][0] - a[`height] - voffset; s[`y;`limits][1] + voffset);
            : s;
            } defaults;

        {[defaults; th; t; a; s]
            a : geom.i.defAlign[s`x;`halign] geom.i.defAlign[s`y;`valign] geom.i.defHeight[s`y] geom.i.defWidth[s`x] geom.i.defAes[th] h.extend[a; defaults];
            : geom.i.group[::; t; a; {[acc; c; n; t; a; s; idxs]
                    ps       : geom.i.pos2D   [s; t; a`x; a`y; idxs];
                    o        : geom.i.options [t; a; s; ps`idx; `fill`alpha`stroke];
                    height   : a[`height] % (-). reverse s[`y]`geom_limits;
                    a[`size] : a`width;     // Set the aesthetic size for the pos adjust
                    if [not any `categorical = s[`x`y]@\:`label;  a[`gap]: 0];
                    adj      : geom.i.posAdjust [`id`dodge; ps; c; n; t; a; s];
                    hoffset  : geom.i.halign  [a`halign; a`width]  % (-). reverse s[`x]`geom_limits;
                    voffset  : geom.i.valign  [a`valign; a`height] % (-). reverse s[`y]`geom_limits;
                    points   : (!) . flip (
                        (`y      ; (voffset+ps`y) - .5*a`gap);
                        (`x      ; (ps[`x] - hoffset) + adj[`dx] + .5*a`gap);
                        (`w      ; adj[`w] - a`gap);
                        (`h      ; height - a`gap);
                        (`colour ; .z.m.axbits.or[o`alpha; o`fill]));

                    if[any 0 = count each points`x`y`h`w; : ()!()];
                    if [not h.null o`stroke; points,: o`stroke];
                    : (etable.el[etable.g.RECT] points;
                        acc);
                    }[; ; ; ; a; s]];
            } defaults;

        {[defaults; pt; t; lyr]
            s       : lyr`scales;
            a       : geom.i.defAlign[s`x;`halign] geom.i.defAlign[s`y;`valign] geom.i.defHeight[s`y] geom.i.defWidth[s`x] h.extend[lyr`aes; defaults];
            width   : a[`width]  % (-). reverse s[`x]`geom_limits;
            height  : a[`height] % (-). reverse s[`y]`geom_limits;
            hoffset : geom.i.halign [a`halign; a`width]  % (-). reverse s[`x]`geom_limits;
            voffset : geom.i.valign [a`valign; a`height] % (-). reverse s[`y]`geom_limits;
            xs      : -[;hoffset] (width  % 2) + proj.proj[s[`x]`geom_limits; 0 1] scale.apply[s`x] tbl.column[t;a`x];
            ys      : +[;voffset] -[;height % 2] proj.proj[s[`y]`geom_limits; 0 1] scale.apply[s`y] tbl.column[t;a`y];
            n       : proj.nearest2D[pt 0; pt 1; xs; ys];
            data    : tbl.at[t; n`idx];
            pt2     : pt;
            if [0 < count data;
                p   : first data;
                pt2 : first each ((proj.proj[s[`x]`geom_limits; 0 1] scale.apply[s`x] enlist p a`x) + (width % 2) - hoffset;
                                  (proj.proj[s[`y]`geom_limits; 0 1] scale.apply[s`y] enlist p a`y) + voffset - height % 2)];
            : `data`distance`pt!(data; n`distance; pt2);

            } defaults;

        enlist `x;

        enlist `y;

        {[pt1; pt2; t; a; s; lyr] geom.fromBound2D[pt1; pt2; t; a; s; lyr] }

        )

    }

// @fileOverview 
// Validate a geometry against a layer
// @param g {dict} 
// @param lyr {dict}
//
// @throws geometry validation error
.z.m.gg.geom.validate:{[g; lyr]
    g[`validateF] lyr
    }

// @fileOverview 
// Vertical bar geometry
.z.m.gg.geom.vbar:{[settings]
    
    defaults : h.extend[settings] h.extend[`orientation`align`gap`sortByValue!(`v; `middle; 0.01; 0b)] geom.i.DEFAULTS _ `size;
    
    : geom.ty.new (
    
        `vbar;
        
        {[d;lyr]
            a : h.extend[lyr`aes; d];
            t : lyr`transformed;
            geom.i.validateAll["vbar"; lyr; a; `colour`fill`alpha];
            if [`size in key a;
                .[geom.i.validateConst; (`size; a`size; "hijef"); {'geom.i.errPre[("vbar";"size")]  ,x}]]; /dnl
            if [not h.null a`position;
                if [not (lyr . `scales`x`label) in `linear`default`categorical`temporal; 
                    '"Only able to use `position adjust` with categorical, temporal, or linear (default) scales"]];
            if [geom.i.useStack[a; t];
                if [not (lyr . `scales`y`label) in `linear`default; '"Only able to use `stack position` with linear (default) scales"];
                .[geom.i.validateStack; (t; a`y);                 {'geom.i.errPre[("vbar";"stack")] ,x}]]; /dnl
            } defaults;

        {[d; lyr]
            s       : lyr`scales;
            a       : geom.i.defSize[s`x] h.extend[lyr`aes; d];
            hoffset : geom.i.halign [a`align; a`size];
            s[`x;`geom_limits]: (s[`x;`limits][0] - hoffset; s[`x;`limits][1] + a[`size] - hoffset);
            s       : geom.i.setStackLimits[`x;`y;lyr`transformed;a;s];
            : geom.i.sortBars[a;lyr;s;`x;`y];
            } defaults;

        {[d; th; t; a; s]
            a : geom.i.defAes[th] geom.i.defSize[s`x] h.extend[a; d];
            : geom.i.group[::; t; a; {[acc; c; n; t; a; s; idxs]
                    ps      : geom.i.pos2D [s; t; a`x; a`y; idxs];
                    hs      : ps`y;
                    o       : geom.i.options [t; a; s; ps`idx; `fill`alpha`stroke];
                    adj     : geom.i.posAdjust [`id`dodge`stack; ps; c; n; t; a; s];
                    width   : a[`size] % (-). reverse s[`x]`geom_limits;
                    if [width < 2*a`gap;  a[`gap]: 0];
                    width  -: a`gap;
                    offset  : 0;
                    hoffset : geom.i.halign [a`align; a`size]  % (-). reverse s[`x]`geom_limits;
                    
                    if [`stack ~ adj`type;
                        ps[`y] : adj`pos;
                        hs     : adj`size];
                    if [`dodge ~ adj`type;
                        width  : adj`w;
                        offset : adj`dx];
                    
                    points : (!) . flip (
                        (`x     ; (ps[`x] + offset + a[`gap] % 2) - hoffset);
                        (`y     ; ps`y);
                        (`w     ; width);
                        (`h     ; hs);
                        (`colour; .z.m.axbits.or[o`alpha; o`fill]));
                    
                    if [not h.null o`stroke; points,: o`stroke];
                    if[any 0 = count each points`x`y`h`w; : ()!()];
                    : (etable.el[etable.g.RECT] h.dictDesc[`y] points;
                        acc);
                    }[; ; ; ; a; s]];
            } defaults;

        {[d; pt; t; lyr]
            s: lyr`scales;
            a: geom.i.defSize[s`x] h.extend[lyr`aes; d];
            width   : $[`left ~ a`align; ::; `right ~ a`align; neg; {0}] 
                %[;2] a[`size] % (-). reverse s[`x]`geom_limits;
            pt[0] -: width;
            r : $[geom.i.useStack[a; t];
                geom.i.stackRollover[`x;`y;d;pt;t;s;a];
                geom.i.nearest1D[`x; d; pt; t; a; s]];
            r[`pt;0] +: width;
            : r;
            } defaults;

        enlist `x;
        enlist `y;
        
        {[d; pt1; pt2; t; a; s; lyr]
            geom.fromBound1D[`x; `x; pt1; pt2; t; geom.i.defSize[s`x] h.extend[a; d]; s; lyr]
            } defaults
        );
    }

// @fileOverview 
// Vertical error bar geometry
.z.m.gg.geom.verrorbar:{[settings]
    
    defaults : h.extend[settings] h.extend[`align`gap`strokewidth!(`middle; 0.01; 1)] geom.i.DEFAULTS _ `size;
    
    : geom.ty.new (
    
        `verrorBar;
        
        {[d;lyr]
            a : h.extend[lyr`aes; d];
            geom.i.validateAll["verrorbar"; lyr; a; `fill`alpha];
            if [`size in key a;
                .[geom.i.validateConst; (`size; a`size; "hijef"); {'geom.i.errPre[("verrorbar";"size")],x}]];  /dnl
            } defaults;

        {[d; lyr]
            s       : lyr`scales;
            a       : geom.i.defSize[s`x] h.extend[lyr`aes; d];
            hoffset : geom.i.halign [a`align; a`size];
            s[`x;`geom_limits]: (s[`x;`limits][0] - hoffset; s[`x;`limits][1] + a[`size] - hoffset);
            : s;
            } defaults;
        
        geom.i.errorbar[`align`px`py`x`y`xend`yend`w`dx`final!geom.i.valign,`x`y`x`y`x`yend`w`dx,enlist`x1`y1`x2`y2; defaults];

        {[d; pt; t; lyr]
            a : h.extend[lyr`aes; d];
            : `data`distance`pt#geom.i.nearestLine[pt; lyr`scales; t; a`x; a`y; a`x; a`yend];
            } defaults;

        1#`x;
        `y`yend;
        
        {[d; pt1; pt2; t; a; s; lyr]
            geom.fromBound1D[`x; `x; pt1; pt2; t; geom.i.defSize[s`x] h.extend[a; d]; s; lyr]
            } defaults

        );

    }

// @fileOverview 
// Vertical interval geometry
.z.m.gg.geom.vinterval:{[settings]
    
    defaults : h.extend[settings] h.extend[`align`gap`strokewidth`collapse`fillByValue!(`middle; 0.01; 1; 0b; 0b)] geom.i.DEFAULTS _ `size;
    : geom.ty.new (
    
        `vinterval;
        
        {[d;lyr]
            a : h.extend[lyr`aes; d];
            geom.i.validateAll["vinterval"; lyr; a; `colour`fill`alpha];
            if [`size in key a;
                .[geom.i.validateConst; (`size; a`size; "hijef"); {'geom.i.errPre[("vinterval";"size")],x}]];  /dnl
            } defaults;

        {[d; lyr]
            s       : lyr`scales;
            a       : geom.i.defSize[s`x] h.extend[lyr`aes; d];
            hoffset : geom.i.halign [a`align; a`size];
            s[`x;`geom_limits]: (s[`x;`limits][0] - hoffset; s[`x;`limits][1] + a[`size] - hoffset);
            if [geom.i.useFillByValue[s;a]; s[`fill]: geom.i.order[lyr`transformed; s`fill; a; `y]];
            : s;
            } defaults;
        
        {[d; th; t; a; s]            
            a: geom.i.defAes[th] geom.i.defSize[s`x] h.extend[a; d];
            : geom.i.group[::; t; a; {[acc; c; n; t; a; s; idxs]
                    p1s     : geom.i.pos2D [s; t; a`x; a`y; idxs];
                    p2s     : geom.i.pos2D [s; t; a`x; a`yend; idxs];
                    idx     : geom.i.resolveIdx[p1s; p2s];
                    o       : geom.i.options [t; a; s; idx; `fill`alpha`size`stroke];
                    xs      : geom.i.pidx[p1s; `x; idx];
                    ys      : geom.i.pidx[p1s; `y; idx];
                    yends   : geom.i.pidx[p2s; `y; idx];
                    ms      : min each ys ,' yends;
                    Ms      : max each ys ,' yends;
                    heights : Ms -' ms;
                    adj     : geom.i.posAdjust [`id`dodge; `x`y!(xs;Ms); c; n; t; a; s];
                    width   : a[`size] % (-) . reverse s[`x]`geom_limits;
                    hoffset : geom.i.halign [a`align; a`size]  % (-). reverse s[`x]`geom_limits;
                    if [width <= a`gap;  a[`gap]: 0];
                    cOffset : 0;
                    width   : adj`w;
                    if [a`collapse;
                        cOffset : adj[`w] % 2;
                        width   : 0.005];
                    points : (!) . flip (
                        (`x     ; (cOffset + xs + adj[`dx] + a[`gap] % 2) - hoffset);
                        (`y     ; Ms);
                        (`w     ; count[heights]#width);
                        (`h     ; heights);
                        (`colour; .z.m.axbits.or[o`alpha; o`fill]));
                    if[any 0 = count each points`x`y`h`w; : ()!()];
                    if [not h.null o`stroke; points,: o`stroke];
                    : (etable.el[etable.g.RECT] points;
                        acc);
                    }[; ; ; ; a; s]];
            } defaults;

        {[d; pt; t; lyr]
            a : h.extend[lyr`aes; d];
            : `data`distance`pt#geom.i.nearestLine[pt; lyr`scales; t; a`x; a`y; a`x; a`yend];
            } defaults;

        1#`x;
        
        `y`yend;
        
        {[d; pt1; pt2; t; a; s; lyr]
            geom.fromBound1D[`x; `x; pt1; pt2; t; geom.i.defSize[s`x] h.extend[a; d]; s; lyr]
            } defaults

        );

    }

// @fileOverview 
// Vertical line geometry
.z.m.gg.geom.vline:{[settings]
    defaults : h.extend[settings] h.extend[`size`minSize`maxSize!1 1 15] geom.i.DEFAULTS;
    
    : geom.ty.new (
    
        `vline;
        
        {[d;lyr]
            geom.i.validateAll["vline"; lyr; h.extend[lyr`aes; d]; `size`fill`alpha]
            } defaults;

        {[lyr] lyr`scales };

        {[d; th; t; a; s]
            if [not `y in key s; '.z.m.axlocalize.t`.gg_vlineStackError];
            a      : geom.i.defAes[th]  h.extend[a; d];
            pxs    : geom.i.pos1D [s`x; t; a`x; ::];
            if [0 = count pxs`idx; : ()];
            pys    : geom.i.pos1D [s`y; ([] y: .z.m.gg.scale.inverse[s`y] s[`y;`limits]); `y; ::];
            if [0 = count pys`idx; : ()];
            gs     : `x xasc ([]x: first pxs`ps; y: pys`ps; idx:til count pys`ps);
            : etable.el[etable.g.LINE] geom.i.linetable[t; gs; a; s]
            } defaults;

        {[pt; t; lyr] `geom`data`distance`pt!(`vline;();0w;pt) }; // Return no data

        enlist `x;
        enlist `y;
        
        {[pt1; pt2; t; a; s; lyr] geom.fromBound1D[`x; `x; pt1; pt2; t; a; s; lyr] }

        );


    }

.z.m.gg.geom.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.gg_vlineStackError; "vline apply error: must be stacked with a layer defining an Y axis");
        (`.gg_hlineStackError; "hline apply error: must be stacked with a layer defining an X axis");
        (`.gg_geomValidationError; "{flag} constant of type {found} not one of {expected}");
        (`.gg_polyNormError; "polygon geom normalization error: x and y lists should have equal length");
        (`.gg_domainDimError; "Unknown dimension for domain");
        (`.gg_posStackAggregateError; "Stacking requires there to be at most 1 value for each stack -- try aggregating first");
        (`.gg_geomErrorPre; "{geom} geom {aes} error: ");
        (`.gg_geomErrorNested; "{xOrY} must be nested numeric");
        (`.gg_geomStackErrorCName; "stack spec must be a column name");
        (`.gg_geomStackErrorExist; "stack column must appear in the table");
        (`.gg_geomStackErrorType; "stack column must be numeric");
        (`.gg_geomErrorMissingColumn; "column `{c}` not found");
        (`.gg_geomErrorValidation; "column type {found} not one of {expected} -- add a {flag} scale for {aes}");
        (`.gg_geomErrorZoom3D; "Unable to zoom in 3D");
        (`.gg_geomErrorStackNeg; "Stacking requires all positive aggregated values, but {axis} aggregates to negative")
        ))
.z.m.gg.geom.i.DEFAULTS:(!). flip (
    (`minFill; 0x0 sv 0x00,colour.Blue);
    (`maxFill; 0x0 sv 0x00,colour.Red);
    (`minColour; 0x0 sv 0x00,colour.Blue);
    (`maxColour; 0x0 sv 0x00,colour.Red);
    (`alpha; 0xff);
    (`minAlpha; 0x40);
    (`maxAlpha; 0xff);
    (`size; 1);
    (`minSize; 0.1);
    (`maxSize; 1);
    (`minStroke; 1);
    (`maxStroke; 4);
    (`strokewidth; 1);
    (`group; ::);
    (`angle; 0);
    (`minAngle; 0);
    (`maxAngle; 359);
    (`dashed; 0b);
    (`strokealpha; 0xff)
    )
.z.m.gg.geom.onLoad:{[]

    
    .z.m.axdatatype.create[ .z.M.gg.geom.ty; `label`validateF`extendF`applyF`rolloverF`xdomain`ydomain`zoomF; ()];
    
    }
.z.m.gg.geom.onLoad[];
system "d .z.m";

system "d .z.m.gg";
// @fileOverview 
// Return a list of columns in the stat that map to the data.
// @param layer {dict}
// @returns {symbol[]}
.z.m.gg.layer.colmap:{[layer]
    : $[not h.null layer`stat;
          $[99h ~ type layer[`stat]`colmap; key; ::] layer[`stat]`colmap;
          layer[`aes] (union) . layer[`geom]`xdomain`ydomain];
    }

// @fileOverview 
// Return a list of column transforms in the stat that map to the data.
// @param layer {dict}
// @returns {symbol[]}
.z.m.gg.layer.coltransform:{[layer]
    noop: {x!count[x]#(::)};
    : $[not h.null layer`stat;
          $[99h ~ type layer[`stat]`colmap; ::; noop] layer[`stat]`colmap;
          noop layer[`aes] (union) . layer[`geom]`xdomain`ydomain];
    }

// @fileOverview 
// Generate an etable for the layer geometry
//
// @param th {dict} theme
// @param lyr {dict} layer
//
// @returns {dict} etable
.z.m.gg.layer.geomtable:{[th; lyr]
    : geom.apply [th; lyr`geom; lyr`transformed; lyr`aes; lyr`scales];
    }

// @fileOverview Add default scales for any aes that are missing explicit scales
// @returns {dict} Updated layer
.z.m.gg.layer.i.addMissingScales:{[gg; lyr; filter; datakey]
    missing:    key[layer.i.SCALES] inter except[;key lyr`scales] {x where -11h = type each x} key lyr`aes;
    if [not (::) ~ filter;
        missing: filter inter missing];
    
    types:      h.metatype[lyr datakey] each lyr[`aes] missing;
    map:        " bg xhijefcspmdznuvts"!"ccccnnnnnnccnnnnnnnnn";
    candidates: (::),layer.i.SCALES[missing]@'map types;
    
    if [(`vbar ~ lyr . `geom`label) & `y in missing;
        candidates[k]: .z.m.gg.scale.extension[layer.i.EXTENSION] candidates k:1+missing?`y];
    if [(`hbar ~ lyr . `geom`label) & `x in missing;
        candidates[k]: .z.m.gg.scale.extension[layer.i.EXTENSION] candidates k:1+missing?`x];
    
    candidates: 1_candidates;
    
    { if [10h ~ type x; 'x] } each candidates;
    
    lyr[`scales]:
        {$[98h ~ type x; first x; x]} each
        lyr[`scales] , (missing!enlist each candidates) , enlist[`]!enlist(::);
    
    : (gg;lyr)
    }
 
// @fileOverview Apply a facet spec to a layer
// @param gg {dict} 
// @param lyr {dict} 
// @returns {(dict;dict)}
.z.m.gg.layer.i.applyFacet:{[gg;lyr]
    lyr[`transformed]: lyr`data;
    
    if [not (::) ~ lyr`facet;
        facet: lyr`facet;
        
        if [facet[0] in tbl.colnames lyr`transformed;
            match : $[0 <= type facet 1; (~\:); (=)];
            index : where match[tbl.column[lyr`transformed; facet 0]; facet 1];
            
            lyr[`transformed] : .z.m.gg.tbl.ty.with.index[index] lyr`transformed]];
    
    : (gg;lyr);
    }

// @fileOverview 
// Apply an initialization function to the layer. This
// allows the layer specification to be a function
// of it's data which could change due to drilldowns.
// @param node {dict} node of the layer in the spec
// @param gg {dict} 
// @param lyr {dict} layer
// @returns {dict} layer
.z.m.gg.layer.i.applyInit:{[node; gg; lyr]
    : (gg; lyr[`initF][gg; node; lyr]);
    }

// @fileOverview 
// If a stat specification exists, apply it to the data
// and replace the old data with the transformed data
// @param gg {dict} 
// @param lyr {dict}
// @returns {dict} updated layer
//
// @throws "stat error: x"
.z.m.gg.layer.i.applyStat:{[gg; lyr]
    
    if [not tbl.ty.transform tbl.box lyr`data;
        : (gg; lyr)];
    
    applyStat: {[l;a;f;ii]
        e:   {'.z.m.axlocalize.t[`.gg_layerStatErrorPre],h.asString x};
        gg:  a 0;
        lyr: a 1;
        
        if [not[(::) ~ lyr`facet] | (0 <> ii) | h.null lyr`linkid;
            : (gg; @[lyr;`transformed;:;@[f; lyr`transformed; e]])];
        
        k: (.z.m.axq.asString l;f);

        if [k in key gg`statcache;
            : (gg;  @[lyr;`transformed;:;gg[`statcache]k])];

        gg[`statcache;k]: lyr[`transformed]: @[f; lyr`transformed; e];

        : (gg; lyr)
        };
    
    : applyStat[lyr`linkid]/[(gg;lyr); stats; til count stats: raze layer.statF lyr];
    }

// @fileOverview 
// Initialize a single layer scale
// @param label {symbol} 
// @param g {dict} layer's geom
// @param scales {dict} 
// @param data {any[]} 
// @returns {dict} initialized scale
.z.m.gg.layer.i.initScale:{[label; g; scales; data]
    if [(`polygon ~ g`label) & (label in `x`y`z) & tbl.metatype[([]x:data);`x] in "XHIJEF"; /dnl
        data : raze data];
    
    : $[not label in key scales;
            ()!();
            [
                if [not 0 = count data; scale.validate[scales label] data];
                enlist[label]!enlist scale.init[scales label; data]]];
    }

// @fileOverview 
// Initialize all specified layer scales
//
// @param lyr {dict}
//
// @returns {dict} the scale-initialized layer
//
// @throws "column x in aes not found"
.z.m.gg.layer.i.initScales:{[gg;lyr]
    
    {[l;c]
        if [not c in tbl.colnames l`transformed;
            '.z.m.axlocalize.t(`.gg_layerErrorMissingAes;string c)]
        }[lyr] each value[lyr`aes] where -11h = type each value lyr`aes;
        
    scales  : enlist[`]!enlist(::);

    if [not 0 = count badscales:k where not .z.m.gg.scale.base.is each lyr[`scales]@/:k: key[lyr`scales] except `;
        '.z.m.axlocalize.t[`.gg_scaleErrorType],"," sv string each badscales];
    
    denylist : h.badpos[lyr`aes; lyr`scales] postable : layer.i.postable lyr;
    
    scales ,: (,/) {[lyr; dl; pos; sc]
        data: h.consolidateTypes pos[til[count pos] except dl] lyr[`aes] geom.domain[lyr`geom; sc];
        : layer.i.initScale[sc; lyr`geom; lyr`scales] raze data
        }[lyr; denylist; postable] each layer.scalesUsed[lyr] inter `x`y;
    
    scalesUsed : layer.scalesUsed lyr;
    
    if [any scales[scalesUsed inter `x`y]@\:`square;
        scales ,: layer.i.squareScales `x`y#scales];
    
    scales ,: (,/) {
        if[x . `scales,y,`initialized; : enlist[y]!enlist x . `scales,y];
        : enlist[y]!enlist scale.initBreaks @[;y] layer.i.initScale[y; x`geom; x`scales; tbl.column[x`transformed; x[`aes;y]]];
        }[lyr] each scalesUsed except ``x`y;

    lyr[`scales]: scales;
    
    if [all `x`y in\: key scales;
        scales : geom.extend[lyr`geom; lyr]];
    
    scales : h.extend[ k!{[s;x] scale.applyExtension scale.initBreaks s x }[scales] each k:layer.scalesUsed[lyr] inter `x`y ] scales;

    if [0 = tbl.nrecords lyr`transformed;
        if [`x in key lyr`scales; lyr[`scales;`x]: scale.breaks[()] lyr[`scales;`x]];
        if [`y in key lyr`scales; lyr[`scales;`y]: scale.breaks[()] lyr[`scales;`y]]];
    
    : (gg;
        @[lyr; `scales; :; h.extend[scales] h.extend[lyr`scales] enlist[`]!enlist(::)]);
    
    }

// @fileOverview 
// Set the origAes key on the layer to be the unmodified aesthetics,
// the set the real (used) aes to be the first entry in each mapping.
// @param gg {dict} 
// @param lyr {dict} layer
// @returns {dict} updated layer
.z.m.gg.layer.i.normalizeAes:{[gg; lyr]
    aes           : lyr`aes;
    lyr[`origAes] : aes;
    aes           : first each aes;
    lyr[`aes]     : aes;
    : (gg;lyr)
    }

// @fileOverview 
// Create a table of only the columns that are used in positioning
// @param lyr {dict}
// @returns {table}
.z.m.gg.layer.i.postable:{[lyr]
    syms    : lyr[`aes] raze lyr[`geom]`xdomain`ydomain;
    columns : tbl.column[lyr`transformed] each syms;
    : flip h.sanitize[syms] ! columns;
    }

// @fileOverview 
// Given a dictionary of x and y scales, extend the smaller of the ranges
// to the same range as the larger
// @param scales {dict} dictionary of x and y scales with `x`y keys (with geom_limits defined)
// @returns {dict} squared scales (`x`y keys)
.z.m.gg.layer.i.squareScales:{[scales]
    if [not (~). value scales@\:`label;  '.z.m.axlocalize.t`.gg_layerErrorSquareType];
    
    rs      : `x`y!.z.m.gg.h.safeRange each (scales`x`y)@\:`geom_limits;
    smaller : `x`y (>) . value rs;
    larger  : `y`x `y ~ smaller;
    diff    : (-) . rs (larger;smaller);
    hdiff   : diff % 2;
    scales[smaller;`geom_limits]: (-;+) .' (scales[smaller]`geom_limits) ,' hdiff;
    : scales;
    }

.z.m.gg.layer.i.toIndexTable:{[gg;lyr]
    lyr[`data]: tbl.box lyr`data;
    
    : (gg;lyr)
    }

// @fileOverview 
// Run a geometry validation against a layer
// @param lyr {dict} layer specification
// @returns {dict} layer unmodified
// @throws any error thrown by geometry validation
.z.m.gg.layer.i.validateGeom:{[gg;lyr]
    geom.validate[lyr`geom] lyr;
    : (gg;lyr)
    }

// @fileOverview 
// Initialize a layer. Stub the layer with default options, then apply
// any statistical transforms, and finally initialize scales on the 
// transformed data
// @param gg {dict} 
// @param node {dict} 
// @param lyr {dict}
// @returns {dict} updated GG
//
// @throws initialization errors
.z.m.gg.layer.init:{[gg; node; lyr]
    
    initF: {[gg; node; lyr]
        updated: layer.i.initScales .
            layer.i.validateGeom .
            layer.i.addMissingScales[;;::;`transformed] .
            layer.i.applyStat .
            layer.i.applyFacet .
            layer.i.applyInit[node] .
            layer.i.toIndexTable .
            layer.i.normalizeAes . (gg;lyr);
    
        : ty.with.spec[;updated 0] spec.updateLayers[ty.spec updated 0; enlist node; enlist updated 1; ::];
        };

    errorF : {[gg; errorCatcher; err]
        : ty.with.spec[;gg] spec.pluck[`defn;errorCatcher][`errorF][gg`spec; errorCatcher; err];
        };

    errorCatcher: spec.ancestorWhere[;gg`spec;node] {[entry]
        : h.and[entry; spec.ty.external.is; {not h.null x[`defn]`errorF}]
        };

    : $[not h.null errorCatcher;
        .[initF; (gg; node; lyr); errorF[gg;errorCatcher]];
        initF[gg; node; lyr]];

    }


// @fileOverview 
// Return whether or not the layer belongs to a link family
// @param layer {dict}
// @returns {boolean}
.z.m.gg.layer.isLinked:{[layer] not h.null layer`linkid }

// @fileOverview 
// Return whether or not the layer is a primary (has dependents)
// @param layer {dict}
// @returns {boolean}
.z.m.gg.layer.isPrimary:{[layer]
    : (h.null layer`secondaryid) and not h.null layer`primaryid
    }

// @fileOverview 
// Return whether or not the layer is a secondary (dependent)
// @param layer {dict}
// @returns {boolean}
.z.m.gg.layer.isSecondary:{[layer]
    : not h.null layer`secondaryid
    }

// @fileOverview 
// Determine what labels should be used for the axes and legends for the layer
//
// @param th {dict} 
// @param lyr {dict}
//
// @returns {dict} dictionary of preferred labels
.z.m.gg.layer.labels:{[th; lyr]
    : layer.i.LABELS!{[th; l; a; x] 
        i.sanitizeLabel[th] $[x in key l; l x; -11h ~ type a x; a x; `const__] 
        }[th; th`labels; lyr`aes] each layer.i.LABELS;
    }

// @fileOverview 
// Promote a dictionary description of a layer to a proper layer
// @param sp {dict} 
// @returns {dict}
.z.m.gg.layer.new:{[sp]
    : layer.stubDefaults sp
    }
 
// @see gg.spec.rotateLayer
.z.m.gg.layer.rotate:{[lyr]
    : spec.rotateLayer lyr;
    }

// @fileOverview 
// Return the keys of only scales that are also
// mapped to aesthetics
// @param lyr {dict}
// @returns {symbol[]}
.z.m.gg.layer.scalesUsed:{[lyr]
    : key[lyr`aes] inter key lyr`scales;
    }

// @fileOverview 
// Return the statistical transform function
// for the layer
// @param layer {dict}
// @returns {fn}
.z.m.gg.layer.statF:{[layer]
    : $[not h.null layer`stat; layer[`stat]`applyF; ::];
    }

// @fileOverview 
// Stub a layer with default options
//
// @param lyr {dict}
//
// @returns {dict} stubbed layer
.z.m.gg.layer.stubDefaults:{[lyr]
    defaults: (!) . flip (
        (`scales;       ()!());
        (`coord;        coords.rect);
        (`stat;         ::);
        (`origAes;      ());
        (`linkid;       ::);
        (`primaryid;    ::);
        (`secondaryid;  ::);
        (`initF;        {[gg;node;lyr] lyr });
        (`legends;      ());
        (`onclick;      ::);
        (`ondrilldown;  ::);
        (`zoomF;        ::);
        (`facet;        ::);
        (`share;        ()!());
        (`error;        ::));
   
    lyr: defaults , lyr;
        
    lyr[`i_shapetables]: ()!();
    : lyr;
    }

.z.m.gg.layer.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.gg_layerErrorMissingAes; "scale init error: column `{column}` in aesthetic mappings not found");
        (`.gg_scaleErrorType; "scale init error: the following mappings do not have valid scales: ");
        (`.gg_layerStatErrorPre; "stat transform error: ")))
.z.m.gg.layer.i.SCALES:(!) . flip (   
    (`x; (!) . flip (    
            ("c"; .z.m.gg.scale.categorical[]);   
            ("n"; .z.m.gg.scale.default); 
            (" "; .z.m.gg.scale.categorical[]) ));
    (`y; (!) . flip ( 
            ("c"; .z.m.gg.scale.categorical[]);
            ("n"; .z.m.gg.scale.default);
            (" "; .z.m.gg.scale.categorical[]) ));
    (`z; (!) . flip (    
            ("c"; .z.m.gg.scale.categorical[]);
            ("n"; .z.m.gg.scale.default);    
            (" "; .z.m.gg.scale.categorical[]) )); 
    (`alpha; (!) . flip (
            ("c"; "Cannot create default alpha scale for non-numeric data");
            ("n"; scale.alpha[50;255]);
            (" "; "Cannot create default alpha scale for non-numeric data") ));
    (`fill;  (!) . flip (
            ("c"; scale.colour.cat10);
            ("n"; scale.colour.gradient . colour`FireBrick`SteelBlue);
            (" "; scale.colour.cat10) ));
    (`colour;  (!) . flip (
            ("c"; scale.colour.cat10);
            ("n"; scale.colour.gradient . colour`FireBrick`SteelBlue);
            (" "; scale.colour.cat10) ));
    (`size; (!) . flip (
            ("c"; "Cannot create default size scale for non-numeric data");
            ("n"; scale.circle.area[5;100]);
            (" "; "Cannot create default size scale for non-numeric data") )) ); 
.z.m.gg.layer.i.LABELS:`x`y`z`fill`alpha`colour`size`stroke`angle`offsetx`offsety
.z.m.gg.layer.i.EXTENSION:0.03
system "d .z.m";

system "d .z.m.gg";
// @fileOverview 
// Check that all the dependency invariants are in place.
// If any invariant does not hold, error with an appropriate error message
// @param spec {table}
// @returns {table}
// @throws "A layer cannot be linked to other layers in a stack"
// @throws "Each primary layer must have a distinct primary ID"
// @throws "All secondary layers must have a primary layer with the same ID"
.z.m.gg.i.init.checkDeps:{[spec]
    {[spec; stackNode]
            
        children    : spec.stackLayers[spec; stackNode];
        layers      : spec.pluck[`defn] spec.every[spec.ty.layer] children;
        notNull     : {x where not h.null each x};
        links       : notNull h.atAll[`primaryid] layers;
        prims       : notNull h.atAll[`primaryid] layers;
        secondaries : notNull h.atAll[`secondaryid] layers;

        if [not count[links] ~ count distinct links; '.z.m.axlocalize.t`.gg_depErrorInStack];
        if [not count[prims] ~ count distinct prims; '.z.m.axlocalize.t`.gg_depErrorPrimaryID];
        if [not all secondaries in\: prims;          '.z.m.axlocalize.t`.gg_depErrorSecondaryID];
        
        }[spec] each spec.every[spec.ty.stack] spec;
    
    : spec;
    }

// @fileOverview 
// Initialize all external nodes within the specification tree
// @param gg {dict}
// @returns {table} initialized specification tree
.z.m.gg.i.init.externals:{[gg]
    
    sp   : gg`spec;
    nodes: nodes where spec.isDirty[sp] each nodes: spec.every[spec.ty.external] ty.spec gg;
    
    if[0 = count nodes; : gg];

    defns: @[;`recurse;:;1b]'[spec.pluck[`defn] nodes];
    nodes: spec.update[`defn; defns; nodes];
    
    initFs : h.atAll[`initF] spec.pluck[`defn;nodes];
    nodes  : initFs @' nodes;
    sp     : spec.updateNodes[sp] nodes;
    : ty.with.spec[sp] gg;
    }

// @fileOverview Initialize facet specs on layers under each facet node
// @param gg {dict} 
// @returns {dict}
.z.m.gg.i.init.facets:{[gg]
    sp: ty.spec gg;
    
    : ty.with.spec[;gg] i.init.i.applyTo[spec.ty.facet; sp; {[sp; facetNode]
            
            if [not spec.isDirty[sp] facetNode; : sp];
            
            column : facetNode . `item`entry`get;
            child  : .z.m.axds.tree.subtree[.z.m.axds.tree.find[first facetNode`children; sp]; sp];
            data   : @[;`data] spec.pluck[`defn] first spec.every[spec.ty.layer] child;
            
            if [spec.ty.theme.is spec.root[child] . `item`entry;
                firstChild: .z.m.axds.tree.find[;child] first .z.m.axds.tree.root[child]`children;
                if [spec.ty.title.is firstChild . `item`entry;
                    child: 2{.z.m.axds.tree.subtree[.z.m.axds.tree.find[;x] first .z.m.axds.tree.root[x]`children; x]}/child]];
            
            l : asc distinct tbl.column[data;column];
            
            if [100 < count l;
                '"Facetting requires less than 100 distinct values, found ",string count l];
            
            cells : {[id; column; val; sp]
                layers : spec.every[spec.ty.layer] sp;
                defns  : @[;`facet;:;(column;val)] each spec.pluck[`defn] layers;
                defns  : @[;`share;:;`x`y!("x";"y"),\:"-",id] each defns;
               
                : spec.with.theme[`title_padding`title_fontsize!(11; 14)] 
                    spec.with.title[val] spec.updateNodes[sp] spec.update[`defn; defns] layers;

                }[string rand 0ng; column]'[l; 1_count[l] .z.m.axds.dag.clone\child];
            
            : .z.m.axds.dag.join[.z.m.axds.tree.connect[facetNode; cells]] 
                sp {[sp;node] .z.m.axds.tree.remove.leaf[node;sp] }/.z.m.axds.tree.descendants[facetNode; sp];
            
            }];
    }
// @fileOverview 
// Add scales to a layer, preferring those given, and taking any non-overlapping
// scales from the layer itself
// @param s {dict} scales 
// @param l {dict} layer
// @returns {dict} updated layer
.z.m.gg.i.init.i.addScales:{[s; l]
    
    if [not `scales in key l;
        l[`scales]: ()!()];
    
    l: h.extend[enlist[`]!enlist (::)] l;
    s: h.extend[enlist[`]!enlist (::)] s;

    l[`scales] : h.extend[s] l`scales;
    
    : l;
    }

// @fileOverview 
// Apply a function to all stacks in a spec and return the resulting spec
// @param typ {dict} 
// @param spec {table} specification 
// @param f {fn} spec, stackNode -> spec
// @returns {table} updated specification
.z.m.gg.i.init.i.applyTo:{[typ; spec; f]
    : f/[spec;] spec.every [typ] spec;
    }


.z.m.gg.i.init.i.conformScales:{[sc; sublayers]

    subscales    : h.atAll[`scales] sublayers;
    subgeoms     : h.atAll[`geom]   sublayers;

    if[0=count scales: scale.reassemble subscales@\:sc;:()];
    scales : enlist[sc]!enlist scales;
    
    sublayers    : {[sc;x;y]x[`scales;sc]:y;x}[sc;;scales sc]'[sublayers];
    newScales    : geom.extend'[subgeoms; sublayers];
    
    lims : flip h.atAll[`geom_limits] h.atAll[sc] newScales;
    scales[sc;`geom_limits]: $[0 = count lims; scales[sc]`limits; (min raze first lims; max raze first 1_lims)];
  
    
    : enlist[sc]!enlist scale.applyExtension scale.initBreaks scales sc;
    
    }

// @fileOverview 
// Initialize stack scales based on sub layer scales
// @param leftlayers {dict[]} list of layers contained within the stack
// @param rightlayers {dict[]} list of layers contained within the stack
// @returns {dict} x and y scales to use for the stack
.z.m.gg.i.init.i.initSplitScales:{[leftlayers; rightlayers]

    if[0 = count[leftlayers] + count rightlayers; : `x`left`right!(::;::;::)];

    x : i.init.i.conformScales[`x;
        (`scales`geom`aes`transformed#/:leftlayers) ,
         `scales`geom`aes`transformed#/:rightlayers];
    
    lefty  : i.init.i.conformScales[`y;`scales`geom`aes`transformed#/:leftlayers];
    righty : i.init.i.conformScales[`y;`scales`geom`aes`transformed#/:rightlayers];
    scales : scales where count each scales: ($[count lefty; lefty`y; ()];$[count righty; righty`y; ()];x`x);
    if [any scales@\:`square;
        '.z.m.axlocalize.t`.gg_squareSplitError];
    
    : `x`left`right!(x;lefty;righty)
    }

.z.m.gg.i.init.i.stackScales:{[aes; sublayers]
    scales: raze i.init.i.conformScales[;sublayers] each aes;
    
    if [any scales@\:`square;
        scales : layer.i.squareScales scales];
    
    : $[not 99h ~ type scales; ()!(); scales]
    }

// @fileOverview 
// Initialize all dirty layers within the specification tree
// @param gg {dict}
// @returns {table} initialized specification tree
.z.m.gg.i.init.layers:{[gg]
    nodes: nodes where spec.isDirty[gg`spec] each nodes: spec.every[spec.ty.layer] ty.spec gg;
    : layer.init/[gg; nodes; spec.qualify[;ty.spec gg] each nodes];
    }

// @fileOverview 
// Apply primary data to associated secondaries in every stack
// @param gg {dict}
// @returns {table} updated specification
//
// @throws "A layer cannot be linked to other layers in a stack"
// @throws "Each primary layer must have a distinct primary ID"
// @throws "All secondary layers must have a primary layer with the same ID"
.z.m.gg.i.init.normDeps:{[gg]
    
    sp: ty.spec gg;
    
    i.init.checkDeps sp;
    
    : ty.with.spec[;gg] i.init.i.applyTo[spec.ty.stack; sp; {[sp; stackNode]
            if[not spec.isDirty[sp] stackNode; :sp];
            children : spec.stackLayers[sp; stackNode];
            layers   : spec.pluck[`defn] spec.every[spec.ty.layer] children;
            prims    : layers where layer.isPrimary each layers;
                                
            layerNodes : {[prims; layerNode; l]
                    
                    if [layer.isSecondary l;
                        primary : first prims where l[`secondaryid] = h.atAll[`primaryid] prims;
                        l[`data]: primary`data];
                    
                    component : spec.ty.component.with.entry[spec.ty.layer.new (::; l)] spec.node.item layerNode;
                    : spec.node.with.item[component] layerNode;
                
                    }[prims]'[children; layers];

            : {[sp; n] spec.modify[n; spec.node.item n; sp] }/[sp;] layerNodes;

            }];
    }

// @fileOverview Initialize shared scales for an entire spec
// For each layer tagged with the same share label for a scale,
// the scales will all be collected and a new scale determined in
// the same way scales are determined within stacks. This new
// set of scales will be set on every participating layer.
// @param gg {dict}
// @returns {table} updated gg spec
.z.m.gg.i.init.sharedScales:{[gg]
    
    sp: ty.spec gg;
   
    : ty.with.spec[;gg] sp {[sp; pair]
        if[all not dirty: spec.isDirty[sp] each .z.m.axds.tree.find[;sp] each pair 1; :sp];
        if[not all dirty;
            '"All layers within a share spec must either all be dirty, or all be clean"];
        : spec.i.sharedNodes[sp; pair 1;
            { x#i.init.i.stackScales[1#x] y }enlist last pair 0;
            i.init.i.addScales;
            {[state; node]
                post    : spec.ty.stack.post spec.ty.component.entry spec.node.item node;
                details : i.init.i.addScales[state] spec.ty.stack.get spec.ty.component.entry spec.node.item node;
                : spec.ty.component.with.entry[ spec.ty.stack.new (::; details; post) ] spec.node.item node
                }];
        }/flip(key;value)@\:spec.shareMap sp
    }

// @fileOverview 
// Initialize all splits within a specification tree
// @param gg {dict}
// @returns {table} updated specification tree
.z.m.gg.i.init.splits:{[gg]
    sp: ty.spec gg;
    
    : ty.with.spec[;gg] i.init.i.applyTo[spec.ty.split; sp; {[sp; splitNode]
            
            initF: {[sp; splitNode]
                if[not spec.isDirty[sp] splitNode; : sp];
               
                childNodes : spec.children[splitNode; sp];
                layerNodes : spec.stackLayers[sp] each childNodes;
                layers : spec.pluck[`defn] each spec.every[spec.ty.layer] each .z.m.axds.tree.descendants[;sp] each childNodes;

                defn        : i.init.i.initSplitScales . layers;
                defn[`coord]: $[
                    count layers 0; first[layers 0]`coord;
                    count layers 1; first[layers 1]`coord;
                        coords.rect];

                leftlayers    : i.init.i.addScales[raze defn`x`left] each layers 0;
                rightlayers   : i.init.i.addScales[raze defn`x`right] each layers 1;
                leftlayers    : @[;`coord;:;defn`coord] each leftlayers;
                rightlayers   : @[;`coord;:;defn`coord] each rightlayers;

                layerNodes : raze {[layerNode; layer]
                        component : spec.ty.component.with.entry[spec.ty.layer.new (::; layer)] spec.node.item layerNode;
                        : spec.node.with.item[component] layerNode;
                        }''[layerNodes; (leftlayers;rightlayers)];

                sp : spec.modify[splitNode; spec.ty.component.with.entry[spec.ty.split.new (::; defn)] spec.node.item splitNode; sp];

                : {[sp; n] spec.modify[n; spec.node.item n; sp] }/[sp;] layerNodes;
                };
            
            errorF : {[sp; node; err]
                : spec.pluck[`defn;node][`errorF][sp; node; err];
                };
            
            errorCatcher: spec.ancestorWhere[;sp;splitNode] {[entry]
                : h.and[entry; spec.ty.external.is; {not h.null x[`defn]`errorF}]
                };
            
            : $[not h.null errorCatcher;
                .[initF; (sp; splitNode); errorF[sp;errorCatcher]];
                initF[sp; splitNode]];
            
            }];
    }

// @fileOverview 
// Initialize all stacks within a specification tree
// @param gg {dict}
// @returns {table} updated specification tree
.z.m.gg.i.init.stacks:{[gg]
    sp: ty.spec gg;
    
    : ty.with.spec[;gg] i.init.i.applyTo[spec.ty.stack; sp; {[sp; stackNode]
            
            initF: {[sp; stackNode]
                if[not spec.isDirty[sp] stackNode; :sp];
            
                children : spec.stackLayers[sp; stackNode];
                layers   : spec.pluck[`defn] spec.every[spec.ty.layer] children;

                if[0 = count layers; : sp];

                newScales    : i.init.i.stackScales[`x`y`z] layers;
                newCoord     : first[layers]`coord;
                layers       : i.init.i.addScales[newScales] each layers;
                layers       : @[;`coord;:;newCoord] each layers;

                stackDetails          : enlist[`]!enlist (::);
                stackDetails[`scales] : newScales;
                stackDetails[`coord]  : newCoord;
                stackDetails[`theme]  : spec.theme[stackNode; sp];
                stackDetails[`theme] ,: #[;spec.theme[first children; sp]] (`axis_tick_length_x;
                                                                            `axis_tick_length_y;
                                                                            `axis_tick_length_z;
                                                                            `axis_tick_label_start_x;
                                                                            `axis_tick_label_start_y;
                                                                            `axis_tick_label_start_z;
                                                                            `axis_use_z);

                layerNodes : {[layerNode; layer]
                        component : spec.ty.component.with.entry[spec.ty.layer.new (::; layer)] spec.node.item layerNode;
                        : spec.node.with.item[component] layerNode;
                        }'[children; layers];

                post : spec.ty.stack.post spec.ty.component.entry spec.node.item stackNode;
                sp   : spec.modify[stackNode; spec.ty.component.with.entry[
                        spec.ty.stack.new (::; stackDetails; post)] spec.node.item stackNode; sp];

                : {[sp; n] spec.modify[n; spec.node.item n; sp] }/[sp;] layerNodes;
                };
            
            errorF : {[sp; node; err]
                : spec.pluck[`defn;node][`errorF][sp; node; err];
                };
            
            errorCatcher: spec.ancestorWhere[;sp;stackNode] {[entry]
                : h.and[entry; spec.ty.external.is; {not h.null x[`defn]`errorF}]
                };
            
            : $[not h.null errorCatcher;
                .[initF; (sp; stackNode); errorF[sp;errorCatcher]];
                initF[sp; stackNode]];

            }];
    }

.z.m.gg.i.init.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.gg_squareSplitError; "Square scales not supported within dual Y axes (splits)");
        (`.gg_depErrorInStack; "dep link error: a layer cannot be linked to other layers in a stack");
        (`.gg_depErrorPrimaryID; "dep primary error: each primary layer must have a distinct primary ID");
        (`.gg_depErrorSecondaryID; "dep secondary error: all secondary layers must have a primary layer with the same ID")))

system "d .z.m";

system "d .z.m.axskiaw";

.z.m.axskiaw.atextL:{[ptr; info; settings]
    
    settings[`x`y]: info[`coords][`applyF] settings`x`y;
    settings[`x`y]: i.stretchAndShift[info] . settings`x`y;
    settings[`pt] : settings`x`y;
    
    {[ptr;settings]    
        settings[`pt]: @[settings`pt;1;+[settings[`fontsize] % 3]];
        .z.m.axskia.rotate[ptr;] . settings[`angle] , settings `pt;
        .z.m.axskia.addTextLeftAnchor . enlist[ptr] , (0 0) , settings `text;
        .z.m.axskia.restore[ptr];
        }[ptr] each i.setupText[ptr; info; settings];
    
    : ptr;
    }
// @fileOverview
// Draw angled text left aligned
//
// @param ptr {byte[]} A skia canvas object
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param settings {dictionary} The geometry specification
// @returns {byte[]} skia pointer
// 
// @example
// Settings: {
//      `x            : Float
//      `y            : Float
//      `z            : Float
//      `angle        : Long
//      `text         : Symbol
//      `offsetx      : Float?
//      `offsety      : Float?
//      `strokewidth  : Float?
//      `fillcolour   : ByteArray?
//      `fontsize     : Long?
//      `fontfamily   : String? (eg, "sans-serif", "monospace", etc)
//      `bold         : Boolean?
//      `italic       : Boolean?
// }
.z.m.axskiaw.atextL3D:{[ptr;info;settings]
    
    settings[`pt]: info[`coords][`applyF] settings`x`y`z;
    settings[`pt]: i.stretchAndShift[info] . settings `pt;
    
    : {[ptr; settings]
        settings[`pt]: @[settings`pt;1;+[settings[`fontsize] % 3]];
        .z.m.axskia.rotate[ptr;] . settings[`angle] , settings `pt;
        .z.m.axskia.addTextLeftAnchor . enlist[ptr] , (0 0) , settings `text;
        .z.m.axskia.restore[ptr];
        : ptr;
        }/[ptr;i.setupText[ptr; info; settings]];
    }


.z.m.axskiaw.atextM:{[ptr; info; settings]
    
    settings[`x`y]: info[`coords][`applyF] settings`x`y;
    settings[`x`y]: i.stretchAndShift[info] . settings`x`y;
    settings[`pt] : settings`x`y;
    
    {[ptr;settings]    
        settings[`pt]: @[settings`pt;1;+[settings[`fontsize] % 3]];
        .z.m.axskia.rotate[ptr;] . settings[`angle] , settings `pt;
        .z.m.axskia.addTextMiddleAnchor . enlist[ptr] , (0 0) , settings `text;
        .z.m.axskia.restore[ptr];
        }[ptr] each i.setupText[ptr; info; settings];
    
    : ptr;
    }

// @fileOverview
// Draw angled text middle aligned
//
// @param ptr {byte[]} A skia canvas object
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param settings {dictionary} The geometry specification
// @returns {byte[]} skia pointer
// 
// @example
// Settings: {
//      `x            : Float
//      `y            : Float
//      `z            : Float
//      `text         : Symbol
//      `offsetx      : Float?
//      `offsety      : Float?
//      `angle        : Long
//      `strokewidth  : Float?
//      `fillcolour   : ByteArray?
//      `fontsize     : Long?
//      `fontfamily   : String? (eg, "sans-serif", "monospace", etc)
//      `bold         : Boolean?
//      `italic       : Boolean?
// }
.z.m.axskiaw.atextM3D:{[ptr;info;settings]
    
    settings[`pt]: info[`coords][`applyF] settings`x`y`z;
    settings[`pt]: i.stretchAndShift[info] . settings `pt;
    
    : {[info; ptr; settings]
        settings[`pt]: @[settings`pt;1;+[settings[`fontsize] % 3]];
        .z.m.axskia.rotate[ptr;] . settings[`angle] , settings `pt;
        .z.m.axskia.addTextMiddleAnchor . enlist[ptr] , (0 0) , settings `text;
        .z.m.axskia.restore[ptr];
        : ptr;
        }[info]/[ptr; i.setupText[ptr; info; settings]];
    }


.z.m.axskiaw.atextR:{[ptr; info; settings]
    
    settings[`x`y]: info[`coords][`applyF] settings`x`y;
    settings[`x`y]: i.stretchAndShift[info] . settings`x`y;
    settings[`pt] : settings`x`y;
    
    {[ptr;settings]    
        settings[`pt]: @[settings`pt;1;+[settings[`fontsize] % 3]];
        .z.m.axskia.rotate[ptr;] . settings[`angle] , settings `pt;
        .z.m.axskia.addTextRightAnchor . enlist[ptr] , (0 0) , settings `text;
        .z.m.axskia.restore[ptr];
        }[ptr] each i.setupText[ptr; info; settings];
    
    : ptr;
    }

// @fileOverview
// Draw angled text right aligned
//
// @param ptr {byte[]} A skia canvas object
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param settings {dictionary} The geometry specification
// @returns {byte[]} skia pointer
// 
// @example
// Settings: {
//      `x            : Float
//      `y            : Float
//      `z            : Float
//      `text         : Symbol
//      `offsetx      : Float?
//      `offsety      : Float?
//      `angle        : Long
//      `strokewidth  : Float?
//      `fillcolour   : ByteArray?
//      `fontsize     : Long?
//      `fontfamily   : String? (eg, "sans-serif", "monospace", etc)
//      `bold         : Boolean?
//      `italic       : Boolean?
// }
.z.m.axskiaw.atextR3D:{[ptr;info;settings]
    
    settings[`pt]: info[`coords][`applyF] settings`x`y`z;
    settings[`pt]: i.stretchAndShift[info] . settings `pt;
    
    : {[info; ptr; settings]
        settings[`pt]: @[settings`pt;1;+[settings[`fontsize] % 3]];
        .z.m.axskia.rotate[ptr;] . settings[`angle] , settings `pt;
        .z.m.axskia.addTextRightAnchor . enlist[ptr] , (0 0) , settings `text;
        .z.m.axskia.restore[ptr];
        : ptr;
        }[info]/[ptr;i.setupText[ptr; info; settings]];
    }


.z.m.axskiaw.circle:{[ptr; info; settings]

    settings[`x`y]: info[`coords][`applyF] settings`x`y;
    settings[`x`y]: i.stretchAndShift[info] . settings`x`y;
    
    .z.m.axskia.setFillColour[ptr;
        $[`fillcolour in key settings;  settings `fillcolour; Defaults `fillcolour]];    
    .z.m.axskia.addCircle . enlist[ptr] , settings[`x`y] , settings `radius;
    
    if [settings[`strokewidth] > 0;
        .z.m.axskia.setStrokeColour[ptr;
            $[not .z.m.axq.isNull settings`strokecolour; settings`strokecolour; Defaults`strokecolour]];
        .z.m.axskia.setStrokeWidth[ptr; settings`strokewidth];
        .z.m.axskia.addCircle . enlist[ptr] , settings[`x`y] , settings `radius];
    : ptr;
    }

// @fileOverview
// Draw a circle in 3D
//
// @param ptr {byte[]} A skia canvas object
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param settings {dictionary} The geometry specification
// @returns {byte[]} skia pointer
// 
// @example
// Settings: {
//      `x            : Float
//      `y            : Float
//      `z            : Float
//      `radius       : Float?
//      `strokewidth  : Float?
//      `strokecolour : ByteArray?
//      `fillcolour   : ByteArray?
// }
.z.m.axskiaw.circle3D:{[ptr;info;settings]
    settings[`x`y]: info[`coords][`applyF] settings`x`y`z;
    settings[`x`y]: i.stretchAndShift[info] . settings`x`y;
    
    .z.m.axskia.setFillColour[ptr;
        $[`fillcolour in key settings;  settings `fillcolour; Defaults `fillcolour]];    
    .z.m.axskia.addCircle . enlist[ptr] , settings[`x`y] , settings `radius;
    
    if [settings[`strokewidth] > 0;
        .z.m.axskia.setStrokeColour[ptr;
            $[not .z.m.axq.isNull settings`strokecolour; settings`strokecolour; Defaults`strokecolour]];
        .z.m.axskia.setStrokeWidth[ptr; settings`strokewidth];
        .z.m.axskia.addCircle . enlist[ptr] , settings[`x`y] , settings `radius];
    : ptr;
    }

.z.m.axskiaw.i.checkDistinct:{[t] 

    k: raze k where in[k: where 0 <= type each t;`radius`strokewidth];
    
    if [not i.REMOVE_DUPS;
        : t];
    constantRadius: all first[t`radius] = t`radius;
    constantStroke: all first[t`strokewidth] = t`strokewidth;
    opaque: all (0x0 sv 0xff000000) = .z.m.axbits.and[0x0 sv 0xff000000; t`fillcolour];
    
    : $[opaque & constantRadius & constantStroke;
        ((where not tt)#t) , flip $[fl;_[1#`c];::]
            0!?[;();`x`y!`x`y;$[fl: count[where tt] = count `x`y;enlist[`c]!enlist (first;`i);()]] // functional select by `x`y
            @[;`x`y;$["i"]] flip (where tt:0<type each t)#t; // Cast x and y to int
        opaque;
        ((where not tt)#t) , flip $[fl;_[1#`c];::]
            0!?[;();(`x`y,k)!`x`y,k;$[fl: count[where tt] = count `x`y,k;enlist[`c]!enlist (first;`i);()]] // functional select by (`x`y,k)
            @[;`x`y;$["i"]] flip (where tt:0<type each t)#t;   // Cast x and y to int
        t]
    }

.z.m.axskiaw.i.path:{[ptr;settings]
    if [2 >= count settings`xs;
        : ptr]; 
    
    .z.m.axskia.setFillColour[ptr;
        $[`fillcolour in key settings;  settings `fillcolour; Defaults `fillcolour]];   
    .z.m.axskia.addPath[ptr] . (first settings`close; "e"$settings`xs; "e"$settings`ys);
        
    if [settings[`strokewidth] > 0;
        .z.m.axskia.setStrokeColour[ptr;
            $[not .z.m.axq.isNull settings`strokecolour; settings `strokecolour; Defaults `strokecolour]];
        .z.m.axskia.setStrokeWidth[ptr; settings `strokewidth];
        .z.m.axskia.addPath[ptr] . (settings`close; "e"$settings`xs; "e"$settings`ys)];
    : ptr;
    }

// @fileOverview
// Draws rectangles on an axskia canvas
// @param ptr {long} skia ptr 
// @param settings {dict} rect specs
// @returns {long} skia ptr
.z.m.axskiaw.i.rect:{[ptr;settings]
    settings[`width]  : $[0 = settings`width;  0; 0.5 | settings`width];
    settings[`height] : $[0 = settings`height; 0; 0.5 | settings`height];
    
    if [`fillcolour in key settings;
        .z.m.axskia.setFillColour[ptr; settings `fillcolour];    
        .z.m.axskia.addRect . enlist[ptr] , settings `x`y`width`height];
    
    if [0 < settings `strokewidth;
        .z.m.axskia.setStrokeColour[ptr;
                $[not .z.m.axq.isNull settings`strokecolour; settings `strokecolour; Defaults `strokecolour]];
        .z.m.axskia.setStrokeWidth[ptr; settings `strokewidth];
        .z.m.axskia.addRect . enlist[ptr] , settings `x`y`width`height]; 
    : ptr;
    }



.z.m.axskiaw.i.setupText:{[ptr; info; settings]
    .z.m.axskia.setFillColour[ptr;
        $[`fillcolour in key settings;  settings `fillcolour; Defaults `fillcolour]];    
    .z.m.axskia.setFontSize[ptr;
        "j"$$[`fontsize in key settings; settings `fontsize; Defaults `fontsize]]; 
    .z.m.axskia.setStrokeWidth[ptr;
        $[`strokewidth in key settings; settings `strokewidth; Defaults `strokewidth]];    
    .z.m.axskia.setFontFace[ptr;
        $[not .z.m.axq.isNull settings`fontfamily; settings `fontfamily; Defaults `fontfamily];
        $[not .z.m.axq.isNull settings`bold; settings `bold; Defaults `bold];
        $[not .z.m.axq.isNull settings`italic; settings `italic; Defaults `italic]];      
    
    if [`offsetx in key settings; settings[`pt;0] +: settings`offsetx];
    if [`offsety in key settings; settings[`pt;1] +: settings`offsety];
    
    parts   : "\n" vs .z.m.gg.h.asString settings`text;
    offsets : settings[`fontsize] * til count parts;
    ys      : offsets + settings[`pt;1]; 
    
    : {[s;t;y] 
        s[`text]: `$t;
        s[`pt;1]: y; 
        : s
        }[settings]'[parts; ys];
    }

// @fileOverview
// Stretches 0-1 normalized 2D points to the canvas size without shifting
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param x {number|number[]} x coordinates
// @param y {number|number[]} y coordinates
// @returns {(number;number)|(number[];number[])}
.z.m.axskiaw.i.stretch:{[info;x;y]
    :(.z.m.gg.proj.proj[0 1; (0;info[`dims] 0)] x;
      .z.m.gg.proj.proj[0 1; (0;info[`dims] 1)] y);
    }
// @fileOverview
// Stretches and shifts 0-1 normalized 2D points to fit the canvas
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param x {number|number[]} x coordinates
// @param y {number|number[]} y coordinates
// @returns {(number;number)|(number[];number[])}
.z.m.axskiaw.i.stretchAndShift:{[info;x;y]
    :(info[`origin][0] +                  .z.m.gg.proj.proj[0 1; (0;info[`dims] 0)] x;
      info[`origin][1] + info[`dims][1] - .z.m.gg.proj.proj[0 1; (0;info[`dims] 1)] y);
    }

// @param ptr {byte[]} ptr A skia pointer
// 
// @fileOverview
// Render the image to a PNG.
//
// @returns {byte[]} The PNG image
.z.m.axskiaw.i.toPNG:{[ptr]
    : .z.m.axskia.toPNG ptr;
    }

.z.m.axskiaw.i.toRGB:{[ptr]
    : .z.m.axskia.toRGB ptr;
    }


.z.m.axskiaw.init:{[]
    }


.z.m.axskiaw.line:{[ptr; info; settings]

    settings[`x1`y1]: info[`coords][`applyF] settings`x1`y1;
    settings[`x1`y1]: i.stretchAndShift[info] . settings`x1`y1;
    settings[`x2`y2]: info[`coords][`applyF] settings`x2`y2;
    settings[`x2`y2]: i.stretchAndShift[info] . settings`x2`y2;
    
    .z.m.axskia.setStrokeColour[ptr;
        $[`strokecolour in key settings;  settings `strokecolour; Defaults `strokecolour]]; 
    .z.m.axskia.setFillColour[ptr;
        $[`fillcolour in key settings;  settings `fillcolour; Defaults `fillcolour]];   
    .z.m.axskia.setStrokeWidth[ptr;
        $[`strokewidth in key settings;  settings `strokewidth; Defaults `strokewidth]];     
    $[$[`dashed in key settings; settings`dashed; 0b];
        .z.m.axskia.addDashedLine[ptr] . "f"$settings[`x1`y1] , settings[`x2`y2] , 5 5f;
        .z.m.axskia.addLine[ptr] . settings[`x1`y1] , settings `x2`y2];
    : ptr;
    }

// @fileOverview
// Draw a 3D line
//
// @param ptr {byte[]} A skia canvas object
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param settings {dictionary} The geometry specification
// @returns {byte[]} skia pointer
// 
// @example
// Settings: {
//      `x1           : Float
//      `y1           : Float
//      `z1           : Float
//      `x2           : Float
//      `y2           : Float
//      `z2           : Float
//      `strokewidth  : Float?
//      `fillcolour   : ByteArray?
//      `dashed       : Bool?
// }
.z.m.axskiaw.line3D:{[ptr;info;settings]
    settings[`x1`y1]: info[`coords][`applyF] settings`x1`y1`z1;
    settings[`x1`y1]: i.stretchAndShift[info] . settings`x1`y1;
    settings[`x2`y2]: info[`coords][`applyF] settings`x2`y2`z2;
    settings[`x2`y2]: i.stretchAndShift[info] . settings`x2`y2;
    
    .z.m.axskia.setStrokeColour[ptr;
        $[`strokecolour in key settings;  settings `strokecolour; Defaults `strokecolour]]; 
    .z.m.axskia.setFillColour[ptr;
        $[`fillcolour in key settings;  settings `fillcolour; Defaults `fillcolour]];   
    .z.m.axskia.setStrokeWidth[ptr;
        $[`strokewidth in key settings;  settings `strokewidth; Defaults `strokewidth]];     
    $[$[`dashed in key settings; settings`dashed; 0b];
        .z.m.axskia.addDashedLine[ptr] . "f"$settings[`x1`y1] , settings[`x2`y2] , 5 5f;
        .z.m.axskia.addLine[ptr] . settings[`x1`y1] , settings `x2`y2];
    : ptr;
    }

// @private
// 
// @fileOverview 
// Add multiple points to the given skia
// 
// @param renderer {long} skia address 
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param t {dict} circle specifications
// @returns {byte[]} skia pointer
.z.m.axskiaw.multi.circle:{[renderer; info; t]
    : $[.z.m.axskia.SUPPORTS`multigeom;
        [
            t[`x`y]: info[`coords][`applyF] t`x`y;
            t[`x`y]: i.stretchAndShift[info] . t`x`y;

            t: i.checkDistinct t;
            t[`fillcolour]: .z.m.axskia.convertColour t`fillcolour;
            .z.m.axskia.multiFillCircle[renderer; "e"$t`x; "e"$t`y; raze "e"$t`radius; raze t`fillcolour];
            if [not all null t`strokewidth;
                t[`strokecolour]: .z.m.axskia.convertColour t`strokecolour;
                .z.m.axskia.multiStrokeCircle[renderer; "e"$t`x; "e"$t`y; raze "e"$t`radius; raze t`strokecolour; raze "e"$t`strokewidth]];
            renderer
            ];
        circle[;info]/[renderer;flip t]];
    }

// @fileOverview 
// Draw multiple circles
//
// @param ptr {byte[]} A skia canvas object
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param settings {dict}
// @returns {byte[]} skia pointer
//
// @see axskiaw.circle3D
.z.m.axskiaw.multi.circle3D:{[ptr; info; settings]
    : $[.z.m.axskia.SUPPORTS`multigeom;
        [
            settings[`x`y]: info[`coords][`applyF] settings`x`y`z;
            settings[`x`y]: i.stretchAndShift[info] . settings `x`y;

            settings: i.checkDistinct settings;
            settings[`fillcolour]: .z.m.axskia.convertColour settings`fillcolour;
            .z.m.axskia.multiFillCircle[ptr; "e"$settings`x; "e"$settings`y; 
                raze "e"$settings`radius; raze settings`fillcolour];
            if [not all null settings`strokewidth;
                settings[`strokecolour]: .z.m.axskia.convertColour settings`strokecolour;
                .z.m.axskia.multiStrokeCircle[ptr; "e"$settings`x; "e"$settings`y; raze "e"$settings`radius; raze settings`strokecolour; raze "e"$settings`strokewidth]];
            ptr
            ];
        circle3D[;info]/[ptr;flip settings]];
    }

// @private
// 
// @fileOverview 
// Add multiple lines to the given skia
// 
// @param renderer {long} skia address 
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param t {dict} line specifications
// @returns {byte[]} skia pointer
.z.m.axskiaw.multi.line:{[renderer; info; t]
    : $[.z.m.axskia.SUPPORTS`multigeom;
        [   
            t[`x1`y1]: info[`coords][`applyF] t`x1`y1;
            t[`x2`y2]: info[`coords][`applyF] t`x2`y2;
            t[`x1`y1]: i.stretchAndShift[info] . t`x1`y1;
            t[`x2`y2]: i.stretchAndShift[info] . t`x2`y2;
            t[`fillcolour]: .z.m.axskia.convertColour t`fillcolour;
            .debug.multiline:(renderer; "e"$t`x1; "e"$t`y1; "e"$t`x2; "e"$t`y2; raze t`fillcolour; raze "e"$t`strokewidth);
            .z.m.axskia.multiLine[renderer; "e"$t`x1; "e"$t`y1; "e"$t`x2; "e"$t`y2; raze t`fillcolour; raze "e"$t`strokewidth];
            renderer
            ];
        line[;info]/[renderer;update p1: flip (x1;y1), p2: flip (x2;y2) from flip t]];
    }

// @fileOverview 
// Draw multiple 3D lines
//
// @param ptr {byte[]} A skia canvas object
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param settings {dict}
// @returns {byte[]} skia pointer
//
// @see axskiaw.line3D
.z.m.axskiaw.multi.line3D:{[ptr; info; settings]
    : $[.z.m.axskia.SUPPORTS`multigeom;
        [   
            settings[`x1`y1]: info[`coords][`applyF] settings`x1`y1`z1;
            settings[`x2`y2]: info[`coords][`applyF] settings`x2`y2`z2;
            settings[`x1`y1]: i.stretchAndShift[info] . settings`x1`y1;
            settings[`x2`y2]: i.stretchAndShift[info] . settings`x2`y2;
            settings[`fillcolour]: .z.m.axskia.convertColour settings`fillcolour; 
            .z.m.axskia.multiLine[ptr; "e"$settings`x1; "e"$settings`y1; "e"$settings`x2; "e"$settings`y2; settings`fillcolour; "e"$settings`strokewidth];
            ptr
            ];
        line3D[;info]/[ptr;settings]];
    }

// @private
// 
// @fileOverview 
// Add multiple paths to the given skia
// 
// @param renderer {long} skia address 
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param t {table} path specifications
// @returns {byte[]} skia pointer
.z.m.axskiaw.multi.path:{[renderer; info; t]     
    : $[.z.m.axskia.SUPPORTS`multigeom;
        [   
            t[`xs`ys]: flip info[`coords][`applyF] each flip t`xs`ys;
            t[`xs`ys]: flip i.stretchAndShift[info] ./: flip t`xs`ys;
            t[`fillcolour]: .z.m.axskia.convertColour t`fillcolour; 
            .z.m.axskia.multiFillPath[renderer; raze t`close; "e"$t`xs; "e"$t`ys; raze t`fillcolour];
            if [not all null t`strokewidth;
                t[`strokecolour]: .z.m.axskia.convertColour t`strokecolour;
                .z.m.axskia.multiStrokePath[renderer; raze t`close; "e"$t`xs; "e"$t`ys; raze t`strokecolour; raze t`strokewidth]];
            renderer
            ];
        path[;info]/[renderer;t]];
    }

// @fileOverview 
// Draw multiple circles
//
// @param ptr {byte[]} A skia canvas object
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param settings {dict}
// @returns {byte[]} skia pointer
//
// @see axskiaw.path3D
.z.m.axskiaw.multi.path3D:{[ptr; info; settings]
    : $[.z.m.axskia.SUPPORTS`multigeom;
        [   
            settings[`xs`ys]: flip info[`coords][`applyF] each flip settings`xs`ys`zs;
            settings[`xs`ys]: flip i.stretchAndShift[info] ./: flip settings`xs`ys;
            settings[`fillcolour]: .z.m.axskia.convertColour settings`fillcolour; 
            .z.m.axskia.multiFillPath[ptr; settings`close; "e"$settings`xs; "e"$settings`ys; settings`fillcolour];
            if [not all null settings`strokewidth;
                settings[`strokecolour]: .z.m.axskia.convertColour settings`strokecolour;
                .z.m.axskia.multiStrokePath[ptr; settings`close; "e"$settings`xs; "e"$settings`ys; settings`strokecolour; settings`strokewidth]];
            ptr
            ];
        path3D[;info]/[ptr;settings]];
    }

// @private
// 
// @fileOverview 
// Add multiple rects to the given skia
// 
// @param renderer {long} skia address 
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param t {dict} rect specifications
// @returns {byte[]} skia pointer
.z.m.axskiaw.multi.rect:{[renderer; info; t]        
    if[not .z.m.axskia.SUPPORTS`multigeom; : rect[;info]/[renderer;flip t]];

    t[`x`y]          : info[`coords][`applyF]         t`x`y;
    t[`x`y]          : i.stretchAndShift[info] .      t`x`y;
    t[`width`height] : info[`coords][`applyF]         t`width`height;
    t[`width`height] : i.stretch[info]         .      t`width`height;
    t[`width]  : $[0 < type t `width; @[t `width ; ii; :; 0.5 | t[`width]  ii : where not t[`width]  = 0]; 0.5 | t `width];
    t[`height] : $[0 < type t `height; @[t `height ; ii; :; 0.5 | t[`height]  ii : where not t[`height]  = 0]; 0.5 | t `height];
    t[`fillcolour]   : .z.m.axskia.convertColour  t`fillcolour;
    .z.m.axskia.multiFillRect[renderer; "e"$t`x; "e"$t`y; raze "e"$t`width; raze "e"$t`height; raze t`fillcolour];
    if [not all null t`strokewidth;
        t[`strokecolour]: .z.m.axskia.convertColour t`strokecolour;
        .z.m.axskia.multiStrokeRect[renderer; "e"$t`x; "e"$t`y; raze "e"$t`width; raze "e"$t`height; raze t`strokecolour; raze t`strokewidth]];
    : renderer;

    }


.z.m.axskiaw.new:{[w;h]
    : .z.m.axskia.new[.z.m.axq.asLong w; .z.m.axq.asLong h];
    }
// @fileOverview 
// Draw a path along the line defined by the given x and y coordinate pairs
//
// @param ptr {byte[]} A skia canvas object
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param settings {dict}
// @returns {byte[]} skia pointer
//
// @example
// Settings : {
//      `xs           : FloatArray
//      `ys           : FloatArray
//      `close        : Boolean
//      `fillcolour   : ByteArray?
//      `strokewidth  : Float?
//      `strokecolour : ByteArray?
//  }
.z.m.axskiaw.path:{[ptr; info; settings]

    if [not count[settings`xs] ~ count settings`ys;
        '"xs and ys must be same length"];  /dnl
    
    settings[`xs`ys]: info[`coords][`applyF] settings`xs`ys;
    settings[`xs`ys]: i.stretchAndShift[info] .      settings`xs`ys;
    
    : i.path[ptr;settings];
    }

// @fileOverview
// Draw a 3D path
//
// @param ptr {byte[]} A skia canvas object
// @param info {dict} drawing info (canvas size, coords, scales, etc.)
// @param settings {dictionary} The geometry specification
// @returns {byte[]} skia pointer
// 
// @example
// Settings: {
//      `xs           : FloatArray
//      `ys           : FloatArray
//      `zs           : FloatArray
//      `close        : Boolean
//      `fillcolour   : ByteArray?
//      `strokewidth  : Float?
//      `strokecolour : ByteArray?
// }
.z.m.axskiaw.path3D:{[ptr;info;settings]
    if [(not count[settings`xs]~count settings`ys) or
         not count[settings`ys]~count settings`zs;
        '"xs,ys, and zs must all be the same length"];
    
    pts: `xs`ys!info[`coords][`applyF] settings`xs`ys`zs;
    pts[`xs`ys]: i.stretchAndShift[info] . pts`xs`ys;
    
    if [2 >= count pts`xs;
        : ptr];
    
    .z.m.axskia.setFillColour[ptr;
        $[`fillcolour in key settings;  settings `fillcolour; Defaults `fillcolour]];   
    .z.m.axskia.addPath[ptr] . (first settings`close; "e"$pts`xs; "e"$pts`ys);
    
    if [settings[`strokewidth] > 0;
        .z.m.axskia.setStrokeColour[ptr;
            $[not .z.m.axq.isNull settings`strokecolour; settings `strokecolour; Defaults `strokecolour]];
        .z.m.axskia.setStrokeWidth[ptr; settings `strokewidth];
        .z.m.axskia.addPath[ptr] . (first settings`close; "e"$pts`xs; "e"$pts`ys)];
    : ptr;
    }


.z.m.axskiaw.rect:{[ptr; info; settings]

    settings[`x`y]          : info[`coords][`applyF] settings`x`y;
    settings[`width`height] : info[`coords][`applyF] settings`width`height;
    settings[`x`y]          : i.stretchAndShift[info] .      settings`x`y;
    settings[`width`height] : i.stretch[info]         .      settings`width`height;
    
    : i.rect[ptr;settings];
    }


.z.m.axskiaw.remove:{[ptr] 
    }

// @fileOverview
// Render a canvas to an array of bytes
//
// @param o {byte[]} A skia canvas object
// @returns {byte[]} PNG image representation of skia
//
// @example 
// bytes : .z.m.axskiaw.render canvas
.z.m.axskiaw.render:{[o]
    : i.toPNG o;
    }


.z.m.axskiaw.square:{[ptr; info; settings]
    
    settings[`x`y] : info[`coords][`applyF] settings`x`y;
    settings[`x`y] : i.stretchAndShift[info] . settings`x`y;
    
    x : settings[`x] - settings`radius;
    y : settings[`y] - settings`radius;
    
    w: 2*settings`radius;
    h: 2*settings`radius;
    
    .z.m.axskiaw.i.rect[ptr] (`fillcolour`strokewidth`strokecolour!(.z.m.axskia.convertColour settings`fillcolour; settings`strokewidth; .z.m.axskia.convertColour settings`strokecolour)) , 
        `x`y`width`height!(x;y;w;h);
    
    : ptr;
    }


.z.m.axskiaw.triangle:{[ptr; info; settings]

    settings[`x`y]: info[`coords][`applyF] settings`x`y;
    settings[`x`y]: i.stretchAndShift[info] . settings`x`y;
    
    r: settings`radius;
    
    if [not `angle in key settings; settings[`angle]: 0];

    a:  r * -0.866 -0.5;
    b:  r *  0.866 -0.5;
    c:  r *  0.0    1.0;

    .z.m.axskia.rotate[ptr;] . settings `angle`x`y;
    
    .z.m.axskiaw.i.path[ptr] (`close`fillcolour`strokewidth`strokecolour!(1b; .z.m.axskia.convertColour settings`fillcolour; settings`strokewidth; .z.m.axskia.convertColour settings`strokecolour)) , 
        `xs`ys!flip (a;b;c);
    
    .z.m.axskia.restore ptr;
    
    : ptr;
    }

.z.m.axskiaw.i.REMOVE_DUPS:1b 
.z.m.axskiaw.LABEL:`skia
.z.m.axskiaw.Defaults:(!) . flip (
    (`fillcolour;   0x0 sv 0xff000000);
    (`strokecolour; 0x0 sv 0xff000000);
    (`fontsize;     10);
    (`strokewidth;  1);
    (`fontfamily;   "sans-serif");
    (`bold;         0b);
    (`italic;       0b)
    )
system "d .z.m";

system "d .z.m.gg";

.z.m.gg.theme.default:(!) . flip (
    
    (`dynamic_axes; 0b);
    (`labels; ()!());
    (`aspect_ratio; `fit);
    (`rollover_ignore; 0b);
    
    (`canvas_fill; 0x00000000);
    (`marker_default_fill; 0x555555);
    (`frame_background_fill; 0x00ffffff);
    
    (`plot_palette;         `cat10);
    (`plot_background_fill; 0xfff4f4f8);
    (`plot_background_stroke; 0x00000000);
    (`plot_margin_top;    5);
    (`plot_margin_bottom; 5);
    (`plot_margin_left;   5);
    (`plot_margin_right;  5);
    
    (`padding_left; 10);
    (`padding_top; 10);
    (`padding_right; 10);
    (`padding_bottom; 10);
    
    (`margin_top;    0);
    (`margin_bottom; 0);
    (`margin_left;   0);
    (`margin_right;  0);
    
    (`grid_majorLine_strokewidth; 2);
    (`grid_minorLine_strokewidth; 1);
    (`grid_majorLine_fill; 0xbaffffff);
    (`grid_minorLine_fill; 0xaaffffff);
    (`grid_style_x; `lines);
    (`grid_style_y; `lines);
    (`grid_style_z; `lines);
    
    (`axis_use_x; 1b);
    (`axis_use_y; 1b);
    (`axis_use_z; 1b);
    (`axis_line_fill; 0xffaaaaaa);
    (`axis_label_fill; 0xef111111);
    (`axis_tick_label_fill; 0xef6f6f6f);
    (`axis_line_strokewidth; 1);
    (`axis_label_stroke; 1);
    (`axis_label_fontsize; 12);
    (`axis_label_bold; 0b);
    (`axis_label_italic; 0b);
    (`axis_label_separators; 1#'"_-");
    (`axis_tick_length_x; 0.075);
    (`axis_tick_length_y; 0.05);
    (`axis_tick_label_start_x; 0.65);
    (`axis_tick_label_start_y; 0.75);
    (`axis_tick_label_angle_x; 0);
    (`axis_tick_label_angle_y; 0);
    (`axis_tick_label_angle_z; 0);
    (`axis_tick_label_anchor_x; `middle);
    (`axis_tick_label_anchor_y; `right);
    (`axis_tick_label_anchor_z; `right);
    (`axis_tick_label_strokewidth; 1);
    (`axis_tick_label_fontsize; 10);
    (`axis_tick_label_italic_x; 0b);
    (`axis_tick_label_bold_x; 0b);
    (`axis_tick_label_italic_y; 0b);
    (`axis_tick_label_bold_y; 0b);
    (`axis_tick_label_italic_z; 0b);
    (`axis_tick_label_bold_z; 0b);
    (`axis_size_x; 40);
    (`axis_size_y; 60);
    (`axis_offset; 5);
    
    (`legend_use; 1b);
    (`legend_header_background_fill; 0xffe2e2e2);
    (`legend_header_background_stroke; 0x00000000);
    (`legend_header_height; 16);
    (`legend_height; 120);
    (`legend_width; 65);
    (`legend_padding_top; 4);
    (`legend_padding_right; 10);
    (`legend_padding_left; 10);
    (`legend_padding_bottom; 4);
    (`legend_background_fill; 0x00000000);
    (`legend_title_size; 16);
    (`legend_background_stroke; 0x00000000);
    (`legend_offset; 5);
    (`legend_tick_length; 0.1);
    (`legend_tick_label_start; 0.75);
    (`legend_title_bold; 0b);
    (`legend_title_italic; 0b);
    
    (`title_fill; 0xef111111);
    (`title_background_fill; 0x00000000);
    (`title_padding; 22);
    (`title_fontsize; 18);
    (`title_strokewidth; 1);
    (`title_bold; 0b);
    (`title_italic; 0b);
    (`title_x_start; .5);
    (`title_x_offset; 0);
    (`title_anchor; `middle);
    
    (`gradient_dark;  .z.m.gg.colour.SteelBlue);
    (`gradient_light; .z.m.gg.colour.FireBrick)
    
    )
.z.m.gg.theme.white:theme.default , ``canvas_fill`plot_background_fill`plot_background_stroke`grid_style_x`grid_style_y`axis_offset`axis_line_fill!(::;0xffffffff;0xffffffff;0xff444444;`none;`none;0;0xff444444)

.z.m.gg.theme.transparent:theme.default , (!) . flip (
    
    (`marker_default_fill; 0x000000);
    
    (`aspect_ratio; `fit);
    
    (`labels; ()!());
    
    (`padding_left; 10);
    (`padding_top; 10);
    (`padding_right; 10);
    (`padding_bottom; 10);
    
    (`grid_majorLine_strokewidth; 2);
    (`grid_majorLine_fill; 0xbadfdfdf);
    (`grid_minorLine_strokewidth; 1);
    (`grid_minorLine_fill; 0xaae5e5e5);
    (`grid_style_x; `none);
    (`grid_style_y; `none);

    (`axis_line_strokewidth; 1);
    (`axis_line_fill; 0xff444444);
    (`axis_label_stroke; 1);
    (`axis_label_fontsize; 12);
    (`axis_label_fill; 0xef111111);
    (`axis_tick_label_angle_x; 0);
    (`axis_tick_label_angle_y; 0);
    (`axis_tick_label_anchor_x; `middle);
    (`axis_tick_label_anchor_y; `right);
    (`axis_tick_label_strokewidth; 1);
    (`axis_tick_label_fill; 0xef6f6f6f);
    (`axis_tick_label_fontsize; 10);
    (`axis_use_x; 1b);
    (`axis_use_y; 1b);
    (`axis_offset; 5);
    
    (`plot_background_fill; 0x00000000);
    (`plot_background_stroke; 0x00000000);
    
    (`legend_header_background_fill; 0xffe2e2e2);
    (`legend_header_background_stroke; 0x00000000);
    (`legend_header_height; 16);
    (`legend_height; 120);
    (`legend_use; 1b);
    (`legend_width; 65);
    (`legend_padding_top; 4);
    (`legend_padding_right; 10);
    (`legend_padding_left; 10);
    (`legend_padding_bottom; 4);
    (`legend_background_fill; 0x00000000);
    (`legend_title_size; 16);
    (`legend_background_stroke; 0x00000000);
    (`legend_offset; 5);
    
    (`title_padding; 22);
    (`title_fontsize; 18);
    (`title_strokewidth; 1);
    (`title_fill; 0xef111111);
    (`title_background_fill; 0x00000000);
    
    (`canvas_fill; 0x00000000);
    
    (`gradient_dark; .z.m.gg.colour.Navy);
    (`gradient_light; .z.m.gg.colour.Red)
    
    
    )
.z.m.gg.theme.m.bordered:`axis_offset`axis_line_fill`axis_tick_length_x`axis_tick_length_y`plot_background_stroke!(
        0; 0xffcccccc; 0.1; 0.1; 0xff888888)

.z.m.gg.theme.light:theme.default , (!) . flip (
    
    (`marker_default_fill; 0x222222);
    
    (`aspect_ratio; `fit);
    
    (`labels; ()!());
    
    (`padding_left; 10);
    (`padding_top; 10);
    (`padding_right; 10);
    (`padding_bottom; 10);
    
    (`grid_majorLine_strokewidth; 2);
    (`grid_majorLine_fill; 0xaae2e2e2);
    (`grid_minorLine_strokewidth; 1);
    (`grid_minorLine_fill; 0xaaf0f0f0);
    (`grid_style_x; `lines);
    (`grid_style_y; `lines);

    (`axis_line_strokewidth; 1);
    (`axis_line_fill; 0xff999999);
    (`axis_label_stroke; 1);
    (`axis_label_fontsize; 12);
    (`axis_label_fill; 0xff333333);
    (`axis_tick_label_angle_x; 0);
    (`axis_tick_label_angle_y; 0);
    (`axis_tick_label_anchor_x; `middle);
    (`axis_tick_label_anchor_y; `right);
    (`axis_tick_label_strokewidth; 1);
    (`axis_tick_label_fill; 0xef6f6f6f);
    (`axis_tick_label_fontsize; 10);
    (`axis_size_x; 60);
    (`axis_size_y; 60);
    (`axis_use_x; 1b);
    (`axis_use_y; 1b);
    (`axis_offset; 5);
    
    (`plot_background_fill; 0xffffffff);
    (`plot_background_stroke; 0x00000000);
    
    (`legend_header_background_fill; 0x00000000);
    (`legend_header_background_stroke; 0x00000000);
    (`legend_header_height; 16);
    (`legend_height; 120);
    (`legend_use; 1b);
    (`legend_width; 65);
    (`legend_padding_top; 4);
    (`legend_padding_right; 10);
    (`legend_padding_left; 10);
    (`legend_padding_bottom; 4);
    (`legend_background_fill; 0xfffffff);
    (`legend_background_stroke; 0x00000000);
    (`legend_title_size; 16);
    (`legend_offset; 5);
    
    (`title_padding; 22);
    (`title_fontsize; 18);
    (`title_strokewidth; 1);
    (`title_fill; 0xef111111);
    (`title_background_fill; 0x00000000);
    
    (`canvas_fill; 0xffffffff)
    
    )

.z.m.gg.theme.i.SETTINGS:(
    `marker_default_fill;
    
    `labels;
    `padding_left;
    `padding_top;
    `padding_right;
    `padding_bottom;
    
    `rollover_ignore;
    
    `grid_majorLine_strokewidth;
    `grid_majorLine_fill;
    `grid_minorLine_strokewidth;
    `grid_minorLine_fill;
    `grid_style_x;
    `grid_style_y;

    `axis_line_strokewidth;
    `axis_line_fill;
    `axis_label_stroke;
    `axis_label_fontsize;
    `axis_label_fill;
    `axis_tick_length_x;
    `axis_tick_length_y;
    `axis_tick_label_angle_x;
    `axis_tick_label_angle_y;
    `axis_tick_label_start_x;
    `axis_tick_label_start_y;
    `axis_tick_label_anchor_x;
    `axis_tick_label_anchor_y;
    `axis_tick_label_strokewidth;
    `axis_tick_label_fill;
    `axis_tick_label_fontsize;
    `axis_size_x;
    `axis_size_y;
    `axis_use_x;
    `axis_use_y;
    `axis_offset;
    
    `plot_background_fill;
    `plot_background_stroke;
    
    `legend_header_background_fill;
    `legend_header_background_stroke;
    `legend_header_height;
    `legend_height;
    `legend_use;
    `legend_width;
    `legend_padding_top;
    `legend_padding_right;
    `legend_padding_left;
    `legend_padding_bottom;
    `legend_background_fill;
    `legend_background_stroke;
    `legend_title_size;
    `legend_offset;
    `legend_tick_length;
    `legend_tick_label_start;
    
    `title_padding;
    `title_fontsize;
    `title_strokewidth;
    `title_fill;
    `title_background_fill;
    
    `canvas_fill
    
    )
.z.m.gg.theme.deepblue:.z.m.gg.theme.default , (!) . flip (
    (`marker_default_fill; 0x5decf4);
    (`plot_background_fill; 0xff162534);
    (`grid_majorLine_fill;0xff1A283B);
    (`grid_minorLine_fill;0x00000000);
    (`canvas_fill; 0xff152535);
    (`axis_label_fill; 0xffadb1b6);
    (`axis_tick_label_fill; 0xff626c78);
    (`axis_tick_length_x; 0);
    (`axis_tick_length_y; 0);
    (`axis_line_fill; 0xff827c88);
    (`title_fill; 0xffadb1b6);
    (`legend_header_background_fill; 0x00e2e2e2)
    )

.z.m.gg.theme.dark:theme.default , (!) . flip (
    
    (`marker_default_fill; 0x909090);
    (`marker_default_colour; 0x505050);
    
    (`aspect_ratio; `fit);
    
    (`labels; ()!());
    
    (`padding_left; 10);
    (`padding_top; 10);
    (`padding_right; 10);
    (`padding_bottom; 10);
     
    (`grid_majorLine_strokewidth; 2);
    (`grid_majorLine_fill; 0xaa313131);
    (`grid_minorLine_strokewidth; 1);
    (`grid_minorLine_fill; 0xaa282828);
    (`grid_style_x; `lines);
    (`grid_style_y; `lines);

    (`axis_line_strokewidth; 1);
    (`axis_line_fill; 0xff515151);
    (`axis_label_stroke; 1);
    (`axis_label_fontsize; 12);
    (`axis_label_fill; 0xffbababa);
    (`axis_tick_label_angle_x; 0);
    (`axis_tick_label_angle_y; 0);
    (`axis_tick_label_anchor_x; `middle);
    (`axis_tick_label_anchor_y; `right);
    (`axis_tick_label_strokewidth; 1);
    (`axis_tick_label_fill; 0xffaaaaaa);
    (`axis_tick_label_fontsize; 10);
    (`axis_use_x; 1b);
    (`axis_use_y; 1b);
    (`axis_offset; 5);
    
    (`plot_background_fill; 0xff222222);
    (`plot_background_stroke; 0x00000000);
    
    (`legend_header_background_fill; 0xff222222);
    (`legend_header_background_stroke; 0x00000000);
    (`legend_header_height; 16);
    (`legend_height; 120);
    (`legend_use; 1b);
    (`legend_width; 65);
    (`legend_padding_top; 4);
    (`legend_padding_right; 10);
    (`legend_padding_left; 10);
    (`legend_padding_bottom; 4);
    (`legend_background_fill; 0x00282828);
    (`legend_background_stroke; 0x00000000);
    (`legend_title_size; 16);
    (`legend_offset; 5);
    
    (`title_padding; 22);
    (`title_fontsize; 18);
    (`title_strokewidth; 1);
    (`title_fill; 0xffaaaaaa);
    (`title_background_fill; 0x00000000);
    
    (`canvas_fill; 0xff303030);
    
    (`gradient_dark; .z.m.gg.colour.LightBlue);
    (`gradient_light; .z.m.gg.colour.Red)
    
    )

.z.m.gg.theme.cleanblue:.z.m.gg.theme.default , (!) . flip (
    (`dynamic_axes; 1b);
    (`marker_default_fill; 0x1e559f);
    (`labels; ()!());
    (`aspect_ratio; `fill);
    (`rollover_ignore; 0b);
    (`padding_left; 20f);
    (`padding_top; 20f);
    (`padding_right; 20f);
    (`padding_bottom; 20f);
    (`margin_top; 0f);
    (`margin_bottom; 0f);
    (`margin_left; 0f);
    (`margin_right; 0f);
    (`grid_majorLine_strokewidth; 2f);
    (`grid_majorLine_fill; 0xffffff);
    (`grid_minorLine_strokewidth; 1f);
    (`grid_minorLine_fill; 0xffffff);
    (`grid_style_x; `lines);
    (`grid_style_y; `lines);
    (`grid_style_z; `lines);
    (`axis_line_strokewidth; 1f);
    (`axis_line_fill; 0xffffff);
    (`axis_label_stroke; 1f);
    (`axis_label_fontsize; 12);
    (`axis_label_fill; 0x212121);
    (`axis_label_bold; 0b);
    (`axis_label_italic; 0b);
    (`axis_tick_length_x; 0.1);
    (`axis_tick_length_y; 0.06);
    (`axis_tick_label_start_x; 0.75);
    (`axis_tick_label_start_y; 0.85);
    (`axis_tick_label_angle_x; 0f);
    (`axis_tick_label_angle_y; 0f);
    (`axis_tick_label_angle_z; 0f);
    (`axis_tick_label_anchor_x; `middle);
    (`axis_tick_label_anchor_y; `right);
    (`axis_tick_label_anchor_z; `right);
    (`axis_tick_label_strokewidth; 1f);
    (`axis_tick_label_fill; 0x212121);
    (`axis_tick_label_fontsize; 10);
    (`axis_tick_label_italic_y; 0b);
    (`axis_tick_label_bold_y; 0b);
    (`axis_tick_label_italic_x; 0b);
    (`axis_tick_label_bold_x; 0b);
    (`axis_tick_label_italic_z; 0b);
    (`axis_tick_label_bold_z; 0b);
    (`axis_size_x; 60f);
    (`axis_size_y; 100f);
    (`axis_use_x; 1b);
    (`axis_use_y; 1b);
    (`axis_use_z; 1b);
    (`axis_offset; 0f);
    (`plot_background_fill; 0xebebeb);
    (`plot_background_stroke; 0xffffff);
    (`legend_header_background_fill; 0xffffff);
    (`legend_header_background_stroke; 0xffffff);
    (`legend_header_height; 16f);
    (`legend_height; 120f);
    (`legend_use; 1b);
    (`legend_width; 65f);
    (`legend_padding_top; 4f);
    (`legend_padding_right; 10f);
    (`legend_padding_left; 10f);
    (`legend_padding_bottom; 4f);
    (`legend_background_fill; 0xffffff);
    (`legend_title_size; 16f);
    (`legend_background_stroke; 0x00ffffff);
    (`legend_offset; 5f);
    (`legend_tick_length; 0.1);
    (`legend_tick_label_start; 0.75);
    (`legend_title_bold; 1b);
    (`legend_title_italic; 1b);
    (`title_padding; 12f);
    (`title_fontsize; 14);
    (`title_strokewidth; 1f);
    (`title_fill; 0xaaaaaa);
    (`title_background_fill; 0xffffff);
    (`title_bold; 1b);
    (`title_italic; 0b);
    (`canvas_fill; 0xffffff);
    (`gradient_dark; 0xadd8e6);
    (`gradient_light; 0xff0000);
    (`marker_default_colour; 0x505050)
    )

.z.m.gg.theme.clean:.z.m.gg.theme.default , (!) . flip (
    (`canvas_fill; 0xffffffff);
    (`plot_background_fill; 0xffffffff);
    (`grid_majorLine_fill; 0x4da0a0a0);
    (`grid_majorLine_strokewidth; 1);
    (`grid_minorLine_fill; 0x00000000);
    (`axis_line_fill; 0x00000000);
    (`axis_tick_label_fill; 0xff444444);
    (`axis_label_fill; 0xff222222);
    (`marker_default_fill; 0x4682b4);
    (`title_fill; 0xff222222);
    (`legend_header_background_fill; 0x00000000);
    (`title_fontsize; 15);
	(`axis_tick_length_x; 0);
	(`axis_tick_length_y; 0)
    );

.z.m.gg.theme.blank:.z.m.gg.theme.default , ``axis_use_x`axis_use_y`grid_style_x`grid_style_y`plot_background_fill!(::;0b;0b;`none;`none;0x00000000)
system "d .z.m";

system "d .z.m.gg";
// @fileOverview
// Constructs drawing info for renderer
// @returns {dict}
.z.m.gg.i.draw.i.info:{[cvs; node; coords]
    component: spec.node.item node;
    origin: spec.ty.component.origin[component] - spec.ty.component.origin .z.m.axds.tree.node.item cvs;
    dims: (spec.ty.component.w;spec.ty.component.h) @\: component;
    : `origin`dims`coords`id!(origin;dims;coords;node`id);
    }

// @fileOverview 
// Draw multiple angled texts
// @param g {symbol} the specific angled text to draw 
// @param renderer {dict} draw api implementation 
// @param renderObj {any} 
// @param cvs {dict} canvas node
// @param node {dict} specification node to draw within 
// @param s {dict} settings of the text element 
.z.m.gg.i.draw.i.multi.atext:{[g; renderer; renderObj; cvs; node; coords; s]
    
    if [0 = count s;
        : renderObj];
    
    s:   etable.qualify s;
    
    texts : ([] x          : s`x;
                y          : s`y;
                text       : s`text;
                angle      : s`angle;
                fontsize   : s`fontsize;
                fillcolour : s`colour);
    
    texts[`bold]:       $[`bold in cols s;       s`bold;      etable.defaults`bold];
    texts[`italic]:     $[`italic in cols s;     s`italic;    etable.defaults`italic];
    texts[`offsetx]:    $[`offsetx in cols s;    0^s`offsetx; etable.defaults`offsetx];
    texts[`offsety]:    $[`offsety in cols s;    0^s`offsety; etable.defaults`offsety];
    texts[`fontfamily]: $[`fontfamily in cols s;
        s`fontfamily; (count texts)#enlist etable.defaults`fontfamily];
    
    info: i.draw.i.info[cvs;node;coords];
    
    : renderer[g;;info;]/[renderObj;texts];
    
    }

// @fileOverview 
// Draw multiple angled texts
// @param g {symbol} the specific angled text to draw 
// @param renderer {dict} draw api implementation 
// @param renderObj {any} 
// @param cvs {dict} canvas node
// @param node {dict} specification node to draw within 
// @param coords {dict} coordinate system
// @param s {dict} settings of the text element 
.z.m.gg.i.draw.i.multi.atext3D:{[g; renderer; renderObj; cvs; node; coords; s]
    if [0 = count s;
        : renderObj];
    
    s: etable.qualify s;
    
    texts: ([]  x          : s`x;
                y          : s`y;
                z          : s`z;
                text       : s`text;
                angle      : s`angle;
                fontsize   : s`fontsize;
                fillcolour : s`colour);
    
    texts[`bold]:       $[`bold in cols s;       s`bold;      etable.defaults`bold];
    texts[`italic]:     $[`italic in cols s;     s`italic;    etable.defaults`italic];
    texts[`offsetx]:    $[`offsetx in cols s;    0^s`offsetx; etable.defaults`offsetx];
    texts[`offsety]:    $[`offsety in cols s;    0^s`offsety; etable.defaults`offsety];
    texts[`fontfamily]: $[`fontfamily in cols s;
        s`fontfamily; (count texts)#enlist etable.defaults`fontfamily];
    
    info: i.draw.i.info[cvs;node;coords];
    
    : renderer[g;;info;]/[renderObj;texts];
    }
// @fileOverview 
// Draw multiple point geometries
// @param shape {symbol} shape to draw
// @param renderer {dict} draw api implementation
// @param renderObj {any} 
// @param cvs {dict} canvas node
// @param node {dict} specification node to draw within 
// @param s {dict} settings of the point element 
.z.m.gg.i.draw.i.multi.i.point:{[shape; renderer; renderObj; cvs; node; coords; s]
    if [0 = count s;
         : renderObj];
    
    s: etable.qualify s;
    
    info: i.draw.i.info[cvs;node;coords];
    
    : {[shape;renderer;info;renderObj;s]

        t : ([] x          : s`x;
                y          : s`y;
                fillcolour : s`colour;
                radius     : s`size);

        if [shape ~ `triangle;
            t[`angle]: 0^s`angle];

        t[`strokewidth]:  $[`strokewidth  in cols s; s`strokewidth;  etable.defaults`strokewidth];
        t[`strokecolour]: $[`strokecolour in cols s; s`strokecolour; etable.defaults`strokecolour];

        : renderer[shape;;info;]/[renderObj;t];
        
        }[shape;renderer;info]/[renderObj;s]
    }

// @fileOverview 
// Draw multiple lines line
// @param renderer {dict} draw api implementation
// @param renderObj {any} 
// @param cvs {dict} canvas node
// @param node {dict} specification node to draw within 
// @param s {dict} settings of the line element 
.z.m.gg.i.draw.i.multi.line:{[renderer; renderObj; cvs; node; coords; s]
    
    if [0 = count s;
        : renderObj];
    
    s:   etable.qualify s;
    
    info: i.draw.i.info[cvs;node;coords];
    
    : {[renderer;info;renderObj;s]
        lines: `x1`y1`x2`y2`fillcolour`strokewidth!s`x1`y1`x2`y2`colour`size;
        lines: @[lines;`x1`y1`x2`y2;raze]; // Patch for table records

        lines[`dashed]: $[`dashed in key s; s`dashed; etable.defaults`dashed];

        : $[h.and[renderer; '[`multi in;key]; '[`line in;{key x`multi}]];
               renderer[`multi][`line][renderObj; info; lines];
               renderer[`line][;info]/[renderObj; lines]];

        }[renderer;info]/[renderObj;s];
    }
// @fileOverview 
// Draw multiple 3D lines
// @param renderer {dict} draw api implementation 
// @param renderObj {any} 
// @param cvs {dict} canvas node
// @param node {dict} specification node to draw within 
// @param coords {dict} coordinate system
// @param s {dict} settings of the 3D lines 
.z.m.gg.i.draw.i.multi.line3D:{[renderer; renderObj; cvs; node; coords; s]
    if [0 = count s;
        : renderObj];
    
    s: etable.qualify s;
    
    lines: `x1`y1`z1`x2`y2`z2#s;
    
    lines[`fillcolour]  : s`colour;
    lines[`strokewidth] : s`size;
    
    lines[`dashed]: $[`dashed in cols s; s`dashed; etable.defaults`dashed];
    
    
    info: i.draw.i.info[cvs;node;coords];
    
    : $[h.and[renderer; '[`multi in;key]; '[`line3D in;{key x`multi}]];
            renderer[`multi][`line3D][renderObj; info; lines];
            renderer[`line3D][;info]/[renderObj; lines]];
    }
// @fileOverview 
// Draw multiple lines line
// @param renderer {dict} draw api implementation
// @param renderObj {any} 
// @param cvs {dict}canvas node
// @param node {dict} specification node to draw within 
// @param s {dict} settings of the line element 
.z.m.gg.i.draw.i.multi.path:{[renderer; renderObj; cvs; node; coords; s]
    if [0 = count s;
        : renderObj];
    
    s:  etable.qualify s;

    paths : ([] close        : s`close;
                xs           : s`xs;
                ys           : s`ys;
                fillcolour   : s`colour);
    
    paths[`strokewidth]:  $[`strokewidth  in cols s; s`strokewidth;  etable.defaults`strokewidth];
    paths[`strokecolour]: $[`strokecolour in cols s; s`strokecolour; etable.defaults`strokecolour];
    
    info: i.draw.i.info[cvs;node;coords];
    
    : $[h.and[renderer; '[`multi in;key]; '[`path in;{key x`multi}]];
           renderer[`multi][`path][renderObj; info; paths];
    
           renderer[`path][;info]/[renderObj; paths]]
    }
// @fileOverview 
// Draw multiple 3D paths
// @param renderer {dict} draw api implementation 
// @param renderObj {any} 
// @param cvs {dict} canvas node
// @param node {dict} specification node to draw within 
// @param coords {dict} coordinate system
// @param s {dict} settings of the 3D paths 
.z.m.gg.i.draw.i.multi.path3D:{[renderer; renderObj; cvs; node; coords; s]
    if [0 = count s;
        : renderObj];
    
    s: etable.qualify s;
    
    paths: ([] xs           : s`xs;
               ys           : s`ys;
               zs           : s`zs;
               close        : s`close;
               fillcolour   : s`colour);
    
    paths[`strokewidth]:  $[`strokewidth  in cols s; s`strokewidth;  etable.defaults`strokewidth];
    paths[`strokecolour]: $[`strokecolour in cols s; s`strokecolour; etable.defaults`strokecolour];
    
    info: i.draw.i.info[cvs;node;coords];
    
    : $[h.and[renderer; '[`multi in;key]; '[`path3D in;{key x`multi}]];
            renderer[`multi][`path3D][renderObj; info; paths];
            renderer[`path3D][;info]/[renderObj; paths]];
    }
// @fileOverview 
// Draw multiple point geometries
// @param renderer {dict} draw api implementation
// @param renderObj {any} 
// @param cvs {dict} canvas node
// @param node {dict} specification node to draw within 
// @param s {dict} settings of the point element 
.z.m.gg.i.draw.i.multi.point:{[renderer; renderObj; cvs; node; coords; s]
    if [0 = count s;
        : renderObj];

    : $[h.and[renderer; '[`multi in;key]; '[`circle in;{key x`multi}]];
       [    // If possible, draw each settings dictionary in one call to avoid the callout time for each point
            s: etable.qualify s;
            
            info: i.draw.i.info[cvs;node;coords];

            {[renderer;info;renderObj;s]
                
                s: @[s; `x`y; raze]; // Patch for table records, see TODO
                
                s[`strokewidth]:  $[`strokewidth  in cols s; s`strokewidth;    etable.defaults`strokewidth];
                s[`strokecolour]: $[`strokecolour in cols s; s`strokecolour;   etable.defaults`strokecolour];

                : renderer[`multi][`circle][renderObj; info;
                    `x`y`radius`fillcolour`strokecolour`strokewidth!s`x`y`size`colour`strokecolour`strokewidth];

                }[renderer;info]/[renderObj;s]
            ];
           i.draw.i.multi.i.point[`circle; renderer; renderObj; cvs; node; coords; s]]
    }

// @fileOverview 
// Draw multiple 3D points
// @param renderer {dict} draw api implementation 
// @param renderObj {any} 
// @param cvs {dict} canvas node
// @param node {dict} specification node to draw within
// @param coords {dict} coordinate system
// @param s {dict} settings of the 3D points 
.z.m.gg.i.draw.i.multi.point3D:{[renderer; renderObj; cvs; node; coords; s]
    if [0 = count s;
        : renderObj];
    
    s: etable.qualify s;
    
    info: i.draw.i.info[cvs;node;coords];

    : {[renderer;info;renderObj;s]
            
        s[`strokewidth]:  $[`strokewidth  in cols s; s`strokewidth;  etable.defaults`strokewidth];
        s[`strokecolour]: $[`strokecolour in cols s; s`strokecolour; etable.defaults`strokecolour];

        pts: `x`y`z`radius`fillcolour`strokecolour`strokewidth!s`x`y`z`size`colour`strokecolour`strokewidth;

        : $[h.and[renderer; '[`multi in;key]; '[`circle3D in;{key x`multi}]];
                renderer[`multi][`circle3D][renderObj; info; pts];
                renderer[`circle3D][;info]/[renderObj; pts]];
        }[renderer;info]/[renderObj;s];
    }

// @fileOverview 
// Draw multiple polar paths
// @param renderer {dict} draw api implementation
// @param renderObj {any} 
// @param cvs {dict} canvas node
// @param node {dict} specification node to draw within 
// @param s {dict} settings of the line element 
.z.m.gg.i.draw.i.multi.polarpath:{[renderer; renderObj; cvs; node; cs; s]

    if [0 = count s;
        : renderObj];

    s: etable.qualify s;

    supported: (`polarpath in key renderer) or h.and[renderer; '[`multi in;key]; '[`polarpath in;{key x`multi}]];
    if [not supported;
        if [0h ~ type first s`xs; s: raze flip each s];
        : i.draw.i.multi.path[renderer; renderObj; cvs; node; cs] i.draw.i.polarpathToPath[first s`samples] s];
    
    info: i.draw.i.info[cvs;node;cs];
    
    : {[renderer;info;renderObj;s]

        paths : `xs`ys`close`fillcolour`samples!s`xs`ys`close`colour`samples;
        
        paths[`strokewidth]:  $[`strokewidth  in cols s; s`strokewidth;  etable.defaults`strokewidth];
        paths[`strokecolour]: $[`strokecolour in cols s; s`strokecolour; etable.defaults`strokecolour];

        : $[h.and[renderer; '[`multi in;key]; '[`polarpath in;{key x`multi}]];
               renderer[`multi][`polarpath][renderObj; info; paths];

               renderer[`polarpath][;info]/[renderObj; paths]]
        
        }[renderer;info]/[renderObj;s];
    
    
    
  
    }
// @fileOverview 
// Draw multiple rectangles
// @param renderer {dict} draw api implementation 
// @param renderObj {any} 
// @param cvs {dict} canvas node
// @param node {dict} specification node to draw within 
// @param s {dict} settings of the rectangle 
.z.m.gg.i.draw.i.multi.rect:{[renderer; renderObj; cvs; node; coords; s]

    if [0 = count s;
        : renderObj];
    
    s: etable.qualify s;
    
    info: i.draw.i.info[cvs;node;coords];
    
    : {[renderer;info;renderObj;s]
        rects: `x`y`width`height`fillcolour!s`x`y`w`h`colour;
        rects: @[rects;`x`y;raze]; // Patch for table records
        
        rects[`strokewidth]:  $[`strokewidth  in cols s;   s`strokewidth;  etable.defaults`strokewidth];
        rects[`strokecolour]: $[`strokecolour in cols s;   s`strokecolour; etable.defaults`strokecolour];
        
        : $[h.and[renderer; '[`multi in;key]; '[`rect in;{key x`multi}]];
               renderer[`multi][`rect][renderObj; info; rects];

               renderer[`rect][;info]/[renderObj; flip rects]];
        }[renderer;info]/[renderObj;s];

    
    }

// @fileOverview 
// Draw multiple rectangles
// @param renderer {dict} draw api implementation 
// @param renderObj {any} 
// @param cvs {dict} canvas node
// @param node {dict} specification node to draw within 
// @param s {dict} settings of the rectangle 
.z.m.gg.i.draw.i.multi.rect4:{[renderer; renderObj; cvs; node; coords; s]
    
    if [0 = count s;
        : renderObj];
    
    s   : etable.qualify s;
    
    info: i.draw.i.info[cvs;node;coords];
    
    : {[renderer;info;renderObj;s]
        p1s : flip s`x1`y1;
        p2s : flip s`x2`y2;
        ws  : p2s[;0] -' p1s[;0];
        hs  : p2s[;1] -' p1s[;1];

        rects: `x`y`width`height`fillcolour!(p1s[;0]; p2s[;1]; ws; hs; s`colour);

        rects[`strokewidth]:  $[`strokewidth  in cols s; 0^s`strokewidth;  0];
        rects[`strokecolour]: $[`strokecolour in cols s; s`strokecolour;  0i];

        : $[h.and[renderer; '[`multi in;key]; '[`rect in;{key x`multi}]];
               renderer[`multi][`rect][renderObj; info; rects];
               renderer[`rect][;info]/[renderObj; flip rects]];
        
        }[renderer;info]/[renderObj;s];
    }

// @fileOverview 
// Draw multiple square geometries
// @param renderer {dict} draw api implementation
// @param renderObj {any} 
// @param spec {table} specification tree 
// @param node {dict} specification node to draw within 
// @param s {dict} settings of the point element 
.z.m.gg.i.draw.i.multi.square:{[renderer; renderObj; spec; node; coords; s]
    if [0 = count s;
        : renderObj];

    : i.draw.i.multi.i.point[`square; renderer; renderObj; spec; node; coords; s]
    }
// @fileOverview 
// Draw multiple triangle geometries
// @param renderer {dict} draw api implementation
// @param renderObj {any} 
// @param cvs {dict} canvas node
// @param node {dict} specification node to draw within 
// @param s {dict} settings of the point element 
.z.m.gg.i.draw.i.multi.triangle:{[renderer; renderObj; cvs; node; coords; s]
    if [0 = count s;
        : renderObj];
     
    : i.draw.i.multi.i.point[`triangle; renderer; renderObj; cvs; node; coords; s]
    }
.z.m.gg.i.draw.i.polarpathToPath:{[n;x]
    if [all x[`source] in `rect`rect4;
        x[`xs`ys]: x[`xs`ys] ,'' first each' x`xs`ys];
    
    x[`ys]: proj.proj[0 1; (0;2*acos -1); x`ys];
    x[`xs`ys]: flip flip each raze each -1_/: coords.i.interp[n] ./:/: flip @/: (::;next) @\:/: (,') .' x@\:`xs`ys;
    x[`xs`ys]: proj.proj[-1 1; 0 1] flip flip each coords.i.polar.apply @/:/: (,') .' x@\:`xs`ys;
    : etable.el[etable.g.PATH] x;
    }

// @fileOverview 
// Draw each element of an etable onto a canvas
// @param renderer {dict} draw api implementation 
// @param renderObj {any} 
// @param cvs {dict} canvas ancestor spec node
// @param node {dict} specification node to draw within
// @param coords {dict} coordinate system
// @param etab {table} etable of elements to draw
.z.m.gg.i.draw.on:{[renderer; renderObj; cvs; node; coords; etab]
    if [0 = count etab; : renderObj];

    etab: coords.transform[coords;etab];
    
    render : {[renderer; renderObj; cvs; node; coords; etab; drawF; g]
        : drawF[renderer; renderObj; cvs; node; coords] etable.every[g] etab;
        }[renderer; ; cvs; node; coords; etab];
        
    : (renderObj render/) . flip i.draw.i.GEOMS;
    }
.z.m.gg.i.draw.i.GEOMS:(
   (i.draw.i.multi.rect     ; etable.g.RECT);
   (i.draw.i.multi.rect4    ; etable.g.RECT4);
   (i.draw.i.multi.point    ; etable.g.POINT);
   (i.draw.i.multi.square   ; etable.g.SQUARE);
   (i.draw.i.multi.triangle ; etable.g.TRIANGLE);
   (i.draw.i.multi.line     ; etable.g.LINE);
   (i.draw.i.multi.path     ; etable.g.PATH);

   (i.draw.i.multi.atext`atextM ; etable.g.ATEXTM); 
   (i.draw.i.multi.atext`atextL ; etable.g.ATEXTL);
   (i.draw.i.multi.atext`atextR ; etable.g.ATEXTR);

   (i.draw.i.multi.point3D ; etable.g.POINT3D);
   (i.draw.i.multi.line3D  ; etable.g.LINE3D);
   (i.draw.i.multi.path3D  ; etable.g.PATH3D);

   (i.draw.i.multi.atext3D`atextL3D ; etable.g.ATEXTL3D);
   (i.draw.i.multi.atext3D`atextM3D ; etable.g.ATEXTM3D);
   (i.draw.i.multi.atext3D`atextR3D ; etable.g.ATEXTR3D);

   (i.draw.i.multi.polarpath ; etable.g.POLARPATH)
   )     
system "d .z.m";

system "d .z.m.gg";
.z.m.gg.scenegraph.i.atext3D:{[g;state;info;settings]
    settings[`x`y]: info[`coords][`applyF] settings`x`y`z;
    : scenegraph.single[g;state;info;settings];
    }

// @fileOverview
// Helper function which determines if a dictionary has a field containing an atom
// Used to identify dictionaries with default-value fields
// @returns {bool}
.z.m.gg.scenegraph.i.containsAtomic:{[d]
    : any 0 > type each d;
    }

.z.m.gg.scenegraph.i.multi.atext3D:{[g;state;info;settings]
    settings[`x`y]: info[`coords][`applyF] settings`x`y`z;
    : scenegraph.multi[g;state;info;settings];
    }

// @fileOverview 
// Append settings dictionary to a geom list of dictionaries
// @returns {dict} updated state
.z.m.gg.scenegraph.i.multiDicts:{[g;state;info;settings]
    state[info`id;`geom;g;`dicts]: state[info`id;`geom;g;`dicts], settings;
    : state;
    }
// @fileOverview 
// Appends records to a geom table
// @returns {dict} updated state
.z.m.gg.scenegraph.i.multiTable:{[g;state;info;settings]
    state[info`id;`geom;g;`table]: state[info`id;`geom;g;`table] uj settings;
    : state;
    }

// @fileOverview
// Creates a new frame state
// @param info {dict} frame information
// @returns {dict} new frame dictionary
.z.m.gg.scenegraph.i.newFrame:{[info]
    : `origin`w`h`geom!(info`origin;info[`dims] 0;info[`dims] 1;()!());
    }

// @fileOverview
// Appends settings to the chosen field in state[`geom]
// @param g {symbol} field to update
// @param state {dict} current state
// @param info {dict} drawing info, unused
// @param settings {dict} settings to append
// @returns {dict} updated state
.z.m.gg.scenegraph.i.single:{[g;state;info;settings]
    state[info`id;`geom;g;`table]: state[info`id;`geom;g;`table] uj enlist settings;
    : state;
    }

// @fileOverview
// Checks to see if the frame being drawn to exists, and if
// it contains the required geom field
// If not, initializes missing fields
// @param g {symbol}
// @param state {dict}
// @param info {dict}
// @returns {dict} updated state
.z.m.gg.scenegraph.i.validate:{[g;state;info];
    if[not info[`id] in key state;
        state[info`id]: scenegraph.i.newFrame info];
    if[not g in key state[info`id;`geom];
        state[info`id;`geom;g]: ()!();
        state[info`id;`geom;g;`table]: scenegraph.i.DEFAULTGEOMS g;
        state[info`id;`geom;g;`dicts]: scenegraph.i.DEFAULTGEOMS g];
    : state;
    }

// @fileOverview
// Appends settings to the chosen field in state[`geom]
// Used to generate all multi geom "draw" functions for scenegraphw
// multi geom "draw" functions are used to save time checking existence of keys
// @param g {symbol} field to update
// @param state {dict} current state
// @param info {dict} drawing info, unused
// @param settings {dict} settings to append
// @returns {table} updated state
.z.m.gg.scenegraph.multi:{[g;state;info;settings]
    state: scenegraph.i.validate[g;state;info];
    if[98h ~ type settings;                      : scenegraph.i.multiTable[g;state;info;settings]];
    if[not scenegraph.i.containsAtomic settings; : scenegraph.i.multiTable[g;state;info;flip settings]];
    : scenegraph.i.multiDicts[g;state;info;settings];
    }

// @fileOverview
// Appends settings to the chosen field in state[`geom]
// Used to generate all geom "draw" functions for scenegraphw
// @param g {symbol} field to update
// @param state {dict} current state
// @param info {dict} drawing info, unused
// @param settings {dict} settings to append
// @returns {dict} updated state
.z.m.gg.scenegraph.single:{[g;state;info;settings]
    state: scenegraph.i.validate[g;state;info];
    : scenegraph.i.single[g;state;info;settings];
    }



// @fileOverview
// Defines the default tables for each geometry.
// The dictionary is used for creating the geometry's tables when a new
// state is created, and the keys of the dictionary are used to generate 
// all "draw" functions for .z.m.gg.scenegraphw
// TODO: Find and remove redundancy with respect to this dictionary of default keys
.z.m.gg.scenegraph.i.DEFAULTGEOMS:{flip x!count[x]#()} each (!) . flip (
    (`atextL;`angle`x`y`text`offsetx`offsety`strokewidth`fillcolour`fontsize`fontfamily`bold`italic);
    (`atextM;`angle`x`y`text`offsetx`offsety`strokewidth`fillcolour`fontsize`fontfamily`bold`italic);
    (`atextR;`angle`x`y`text`offsetx`offsety`strokewidth`fillcolour`fontsize`fontfamily`bold`italic);
    (`circle;`x`y`radius`strokewidth`strokecolour`fillcolour);
    (`line;`x1`y1`x2`y2`strokewidth`fillcolour`dashed);
    (`path;`xs`ys`close`fillcolour`strokewidth`strokecolour);
    (`rect;`x`y`width`height`strokewidth`strokecolour`fillcolour);
    (`square;`x`y`radius`strokewidth`strokecolour`fillcolour);
    (`triangle;`x`y`angle`radius`strokewidth`strokecolour`fillcolour);
    (`atextL3D;`x`y`z`text`offsetx`offsety`angle`strokewidth`fillcolour`fontsize`fontfamily`bold`italic);
    (`atextM3D;`x`y`z`text`offsetx`offsety`angle`strokewidth`fillcolour`fontsize`fontfamily`bold`italic);
    (`atextR3D;`x`y`z`text`offsetx`offsety`angle`strokewidth`fillcolour`fontsize`fontfamily`bold`italic);
    (`circle3D;`x`y`z`radius`strokewidth`strokecolour`fillcolour);
    (`line3D;`x1`y1`z1`x2`y2`z2`strokewidth`fillcolour`dashed);
    (`path3D;`xs`ys`zs`close`fillcolour`strokewidth`strokecolour);
    (`polarpath; `xs`ys`close`fillcolour`strokewidth`strokecolour`samples)
    )

system "d .z.m";

system "d .z.m.gg";
.z.m.gg.scenegraphw.atextL3D:{[state;info;settings]
    : scenegraph.i.atext3D[`atextL;state;info;settings];
    }
.z.m.gg.scenegraphw.atextM3D:{[state;info;settings]
    : scenegraph.i.atext3D[`atextM;state;info;settings];
    }
.z.m.gg.scenegraphw.atextR3D:{[state;info;settings]
    : scenegraph.i.atext3D[`atextR;state;info;settings];
    }
.z.m.gg.scenegraphw.circle3D:{[state;info;settings]
    settings[`x`y]: info[`coords][`applyF] settings`x`y`z;
    : scenegraph.single[`circle;state;info;settings];
    }

// @private
// @fileOverview
// Do any scenegraph setup that must be done before
// instances can be made.
//
// Run only once.
//
// @returns {null}
.z.m.gg.scenegraphw.init:{[]
    }

.z.m.gg.scenegraphw.line3D:{[state;info;settings]
    settings[`x1`y1]: info[`coords][`applyF] settings`x1`y1`z1;
    settings[`x2`y2]: info[`coords][`applyF] settings`x2`y2`z2;
    : scenegraph.single[`line;state;info;settings];
    }
.z.m.gg.scenegraphw.multi.atextL3D:{[state;info;settings]
    : scenegraph.i.multi.atext3D[`atextL;state;info;settings];
    }
.z.m.gg.scenegraphw.multi.atextM3D:{[state;info;settings]
    : scenegraph.i.multi.atext3D[`atextM;state;info;settings];
    }
.z.m.gg.scenegraphw.multi.atextR3D:{[state;info;settings]
    : scenegraph.i.multi.atext3D[`atextR;state;info;settings];
    }
.z.m.gg.scenegraphw.multi.circle3D:{[state;info;settings]
    settings[`x`y]: info[`coords][`applyF] settings`x`y`z;
    : scenegraph.multi[`circle;state;info;settings];
    }

.z.m.gg.scenegraphw.multi.line3D:{[state;info;settings]
    settings[`x1`y1]: info[`coords][`applyF] settings`x1`y1`z1;
    settings[`x2`y2]: info[`coords][`applyF] settings`x2`y2`z2;
    : scenegraph.multi[`line;state;info;settings];
    }

.z.m.gg.scenegraphw.multi.path3D:{[state;info;settings]
    settings[`xs`ys]: flip info[`coords][`applyF] each flip settings`xs`ys`zs;
    : scenegraph.multi[`path;state;info;settings];
    }

// @fileOverview
// Create an empty scenegraph state
//
// @param w {long} Width
// @param h {long} Height
//
// @returns {dict} new scenegraph state
.z.m.gg.scenegraphw.new:{[w;h]
    : ()!();
    }

.z.m.gg.scenegraphw.path3D:{[state;info;settings]
    settings[`xs`ys]: info[`coords][`applyF] settings`xs`ys`zs;
    : scenegraph.single[`path;state;info;settings];
    }
// @fileOverview
// No op
// @param state {dict} scenegraph state
// @returns {dict} state
.z.m.gg.scenegraphw.remove:{[state]}

// @fileOverview Package the intermediate state tables into frames
// @param o {dict} intermediate state
// @returns {dict[]} list of frames
.z.m.gg.scenegraphw.render:{[o]
    if[0 = count o; : ()];
    o: @[;`guid;:;key o] value o;
    : .[o;(::;`geom);{$[0 = count x`table;x`dicts;x[`dicts], flip x`table]}'];
    }

.z.m.gg.scenegraphw.LABEL:`scenegraph
.z.m.gg.scenegraphw.onLoad:{
    if[(::) ~ scenegraphw`multi; scenegraphw[`multi]: ()!()];
    scenegraphw        ,: k!scenegraph.single @' k:key[scenegraph.i.DEFAULTGEOMS] except key scenegraphw;
    scenegraphw[`multi],: k!scenegraph.multi  @' k:key[scenegraph.i.DEFAULTGEOMS] except key scenegraphw[`multi];
    }

.z.m.gg.scenegraphw.onLoad[];
system "d .z.m";

system "d .z.m.gg";
// @fileOverview
// Creates external outputs for composite renderObj from a list of external nodes
// @param nodes {table} list of external nodes
// @returns {table} 
.z.m.gg.composite.i.externalOutputs:{[nodes]
    if[0 = count nodes; : 0#enlist `origin`w`h`label`state`output!6#(::)];
    d : `origin`w`h!nodes[`item] `origin`w`h;
    d,: enlist[`label]!enlist spec.pluck[`defn;nodes]`label;
    d,: `state`output!`state`output spec.pluck\: nodes;
    : flip d;
    }

// @fileOverview
// Calls scenegraphw draw functions to update main canvas state
// Used to generate all geom "draw" functions for compositew
// @param g {symbol} field to update
// @param renderObj {dict}
// @param info {dict} drawing info, unused
// @param settings {dict} settings to append
// @returns {dict} updated renderObj
.z.m.gg.composite.multi:{[g;renderObj;info;settings]
    : @[renderObj;`main;scenegraphw[`multi][g;;info;settings]];
    }



// @fileOverview
// Creates new record for a composite renderer state with given id
// @param node {dict} canvas node
// @returns {dict}
.z.m.gg.composite.newCanvas:{[node]
    component: spec.node.item node;
    dims: (spec.ty.component.w;spec.ty.component.h) @\: component;
    : (!) . flip (
        (`origin;   spec.ty.component.origin component);
        (`w;        dims 0);
        (`h;        dims 1);
        (`type;     `scenegraph);
        (`renderer; scenegraphw);
        (`renderObj;scenegraphw[`new] . dims);
        (`externals;()!()));
    }

// @fileOverview
// Calls scenegraphw draw functions to update main canvas state
// Used to generate all geom "draw" functions for compositew
// @param g {symbol} field to update
// @param renderObj {dict}
// @param info {dict} drawing info, unused
// @param settings {dict} settings to append
// @returns {dict} updated renderObj
.z.m.gg.composite.single:{[g;renderObj;info;settings]
    : @[renderObj;`main;scenegraphw[g;;info;settings]];
    }



.z.m.gg.composite.i.MAXSTATESIZE:5*2 xexp 20
system "d .z.m";

system "d .z.m.gg";
// @fileOverview
// If there is no renderer/renderObj pair associated with the given node, creates one.
// Also creates a cache of the spec to use when switching to the skia renderer
// @param renderObj {dict}
// @param sp {table} 
// @param node {dict} canvas node
// @returns {dict} updated renderObj
.z.m.gg.compositew.initLocalRenderer:{[renderObj;sp;node]
    renderObj[`specCache]: sp;
    if[not node[`id] in key renderObj`canvases;
        renderObj[`canvases;node`id]: composite.newCanvas node];
    : renderObj;
    }

// @fileOverview 
// Gets the renderObj used by the given canvas node
// @param renderObj {any}
// @param node {dict} canvas node
// @returns {dict} renderObj
.z.m.gg.compositew.localRenderObj:{[renderObj;node]
    : renderObj[`canvases][node`id]`renderObj;
    }
// @fileOverview 
// Gets the renderer used by the given canvas node
// @param renderObj {any}
// @param node {dict} canvas node
// @returns {dict} renderer
.z.m.gg.compositew.localRenderer:{[renderObj;node]
    : renderObj[`canvases][node`id]`renderer;
    }

// @fileOverview
// Create a new composite scene state
//
// @param w {long} Width
// @param h {long} Height
//
// @returns {dict} new composite scene state
.z.m.gg.compositew.new:{[w;h]
    : `canvases`main`specCache!(()!();scenegraphw.new[w;h];::);
    }

// @fileOverview 
// Calls render for each local renderer
// @param s {dict} renderObj
// @returns {dict} output state
.z.m.gg.compositew.render:{[s]
    f: {`origin`w`h`type`state`externals!(x`origin;x`w;x`h;x`type;x[`renderer][`render] x`renderObj; x`externals)};
    v: (0#flip `origin`w`h`type`state`externals!6#enlist ()), value f each s`canvases;

    : `canvases`main!(
        @[v;`guid;:;key s`canvases]; 
        scenegraphw[`render] s`main);
    }

// @fileOverview
// Sets the renderObj used by the given canvas node
// @param renderObj {dict} 
// @param sp {table} spec 
// @param node {dict} canvas node
// @param localRenderObj {any} 
// @returns {(table;dict)} update spec + renderObj
.z.m.gg.compositew.updateRenderObj:{[renderObj; sp; node; localRenderObj]

    if [h.and[localRenderObj;{`scenegraph ~ y`type}[;renderObj[`canvases] node`id];{composite.i.MAXSTATESIZE < -22!x}];
        dims : (spec.ty.component.w;spec.ty.component.h) @\: spec.node.item node;
        renderObj[`canvases;node`id]: @[renderObj[`canvases] node`id; `renderer`renderObj`type;:;(.axskiaw;.axskiaw[`new] . dims; `skia)];
        : i.resizeCanvas[compositew; (renderObj`specCache; renderObj _ `specCache); node]];
    
    externalNodes : spec.every[spec.ty.external] .z.m.axds.tree.descendants[node;sp];
    externals     : externalNodes[`id] ! composite.i.externalOutputs externalNodes;
    
    renderObj: .[renderObj; (`canvases;node`id;`renderObj`externals); :; (localRenderObj; externals)];
    : (sp; renderObj);
    }

.z.m.gg.compositew.LABEL:`composite
.z.m.gg.compositew.onLoad:{
    compositew       ,: k!composite.single @' k:key scenegraph.i.DEFAULTGEOMS;
    compositew[`multi]: k!composite.multi  @' k:key scenegraph.i.DEFAULTGEOMS;
    }

.z.m.gg.compositew.onLoad[];
system "d .z.m";

system "d .z.m.gg";
// @fileOverview 
// Stub an 'external' definition with default options
//
// @param ext {dict}
// @desc  ext.recurse  {boolean} if false, does not recurse at display/resize steps
// @desc  ext.initF    {fn (dict) => dict} initializes an unitialized external node 
// @desc  ext.preF     {fn (table;dict) -> table} modifies the spec, called before children are all drawn
// @desc  ext.postF    {fn (table;dict) -> table} modifies the spec, called after children are all drawn
// @desc  ext.outputF  {fn (dict;any) -> any} creates the output from the external node's data and state (called after postF)
// @returns {dict} stubbed external
.z.m.gg.external.stubDefaults:{[ext]
    defaults: (!) . flip (
        (`data    ; ::);
        (`linkid  ; ::);
        (`recurse ; 1b);
        (`initF   ; ::);
        (`preF    ; {[sp; node] : sp});
        (`postF   ; {[sp; node] : sp});
        (`outputF ; {[data;state] });
        (`errorF  ; ::);
        (`label   ; "")
        );
    
    : defaults, ext;
    }

system "d .z.m";

system "d .z.m.gg";
// @fileOverview 
// Displays an initialized GG object using the default GG renderer
//
// @see gg.resizeUsing
//
// @param w {long} width
// @param h {long} height 
// @param gg {dict} initialized GG 
// @throws "resize error: canvas is not large enough to hold frame components"
.z.m.gg.display:{[w; h; gg]
    : resize[w;h] i.display gg;
    }
// @fileOverview 
// Display and render using an explicit renderer. A renderer
// is a dictionary/namespace with the following:
//
// - `atextL : state, settings -> state`
// - `atextM : state, settings -> state`
// - `atextR : state, settings -> state`
// - `circle : state, settings -> state`
// - `line : state, settings -> state`
// - `path : state, settings -> state`
// - `rect : state, settings -> state`
// - `remove : state -> ()`
// - `render : state -> any`
// - `new : w, h -> state`
//
// In each of the above, `state` is anything that the renderer needs to track, and
// `settings` is a dictionary of settings for each  geometry. These settings have the following keys:
//
// - `` atextL : `pt`fontsize`fillcolour`angle ``
// - `` atextM : `pt`fontsize`fillcolour`angle ``
// - `` atextR : `pt`fontsize`fillcolour`angle ``
// - `` circle : `center`radius`strokecolour`strokewidth`fillcolour ``
// - `` line : `x1`y1`x2`y2`strokewidth`fillcolour ``
// - `` path : `xs`ys`strokewidth`strokecolour`fillcolour ``
// - `` rect : `x`y`w`h`strokewidth`strokecolour`fillcolour ``
//
// Stroke-colour and Fill-colour are both byte arrays of the form `0xAARRGGBB`.
//
// When stroke is not used, stroke-width is `0` and stroke-colour is undefined. 
//
// @param r {dict} render API
// @param w {long} width
// @param h {long} height
// @param gg {dict} initialized GG object
// @returns {dict} Rendered GG
//
// @example
// .z.m.gg.displayUsing[.myrenderer; 500; 500] .z.m.gg.new spec
.z.m.gg.displayUsing:{[r; w; h; gg]
    : resizeUsing[r; w; h] i.display gg;
    }

// @fileOverview Cleveland et al assert the 'primary' angle in a line chart
// should be banked to 45 degrees. Others have shown that other angles work
// well, but 45 degrees is a good starting point.
// This function resizes a frame so that it banks the max angle of a line chart
// to the given angle in degrees.
// @param frame {dict} frame settings 
// @param lyr {dict} GG layer
// @returns {dict} New frame
.z.m.gg.i.bankSlopes:{[frame; lyr]
    s: last value lyr . `geom`applyF;
    shapetables: lyr`i_shapetables;
    degToRad: (acos[-1]%180)*;
    
    if [`line ~ lyr[`geom]`label;
        l: first etable.qualify etable.every[etable.g.LINE] shapetables`geom;
        
        if [0 = count l;
            : frame];
        
        if [90 = s`bankMaxAngle;
            : frame];
        
        f: frame . `geom`item;
        angles: abs atan (%) . (-) .' f[`h`w] *' l(`y2`y1;`x2`x1);
        
        if [max[angles] <= degToRad s`bankMaxAngle;
            : frame];
        
        ratio: abs tan[degToRad s`bankMaxAngle] * (%) . (-) .' f[`w`h] *' l[(`x2`x1;`y2`y1)]@\:\:first idesc angles;
        
        if [ratio within 0 1;
            oldHeight: frame[`geom;`item;`h];
            newHeight: frame[`geom;`item;`h] & s[`bankMinHeight] | frame[`geom;`item;`h] * ratio;
            diff:      oldHeight - newHeight;
            
            frame[`geom`yaxis`background;`item;`h]         : newHeight;
            frame[`geom`yaxis`background;`item;`origin;1] +: diff % 2;
            frame[`xaxis;`item;`origin;1]                 -: diff % 2]];
    
    : frame;
    }

// @fileOverview
// If the interpolation amount has been changed on polar coordinates, 
// draw the grid with the default interpolation
.z.m.gg.i.bgcoord:{[c] $[coords.polarn[0][`label] ~ c`label; coords.polar; c] }

// @fileOverview 
// Continue a tree traversal without processing the given node
// @param f {fn} The node processing function 
// @param accum {table} The specification table 
// @param root {dict} A node within the specification table treated as the current root 
// @returns {table} Updated/processed specification 
.z.m.gg.i.continue:{[f; accum; root]
    : {[f; accum; child]
        f [accum 1; child; accum 0]
        }[f]/[accum;] spec.children[root; accum 0];
    }
// @fileOverview 
// Continue a tree traversal without processing the given node
// @param f {fn} The node processing function 
// @param spec {table} The specification table 
// @param root {dict} A node within the specification table treated as the current root 
// @returns {table} Updated/processed specification 
.z.m.gg.i.continue1:{[f; spec; root]
    : {[f;spec; child]
        f [child; spec]
        }[f]/[spec;] spec.children[root; spec];
    }
// @qlintsuppress all
// @fileOverview Internal routine to draw a labelled gg spec tree
// @param sp {table} 
.z.m.gg.i.debug:{[sp]
    t: .z.m.qp.tree.layout[sp; `id; `children; ::];
    t2: t[`nodes] lj 1!select id, label: ((4#'string id),'" ",/:{"(",last[x],")"} each "." vs'string (item@\:`entry) @\: `i_.type) from sp;
 
    : .z.m.qp.theme[.z.m.gg.theme.blank , ``canvas_fill`padding_right!(::;`white;100)]
        .z.m.qp.stack (
            .z.m.qp.segment[t`edges; `x__; `y__; `x2__; `y2__; .z.m.qp.s.geom[``fill!(::;0xdadada)]];
            .z.m.qp.point[t`nodes; `x__; `y__; .z.m.qp.s.geom[``size`fill!(::;4;0xdadada)]];
            .z.m.qp.text[t2; `x__; `y__; `label; .z.m.qp.s.geom[``offsetx!(::;10)]]);
    }


.z.m.gg.i.decorations:{[th; scales; coordinates; labels; customLegends]

    xaxis : yaxis : zaxis : (::);
    background : coordinates[`backgroundF] . th`plot_background_fill`plot_background_stroke;
    frame      : coordinates[`backgroundF] . th`frame_background_fill`plot_background_stroke;
    grid       : coordinates[`gridF][th; scales];
    
    if [spec.frame.useAxis[th; coordinates; `x];
        xaxis : i.rules.xaxis[th; coordinates; labels`x; scales`x]];
    if [spec.frame.useAxis[th; coordinates; `y] and `y in key scales;
        yaxis : i.rules.yaxis[th; coordinates; labels`y; scales`y]];
    if [spec.frame.useAxis[th; coordinates; `z];
        zaxis : i.rules.zaxis[th; coordinates; labels`z; scales`z]];
    
    lkeys   : i.legendKeys[th; scales];
    legends : {[t; l; s; x] i.rules.legend[t; l x; s x]}[th; labels; scales] each lkeys;
    legends : legends where not h.null each legends;
    legends : legends , {[th;x]
        s: $[.z.m.gg.scale.base.is x`ticks;
            x`ticks;
            scale.init[scale.colour.cat x`ticks; key x`ticks]];
        : i.rules.legend[th; x`title; scale.initBreaks s];
        }[th] each customLegends;
    
    : `xaxis`yaxis`zaxis`legends`background`grid`frame!(xaxis; yaxis; zaxis; legends; background; grid; frame);
    }


.z.m.gg.i.display:{[gg]
    sp : i.displayFrom [spec.root ty.spec gg; ty.spec gg];
    
    : ty.with.spec[sp] gg;
    }

// @fileOverview 
// Checks for errored nodes in the canvas's subtree, and calls the canvas's error function if it finds any
// @param sp {table} specification table 
// @param node {dict} canvas node
// @returns {table} updated specification table
.z.m.gg.i.displayCanvas:{[sp; node]
    
    if[not spec.ty.canvas.dirty spec.ty.component.entry .z.m.axds.tree.node.item node; : sp];
    
    : i.continue1[i.displayFrom; sp; node];
    }

// @fileOverview
// @param sp {table} 
// @param node {dict} external node
// @returns {table} updated spec table
.z.m.gg.i.displayExternal:{[sp; node]
    
    if[not spec.pluck[`defn;node]`recurse; : sp];
    
    : $[h.null .z.m.gg.spec.pluck[`defn;node]`errorF;
        i.continue1[i.displayFrom; sp; node];
        [
            errorF : {[sp; node; err]
                sp   : spec.pluck[`defn;node][`errorF][sp; node; err];
                node : .z.m.axds.tree.find[node`id; sp];
                : $[spec.pluck[`defn;node]`recurse;
                    i.continue1[i.displayFrom; sp; node];
                    sp];
                }[sp;node];

            .[i.continue1; (i.displayFrom; sp; node); errorF]]];
    }


.z.m.gg.i.displayFrom:{[root; sp]
    entry : spec.ty.component.entry spec.node.item root;
    : $[spec.ty.layer.is entry;
            i.displayLayer[sp; root];
        spec.ty.stack.is entry;
            i.displayStack[i.stackDecorations; sp; root];
        spec.ty.theme.is entry;
            i.displayTheme[sp; root];
        spec.ty.split.is entry;
            i.displayStack[i.splitDecorations; sp; root];
        spec.ty.canvas.is entry;
            i.displayCanvas[sp; root];
        spec.ty.external.is entry;
            i.displayExternal[sp; root];
            i.continue1[i.displayFrom; sp; root]];

    }

// @fileOverview 
// Draw a specification from a layer node. A frame is created
// and added to the specification. If a canvas node is provided,
// it is used as the drawing context. Otherwise, a new canvas will
// be created in the frame. The geometry etable is always added to
// the canvas, but decorations can be disabled.
// @param sp {table} specification tree 
// @param node {dict} specification node acting as the root
// @returns {table} a specification with decoration nodes added
.z.m.gg.i.displayLayer:{[sp; node]
    lyr       : spec.pluck[`defn] node;
    if[not h.null lyr`error; 'lyr`error];    
    th        : spec.theme[node; sp];
    
    decorations : i.decorations[th; layer.scalesUsed[lyr] # lyr`scales; lyr`coord; layer.labels[th; lyr]; lyr`legends];
    geometry    : layer.geomtable[th; lyr];
    
    lyr[`i_shapetables]: `geom`decorations!(geometry;decorations);
    
    component : spec.node.item node;
    entry     : spec.ty.component.entry component;
    component : spec.ty.component.with.entry [ spec.ty.layer.with.defn[lyr] entry ] component;
    
    : .z.m.axds.tree.modify[node; component; sp];
    
    }

.z.m.gg.i.displayStack:{[decorationsF; sp; root]

    if[0 = count spec.stackLayers[sp; root]; : i.continue1[i.displayFrom; sp; root]];
    
    component     : spec.node.item root;
    stackAncestor : spec.ancestorWhere[{spec.ty.stack.is[x] or spec.ty.split.is x}; sp; root];
    
    if[not h.null stackAncestor;
        component[`entry;`get;`i_shapetables] : spec.pluck[`get;stackAncestor]`i_shapetables;
        sp : .z.m.axds.tree.modify[root; component; sp];
        : i.continue1[i.displayFrom; sp; root]];
    
    decorations : decorationsF [sp; root];
    
    component[`entry;`get;`i_shapetables] : enlist[`decorations]!enlist decorations;
    sp : .z.m.axds.tree.modify[root; component; sp];
    : i.continue1[i.displayFrom; sp; root];
    }

// @fileOverview 
// Draw a theme node - if a canvas_fill is present, then the background is coloured.
// @param spec {table} specification tree 
// @param root {dict} tree node
.z.m.gg.i.displayTheme:{[spec; root]
    : i.displayFrom[first spec.children[root; spec]; spec];
    }


.z.m.gg.i.drawCanvas:{[renderer; renderObj; cvs; node]
    top      : spec.node.item node;
    th       : spec.pluck[`get] top;
    : $[$[not `canvas_fill in key th; 1b; .z.m.gg.h.null th`canvas_fill];
        renderObj;
        renderer[`rect][renderObj; i.draw.i.info[cvs;node;coords.rect]; `x`y`width`height`fillcolour!(0; 1; 1; 1; 0x0 sv th`canvas_fill)]];
    }


.z.m.gg.i.drawDecorations:{[c; renderer; renderObj; cvs; frame; decorations]
    
    gridCoord : i.bgcoord c;
    xCoord    : $[`cube~c`label;gridCoord;coords.rect];
    
    if [not h.null decorations`grid;    renderObj: i.draw.on[renderer; renderObj; cvs; frame`background;    gridCoord; decorations`grid]];
    if [not h.null decorations`xaxis;   renderObj: i.draw.on[renderer; renderObj; cvs; frame c`xaxisFrame;  xCoord;    decorations`xaxis]];
    if [not h.null decorations`yaxis;   renderObj: i.draw.on[renderer; renderObj; cvs; frame c`yaxisFrame;  gridCoord; decorations`yaxis]];
    if [not h.null decorations`zaxis;   renderObj: i.draw.on[renderer; renderObj; cvs; frame c`zaxisFrame;  gridCoord; decorations`zaxis]];
    if [not h.null decorations`yaxis2;  renderObj: i.draw.on[renderer; renderObj; cvs; frame c`yaxisFrame2; gridCoord; decorations`yaxis2]];
    
    if [not h.null decorations`legends;
        ii : where not h.null each decorations`legends;
        renderObj: i.drawLegend[renderer;cvs]/[renderObj;] 
            flip (frame`legends; decorations[`legends] ii)];
    
    : renderObj;
    }

// @fileOverview 
// Draw a legend to a frame component.
// @param renderer {dict} draw api implementation 
// @param cvs {dict} canvas ancestor spec node 
// @param renderObj {any} 
// @param accum2 {dict}
// @returns {any} Updated render obj
.z.m.gg.i.drawLegend:{[renderer; cvs; renderObj; accum2]
    frame     : accum2 0;
    legend    : accum2 1;
    if [not h.null[frame] or h.null legend;
        renderObj: i.draw.on[renderer; renderObj; cvs; frame 0; coords.rect; legend 0];
        renderObj: i.draw.on[renderer; renderObj; cvs; frame 1; coords.rect; legend 1]];
    
    : renderObj;
    }

.z.m.gg.i.formatLegend:{[thm; frame; cds; shapetables]
    
    shapetables[`decorations;`legends]: frame[`legends] {[thm; fr; sh]
        if [(::) ~ fr; : sh];
        w: -[;10] @[;`w] .z.m.axds.tree.node.item fr 1;
        s: raze string axis . ii: (where `atextR = @[;`geometry] axis:sh 1;`settings;`text);
        prefixes: (-1_)\'[s];
        t: (neg first each where each w >= .z.m.gg.h.textWidth[thm`axis_tick_label_fontsize] each prefixes)_'s;
        t[truncated]: t[truncated:where not t ~' s] ,\:  "..";
        axis: .[axis; ii; :; `$h.asString t];
        sh[1]: axis;
        : sh
        }[thm]' shapetables[`decorations]`legends;
    
    : shapetables
    }

// @fileOverview 
// Format an x axis before rendering.
//
// * Trims string labels based on the amount of room available
// * Removes maxChars key from tick labels settings
// @param thm {dict} theme
// @param frame {dict} 
// @param cds {dict} coords
// @param shapetables {dict (xaxis: dict)} 
// @returns {dict (xaxis: dict)}
// @private
.z.m.gg.i.formatXAxis:{[thm; frame; cds; shapetables]

    if [h.null shapetables[`decorations]`xaxis; : shapetables];
    
    xaxis : shapetables[`decorations]`xaxis;
    g     : exec first geometry from xaxis where geometry like "*text*";


    if [(not 0 = thm`axis_tick_label_angle_x) or not i.useDynamicAxes[thm; cds];
        xaxis:update settings:{`maxChars _ @[x;`text;:;] `$h.trim[x`maxChars; h.asString x`text]}''[settings] from xaxis where geometry = g, `maxChars in' cols each settings;
        : .[shapetables; `decorations`xaxis; :; xaxis]];

    
    w : frame . `xaxis`item`w;
    
    settings: raze etable.settings select from xaxis where geometry = g, `maxChars in' cols each settings;
    if [0 = count settings; : shapetables];
        
    px: w * exec x from settings;
    
    widths: { x: x[2]^x; min abs (x[1]-x 0; x[2]-x 1) } each prev[px] ,' px ,' next px;
        
    prefixes: (-1_)\'[first each t@'where each (max each c) = c:count each/: t:"\n"vs'h.asString each settings@\:`text];

    labels: count each {[s;w;p] p first where h.textWidth[s;p] < w - 5 }[thm`axis_tick_label_fontsize]'[widths; prefixes];
    labels: `$"\n" sv' labels h.trim/:' t;
    
    xaxis: update settings: labels{@[y;`text;:;x]}'settings from xaxis where geometry = g, `maxChars in' cols each settings;

    : .[shapetables; `decorations`xaxis; :; xaxis]
    }
// @fileOverview 
// Format a y axis before rendering.
//
// * Removes maxChars key from tick labels settings
// @param theme {dict} 
// @param frame {dict} 
// @param coords {dict} 
// @param shapetables {dict (yaxis: dict)} 
// @returns {dict (yaxis: dict)} 
.z.m.gg.i.formatYAxis:{[theme; frame; coords; shapetables]
    if [h.null shapetables[`decorations]`yaxis; : shapetables];
    yaxis : shapetables . `decorations`yaxis;
    yaxis : update settings: (`maxChars _'' settings) from yaxis where geometry like "*text*", `maxChars in' cols each settings;
    : .[shapetables; `decorations`yaxis; :; yaxis];
    }

// @fileOverview 
// Format a z axis before rendering.
//
// * Removes maxChars key from tick labels settings
// @param theme {dict} 
// @param frame {dict} 
// @param coords {dict} 
// @param shapetables {dict (zaxis: dict)} 
// @returns {dict (zaxis: dict)} 
.z.m.gg.i.formatZAxis:{[theme; frame; coords; shapetables]
    if [h.null shapetables[`decorations]`zaxis; : shapetables];
    zaxis : shapetables . `decorations`zaxis;
    zaxis : update settings: (`maxChars _'' settings) from zaxis where geometry like "*text*", `maxChars in' cols each settings;
    : .[shapetables; `decorations`zaxis; :; zaxis];
    }

.z.m.gg.i.legendKeys:{[th; scales]
    : $[1b ~ th`legend_use;
            key[scales] except ``x`y`z;
        0b ~ th`legend_use;
            ();
        11 = abs type th`legend_use;
            raze th`legend_use;
            '"theme legend_use error - must be boolean or symbol list"];
    }

// @qlintsuppress UNUSED_INTERNAL(1)
.z.m.gg.i.qdformatter:{[r]
    : .qd.format.imageTag
            .qd.format.base64
            .[;`output`bytes]
            .z.m.gg.display[500;500]
            .z.m.gg.new
            .z.m.qp.theme[.z.m.gg.theme.clean , ``marker_default_fill!(::; 0x222222)]
            r
    }

// @fileOverview 
// Handles the drawing of a subtree of a canvas node
// Upon reaching a canvas node, get the associated renderObj and renderer which is used to
// draw the subtree
// @param renderer {dict} draw api implementation 
// @param accum {(any;table)} renderObj + specification tree 
// @param node {dict} specification node acting as the root
// @returns {(table;any)} updated specification + renderObj
.z.m.gg.i.resizeCanvas:{[renderer; accum; node]
    entry:  spec.ty.component.entry .z.m.axds.tree.node.item node;
    
    if[not spec.ty.canvas.splitframe entry;
        : i.continue[i.resizeFrom renderer; accum; node]];
    
    if[not[spec.ty.canvas.resize entry] and not spec.ty.canvas.dirty entry; : accum];

    sp: accum 0;
    renderObj: accum 1;

    renderObj: renderer[`initLocalRenderer][renderObj; sp; node];
    localRenderer : renderer[`localRenderer][renderObj; node];
    localRenderObj: renderer[`localRenderObj][renderObj; node];
    
    accum: {[localRenderer; accum; child]
        : i.resizeFrom[localRenderer; accum 1; child; accum 0];
        }[localRenderer]/[(sp; localRenderObj); spec.children[node; sp]];

    accum: renderer[`updateRenderObj][renderObj; accum 0; node; accum 1];

    sp      : accum 0;
    node    : spec.update[`dirty; 0b] node;
    node    : spec.update[`resize;0b] node;
    sp      : spec.modify[node;node`item;sp];
    accum[0]: sp;
    
    : accum;
    }

// @fileOverview
// Generate external node output 
// @param accum {(table;any)} spec and renderObj
// @param node {dict} external node
// @returns {(table;any)} Updated spec and unchanged renderObj
.z.m.gg.i.resizeExternal:{[renderer; accum; node]

    sp        : accum 0;
    renderObj : accum 1;

    sp     : .z.m.gg.spec.pluck[`defn;node][`preF][sp; node];
    node   : .z.m.axds.tree.find[node`id;sp];

    accum: $[not spec.pluck[`defn;node]`recurse;
            (sp;renderObj);
        h.null .z.m.gg.spec.pluck[`defn;node]`errorF;
            i.continue[i.resizeFrom renderer; (sp; renderObj); node];
        [
            errorF : {[renderer; renderObj; sp; node; err]
                sp   : spec.pluck[`defn;node][`errorF][sp; node; err];
                node : .z.m.axds.tree.find[node`id; sp];
                : $[spec.pluck[`defn;node]`recurse; 
                    i.continue[i.resizeFrom renderer; (sp; renderObj); node];
                    (sp; renderObj)];
                }[renderer;renderObj;sp;node];

            .[i.continue; (i.resizeFrom renderer; (sp; renderObj); node); errorF]]];

    sp        : accum 0;
    renderObj : accum 1;
    
    node   : .z.m.axds.tree.find[node`id;sp];
    sp     : .z.m.gg.spec.pluck[`defn;node][`postF][sp; node];
    node   : .z.m.axds.tree.find[node`id;sp];
    
    data   : .z.m.gg.spec.pluck[`defn;node]`data;
    output : .z.m.gg.spec.pluck[`defn;node][`outputF][data; .z.m.gg.spec.pluck[`state;node]];
    node   : spec.update[`output; output] node;
    sp     : spec.modify[node; node`item; sp];
    
    : (sp; renderObj);
    
    }


.z.m.gg.i.resizeFrom:{[renderer; renderObj; root; sp]

    entry : spec.ty.component.entry spec.node.item root;
    : $[spec.ty.layer.is entry;
            i.resizeLayer[renderer; (sp; renderObj); root];
      spec.ty.stack.is entry;
            i.resizeStack[renderer; (sp; renderObj); root];
      spec.ty.split.is entry;
            i.resizeStack[renderer; (sp; renderObj); root];
      spec.ty.title.is entry;
            i.resizeTitle[renderer; (sp; renderObj); root];
      spec.ty.theme.is entry;
            i.resizeTheme[renderer; (sp; renderObj); root];
      spec.ty.canvas.is entry;
            i.resizeCanvas[renderer; (sp; renderObj); root];
      spec.ty.external.is entry;
            i.resizeExternal[renderer; (sp; renderObj); root];
            i.continue[i.resizeFrom renderer; (sp; renderObj); root]];

    }

// @fileOverview 
// Draw a specification from a layer node. A frame is created
// and added to the specification. If a canvas node is provided,
// it is used as the drawing context. Otherwise, a new canvas will
// be created in the frame. The geometry etable is always added to
// the canvas, but decorations can be disabled. 
// @param renderer {dict} draw api implementation 
// @param accum {table} specification tree 
// @param node {dict} specification node acting as the root
// @returns {table} a specification with decoration nodes added
.z.m.gg.i.resizeLayer:{[renderer; accum; node]

    sp        : accum 0;
    renderObj : accum 1;
    lyr       : spec.pluck[`defn] node;
    th        : spec.theme [node; sp];
    
    stackNode : spec.ancestorWhere[{spec.ty.stack.is[x] or spec.ty.split.is x}; sp; node];

    shapetables : lyr`i_shapetables;
    sizes       : i.sizes       [th; lyr`coord; shapetables];
    
    shapetables : i.resizeYAxis [th; sizes]
                  i.resizeXAxis [th; sizes] shapetables;
    
    decorations : $[h.null stackNode; shapetables`decorations; spec.pluck[`get;stackNode] . `i_shapetables`decorations];

    frame       : $[h.null stackNode; 
        spec.frame.all[sizes; ::; decorations; th; lyr`coord; node];
        spec.pluck[`frame] stackNode];
    cvs         : spec.findAncestorCanvasNode[sp; node];

    if [h.null stackNode;
        shapetables : i.formatZAxis [th; frame; lyr`coord]
                      i.formatYAxis [th; frame; lyr`coord]
                      i.formatXAxis [th; frame; lyr`coord]
                      i.formatLegend[th; frame; lyr`coord] shapetables;
        frame    : i.bankSlopes[frame; lyr];
        renderObj: i.draw.on[renderer; renderObj; cvs; frame`frame;      coords.rect; shapetables . `decorations`frame];
        renderObj: i.draw.on[renderer; renderObj; cvs; frame`background; lyr`coord;   shapetables . `decorations`background];
        renderObj: i.drawDecorations[lyr`coord; renderer; renderObj; cvs; frame; shapetables`decorations]];
    
    sp       : spec.add.frame[frame; node; sp];
    frame    : spec.pluck[`frame] .z.m.axds.tree.find[node`id;sp];
    renderObj: i.draw.on[renderer; renderObj; cvs; first frame`geom; lyr`coord; shapetables`geom];
    
    : (sp; renderObj)
    }

.z.m.gg.i.resizeStack:{[renderer; accum; root]

    sp          : accum 0;
    renderObj   : accum 1;
    
    if[0 = count spec.stackLayers[sp; root]; : i.continue[i.resizeFrom renderer; (sp;renderObj); root]];
    
    stackAncestor : spec.ancestorWhere[{spec.ty.stack.is[x] or spec.ty.split.is x}; sp; root];
    
    if[not h.null stackAncestor;
        frame : spec.pluck[`frame] stackAncestor;
        sp    : spec.add.frame[frame; root; sp];
        : i.continue[i.resizeFrom renderer; (sp;renderObj); root]];

    details     : spec.ty.stack.get  spec.ty.component.entry spec.node.item root;
    th          : spec.theme [root; sp];
    
    shapetables : details`i_shapetables;
    sizes       : i.sizes        [th; details`coord; shapetables];
    shapetables : i.resizeYAxis  [th; sizes]
                  i.resizeXAxis  [th; sizes] shapetables;
    frame       : spec.frame.all [sizes; ::; shapetables`decorations; th; details`coord; root];
    cvs         : spec.findAncestorCanvasNode[sp; root];
        
    frame       : frame {[f;n] i.bankSlopes[f; spec.pluck[`defn] n] }/ spec.stackLayers[sp; root];
    sp          : spec.add.frame [frame; root; sp];
    shapetables : i.formatYAxis  [th; frame; details`coord]
                  i.formatXAxis  [th; frame; details`coord]
                  i.formatLegend [th; frame; details`coord] shapetables;
    
    renderObj   : i.draw.on [renderer; renderObj; cvs; frame`frame;      coords.rect;   shapetables . `decorations`frame];
    renderObj   : i.draw.on [renderer; renderObj; cvs; frame`background; details`coord; shapetables . `decorations`background];
    renderObj   : i.drawDecorations [details`coord; renderer; renderObj; cvs; frame; shapetables`decorations];

    ret : i.continue[i.resizeFrom renderer; (sp;renderObj); root];

    : i.stackCallbacks[root; renderer; ret 1; ret 0; frame]
    }

// @fileOverview 
// Draw a theme node - if a canvas_fill is present, then the background is coloured.
// @param renderer {dict} draw API 
// @param accum {table} specification tree 
// @param root {dict} tree node
.z.m.gg.i.resizeTheme:{[renderer; accum; root]
    sp        : accum 0;
    renderObj : accum 1;

    stackNode : spec.ancestor[spec.ty.stack; sp; root];
    if[h.null stackNode;
        cvs       : spec.findAncestorCanvasNode[sp; root];
        renderObj : i.drawCanvas[renderer; renderObj; cvs; root]];
    
    : i.resizeFrom[renderer; renderObj; first spec.children[root; sp]; sp];
    }


.z.m.gg.i.resizeTitle:{[renderer; accum; root]
    renderObj : accum 1;
    sp        : accum 0;
    th        : spec.theme[root; sp];
    item      : spec.node.item root;
    title     : spec.pluck[`get] item;
    titleNode : spec.component[spec.ty.component.origin item; spec.ty.component.w item; spec.ty.component.h item; ::];
    cvs       : spec.findAncestorCanvasNode[sp; root];
    g         : $[`left ~ th`title_anchor; etable.g.ATEXTL; `right ~ th`title_anchor; etable.g.ATEXTR; etable.g.ATEXTM];
    
    renderObj: i.draw.on[renderer; renderObj; cvs; titleNode; coords.rect]
        etable.el[etable.g.RECT; enlist `x`y`w`h`colour!(0; 1; 1; 1; th`title_background_fill)]
        , etable.el[g; enlist (!) . flip (
            (`text;     `$h.asString title);
            (`angle;    0);
            (`x;        "f"$th`title_x_start);
            (`y;        0.5);
            (`fontsize; th`title_fontsize);
            (`colour;   th`title_fill);
            (`bold;     th`title_bold);
            (`italic;   th`title_italic);
            (`offsetx;  th`title_x_offset))];
           
    : {[renderer; accum; child]
        : i.resizeFrom[renderer; accum 1; child; accum 0]
        }[renderer]/[(sp;renderObj);] spec.children[root; sp];
    }

.z.m.gg.i.resizeXAxis:{[theme; sizes; shapetables] : shapetables; }

// @fileOverview 
// Given a yaxis shape table, reposition the components of the axis so that scaling does not skew the
// spacing (tick label should be x pixels from the left, ticks should be y pixels long, etc)
// @param th {dict} 
// @param sizes {dict (x:float; y:float; y2:float)} axis sizes (null where default) 
// @param shapetables {dict (decorations: dict (yaxis: any))} all shapetables for a given layer 
// @returns {dict (decorations: dict (yaxis: any))} updated shapetables
.z.m.gg.i.resizeYAxis:{[th; sizes; shapetables]
    yaxis : shapetables[`decorations]`yaxis;
    
    if [(::) ~ yaxis; shapetables];
    
    if [not null sizes`y;
        yaxis: update settings: {[t;s;x] $[not 0.1~x`x; x; @[x;`x;:;15%s]]   }[th;sizes`y]'[settings] from yaxis where geometry = `atextM;
        
        yaxis: update settings: {[t;s;x] $[not t[`axis_tick_label_start_y]~x`x; x; @[x;`x;:;1-10%s]] }[th;sizes`y]'[settings] from yaxis where geometry = `atextR;
        
        yaxis: update settings: {[t;s;x] $[0 1~raze x`y1`y2; x; @[x;`x2;:;1-6%s]] }[th;sizes`y]'[settings] from yaxis where geometry = `line];
    
    : .[shapetables; `decorations`yaxis; :; yaxis];
    
    }
// @fileOverview Sanitize a label for display
// @param th {dict} theme
// @param x {any} label
// @returns {string} Label to display
.z.m.gg.i.sanitizeLabel:{[th;x] ssr/[;th`axis_label_separators;" "] h.asString x }

.z.m.gg.i.sizes:{[theme; coords; shapetables] `x`y`y2!(0n; i.yaxisSize[theme; coords; shapetables]; 0n) }

// @fileOverview 
// Return a dictionary of decorations (axes/legends/etc) for a stack.
// @param sp {table} specification table 
// @param root {dict} specification node acting as root
// @returns {dict}
.z.m.gg.i.splitDecorations:{[sp; root]
    th          : spec.theme[root; sp];
    details     : spec.pluck[`get] root;
    labels      : i.stackLabels[th; ; sp] each spec.children[root; sp];
    decorations : i.decorations [th; raze details`x`left; details`coord; labels $[count details`left; 0; 1]; ()];
    
    if [spec.frame.useAxis[th; details`coord; `y] and count details`right;
        decorations[`yaxis2] : i.rules.yaxis2[th; details`coord; labels[1]`y; details[`right]`y]];
    
    decorations[`legends]: i.stackLegends[sp; root; th; labels $[count details`left; 0; 1]];
    : decorations;
    }

.z.m.gg.i.stackCallbacks:{[root; renderer; renderObj; sp; frame]
    
    substacks: spec.every[spec.ty.stack] select from .z.m.axds.tree.descendants[root;sp] where not null id;

    renderObj: {[renderer; sp; renderObj; frame; root]
        post: spec.ty.stack.post spec.ty.component.entry spec.node.item root;
        cvs : spec.findAncestorCanvasNode[sp; root];

        if [not (::) ~ post;
            : .[post; (renderer; renderObj; cvs; frame`geom;
                .\:[;`i_shapetables`geom] .z.m.gg.spec.pluck[`defn] spec.stackLayers[sp; root]);
                {'"Error in post-stack fn: ", x}]];
        : renderObj;
        
        }[renderer;sp;;frame]/[renderObj; root , substacks];

    : (sp; renderObj)
    }

// @fileOverview 
// Return a dictionary of decorations (axes/legends/etc) for a stack.
// @param sp {table} specification table 
// @param root {dict} specification node acting as root
// @returns {dict}
.z.m.gg.i.stackDecorations:{[sp; root]
    details     : spec.pluck[`get] root;
    decorations : i.decorations [details`theme; details`scales; details`coord; i.stackLabels[details`theme; root; sp]; ()];
    labels      : i.stackLabels[details`theme; root; sp];
    decorations[`legends]: i.stackLegends[sp; root; details`theme; labels];
    : decorations;
    }


.z.m.gg.i.stackLabels:{[theme; root; spec]
    lblTbl: {[spec; node]
        : layer.labels[spec.theme[node; spec]; spec.pluck[`defn] node];
        }[spec] each spec.stackLayers[spec; root];
    : `x`y`z!{ ",  " sv h.asString each distinct h.atAll[y] x }[lblTbl] @/: `x`y`z;
    }
.z.m.gg.i.stackLegends:{[sp; root; th; labels]
    lyrs: spec.stackLayers[sp; root];
    
    legends: distinct raze {[sp; lyrNode]
        lyr     : spec.pluck[`defn] lyrNode;
        th      : spec.theme[lyrNode; sp];
        lbls    : layer.labels[th; lyr];
        lkeys   : i.legendKeys[th; lyr`scales];
        pairs   : flip (key;value)@\:lkeys#lyr`scales;
        legends : (enlist each lbls pairs[;0]) ,' pairs;
        
        : legends, {[th;x]
            s: scale.initBreaks $[.z.m.gg.scale.base.is x`ticks;
                x`ticks;
                scale.init[scale.colour.cat x`ticks; key x`ticks]];
            : (x`title;`custom;s);
            }[th] each lyr`legends;
        }[sp] each lyrs;

     : i.rules.legend[th]'[legends[;0]; legends[;2]];
    }

.z.m.gg.i.useDynamicAxes:{[theme; coords]
    : (coords.rect[`label] ~ coords`label) and theme`dynamic_axes
    }

.z.m.gg.i.yaxisSize:{[th; co; shapetables]
    labelSpacing : 40;
    
    if [not i.useDynamicAxes[th; co]; : 0n];
    if [(::) ~ shapetables[`decorations]`yaxis; : 0n];
    
    labels : raze .z.m.gg.etable.settings .z.m.gg.etable.every[.z.m.gg.etable.g.ATEXTR] shapetables[`decorations]`yaxis;
    
    if [0 = count labels; : labelSpacing];
    
    
    : "j"$labelSpacing + max h.maxTextWidth [th`axis_tick_label_fontsize] each "\n" vs'exec .z.m.gg.h.asString text from labels;
     
    }


.z.m.gg.new:{[s]
    : i.init.splits
        i.init.sharedScales
        i.init.stacks
        i.init.layers
        i.init.externals
        i.init.normDeps
        i.init.facets
            ty.new (::; s; ::; 0b; enlist[("";()!())]!enlist(::));;
    }

// @private
// @fileOverview
// Initialize a new GG spec with separated frames
// Canvas nodes in the spec are dirtied so that they are drawn
// @param sp {table} A specification tree (see .z.m.gg.spec)
// @returns {dict} Initialized GG object
.z.m.gg.newWithSplit:{[sp]
    : new {[sp] spec.makeDirty[sp; spec.root sp]} spec.splitFrames sp;
    }


.z.m.gg.resize:{[w; h; gg]
    if [not all (w;h) within\: 1 10000;
        '.z.m.axlocalize.t`.gg_imageTooBig];
    
    : resizeUsing[i.DEFAULTRENDERER; w; h; gg];
    
    }
// @fileOverview 
//
// Given a renderer implementation, display an initialized GG object
// with the given width and height.
// 
// A new specification tree will be created, and returned as part of
// the resulting GG object. The new specification tree will have every
// node in the tree correctly sized with a origin (w,h), width, and height.
// Tree nodes for all frame components for every layer and stack will be
// added to the tree. The origin of each node will be specified as an
// absolute location.
// 
// As an example, the following uninitialized specification tree:
// 
//      Example 1 below
// 
// becomes (without padding, styling, etc):
// 
//      Example 2 below
// 
// The tree is descended starting at the root, drawing each node individually.
//
// @param r {dict} renderer implementation 
// @param w {long} width 
// @param h {long} height 
// @param gg {dict} initialized GG object 
// @see gg.displayUsing
//
// @returns {dict} a new GG object with an updated specification tree and output
// @example 1
//      vert 
//      \_ layer
//
// @example 2
//      vert (0,0), 500, 500
//      \_ layer (0,0), 500, 500
//         \_ canvas (50, 0), 450, 450
//         \_ xaxis (50, 450), 450, 50
//         \_ yaxis (0,0), 50, 450
//         \_ ...
.z.m.gg.resizeUsing:{[r; w; h; gg]
    sp : spec.with.size[w; h; ty.spec gg];
    
    obj   : r[`new][w; h];
    accum : i.resizeFrom [r; obj; spec.root sp; sp];
    sp    : accum 0;
    obj   : accum 1;
    
    out: outputD.new (r`LABEL; w; h; r[`render] obj);
    r[`remove] obj;
    
    : ty.with.spec[sp] ty.with.output[out] gg;
    
    }

.z.m.gg.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.gg_pushError;"push error: the visual must be displayed first");
        (`.gg_imageTooBig; "Images must be smaller than 10000x10000")
    ))
.z.m.gg.i.DEFAULTRENDERER:.z.m.axskiaw
// @private
.z.m.gg.onLoad:{[]
    
    
    
    
    .z.m.axdatatype.create[ .z.M.gg.outputD; `label`w`h`bytes; ()];
    
    
    .z.m.axdatatype.create[ .z.M.gg.ty; `id`spec`output`splitframes`statcache; `spec`output`splitframes`statcache];
    }

.z.m.gg.onLoad[];
system "d .z.m";

system "d .z.m.st";
// @fileOverview 
// Return a description of an `avg` aggregation.
//
// Note - the aggregation will be mapped to the column name. For an aggregation
// with an explicit output mapping (to avoid collisions with other aggregations
// on the same column, see .z.m.st.a.custom).
// @see st.a.custom
// @param col {symbol} column name to avg
// @example An average aggregation of a column
// .z.m.st.a.avg[`mycolumn]
// @example A count and avg aggregation
// .z.m.st.a.count[] , .z.m.st.a.avg[`mycolumn]
.z.m.st.a.avg:{[col]
    : enlist [`avg__]! enlist `column`mod!(col;`avg)
    }

// @fileOverview 
// Return a count aggregation description. The output will be mapped
// to a variable named `count__`.
// @returns {dict}
// @example A count aggregation
// .z.m.st.a.count[]
.z.m.st.a.count:{[]
    : enlist [`count__]! enlist `column`mod!(`i;count)
    }

// @fileOverview 
// Return a description for a custom aggregation on a
// table. The custom function should take a 
// list of the type of the column, and return a single
// value (e.g. `avg`, `dev`, `{count distinct x}`, etc)
// @param n {symbol} name of resulting column 
// @param col {symbol} name of column to aggregate 
// @param customF {fn} function to aggregate sublists of the column
// @returns {dict}
// @example Custom average aggregator
// .z.m.st.a.custom[`outputName__; `mycolumn; avg]
// @example Count and a custom aggregator count occurrences
// .z.m.st.a.count[] , .z.m.st.a.custom[`output__; `mycolumn; {count where x = `something}]
.z.m.st.a.custom:{[n; col; customF]
    : enlist [n]!enlist `column`mod!(col; customF)
    }

// @fileOverview 
// Return a description of a max aggregation.
//
// Note - the output will be mapped to the column name. For an aggregation
// with an explicit output mapping (to avoid collisions with other aggregations
// on the same column, see .z.m.st.a.custom).
// @param col {symbol} column name to max
// @see st.a.custom
.z.m.st.a.max:{[col]
    : enlist [`max__]! enlist `column`mod!(col;`max)
    }

// @fileOverview 
// Return a description of a min aggregation
//
// Note - the output will be mapped to the column name. For an aggregation
// with an explicit output mapping (to avoid collisions with other aggregations
// on the same column, see .z.m.st.a.custom).
// @see st.a.custom
// @param col {symbol} column name to min
.z.m.st.a.min:{[col]
    : enlist [`min__]! enlist `column`mod!(col;`min)
    }

// @fileOverview 
// Return a description of a sum aggregation
//
// Note - the output will be mapped to the column name. For an aggregation
// with an explicit output mapping (to avoid collisions with other aggregations
// on the same column, see .z.m.st.a.custom).
// @see st.a.custom
// @param col {symbol} column name to sum
.z.m.st.a.sum:{[col]
    : enlist [`sum__]! enlist `column`mod!(col;`sum)
    }


.z.m.st.bin1d:{[col; val; aggs; options; table]
    .z.m.gg.h.assert.colExists[table; col];
    
    defaultArgs: (val ~ (::)) & options ~ (::);
    
    if [defaultArgs & .z.m.st.usePartitionedBins[table;col];
        cstr:  string col;
        cs:    `$(cstr; cstr,"_start__";cstr,"_end__");
        aggrs: { ({$[-11=type x;value string x;x]};::)@'reverse value x} each aggs;
        t:     0!?[.z.m.gg.tbl.unbox table;();enlist[col]!enlist col; aggrs];
        : cs xcols @[t;1_cs;:;(t col; 1+t col)]];
    
    scale: .z.m.gg.scale.fromMeta[0b] .z.m.gg.tbl.metatype[table; col];
    : .z.m.st.sbin1d[col; val; scale; aggs; options; table];
    }


.z.m.st.bin2d:{[columns; xbins; ybins; mods; options; table]
    .z.m.gg.h.assert.colExists[table] each columns;
    
    xscale  : .z.m.gg.scale.fromMeta[0b] .z.m.gg.tbl.metatype[table; columns 0];
    yscale  : .z.m.gg.scale.fromMeta[0b] .z.m.gg.tbl.metatype[table; columns 1];
    : sbin2d[columns; xbins; ybins; xscale; yscale; mods; options; table];
    };
// @fileOverview 
// Perform an nD binning and all specified aggregations on the bins
// of a specified table.
// @see st.bin1d
// @param columns {symbol[]} list of column names to bin
// @param xbins {(symbol;number;number)} width or count (`` `w `` or `` `c ``) and argument 
// @param ybins {(symbol;number;number)} width or count (`` `w `` or `` `c ``) and argument 
// @param mods {dict} aggregations to perform 
// @param options {dict|null} see .z.m.st.bin2d
// @param table {table}
// @returns {table}
// @throws "column x not found"
.z.m.st.binNd:{[columns; binDesc; mods; options; table]
    .z.m.gg.h.assert.colExists[table] each columns;
    
    scales : {[t;c] .z.m.gg.scale.fromMeta[0b] .z.m.gg.tbl.metatype[t; c]}[table] each columns;
    : sbinNd[columns; binDesc; scales; mods; options; table];
    };
// @private
// @fileOverview 
// Return the size and count of both x and y binDescrs
// @private
// @param t {table} 
// @param cs {symbol[]} columns
// @param descrs {any[]} bin descriptions
// @param sc {dict[]} scales
// @returns {dict} bin counts and widths
.z.m.st.bins:{[t; cs; descrs; sc]
    .z.m.gg.h.assert.colExists[t] each cs;
    
    res : {[t;c;s;b]
        fromWidth : {[s;x;p] (ceiling (p + i.expandIfZero (-). desc s`limits) % x; x; ::; `numeric) };
        
        fromCount : {[s;x;p] (x; (p + i.expandIfZero (-). desc s`limits) % x; ::; `numeric) };
        
        fromTemporal : {[t;c;k;w]
            actual: .z.m.gg.h.METATYPES .z.m.gg.h.metatype[t;c];
            if [(not actual in i.TEMPORALS) | (k;actual) in i.INVALID_TEMPORAL_CASTS;
                '"Unable to bin data: cannot convert type ",
                "`",string[actual],"` to target type `",string[k],"`"];

            values: (max;min)@\:k$.z.m.gg.h.removeInfs .z.m.gg.tbl.column[t;c];
            : (ceiling %[;w] 1 + (-) . values; "j"$w; values; k)
            };

        : $[b[0] ~ `by; 
                (0N;0N;();`by);
            b[0] in i.TEMPORALS;
                fromTemporal[t; c; b 0; b 1];
            b[0] in `w`width;
                fromWidth[s; b 1; b 2];
                fromCount[s; b 1; b 2]]
        };
    
    descrs : res[t]'[cs; sc; descrs];
    num    : prd descrs[;0];
    r      : `count`num`width`values`kind!("j"$num; "j"$descrs[;0]; descrs[;1]; descrs[;2]; descrs[;3]);
    
    i.validateBinCounts[cs; r];
    
    : r;
    }

// @private
// @fileOverview 
// Extract records from the table that match a given value in one column
// @param x {symbol} column name 
// @param xval {any}
// @param columns {symbol[]} list of columns to extract
// @param table {table} 
// @returns {table}
// @throws "column x not found"
// @private
.z.m.st.extract:{[x; xval; columns; table]
    
    
    if [not -11h ~ type x;
        : table];
    
    if [not x in .z.m.gg.tbl.colnames table;
        : table];
    
    match : $[0 <= type xval; (~\:); (=)];
    matchClause : $[x in .z.m.gg.tbl.colnames table; (match; x; .z.m.gg.h.enlistIfSymbol xval); 1b];
    : .z.m.table.query[table; enlist matchClause; 0b; columns!columns];
    
    }

// @fileOverview Calculates the factorial of a number
// This uses floats, as longs overflow too quickly
// @param x {Number}
// @returns {float}
.z.m.st.factorial:{*/[1f + til x]}

// @fileOverview Generate a normal distribution
// @param n {Long} The number of points to generate
// @returns {Float[]} The random data points
.z.m.st.gen.normal:{[n]
    
    half: ceiling n % 2;
    co1: sqrt -2 * log half?1f;
    co2: 6.2831853071795862 * half?1f;
    l: (co1 * cos co2) , co1 * sin co2;

    : $[n mod 2;
        1 _ l;
        l];
    }
// @fileOverview Return bin bounds as a list
// @param cs {symbol[]} columns
// @param d {dict} bin descriptions
// @param s {dict[]} scales
// @returns {any[]} bin bounds
.z.m.st.i.bin.bounds:{[cs;d;s]
    bs: {[s;n;w;k;v]
        : $[k in i.TEMPORALS;
            v[1] + w * til 2|ceiling (2 + (-) . v) % w;
            s[`limits;0] + w * til 0^"j"$n + 1]
        }'[s;d`num;d`width;d`kind;d`values];
    
    if [any r:0 = .z.m.gg.h.safeRange each (first;last)@\:/:bs;
        '.z.m.axstr.interp["bin columns ({0}) do not have large enough range for binning"] ", " sv string cs where r];
    
    : bs
    }

// @fileOverview 
// Given a table, a column, and a list of bounds, determine the 
// the closest bound to each data item without going over.
// @param k {symbol} bin kind (numeric, month, etc)
// @param c {symbol} column name 
// @param b {number[]} list of bounds 
// @returns {number[]} index of bound for each data item
.z.m.st.i.bin.col:{[k; c; b]
    if [0 = count c;
        : `long$()];
    
    $[k in i.TEMPORALS;
        [
            bi: b bin k$c;
            bi[where (bi = -1)|bi = -1 + count b]: 0N];
        [
            is : count[b]-1; // Intervals
            r  : (-).(last;first)@\:b;
            bi : floor obi: (c - b 0) % r % is;

            if [`arm64 ~ .z.m.axenv.arch[];
                bi[.z.m.gg.h.infPos bi]: 0N;
                bi[where null obi] : 0N];

            if [.z.m.gg.h.metatype[([]x:c); `x] in "ijdtvump"; /dnl
                bi[.z.m.gg.h.infPos c]: type[c]$0N];
            
            if [is = max bi; bi[where bi = is]: is - 1]]];
    
    if [1h ~ type c; bi &: 1];
        
    if [0 > min bi; bi[where (bi < 0) & not null bi] : 0];
    
    : bi;
    
    }

// @fileOverview Bin values of a single column
// @param t {table|#.z.m.gg.tbl.ty} 
// @param c {symbol} column
// @param s {dict} scale
// @param k {symbol} bin kind
// @param b {any[]} bin bounds
// @returns {symbol|long[]} 'by' if the column should be used in the qsql by-clause, otherwise bin indexes
.z.m.st.i.bin.column:{[t;c;s;k;b]
    : $[k ~ `by; `by; i.bin.col[k; i.scaleColumn[t; c; s; k]; b]]
    }

// @fileOverview Center bin positions in the middle of a bin rather than the start
// @param cs {symbol[]} columns
// @param d {dict} bin description
// @param t {table|#.z.m.gg.tbl.ty} 
// @returns {table} Table with bins centered
.z.m.st.i.center:{[cs; d; t]
    : {[t; c; w]         
         if [(not null w) & .z.m.gg.tbl.metatype[t; c] in "bxhijef"; t[c] +: w % 2];
         : t
         }/[t; cs; d`width]
    }

// @fileOverview 
// If the value given is zero, expand by one (to 1)
// @param r {number}
// @returns {number}
.z.m.st.i.expandIfZero:{[r]
    : $[r = 0; 1; r];
    }

// @fileOverview Hexbin a source table
// @param t {table} 
// @param cs {symbol[]} columns to bin
// @param d {dict} bin descriptions
// @param scales {dict[]} 
// @param mods {dict[]} aggregations to apply
// @returns {table} hex binned table
.z.m.st.i.hexbin:{[t;cs;d;scales;mods]
    if [2 <> count cs; '"Hexbins requires exactly two columns"];
    d:     bins[t; cs; resolveBins[t]'[d; cs; scales]; scales];
    bs:    i.hexbins[t; cs; d`num; d`width; d`kind; scales];
    agg:   0!?[t; (); `bx__`by__!bs; mods@\:`mod`column];
    hex:   {[x;y;w;h] "f"$flip(x;y)+'/:(w*sin@;h*cos@)@\:/:(2*PI*til 6)%6 };
    m:     hex[;;d[`width][0]%sqrt 3; d[`width][1]%sqrt 3];
    hexes: cs!/:scales .z.m.gg.scale.inverse'/: (m') . agg`bx__`by__;
    : hexes ,' `bx__`by__ _ agg
    }

// @fileOverview Find the hexbin center closest to each point of a table
// @param t {table} 
// @param cs {symbol[]} columns to bin
// @param n {long} bin count
// @param w {float} bin widths
// @param ks {symbol[]} bin kinds
// @param scales {dict[]}
// @returns {float[][]} bin centers
.z.m.st.i.hexbins:{[t;cs;n;w;ks;scales]
    c1: i.scaleColumn[t; cs 0; scales 0; ks 0];
    c2: i.scaleColumn[t; cs 1; scales 1; ks 1];
    d:  {[x;y;x1;y1] sqrt ({x*x} x - x1) + {x*x} y - y1 };       // distance
    bc: {[v;s] d: v div s % 2; (s%2)*d+/:(::;not)@\:1=d mod 2 }; // bin centers
    px: bc[c1; w 0];
    py: bc[c2; w[1] * sqrt 3];
    z1: d[c1; c2; px 0; py 0];
    z2: d[c1; c2; px 1; py 1];
    : (?[b; px 0; px 1]; ?[b:z1<z2; py 0; py 1])
    }
.z.m.st.i.initScales:{[table; columns; scales]
    {[t;s;c] .z.m.gg.scale.validate[s; .z.m.gg.tbl.column[t;c]] }[table]'[scales; columns];
    
    : {[t; sc; c] .z.m.gg.scale.init[sc] .z.m.gg.tbl.column[t; c] }[table]'[scales; columns];
    }

// @fileOverview 
// Normalize a column of a table (optionally by another column)
// @param ncol {symbol} column to normalize BY (or ` for none)
// @param col {symbol} column to normalize 
// @param outcol {symbol} column name to output to
// @param table {table}
// @returns {table}
.z.m.st.i.normalize:{[ncol; col; outcol; table]
    
    : $[not ncol ~ `;
        [   .z.m.gg.h.assert.colExists[table] each (ncol; col);
            .z.m.gg.h.assert.colType[i.CTYPES; table; col];
            b : ?[table;();ncol;(sum;col)]; // totals
            ![table;();0b;(enlist outcol)!enlist (%; col;(b; ncol))]]; // normalize
        
        [   .z.m.gg.h.assert.colExists[table; col];
            .z.m.gg.h.assert.colType[i.CTYPES; table; col];
            b : ?[table;();();(sum;col)]; // total
            ![table;();0b;(enlist outcol)!enlist (%;col;b)]]];
        
    }

// @fileOverview Bin a source table
// @param cs {symbol[]} columns to bin
// @param bs {any[]} bin bounds
// @param d {dict} bin descriptions
// @param mods {dict[]} aggregations to apply
// @param sc {dict[]} scales
// @param t {table} table to bin
// @returns {table} binned table
.z.m.st.i.qsql.bin:{[cs;bs;d;mods;sc;t]
    
    bis: i.bin.column[t]'[cs; sc; d`kind; bs];
    bi:  bis ~\: `by;
    lb:  sum {$[y~1;x;x*y]}'[bis where not bi; -1 _ prds 1 , d[`num] where not bi];  // linear bins
    cb:  {x!x} cs where bi;                                                          // columns using by
    bs:  {x!first,/:x} cs where not bi;                                              // add in column bin index
    
    t[cs where not bi]: bis where not bi;
    
    : (1#`bin__) _ 0!?[t; 
        (); 
        cb , $[0 <> count lb; (1#`bin__)!enlist lb; ()!()];
        bs , mods@\:`mod`column];
    }

// @fileOverview Add start and end bounds for non 'by' binned columns
// @param cs {symbol[]} columns
// @param scales {dict[]} 
// @param ks {symbol[]} bin kinds
// @param bs {any[]} bin bounds
// @param binned {table} binned table
// @param converted {table} cast binned table
// @returns {table} extended table
.z.m.st.i.qsql.bounds:{[cs; scales; ks; bs; binned; converted]
    bounds: raze {[t;c;s;k;b] 
        if [k ~ `by; : (`$())!()]; 
        f: $[k in i.TEMPORALS; ::; .z.m.gg.scale.inverse s];
        n: `$string[c] ,/: ("_start__";"_end__");
        : n!f each (b;next b) @\: t c
        }[binned]'[cs; scales; ks; bs];
    
    : $[0 < count bounds;
        converted ,' flip bounds;
        converted];
    }

// @fileOverview Back cast types to their source types
// @param bs {any[]} bin bounds 
// @param cs {symbol[]} columns
// @param scales {dict[]} scales
// @param ks {symbol[]} bin kinds
// @param t {table} 
// @returns {table}
.z.m.st.i.qsql.cast:{[bs;cs;scales;ks;t]
    : ![t; (); 0b; 
        cs!{[c;s;b;k]
            : $[k ~ `by; c; k in i.TEMPORALS; (b;c); (.z.m.gg.scale.inverse s; (b;c))]
            }'[cs;scales;bs;ks]];
    }

// @fileOverview Filter out nulls in a binning result
// @param cs {symbol[]} columns
// @param t {table} binning result
// @returns {table} binning result with nulls removed
.z.m.st.i.qsql.filter:{[cs;t] 
    cs: cs where .z.m.gg.h.metatype[t]'[cs] in key[.z.m.gg.h.METATYPES] except " Ccbg";
    if [0 = count cs; : t];
    : ?[t; {(not;(null;x))} each cs; 0b; ()] 
    }

.z.m.st.i.scaleColumn:{[t; c; s; k]
    c: .z.m.gg.tbl.column[t; c];
    : $[k in i.TEMPORALS; ::; .z.m.gg.scale.apply s] c
    }

// @fileOverview Validate bin numbers are within usable ranges
.z.m.st.i.validateBinCounts:{[columns; descr]
    if [i.MAX_BINS < first raze descr`count;
        '.z.m.axlocalize.t(`.st_binCountError; `found`supported!(
            .z.m.gg.h.printNum[.z.m.gg.h.print; ::; descr`count];
            .z.m.gg.h.printNum[.z.m.gg.h.print; ::; i.MAX_BINS]))];
    
    if [0 < count w:where i.MAX_COLUMN_BINS < descr`num;
        '"Unable to bin ", (", "sv {"`",x,"`"} each string columns w) ,
            " since bin count would be greater than max of ",string i.MAX_COLUMN_BINS];
    }

// @fileOverview 
// Return a 1000-point sampling of the d-degree least squares fit of the 
// x and y column of the given table
// @param x {symbol} column name  
// @param y {symbol} column name 
// @param d {long} degree (i.e., between 0-4) 
// @param t {table|dict} table or .z.m.gg.tbl.ty instance
// @returns {table} 1000-point sampling
.z.m.st.lsqTable:{[x; y; d; t]
    : lsqTableGrouped[x; y; `; d; t];
    }
// @fileOverview 
// Return a 1000-point sampling of the d-degree least squares fit of the 
// x and y column of the given table
// @param x {symbol} column name  
// @param y {symbol} column name 
// @param g {symbol} group column name 
// @param d {long} degree (i.e., between 0-4) 
// @param t {table|dict} table or .z.m.gg.tbl.ty instance
// @returns {table} 1000-point sampling
.z.m.st.lsqTableGrouped:{[x; y; g; d; t]
    .z.m.gg.h.assert.colExists[t] each (x;y);
    if [not null g; .z.m.gg.h.assert.colExists[t; g]];
    .z.m.gg.h.assert.colType[i.CTYPES except "b"; t; x];
    .z.m.gg.h.assert.colType[i.CTYPES except "b"; t; y];
    
    if [.z.m.gg.tbl.isempty t;
        : t];
    
    t:   flip `x`y`g!.z.m.gg.tbl.column[t] each (x;y;g);
    xsc: .z.m.gg.scale.init[.z.m.gg.scale.fromMeta[0b] .z.m.gg.h.metatype[t;`x]] t`x;
    ysc: .z.m.gg.scale.init[.z.m.gg.scale.fromMeta[0b] .z.m.gg.h.metatype[t;`y]] t`y;
   
    dom: 
        (.z.m.gg.scale.apply[xsc] distinct .z.m.gg.scale.inverse[xsc]@) each
        exec {x + til[1000] * (y-x)%1000} . .z.m.gg.scale.apply[xsc] (min;max)@\:x by g from t;
    
    fit: exec 
        first (enlist "f"$.z.m.gg.scale.apply[ysc;y]) lsq ("f"$.z.m.gg.scale.apply[xsc;x]) xexp/: til 1 + d 
        by g from t where not null .z.m.gg.scale.apply[ysc;y], not null .z.m.gg.scale.apply[xsc;x];
    
    res: fit { sum each x*'/:y xexp'\:til count x}' dom;
    
    : $[null g; (x;y) xcol enlist[`g]_; (x;y;g) xcol]
        @[;`y;.z.m.gg.scale.inverse ysc]       // cast back to original domain
        @[;`x;.z.m.gg.scale.inverse xsc]       
        raze {[k;d;r] ([]x:d;y:r;g:k) }'[key dom; dom; res]
    }
// @fileOverview 
// Return the coefficients of the d-degree least-squares fit on the given table
// @param x {symbol} column 
// @param y {symbol} column 
// @param d {long} degree (i.e., between 0-4) 
// @param table {table|dict} table or .z.m.gg.tbl.ty instance
// @returns {number[]} coefficients
.z.m.st.lsquares:{[x;y;d;table]
    (enlist "f"$.z.m.gg.tbl.column[table;y]) lsq "f"$.z.m.gg.tbl.column[table;x] xexp/: til 1 + d
    }
// @fileOverview The probability density function of a normal distribution
// @param u {Number} The mean value
// @param stddev {Number} The variance
// @param x {Number} The x value
// @returns {Number}
.z.m.st.normalPDF:{[u; stddev; x]
    
    if [stddev <= 0;
        : 0n];
    
    : (1 % stddev * sqrt 6.28318530717958646) * 2.71828182845904523 xexp -.5 * {x*x} (x - u) % stddev;
    }
// @fileOverview 
// Return the "outliers" component of a box-plot. All data points further
// than 1.5 times the interquartile range from the median are returned.
// @param catcol {symbol} categorical column 
// @param numcol {symbol} numeric column 
// @param table {table}
// @returns {table}
// @see st.summary
// @example
//      t : ([]x:45?5?`8; y:45?45);
//
//      .z.m.st.outliers[`x; `y; t]
//
// /=> x        y 
// /=> -----------
// /=> mijpkecf 44
// /=> kiggemin 39
.z.m.st.outliers:{[catcol; numcol; table]
    
    table : .z.m.gg.tbl.box table;
    
    if [.z.m.gg.tbl.isempty table;
        : table];
    
    : (,/) {[table; xc; yc; x]
        match : $[0 <= type x xc; (~\:); (=)];
        matchClause : $[xc in .z.m.gg.tbl.colnames table; (match; xc; .z.m.gg.h.enlistIfSymbol x xc); 1b];
        index : .z.m.table.indices[.z.m.gg.tbl.ty.raw table; (matchClause; (|; (<;yc;x `lower__); (>;yc;x `upper__)))];
        : .z.m.table.index[.z.m.gg.tbl.ty.raw table; index];
        }[table; first .z.m.gg.h.sanitize catcol; first .z.m.gg.h.sanitize numcol] each summary[catcol; numcol; table];
    
    }

// @fileOverview The probability mass function of a poisson distribution
// @param l {Number} The mean value
// @param k {Number} The number of occurrences
// @returns {Float} The probability of a given outcome
.z.m.st.poissonPMF:{[l;k]
    (2.71828182845904523 xexp neg l) * (l xexp k)%factorial k
    }
// @fileOverview 
// Perform a quantile transform on a numeric column
// @param x {symbol} numeric column name
// @param table {table}
// @returns {table}
// @throws "column x not found"
// @throws "column x of type y not one of z"
// @example
//      t:([]x:45?45);
//
//      .z.m.st.quantile[`x; t]
//
// /=> x  fvalue__  
// /=> -------------
// /=> 0  0.01111111
// /=> 0  0.03333333
// /=> 1  0.05555556
// /=> 1  0.07777778
// /=> 1  0.1       
// /=> 2  0.1222222 
// /=> 2  0.1444444 
// /=> ...
.z.m.st.quantile:{[x; table]
    
    .z.m.gg.h.assert.colExists[table; x];
    .z.m.gg.h.assert.colType[i.CTYPES; table; x];
    
    col : .z.m.gg.tbl.column[table; x];
    f   : {[n;k](k - 0.5) % n};
    : (x;`fvalue__) xcol ([]x__ :asc col; y__ : "f"$f[count col] each 1+til count col);
    
    }

// @fileOverview Calculate the nth quantile of a list via linear interpolation
// @param x {number[]}
// @param percentiles {float|float[]} A number, or list of numbers, between 0 and 1
// @returns {number}
.z.m.st.quantiles:{[x; percentiles]
    
    if [any (percentiles <= 0) or percentiles >= 1;
        ' "Invalid percentile"];
    
    outputType: $[
        type[x] in 12 13 14 15h;
            `timestamp;
        type[x] in 16 17 18 19h;
            `timespan;
            `float];
    
    rangeType: $[type[x] in 12 13 14 15 16 17 18 19h; `timespan; `float];
    
    x: asc x;
    
    x: (null[x]?0b) _ x;
    
    results: {[outputType; rangeType; x; percentile]
        if [1 ~ count x;
            : outputType$first x];
        
        index: percentile * (count x) - 1;
        integer: floor index;
        decimal: index - floor index;
        : (outputType$x integer) + rangeType$decimal * (outputType$x integer + 1) - outputType$x integer;
        }[outputType; rangeType; x] each .z.m.axq.asList percentiles;
    
    : $[1 ~ count percentiles;
        first results;
        results];
    }
// @fileOverview 
// Take the quartiles of column y of the table for each distinct column x value.
//
// The output columns are the following:
//
// - the first column has the same name as the given categorical column (x)
// - `q1__` - first quartile
// - `q2__` - second quartile
// - `q3__` - third quartile
// @param x {symbol} 
// @param y {symbol} 
// @see st.summary
// @param table {table}
// @returns {table}
// @throws "column x not found"
// @throws "column x of type y not one of z"
// @example 
//      t: ([]x:45?5?`8; y:45?45);
//
//      .z.m.st.quartiles[`x; `y; t]
//
// /=> x        q1__ q2__ q3__
// /=> -----------------------
// /=> npccjbfg 4    23   32.5
// /=> kcjfooab 7.5  23.5 31  
// /=> jnmhejla 14   23   30  
// /=> iiphmkna 16   25.5 31  
// /=> gnlighkg 22   34   41  
.z.m.st.quartiles:{[x; y; table]
    
    .z.m.gg.h.assert.colExists[table; x];
    .z.m.gg.h.assert.colExists[table; y];
    .z.m.gg.h.assert.colType[i.BASETYPES; table; x];
    .z.m.gg.h.assert.colType[i.CTYPES; table; y];
    
    colNames : (x;`q1__;`q2__;`q3__);
    colTypes : .z.m.gg.tbl.metatype[table; x] , 3#.z.m.gg.tbl.metatype[table; y];
    
    l: $[.z.m.axq.isNull x; enlist (::); distinct .z.m.gg.tbl.column [table;x]];
        
    if [0 = count l;
        : flip colNames!colTypes$\:()];
    
    : .z.m.gg.h.sanitize[(x;`q1__;`q2__;`q3__)] xcol {[x; y; table; xval]
        t: extract [x; xval; enlist y; .z.m.gg.tbl.unbox table];
        col : .z.m.gg.tbl.column[t; y];
        : `x__`q1__`q2__`q3__!enlist[xval] , .z.m.st.quantiles[col; .25 .5 .75];
        }[x; y; table] each l;
    
    }
// @private
// @fileOverview 
// Given custom settings, and scales, determine the bin counts
// for a binned visual.
// @param table {table}
// @param arg {(symbol;number;number)|null} bin spec 
// @param col {symbol} column 
// @param sc {dict} initialized scale dictionary for x 
// @returns {symbol[]|number[]} width/count and argument pairs for x and y bins
.z.m.st.resolveBins:{[table; arg; col; sc]
    tt : .z.m.gg.tbl.metatype[table; col];
    
    if [.z.m.gg.tbl.isempty table;
        : (`c;1;0)];
    
    if [arg ~ `by; : (`by;1;0)];
    
    bs : $[not .z.m.axq.isNull arg;
            arg;
        
      (tt in "bxhij") & `linear ~ sc`label; /dnl
            $[i.BINS[1] > .z.m.gg.h.safeRange sc`true_limits; (`w;1;1); @[i.BINS;2;:;1]];
      
      tt in "bxhij"; /dnl
            $[i.BINS[1] > .z.m.gg.h.safeRange (min;max)@\: .z.m.gg.h.removeInfs .z.m.gg.tbl.column[table; col];
            (`w;1;1);
            @[i.BINS;2;:;1]];
        
      .z.m.gg.scale.categorical[][`label] ~ sc`label;
            (`w;1;1);
        
            i.BINS];
    
    if [first[bs] in i.TEMPORALS;
        if [(0 >= "j"$bs 1) | not bs[1] = "j"$bs 1;
            '"bin argument must be a positive integer"];
        : @[bs;1;"j"$]];
    
    if [(tt in "bxhijdtvumscCgp") and not .z.m.gg.scale.log[`label] ~ sc`label;
        counts : .z.m.st.bins[table; enlist col; enlist bs; enlist sc];
        w      : ceiling first counts`width;
        bs     : (`w;w;1)];
    
    : bs;
    
    }

// @fileOverview Calculate a columns statistics if column is of
//               type 1,4-10,12-19. Otherwise this will return empty stats dictionary
// @param col {list} The column in list format, which stats are to be calculated on.
// @returns {dict} The stats keyed by statistical operation.
.z.m.st.rollup.col:{[col]
    fList: `min`max`avg`med`dev`nulls!(min;max;avg;med;dev;sum where null@);

    d: (!) . flip (
        (1h;  `cast`skip!(0b; `nulls));
        (2h;  `cast`skip!(0b; `min`max`avg`med`dev));
        (4h;  `cast`skip!(1b; `nulls));
        (8h;  `cast`skip!(1b; ()));
        (11h; `cast`skip!(0b; `min`max`avg`med`dev));
        (12h; `cast`skip!(1b; `avg`med`dev));
        (13h; `cast`skip!(1b; `dev));
        (14h; `cast`skip!(1b; `dev));
        (15h; `cast`skip!(1b; `dev));
        (16h; `cast`skip!(1b; `avg`med`dev));
        (17h; `cast`skip!(1b; `dev));
        (18h; `cast`skip!(1b; `dev));
        (19h; `cast`skip!(1b; `dev)));

    settings: d type col;
    
    if [settings `cast;
        fList[`avg`med`dev]: {.z.m.axq.asType[x y;.z.m.axq.typeOf y]}@/:fList `avg`med`dev];

    if[not .z.m.axq.isNull settings`skip;
        fList[settings `skip]: {"N/A"}];

    : $[type[col] within 1 19;
        [   col: $[all (>=) prior col; (::)@'col; col];
            .z.m.axq.asString fList @\: col];
            key[fList]!count[fList]# enlist "N/A"];
    }

// @fileOverview For a given table, construct the statistics on each column
// @param table {table} The (keyed) table which stats should be calculated.
// @returns {dict} A dictionary keyed by column names containing each columns calculated stats.
.z.m.st.rollup.table:{[table]
    $[99h~type table;flip raze rollup.col each/: flip each (key;value)@\:table;
        98h~type table;flip rollup.col each flip table;
        ()!()]
    }
// @fileOverview 
// Perform a scaled 1d bin on a table. The given scale is applied to the data
// before binning.
// @see st.bin1d
// @param col {symbol} 
// @param val {(symbol;number)} width or count (`` `w `` or `` `c ``) and arg for bin 
// @param scale {dict} scale (see .z.m.gg.scale) 
// @param aggs {dict} aggregations (see .z.m.st.a.\*) 
// @param options {dict|null} see .z.m.st.bin2d
// @param table {table}
// @returns {table}
.z.m.st.sbin1d:{[col; val; scale; aggs; options; table]
    : .z.m.st.sbinNd[enlist col; enlist val; enlist scale; aggs; options; table]
    }

// @fileOverview 
// Perform a 2d binning and necessary aggregations.
// @see st.bin1d
// @param columns {symbol[]} pair of symbols to bin 
// @param xbins {(symbol;number;number)} (`` `w `` or `` `c ``; arg; padding) 
// @param ybins {(symbol;number;number)} (`` `w `` or `` `c ``; arg; padding) 
// @param xscale {dict} scale for the x axis 
// @param yscale {dict} scale for the y axis 
// @param mods {dict} aggregations 
// @param options {dict|null} see .z.m.st.bin2d
// @param table {table} 
.z.m.st.sbin2d:{[columns; xbins; ybins; xscale; yscale; mods; options; table]
    : sbinNd[columns; (xbins; ybins); (xscale; yscale); mods; options; table]
    }

// @fileOverview 
// Perform an nD binning using the given scales. Bins can be specified
// as in width or height. The padding to a bin is added to increase the range
// over which the bins are split. For example, categorical columns would
// likely specify a padding value of 1 so that bins (`c;5;1) are spaced on
// even numbers, rather than over (num distinct) % 5 intervals.
// @see st.bin1d
// @param columns {symbol[]} list of column names 
// @param binDescr {(symbol;number;number)[]} bin description (`` `w `` or `` `c ``; arg; padding) 
// @param scales {dict[]} list of scales for each variable 
// @param mods {dict} list of aggregations to perform 
// @param options {dict|null} see .z.m.st.bin2d
// @param table {table} 
.z.m.st.sbinNd:{[columns; binDescr; scales; mods; options; table]
    : sbinNd_i[columns; binDescr; i.initScales[table;columns;scales]; mods; options; table]
    };


// @fileOverview 
// Perform an nD binning using the given scales. Bins can be specified
// as in width or height. The padding to a bin is added to increase the range
// over which the bins are split. For example, categorical columns would
// likely specify a padding value of 1 so that bins (`c;5;1) are spaced on
// even numbers, rather than over (num distinct) % 5 intervals.
// @see st.bin1d
// @param cs {symbol[]} list of column names 
// @param descr {((symbol;number;number)|null)[]} bin description (`` `w `` or `` `c ``; arg; padding), or null to accept defaults
// @param scales {dict[]} list of scales for each variable 
// @param mods {dict} list of aggregations to perform 
// @param opts {dict|null} see .z.m.st.bin2d
// @param t {table} 
// @returns {table} binned data
//
// @throws "column x not found"
//
// [!!] NOTE - this binning function should avoid duplicating data at all costs!
.z.m.st.sbinNd_i:{[cs; descr; scales; mods; opts; t]
    defaults : `norm`center`filter`hex!(::;0b;0b;0b);
    opts     : defaults , $[99h ~ type opts; opts; ()!()];
    
    .z.m.gg.h.assert.colExists[t] each cs , mods[key mods; `column] except `i;
    if [not all 1 = d:(count distinct@) each descr group cs;
        '.z.m.axstr.interp["'{0}' has more than one bin configuration"] first where d];
    if [any idx: cs in key mods; '.z.m.axstr.interp["column '{0}' cannot be both binned and aggregated"] cs first where idx];
    if [0 = count cs; cs: 0#`];
    
    if [opts`hex; 
        : i.hexbin[t;cs;descr;scales;mods]];
    
    descr     : bins[t; cs; resolveBins[t]'[descr; cs; scales]; scales];
    bs        : i.bin.bounds[cs; descr; scales];
    binned    : i.qsql.filter[cs] 
                i.qsql.bin[cs;bs;descr;mods;scales]
                flip u!.z.m.gg.tbl.column[t] each u:{$[0 = count x; 1#`i; x]} cs , value[mods@\:`column] except `i; 
    final     : i.qsql.bounds[cs;scales;descr`kind;bs;binned]
                i.qsql.cast[bs;cs;scales;descr`kind] binned;
    
    if [opts`center; 
        final: i.center[cs; descr; final]];
    
    if [.z.m.gg.h.and[opts`norm; '[not;(::)~]; {`count__ in cols y}[;final]];
        final: i.normalize[opts`norm; `count__; `norm__; final]];
    
    : final;
    };
// @fileOverview 
// Returns a five-number-summary-style report for each subset of the data
// split on distinct values of one column (x). The x column should be categorical, while the
// y column should be numeric/continuous.
//
// The output columns are the following:
//
// - the first column has the same name as the given categorical column (x)
// - `q1__` - first quartile
// - `q2__` - second quartile
// - `q3__` - third quartile
// - `min__` - min
// - `max__` - max
// - `med__` - median
// - `mean__` - average (avg)
// - `upper__` - upper hinge (1.5 * interquartile range from median)
// - `lower__` - lower hinge (1.5 * interquartile range from median)
//
// @param x {symbol} categorical column name
// @param y {symbol} continuous column name 
// @param table {table}
// @returns {table}
// @throws "column x not found"
// @throws "column x of type y not one of z"
// @see st.quartiles
// @see st.outliers
// @example
//      t:([]x:45?5?`8; y:45?45);
//
//      .z.m.st.summary[`x; `y; t]
//
// /=> x        q1__ q2__ q3__ min__ max__ med__ mean__   upper__ lower__
// /=> ------------------------------------------------------------------
// /=> npccjbfg 4    23   32.5 0     42    23    18.88889 42      0      
// /=> kcjfooab 7.5  23.5 31   1     42    23    20       42      1      
// /=> jnmhejla 14   23   30   7     33    22.5  21       33      7      
// /=> iiphmkna 16   25.5 31   13    41    20    24.2     41      13     
// /=> gnlighkg 22   34   41   17    42    30    29.66667 42      17     
.z.m.st.summary:{[x; y; table]
    
    .z.m.gg.h.assert.colExists[table; x];
    .z.m.gg.h.assert.colExists[table; y];
    .z.m.gg.h.assert.colType[i.BASETYPES; table; x];
    .z.m.gg.h.assert.colType[i.CTYPES; table; y];
        
    colNames : .z.m.gg.h.sanitize (x;`q1__;`q2__;`q3__;`min__;`max__;`med__;`mean__;`upper__;`lower__);
    colTypes : .z.m.gg.tbl.metatype[table; x] , 9#.z.m.gg.tbl.metatype[table;y];
    
    qs : quartiles [x; y; table];
        
    l : distinct .z.m.gg.tbl.column[table;x];
    
    if [0 = count l;
        : flip colNames!colTypes$\:()];
    
    rs: {`x__`rd!(x`x__; x[`q3__] - x`q1__) } each `x__ xcol qs;
    
    ms : {[rs; x;y;table;xval]
        rs     : `x__ xkey rs;
        subset : extract[x; xval; enlist y; .z.m.gg.tbl.unbox table];
        l      : .z.m.gg.tbl.column[subset; y];
        kind   : .z.m.gg.tbl.metatype[table; y];
        mmm    : `x__`min__`max__`med__`mean__!(xval; min l; max l; med l;avg l);
        
        if [kind in "pmdznuvt"; /dnl
            mmm[`med__]: kind$mmm`med__];
        
        r: rs[xval]`rd;
        mru  : mmm[`med__] + 1.5 * r;
        mrd  : mmm[`med__] - 1.5 * r;
        temp :  l where l >= mrd;
        h1   : $[0 = count temp; min l; min temp];
        temp : l where l <= mru;
        h2   : $[0 = count temp; max l; max temp];
        mmm[`upper__`lower__]: (h2; h1);
        : mmm;
        }[rs; x; y; table] each l;
        
    : qs pj .z.m.gg.h.sanitize[enlist x] xkey .z.m.gg.h.sanitize[enlist x] xcol ms;
    
    }

// @private
// @fileOverview
// Tricube function for statistical transforms
// @param x {number}
.z.m.st.tricube:{[x]
    x*x*x:1-x*x*x
    }

// @private
// @fileOverview Whether partitioned bins will be used when binning
// @param table {table} 
// @param col {symbol} 
// @returns {boolean}
.z.m.st.usePartitionedBins:{[table;col]
    isRaw: $[.z.m.gg.tbl.ty.is table; (::) ~ .z.m.gg.tbl.ty.index table; 1b];
    
    if [isRaw;
        raw: .z.m.gg.tbl.unbox table;
        : .Q.qp[raw] & @[{.Q.pf ~ x};col;0b]];
            
    : 0b
    }

.z.m.st.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.st_aggregateError; "unable to aggregate");
        (`.st_binLengthError; "bin columns are not the same length");
        (`.st_binCountError; "bin count would be {found}, but maximum supported is {supported}");
        (`.st_binAggregationError; "error aggregating {f} `{column}` ({typ}): {msg}")
    ))
.z.m.st.i.TEMPORALS:`date`month`year`hh`minute`second`time`timestamp`datetime
.z.m.st.i.MAX_COLUMN_BINS:24 * 60 * 60 // allow a second bin over a day
.z.m.st.i.MAX_BINS:1000000000

// keep only the pairs that errored
.z.m.st.i.INVALID_TEMPORAL_CASTS:{x where not (::) ~/: x}
    { $[0b ~ .[$;(x;y);0b]; (x;.z.m.axq.typeOf y); ::] } .'
    `datetime`timestamp`date`month`year`timespan`minute`time`second
    cross
    (.z.z;.z.p;.z.d;`month$.z.d;`year$.z.d;.z.n;`minute$.z.p;`time$.z.p;`second$.z.p)
.z.m.st.i.CTYPES:"bxhijefpmdznuvt" /dnl
.z.m.st.i.BINS:(`c;20;0)
.z.m.st.i.BASETYPES:"bgxhijefcCspmdznuvt" /dnl
.z.m.st.PI:acos -1
.z.m.st.onLoad:{[]
    }

.z.m.st.onLoad[];
system "d .z.m";

system "d .z.m.gg";
// @subcategory Statistics
// @fileOverview 
// A 1d binning stat
// @see st.bin1d
// @param column {symbol} 
// @param binspec {(symbol;number;number)} width or count (`w or `c), argument, padding 
// @param aggs {dict} see .z.m.st.a.\*
// @param options {dict | null} null for defaults, see .z.m.st.sbinNd_i 
// @returns {dict} table -> transformed table
.z.m.gg.stat.bin1d:{[column; binspec; aggs; options]
    
    : stat.ty.new (
        
        .z.m.st.bin1d[column; binspec; aggs; options];
        
        stat.i.binColMap[enlist column; enlist binspec]
        
        );
    
    }

// @subcategory Statistics
// @fileOverview 
// 2d binning transform
// @see st.bin2d
// @param columns {symbol[]} list of two column names
// @param binspec1 {(symbol; number; number)} width or count (`w; or `c), argument, padding 
// @param binspec2 {(symbol; number; number)} 
// @param aggs {dict} see .z.m.st.a.\*
// @param options {dict | null} null for defaults, see .z.m.st.sbinNd_i 
// @returns {dict} table -> transformed table
.z.m.gg.stat.bin2d:{[columns; binspec1; binspec2; aggs; options]
    
    : stat.ty.new (
        
        .z.m.st.bin2d[columns; binspec1; binspec2; aggs; options];
        
        stat.i.binColMap[columns; (binspec1; binspec2)]
        
        );
    
    }

// @subcategory Statistics
// @fileOverview 
// nD binning transform
// @see st.binNd
// @param columns {symbol[]} list of n column names
// @param binspecs {(symbol; number; number)[]} list of n triples of: width or count (`w or `c), argument, padding
// @param aggs {dict} see .z.m.st.a.\*
// @param options {dict | null} null for defaults, see .z.m.st.sbinNd_i 
// @returns {dict} table -> transformed table
.z.m.gg.stat.binNd:{[columns; binspecs; aggs; options]
    
    : stat.ty.new (
        
        .z.m.st.binNd[columns; binspecs; aggs; options];
        
        stat.i.binColMap[columns; binspecs]
        
        );
    
    }

// @fileOverview Return a colmap of columns -> column operations
// resulting from a stat
// @param columns {symbol[]} 
// @param binspecs {any[]} 
// @returns {dict} 
.z.m.gg.stat.i.binColMap:{[columns; binspecs]
    columns!{$[`by ~ x; ::; (::) ~ x; ::; x[0] in h.TEMPORALS; x[0]$; ::]} each binspecs
    }
// @fileOverview Run a moving average stat on the table
// @param n {long} number of items in average
// @param x {symbol} x column
// @param y {symbol} y column
// @param g {symbol} group column
// @param t {table} 
// @returns {table}
.z.m.gg.stat.i.mavg:{[n;x;y;g;t]
    h.assert.colExists[t] each (x;y);
    if [not null g; h.assert.colExists[t;g]];
    h.assert.colType["xhijefpmdznuvt"; t; y];
    
    if [tbl.isempty t; : update hdev__:0#0f, ldev__: 0#0f from t];
    
    t: flip `x`y`g!.z.m.gg.tbl.column[t] each (x;y;g);
    
    ysc: scale.init[scale.fromMeta[0b] h.metatype[t;`y]] t`y;
    
    r: $[null g;
        (x;y) xcol update 
            y: .z.m.gg.scale.inverse[ysc] n mavg .z.m.gg.scale.apply[ysc] y,
            dev__: n mdev .z.m.gg.scale.apply[ysc] y
            from `x xasc t;
        (x;y;g) xcol update 
            y: .z.m.gg.scale.inverse[ysc] n mavg .z.m.gg.scale.apply[ysc] y,
            dev__: n mdev .z.m.gg.scale.apply[ysc] y 
            by g from `x xasc t];
    
    r[`hdev__`ldev__]: .z.m.gg.scale.inverse[ysc] each r[y] +/: (::;neg) @\: 2 * r`dev__;
    : r;
    }
// @subcategory Statistics
// @fileOverview
// Least-squares regression transform function.
//
// Produce a table of values along the least-squares regression of the input table
// @see st.lsqTable
// @param x {symbol} column
// @param y {symbol} column
// @param degree {number} degree of the least-squares fit polynomial
// @returns {dict} transform object
.z.m.gg.stat.lsquares:{[x;y;degree]
    
    : stat.ty.new (
        
        .z.m.st.lsqTable[x;y;degree];
        
        (x;y)
        
        );
    
    }

// @subcategory Statistics
// @fileOverview Moving average statistic
// @param num {long} the number of values to be averaged at each point
// @param x {symbol} column
// @param y {symbol} column
// @param g {symbol|null} group column
// @returns {dict} transform object
.z.m.gg.stat.mavg:{[num; x; y; g]
    : stat.ty.new (
        stat.i.mavg[num;x;y;g];
        enlist y);
    }

// @subcategory Statistics
// @private
// @fileOverview 
// Create a new GG stat tranform object
// @param f {fn} table -> transformed table 
// @param colmap {symbol[]} list of column names that appear in the output table and relate to the input table 
.z.m.gg.stat.new:{[f; colmap]
    : stat.ty.new (f; colmap);
    }

// @subcategory Statistics
// @fileOverview 
// Compute the outliers component of a box-plot
// @see st.outliers
// @param catcol {symbol} categorical column name 
// @param numcol {symbol} continuous column name 
// @returns {fn} table -> transformed table
.z.m.gg.stat.outliers:{[catcol; numcol]
    : stat.ty.new (
        
        .z.m.st.outliers[catcol; numcol];
        
        enlist catcol
        
        );
    }

// @subcategory Statistics
// @fileOverview 
// Summarizing 1d bin transform with an additional constant 0 column (`const__`)
// @param column {symbol} column name
// @param aggs {dict} aggregators to use (see .z.m.st.a)
// @returns {dict} new stat transform
.z.m.gg.stat.pie:{[column; aggs]
    : .z.m.gg.stat.new[
        
        {[column; aggs; table] update const__:0 from .z.m.st.bin1d[column; ::; aggs; ::; table] }[column; aggs];
        
        enlist column]
    }

// @subcategory Statistics
// @fileOverview 
// Compute the quantiles of a numeric column
// @see st.quantile
// @param column {symbol} column name
// @returns {dict} table -> quantile table
.z.m.gg.stat.quantile:{[column]
    
    : stat.ty.new (
        
        .z.m.st.quantile column;
        
        enlist column
        
        );
    
    }

// @subcategory Statistics
// @fileOverview 
// Compute the quartiles of a column for each distinct value of another column
// @see st.quartiles
// @param catcol {symbol} categorical column name 
// @param numcol {symbol} continuous column name
// @returns {dict} table -> transformed table
.z.m.gg.stat.quartiles:{[catcol; numcol]
    : stat.ty.new (
        
        .z.m.st.quartiles[catcol; numcol];
        
        enlist catcol
        
        );
    }

// @subcategory Statistics
// @fileOverview 
// Scaled 1d bin (i.e., log bins)
// @see st.sbin1d
// @param column {symbol} column name 
// @param binspec {(symbol;number;number)} width or count (`w or `c), argument, padding 
// @param sc {dict} see .z.m.gg.scale 
// @param aggs {dict} see .z.m.st.a.\*
// @returns {dict} table -> transformed table
.z.m.gg.stat.sbin1d:{[column; binspec; sc; aggs; options]
    
    : stat.ty.new (
        
        .z.m.st.sbin1d[column; binspec; sc; aggs; options];
        
        stat.i.binColMap[enlist column; enlist binspec]
        
        );
    
    }

// @subcategory Statistics
// @fileOverview 
// Scaled 2d bin (i.e., log bins)
// @see st.sbin2d
// @param columns {symbol[]} 2 column names
// @param binspec1 {(symbol;number;number)} width or count (`w or `c), argument, padding 
// @param binspec2 {(symbol;number;number)}
// @param scale1 {dict} see .z.m.gg.scale 
// @param scale2 {dict}
// @param aggs {dict} see .z.m.st.a.\*
// @param options {dict | null} null for defaults, see .z.m.st.sbinNd_i 
// @returns {dict} table -> transformed table
.z.m.gg.stat.sbin2d:{[columns; binspec1; binspec2; scale1; scale2; aggs; options]
    
    : stat.ty.new (
        
        .z.m.st.sbin2d[columns; binspec1; binspec2; scale1; scale2; aggs; options];
        
        stat.i.binColMap[columns; (binspec1;binspec2)]
        
        );
    
    }

// @subcategory Statistics
// @fileOverview 
// Scaled nD bin (i.e., log bins)
// @see st.sbinNd
// @param columns {symbol} n column names
// @param binspecs {(symbol;number;number)} n triples of: width or count (`w or `c), argument, padding 
// @param scales {dict} n scales -- see .z.m.gg.scale 
// @param aggs {dict} see .z.m.st.a.\*
// @param options {dict | null} null for defaults, see .z.m.st.sbinNd_i 
// @returns {dict} table -> transformed table
.z.m.gg.stat.sbinNd:{[columns; binspecs; scales; aggs; options]
    
    : stat.ty.new (
        
        .z.m.st.sbinNd[columns; binspecs; scales; aggs; options];
        
        stat.i.binColMap[columns; binspecs]
        
        );
    
    }

// @private
// @fileOverview 
// nD scaled bin using pre-initialized scales
// @see gg.scale.init
// @see st.sbinNd_i
// @param columns {symbol} n column names
// @param binspecs {(symbol;number;number)} n triples of: width or count (`w or `c), argument, padding 
// @param scalesi {dict} n **initialized** scales -- see .z.m.gg.scale 
// @param aggs {dict} see .z.m.st.a.\*
// @param options {dict | null} null for defaults, see .z.m.st.sbinNd_i 
// @returns {dict} table -> transformed table
.z.m.gg.stat.sbinNd_i:{[columns; binspecs; scalesi; aggs; options]
    
    : stat.ty.new (
        
        .z.m.st.sbinNd_i[columns; binspecs; scalesi; aggs; options];
        
        stat.i.binColMap[columns; binspecs]
        
        );
    
    }

// @subcategory Statistics
// @fileOverview 
// Compute 5-number summaries of a column for each distinct value of another column
// @see st.summary
// @param catcol {symbol} categorical column name 
// @param numcol {symbol} continuous column name
// @returns {dict} table -> transformed table
.z.m.gg.stat.summary:{[catcol; numcol]
    
    : stat.ty.new (
        
        .z.m.st.summary[catcol; numcol];
        
        enlist catcol
        
        );
    
    }

// @private
.z.m.gg.stat.onLoad:{[]
    
    
    .z.m.axdatatype.create[ .z.M.gg.stat.ty; `applyF`colmap; enlist `colmap];
    
    }
.z.m.gg.stat.onLoad[];
system "d .z.m";

system "d .z.m.gg";
// @subcategory Visualization DSL
// @fileOverview 
// Top level evaluator for GG DSL syntax trees. Given a syntax tree, draw the described image.
// @param e {dict} evaluation environment
// @param tree {any[]} current tree
// @returns {null} 
// @deprecated
.z.m.gg.dsl.eval:{[e; tree]
    
    root : first tree;
    path : first root;
    
    go : $[`go ~ path;     dsl.i.eval.go;
           `title ~ path;  dsl.i.eval.title;
           `layout ~ path; dsl.i.eval.layout;
           `theme ~ path;  dsl.i.eval.theme;
           `layer ~ path;  dsl.i.eval.layer;
           `stack ~ path;  dsl.i.eval.stack;
           `split ~ path;  dsl.i.eval.split;
                           '"Unrecognized path"]; /dnl
    
    : go[e; 1_root; 1_tree];
    
    }

.z.m.gg.dsl.i.bintype:{[x]
    : $[x ~ `count; `c;
        x ~ `width; `w;
                     `c];
    
    }

// @fileOverview 
// Evaluate aggregation descriptions
// @param e {dict} evaluation environment
// @param a {any} aggregations
// @returns {dict}
.z.m.gg.dsl.i.eval.aggr:{[e; a]
    process : {[e;a]
        $[a ~ `count; .z.m.st.a.count[];
                      .z.m.st.a.custom[a 2; a 4; dsl.i.eval.inlineIdentifier[e] a 6]]
        } e;
    : .z.m.qp.s.aggr raze process each 1_a;
    }

// @fileOverview 
// Parse a custom chart
// @param e {dict} evaluation environment
// @param root {any[]} current tree
// @returns {table} chart description
.z.m.gg.dsl.i.eval.custom:{[e; root]
    chart : dsl.i.eval.inlineIdentifier[e] root 1;
    arg : dsl.i.eval.inlineIdentifier[e] each (!) . flip root 2;
    : chart arg;
    }

// @fileOverview 
// Evaluate `go width height rest` syntax
// @param e {dict} evaluation environment
// @param root {any[]} root of the current tree
// @param rest {any[]} next nodes in the tree to process
// @returns {dict}
.z.m.gg.dsl.i.eval.go:{[e; root; rest]
    : .z.m.gg.display[root 1; root 2] .z.m.gg.new dsl.eval[e] rest;
    }

.z.m.gg.dsl.i.eval.inlineIdentifier:{[e; i]
    : $[any `identifier`qexpr ~\: first i;  @[value; last i; {'.z.m.axlocalize.t(`.gg_dslErrorIdentifier;x)}];
        `param ~ first i;                    $[last[i] in key e; e last i; '.z.m.axlocalize.t(`.gg_dslErrorMissingParam;string last i)];
                                             '"Unknown identifier"]; /dnl
    }
// @fileOverview 
// Evaluate layer descriptions
// @param e {dict} evaluation environment
// @param root {any[]} root of the current tree
// @param rest {any[]} next nodes in the tree to process
// @returns {dict}
.z.m.gg.dsl.i.eval.layer:{[e; root; rest]
    
    
    if [`chart ~ first root;
        : dsl.i.eval.custom[e; root]];
    
    if [not first[root] in key .z.m.qp;
        '.z.m.axlocalize.t`.gg_dslErrorMissingGeom];
   
    g    : .z.m.qp first root;
    data : dsl.i.eval.inlineIdentifier[e; root 1];

    call        : $[first[root] in `hline`vline; g data; g[data] . 2_-1_root];
    options     : last root;
    optionTypes : first each options;
    
    aes    : .z.m.qp.s.aes .' 1_' options where optionTypes = `aes;
    g      : .z.m.qp.s.geom each dsl.i.eval.inlineIdentifier[e] each/: (!) .' flip each 0N 2#/:1_'options where optionTypes = `geom;
    scales : dsl.i.eval.scale[e] each options where optionTypes = `scale;
    stats  : dsl.i.eval.stat[e] each options where optionTypes = `stat;
    aggrs  : dsl.i.eval.aggr[e] each options where optionTypes = `aggregations;
    cs     : .z.m.qp.s.coord each {$[x in `polar`rect;
                    .z.m.gg.coords x;
                    '.z.m.axlocalize.t`.gg_dslErrorMissingCoords]} each first each 1_'options where optionTypes = `coord;
    
    link      : .z.m.qp.s.link each first each 1_'options where optionTypes = `link;
    primary   : .z.m.qp.s.link each first each 1_'options where optionTypes = `primary;
    secondary : .z.m.qp.s.link each first each 1_'options where optionTypes = `secondary;
    
    textalign : .z.m.qp.s.textalign each first each 1_'options where optionTypes = `textalign;
    bins      : {$[`x ~ y 0; .z.m.qp.s.binx; .z.m.qp.s.biny][dsl.i.bintype y 1; dsl.i.eval.inlineIdentifier[x] y 2; 0]}[e] each 1_'options where optionTypes = `bin;
    labels    : .z.m.qp.s.labels each (!).' flip each 1_'options where optionTypes = `labels;
    options   : raze raze each (aes; g; scales; cs; link; primary; secondary; bins; textalign; labels; stats; aggrs);
    
    : call options;
    }

// @fileOverview 
// Evaluate latyout descriptions
// @param e {dict} evaluation environment
// @param root {any[]} root of the current tree
// @param rest {any[]} next nodes in the tree to process
// @returns {dict}
.z.m.gg.dsl.i.eval.layout:{[e; root; rest]
    
    layoutPair : $[(`horizontal ~ first root) and `weights ~ root 1;
                    (3; .z.m.qp.layout[`hori_w;@[value;root 2;{'.z.m.axlocalize.t[`.gg_dslErrorEvalWeightsPre],x}]]);
               (`vertical ~ first root) and `weights ~ root 1;
                    (3; .z.m.qp.layout[`vert_w;@[value;root 2;{'.z.m.axlocalize.t[`.gg_dslErrorEvalWeightsPre],x}]]);
               `horizontal ~ first root;
                    (1; .z.m.qp.layout[`hori;::]);
               `vertical ~ first root;
                    (1; .z.m.qp.layout[`vert;::]);
                    '"Unknown layout"]; /dnl
    
    : layoutPair[1] dsl.eval[e] each enlist each layoutPair[0]_root;
    
    }

// @fileOverview 
// Evaluate scale descriptions
// @param e {dict} evaluation environment
// @param s {any[]} scale description
// @returns {dict}
.z.m.gg.dsl.i.eval.scale:{[e; s]
    for     : s 1;
    kind    : s 2;
    options : s 3;
    
    scales : (.z.m.gg.scale.linear;
        .z.m.gg.scale.log;
        .z.m.gg.scale.power;
        .z.m.gg.scale.categorical (::);
        .z.m.gg.scale.date;
        .z.m.gg.scale.datetime;
        .z.m.gg.scale.minute;
        .z.m.gg.scale.month;
        .z.m.gg.scale.second;
        .z.m.gg.scale.time;
        .z.m.gg.scale.timespan;
        .z.m.gg.scale.timestamp;
        .z.m.gg.scale.mercator;
        .z.m.gg.scale.weekday;
        .z.m.gg.scale.colour.cat;
        .z.m.gg.scale.colour.cat10;
        .z.m.gg.scale.colour.cat20;
        .z.m.gg.scale.colour.gradient;
        .z.m.gg.scale.colour.gradient2;
        .z.m.gg.scale.circle.area;
        .z.m.gg.scale.circle.radius;
        .z.m.gg.scale.line.size;
        .z.m.gg.scale.alpha);
    
    types : `linear`log`power`categorical`date`datetime`minute`month`second`time`timespan`timestamp,
        `mercator`weekday,
        `colour.cat`colour.cat10`colour.cat20`colour.gradient`colour.gradient2,
        `circle.area`circle.radius`line.size`alpha;
    
    if [not kind in types; '.z.m.axlocalize.t`.gg_dslErrorScaleType];
    
    sc          : scales types?kind;
    optionTypes : first each options;
    
    if [kind ~ `colour.gradient;
        if [any not `from`to in\: optionTypes; '.z.m.axlocalize.t`.gg_dslErrorGradient1];
        sc : sc . dsl.i.eval.inlineIdentifier[e] each last each options optionTypes?`from`to];
    
    if [kind ~ `colour.gradient2;
        if [any not `from`to`mid`midValue in\: optionTypes; '.z.m.axlocalize.t`.gg_dslErrorGradient2];
        sc : sc . dsl.i.eval.inlineIdentifier[e] each last each options optionTypes?`midValue`from`mid`to];
    
    if [kind ~ `circle.area;
        if [any not `from`to in\: optionTypes; '.z.m.axlocalize.t`.gg_dslErrorCircleArea];
        sc : sc . dsl.i.eval.inlineIdentifier[e] each last each options optionTypes?`from`to];
    
    if [kind ~ `circle.radius;
        if [any not `from`to in\: optionTypes; '.z.m.axlocalize.t`.gg_dslErrorCircleRadius];
        sc : sc . dsl.i.eval.inlineIdentifier[e] each last each options optionTypes?`from`to];
    
    if [kind ~ `line.size;
        if [any not `from`to in\: optionTypes; '.z.m.axlocalize.t`.gg_dslErrorLineSize];
        sc : sc . dsl.i.eval.inlineIdentifier[e] each last each options optionTypes?`from`to];
        
    if [kind ~ `alpha;
        if [any not `from`to in\: optionTypes; '.z.m.axlocalize.t`.gg_dslErrorAlpha];
        sc : sc . dsl.i.eval.inlineIdentifier[e] each last each options optionTypes?`from`to];
        
    if [kind ~ `colour.cat;
        if [not `palette in first each options; '.z.m.axlocalize.t`.gg_dslErrorCatColour];
        sc : sc dsl.i.eval.inlineIdentifier[e] last options optionTypes?`palette];
    
    if [kind ~ `mercator;
        if [all not `latitude`longitude in\: first each options; '.z.m.axlocalize.t`.gg_dslErrorMercator];
        if [all `latitude`longitude in\: first each options; '.z.m.axlocalize.t`.gg_dslErrorMercator];
        sc : sc `latitude in first each options];
    
    if [`breaks in optionTypes;
        sc : .z.m.gg.scale.breaks[dsl.i.eval.inlineIdentifier[e] last first options where optionTypes = `breaks] sc];
    
    if [`limits in optionTypes;
        sc : .z.m.gg.scale.limits[dsl.i.eval.inlineIdentifier[e] last first options where optionTypes = `limits] sc];
    
    if [`extend in optionTypes;
        sc : .z.m.gg.scale.extend[dsl.i.eval.inlineIdentifier[e] last first options where optionTypes = `extend] sc];
    
    if [`extension in optionTypes;
        sc : .z.m.gg.scale.extension[dsl.i.eval.inlineIdentifier[e] last first options where optionTypes = `extension] sc];
    
    : .z.m.qp.s.scale[for; sc];
    }

// @fileOverview 
// Evaluate split descriptions
// @param e {dict} evaluation environment
// @param root {any[]} root of the current tree
// @param tree {any[]} next nodes in the tree to process
// @returns {dict}
.z.m.gg.dsl.i.eval.split:{[e; root; tree]
    if [not 3 = count root; '.z.m.axlocalize.t`.gg_dslErrorSplitSpec];
    : .z.m.qp.split dsl.eval[e] each enlist each 1_root;
    }

// @fileOverview 
// Evaluate binning stat transform descriptions
// @param e {dict} evaluation environment
// @param s {any[]} bin settings
// @returns {dict}
.z.m.gg.dsl.i.eval.z.m.st.bin:{[e; s]
    columnSpec   : s 0;
    explicit     : columnSpec where ii : `explicit = columnSpec[;2];
    implicit     : columnSpec where not ii;
    explicit[;3] : dsl.i.eval.inlineIdentifier[e] each {x[;3]} explicit: explicit[;0 1 4 5];
    explicit[;2] : `c`w `width = explicit[;2];
    aggregations : s 1;
    
    process : {[e;a]
        $[a ~ `count; .z.m.st.a.count[];
                      .z.m.st.a.custom[a 2; a 4; dsl.i.eval.inlineIdentifier[e; a 6]]]
        } e;
    
    aggregations : raze process each 1_aggregations;
    
    settings : s 2;
    settings : $[not `settings ~ first settings;
        ::;
        dsl.i.eval.inlineIdentifier[e] each (!) . flip 1_settings];
    
    n       : count columnSpec;
    columns : (implicit,explicit)[;1];
    specs   : (count[implicit]#(::)),explicit[;2 3] ,' 0;
        
    : $[1 ~ n; .z.m.gg.stat.bin1d[first columns; first specs; aggregations; settings];
             2 ~ n; (.z.m.gg.stat.bin2d[columns] . specs)[aggregations; settings];
            '.z.m.axlocalize.t`.gg_dslErrorBinNumber];
    
    }

// @fileOverview 
// Evaluate least squares stat transform descriptions
// @param s {any[]} stat description
// @returns {dict}
.z.m.gg.dsl.i.eval.z.m.st.lsquares:{[s]
    : .z.m.gg.stat.lsquares . s 1 3
    }

// @fileOverview 
// Evaluate quantile stat transform descriptions
// @param s {any[]} stat description
// @returns {dict}
.z.m.gg.dsl.i.eval.z.m.st.quantiles:{[s]
    : .z.m.gg.stat.quantile s 1
    }

// @fileOverview 
// Evaluate quartiles stat transform descriptions
// @param s {any[]} stat description
// @returns {dict}
.z.m.gg.dsl.i.eval.z.m.st.quartiles:{[s]
    : .z.m.gg.stat.quartiles . s 1 3
    }

// @fileOverview 
// Evaluate summary stat transform descriptions
// @param s {any[]} stat description
// @returns {dict}
.z.m.gg.dsl.i.eval.z.m.st.summary:{[s]
    : .z.m.gg.stat.summary . s 1 3
    }

// @fileOverview 
// Evaluate stack descriptions
// @param e {dict} evaluation environment
// @param root {any[]} root of the current tree
// @param rest {any[]} next nodes in the tree to process
// @returns {dict}
.z.m.gg.dsl.i.eval.stack:{[e; root; rest]
    
    : .z.m.qp.stack dsl.eval[e] each enlist each 1_root;
    }

// @fileOverview 
// Evaluate stat transform descriptions
// @returns {dict}
.z.m.gg.dsl.i.eval.stat:{[e; s]
    path : s 1;
    : .z.m.qp.s.stat $[path ~ `raw;
               dsl.i.eval.inlineIdentifier[e;2_s];
             path ~ `bin;
                dsl.i.eval.z.m.st.bin[e] 2_s;
             path ~ `quartiles;
                dsl.i.eval.z.m.st.quartiles 2_s;
             path ~ `quantiles;
                dsl.i.eval.z.m.st.quantiles 2_s;
             path ~ `leastsquares;
                dsl.i.eval.z.m.st.lsquares 2_s;
             path ~ `summary;
                dsl.i.eval.z.m.st.summary 2_s;
                ()];
    
    }

// @fileOverview 
// Evaluate theme descriptions
// @param e {dict} evaluation environment
// @param root {any[]} root of the current tree
// @param rest {any[]} next nodes in the tree to process
// @returns {dict}
.z.m.gg.dsl.i.eval.theme:{[e; root; rest]
    path : first root;
    
    th : $[`themename ~ path;
        $[not root[1] in key theme; '.z.m.axlocalize.t`.gg_dslErrorMissingTheme; theme root 1];
        dsl.i.eval.inlineIdentifier[e] each (!) . flip root 1];
    
    
    : .z.m.qp.theme[th] dsl.eval[e] enlist last root;
    }

// @fileOverview 
// Evaluate title descriptions
// @param e {dict} evaluation environment
// @param root {any[]} root of the current tree
// @param rest {any[]} next nodes in the tree to process
// @returns {dict}
.z.m.gg.dsl.i.eval.title:{[e; root; rest]
    : .z.m.qp.title[first 1_root] dsl.eval[e] enlist last root;
    }

// @fileOverview 
// Evaluate geometry settings descriptions
// @param name {string} layer name
// @param identifiers {symbol[]} list of identifier names for the layer
// @returns {dict}
.z.m.gg.dsl.i.geom:{[name; identifiers]
    
    name        : .z.m.axpc.symbol name;
    data        : .z.m.axpc.ws .z.m.axpc.a[,:] dsl.inlineIdentifier;
    identifiers : { .z.m.axpc.ws .z.m.axpc.a[`$] dsl.identifier } each identifiers;
    options     : .z.m.axpc.a[,:] .z.m.axpc.many .z.m.axpc.a[,:] .z.m.axpc.ws dsl.option;
    
    : .z.m.axpc.seq(name; data; .z.m.axpc.seq identifiers; options)
    
    }

// @subcategory Visualization DSL
// @fileOverview 
// Parse DSL syntax into a plot description object
// @param input {string} input to parse
// @returns {dict}
// @deprecated
.z.m.gg.dsl.parse:{[input]
    : .z.m.axpc.prs[dsl.plot] input;
    }

.z.m.gg.dsl.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.gg_dslErrorIdentifier; "Cannot execute identifier: {id}");
        (`.gg_dslErrorMissingParam; "Parameter not found in environment: {param}");
        (`.gg_dslErrorMissingGeom; "Geometry not found");
        (`.gg_dslErrorMissingCoords; "Coordinate system not found");
        (`.gg_dslErrorEvalWeightsPre; "Error evaluating weights: ");
        (`.gg_dslErrorScaleType; "Scale type not recognized");
        (`.gg_dslErrorGradient1; "Gradient scales must have 'from' and 'to' attributes");
        (`.gg_dslErrorGradient2; "Gradient2 scales must have 'from', 'mid', 'to', and 'midvalue' attributes");
        (`.gg_dslErrorCircleArea; "Circle area scales must have 'from' and 'to' attributes");
        (`.gg_dslErrorCircleRadius; "Circle radius scales must have 'from' and 'to' attributes");
        (`.gg_dslErrorLineSize; "Line size scales must have 'from' and 'to' attributes");
        (`.gg_dslErrorAlpha; "Alpha scales must have 'from' and 'to' attributes");
        (`.gg_dslErrorCatColour; "Categorical colour scales must have a 'palette' attribute");
        (`.gg_dslErrorMercator; "Mercator scales must have either a 'longitude' or 'latitude' attribute");
        (`.gg_dslErrorSplitSpec; "Splits must have two child specifications");
        (`.gg_dslErrorBinNumber; "Unsupported bin number");
        (`.gg_dslErrorMissingTheme; "Theme not found")
    ))

.z.m.gg.dsl.i.grammar:dsl.tok : {.z.m.axpc.a {enlist x,y} x};

dsl.identifier : .z.m.axpc.lexeme .z.m.axpc.many1 .z.m.axpc.anyOf ".",.Q.an;
dsl.qexpr      : (%; "<<"; ">>"; .z.m.axpc.whileNot[.z.m.axpc.anyChar; ">>"]);
dsl.param      : .z.m.axpc.a[last] (>; .z.m.axpc.symbol"param"; (%; "("; ")"; .z.m.axpc.a[`$] dsl.identifier));
 
dsl.inlineIdentifier : (|;
    .z.m.axpc.a[`param,enlist@]        dsl.param;
    .z.m.axpc.a[`qexpr,enlist@]        dsl.qexpr;
    .z.m.axpc.a[`identifier,enlist `$] dsl.identifier);
 
dsl.top   : (>; (@;`$;"go");    (@;"J"$;.z.m.axpc.integer);  (@;"J"$;.z.m.axpc.integer));
dsl.aes   : (>; (@;`$;"aes");   (@;`$;dsl.identifier); (@;`$;dsl.identifier));
dsl.coord : (>; (@;`$;"coord"); (@;`$;dsl.identifier));

geomOptions : .z.m.axpc.symbol each (
    "alpha";  "size";    "fill";      "colour";    "width";       "height";    "fontsize";
    "align";  "halign";  "position";  "gap";       "strokewidth"; "collapse";  "angle" );
   
dsl.geom : (>;
    .z.m.axpc.symbol"geom";
    (*; >;
        .z.m.axpc.oneOf geomOptions;
        .z.m.axpc.a[,:] dsl.inlineIdentifier));

dsl.scale : (>;
    .z.m.axpc.symbol"scale";
    (@;`$;dsl.identifier);
    (@;`$;.z.m.axpc.lexeme .z.m.axpc.many1 .z.m.axpc.anyOf ".",.Q.an);
    (@;,:;*;@;,:;|;
        (>; (@;`$;"breaks"   ); (@;,:;dsl.inlineIdentifier));
        (>; (@;`$;"exponent" ); (@;,:;dsl.inlineIdentifier));
        (>; (@;`$;"limits"   ); (@;,:;dsl.inlineIdentifier));
        (>; (@;`$;"from"     ); (@;,:;dsl.inlineIdentifier));
        (>; (@;`$;"to"       ); (@;,:;dsl.inlineIdentifier));
        (>; (@;`$;"midValue" ); (@;,:;dsl.inlineIdentifier));
        (>; (@;`$;"mid"      ); (@;,:;dsl.inlineIdentifier));
        (>; (@;`$;"extend"   ); (@;,:;dsl.inlineIdentifier));
        (>; (@;`$;"palette"  ); (@;,:;dsl.inlineIdentifier));
        (>; (@;`$;"latitude" ); (@;,:;dsl.inlineIdentifier));
        (>; (@;`$;"extension"); (@;,:;dsl.inlineIdentifier))));


dsl.link      : (>; .z.m.axpc.symbol"link";           (@;`$;dsl.identifier));
dsl.primary   : (>; .z.m.axpc.symbol"primary";        (@;`$;dsl.identifier));
dsl.secondary : (>; .z.m.axpc.symbol"secondary";      (@;`$;dsl.identifier));
dsl.textalign : (>; .z.m.axpc.symbol"textalign";      (@;`$;dsl.identifier));
dsl.binspec   : (>; (@;`$;(|;"width";"count")); (@;,:;dsl.inlineIdentifier));
dsl.bin       : (>; .z.m.axpc.symbol"bin"; (@;`$;|;"x";"y"); dsl.binspec);
 
dsl.labels : (>;
    .z.m.axpc.symbol"labels";
    (+; >; (@;`$;dsl.identifier);
           (%; "\""; "\""; @;,:;.z.m.axpc.many .z.m.axpc.notAny"\"")));

dsl.aggr : (>;
    .z.m.axpc.symbol"aggregations";
     (+; |;
        .z.m.axpc.symbol"count";
        .z.m.axpc.a[enlist] (>;
            .z.m.axpc.symbol"custom";
            .z.m.axpc.symbol"name";
            (@;`$;dsl.identifier);
            .z.m.axpc.symbol"column";
            (@;`$;dsl.identifier);
            .z.m.axpc.symbol"op";
            (@;,:;dsl.inlineIdentifier))));

 dsl.binstat : (>;
     .z.m.axpc.symbol"bin";
     (@;,:;*;@;,:;>;
         .z.m.axpc.symbol"column";
         (@;`$;dsl.identifier);
         (|; .z.m.axpc.a[`explicit,] (>; .z.m.axpc.symbol"of"; dsl.binspec);
             .z.m.axpc.a[`implicit,] ""));
     (@;,:;dsl.aggr);
     (?;@;,:;>;
        .z.m.axpc.symbol"settings";
        (*;@;,:;>;
            .z.m.axpc.oneOf .z.m.axpc.symbol each ("norm";"center");
            .z.m.axpc.a[enlist `qexpr,enlist@] dsl.qexpr)));

dsl.quartilesstat : (>;
    .z.m.axpc.symbol"quartiles";
    .z.m.axpc.symbol"column";
    (@;`$;dsl.identifier);
    .z.m.axpc.symbol"aggregate";
    (@;`$;dsl.identifier));

dsl.quantilestat : (>;
    .z.m.axpc.symbol"quantiles";
    .z.m.axpc.symbol"column";
    (@;`$; dsl.identifier));

dsl.lsquaresstat : (>;
    .z.m.axpc.symbol"leastsquares";
    .z.m.axpc.symbol"column";
    (@;`$;dsl.identifier);
    .z.m.axpc.symbol"column";
    (@;`$;dsl.identifier));

dsl.summarystat : (>;
    .z.m.axpc.symbol"summary";
    .z.m.axpc.symbol"column";
    (@;`$;dsl.identifier);
    .z.m.axpc.symbol"aggregate";
    (@;`$;dsl.identifier));

dsl.stat : (>;
    .z.m.axpc.symbol"stat"; (|;
        .z.m.axpc.a[`raw,enlist@] dsl.qexpr;
        dsl.binstat;
        dsl.quartilesstat;
        dsl.quantilestat;
        dsl.lsquaresstat;
        dsl.summarystat));

dsl.option : (|;
    dsl.aes;
    dsl.scale;
    dsl.geom;
    dsl.coord;
    dsl.link;
    dsl.bin;
    dsl.primary;
    dsl.secondary;
    dsl.textalign;
    dsl.labels;
    dsl.stat;
    dsl.aggr);

dsl.customChart : (>;
    .z.m.axpc.symbol"chart";
    .z.m.axpc.a[,:] dsl.inlineIdentifier;
    .z.m.axpc.a[,:] .z.m.axpc.between["{";;"}"] .z.m.axpc.many .z.m.axpc.a[,:] .z.m.axpc.seq (.z.m.axpc.a[`$] dsl.identifier; .z.m.axpc.a[,:] dsl.inlineIdentifier));

dsl.layer : .z.m.axpc.oneOf (
    dsl.i.geom["heatmap";    `x`y];
    dsl.i.geom["point";      `x`y];
    dsl.i.geom["area";       `x`y];
    dsl.i.geom["bar";        `x`y];
    dsl.i.geom["boxplot";    `x`y];
    dsl.i.geom["hbar";       `x`y];
    dsl.i.geom["hboxplot";   `x`y];
    dsl.i.geom["hhistogram"; enlist `y];
    dsl.i.geom["hinterval";  `x`xend`y];
    dsl.i.geom["histogram";  enlist `x];
    dsl.i.geom["interval";   `x`y`yend];
    dsl.i.geom["line";       `x`y];
    dsl.i.geom["path";       `x`y];
    dsl.i.geom["polygon";    `xs`ys];
    dsl.i.geom["quantile";   enlist `y];
    dsl.i.geom["rect";       `x`y`xend`yend];
    dsl.i.geom["ribbon";     `x`y`yend];
    dsl.i.geom["scatter";    `x`y];
    dsl.i.geom["segment";    `x`y`xend`yend];
    dsl.i.geom["text";       `x`y`text];
    dsl.i.geom["tile";       `x`y];
    dsl.customChart;
    .z.m.axpc.then[.z.m.axpc.symbol "hline"] .z.m.axpc.then[.z.m.axpc.a[,:]  dsl.inlineIdentifier] .z.m.axpc.a[,:] .z.m.axpc.many .z.m.axpc.a[,:]  dsl.option;
    .z.m.axpc.then[.z.m.axpc.symbol "vline"] .z.m.axpc.then[.z.m.axpc.a[,:]  dsl.inlineIdentifier] .z.m.axpc.a[,:] .z.m.axpc.many .z.m.axpc.a[,:]  dsl.option);

dsl.stack : .z.m.axpc.seq (
        .z.m.axpc.symbol"stack";
        .z.m.axpc.between["{";;"}"]
            .z.m.axpc.many1  .z.m.axpc.oneOf (
                dsl.tok[`layer] dsl.layer;
                dsl.tok[`stack]  .z.M.gg.dsl.stack)) ;

dsl.frame : (|;
    dsl.tok[`layer] dsl.layer;
    dsl.tok[`stack] dsl.stack);


dsl.title : .z.m.axpc.seq (
    .z.m.axpc.a[`$] "title";
    .z.m.axpc.between["\""; .z.m.axpc.a[,:] .z.m.axpc.many .z.m.axpc.notAny"\""; "\""]);

dsl.theme : (>;
    .z.m.axpc.ignore .z.m.axpc.symbol"theme";
    (|;
        .z.m.axpc.a[`themename,] .z.m.axpc.a[`$] dsl.identifier;
        .z.m.axpc.a[`theme,].z.m.axpc.a[,:] (%; "{"; "}"; *; @; ,:; >;
                    .z.m.axpc.a[`$] dsl.identifier;
                    .z.m.axpc.a[,:] dsl.inlineIdentifier))) ;
 
dsl.split : (>;
    .z.m.axpc.symbol"split";
    .z.m.axpc.between["{"; .z.m.axpc.many1 dsl.frame; "}"]); // (%; "{"; "}"; +; dsl.frame)); 

dsl.layout : (>;
    .z.m.axpc.oneOf .z.m.axpc.symbol each ("vertical"; "horizontal");
    (?; >; .z.m.axpc.symbol"weights"; .z.m.axpc.a[,:] dsl.qexpr);
    .z.m.axpc.between["{"; .z.m.axpc.many1 .z.m.axpc.delay .z.M.gg.dsl.spec; "}"]);

dsl.spec : (|;
        dsl.frame;
        dsl.tok[`title] (>; dsl.title;  .z.M.gg.dsl.spec);
        dsl.tok[`theme] (>; dsl.theme;  .z.M.gg.dsl.spec);
        dsl.tok[`split]  dsl.split;
        dsl.tok[`layout] dsl.layout);
  
dsl.plot : (>;
    dsl.tok[`go] dsl.top;
    dsl.spec;
    .z.m.axpc.ws[]);

system "d .z.m";

system "d .z.m.gg";
.z.m.gg.math.angle:{ math.atan2[y 1; y 0] - math.atan2[x 1; x 0] }
.z.m.gg.math.atan2:{[y;x]
    $[x>0;          atan y % x;
      (x<0)&y>=0;   atan[y % x] + acos -1;
      (x<0)&y<0;    atan[y%x] - acos -1;
      (x=0)&y>0;    acos[-1]%2;
      (x=0)&y<0;    acos[-1]%-2;
                    0n]
    }
.z.m.gg.math.degtorad:{[x] (acos[-1]%180)*x }

.z.m.gg.math.midpoint:{ a:(x[0]+y 0)%2; b:(x[1]+y 1)%2; (a;b) }
.z.m.gg.math.radtodeg:{[x] (180%acos -1)*x }

.z.m.gg.math.rotatept:{[p;a] ( (p[0]*cos a)-p[1]*sin a; (p[1]*cos a)+p[0]*sin a) }

.z.m.gg.math.unit.tri:(-0.866 -0.5; 0.866 -0.5; 0.0 1.0)
system "d .z.m";

system "d .z.m.st";
// @fileOverview 
// Locally weight linear regression
// Given weights for each x, a list of xs, a list of ys, and a local
// interval, compute the low-polynomial linear regression within the
// interval.
// @param xs {number[]} 
// @param ys {number[]} 
// @param weights {float[]} 
// @param ii {long} 
// @param interval {long[]}
// @returns {dict}
.z.m.st.loess.i.localRegression:{[xs; ys; weights; rweights; ii; interval; accuracy]
    x      : xs ii;
    ileft  : first interval;
    iright : last interval;
    edge   : $[(x - xs ileft) > xs[iright] - x; ileft; iright];
    denom  : abs 1 % xs[edge] - x;
    ks     : .z.m.axq.until[ileft;iright-1];
    xks    : xs ks;
    yks    : ys ks;
    dists  : @[xks-x; is; :; x-xks is:where ks < ii];
    ws     : tricube[dists * denom] * rweights[ks] * weights ks;
    xkws   : xks * ws;
    
    lres : (!) . flip (
        (`;::);
        (`sumWeights;  sum ws);
        (`sumX;        sum xkws);
        (`sumXSquared; sum xks * xkws);
        (`sumY;        sum yks * ws);
        (`sumXY;       sum yks * xkws)
        );
    lres ,: (!). flip (
        (`meanX;        lres[`sumX]  % lres `sumWeights);
        (`meanY;        lres[`sumY]  % lres `sumWeights);
        (`meanXY;       lres[`sumXY] % lres `sumWeights);
        (`meanXSquared; lres[`sumXSquared] % lres `sumWeights)
        );
      
    lres[`beta] : $[accuracy > sqrt abs lres[`meanXSquared] - lres[`meanX] xexp 2;
        0;
        (lres[`meanXY] - lres[`meanX] * lres `meanY) % lres[`meanXSquared] - lres[`meanX] xexp 2];

    lres[`alpha]    : lres[`meanY] - lres[`beta] * lres `meanX;
    : lres[`alpha] + lres[`beta] * x;
    }
.z.m.st.loess.i.nextInterval:{[xval; weights; ii; bandwidthInterval]
    
    left      :  bandwidthInterval 0;
    right     :  bandwidthInterval 1;
    nextRight : loess.i.nextNonZero[weights; right];
    
    if [(nextRight < count xval) and (xval[nextRight] - xval ii) < xval[ii] - xval left;
        nextLeft: loess.i.nextNonZero[weights; left];
        bandwidthInterval[0]: nextLeft;
        bandwidthInterval[1]: nextRight;
        ];
    
    : bandwidthInterval;
    
    }

.z.m.st.loess.i.nextNonZero:{[weights; i]
    j: i + 1;
    while [(j < count weights) and weights[j] = 0; j+:1];
    : j;
    }

// Based on LoessInterpolator in org.apache.commons.math: 
// http://commons.apache.org/proper/commons-math/apidocs/index.html
// and Cleveland's lowess: http://www.netlib.org/go/lowess.f
.z.m.st.loess.smooth:{[xs; ys; opts]
    
    opts : .z.m.gg.h.extend[opts]``bandwidth`iters`accuracy`delta!(::;0.25;2;1e-12;0);
    
    if [not count[xs] ~ count ys;  '.z.m.axlocalize.t`.st_loessLengthError];

    if [not (.z.m.gg.tbl.metatype[([]x:xs);`x]) in "xhijefpmdznuvt"; /dnl
        '.z.m.axlocalize.t`.st_loessFloatError];
    if [not (.z.m.gg.tbl.metatype[([]x:ys);`x]) in "xhijefpmdznuvt"; /dnl
        '.z.m.axlocalize.t`.st_loessFloatError];
    
    ii : iasc xs;
    xs @: ii;
    ys @: ii;
    n  : count xs;
    ws : n#1; // weights
    
    if [n < 3;
        : `x`response`residuals!(xs;n#ys;n#0f)];
    
    bandwidthInPoints : floor opts[`bandwidth] * n;  // # points within bandwidth
    
    if [bandwidthInPoints < 2; '.z.m.axlocalize.t`.st_loessBandwidthError];
    
    rws : n#1f; // residual weights   
    
    ds:deltas xs;
    nz : where not 0 = ds;
    ivalid : $[0=opts`delta;
        til n;
        distinct 0,(where 0 > @[ds;nz;:;(type ds)$deltas (sums ds nz) mod opts`delta]),n-1];
    
    iter : -1;
    response : residuals : 0;
    while [ (iter+:1) <= opts `iters;
        interval  : (0; bandwidthInPoints-1);
        intervals : -1_last flip {(x[0]+1;loess.i.nextInterval[y;z;x 0;x 1])}[;xs;ws]\[{x > y 0} n;(0;interval)];
        response : ({[xs;ys;ws;rws;interval;opts;ii]
            : loess.i.localRegression[xs; ys; ws; rws; ii; interval; opts`accuracy]
            }[xs;ys;ws;rws;;opts].) peach flip (intervals ivalid;ivalid);
        
        response:"f"$raze {
                .z.m.gg.proj.proj[x 0; x 1; .z.m.axq.until[x[0;0]; x[0;1]]]
                } peach flip (ivalid,'n^next ivalid;response,'(max response)^next response);
        residuals    : "f"$ys - response;
        absResiduals : "f"$abs residuals;

        if [not iter = opts `iters;
            m : med absResiduals;

            if [not opts[`accuracy] > abs m;
                arg : absResiduals % 6 * m;
                rws: @[n#0f;is;:;(w*w:1-arg xexp 2)is:where not arg >= 1]]]];
    
    : `x`response`residuals!(xs;response;residuals);
    
    }

.z.m.st.loess.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.st_loessLengthError; "Lists must be equal length");
        (`.st_loessFloatError; "Lists must contain float data");
        (`.st_loessBandwidthError; "Bandwidth is too small")
    ))
system "d .z.m";

system "d .z.m.qp";
// @subcategory Geometries
// @fileOverview 
// Area chart - draw a filled line given the X and Y coordinates of the line.
//
// - X - horizontal position
// - Y - vertical position
//
// Series can be stacked (see examples below).
//
// Aesthetic mappings ( .z.M.qp.s.aes`, dynamic) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `group `` - Grouping (combined with `` `position `` geom settings)
//
// Geometry settings ( .z.M.qp.s.geom`, static) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `position `` - `` `stack ``
// - `` `decorations `` - Disable line and point decorations
//
// @param table {table} data to be visualized 
// @param x {symbol} x column 
// @param y {symbol} y column 
// @param settings {dict | null} settings for the visual (theme/geom/etc)
// @returns {table} specification table for a line chart
//
// @format .z.m.qp.i.qdformatter
//
// @example Load data and basic plot
//      t : ([]x: til 100; y: { sin[3*x] + sin[2*x] } acos[-1] * til[100] % 100);
//
//      .z.m.qp.area[t; `x; `y; ::]
//
// @example Disable points and outline
//
//      .z.m.qp.area[t; `x; `y]
//          .z.m.qp.s.geom[enlist[`decorations]!enlist 0b]
//
// @example Filled and alpha
//      .z.m.qp.area[t; `x; `y]
//          .z.m.qp.s.geom[`alpha`areaAlpha`fill!(0x7f; 0x2f; 0xb22222)]
//
// @example Grouped and stacked
//      t : raze { ([]
//             x: til 100; 
//             y: 5 + { sin[rand[5]*x] + sin[rand[5]*x] } acos[-1] * til[100] % 100; z: x) 
//         } each `a`b`c;
//
//      .z.m.qp.area[t; `x; `y]
//            .z.m.qp.s.aes[`fill`group; `z`z]
//          , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat10]
//          , .z.m.qp.s.geom[``position!(::; `stack)]
//
// @example Grouped and stacked with properties
//      .z.m.qp.area[t; `x; `y]
//            .z.m.qp.s.aes[`fill`group; `z`z]
//          , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat `blues]
//          , .z.m.qp.s.geom[`colour`position`alpha`strokewidth!(`black; `stack; 0x7f; 3)] 
.z.m.qp.area:{[table; x; y; settings]
    : i.apoint[.z.m.gg.geom.area; table; x; y; settings];
    }





.z.m.qp.bar:{[table; x; y; settings]
    : i.apoint[.z.m.gg.geom.vbar; table; x; y; settings];
    }

// @subcategory Geometries
// @fileOverview 
// Box plot showing median, first and third quartiles, farthest
// point within 1.5 times the interquartile range from the median
// on either side, and all outliers (points further than this).
//
// - X - Category (position along the horizontal)
// - Y - Continuous value (value to summarize)
//
// The X column should be a category, and the Y column continuous.
//
// @param table {table} data to be visualized 
// @param x {symbol} x column 
// @param y {symbol} y column 
// @param settings {dict | null} settings for the visual (theme/geom/etc)
// @returns {table} specification tree for a box plot
//
// @format .z.m.qp.i.qdformatter
//
// @example Load data and basic categorical plot
//      t : ([]x: raze 50#enlist 10?`5; y: 500?50; z: raze 50#'til 10);
//
//      .z.m.qp.boxplot[t; `x; `y; ::]
//
// @example Basic numeric plot
//      .z.m.qp.boxplot[t; `z; `y; ::]
//
.z.m.qp.boxplot:{[table; x; y; settings]
    : i.aboxplot[(.z.m.gg.geom.vinterval; .z.m.gg.geom.verrorbar);
        `x;
        (   `x`y`xend`yend!(x;`lower__;x;`upper__);
            `x`y`yend!(x;`q1__;`q3__);
            `x`y`yend!(x;`med__;`med__));
        (x; y);
        table; x; y; settings];
    }

// @subcategory Rendering
// @fileOverview 
// Display a plot with the given width and height. The renders the plot, 
// but does not serve the plot to the IDE. The bytes can be used directly.
// For serving a visual, see  .z.M.qp.go`.
//
// The image output (for whichever renderer was used) will be stored in the `` `output ``
// field of the result. The default renderer is a png renderer, and contains the following keys:
// `` `w`h`bytes ``.
// @see qp.go
// @param w {long} width in pixels
// @param h {long} height in pixels
// @param v {table} specification table
// @returns {dict} displayed GG object
//
// @example
// .z.m.qp.display[500;500] .z.m.qp.point[([]x:til 45); `x; `x; ::]
// /=>              | ::
// /=> i_.type      |  .z.M.gg.ty
// /=> i_.extensions| `symbol$()
// /=> id           | ::
// /=> spec         | +`id`parents`children`item!(3fe4d662-12ab-ed6...
// /=> output       | ``i_.type`i_.extensions`w`h`bytes!(::; ...
.z.m.qp.display:{[w;h;v]
    : .z.m.gg.display[w;h;.z.m.gg.new v]
    }


.z.m.qp.dsl:{[e; f]
    f: $[10h ~ type f; f; -11h ~ type f; "\n" sv read0 f; '`unknownType];
    : .z.m.gg.dsl.eval[e] .z.m.gg.dsl.parse f;
    }


.z.m.qp.empty:{[]
    : .z.m.qp.theme[`plot_background_fill`axis_use_x`axis_use_y!(0x00000000; 0b; 0b)] .z.m.qp.scatter[([]a:());`a;`a;::];
    }

// @subcategory Geometries
// @fileOverview 
// Vertical error bar geometry.
//
// - X - position along the horizontal
// - Y - first point of the interval
// - YEND - second point of the interval
//
// Series can be dodged (see examples below).
//
// Aesthetic mappings ( .z.M.qp.s.aes`, dynamic) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `group `` - Grouping (combined with `` `position `` geom settings)
//
// Geometry settings ( .z.M.qp.s.geom`, static) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `position `` - `` `dodge `` 
//
// @param table {table} 
// @param x {symbol} column name
// @param y {symbol} column name
// @param yend {symbol} column name
// @param settings {dict | null}  settings for the visual (geom/bins/etc)
// @returns {table} tree specifying an interval chart
//
// @format .z.m.qp.i.qdformatter
// 
// @example Stacking with a point
//      t:update l1:x-.25,l2:x+.25 from 
//          0!select max x by y, y2 from 
//          ([]x:.z.m.st.gen.normal 100;y:100?`a`b`c`d; y2:100?`e`f`g`h);
//
//      .z.m.qp.stack (
//         .z.m.qp.errorbar[select from t where y2=`e; `y; `l1; `l2; ::];
//         .z.m.qp.point   [select from t where y2=`e; `y; `x]
//             .z.m.qp.s.geom[``size!(::;5)])
//
// @example Dodged error bars stacked with bars
//     .z.m.qp.stack (
//         .z.m.qp.bar[t;`y;`x] 
//             .z.m.qp.s.aes[`group`fill; `y2`y2] , 
//             .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat `rdylbu] ,
//             .z.m.qp.s.geom[``position!(::;`dodge)];
//         .z.m.qp.errorbar[t;`y;`l1;`l2] 
//             .z.m.qp.s.aes[`group; `y2] , 
//             .z.m.qp.s.geom[``position`fill!(::;`dodge;`black)])
//
.z.m.qp.errorbar:{[table; x; y; yend; settings]
    : i.ageom[.z.m.gg.geom.verrorbar; table; x; y; `x`y`yend; (x;y;yend); settings];
    }
// @subcategory Layouts
// @fileOverview 
// Split a table on distinct values of a given column,
// and display a separate visual for each subset of the data.
//
// @param t {table} (optional) table to facet 
// @param x {symbol} column to split on 
// @param sp {fn} partial specification (function from table to specification tree) 
// @returns {table} specification table
//
// @format .z.m.qp.i.qdformatter
//
// @example Load data and basic categorical plot
//      t : ([]x: raze 5#enlist 10?`5; y: 50?5; z: raze 5#'til 10);
//
//      .z.m.qp.facet[t; `x] .z.m.qp.plot[; `y`z; ::]
//
.z.m.qp.facet:{[t; x; sp]
    : .z.m.gg.spec.with.facet[x] $[100 <= type sp; sp t; sp];
    }


.z.m.sixel:{[w;h;c;b]
    rgb:3#'c cut b;
    weight:count@'group rgb;
    maxd:{(l?ml;ml:max l:abs (-) . (min;max)@\:x)};
    medcut:{  r:$[type first x;
                  {(x#y;x _ y)}[;o] first where {$[all x;01b;x]} (sum[w]%2)<sums w:y o:x idesc x[;z[x]@0];
                  (x _ i),{(x#y;x _ y)}[;o] first where {$[all x;01b;x]} (sum[w]%2)<sums w:y o:x[i] idesc x[i][;m[i:{x?max x} (m:z@'x)[;1];0]]
                  ];
                  if[any w:()~/:r;r:r _ first where w];r}[;weight;maxd];
    p:255 medcut/distinct rgb;
    p:distinct "i"$ weight[p] wavg' p;
    rgb:"i"$rgb;
    idxmap:(w;h)#((distinct rgb)!{d?min d:sum@/:abs x-/:y}[;p] each distinct rgb)@rgb;
    head:"\033Pq\"1;1;",string[count[first idxmap]],";",string[count idxmap];
    pallet:{[i;b;g;r]"#",string[i],";2;",string[r],";",string[g],";",string[b]} ./: til[count p],'(100*p) div 255;
    footer:"\033\\";
    // TODO: Repeats done properly with counts
    if[md:count[idxmap] mod 6;idxmap,:(6-md)#enlist count[first idxmap]#0Wj];
    idxc:6 cut idxmap;
    body:"-" sv {pal:distinct raze x;r:("#",'string[pal]),'`char$63+sum@/:(2 xexp til 6)*/:pal=\:x;"$" sv r} each idxc;
    head,(raze pallet),body,footer
  }

// @subcategory Rendering
// @fileOverview
// Render a visual specification at the given width and height, and send the 
// visual to the Analyst IDE
// @param w {long} width in pixels
// @param h {long} height in pixels
// @param spec {table} a GG specification (for example, `` .z.m.qp.point[t; `x; `y; ::] ``)
// @returns {null}
//
// @example
// .z.m.qp.go[500;500] .z.m.qp.point[([]x:til 45); `x; `x; ::]
.z.m.qp.go:{[w; h; spec]
    if[.z.k < 2026.04.10;'"sixel not supported with this version of KDB-X. Requires 2026.04.10. Use qp.png or upgrade"];
    -1 .z.m.qp.i.go[w; h; spec];
    }

.z.m.qp.i.go:{[w; h; spec]
    o:.z.m.gg.i.DEFAULTRENDERER.render;
    .z.M.gg.i.DEFAULTRENDERER.render set {:.z.m.axskiaw.i.toRGB x};
    r:.z.m.sixel . {x . `output`bytes} .z.m.qp.display[w;h] spec;
    .z.M.gg.i.DEFAULTRENDERER.render set o;
    r
    }

.z.m.qp.grid:{[grid; speclist]
    : .z.m.qp.layout[`grid; grid] speclist;
    }

// @subcategory Geometries
// @fileOverview 
// Horizontal bar chart.
//
// - X - length of the bar
// - Y - vertical position
//
// Series can be stacked or dodged (see examples below).
//
// By default, the bars will start at the smallest value, unless extended
// in order to get a nice range for axis ticks. The minimum or maximum can
// be extended to any desired value. This is useful to set the minimum to 0
// to compare the absolute heights rather than the relative heights. This
// is done by setting the  .z.M.gg.scale.limits[(min;max)]` on the X scale.
//
// Aesthetic mappings ( .z.M.qp.s.aes`, dynamic) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `group `` - Grouping (combined with `` `position `` geom settings)
//
// Geometry settings ( .z.M.qp.s.geom`, static) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `position `` - `` `dodge `` or `` `stack ``
// - `` `gap `` - Gap between bars as percent of width/height (i.e., `0.03` for 3%)
// - `` `align `` - Bar alignment
// - `` `sortByValue `` - Sort bars by y axis value (largest to smallest)
//
// @see gg.scale.limits
// @param table {table} data to be visualized 
// @param x {symbol} x column 
// @param y {symbol} y column 
// @param settings {dict | null} settings for the visual (theme/geom/etc)
// @returns {table} specification tree for a bar chart
//
// @format .z.m.qp.i.qdformatter
// @example Load data and basic plot
//     t: ([] x: 15#.Q.a; y: 10 + sums 15?-2 -1 1 2);
//
//     .z.m.qp.hbar[t; `y; `x; ::]
//
// @example Change colour and order by value
//      .z.m.qp.hbar[t; `y; `x]
//          .z.m.qp.s.geom[``fill`sortByValue!(::; `slategrey; 1b)]
//
// @example Annotate with text labels and start at 0
//     .z.m.qp.stack (
//         .z.m.qp.hbar[t; `y; `x]
//              .z.m.qp.s.geom[``fill`sortByValue!(::; `slategrey; 0b)];
//         .z.m.qp.text[t; `y; `x; `y]
//              .z.m.qp.s.geom[``offsetx`align`bold`size!(::;10;`middle;1b;11)])
//
// @example Grouped
//      t: raze { ([] cat:x; x: 15#.Q.a; y: 10 + sums 15?-2 -1 1 2)} each `cat1`cat2`cat3`cat4;
//
//      .z.m.qp.hbar[t; `y; `x]
//            .z.m.qp.s.aes[`fill; `cat]
//
// @example Grouped and stacked
//      .z.m.qp.hbar[t; `y; `x]
//            .z.m.qp.s.aes[`fill`group; `cat`cat]
//          , .z.m.qp.s.geom[``position!(::; `stack)]
//          , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat `puor]
//
// @example Grouped and dodged with custom y and fill scales
//
//      .z.m.qp.hbar[select from t where x in "abcde"; `y; `x]
//            .z.m.qp.s.aes   [`fill`group; `cat`cat]
//          , .z.m.qp.s.geom  [``position`gap!(::; `dodge;0.05)]
//          , .z.m.qp.s.scale [`fill; .z.m.gg.scale.colour.cat `brbg]
//             // start y axis at 0
//          , .z.m.qp.s.scale [`x; .z.m.gg.scale.limits[0 0N] .z.m.gg.scale.linear]
//
.z.m.qp.hbar:{[table; x; y; settings]
    : i.apoint[.z.m.gg.geom.hbar; table; x; y; settings];
    }

// @subcategory Geometries
// @fileOverview 
// Horizontal box plot showing median, first and third quartiles, farthest
// point within 1.5 times the interquartile range from the median
// on either side, and all outliers (points further than this).
//
// - X - Continuous value (value to summarize)
// - Y - Category (position along the vertical)
//
// The Y column should be a category, and the X column continuous.
// @param table {table} data to be visualized 
// @param x {symbol} x column 
// @param y {symbol} y column 
// @param settings {dict | null} settings for the visual (theme/geom/etc)
// @returns {table} specification tree for a box plot
//
// @format .z.m.qp.i.qdformatter
//
// @example Load data and basic categorical plot
//      t : ([]x: raze 50#enlist 10?`5; y: 500?50; z: raze 50#'til 10);
//
//      .z.m.qp.hboxplot[t; `y; `x; ::]
//
// @example Basic numeric plot
//      .z.m.qp.hboxplot[t; `y; `z; ::]
//
.z.m.qp.hboxplot:{[table; x; y; settings]
    : i.aboxplot[(.z.m.gg.geom.hinterval; .z.m.gg.geom.herrorbar);
        `y;
        (   `y`x`yend`xend!(y;`lower__;y;`upper__);
            `y`x`xend!(y;`q1__;`q3__);
            `y`x`xend!(y;`med__;`med__));
        (y; x);
        table; x; y; settings];
    }



.z.m.qp.heatmap:{[table; x; y; settings]
    
    settings : i.initSettings settings;
    
    norm : i.resolveItem[settings; `norm] i.describe[`norm; enlist`norm; enlist (::)];
    
    aes : i.resolveMulti[`aes; settings] i.describe[`aes; i.AES,`x`y]
                (::; ::; $[(::)~norm;`count__; `norm__]; ::; ::; ::; ::; ::; ::; x; y);
    
    scales : i.resolveMulti[`scales; settings] i.describe[`scales; i.SCALES]
                 (.z.m.gg.scale.alpha[50; 255]; ::; ::; ::; ::; ::);
        
    aes : i.filterAes[aes; scales];
    
    initF : {[settings; gg; node; lyr]
        scales     : last[.z.m.gg.layer.i.addMissingScales[::; lyr; `x`y; `data]]`scales;
        aes        : lyr`aes;
        table      : lyr`data;
        
        .z.m.gg.scale.validate[scales`x] xdomain : .z.m.gg.tbl.column[table; aes`x];
        .z.m.gg.scale.validate[scales`y] ydomain : .z.m.gg.tbl.column[table; aes`y];
        
        xscalei    : .z.m.gg.scale.init [scales`x] xdomain;
        yscalei    : .z.m.gg.scale.init [scales`y] ydomain;
        bins       : i.resolveBins[settings; table; aes`x; aes`y; xscalei; yscalei];
        aggr       : i.resolveItem[settings; `aggr] i.describe[`aggr; enlist`aggr; enlist .z.m.st.a.count[]];
        norm       : i.resolveItem[settings; `norm] i.describe[`norm; enlist`norm; enlist (::)];

        stat : i.resolveStat[settings] i.describe[`stat; `transform`bins`aggr]
                     (.z.m.gg.stat.sbinNd_i[(aes`x;aes`y); (bins 0; bins 1); (xscalei; yscalei); aggr; enlist[`norm]!enlist norm];
                      bins; aggr);

        binsi : .z.m.st.bins [table; aes`x`y; bins; (xscalei; yscalei)];
        geom  : .z.m.gg.h.extend[enlist[`]!enlist (::)] i.resolveWDefault[()!(); `geom; settings];
        geom[`width`height]: min each 0W,/:1^binsi`width;
        
        : .z.m.gg.h.extend[`geom`stat!(.z.m.gg.geom.tile geom; stat`transform)] lyr;
        
        } settings;
        
    coord      : i.resolveWDefault[.z.m.gg.coords.rect; `coord; settings];
    primary    : i.resolveWDefault[::; `primaryid; settings];
    secondary  : i.resolveWDefault[::; `secondaryid; settings];
    linkid     : i.resolveWDefault[::; `linkid; settings];
    onclick    : i.resolveWDefault[::; `onclick; settings];
    ondrilldown: i.resolveWDefault[::; `ondrilldown; settings];
    share      : i.resolveMulti[`share;settings] i.describe[`share; i.SCALES] count[i.SCALES]#(::);
    
    labels     : i.resolveLabels[settings] i.describe[`labels; enlist`labels; enlist ()!()];
    th         : i.resolveWDefault[()!(); `theme; settings];
    legends    : i.resolveLegends settings;
    
    : .z.m.gg.spec.with.theme[i.cleanLabels labels]
        .z.m.gg.spec.with.theme[th]
            .z.m.gg.spec.single .z.m.gg.layer.new `initF`data`aes`coord`scales`linkid`primaryid`secondaryid`legends`onclick`ondrilldown`share`zoomF!(
                initF; table; aes; coord; scales; linkid; primary; secondary; legends; onclick; ondrilldown; share; 1b);
    
    }

// @subcategory Geometries
// @fileOverview 
// Horizontal error bar geometry.
//
// - X - first point of the interval
// - XEND - second point of the interval
// - YEND - position along the vertical
//
// Series can be dodged (see examples below).
//
// Aesthetic mappings ( .z.M.qp.s.aes, dynamic) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `group `` - Grouping (combined with `` `position `` geom settings)
//
// Geometry settings ( .z.M.qp.s.geom`, static) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `position `` - `` `dodge `` 
//
// @param table {table} 
// @param x {symbol} column name
// @param xend {symbol} column name
// @param y {symbol} column name
// @param settings {dict | null}  settings for the visual (geom/bins/etc)
// @returns {table} tree specifying an interval chart
//
// @format .z.m.qp.i.qdformatter
// 
// @example Stacking with a point
//      t:update l1:x-.25,l2:x+.25 from 
//          0!select max x by y, y2 from 
//          ([]x:.z.m.st.gen.normal 100;y:100?`a`b`c`d; y2:100?`e`f`g`h);
//
//      .z.m.qp.stack (
//         .z.m.qp.herrorbar[select from t where y2=`e; `l1; `l2; `y; ::];
//         .z.m.qp.point   [select from t where y2=`e; `x; `y]
//             .z.m.qp.s.geom[``size!(::;5)])
// 
// @example Dodged error bars stacked with bars
//     .z.m.qp.stack (
//         .z.m.qp.hbar[t;`x;`y] 
//             .z.m.qp.s.aes[`group`fill; `y2`y2] , 
//             .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat `rdylbu] ,
//             .z.m.qp.s.geom[``position!(::;`dodge)];
//         .z.m.qp.herrorbar[t;`l1;`l2;`y] 
//             .z.m.qp.s.aes[`group; `y2] , 
//             .z.m.qp.s.geom[``position`fill!(::;`dodge;`black)])
//
.z.m.qp.herrorbar:{[table; x; xend; y; settings]
    : i.ageom[.z.m.gg.geom.herrorbar; table; x; y; `x`xend`y; (x;xend;y); settings];
    }

// @example Change from a stack to a dodge with a blue scale
//     .z.m.qp.hhistogram[t; `x]
//         .z.m.qp.s.scale[`x; .z.m.gg.scale.limits[0 0N] .z.m.gg.scale.linear]
//         , .z.m.qp.s.stat[ .z.m.gg.stat.bin2d[`x`c1; ::; ::; .z.m.st.a.count[]; ::] ]
//         , .z.m.qp.s.geom[``position!(::; `stack)]  // <- changed to stack
//         , .z.m.qp.s.aes[`group; `c1]
//         , .z.m.qp.s.aes[`fill; `c1]
//         , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat `pubugn]
//
// @example Stack with an binned line of another continuous column using 100 bins
//     .z.m.qp.stack (
//         .z.m.qp.hhistogram[t; `x]
//             .z.m.qp.s.scale[`x; .z.m.gg.scale.limits[0 0N] .z.m.gg.scale.linear]
//             , .z.m.qp.s.stat[ .z.m.gg.stat.bin2d[`x`c1; (`c;100;0); ::; .z.m.st.a.count[]; ::] ]
//             , .z.m.qp.s.biny[`x;100;0]
//             , .z.m.qp.s.geom[``position`gap!(::;`stack;0)]
//             , .z.m.qp.s.aes[`group; `c1]
//             , .z.m.qp.s.aes[`fill; `c1]
//             , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat `bugn];
//         .z.m.qp.path[t;  `count__; `y]
//             .z.m.qp.s.stat[ .z.m.gg.stat.bin1d[`y; (`c;100;0); .z.m.st.a.count[]; ::] ] 
//             , .z.m.qp.s.geom[``fill`size!(::; 0xcd0000;1.5)])
.z.m.qp.hhistogram:{[table; x; settings]
    : i.ahistogram[.z.m.gg.geom.hbar; `y; table; x; settings];
    }

// @private
.z.m.qp.hhistogram2:{[table; x; y; s]
    
    : i.ahistogram[.z.m.gg.geom.hbar; `y; table; y; s];
    }

// @subcategory Geometries
// @fileOverview 
// Horizontal interval chart - an interval between two numbers on the X axis for each value along the Y axis.
//
// - X - first point of the interval
// - XEND - second point of the interval
// - Y - position along the vertical
//
// Series can be dodged (see examples below).
//
// Aesthetic mappings ( .z.M.qp.s.aes`, dynamic) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `group `` - Grouping (combined with `` `position `` geom settings)
//
// Geometry settings ( .z.M.qp.s.geom`, static) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `position `` - `` `dodge `` 
// - `` `gap `` - Gap between bars as percent of width/height (i.e., `0.03` for 3%)
// - `` `align `` - Bar alignment
// @param table {table} data to be visualized
// @param x {symbol} column name
// @param xend {symbol} column name
// @param y {symbol} column name
// @param settings {dict}  settings for the visual (geom/bins/etc)
// @returns {table} tree specifying an hinterval chart
//
// @format .z.m.qp.i.qdformatter
//
// @example Load data and basic plot
//      t: ([] x: `a`b`c`d`e`f`g; y1: -50+7?100; y2: 50+7?100);
//      .z.m.qp.hinterval[t;  `y1; `y2;`x; ::]
//
// @example Filled
//      .z.m.qp.hinterval[t; `y1; `y2; `x]
//          .z.m.qp.s.geom[``fill!(::;0x0070cd)]
//
// @example Grouped and dodged
//      t:  raze {[category;num] ([] 
//             c1: category; 
//             c2: num?`cat1`cat2`cat3;
//             x: (-2 + rand 4f) + .z.m.st.gen.normal num; 
//             y: .z.m.st.gen.normal num) 
//         }'[`a`b`c`d`e; 10000+5?35000];
//      t: select y1: min x, y2: max x by c1, c2 from t;
//    
//      .z.m.qp.hinterval[t; `y1; `y2; `c1]
//            .z.m.qp.s.aes[`fill; `c2]
//          , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat10]
//          , .z.m.qp.s.aes[`group;`c2]
//          , .z.m.qp.s.geom[``position!(::; `dodge)]
//
// @example Positive/negative bar charts
//     t: ([]y:0; y2: (.z.m.st.gen.normal[30] % 5) + sin 3 * acos[-1] * til[30] % 30; x:til 30);
//     t: update pos:y2>=0 from t;
//    
//     .z.m.qp.hinterval[t; `y; `y2; `x]
//           .z.m.qp.s.aes[`fill; `pos]
//         , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat 01b!(0xcd4000; 0x0070cd)]
//        
// @example Stack a moving average line
//   
//     .z.m.qp.stack (
//         .z.m.qp.hinterval[t; `y; `y2; `x]
//               .z.m.qp.s.aes[`fill; `pos]
//             , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat 01b!(0xcd4000; 0x0070cd)]
//             , .z.m.qp.s.geom[``alpha!(::;0x7f)];
//         .z.m.qp.path[update y2: 10 mavg y2 from t; `y2; `x]
//               .z.m.qp.s.geom[``size!(::;2)])
//
.z.m.qp.hinterval:{[table; x; xend; y; settings]
    : i.ageom[.z.m.gg.geom.hinterval; table; x; y; `x`y`xend; (x;y;xend); settings];
    }
// @subcategory Geometries
// @fileOverview 
// Vertical histogram chart - the height of each bar depicts the number of observations of each distinct value
//
// - X - the position along the X axis
//
// Aesthetic mappings ( .z.M.qp.s.aes`, dynamic) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `group `` - Grouping (combined with `` `position `` geom settings)
//
// Geometry settings ( .z.M.qp.s.geom`, static) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `position `` - `` `dodge `` or `` `stack ``
// - `` `sortByValue `` - Sort bars by y axis value (largest to smallest)
//
// @param table {table} data to be visualized 
// @param x {symbol} column name 
// @param settings {dict | null} settings for the visual (geom/bins/etc)
// @returns {table} specification tree
//
// @format .z.m.qp.i.qdformatter
//
// @example Load data and continuous histogram
//     t: raze {[category; num]
//         ([] 
//             c1: category; 
//             x: 2 * (-2 + rand 4f) + .z.m.st.gen.normal num; 
//             y: .z.m.st.gen.normal num; 
//             z:  {acos[-1] * x % max x} .z.m.st.gen.normal num) 
//         }'[`a`b`c`d`e; 10000+5?35000];
//
//     .z.m.qp.histogram[t; `c1; ::]
//
// @example Change the scale to start at 0 and order by value
//
//     .z.m.qp.histogram[t; `c1]
//         .z.m.qp.s.scale[`y; .z.m.gg.scale.limits[0 0N] .z.m.gg.scale.linear] ,
//         .z.m.qp.s.geom[``sortByValue!(::;1b)]
//
// @example Continuous axis with fill colour
//     .z.m.qp.histogram[t; `x]
//         .z.m.qp.s.geom[``fill!(::; 0x0070cd)]
//
// @example Dodge based on another column
//     .z.m.qp.histogram[t; `x]
//         .z.m.qp.s.scale[`y; .z.m.gg.scale.limits[0 0N] .z.m.gg.scale.linear]
//                      // Requires a 2D bin transform rather than a 1D
//         , .z.m.qp.s.stat[ .z.m.gg.stat.bin2d[`x`c1; ::; ::; .z.m.st.a.count[]; ::] ]
//         , .z.m.qp.s.geom[`position`gap!(`dodge; 0)]
//         , .z.m.qp.s.aes[`group`fill; `c1`c1]
//
// @example Add an explicit fill scale
//     .z.m.qp.histogram[t; `x]
//         .z.m.qp.s.scale[`y; .z.m.gg.scale.limits[0 0N] .z.m.gg.scale.linear]
//                      // Requires a 2D bin transform rather than a 1D
//         , .z.m.qp.s.stat[ .z.m.gg.stat.bin2d[`x`c1; ::; ::; .z.m.st.a.count[]; ::] ]
//         , .z.m.qp.s.geom[``position!(::; `dodge)]
//         , .z.m.qp.s.aes[`group`fill; `c1`c1]
//         , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat `pubugn]
//
// @example Change from a stack to a dodge with a blue scale
//     .z.m.qp.histogram[t; `x]
//         .z.m.qp.s.scale[`y; .z.m.gg.scale.limits[0 0N] .z.m.gg.scale.linear]
//         , .z.m.qp.s.stat[ .z.m.gg.stat.bin2d[`x`c1; ::; ::; .z.m.st.a.count[]; ::] ]
//         , .z.m.qp.s.geom[``position!(::; `stack)]  // <- changed to stack
//         , .z.m.qp.s.aes[`group`fill; `c1`c1]
//         , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat `pubugn]
//
// @example Stack with an binned line of another continuous column using 100 bins
//     .z.m.qp.stack (
//         .z.m.qp.histogram[t; `x]
//             .z.m.qp.s.scale[`y; .z.m.gg.scale.limits[0 0N] .z.m.gg.scale.linear]
//             , .z.m.qp.s.stat[ .z.m.gg.stat.bin2d[`x`c1; (`c;100;0); ::; .z.m.st.a.count[]; ::] ]
//             , .z.m.qp.s.binx[`c;100;0]
//             , .z.m.qp.s.geom[``position`gap!(::;`stack;0)]
//             , .z.m.qp.s.aes[`group`fill; `c1`c1]
//             , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat `bugn];
//         .z.m.qp.path[t;  `y; `count__]
//             .z.m.qp.s.stat[ .z.m.gg.stat.bin1d[`y; (`c;100;0); .z.m.st.a.count[]; ::] ] 
//             , .z.m.qp.s.geom[``fill`size!(::; 0xcd0000;1.5)])
.z.m.qp.histogram:{[table; x; settings]
    : i.ahistogram[.z.m.gg.geom.vbar; `x; table; x; settings];
    }

// @private
.z.m.qp.histogram2:{[table; x; y; s]
    
    : i.ahistogram[.z.m.gg.geom.vbar; `x; table; x; s];
    }


.z.m.qp.hline:{[y; settings] i.sline[`y; y; settings] }

// @subcategory Layouts
// @fileOverview
// Layout independent specifications horizontally with the same weighting
// @param speclist {table[]} list of specifications to layout
// @format .z.m.qp.i.qdformatter
// @see qp.layout
//
// @example Load data and horizontal layout
//     t : ([] date: til 1000; 
//             start: sums?[1000?1.<0.5;-1;1]; 
//             end: sums?[1000?1.<0.5;-1;1];
//             volume: 10+1000?10; 
//             sym: 1000?10?`5);
// 
//    .z.m.qp.horizontal (
//        .z.m.qp.ribbon[t; `date; `start; `end; ::];
//        .z.m.qp.histogram[t; `sym; ::])
.z.m.qp.horizontal:{[speclist]
    : .z.m.qp.layout[`hori; ::] speclist;
    }


.z.m.qp.i.aboxplot:{[geomFs; xOrY; compAes; catNum; table; xs; ys; settings]
    x: first xs;
    y: first ys;
    
    settings : i.initSettings settings;
    
    aes : i.resolveMulti[`aes; settings] i.describe[`aes; i.AES,`x`y]
                (::; ::; ::; ::; ::; ::; ::; ::; ::; xs; ys);
    
    geom        : i.resolveWDefault[()!(); `geom; settings];
    boxsettings : ``strokewidth!(::;1);
    box         : .z.m.gg.h.extend[geom] boxsettings;
    gpoint      : .z.m.gg.h.extend[geom] `colour`alpha!(.z.m.gg.colour.Gray;0x00);
    gerrorbar   : ``strokewidth!(::;1);
    legends     : i.resolveLegends settings;
        
    summaryI  : {[catNum; xOrY; gg; node; l]
        l[`stat]: .z.m.gg.stat.summary[l[`aes] $[`x~xOrY;`x;`y]; catNum 1];
        : l;
        }[catNum; xOrY];
    
    boxI : {[geomF; box; catNum; xOrY; gg; node; l] 
        th   : .z.m.gg.spec.theme[node; .z.m.gg.ty.spec gg];
        hsls : (.z.m.gg.colour.hsl -3#.z.m.gg.colour.qualify@) each th`marker_default_fill`plot_background_fill;
        op   : $[50 > hsls[1;2]; +; -];
        
        fill : .z.m.gg.colour.rgbFromHSL hsls[0;0 1] , op[;30] hsls[1;2];
        
        l[`geom]: geomF (``fill`colour!(::;fill;th`marker_default_fill)) , box;
        l[`stat]: .z.m.gg.stat.summary[l[`aes] $[`x~xOrY;`x;`y]; catNum 1];
        : l;
        }[geomFs 0; box; catNum; xOrY];
    
    medianI: {[geomF; box; catNum; xOrY; gg; node; l] 
        th: .z.m.gg.spec.theme[node; .z.m.gg.ty.spec gg];
        l[`stat]: .z.m.gg.stat.summary[l[`aes] $[`x~xOrY;`x;`y]; catNum 1];
        l[`geom]: geomF (``colour!(::;th`marker_default_fill)) , box;
        : l;
        }[geomFs 0; box; catNum; xOrY];

    outliersI  : {[catNum; xOrY; gg; node; l]
        l[`stat]: .z.m.gg.stat.outliers[l[`aes] $[`x~xOrY;`x;`y]; catNum 1];
        : l;
        }[catNum; xOrY];
            
    depid      : first 1?`8;
    primary    : i.resolveWDefault[depid; `primaryid; settings];
    
    labels     : i.resolveLabels[settings] i.describe[`labels; enlist`labels; enlist enlist[$[`x~xOrY;`y;`x]]!enlist $[`x~xOrY; y; x]];
    onclick    : i.resolveWDefault[::; `onclick; settings];
    ondrilldown: i.resolveWDefault[::; `ondrilldown; settings];
    th         : i.resolveWDefault[()!(); `theme; settings];
    share      : i.resolveMulti[`share;settings] i.describe[`share; i.SCALES] count[i.SCALES]#(::);
    
    base   : i.boxplotBaseLayer[table; settings];
    layers : ( // hinge segments
              .z.m.gg.spec.single .z.m.gg.layer.new base , `primaryid`secondaryid`initF`geom`aes`legends`onclick`ondrilldown`share!
                    (::; primary; summaryI; geomFs[1]gerrorbar;  compAes 0; legends; onclick; ondrilldown; share);
              .z.m.gg.spec.single .z.m.gg.layer.new base , `primaryid`secondaryid`initF`geom`aes!(primary; ::; boxI; geomFs[0]box; compAes 1);
              .z.m.gg.spec.single .z.m.gg.layer.new base , `primaryid`secondaryid`initF`geom`aes!(::; primary; medianI; geomFs[0]box; compAes 2);
              .z.m.gg.spec.single .z.m.gg.layer.new base , `primaryid`secondaryid`initF`geom`aes!(::; primary; outliersI; .z.m.gg.geom.point gpoint; aes));

    : .z.m.gg.spec.with.theme[i.cleanLabels labels]
        .z.m.gg.spec.with.theme[th]
            .z.m.gg.spec.stack[;::]
                layers;
    
    }

// @fileOverview 
// Abstract charts from a basic geometry. Allows the creation of any visual
// using a geometry than can be specified by any aes.
// @param geomF {fn} geometry constructor 
// @param table {table} data to be visualized 
// @param x {symbol} main x axis column
// @param y {symbol} main y axis column
// @param aes {symbol[]} aes specifying geom locations
// @param cs {symbol[]} default columns for aes
// @param settings {dict | null} settings for the visual (geom/bins/etc)
// @returns {table} specification tree
.z.m.qp.i.ageom:{[geomF; table; x; y; aes; cs; settings]
    
    settings : i.initSettings settings;
    
    aes : i.resolveMulti[`aes; settings] i.describe[`aes; i.AES,aes]
                (::; ::; ::; ::; ::; ::; ::; ::; ::) , cs;
    
    scales : i.resolveMulti[`scales; settings] i.describe[`scales; i.SCALES]
                 (::; ::; ::; ::; ::; ::);
    
    aes : i.filterAes[aes; scales];
    
    th         : i.resolveWDefault[()!(); `theme; settings];
    legends    : i.resolveLegends settings;
    labels     : i.resolveLabels[settings] i.describe[`labels; enlist`labels; enlist ()!()];
    
    g     : i.resolveWDefault[()!(); `geom; settings];
    stats : i.resolveWDefault[::; `stat; settings];
    
    coord      : i.resolveWDefault[.z.m.gg.coords.rect; `coord; settings];
    primary    : i.resolveWDefault[::; `primaryid; settings];
    secondary  : i.resolveWDefault[::; `secondaryid; settings];
    linkid     : i.resolveWDefault[::; `linkid; settings];
    onclick    : i.resolveWDefault[::; `onclick; settings];
    ondrilldown: i.resolveWDefault[::; `ondrilldown; settings];
    share      : i.resolveWDefault[::; `share; settings];
    init       : i.resolveWDefault[{z}; `init; settings];
    zoom       : i.resolveWDefault[::; `zoomF; settings];
    share      : i.resolveMulti[`share;settings] i.describe[`share; i.SCALES] count[i.SCALES]#(::);
    
    layer : `stat`data`geom`aes`coord`scales`linkid`primaryid`secondaryid`legends`onclick`ondrilldown`initF`share`zoomF!(
            stats; table; geomF g; aes; coord; scales; linkid; primary; secondary; legends; onclick; ondrilldown; init; share; zoom);

    : .z.m.gg.spec.with.theme[i.cleanLabels labels]
        .z.m.gg.spec.with.theme[th]
            .z.m.gg.spec.single .z.m.gg.layer.new layer;
    
    }

// @fileOverview 
// Abstract hisogram description. Allows creation of horizontal or vertical
// histograms.
// @param geomF {fn} geometry constructor 
// @param xOrY {symbol} axis used for column - `x or `y 
// @param table {table} data to be visualized 
// @param xs {symbol} column 
// @param settings {dict | null} settings for the visual (geom/bins/etc)
// @returns {table} specification tree
.z.m.qp.i.ahistogram:{[geomF; xOrY; table; xs; settings]
    x:first xs;
    settings : i.initSettings settings;
    
    norm   : i.resolveItem[settings; `norm] i.describe[`norm; enlist`norm; enlist (::)];
    defAggr : $[(::)~norm;`count__; `norm__];
    
    aes : i.resolveMulti[`aes; settings] i.describe[`aes; i.AES,`x`y]
                (::; ::; ::; ::; ::; ::; ::; ::; ::; $[xOrY ~ `x; xs; defAggr]; $[xOrY ~ `y; xs; defAggr]);
    
    scales : i.resolveMulti[`scales; settings] i.describe[`scales; i.SCALES]
                 (::; ::; ::; ::; ::; ::);
    
    aes : i.filterAes[aes; scales];
    
    initF : {[settings; scales; geomF; xOrY; x; gg; node; lyr]
        table  : lyr`data;
        aes    : lyr`aes;
        
        binSetting: i.resolveWDefault[::; $[xOrY ~ `x; `binx; `biny]; settings];
        aggr   : i.resolveItem[settings; `aggr] i.describe[`aggr; enlist`aggr; enlist .z.m.st.a.count[]];
        geom   : .z.m.gg.h.extend[enlist[`]!enlist (::)] i.resolveWDefault[()!(); `geom; settings];
        x      : first aes xOrY;
        
        defaultBin   : (::) ~ binSetting;
        defaultScale : (() ~ scales xOrY) | .z.m.gg.h.and[scales xOrY; 99h=type@; {`default ~ x`label}];
        defaultStat  : not `stat in key settings;
        
        $[defaultBin & defaultScale & defaultStat & .z.m.st.usePartitionedBins[table; x];
            stat: enlist[`transform]!enlist .z.m.gg.stat.bin1d[x; ::; aggr; ::];
       
            [
                scales : last[.z.m.gg.layer.i.addMissingScales[::;lyr;enlist xOrY;`data]]`scales;
                .z.m.gg.scale.validate[scales xOrY] xdomain : .z.m.gg.tbl.column[table; x];
                scalei : .z.m.gg.scale.init [scales xOrY] xdomain;
                norm   : i.resolveItem [settings; `norm] i.describe[`norm; enlist`norm; enlist (::)];
                bins   : i.resolveBin  [settings; table; x; scalei; $[xOrY ~ `x; `binx; `biny]];
                
                stat : i.resolveStat[settings] i.describe[`stat; `transform`bins`aggr]
                             (.z.m.gg.stat.sbinNd_i[enlist x; enlist { $[`by ~ x 0; `by; x] } bins; enlist scalei; aggr; ``norm!(::;norm)]; enlist bins; aggr);
                
                binsi : .z.m.st.bins [table; enlist x; enlist bins; enlist scalei];
                
                if [not `by ~ binsi[`kind]0;
                    if [not `categorical ~ scalei`label; geom[`align]: $[geomF ~ .z.m.gg.geom.vbar; `left; `bottom]];
                    geom[`size]: min 0W,1^binsi[`width] 0]]];
        
        : .z.m.gg.h.extend[`stat`geom!(stat`transform; geomF geom)] lyr;

        }[settings; scales; geomF; xOrY; x];
    
    th         : i.resolveWDefault[()!(); `theme; settings];
    labels     : i.resolveLabels[settings] i.describe[`labels; enlist`labels; enlist ()!()];
    
    coord      : i.resolveWDefault[.z.m.gg.coords.rect; `coord; settings];
    primary    : i.resolveWDefault[::; `primaryid; settings];
    secondary  : i.resolveWDefault[::; `secondaryid; settings];
    linkid     : i.resolveWDefault[::; `linkid; settings];
    onclick    : i.resolveWDefault[::; `onclick; settings];
    ondrilldown: i.resolveWDefault[::; `ondrilldown; settings];
    share      : i.resolveMulti[`share;settings] i.describe[`share; i.SCALES] count[i.SCALES]#(::);
    legends    : i.resolveLegends settings;
    
    : .z.m.gg.spec.with.theme[i.cleanLabels labels]
        .z.m.gg.spec.with.theme[th]
            .z.m.gg.spec.single .z.m.gg.layer.new `initF`data`aes`coord`scales`linkid`primaryid`secondaryid`legends`onclick`ondrilldown`share`zoomF!(
                initF; table; aes; coord; scales; linkid; primary; secondary; legends; onclick; ondrilldown; share; 1b);
    }

// @fileOverview 
// Abstract "point" chart. Allows the creation of any visual
// using a geometry than can be specified by an x and y location.
// @param geomF {fn} geometry constructor 
// @param table {table} data to be visualized 
// @param x {symbol} column 
// @param y {symbol} column
// @param settings {dict | null} settings for the visual (geom/bins/etc)
// @returns {table} specification tree
.z.m.qp.i.apoint:{[geomF; table; x; y; settings]
    : i.ageom[geomF; table; x; y; `x`y; (x;y); settings];
    }

// @fileOverview Return the base layer for a boxplot, to extend with each component customization
// @param table {table} 
// @param settings {dict} 
// @returns {dict}
.z.m.qp.i.boxplotBaseLayer:{[table; settings]
    coord  : i.resolveWDefault[.z.m.gg.coords.rect; `coord; settings];
    scales : i.resolveMulti[`scales; settings] i.describe[`scales; i.SCALES] (::; ::; ::; ::; ::; ::);
    linkid : i.resolveWDefault[::; `linkid; settings];
    
    : `coord`scales`linkid`data`zoomF!(coord; scales; linkid; table; 1b);    
    }

.z.m.qp.i.cleanLabels:{[labels]
    : $[0 = count labels`labels; ()!(); labels];
    }

// @fileOverview
// Simple dictionary for wrapping and composing default options
// @param item {symbol} name for the default option 
// @param ks {symbol[]} names for the default option parts 
// @param settings {any[]} values for the default option parts
// @returns {dict}
.z.m.qp.i.describe:{[item; ks; settings]
    : enlist[item]!enlist enlist ks!flip enlist[`default]!enlist settings
    }

// @fileOverview Create a tightly packed matrix layout where axes are only 
// enabled on the bottom and left charts
// @param grid {long[]} dimensions of the grid 
// @param speclist {table[]} list of gg specs
// @returns {table} A single gg spec
.z.m.qp.i.facetGrid:{[grid; speclist]
    speclist: {[m0;m1;d;c]
        if [0  <> d 1; c: .z.m.qp.theme[``axis_use_y!(::;0b)] c];
        if [m1 <> d 0; c: .z.m.qp.theme[``axis_use_x!(::;0b)] c];
        if [0  <> d 1; c: .z.m.qp.theme[    ``padding_left`plot_margin_left!(::;0;0)] c];
        if [m1 <> d 1; c: .z.m.qp.theme[  ``padding_right`plot_margin_right!(::;0;0)] c];
        if [0  <> d 0; c: .z.m.qp.theme[      ``padding_top`plot_margin_top!(::;0;0)] c];
        if [m0 <> d 0; c: .z.m.qp.theme[``padding_bottom`plot_margin_bottom!(::;0;0)] c];
        : c
        }'[max til grid 0; max til grid 1; til[grid 0] cross til grid 1; speclist];
    
    : .z.m.qp.theme[``dynamic_axes!(::;0b)] .z.m.qp.layout[`facetGrid; grid] speclist;
    }
.z.m.qp.i.filterAes:{[aes; scales]
    if [(`alpha in key aes) and .z.m.gg.h.null scales`alpha;   aes _: `alpha];
    if [(`fill in key aes)  and .z.m.gg.h.null scales`fill;    aes _: `fill];
    : aes
    }

// @fileOverview Fit text to given widths, truncating text that doesn't fit
// @param widths {long[]} 
// @param fontsizes {long[]} 
// @param text {string[]} 
// @returns {string[]} Potentially truncated text
.z.m.qp.i.fitText:{[widths; fontsizes; text]
    : {[w;s;t]
        
        ii: 1;
        r: t;
        while [ii < count t;
            if [w > first .z.m.gg.h.textWidth[s;enlist r]; : r];
            r: (neg[ii]_t),"..";
            ii +: 1];
        : $[ii = count t; ""; r];
        
        }'[widths; fontsizes; text];
    }

// @fileOverview 
// Turn a settings specification into a dictionary
// @param s {dict|null} 
// @returns {dict}
.z.m.qp.i.initSettings:{[s]
    : $[99h ~ type s; s; ()!()]
    }

// @qlintsuppress UNUSED_INTERNAL(1)
.z.m.qp.i.qdformatter:{[r]
    : .qd.format.imageTag
            .qd.format.base64
            .[;`output`bytes]
            .z.m.gg.display[500;500]
            .z.m.gg.new
            .z.m.qp.theme[.z.m.gg.theme.clean , ``marker_default_fill!(::; 0x222222)]
            r
    }

// @fileOverview 
// Given custom settings, and scales, determine the bin counts
// for a binned visual.
// @param settings {dict} 
// @param table {table} 
// @param x {symbol} column 
// @param xscale {dict} scale dictionary for x 
// @param flag {symbol} 
// @returns {(symbol;number)[]} width/count and argument pairs for x and y bins
.z.m.qp.i.resolveBin:{[settings; table; x; xscale; flag]
    toResolve: i.resolveWDefault[::; flag; settings];
    if [toResolve ~ (); : (`by;1;0)];
    : .z.m.st.resolveBins[table; toResolve; x; xscale];
    }

// @fileOverview 
// Given custom settings, and scales, determine the bin counts
// for a binned visual.
// @param settings {dict} 
// @param table {table} 
// @param x {symbol} column 
// @param y {symbol} column 
// @param xscale {dict} scale dictionary for x 
// @param yscale {dict} scale dictionary for y
// @returns {(symbol;number)[]} width/count and argument pairs for x and y bins
.z.m.qp.i.resolveBins:{[settings; table; x; y; xscale; yscale]
    
    xres : .z.m.st.resolveBins[table; i.resolveWDefault[::; `binx; settings]; x; xscale];
    yres : .z.m.st.resolveBins[table; i.resolveWDefault[::; `biny; settings]; y; yscale];
    
    : $[x ~ y;
        (xres; xres);
        (xres; yres)];
    }

.z.m.qp.i.resolveItem:{[settings; k; descr]
    : i.resolveWDefault[raze[descr k][k] `default; k; settings];
    }

// @fileOverview 
// Given a dictionary of settings and preferred defaults, determine
// the labels to apply to a visual (x/y/legends/etc)
// @param settings {dict} 
// @param descr {dict}
// @returns {dict}
.z.m.qp.i.resolveLabels:{[settings; descr]
    : enlist[`labels]!enlist i.resolveItem[settings; `labels; descr];
    }

.z.m.qp.i.resolveLegends:{[settings]
    ks: k where string[k:key settings] like "legend*";
    if [0 = count ks; : ()];
    titles: count["legend"] _/: string ks;
    : `title`ticks!/:flip (titles; @[;`get] settings@/:ks);
    }

// @fileOverview 
// Given a dictionary of custom settings and preferred defaults, determine
// the given setting for a visual
// @param name {symbol} the settings key to check
// @param settings {dict} 
// @param descr {dict}
// @returns {dict}
.z.m.qp.i.resolveMulti:{[name; settings; descr]
    ks: cols descr name;
    : i.stripNulls ks!{[name; descr; settings; k]
        : i.resolveWDefault[raze[descr name][k]`default; `$string[name],string k;  settings]; /dnl
        }[name; descr; settings] each ks;
    }
// @fileOverview 
// Given a dictionary of custom settings and preferred defaults, determine
// the statistical transform settings for a visual
// @param settings {dict} 
// @param descr {dict}
// @returns {dict}
.z.m.qp.i.resolveStat:{[settings; descr]
    : i.stripNulls `transform`bins`aggr!(
        i.resolveWDefault[raze[descr`stat][`transform]`default; `stat;  settings];
        i.resolveWDefault[raze[descr`stat][`bins]`default;      `;      settings];
        i.resolveWDefault[raze[descr`stat][`aggr]`default;      `aggr;  settings]);
    
    }

// @fileOverview 
// If an item is in the settings, use it, otherwise, use the default
// @param default {dict} 
// @param item {symbol} the setting name 
// @param settings {dict}
// @returns {any}
.z.m.qp.i.resolveWDefault:{[default; item; settings]
    : $[not item in key settings; default; settings[item] `get]
    }

// @fileOverview 
// Unless a scale has been specified, use whatever scale matches the type of the column
// @param item {symbol} scale name 
// @param settings {dict} 
// @param t {table} 
// @param x {symbol} column
// @returns {dict} scale
.z.m.qp.i.scale:{[item; settings; t; x]
    : i.resolveWDefault[.z.m.gg.scale.fromMeta[0b] .z.m.gg.tbl.metatype[t;x]; item; settings]
    }

.z.m.qp.i.sline:{[xOrY; s; settings]
    
    table    : flip enlist[xOrY]!enlist enlist s;
    settings : i.initSettings settings;
    aes      : i.resolveMulti[`aes; settings] i.describe[`aes; i.AES,xOrY]
                    (::; ::; ::; ::; ::; ::; ::; ::; ::) , xOrY;
    scales   : i.resolveMulti[`scales; settings] i.describe[`scales; i.SCALES]
                     (::; ::; ::; ::; ::; ::);
    
    aes : i.filterAes[aes; scales];
    
    geometry   : $[`x ~ xOrY; .z.m.gg.geom.vline; .z.m.gg.geom.hline];
    th         : i.resolveWDefault[()!(); `theme; settings];
    labels     : i.resolveLabels[settings] i.describe[`labels; enlist`labels; enlist ()!()];
    geom       : i.resolveWDefault[()!(); `geom; settings];
    coord      : i.resolveWDefault[.z.m.gg.coords.rect; `coord; settings];
    share      : i.resolveMulti[`share;settings] i.describe[`share; i.SCALES] count[i.SCALES]#(::);
    legends    : i.resolveLegends settings;
    layer      : `data`geom`aes`coord`scales`legends`share!(table; geometry geom; aes; coord; scales; legends; share);
    legends    : i.resolveLegends settings;
    : .z.m.gg.spec.with.theme[i.cleanLabels labels]
        .z.m.gg.spec.with.theme[th]
            .z.m.gg.spec.single .z.m.gg.layer.new layer;
    
    }

// @fileOverview
// Strip all null-valued entries from a dictionary
// @param d {dict} 
.z.m.qp.i.stripNulls:{[d]
    : ks!d ks:key[d] where not .z.m.gg.h.null each value d
    }

// @fileOverview 
// Transforms a theme for 2D plots into one suitable for 3D plots
// @param theme {dict} theme dictionary
// @returns {dict} theme for 3D plots
.z.m.qp.i.theme3D:{[theme]
    : ((!) . flip (
        (`axis_tick_length_x;0.04);
        (`axis_tick_length_y;0.04);
        (`axis_tick_length_z;0.04);
        (`axis_tick_label_start_x;0.08);
        (`axis_tick_label_start_y;0.08);
        (`axis_tick_label_start_z;0.08);
        (`axis_tick_label_anchor_x;`right);
        (`axis_tick_label_anchor_y;`left);
        (`axis_tick_label_anchor_z;`right);
        (`axis_tick_label_italic_z;0b);
        (`axis_tick_label_bold_z;0b);
        (`axis_tick_label_angle_z;0);
        (`grid_style_x;`lines);
        (`grid_style_y;`lines);
        (`grid_style_z;`lines);
        (`canvas_fill; 0xffffffff)
        )),theme;
    }

// @private
// @subcategory Rendering
// @fileOverview 
// Push an initial scenegraph to the browser
// @param gg {dict} a pre-rendered GG 
// @returns {null}
.z.m.qp.initScene:{[gg]
    .z.m.gg.z.m.ax.initScene gg;
    }

        

.z.m.qp.interval:{[table; x; y; yend; settings]
    : i.ageom[.z.m.gg.geom.vinterval; table; x; y; `x`y`yend; (x;y;yend); settings];
    }
// @subcategory Layouts
// @fileOverview
// Layout independent specifications horizontally, vertically, etc
//
// Vertical and horizontal weighted layouts support both fixed-width and canvas percentages. 
//
// @param typ {symbol} one of `` `vert`hori`vert_w`hori_w`vert_p`hori_p`square ``
// @param arg {null | long[]} argument to the layout (used as weights for `` `vert_w `` and `` `hori_w ``)
// @param speclist {table[]} list of specifications to layout
// @format .z.m.qp.i.qdformatter
//
// @example Load data and horizontal layout
//     t : ([] date: til 1000; 
//             start: sums?[1000?1.<0.5;-1;1]; 
//             end: sums?[1000?1.<0.5;-1;1];
//             volume: 10+1000?10; 
//             sym: 1000?10?`5);
// 
//    .z.m.qp.layout[`hori; ::] (
//        .z.m.qp.ribbon[t; `date; `start; `end; ::];
//        .z.m.qp.histogram[t; `sym; ::])
//
// @example Vertical layout
//    .z.m.qp.layout[`vert; ::] (
//        .z.m.qp.ribbon[t; `date; `start; `end; ::];
//        .z.m.qp.histogram[t; `sym; ::])
//
// @example Horizontal weighted layout
//    .z.m.qp.layout[`hori_w; 2 1] (
//        .z.m.qp.ribbon[t; `date; `start; `end; ::];
//        .z.m.qp.histogram[t; `sym; ::])
//
// @example Horizontal weighted layout with pixels
//    .z.m.qp.layout[`hori_p; 150 0N] (
//        .z.m.qp.ribbon[t; `date; `start; `end; ::];
//        .z.m.qp.histogram[t; `sym; ::])
//
// @example Vertical weighted layout
//    .z.m.qp.layout[`vert_w; 2 1] (
//        .z.m.qp.ribbon[t; `date; `start; `end; ::];
//        .z.m.qp.histogram[t; `sym; ::])
//
// @example Vertical weighted layout with pixels
//    .z.m.qp.layout[`vert_p; 150 0N] (
//        .z.m.qp.ribbon[t; `date; `start; `end; ::];
//        .z.m.qp.histogram[t; `sym; ::])
//
// @example Square layout
//    .z.m.qp.layout[`square; ::] 
//        {.z.m.qp.point[([]x:til 5; y:5?5); `x; `y; ::]} each til 5
//
// @example Nested layouts
//     .z.m.qp.layout[`vert; ::] (
//         .z.m.qp.point[t; `start; `end; ::];
//         .z.m.qp.layout[`hori; ::] (
//             .z.m.qp.ribbon[t; `date; `start; `end; ::];
//             .z.m.qp.histogram[t; `sym; ::]))
// 
// @example Add some titles
//     .z.m.qp.layout[`vert; ::] (
//         .z.m.qp.title["Point plot"]
//             .z.m.qp.point[t; `start; `end; ::];
//         .z.m.qp.layout[`hori; ::] (
//             .z.m.qp.title["Ribbon plot"]
//                 .z.m.qp.ribbon[t; `date; `start; `end; ::];
//             .z.m.qp.title["Histogram"]
//                 .z.m.qp.histogram[t; `sym; ::]))
.z.m.qp.layout:{[typ; arg; speclist]
    l: $[`vert ~ typ; .z.m.gg.spec.vert;
         `grid ~ typ; .z.m.gg.spec.grid arg;
         `facetGrid ~ typ; .z.m.gg.spec.facetGrid arg;
         `fillGrid ~ typ; .z.m.gg.spec.i.addlayout[`fillGrid; arg];
         `hori ~ typ; .z.m.gg.spec.hori;
         `square ~ typ; .z.m.gg.spec.square;
         `vert_w ~ typ; .z.m.gg.spec.vert_w arg;
         `hori_w ~ typ; .z.m.gg.spec.hori_w arg;
         `vert_p ~ typ; .z.m.gg.spec.vert_p arg;
         `hori_p ~ typ; .z.m.gg.spec.hori_p arg;
            .z.m.gg.spec.square];
    : l speclist;
    }

// @subcategory Geometries
// @fileOverview 
// Line chart - draw a line from the left to the right (in the order of the domain).
//
// - X - position along the X axis
// - Y - position along the Y axis
//
// Aesthetic mappings ( .z.M.qp.s.aes`, dynamic) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `size `` - Line size
// - `` `group `` - Grouping (break lines in categories based on this label)
//
// Geometry settings ( .z.M.qp.s.geom`, static) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `size `` - Line size
// - `` `dashed `` - Solid or dashed line
// - `` `decorations `` - Add or remove points from the line (default: false)
//
// @param table {table} data to be visualized
// @param x {symbol} column name 
// @param y {symbol} column name 
// @param settings {dict | null}  settings for the visual (geom/bins/etc)
// @returns {table} specification table for a line chart
// @see qp.path
// @format .z.m.qp.i.qdformatter
//
// @example Load data and basic chart
//     t : raze { 
//         ([] date: .z.d + til 800; 
//             price: sums?[800?1.<0.5;-1;1];
//             sym: x) 
//     } each `a`b`c;
//
//     .z.m.qp.line[select med price by date.month from t; `month; `price; ::]
//
// @example Change fill colour and add points
//
//     .z.m.qp.line[select med price by date.month from t; `month; `price]
//         .z.m.qp.s.geom[``fill`decorations!(::; 0x0070cd; 1b)]
//
// @example Group lines by symbol
//     .z.m.qp.line[select med price by date.month, sym from t; `month; `price]
//           .z.m.qp.s.geom[``decorations!(::; 1b)]
//         , .z.m.qp.s.aes[`group`fill; `sym`sym]
//
// @example Increase granularity and group
//     .z.m.qp.line[t; `date; `price]
//           .z.m.qp.s.geom[``fill!(::; 0x0070cd)]
//         , .z.m.qp.s.aes[`group`fill; `sym`sym]
//
// @example Draw a moving average over a line
//     .z.m.qp.stack (
//         .z.m.qp.line[select from t where sym = `a; `date; `price]
//             .z.m.qp.s.geom[``fill`alpha!(::; 0x0070cd; 0x9f)];
//         .z.m.qp.line[update price: 30  mavg price from select from t where sym = `a; `date; `price]
//             .z.m.qp.s.geom[``fill`size!(::; 0xcd3000; 1.5)];
//         .z.m.qp.line[update price: 100 mavg price from select from t where sym = `a; `date; `price]
//             .z.m.qp.s.geom[``size!(::; 1.5)])
//
.z.m.qp.line:{[table; x; y; settings]
    : i.apoint[.z.m.gg.geom.line; table; x; y; settings];
    }

// @private
// @subcategory Rendering
// @fileOverview
// Creates a WebGL render context of the given height and width, and 
// renders the scenegraph created by compiling the GG spec
// @param w {long} width in pixels
// @param h {long} height in pixels
// @param spec {table} a GG specification (for example, `` .z.m.qp.point[t; `x; `y; ::] ``)
// @returns {null}
//
// @example
// .z.m.qp.live[500;500] 
//     .z.m.qp.theme[``canvas_fill!(::;0xffffffff)] 
//     .z.m.qp.point[([] x: til 5;y: til 5);`x;`y;::];
.z.m.qp.live:{[w; h; spec]
    : .z.m.qp.initScene .z.m.gg.displayUsing[.z.m.gg.scenegraphw; w; h; .z.m.gg.new spec];
    }

// @subcategory Rendering
// @fileOverview
// Render a visual specification at the given width and height, and send the 
// visual to the Analyst IDE
// @param id {symbol} id of the managed plot
// @param w {long} width in pixels
// @param h {long} height in pixels
// @param spec {table} a GG specification (for example, `` .z.m.qp.point[t; `x; `y; ::] ``)
// @returns {null}
//
// @example
// .z.m.qp.managed[`name;500;500] .z.m.qp.point[([]x:til 45); `x; `x; ::]
.z.m.qp.managed:{[id; w; h; spec]
    : .z.m.qp.push @[;`appID;:;id] .z.m.gg.display[w; h; .z.m.gg.new spec];
    }


.z.m.qp.matrix:{[x]
    w: count x 0;
    h: count x;
    x: raze x;
    : .z.m.qp.tile[([]column:til[count x]mod w;row:raze w#'til h;val:raze x);`column;`row]
              .z.m.qp.s.aes[`fill;`val]
            , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.gradient[.z.m.gg.colour.SteelBlue; .z.m.gg.colour.FireBrick]]
    }


.z.m.qp.path:{[table; x; y; settings]
    : i.apoint[.z.m.gg.geom.path; table; x; y; settings];
    }

// @subcategory Geometries
// @fileOverview 
// Create a plot of the indicated columns from a table.
//
// Creates a best-guess plot based on the types of the columns.
// If more than two columns are specified, a plot of pairs of all columns will be created.
//
// Only the lower triangle of pairs will be plotted (this covers all relationships). The
// upper triangle will display the correlation of each continuous pair. If either pair
// is categorical, the correlation will be empty for that pair. See the examples below.
//
// @param table {table} data to be visualized
// @param cs {symbol[]} list of columns to be visualized 
// @param settings {null | dict} settings for the visual (geom/etc)
// @returns {table} specification table
// @format .z.m.qp.i.qdformatter
//
// @example A single column - histogram
// t: ([]
//     num1:  .z.m.st.gen.normal 1000; 
//     num2:  {sin acos[-1] * x % max x} .z.m.st.gen.normal 1000; 
//     num3:  {cos acos[-1] * x % max x} .z.m.st.gen.normal 1000; 
//     cat1:  1000?5?`5;
//     cat2:  1000?5?`5);
//
// .z.m.qp.plot[t; `num1; ::]
//
// @example Two columns - scatter, boxplot, or heatmap
// .z.m.qp.plot[t; `num1`num2; ::]
//
// @example Three columns - a grid of relationships
// .z.m.qp.plot[t; `num1`num2`cat1; ::]
//
// @example All columns
// .z.m.qp.plot[t; (); ::]
//
// @example Change fill colour
// .z.m.qp.plot[t; ()]
//     .z.m.qp.s.geom[``fill!(::;0x0070cd)]
.z.m.qp.plot:{[table; cs; settings]
    
    if [not[.z.m.gg.tbl.ty.is table] and not 98h ~ type table; '.z.m.axlocalize.t`.qp_tableArgumentError];
    if [not (()~cs) or (11h ~ type cs) or -11h ~ type cs;  '.z.m.axlocalize.t`.qp_columnListArgumentError];
    
    if [0 = count cs;
        : .z.m.qp.smalls[table; .z.m.gg.tbl.colnames table; settings]];
    
    if [2 < count cs;
        : .z.m.qp.smalls[table; cs; settings]];

    if [1 = count cs;
        : .z.m.qp.histogram[table; cs; settings]];
     
    x : @[;`label] i.scale[`xscale; ()!(); table; first cs];
    y : @[;`label] i.scale[`yscale; ()!(); table; cs 1];
    
    under: 10000 > .z.m.gg.tbl.nrecords table;
    base : $[under; scatter; heatmap];
    
    : $[ (x ~ `linear)      and y ~ `linear;       base     [table;cs 0; cs 1; settings];
         (x ~ `linear)      and y ~ `linear;       base     [table;cs 0; cs 1; settings];
         (x ~ `temporal)    and y ~ `linear;       base     [table;cs 0; cs 1; settings];
         (x ~ `linear)      and y ~ `temporal;     base     [table;cs 0; cs 1; settings];
         (x ~ `temporal)    and y ~ `temporal;     base     [table;cs 0; cs 1; settings];
         (x ~ `temporal)    and y ~ `categorical;  base     [table;cs 0; cs 1; settings];
         (x ~ `categorical) and y ~ `temporal;     base     [table;cs 0; cs 1; settings];
         (x ~ `categorical) and y ~ `linear;       $[under; boxplot;  heatmap][table;cs 0; cs 1; settings];
         (x ~ `linear)      and y ~ `categorical;  $[under; hboxplot; heatmap][table;cs 0; cs 1; settings];
         (x ~ `categorical) and y ~ `categorical;  heatmap  [table;cs 0; cs 1; settings];
        '.z.m.axlocalize.t`.qp_noDefaultError];
    
    }

// @subcategory Rendering
// @fileOverview Save a GG specification as a png
// @param filename {symbol} Symbolic file handle to PNG output location 
// @param w {long} width 
// @param h {long} height 
// @param spec {table} gg specification 
// @example
// .z.m.qp.png[`:/output/file.png; 500; 500]
//      .z.m.qp.point[([]x:til 45); `x; `x; ::]
.z.m.qp.png:{[filename;w;h;spec]
    filename 1: {x . `output`bytes} .z.m.qp.display[w;h] spec
    }

// @subcategory Geometries
// @fileOverview 
// Scatter chart - basic point geometry.
//
// - X - position along the X axis
// - Y - position along the Y axis
//
// Aesthetic mappings ( .z.M.qp.s.aes`, dynamic) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `group `` - Grouping 
// - `` `size `` - Circle size
//
// Geometry settings ( .z.M.qp.s.geom`, static) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `size `` - Circle size
// - `` `shape `` - One of `` `circle`square`triangle ``
// - `` `jitterx `` - Jitter x position (percent of canvas)
// - `` `jittery `` - Jitter y position (percent of canvas)
//
// @see qp.scatter
//
// @param table {table} data to be visualized
// @param x {symbol} column name 
// @param y {symbol} column name 
// @param settings {dict | null}  settings for the visual (geom/bins/etc)
// @returns {table} specification table for a scatter chart
// 
// @format .z.m.qp.i.qdformatter
//
// @example Load data and basic chart
//     t:      ([]x:10000?1.;y:10000?1.);
//     t:      update z: {.z.m.gg.proj.proj[(min x;max x);0 5000000;x]} sin[x]*sin[y] from t;
//     labels: ("0-1M";"1-2M";"2-3M";"3-4M";"4-5M");
//     t:      update fillcol: labels("f"$1000000*til 5)?1000000 xbar z from t;
//
//     .z.m.qp.point[t; `x; `y; ::]
//
// @example Add a fill colour
//
//      .z.m.qp.point[t; `x; `y]
//          .z.m.qp.s.geom[``fill!(::;`steelblue)]
//
// @example Add a fil mapping
//
//     .z.m.qp.point[t; `x; `y]
//        .z.m.qp.s.aes[`fill; `fillcol]
//      , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat `blues]
//
// @example Use stroke rather than fill
//
//     .z.m.qp.point[t; `x; `y]
//        .z.m.qp.s.aes[`colour; `fillcol]
//      , .z.m.qp.s.scale[`colour; .z.m.gg.scale.colour.cat `blues] 
//      , .z.m.qp.s.geom[`size`alpha`colour`strokewidth!(4; 0x00; `firebrick; .5)]
//
// @example Adding x and/or y jitter as percentage of canvas
//
//     t: ([]x: sums?[45?1.<0.5;-1;1]; y: sums?[45?1.<0.5;-1;1]);
//
//     .z.m.qp.point[500#([]x:0 0 1 1;y:0 1 0 1);`x;`y] 
//         .z.m.qp.s.geom[``jitterx`jittery!(::;0.1;0.3)]
//
.z.m.qp.point:{[table; x; y; settings]
    : .z.m.qp.scatter [table; x; y; settings];
    }

// @subcategory Geometries
// @fileOverview 
// 3D Scatter chart - basic 3D point geometry.
//
// - X - position along the X axis
// - Y - position along the Y axis
// - Z - position along the Z axis
//
// Aesthetic mappings ( .z.M.qp.s.aes`, dynamic) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `group `` - Grouping 
// - `` `size `` - Circle size
//
// Geometry settings ( .z.M.qp.s.geom`, static) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `size `` - Circle size
//
// The default viewing angle is an isometric view. The viewing angle can be changed by using  .z.M.qp.s.coord` to set a new `cube` coordinate system with the desired azimuth and altitude.
// @see gg.coords.cube
//
// @param table {table} data to be visualized
// @param x {symbol} column name 
// @param y {symbol} column name 
// @param z {symbol} column name 
// @param settings {dict | null}  settings for the visual (geom/bins/etc)
// @returns {table} specification table for a 3D scatter chart
// 
// @format .z.m.qp.i.qdformatter
//
// @example Load data and basic chart
//      t: ([]x: sums?[45?1.<0.5;-1;1]; y: sums?[45?1.<0.5;-1;1]; z: y: sums?[45?1.<0.5;-1;1]);
//      
//      .z.m.qp.point3D[t; `x; `y; `z; ::]
//
// @example Add a fill colour
//      .z.m.qp.point3D[t; `x; `y; `z]
//          .z.m.qp.s.geom[enlist[`fill]!enlist `steelblue]
//
// @example Change the size, opacity, and fill
//      .z.m.qp.point3D[t; `x; `y; `z]
//          .z.m.qp.s.geom[`size`alpha`colour`fill!(4; 0x20; `firebrick; `steelblue)]
//
// @example Change the viewing angle
//      .z.m.qp.point3D[t; `x; `y; `z]
//            .z.m.qp.s.geom[`size`fill!(3; `firebrick)]
//          , .z.m.qp.s.coord[.z.m.gg.coords.cube . 2#4*atan[1]%3]
//
// @example Grid in multiple views
//     s: {x*x};
//     t: 5+`x`y`z!/:ps,'{ sin[sqrt s[x]+s y] % sqrt s[x]+s y } .' ps:({x cross x} -60+til 120) % 16;
//
//     .z.m.qp.theme[``legend_use!(::;0b)]
//         .z.m.qp.grid[0N 0N] (
//             .z.m.qp.point3D[t; `x; `y; `z]
//                 .z.m.qp.s.aes   [`fill`alpha; `z`count__] ,
//                 .z.m.qp.s.geom  [``alpha`size!(::;0x7f;1)] ,
//                 .z.m.qp.s.stat  [ .z.m.gg.stat.binNd[`x`y`z; ((`c;60;0);(`c;60;0);(`c;60;0)); .z.m.st.a.count[]; ``center!(::;1b)] ];
//             .z.m.qp.point3D[t; `x; `y; `z]
//                 .z.m.qp.s.aes[`fill`alpha; `z`count__] ,
//                 .z.m.qp.s.geom  [``alpha`size!(::;0x7f;1)] ,
//                 .z.m.qp.s.coord [.z.m.gg.coords.cube[neg 1%sqrt 2; 2] ] ,
//                 .z.m.qp.s.stat  [ .z.m.gg.stat.binNd[`x`y`z; ((`c;60;0);(`c;60;0);(`c;60;0)); .z.m.st.a.count[]; ``center!(::;1b)] ];
//             .z.m.qp.point[t;`x;`y] 
//                 .z.m.qp.s.geom  [``alpha`size!(::;0x7f;1)] ,
//                 .z.m.qp.s.aes   [`fill;`z];
//             .z.m.qp.point[t;`x;`z] 
//                 .z.m.qp.s.geom  [``alpha`size!(::;0x7f;1)] ,
//                 .z.m.qp.s.aes   [`fill;`z])
//
.z.m.qp.point3D:{[table; x; y; z; settings]

    settings : i.initSettings settings;
    
    aes : i.resolveMulti[`aes;settings] i.describe[`aes; i.AES,`x`y`z]
                (::; ::; ::; ::; ::; ::; ::; ::; ::) , (x;y;z);

    scales : i.resolveMulti[`scales;settings] i.describe[`scales; i.SCALES,`z]
                 (::; ::; ::; ::; ::; ::; ::);
    
    th         : i.resolveWDefault[()!(); `theme; settings];
    legends    : i.resolveLegends settings;
    labels     : i.resolveLabels[settings] i.describe[`labels; enlist`labels; enlist ()!()];
    
    g     : i.resolveWDefault[()!(); `geom; settings];
    stats : i.resolveWDefault[::;    `stat; settings];
    
    coord      : i.resolveWDefault[.z.m.gg.coords.cube . i.angles3D; `coord; settings];
    primary    : i.resolveWDefault[::; `primaryid; settings];
    secondary  : i.resolveWDefault[::; `secondaryid; settings];
    linkid     : i.resolveWDefault[::; `linkid; settings];
    onclick    : i.resolveWDefault[::; `onclick; settings];
    share      : i.resolveMulti[`share;settings] i.describe[`share; i.SCALES,`z] count[i.SCALES,`z]#(::);
    init       : i.resolveWDefault[{z}; `init; settings];
    layer : `stat`data`geom`aes`coord`scales`linkid`primaryid`secondaryid`legends`onclick`initF`share!(
            stats; table; .z.m.gg.geom.point3D g; aes; coord; scales; linkid; primary; secondary; legends; onclick; init; share);
    
    : .z.m.gg.spec.with.theme[i.cleanLabels labels]
        .z.m.gg.spec.with.theme[i.theme3D th]
            .z.m.gg.spec.single .z.m.gg.layer.new layer;
    }


.z.m.qp.polygon:{[table; xs; ys; settings]
    settings: (
        .z.m.qp.s.scale[`x; .z.m.gg.scale.fromMeta[1b] .z.m.gg.tbl.metatype[table;first xs]] ,
        .z.m.qp.s.scale[`y; .z.m.gg.scale.fromMeta[1b] .z.m.gg.tbl.metatype[table;first ys]]
        ) , i.initSettings settings;
    : i.ageom[.z.m.gg.geom.polygon; table; xs; ys; `x`y; (xs; ys); settings];
    }

// @subcategory Rendering
// @fileOverview 
// Push a pre-rendered visual to the client
// @param gg {dict} a pre-rendered GG 
// @returns {null}
// @example
// .z.m.qp.push .z.m.gg.dsl[()!()] `:image.gg
.z.m.qp.push:{[gg]
    id : .z.m.gg.cache.new gg;
    
    .z.m.gg.ax.push[id; gg];
    }

// @subcategory Geometries
// @fileOverview 
// Create a quantile plot of a single column. Shows a distribution of values over
// a single variable.
//
// Aesthetic mappings ( .z.M.qp.s.aes`, dynamic) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `group `` - grouping (combined with `` `position `` geom settings)
//
// Geometry settings ( .z.M.qp.s.geom`, static) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `size `` - Point size
// - `` `strokewidth `` - Outline size
// @param table {table} data to be visualized
// @param x {symbol} column name
// @param settings {dict | null}  settings for the visual (geom/bins/etc)
// @returns {table} specification table 
//
// @format .z.m.qp.i.qdformatter
//
// @example Load data and basic plot
//      t : ([]x: 45?100);
//
//      .z.m.qp.quantile[t; `x; ::]
.z.m.qp.quantile:{[table; x; settings]
    customSettings : .z.m.qp.s.scale [`x; .z.m.gg.scale.limits[0 1] .z.m.gg.scale.linear]
                   , .z.m.qp.s.stat   .z.m.gg.stat.quantile x ;
    
    : i.apoint [.z.m.gg.geom.point; table; `fvalue__; x; .z.m.gg.h.extend[customSettings] i.initSettings settings];
    }

// @subcategory Geometries
// @fileOverview 
// Rectangle chart - draw a rectangle given it's bounds as two points for each record.
//
// - X - first position along the X axis
// - Y - first position along the Y axis
// - XEND - second position along the X axis
// - YEND - second position along the Y axis
//
// Aesthetic mappings ( .z.M.qp.s.aes`, dynamic) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `group `` - Grouping 
//
// Geometry settings ( .z.M.qp.s.geom`, static) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// @param table {table} data to be visualized
// @param x {symbol} column name
// @param y {symbol} column name
// @param xend {symbol} column name
// @param yend {symbol} column name
// @param settings {dict | null} settings for the visual (geom/bins/etc) 
// @returns {table} tree specifying a segment chart
// @see qp.tile
//
// @format .z.m.qp.i.qdformatter
//
// @example Load data and basic chart
//     t : ([]x1: 0 10; y1: 0 10; x2: 5 15; y2: 5 15);
//
//     .z.m.qp.rect[t; `x1; `y1; `x2; `y2; ::]
//
// @example Add custom geom properties
//     .z.m.qp.rect[t; `x1; `y1; `x2; `y2]
//            .z.m.qp.s.geom[`fill`alpha`colour`strokewidth!(`firebrick; 0x7f; `orange; 10)]
//
// @example Treemap
//     t: ([]Sector: 10?`8;MarketValue: 10?100);
//     positions: .z.m.qp.treemap.layout[t; `Sector; `MarketValue; ::];
// 
//     .z.m.qp.theme[.z.m.gg.theme.blank]
//          .z.m.qp.rect[positions;`x__;`y__;`x2__;`y2__]
//              .z.m.qp.s.aes[`fill; `Sector] ,
//              .z.m.qp.s.geom[``colour!(::; 0xffffff)]
.z.m.qp.rect:{[table; x; y; xend; yend; settings]
    : i.ageom[.z.m.gg.geom.rect; table; x; y; `x`y`xmax`ymax; (x;y;xend;yend); settings];
    }


.z.m.qp.ribbon:{[table; x; y; yend; settings]
    : i.ageom[.z.m.gg.geom.ribbon; table; x; y; `x`y`yend; (x;y;yend); settings];
    }


.z.m.qp.s.aes:{[item; col]
    : $[11h ~ type item;
        raze item .z.s' col;
        s.i.new[`$"aes",.z.m.gg.h.asString item; col]]    /dnl
    }

// @subcategory Layer Settings
// @fileOverview 
// Create a new aggregation setting.
//
// Applies only to Histogram, HHistogram, and Heatmap plots.
// @param aggr {any} value for the aesthetic 
// @returns {dict}
// @format .z.m.qp.i.qdformatter
// @example Add a count and custom aggregation (`avg` of `y`)
// .z.m.qp.histogram[([]x:til 45; y:til 45); `x]
//     .z.m.qp.s.aggr[.z.m.st.a.count[] , .z.m.st.a.custom[`yout; `y; avg]]
//    ,.z.m.qp.s.aes[`fill; `yout]
.z.m.qp.s.aggr:{[aggr]
    s.i.new[`aggr; aggr]
    }

// @subcategory Layer Settings
// @fileOverview 
// Create a new x bin setting.
//
// Applies only to Histogram, HHistogram, and Heatmap plots.
// @param d {symbol} width or count `w or `c
// @param s {number} width or count arg
// @param p {null|number} padding (normally 0)
// @returns {dict}
// @format .z.m.qp.i.qdformatter
// @example Change x bin settings to count=100
// .z.m.qp.heatmap[([]x:500?450; y:500?450); `x; `y]
//      .z.m.qp.s.binx[`c; 100; 0]
.z.m.qp.s.binx:{[d; s; p]
    if [.z.m.gg.h.null p; p: 0];
    s.i.new[`binx; (d; s; p)]
    }

// @subcategory Layer Settings
// @fileOverview 
// Create a new y bin setting.
//
// Applies only to Histogram, HHistogram, and Heatmap plots.
// @param d {symbol} width or count `w or `c
// @param s {number} width or count arg
// @param p {null|number} padding (normally 0)
// @returns {dict}
// @format .z.m.qp.i.qdformatter
// @example Change y bin settings to count=100
// .z.m.qp.heatmap[([]x:500?450; y:500?450); `x; `y]
//      .z.m.qp.s.biny[`c; 100; 0]
.z.m.qp.s.biny:{[d; s; p]
    if [.z.m.gg.h.null p; p: 0];
    s.i.new[`biny; (d; s; p)]
    }

// @subcategory Layer Settings
// @fileOverview 
// Change the coordinate system setting.
//
// Supported coordinate systems are:
//
// * `` .z.m.gg.coords.rect  `` - rectangular/2D Cartesian coordinates
// * `` .z.m.gg.coords.polar `` - polar coordinates
// * `` .z.m.gg.coords.cube  `` - cubic/3D Cartesian coordinates
//
// By default, rectangular coordinates are assumed for 2D plots, and cubic coordinates for 3D plots.
//
// Note - if polar coordinates are used, the frame canvas can be locked to
// a circle by specifying `` `square `` as the `` `aspect_ratio `` in the 
// theme. Otherwise the frame canvas will fill the space available. See
// the examples below.
// @param col {symbol} value for the aesthetic 
// @returns {dict}
//
// @format .z.m.qp.i.qdformatter
//
// @example Basic point plot (default is rectangular coordinates)
// .z.m.qp.point[([]x:45?45; y:45?45); `x; `y]
//      .z.m.qp.s.coord[.z.m.gg.coords.rect]
//
// @example Explicit rectangular coordinates
// .z.m.qp.theme[enlist[`aspect_ratio]!enlist `square]
// .z.m.qp.point[([]x:45?45; y:45?45); `x; `y]
//      .z.m.qp.s.coord[.z.m.gg.coords.rect]
// 
// @example Custom rectangular coordinates plot
//     .z.m.qp.bar[([]x:`a`b`c`d`e; y:9 6 4 3 1); `x; `y]
//          .z.m.qp.s.coord[.z.m.gg.coords.rect]
//          , .z.m.qp.s.aes[`fill; `x]
//          , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat10]
//          , .z.m.qp.s.scale[`y; .z.m.gg.scale.limits[0 9] .z.m.gg.scale.linear]
//
// @example Custom cubic coordinates plot
//     .z.m.qp.point3D[([]x:45?45; y:45?45; z:45?45); `x; `y; `z]
//          .z.m.qp.s.coord[.z.m.gg.coords.cube . 2#4*atan[1]%3]
// 
// @example Change the coordinate system to polar
//     .z.m.qp.theme[enlist[`aspect_ratio]!enlist `square]
//     .z.m.qp.bar[([]x:`a`b`c`d`e; y:9 6 4 3 1); `x; `y]
//          .z.m.qp.s.coord[.z.m.gg.coords.polar]
//          , .z.m.qp.s.aes[`fill; `x]
//          , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat10]
//          , .z.m.qp.s.scale[`y; .z.m.gg.scale.limits[0 9] .z.m.gg.scale.linear]
//
// @example The interpolation for polar coordinate can be changed
//      // Use .z.m.gg.coords.polarn[n] to have lines from a->b with no interpolation
//
//      .z.m.qp.segment[([]x1:45#0; y1:45#0; x2: 45?45; y2: 45?45); `x1; `y1; `x2; `y2] 
//            .z.m.qp.s.coord[.z.m.gg.coords.polarn 2]
//          , .z.m.qp.s.geom[`fill`size!(`firebrick; 2)]
// 
// @example Change geometry to horizontal bars, rect coords
//     .z.m.qp.hbar[([]x:`a`b`c`d`e; y:9 6 4 3 1); `y; `x]
//          .z.m.qp.s.coord[.z.m.gg.coords.rect]
//          , .z.m.qp.s.aes[`fill; `x]
//          , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat10]
//          , .z.m.qp.s.scale[`x; .z.m.gg.scale.limits[0 9] .z.m.gg.scale.linear]
// 
// @example Change coordinate system to polar
//     .z.m.qp.theme[enlist[`aspect_ratio]!enlist `square]
//     .z.m.qp.hbar[([]x:`a`b`c`d`e; y:9 6 4 3 1); `y; `x]
//          .z.m.qp.s.coord[.z.m.gg.coords.polar]
//          , .z.m.qp.s.aes[`fill; `x]
//          , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat10]
//          , .z.m.qp.s.scale[`x; .z.m.gg.scale.limits[0 9] .z.m.gg.scale.linear]
// 
// @example Customize limits, rect coordinates
//     .z.m.qp.hbar[([]z:0; x:`a`b`c`d`e; y:9 6 4 3 1); `y; `z]
//          .z.m.qp.s.coord[.z.m.gg.coords.rect]
//          , .z.m.qp.s.aes[`group; `x]
//          , .z.m.qp.s.geom[`gap`position!(0; `stack)]
//          , .z.m.qp.s.aes[`fill; `x]
//          , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat10]
//          , .z.m.qp.s.scale[`x; .z.m.gg.scale.extend[0b] .z.m.gg.scale.breaks[()] .z.m.gg.scale.limits[0 0N] .z.m.gg.scale.linear]
//          , .z.m.qp.s.scale[`y; .z.m.gg.scale.limits[0 0] .z.m.gg.scale.linear]
// 
// @example Change coordinate system to polar
//     .z.m.qp.theme[enlist[`aspect_ratio]!enlist `square]
//     .z.m.qp.hbar[([]z:0; x:`a`b`c`d`e; y:9 6 4 3 1); `y; `z]
//          .z.m.qp.s.coord[.z.m.gg.coords.polar]
//          , .z.m.qp.s.aes[`group; `x]
//          , .z.m.qp.s.geom[`gap`position!(0;`stack)]
//          , .z.m.qp.s.aes[`fill; `x]
//          , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat10]
//          , .z.m.qp.s.scale[`x; .z.m.gg.scale.extend[0b] .z.m.gg.scale.breaks[()] .z.m.gg.scale.limits[0 0N] .z.m.gg.scale.linear]
//          , .z.m.qp.s.scale[`y; .z.m.gg.scale.limits[0 0] .z.m.gg.scale.linear]
// 
// @example Change geometry to vertical bars, rect coordinates
//     .z.m.qp.bar[([]z:0; x:`a`b`c`d`e; y:9 6 4 3 1); `z; `y]
//          .z.m.qp.s.coord[.z.m.gg.coords.rect]
//          , .z.m.qp.s.aes[`group; `x]
//          , .z.m.qp.s.geom[`gap`position!(0; `stack)]
//          , .z.m.qp.s.aes[`fill; `x]
//          , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat10]
//          , .z.m.qp.s.scale[`y; .z.m.gg.scale.extend[0b] .z.m.gg.scale.breaks[()] .z.m.gg.scale.limits[0 0N] .z.m.gg.scale.linear]
//          , .z.m.qp.s.scale[`x; .z.m.gg.scale.limits[0 0] .z.m.gg.scale.linear]
// 
// @example Change coordinate system to polar
//     .z.m.qp.theme[enlist[`aspect_ratio]!enlist `square]
//     .z.m.qp.bar[([]z:0; x:`a`b`c`d`e; y:9 6 4 3 1); `z; `y]
//          .z.m.qp.s.coord[.z.m.gg.coords.polar]
//          , .z.m.qp.s.aes[`group; `x]
//          , .z.m.qp.s.geom[`gap`position!(0; `stack)]
//          , .z.m.qp.s.aes[`fill; `x]
//          , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat10]
//          , .z.m.qp.s.scale[`y; .z.m.gg.scale.extend[0b] .z.m.gg.scale.breaks[()] .z.m.gg.scale.limits[0 0N] .z.m.gg.scale.linear]
//          , .z.m.qp.s.scale[`x; .z.m.gg.scale.limits[0 0] .z.m.gg.scale.linear]
// 
// @example Polar coordinates are useful to visualize tree leaves
//     // Generate a binary tree of height 8
//     h: 8;
//     n: sum pn:"j"$xexp[2;]til h;
//     ls: n?`8;
//     ps: `,(,/)2#'(count[ls]-"j"$2 xexp h - 1)#ls;
//     t: ([]parent: ps; label: ls; amount: n?50);
// 
//     // Custom layout algorithm
//     arrange : {[table; level; a; p; o]
//         ra: select from table where parent = p;
//         ra[`amount]: ra[`amount] % sum ra`amount;
//         ra : `amount xdesc ra;
//         if [0 = count ra;
//             : ra];
//         t: ([] parent: p; 
//                x1: "f"$o+0,sums a*-1_ra`amount; 
//                w: a*ra`amount; 
//                y1: level; 
//                y2: level + 1; 
//                label: ra`label);
//         t[`x2]: t[`x1] + t[`w];
//         : t , raze .z.s[table; level + 1]'[t`w; ra`label; t`x1];
//         };
// 
//     .z.m.qp.theme[`aspect_ratio`legend_use!(`square; 0b)]
//         .z.m.qp.rect[arrange[t; 0f; 1; `; 0f]; `y1; `x1; `y2; `x2]
//              .z.m.qp.s.geom[`alpha`colour!(0xb0; `white)]
//            , .z.m.qp.s.aes[`fill; `parent]
//            , .z.m.qp.s.scale[`y; .z.m.gg.scale.extend[0b] .z.m.gg.scale.linear]
//            , .z.m.qp.s.scale[`x; .z.m.gg.scale.extension[0.3] .z.m.gg.scale.linear]
//            , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat20]
//
// @example Sunburst chart
//     .z.m.qp.theme[`aspect_ratio`legend_use!(`square; 0b)]
//         .z.m.qp.rect[arrange[t; 0f; 1; `; 0f]; `y1; `x1; `y2; `x2]
//              .z.m.qp.s.geom[`alpha`colour!(0xb0; `white)]
//            , .z.m.qp.s.coord[.z.m.gg.coords.polar]
//            , .z.m.qp.s.aes[`fill; `parent]
//            , .z.m.qp.s.scale[`y; .z.m.gg.scale.extend[0b] .z.m.gg.scale.linear]
//            , .z.m.qp.s.scale[`x; .z.m.gg.scale.extension[0.3] .z.m.gg.scale.linear]
//            , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat20]
.z.m.qp.s.coord:{[col]
    : s.i.new[`coord; col]
    }
// @subcategory Layer Settings
// @fileOverview 
// Create a new geometry setting.
//
// The properties that can be mapped are different depending on the geometry used (see  .z.M.gg.cheat.sheet[]` for a list of 
// geometries and their properties). In general, geometries can support the following properties:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `position `` - position adjust (`` `dodge ``, or `` `stack `` where supported, combined with `` `group `` aes setting)
//
// Other geometries may have custom properties that can be mapped as well (for example `` `width `` and `` `height`` in some cases).
// @param g {dict} dictionary of geom properties to set, and their corresponding values
// @returns {dict}
// @format .z.m.qp.i.qdformatter
// @example
// t : ([]x:sums?[45?1.<0.5;-1;1]; y:sums?[45?1.<0.5;-1;1]);
//
// .z.m.qp.point[t; `x; `y]
//     .z.m.qp.s.geom[``fill!(::;`firebrick)]
//
// @example
// .z.m.qp.point[t; `x; `y]
//     .z.m.qp.s.geom[`size`alpha`colour`strokewidth!(6; 0x00; `steelblue; 2)]
.z.m.qp.s.geom:{[g]
    s.i.new[`geom; @[;`fill`colour inter key g;.z.m.gg.colour.qualify] g , enlist[`]!enlist(::)]
    }

// @private
// @fileOverview 
// Create a new setting dictionary entry
// @param name {symbol} name of the setting 
// @param val {any} value for the setting
// @returns {dict}
.z.m.qp.s.i.new:{[name; val]
    : enlist[name]!enlist enlist[`get]!enlist val
    }

// @subcategory Layer Settings
.z.m.qp.s.init:{[f] 
    : s.i.new[`init; {[f;gg;node;lyr] f lyr } f]; 
    }

// @subcategory Layer Settings
// @fileOverview 
// Create a new label setting.
// @param l {any} value for the aesthetic 
// @returns {dict}
// @format .z.m.qp.i.qdformatter
// @example 
// t: ([]x: 500?500; y: 500?500);
//
// .z.m.qp.point[t; `x; `y]
//      .z.m.qp.s.scale[`y; .z.m.gg.scale.log]
//    , .z.m.qp.s.labels[`x`y!("X Position";"log of Y ($)")]
.z.m.qp.s.labels:{[l]
    : s.i.new[`labels; l]
    }


.z.m.qp.s.legend:{[title; legend]
    : s.i.new[`$"legend",.z.m.gg.h.asString title; legend]    /dnl
    }

// @subcategory Layer Settings
// @fileOverview 
// Add a link dependency.
//
// A link between plots (in a separate frame) ensures that whenever either
// of the plots is zoomed (drilled into), all other "linked" layers will inherit
// the new data of the zoomed layer. This way all linked plots are kept in sync.
//
// Many layer may be linked to the same ID as long as all layers are in separate 
// independent frames. For dependencies within a single frame, see  .z.M.qp.s.primary`.
// 
// @see qp.s.primary
// @see qp.s.secondary
// 
// @param linkid {symbol} a unique symbol relating to the dependency group
// @format .z.m.qp.i.qdformatter
// @example
// t : ([] x:sums?[45?1.<0.5;-1;1]; y:sums?[45?1.<0.5;-1;1]; z:45?45);
//
// .z.m.qp.layout[`hori; ::] (
//      .z.m.qp.point[t; `x; `y]
//          .z.m.qp.s.link[`myid];
//      .z.m.qp.point[t; `x; `z]
//          .z.m.qp.s.link[`myid])
.z.m.qp.s.link:{[linkid]
    : s.i.new[`linkid; linkid];
    }


.z.m.qp.s.norm:{[col]
    s.i.new[`norm; col]
    }

// @fileOverview 
// Add a click handler or tooltip data formatter to a layer
//
// Return anything other than a table (eg, `0b`) to disable tooltips for the layer
//
// @subcategory Layer Settings
// @param f {fn (table) -> table} Handler taking the subset of the layer's data that would be displayed
// @returns {table} table to display
//
// @example Choose which columns should appear in the results
// .z.m.qp.point[([]x:til 45;y:til 45;z:til 45); `x;`y]
//     .z.m.qp.s.onclick[{ `x`y#x }]
//
// @example Fire a new visual based on the clicked data
// .z.m.qp.point[([]x:til 45;y:til 45;z:til 45); `x;`y]
//      .z.m.qp.s.onclick[{ .z.m.qp.managed[`tooltip;500;500] .z.m.qp.point[x;`x;`y;::]; x }]
.z.m.qp.s.onclick:{[f] : s.i.new[`onclick; f]; }

// @subcategory Layer Settings
// @fileOverview 
// Add a zoom handler to a layer
//
// @param f {fn (table) -> table} 
// @returns {null}
//
.z.m.qp.s.ondrilldown:{[f] : s.i.new[`ondrilldown; f]; }


.z.m.qp.s.primary:{[id]
    : s.i.new[`primaryid; id];
    }



.z.m.qp.s.scale:{[item; col]
    : s.i.new[`$"scales",.z.m.gg.h.asString item; col]    /dnl
    }

// @subcategory Layer Settings
// @fileOverview
// Register the layer as a secondary data supplier for the frame.
// Whenever the frame is zoomed, the primary layer will feed its 
// data to the secondary layer(s).
//
// The secondary layer must be in the same frame as the primary layer.
//
// @see qp.s.primary
// @param id {symbol} unique identifier for the dependency group
// @format .z.m.qp.i.qdformatter
// @example
//     t:([]date:til 100; price:sums?[100?1.<0.5;-1;1]);
// 
//     .z.m.qp.stack (
//         .z.m.qp.point[t; `date; `price]
//              .z.m.qp.s.primary[`myid];
//         .z.m.qp.smooth[t; `date; `price; ::]
//              .z.m.qp.s.secondary[`myid])
.z.m.qp.s.secondary:{[id]
    : s.i.new[`secondaryid; id];
    }

// @subcategory Layer Settings
// @fileOverview 
// Share a scale between plots in separate frames based on unique label.
// All plots with the same label/axis pair will contain the same limits
// when plotted or zoomed.
//
// @param label {symbol} unique label to associate plots to this shared scale
// @param scale {symbol} x or y - the axis to share
// @returns {dict}
//
// @format .z.m.qp.i.qdformatter
// @example Shared y scale between a heatmap and scatter
// // Notice how the limits of both plots are extended
// // to show the same region
// .z.m.qp.horizontal (
//     .z.m.qp.heatmap[([]x:til 45); `x; `x]
//         .z.m.qp.s.share[`label; `y];
//     .z.m.qp.point[([]x:neg til 45); `x; `x]
//         .z.m.qp.s.share[`label; `y]
//     )
.z.m.qp.s.share:{[label; scale]
    s.i.new[`$"share",.z.m.gg.h.asString scale; label]
    }

// @subcategory Layer Settings
// @fileOverview 
// Create a new statistical function setting for the layer. See .z.m.gg.stat for available statistical transform functions.
// @param val {any} statistical transform (see .z.m.gg.stat for options)
// @returns {dict}
// @format .z.m.qp.i.qdformatter
// @example A histogram is bar geometry with a 1D bin stat
//     t: ([]x: 500?5?`5);
//
//     .z.m.qp.bar[t; `x; `count__]
//         .z.m.qp.s.stat[.z.m.gg.stat.bin1d[`x; ::; .z.m.st.a.count[]; ::]]
.z.m.qp.s.stat:{[val]
    : s.i.new[`stat; val]
    }

// @subcategory Layer Settings
// @fileOverview
// Change the alignment of a text geometry.
//
// > Note, this setting is deprecated, and the  .z.M.qp.s.geom` setting
// > on a text geometry should be used instead.
//
// @param val {symbol} one of `` `left`middle`right ``
// @format .z.m.qp.i.qdformatter
// @example The default is left alignment
// t: ([]x:til 5; label:5?`8);
//
// .z.m.qp.text[t; `x; `x; `label; ::]
//
// @example Explicit left alignment
// .z.m.qp.text[t; `x; `x; `label]
//      .z.m.qp.s.textalign[`left]
//
// @example Middle alignment
// .z.m.qp.text[t; `x; `x; `label]
//      .z.m.qp.s.textalign[`middle]
//
// @example Right alignment
// .z.m.qp.text[t; `x; `x; `label]
//      .z.m.qp.s.textalign[`right]
// @deprecated
// @see qp.text
.z.m.qp.s.textalign:{[val]
    : s.i.new[`textalign; val]
    }

// @subcategory Layer Settings
// @fileOverview 
// Bound text within a rectangle, adjusting the fontsize so that it fits
// @param val {(symbol;symbol;symbol;symbol)} symbol list containing columns for bounding rect in x1, y1, x2, y2 order
// @returns {dict} Settings object
//
// @format .z.m.qp.i.qdformatter
//
// @example
//
//     t: .z.m.gg.cheat.i.assemble[];
//     t: update w: 1 from t;
//     r: .z.m.qp.treestack.layout[t;`id;`children;`w;::];
// 
//     .z.m.qp.stack (
//         .z.m.qp.rect[r;`x__;`y__;`x2__;`y2__]
//             .z.m.qp.s.geom[``colour!(::;0xffffff)];
//         .z.m.qp.text[r;`tx__;`ty__;`id]
//             .z.m.qp.s.textalign[`middle] ,
//             .z.m.qp.s.textbounds[`x__`y__`x2__`y2__] ,
//             .z.m.qp.s.geom[``fill!(::;0xffffff)])
//
.z.m.qp.s.textbounds:{[val]
    : s.i.new[`textbounds; val]
    }
// @subcategory Layer Settings
// @fileOverview 
// Change layer specific theme settings (labels, etc). For global/subplot
// theme settings, see .z.m.qp.theme.
// @see qp.theme
// @param t {any} value for the aesthetic 
// @returns {dict}
.z.m.qp.s.theme:{[t]
    s.i.new[`theme; t]
    }

// @subcategory Layer Settings
// @fileOverview
// Set a custom zoom handler
// @param f {fn} (pt1; pt2; table; aes; scales; layer) -> long[]
// @returns {long[]} Indicies
.z.m.qp.s.zoom:{[f] s.i.new[`zoomF; f] }


.z.m.qp.scatter:{[table; x; y; settings]
    : i.apoint [.z.m.gg.geom.point; table; x; y; settings];
    }

// @subcategory Geometries
// @fileOverview 
// Segment chart. Draw a line between two points (defined by four columns) for every record.
//
// - X - horizontal position of the first point
// - Y - vertical position of the first point
// - XEND - horizontal position of the last point
// - YEND - vertical position of the last point
//
// Aesthetic mappings ( .z.M.qp.s.aes`, dynamic) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `size `` - Line size
//
// Geometry settings ( .z.M.qp.s.geom`, static) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `size `` - Line size
// - `` `dashed `` - Solid or dashed line
//
// @param table {table} data to be visualized 
// @param x {symbol} x column 
// @param y {symbol} y column 
// @param xend {symbol} x end column
// @param yend {symbol} y end column
// @param settings {dict | null} settings for the visual (theme/geom/etc)
// @returns {table} tree specifying a segment chart
//
// @format .z.m.qp.i.qdformatter
//
// @example Load data and basic chart
//      t : ([]x1: 0 10; y1: 0 10; x2: 5 15; y2: 5 15);
//
//      .z.m.qp.segment[t; `x1; `y1; `x2; `y2; ::]
//
// @example Add some geom properties
// .z.m.qp.segment[t; `x1; `y1; `x2; `y2]
//     .z.m.qp.s.geom[`fill`size!(`steelblue; 10)]
//
// @example Step charts created using segments
// // original values
// points: ([]x:til 10;y:10?45);
// // create steps for segments
// steps:  raze {flip `x`y`x2`y2!(x`x`x2; x`y; x`x2; x`y`y2)} each 
//     points,'select x2:next x, y2:next y from points;
//
// .z.m.qp.title["Example step chart"]
//     .z.m.qp.stack (
//         // step lines
//         .z.m.qp.segment[steps; `x; `y; `x2; `y2; ::];
//         // original points
//         .z.m.qp.point[points;`x;`y] .z.m.qp.s.geom[``size`fill!(::;3;0xff0000)])
//
// @example Draw lines out of a single point
//     t:         (0 0;) @' flip -10 + 20 20?\:20;
//     quadrant:  {$[all 0<=x,y;1;(0>x)&0<=y;2;(0>x)&0>y;3;4]};
//     angles:    {atan (%). abs reverse y-x}./:t;
//     quadrants: {quadrant . y-x} ./: t;
//     t:         update q: quadrants from `x`y`x2`y2!/:raze each t;
//
//     .z.m.qp.segment[t; `x; `y; `x2; `y2]
//         .z.m.qp.s.aes[`fill; `q] ,
//         // Override the default numeric colour scale with a categorical one
//         .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat10]
//
.z.m.qp.segment:{[table; x; y; xend; yend; settings]
    : i.ageom[.z.m.gg.geom.segment; table; x; y; `x`y`xend`yend; (x;y;xend;yend); settings];
    }

// @private
// @fileOverview 
// Create a plot of small multiples - one plot per pair of columns in `cs`. If `cs` is empty, all columns will be rendered in pairs.
// @param t {table} 
// @param cs {symbol[]|symbol} 
// @param settings {dict|null} 
.z.m.qp.smalls:{[t; cs; settings]
    
    if [5 < count cs;
        '.z.m.axlocalize.t`.qp_columnLimitError];

    settings : i.initSettings settings;
    
    m:   (count cs;count cs)#cs cross cs;
    id:  i.resolveWDefault[`$string rand 0Ng; `linkid; settings];
    tri: {(x#'0b),'reverse(1+x)#'1b} til count m;
    m:   tri {$[x;y;`$"__",/:string y]}'' m;
    
    horis : {[id;t;s;row]
        layers: ({[id;t;s;x;y]
                
                if [any not (.z.m.gg.tbl.metatype[t] each x,y) in\: key .z.m.gg.h.METATYPES;
                    : empty[]];

                if [all (x,y) like "__*";
                    cs: `$2_'string x,y;
                    numeric: all (.z.m.gg.h.metatype[t] each cs) in "bxhijefpmdznuvt";
                    
                    : $[not numeric;
                        .z.m.qp.empty[];
                        .z.m.qp.theme[``grid_style_x`grid_style_y`legend_use!(::;`none;`none;0b)]
                        .z.m.qp.text[enlist`x`y`t!(0;0;(cor) . .z.m.gg.tbl.column[t] each cs);`x;`y;`t]
                            .z.m.qp.s.aes[`fill; `t] ,
                            .z.m.qp.s.scale[`fill; .z.m.gg.scale.limits[-1 1] .z.m.gg.scale.colour.gradient2[0f; `red; `black; `green]] ,
                            .z.m.qp.s.geom ``align!(::;`middle)]];
                
                : $[x ~ y;
                    .z.m.qp.histogram[t; x]
                        .z.m.gg.h.extend[s;
                            .z.m.qp.s.link[id] ,
                            .z.m.qp.s.share[x; `x] ,
                            .z.m.qp.s.labels[`x`y!(x;x)] ,
                            .z.m.qp.s.theme ``legend_use!(::;0b)];
                    .z.m.qp.plot[t; (x;y)]
                        .z.m.gg.h.extend[s;
                            .z.m.qp.s.link[id] ,
                            .z.m.qp.s.share[x; `x] ,
                            .z.m.qp.s.share[y; `y] ,
                            .z.m.qp.s.theme ``legend_use!(::;0b)]];
                }[id;t;s].) each row;
        : layers;
        }[id;t;settings] each m;
    
    : .z.m.qp.i.facetGrid[2#count cs] raze flip horis;
    };


.z.m.qp.smooth:{[table; x; y; opts; settings]
    
    opts: .z.m.gg.h.extend[(enlist`)!enlist (::)] i.initSettings opts;
    
    if [not `force in key opts;
        opts[`force]: 0b];
       
    loessStat : .z.m.gg.stat.new[{[x;y;opts;table]
            ys : .z.m.st.loess.smooth[.z.m.gg.tbl.column[table;x]; .z.m.gg.tbl.column[table;y]; opts];
            : (x;y) xcol flip `x`y!(ys`x; ys`response)
            }[x;y;opts]; enlist x];
    
    lsquaresStat : .z.m.gg.stat.lsquares[x;y;opts`degree];
    
    stat : $[not `stat in key opts; `loess;
             `loess ~ opts`stat;    `loess;
             `lsq ~ opts`stat;      `lsq;
                                    `loess];
    
    if [(not opts`force) and (stat ~ `loess) and i.LOESS_THRESHOLD < count table;    '.z.m.axlocalize.t`.qp_loessLimitError];
    if [(stat ~ `lsq) and not `degree in key opts;                                   '.z.m.axlocalize.t`.qp_lsqDegreeError];
    
    stat : (loessStat; lsquaresStat) `loess`lsq ? stat;
    
    : .z.m.qp.line[table; x; y;
        .z.m.qp.s.stat[stat]
      , .z.m.qp.s.geom[`size`fill!(2;.z.m.gg.colour.Red)]
      , i.initSettings settings]
    
    }


.z.m.qp.split:{[speclist]
    if [not 2 = count speclist; '.z.m.axlocalize.t`.qp_splitPairError];
    : .z.m.gg.spec.split . speclist;
    }

// @subcategory Layouts
// @fileOverview 
// Stack multiple visuals with the same x and y scales on top of each other.
// @param speclist {table[]} list of specifications to stack
// @returns {table} specification table
//
// @format .z.m.qp.i.qdformatter
//
// @example Basic stack using same table
//     t: ([]x: til 20; y: 20?20; x2: 0.4+til 20);
// 
//     .z.m.qp.stack (
//         .z.m.qp.line[t; `x; `y; ::];
//         .z.m.qp.point[t; `x; `y; ::])
// 
// @example Customize
//     .z.m.qp.stack (
//         .z.m.qp.line[t; `x; `y]
//             .z.m.qp.s.geom[`size`fill!(3; `firebrick)];
//         .z.m.qp.point[t; `x; `y]
//             .z.m.qp.s.geom[`strokewidth`size`colour`fill!(2; 6; `firebrick; 0xf4f4f8)])
// 
// @example Add annotations
//     .z.m.qp.stack (
//         .z.m.qp.line[t; `x; `y]
//             .z.m.qp.s.geom[`size`fill!(3; `firebrick)];
//         .z.m.qp.point[t; `x; `y]
//             .z.m.qp.s.geom[`strokewidth`size`colour`fill!(2; 6; `firebrick; 0xf4f4f8)];
//         .z.m.qp.text[t; `x2; `y; `y; ::])
// 
// @example Overlay smoothers
//     t:([]date:til 100; price:sums?[100?1.<0.5;-1;1]);
// 
//     .z.m.qp.stack (
//         .z.m.qp.point[t; `date; `price; ::];
//         .z.m.qp.smooth[t; `date; `price; ::; ::])
// 
// @example Stack multiple geometries to build custom charts
//     n:10000;
//     t:([]date:raze 200#'2015.01.01+til 50; price:sums?[n?1.<0.5;-1;1]);
// 
//     ohlc : 0!select open:first price, close:last price, high:max price, low:min price by date from t;
//     gain : select from ohlc where close > open;
//     loss : select from ohlc where not close > open;
// 
//     .z.m.qp.stack (
//         .z.m.qp.segment[gain; `date; `high; `date; `low]
//             .z.m.qp.s.geom[``fill!(::;`green)];
//         .z.m.qp.segment[loss; `date; `high; `date; `low]
//             .z.m.qp.s.geom[``fill!(::;`red)];
// 
//         .z.m.qp.interval[gain; `date; `open; `close]
//             .z.m.qp.s.geom[``fill!(::; `green)];
//         .z.m.qp.interval[loss; `date; `open; `close]
//             .z.m.qp.s.geom[``fill!(::; `red)])
.z.m.qp.stack:{[speclist]
    : .z.m.gg.spec.stack[speclist;::]
    }

// @subcategory Layouts
.z.m.qp.stackAnd:{[f;speclist]
    : .z.m.gg.spec.stack[speclist;f]
    }


.z.m.qp.stackWith:{[table; speclist]
    : .z.m.gg.spec.stack[;::] speclist @\: table
    }


.z.m.qp.text:{[table; x; y; label; settings]
    settings: i.initSettings settings;
    labels: {[settings; align; alpha; renderer; renderObj; cvs; frame; tabs]
        g:     i.resolveWDefault[()!(); `geom; settings];
        truncate: $[`truncate in key g; g`truncate; 0b];
        comp: .z.m.gg.spec.node.item frame;
        box:  raze .z.m.gg.etable.settings first tabs;
        txt:  raze .z.m.gg.etable.settings last tabs;
        
        if [0 = count box;
            : renderObj];
        
        if [0 = count txt;
            : renderObj];
        
        box: flip `x1`y1`x2`y2!box`x1`y1`x2`y2;
        boxes: -1+0{[box;l;f]
                first {[box;x] (not last x) & first[x] < 1+count box}[box]{
                    b: z y 0;
                    (1+y 0;) {[x;y;bx1;by1;bx2;by2]
                        (x within asc bx1,bx2) & y within asc by1,by2
                        }[x`x;x`y;b`x1;b`y1;b`x2;b`y2]
                    }[f;;box]/($[l=1+count box;0;l];0b)
                }[box]\txt;

        boxes: ?[boxes=count box;0N;boxes];

        if [0 = count where not null boxes;
            : renderObj];

        txt[`colour]:    .z.m.gg.colour.setAlpha[alpha] .z.m.axbits.and[0x0 sv 0x00ffffff] txt`colour;
        widths:  (exec comp[`w] * x2 - x1 from box boxes) - $[`offsetx in key g; 2 * g`offsetx; 0];
        heights:  exec comp[`h] * y2 - y1 from box boxes;
        $[truncate;
            [
                txt[`text]: i.fitText[widths; txt`fontsize; txt`text];
                txt: txt where txt[`fontsize] < heights];
            [
                txt[`fontsize]:  12&"j"$heights;
                fontsizes:       raze each {.z.m.gg.h.textWidth[;y] each x} .' flip (fs:1|{(1<){x-1}\x}each txt`fontsize;enlist each txt`text);
                txt[`fontsize]:  0^fs@'(first where@) each widths > fontsizes]];
        
        : .z.m.gg.i.draw.on[renderer; renderObj; cvs; frame; .z.m.gg.coords.rect] 
            .z.m.gg.etable.el[(`left`middle`center`right!.z.m.gg.etable.g`ATEXTL`ATEXTM`ATEXTM`ATEXTR)align] txt;
        } settings;
    
    align : i.resolveWDefault[`left; `textalign; settings];
    
    if [`geom in key settings;
        if [`align in key settings .`geom`get;
            align: settings . `geom`get`align]];
    
    alpha : 0xff;
    bounds: i.resolveWDefault[0b; `textbounds; settings];
    g     : $[`left ~ align; .z.m.gg.geom.textL; any align ~/: `middle`center; .z.m.gg.geom.textM; `right ~ align; .z.m.gg.geom.textR; .z.m.gg.geom.textL];

    if [not bounds ~ 0b;
        $[`geom in key settings;
            [ alpha: settings[`geom;`get;`alpha]; settings[`geom;`get] ,: ``alpha!(::;0x00) ];
            settings ,: .z.m.qp.s.geom ``alpha!(::;0x00)]];
    
    txt  : i.apoint[g; table; x; y; .z.m.gg.h.extend[s.aes[`label; label]] settings];
    
    if [bounds ~ 0b;
        : txt];
    
    if [not (4 = count bounds) & 11h ~ type bounds;
        '"Bounds must be a list of columns in x, y, x2, y2 order"];
    
    : .z.m.qp.stackAnd[labels[align; $[(::) ~ alpha; 0xff; alpha]]] (
        .z.m.qp.rect[table; bounds 0; bounds 1; bounds 2; bounds 3]
              .z.m.qp.s.geom    [``alpha!(::;0x00)]
            , .z.m.qp.s.onclick [{ 0b }]
            , $[not `linkid in key settings; (); .z.m.qp.s.link settings[`linkid;`get]]
            , $[not `stat   in key settings; (); .z.m.qp.s.stat settings[`stat;  `get]];
        txt)
    }


// @example Clean blue theme
//     .z.m.qp.theme[.z.m.gg.theme.cleanblue] SPEC
// 
// @example Transparent theme
//     .z.m.qp.theme[.z.m.gg.theme.transparent] SPEC
// 
// @example White theme
//     .z.m.qp.theme[.z.m.gg.theme.white] SPEC
// 
// @example Blank theme
//     .z.m.qp.theme[.z.m.gg.theme.blank] SPEC
// 
// @example custom settings
//     .z.m.qp.theme[``dynamic_axes`grid_style_y`legend_use!(::;1b;`zebra;0b)] 
//     SPEC
//
.z.m.qp.theme:{[t; s]
    colours: where 4h = type each .z.m.gg.theme.default;
    alpha:   where 4 = count each colours!.z.m.gg.theme.default colours;
    
    : .z.m.gg.spec.with.theme[
        @[;alpha inter key t;{$[3=count x;0xff,x;x]}]
        @[;colours inter key t;.z.m.gg.colour.qualify] t , enlist[`]!enlist(::)] s
    }

// @subcategory Geometries
// @fileOverview 
// Tile plot. Default width and height is 1, but can be changed (see examples below).
//
// - X - left edge of the tile
// - Y - bottom of the tile
//
// Aesthetic mappings ( .z.M.qp.s.aes`, dynamic) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `group `` - Grouping (combined with `` `position `` geom settings)
//
// Geometry settings ( .z.M.qp.s.geom`, static) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `colour `` - Outline colour
// - `` `strokewidth `` - Outline size
// - `` `width `` - Width
// - `` `height `` - Height
// - `` `valign `` - Vertical alignment (`` `bottom`top`middle ``)
// - `` `halign `` - Horizontal alignment (`` `right`left`middle ``)
// - `` `gap `` - gap between tiles as percentage of width/height (for example, `0.03` for 3%)
//
// @param table {table} data to be visualized 
// @param x {symbol} x column 
// @param y {symbol} y column 
// @param settings {dict | null} settings for the visual (theme/geom/etc)
// @returns {table} tile plot specification
// @see qp.rect
//
// @format .z.m.qp.i.qdformatter
//
// @example Load data and basic chart
//      t : ([]x: 0 10; y: 0 10);
//
//     .z.m.qp.tile[t; `x; `y; ::]
//
// @example Change width and height
//     .z.m.qp.tile[t; `x; `y]
//          .z.m.qp.s.geom[`width`height!5 5]
//
// @example Correlation matrix
//
//     t:  flip raze {enlist[x]!enlist sums 1000?-1 1} each `$/:10#.Q.a;
//     t2: `x`y`r!/:{ x ,' (cor) .' t x } (cross) . 2#enlist cols t;
//
//     .z.m.qp.tile[t2; `x; `y]
//         .z.m.qp.s.aes[`fill; `r] ,
//         .z.m.qp.s.scale[`fill; .z.m.gg.scale.limits[-1 1] .z.m.gg.scale.colour.gradient2[0f; `red; 0xcbcbcb; 0x0070cd]]
.z.m.qp.tile:{[table; x; y; settings]
    : i.apoint[.z.m.gg.geom.tile; table; x; y; settings];
    }

// @subcategory Plot Settings
// @fileOverview 
// Add a title node to a specification
// @param title {char[]} 
// @param spec {table}
// @return {table}
//
// @format .z.m.qp.i.qdformatter
//
// @example
//      .z.m.qp.title["A basic scatterplot"] 
//          .z.m.qp.point[([]x:til 45); `x; `x; ::]
.z.m.qp.title:{[title; spec]
    : .z.m.gg.spec.with.title[title] spec
    }


.z.m.qp.vector:{[t; x1; y1; x2; y2; segsettings; nodesettings]
    director: {[renderer; renderObj; cvs; frame; tabs]
        points:    (,'/) .z.m.gg.etable.qualify tabs 0;
        segments:  (,'/) .z.m.gg.etable.qualify tabs 1;
        
        triangleSize: 4;
        comp:      .z.m.gg.spec.node.item frame;
        
        if [(0 = count segments)|0 = count points;
            : renderObj];

        triangles: .z.m.gg.h.dictAt[points;] flip[points`x`y] ? flip value exec x:x2, y:y2 from segments;
        triangles[`size]: 0^triangles `size;
        
        segments: update x1*comp`w, x2*comp`w, y1*comp`h, y2*comp`h from segments;
        angles:   180 + neg .z.m.gg.math.radtodeg .z.m.gg.math.angle[0 1] each flip (segments`x2`y2) - segments`x1`y1;
        offsets: flip (triangleSize + triangles`size) * .z.m.gg.proj.normalize each flip segments[`x1`y1] - segments`x2`y2;

        normOffsets:  (.z.m.gg.proj.proj[(0;comp`w);0 1;]; .z.m.gg.proj.proj[(0;comp`h);0 1;]) @' offsets;
        triangles[`x`y]  +: normOffsets;
        
        triangles[`angle] : angles;
        triangles[`size]  : triangleSize;
        triangles[`colour]: segments`colour;
        
        renderObj: .z.m.gg.i.draw.on[renderer; renderObj; cvs; frame; .z.m.gg.coords.rect] .z.m.gg.etable.el[.z.m.gg.etable.g.TRIANGLE] triangles;
        
        : renderObj;
        };
    
    : .z.m.qp.stackAnd[director] (
        .z.m.qp.point  [t; x1; y1]         nodesettings;
        .z.m.qp.segment[t; x1; y1; x2; y2] segsettings)
    
    }

// @subcategory Layouts
// @fileOverview
// Layout independent specifications vertically with the same weighting
// @param speclist {table[]} list of specifications to layout
// @format .z.m.qp.i.qdformatter
// @see qp.layout
//
// @example Load data and vertical layout
//     t : ([] date: til 1000; 
//             start: sums?[1000?1.<0.5;-1;1]; 
//             end: sums?[1000?1.<0.5;-1;1];
//             volume: 10+1000?10; 
//             sym: 1000?10?`5);
// 
//    .z.m.qp.vertical (
//        .z.m.qp.ribbon[t; `date; `start; `end; ::];
//        .z.m.qp.histogram[t; `sym; ::])
.z.m.qp.vertical:{[speclist]
    : .z.m.qp.layout[`vert; ::] speclist;
    }

// @subcategory Geometries
// @fileOverview 
// Vertical straight line.
//
// - X - horizontal position of the line
//
// Aesthetic mappings ( .z.M.qp.s.aes`, dynamic) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `size `` - Line size
//
// Geometry settings ( .z.M.qp.s.geom`, static) supported:
//
// - `` `fill `` - Fill colour
// - `` `alpha `` - Opacity
// - `` `size `` - Line size
// - `` `dashed `` - Solid or dashed lines
//
// @param x {symbol} x position
// @param settings {dict | null} settings for the visual (theme/geom/etc)
// @returns {table} specification tree for a bar chart
//
// @format .z.m.qp.i.qdformatter
//
// @example Basic vertical rules
//
// t: ([]x: .z.m.st.gen.normal 100000; y: .z.m.st.gen.normal 100000);
//
// .z.m.qp.stack (
//     .z.m.qp.point[t; `x; `y] .z.m.qp.s.geom[``alpha!(::; 0x2f)];
//     .z.m.qp.vline[-2] .z.m.qp.s.geom[``fill!(::; `red)];
//     .z.m.qp.vline[2]  .z.m.qp.s.geom[``fill!(::; `red)])
//
// @example Adding in horizontal rules
//
// .z.m.qp.stack (
//     .z.m.qp.point[t; `x; `y] .z.m.qp.s.geom[``alpha!(::; 0x2f)];
//     .z.m.qp.hline[0]  .z.m.qp.s.geom[``fill!(::; `red)];
//     .z.m.qp.vline[-2] .z.m.qp.s.geom[``fill!(::; `red)];
//     .z.m.qp.vline[2]  .z.m.qp.s.geom[``fill!(::; `red)])
//
.z.m.qp.vline:{[x; settings] i.sline[`x; x; settings] }

.z.m.qp.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.qp_tableArgumentError; "First argument must be a table");
        (`.qp_columnListArgumentError; "Second argument must be a list of columns or an empty list");
        (`.qp_noDefaultError; "No default for the given column types");
        (`.qp_columnLimitError; "Plot matrix only supports up to 5 columns");
        (`.qp_loessLimitError; "LOESS not supported for greater than 10000 records: add the `force option, set a `delta, or use a stat");
        (`.qp_lsqDegreeError; "Least Squares requires a polynomial degree: add `degree option");
        (`.qp_splitPairError; "split must be a pair of left and right specifications")
            
    ))
.z.m.qp.i.angles3D:(
    5*atan 1;
    neg atan 1%sqrt 2)
.z.m.qp.i.SCALES:`alpha`fill`colour`size`x`y
.z.m.qp.i.LOESS_THRESHOLD:10000
.z.m.qp.i.AES:`group`label`alpha`fill`colour`size`angle`offsetx`offsety
system "d .z.m";

system "d .z.m.gg";
// @fileOverview 
// Convert each field of the rollover to a string view
// @param d {dict[]} 
.z.m.gg.interact.i.fmtRecords:{[d]
    if [() ~ d; : d];
    if [0 = count d`data; : d];
    d[`data]: {
        if [not 98h ~ type x; : x];
        flip h.printNum[h.print2;::] each/: flip x
        } each d`data;
    : d;
    }

// @fileOverview 
// Get all geometries that have a zoom defined, with layer zoom functions given 
// precedence over geom zoom functions
// @param layerDefns {dict[]} 
// @returns {function[]} list of zoom functions
.z.m.gg.interact.i.getZoomFs:{[layerDefns]
    zoomFs : h.atAll[`zoomF] layerDefns;
    f      : { $[(::) ~ x; (`transformed;y); 1b ~ x; (`data;y); (`transformed;x)] };
    : zoomFs f' h.atAll[`zoomF] h.atAll[`geom] layerDefns;
    }
// @fileOverview 
// Return any axis type, scale, and bounds of any axes that bound the given point
// @param pt {(number;number)} pixel coordinate 
// @param gg {dict} displayed GG object
// @returns {dict} axis, scale, and bounds
.z.m.gg.interact.i.hitAxes:{[pt; gg]
    hitAxes : spec.axesFromPt [pt; ty.spec gg];
    
    if [0 = count hitAxes;
        : ()];
    
    item   : first hitAxes;
    lyr    : spec.pluck[`defn] item`node;
    bounds : spec.toBounds first @[;item`axis] spec.pluck[`frame] item`node;
    : `axis`scale`bounds!(item`axis; lyr[`scales;$[`xaxis ~ item`axis; `x; `y]]; bounds $[`xaxis ~ item`axis; 0; 1]);
    }

// @fileOverview 
// Return the hit layer components given a point and a sized specification
// @param pt {(number;number)} pixel coordinate 
// @param gg {dict} GG object 
.z.m.gg.interact.i.hitLayerComponents:{[pt; gg; opts]
    
    if [(::) ~ opts; opts : ()!()];
    if [not `filter in key opts; opts[`filter]: 0b];
    if [not `extend in key opts; opts[`extend]: 0b];
    
    hitLayerNodes : spec.layersFromPt [pt; ty.spec gg];
    if [opts`filter; hitLayerNodes : hitLayerNodes where not 1b ~/: (spec.theme[;ty.spec gg] each hitLayerNodes)@\:`rollover_ignore];
    hitLayerComponents : spec.node.item each hitLayerNodes;
    
    nonEmpty : 0 < count each h.atAll[`data] spec.pluck[`defn] hitLayerComponents;
    
    if [0 = count where nonEmpty;
        : ()];
    
    : hitLayerComponents where nonEmpty;
    }

// @fileOverview 
// Given a point and a GG, return a 0-1 normalized point relative to a
// containing canvas within the GG.
// @param pt {(number;number)} pixel coordinate (0,0) is top left 
// @param gg {dict} displayed GG object
// @returns {(number;number)[]} list of 0-1 normalized points (one for each canvas)
.z.m.gg.interact.i.invNormalizePt:{[pt; gg; npts; opts]
    
    hitLayerComponents : interact.i.hitLayerComponents [pt; gg; opts];
    
    hitCanvases : spec.node.item each first each h.atAll[`geom] spec.pluck[`frame] hitLayerComponents;
    
    xs  : proj.proj[0 1]'[0,/:spec.ty.component.w each hitCanvases; npts[;0]];
    ys  : proj.proj[0 1]'[0,/:spec.ty.component.h each hitCanvases; npts[;1]];
    
    : {[opt; pt; cs; ii]
        : opt ^ (pt[ii;0] + (spec.ty.component.origin cs ii) 0;
                           ((spec.ty.component.h cs ii) - pt[ii;1]) + (spec.ty.component.origin cs ii) 1);
        }[pt; flip(xs;ys); hitCanvases] each til count hitCanvases;
    
    }

// @fileOverview 
// Limit the number of records returned in a rollover query
// @param d {dict} rollover data containing `data`distance`geom`pt
// @returns {dict} updated rollover data limits the number of records in the `data field
.z.m.gg.interact.i.limitRecords:{[d]
    if [not 98h ~ type d`data; : d];
    d[`data] : {(0;interact.i.MAXRECORDS) sublist x} d`data;
    : d;
    }

// @fileOverview 
// Given a point and a GG, return a 0-1 normalized point relative to a
// containing canvas within the GG.
// @param pt {(number;number)} pixel coordinate (0,0) is top left 
// @param gg {dict} displayed GG object
// @returns {(number;number)[]} list of 0-1 normalized points (one for each canvas)
.z.m.gg.interact.i.normalizePt:{[pt; gg; opts]
    
    hitLayerComponents : interact.i.hitLayerComponents [pt; gg; opts];
    
    hitCanvases : spec.node.item each first each h.atAll[`geom] spec.pluck[`frame] hitLayerComponents;
    
    pts : {[pt; x]
        : (pt[0] - (spec.ty.component.origin x) 0; (spec.ty.component.h x) - pt[1] - (spec.ty.component.origin x) 1);
        }[pt] each hitCanvases;
    
    xs  : proj.proj[;0 1]'[0,/:spec.ty.component.w each hitCanvases; pts[;0]];
    ys  : proj.proj[;0 1]'[0,/:spec.ty.component.h each hitCanvases; pts[;1]];
    
    : flip (xs;ys);
    }

// @fileOverview 
// Return the data associated with the closest break on the axis clicked
// @param pt {(number;number)} pixel coordinate 
// @param gg {dict} displayed GG object
// @returns {dict|null} the point and break value
.z.m.gg.interact.i.rollover.axes:{[pt; gg]
    
    axis : interact.i.hitAxes [pt; gg];
    
    if [0 = count axis;
        : (::)];
    
    pp    : pt $[`xaxis ~ axis`axis; 0; 1];
    pp    : pp - axis[`bounds;0];
    range : (-) . desc axis`bounds;
    
    if [`yaxis ~ axis`axis;
        pp : range - pp];
    
    norm    : pp % range;
    sc      : axis`scale;
    projd   : proj.proj[sc`geom_limits; 0 1; sc`breaks];
    indexed : (diff:abs projd - norm)!til count projd;
    idx     : indexed min diff;
    
    pt : interact.i.rollover.axisPoint[pt; axis; idx];
    
    : `pt`data!(pt; enlist enlist[`axis]!enlist h.print scale.inverse[sc; first sc[`breaks]idx]);
    
    }

// @fileOverview 
// Given a point, an "axis", and a break index, get the pixel of the corresponding visual break
// @param pt {long[]} pixel coordinate (the clicked point) 
// @param axis {dict} dictionary containing the scale, the axis direction (xaxis, yaxis, etc), and visual bounds 
// @param idx {long} the break index
// @returns {long[]} the snapped point
.z.m.gg.interact.i.rollover.axisPoint:{[pt; axis; idx]
    p : proj.proj[axis[`scale]`limits; axis`bounds; axis[`scale][`breaks] idx];
    : $[`yaxis ~ axis`axis;
        (pt 0; sum[axis`bounds] - p);
        (p; pt 1)];
    }

// @fileOverview 
// Return the data associated with all layers whose canvas' bound the pt
// @param pt {(number;number)} pixel coordinate 
// @param gg {dict} displayed GG object
// @returns {dict|null} data and point associated with the pixel
.z.m.gg.interact.i.rollover.plots:{[pt; gg]
    
    opts      : ``filter!(::; 1b);
    hitLayers : spec.pluck[`defn] interact.i.hitLayerComponents [pt; gg; opts];
    
    if [0 = count hitLayers; : (::)];
    
    ps   : interact.i.normalizePt [pt; gg; opts];
    
    isPolar: coords.polar.label ~ first[hitLayers][`coord]`label;
    
    ps   : {[lyr;pt] lyr[`coord][`inverseF] pt }'[hitLayers;ps];
    fs   : h.atAll[`rolloverF] h.atAll[`geom] hitLayers;
    idx  : where not h.null each fs;
    data : h.applyeach[fs idx] h.atAll[idx] (ps; h.atAll[`transformed;hitLayers]; hitLayers);
  
    data[;`data]: @[;;]'[hitLayers@\:`onclick; data@\:`data;{{-1 "error in rollover callback: ",y;x}x} each data@\:`data];
    
    data: ([]geom: (h.atAll[`label] h.atAll[`geom] hitLayers) idx) ,' data;
    
    r : interact.i.fmtRecords interact.i.limitRecords each data;
    
    if [0 < count r;
        r[`pt]: $[isPolar; count[r]#enlist pt; interact.i.invNormalizePt[pt; gg; r`pt; opts]];
        r: `distance xasc select from r where not data ~\: 0b];
    
    : $[r ~ (); ::; r]
    
    }

// @fileOverview 
// Given bounds and a point, snap the point to the bounds
// @param bs {( (number;number); (number;number) )} bounds - `((xmin; xmax), (ymin; ymax))`
// @param p {(number;number)} point - `(x, y)`
// @returns {(number;number)} bounded point
// @example
//      .z.m.gg.interact.i.snap[ ((1 2);(0 2)); 0 3 ]
.z.m.gg.interact.i.snap:{[bs; p]
    x : p 0;
    y : p 1;
    xbounded : x within bs 0;
    ybounded : y within bs 1;

    : $[xbounded and ybounded;
                p;
        xbounded and not ybounded;
                $[y < bs[1;0]; (x; bs[1;0]); (x; bs[1;1])];
        ybounded and not xbounded;
                $[x < bs[0;0]; (bs[0;0]; y); (bs[0;1]; y)];
                $[ (x > bs[0;1]) and y > bs[1;1];   bs[;1];
                   (x > bs[0;1]) and y < bs[1;0];   (bs[0;1]; bs[1;0]);
                   (x < bs[0;0]) and y > bs[1;1];   (bs[0;0]; bs[1;1]);
                                                      bs[;0]]];
    
    }

// @fileOverview Update layers with shared scale specs. Each participating
// layer to a currently-zoomed layer will also be zoomed to prime the data 
// for sharing when processing
// @param sp {table} gg spec 
// @param p1s {(float;float)} first normalized pixel 
// @param p2s {(float;float)} second normalized pixel
// @param nodes {table} subset of the `sp` corresponding to zoomed layers 
// @param shares {dict} specification of share dependencies *between* all layers
// @returns {table} updates layer nodes
// @see gg.i.init.sharedScales
.z.m.gg.interact.i.updateSharedScales:{[sp; p1s; p2s; nodes; shares]
    shareMap  : raze flip each {(y;count[y]#enlist x)} .' flip (key;value)@\:shares;
    toProcess : shareMap where shareMap[;0] in nodes`id;
    
    setShares: {[shares; shareMap; p1s; p2s; sp; pair]
        share : pair 1;
        : spec.i.sharedNodes[sp; shares[share] except pair 0; {::};
            {[k;p1s;p2s;state;lyr]
                idx: geom.fromBound1D[k; k; p1s; p2s; lyr`data; lyr`aes; lyr`scales; lyr];
                @[lyr;`data;:;tbl.rindex[lyr`data; idx]]
                }[share 1; p1s; p2s];
            {spec.node.item y}]
        };
    
    : select from spec.every[spec.ty.layer]
        sp setShares[shares; shareMap; first p1s; first p2s]/toProcess
        where id in (raze shares last each toProcess) except first each toProcess
    }

// @fileOverview
// Process a rollover interaction on a GG. All layers under the point clicked are
// processed separately, and the results combined.
// @param pt {(number;number)} a pixel coordinate 
// @param gg {dict} a displayed GG object
// @returns {dict} dictionary of geometries and their associated data
.z.m.gg.interact.rollover:{[pt; gg]
    axes   : interact.i.rollover.axes  [pt; gg];
    points : interact.i.rollover.plots [pt; gg];
    : `axes`points!(axes; points);
    }

// @fileOverview 
// Given two pixel coordinates and a displayed GG object, return a new specification
// with layer data replaced by data contained within the two pixels.
// Note - only the first point determines the CANVAS. The second point is snapped 
// to each canvas chosen by the first.
// @param px1 {(number;number)} pixel coordinate 
// @param px2 {(number;number)} pixel coordinate 
// @param gg {dict} GG object
// @returns {table} specification table
.z.m.gg.interact.zoom:{[px1; px2; gg]
    : spec.updateSpec[gg`spec] interact.zoomedLayers[px1; px2; gg`spec];
    }

// @fileOverview
// Given two pixel coordinates and a displayed GG spec tree, return a list of zoomed layers
// with layer data replaced by data contained within the two pixels.
// Note - only the first point determines the CANVAS. The second point is snapped 
// to each canvas chosen by the first.
// @param px1 {(number;number)} pixel coordinate 
// @param px2 {(number;number)} pixel coordinate 
// @param sp {table} display specification tree
// @returns {table} list of updated layer nodes
// TODO - decompose...
.z.m.gg.interact.zoomedLayers:{[px1; px2; sp]

    hitLayers: $[1 = count distinct layers: .z.m.gg.spec.every[.z.m.gg.spec.ty.layer] sp;
        layers;
        spec.layersFromPt [px1; sp]];

    if [0 = count hitLayers;
        '.z.m.axlocalize.t`.gg_clickBoundsError];
    
    pHitLayers: hitLayers pIdx: where not layer.isSecondary each spec.pluck[`defn] hitLayers;
    
    hitGeoms: first each h.atAll[`geom] spec.pluck[`frame] pHitLayers;
    px1  : interact.i.snap[spec.toBounds first hitGeoms; px1];      // <-- convert geom frame to bounds
    px2s : interact.i.snap[; px2] each spec.toBounds each hitGeoms; // <-- convert geom frame to bounds
    
    rescale : {[pt;g] proj.proj[;0 1]'[(::;reverse) @' spec.toBounds g;pt]};
    p1s: rescale[px1] each hitGeoms;
    p2s: rescale'[px2s;hitGeoms];
    
    hitDefns: spec.pluck[`defn] pHitLayers;
    p1s: (hitDefns .\: `coord`inverseF) @' p1s;
    p2s: (hitDefns .\: `coord`inverseF) @' p2s;
    
    zoomFs    : interact.i.getZoomFs hitDefns;
    zoomedIdx : where not h.null each zoomFs[;1];
    
    indices: h.applyeach[zoomFs[zoomedIdx][;1]] h.atAll[zoomedIdx]
        (p1s; p2s; hitDefns@'`data; hitDefns@'`aes; hitDefns@'`scales; hitDefns);

    updatedDefns: @[;`data;:;]'[hitDefns zoomedIdx] tbl.rindex'[h.atAll[`data] hitDefns zoomedIdx; indices];
    updatedNodes: spec.update[`defn; updatedDefns] pHitLayers zoomedIdx;
    
    (updatedDefns@\:`ondrilldown) @' .z.m.gg.h.atAll[`data] updatedDefns;
    
    hitLayers[pIdx zoomedIdx]: updatedNodes;
    
    if [0 <> count shares: spec.shareMap sp;
        hitLayers : hitLayers , interact.i.updateSharedScales[sp; p1s; p2s; hitLayers; shares]];
    
    : hitLayers;
    
    }

.z.m.gg.interact.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip
            enlist
            (`.gg_clickBoundsError; "The first click must be within the bounds of some non-empty canvas"))
      
.z.m.gg.interact.i.MAXRECORDS:10
system "d .z.m";

system "d .z.m.axrch";
.z.m.axrch.add:{[cache; parent; item]
    
    id: rand 0Ng;
    
    cache upsert enlist[id]!enlist itemD.new (parent; 0; item);
    
    {[c; id] 
        c upsert enlist[id]!enlist itemD.with.watchers[watchers[c;id]+1] c id   
        }[cache] each chain[cache] id;
    
    : id;

    }

.z.m.axrch.chain:{[cache; id]    
    f : {[c; f;x] 
        $[null p:itemD.parent c[x]; x; x,f[f] p] 
        }[cache];
    : f[f] id;
    }

// @qlintsuppress UNUSED_PARAM(1) MISSING_OVERVIEW(1) MISSING_RETURNS(1) UNDOCUMENTED_PARAM(1)
.z.m.axrch.clear:{[cache; x]
    : cache set (`guid$())!();    
    }

// @qlintsuppress UNUSED_PARAM(1) MISSING_OVERVIEW(1) MISSING_RETURNS(1) UNDOCUMENTED_PARAM(1)
.z.m.axrch.create:{[cache; x]
    : cache set enlist[0Ng]!enlist itemD.new (0Ng; 0; (::));
    }

// @fileOverview
// Removes an entry regardless of the number of watchers
//
// @param cache {symbol}
// @param id    {guid} item to remove
.z.m.axrch.destroy:{[cache; id]
    deleted: k where id = k:key cache;
    cache set deleted _ get cache;
    : deleted;
    };
.z.m.axrch.entry:{[cache; id]
    if [not id in key cache;
        '"Cannot find entry with id ",string id]; /dnl
    
    : itemD.entry cache[id]
    }

.z.m.axrch.has:{[cache; id]
    : id in key cache
    }

.z.m.axrch.modify:{[cache; id; item]
    : cache upsert enlist[id]!enlist itemD.with.entry[item] cache[id];
    }

.z.m.axrch.new:{[cache; item]
    
    id : rand 0Ng;
    cache upsert enlist[id]!enlist itemD.new (0Ng; 1; item);
    : id;
    
    }

.z.m.axrch.remove:{[cache; id]
    if [not id in key cache;
        '"Cannot find entry with id ",string id]; /dnl
    
     {[c; id] 
        c upsert enlist[id]!enlist itemD.with.watchers[watchers[c;id]-1] c id;
        }[cache] each chain[cache] id;
    
    cache set (deleted:k where cache[k:key cache][`watchers] = 0) _ get cache;
    
    if [0 = count key cache;
        clear[cache;::]];
    
    : deleted;
    }

// @qlintsuppress UNUSED_PARAM(1) MISSING_OVERVIEW(1) MISSING_RETURNS(1) UNDOCUMENTED_PARAM(1)
.z.m.axrch.reset:{[cache; x]
    create[cache] clear[cache](::)
    }

// @fileOverview
// Increments the number of watchers on an item
// @param cache {symbol} 
// @param id    {guid}   id of item
.z.m.axrch.watch:{[cache; id]
    cache upsert enlist[id]!enlist itemD.with.watchers[watchers[cache;id]+1] cache id   ;
    : id;
    }

.z.m.axrch.watchers:{[cache; id]
    if [not id in key cache;
        '"Cannot find entry with id ",string id]; /dnl
    
    : itemD.watchers cache[id]
    }

.z.m.axrch.onLoad:{[]
    .z.m.axdatatype.create[ .z.M.axrch.itemD; `parent`watchers`entry; `watchers`entry];
    }

.z.m.axrch.onLoad[];
system "d .z.m";

system "d .z.m.gg";
.z.m.gg.cachei.onLoad:{[]

    .z.m.axutl.injeqt.injeqt[enlist[`cache]!enlist enlist .z.M.gg.cache.Cache; .z.M.axrch; .z.M.gg.cache];
    }

.z.m.gg.cachei.onLoad[];
system "d .z.m";

system "d .z.m.gg";
// @fileOverview 
// Clear a single cache entry
// @param id {guid}
// @returns {dict} web response
.z.m.gg.web.clear:{[id]
    id : .z.m.axq.asGUID id;
    if [not cache.has id; '.z.m.axlocalize.t`.gg_unmanagedError];
    :`error`errorMessage`data!(`;"";cache.remove id);
    }

// @fileOverview 
// Creates a new graph that is zoomed in on a given graph
//
// @param w     {long}          graph width
// @param h     {long}          graph height
// @param p1    {(long;long)}   first bound point 
// @param p2    {(long;long)}   second bound point
// @param id    {guid}          id of graph being resized
//
// @returns {dict} web response that includes the id and rendered gg of the new graph
.z.m.gg.web.drilldown:{[w; h; p1; p2; id]
    zoomed: web.i.zoom[w;h;p1;p2;id];
    out: zoomed `gg;
    return: `id`img`dimensions!(zoomed `id; .z.m.gg.h.b64 outputD.bytes out`output; (outputD.w out`output; outputD.h out`output));
    : `error`data`errorMessage!(`; return; "")
    }


// @fileOverview 
// Returns the parent of a graph
//
// @param cacheID {guid} the ID of the graph who's parent is being retrieved 
//
// @returns {dict} web response containing the parent gg
.z.m.gg.web.drillup:{[cacheID]
    childID : .z.m.axq.asGUID cacheID;
    if [not cache.has childID; '.z.m.axlocalize.t`.gg_unmanagedError];
    
    parentID: .z.m.axrch.itemD.parent cache.Cache childID;
    childOut: cache.entry[childID]`output;
    parentOut: cache.entry[parentID]`output;
    hasParent: not 0Ng = .z.m.axrch.itemD.parent cache.Cache parentID;
    
    img: $[all (=).' (outputD.w;outputD.h) @/:\: (parentOut;childOut);
            .z.m.gg.h.b64 outputD.bytes parentOut;
            web.resize[outputD.w childOut;outputD.h childOut;parentID] . `data`output`bytes
        ];
    return: `id`img`dimensions`hasParent!( parentID; img; (outputD.w childOut; outputD.h childOut); hasParent);
    cache.remove childID;
    : `error`data`errorMessage!(`; return; "")
    }
// @param source {string} 
// @param mapping {dict} 
.z.m.gg.web.fromDSL:{[source; mapping]
            
    tbls : @[value; ; {'.z.m.axlocalize.t[`.gg_dslErrorPre],x}] each mapping;
    gg   : .z.m.gg.dsl.eval[tbls] .z.m.gg.dsl.parse source;
    id   : .z.m.gg.cache.new gg;
    .z.m.gg.ax.push[id; gg];
    : `error`errorMessage`data!(`;"";::)
    
    }

// @fileOverview 
// Creates a new graph that is zoomed in on a given graph
//
// @param w     {long}          graph width
// @param h     {long}          graph height
// @param p1    {(long;long)}   first bound point 
// @param p2    {(long;long)}   second bound point
// @param id    {guid}          id of graph being resized
//
// @returns {dict} the id and rendered gg of the new graph
.z.m.gg.web.i.zoom:{[w; h; p1; p2; id]
    id : .z.m.axq.asGUID id;
    if [not cache.has id; '.z.m.axlocalize.t`.gg_unmanagedError];
    zoomed : interact.zoom[p1; p2; cache.entry id];
    gg     : display[w; h; new zoomed];
    tid    : cache.add[id; gg];
    : `id`gg!(tid; gg)
    }

// @fileOverview 
// Resize a GG visual from a cache entry
// @param w {long} 
// @param h {long} 
// @param id {guid} 
// @returns {dict} 
.z.m.gg.web.resize:{[w; h; id]
    
    id : .z.m.axq.asGUID id;
    if [not cache.has id; '.z.m.axlocalize.t`.gg_unmanagedError];
    
    gg   : cache.entry id;
    dims : 0^(w;h);
    
    if[not (::) ~ gg `output;
        dims : 0^gg[`output][`w`h] ^ (w;h)];
    
    gg[`spec]: spec.with.theme[theme.default] gg`spec;
    
    cache.modify[id; resize[dims 0; dims 1; gg]];
    
    gg     : cache.entry id;
    parent : .z.m.axrch.itemD.parent .z.m.gg.cache.Cache id;
    
    : `error`data`errorMessage!(`; `output`id`parent!(@[;`bytes;.z.m.gg.h.b64] .z.m.gg.ty.output gg; id; $[.z.m.axq.isNull parent; ::; parent]); "");
    
    }

// @fileOverview 
// Rollover
// @param pt {(long;long)} 
// @param id {guid}
// @returns {dict} web response
.z.m.gg.web.rollover:{[pt; id]
    id : .z.m.axq.asGUID id;
    if [not cache.has id; '.z.m.axlocalize.t`.gg_unmanagedError];
    : `error`data`errorMessage!(`; interact.rollover[pt; cache.entry id]; "");
    }

// @fileOverview 
// Creates and pushes a new graph that is zoomed in on a given graph
//
// @param w     {long}          graph width
// @param h     {long}          graph height
// @param p1    {(long;long)}   first bound point 
// @param p2    {(long;long)}   second bound point
// @param id    {guid}          id of graph being resized
//
// @returns {dict} web response 
.z.m.gg.web.zoom:{[w; h; p1; p2; id]
    zoomed: web.i.zoom[w;h;p1;p2;id];
    ax.push[zoomed `id; zoomed `gg];
    : `error`data`errorMessage!(`; ::; "");
    }

.z.m.gg.web.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.gg_unmanagedError; "Cannot interact with unmanaged plot");
        (`.gg_dslErrorPre; "Error evaluating table argument: ")))
system "d .z.m";

system "d .z.m.gg";
// @subcategory Dashboard Utilities
// @fileOverview 
// Take an environment of parameter names to tables, as well as an hsym
// to a GG file, or a string of GG DSL, and return a table pointing to 
// a managed GG object for use within Dashboards
// @returns {table}
// @example
// .z.m.gg.dash.dsl[()!()] `:image.gg
.z.m.gg.dash.dsl:{[e; f]
    gg : .z.m.qp.dsl[e] f;
    id : .z.m.gg.cache.new gg;
    : ([] id : enlist id)
    }

// @subcategory Dashboard Utilities
// @fileOverview 
// Return the ID for a GG object ready for Dashboards.
//
// Used for integrating Analyst visuals with HTML5 dashboards. See examples for use.
// @param s {table} GG specification table 
// @returns {table} table containing the cache ID 
// @example Analyst visual within Dashboards
// // Place the following within a Analyst widget Data Source
// .z.m.gg.dash.go .z.m.qp.theme[.z.m.gg.dash.dark] .z.m.qp.point[([]x:til 45); `x; `x; ::]
.z.m.gg.dash.go:{[s]
    g : .z.m.gg.i.display .z.m.gg.new s;
	id : .z.m.gg.cache.new g;
    : ([] id : enlist id)
    };
// @subcategory Dashboard Utilities
// @private
// @fileOverview 
// Resize a GG cache entry for Dashboards. Returns the resized image info and whether or
// not the GG cache object has a parent.
// @param w {long} 
// @param hh {long} 
// @param id {guid} 
// @returns {table} 
.z.m.gg.dash.resize:{[w;hh;id]
	id  : .z.m.axq.asGUID id;
	r   : .z.m.gg.web.resize[w;hh;id];
    out : r[`data]`output;
    out[`bytes]: out`bytes;
    hasParent  : 1 < count .z.m.gg.cache.chain id;
    : ([]w:enlist out`w; h:enlist out`h; bytes: enlist out`bytes; id : enlist id; hasParent: enlist hasParent);
    };
// @subcategory Dashboard Utilities
// @private
// @fileOverview 
// Rollover
// @param pt {(number;number)} 
// @param id {guid}
// @returns {dict} web response
.z.m.gg.dash.rollover:{[pt; id]
    id : .z.m.axq.asGUID id;
    if [not cache.has id; '.z.m.axlocalize.t`.gg_unmanagedError];
    : interact.rollover[pt; cache.entry id];
    }
// @private
// @subcategory Dashboard Utilities
// @fileOverview 
// Drilldown for a Dashboards GG object
// @param p1 {(number;number)} first point of the bounds 
// @param p2 {(number;number)} second point of the bounds 
// @param id {guid} cache ID 
// @returns {table} table with the resulting GG cache object 
.z.m.gg.dash.zoom:{[p1;p2;id]
    id     : .z.m.axq.asGUID id;
    if [not .z.m.gg.cache.has id;  '.z.m.axlocalize.t`.gg_unmanagedError];
    zoomed : .z.m.gg.interact.zoom[p1; p2; .z.m.gg.cache.entry id];
    r      : .z.m.gg.i.display .z.m.gg.new zoomed;
    tid    : .z.m.gg.cache.add[id; r];
    : ([]id : enlist tid);
    };
.z.m.gg.dash.light:.z.m.gg.theme.default , (!) . flip (
    (`canvas_fill; 0xffffffff);
    (`plot_background_fill; 0xffffffff);
    (`grid_majorLine_fill; 0x4da0a0a0);
    (`grid_majorLine_strokewidth; 1);
    (`grid_minorLine_fill; 0x00000000);
    (`axis_line_fill; 0xff222222);
    (`axis_tick_label_fill; 0xff222222);
    (`axis_label_fill; 0xff222222);
    (`marker_default_fill; .z.m.gg.colour.SteelBlue);
    (`title_fill; 0xff222222);
    (`legend_header_background_fill; 0x00000000);
    (`title_fontsize; 15);
	(`axis_tick_length_x; 0);
	(`axis_tick_length_y; 0)
    );

.z.m.gg.dash.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.gg_numeric; "numeric");
        (`.gg_temporal; "temporal");
        (`.gg_unmanagedError; "Cannot interact with unmanaged plot")))
.z.m.gg.dash.dark:.z.m.gg.theme.default , (!) . flip (
    (`canvas_fill; 0xff303030);
    (`plot_background_fill; 0x00000000);
    (`grid_majorLine_fill; 0x4da0a0a0);
    (`grid_majorLine_strokewidth; 1);
    (`grid_minorLine_fill; 0x00000000);
    (`axis_line_fill; 0xffffffff);
    (`axis_tick_label_fill; 0xffffffff);
    (`axis_label_fill; 0xffffffff);
    (`marker_default_fill; .z.m.gg.colour.SteelBlue);
    (`title_fill; 0xffffffff);
    (`legend_header_background_fill; 0x00000000);
    (`title_fontsize; 15);
	(`axis_tick_length_x; 0);
	(`axis_tick_length_y; 0)
    );

system "d .z.m";

system "d .z.m.axds";
.z.m.axds.qtree.i.contains:{ (y[;0] within x 0 2) & y[;1] within x 1 3 }


.z.m.axds.qtree.new:{[maxlvl; bounds; points]
    
    make: {[m;l;k;p;b]
        c: where qtree.i.contains[b] p; 
        d: %[;2] (-) .' 2 0N#b 2 0 3 1;
        r: (rand 0ng; l; b; count c; 2*d 0;sum[p c]%count c),4#0ng;
        $[0 = count c; : (); (1 = count c)|l = m; : enlist r; ::];
        q: .z.s[m;l+1;k c;p c] peach b +/: ((0;d 1;neg d 0;0); (d 0;d 1;0;0); (0;0;neg d 0;neg d 1); (d 0;0;0;neg d 1));
        : raze[q] , enlist[@[r;6 7 8 9;:;{ $[not () ~ x; last[x]0; 0ng] } each q]] };
    
    r: update `u#id from flip`id`lv`bs`ps`w`c`ne`nw`se`sw!flip make[maxlvl; 0; key points; value points; bounds];
    
    d: (`u#r`id)!til count r;
    : update id:value d, d ne, d nw, d se, d sw from r;
    
    } 

// @fileOverview Return the root of a quadtree
// @returns {dict} root of the tree
.z.m.axds.qtree.root:{ last x }

// @fileOverview Search a quad tree
// @param m {long} max depth 
// @param qt {table} quad tree to search 
// @param n {dict} node to search from 
// @param p {any} 
// @param f {fn} search function 
// @returns {any[]} ids of found nodes
.z.m.axds.qtree.search:{[m;qt;n;p;f]
    if [(1 = n`ps)|m = n`lv; : n`id];
    if [f[qt;n]; : n`id]; 
    : raze .z.s[m;qt;;p;f] each qtree.sel[qt;n]
    }
.z.m.axds.qtree.sel:{ x y[`ne`nw`se`sw] except 0N }

system "d .z.m";

system "d .z.m.qp";

.z.m.qp.network.format:{[t;c]
    if [any not c in .z.m.gg.tbl.colnames t; '"Not all columns found within table"];
    
    t: ?[t; (); (1#c 0)!1#c 0; (1#c 1)!enlist(raze;c 1)];
    
    ty: .z.m.gg.tbl.metatype[t] each c;

    colformat: { (x ~ lower y) & y ~ upper x } . ty;
    if [(~) . c; '"Child column cannot be the same as the ID column"];
    if [not[colformat] & 0 <> count t; '"Child column must be lists of the same type as the ID column"];
    
    t:   ?[t;();0b;c!(c 0; ($; first ty; c 1))];
    ids: (distinct t[c 0],raze t c 1) except t c 0;
    : t , flip c!(ids; type[ids]$count[ids]#enlist ());
    }

.z.m.qp.network.i.aggregate:{[o;s;t;c;p;d]
    vecs: d (key[p]!til count p) k:t c 0;
    magn: network.i.mag flip vecs;
    norm: 0^vecs % magn;
    maxd: o[`maxdist][s;p];
    
    : @[p;k;+;norm*maxd&magn]
    }

.z.m.qp.network.i.attract:{[o;t;c;p]
    ii: key[p]!til count p;
    
    p2: {[o;p;c;x]
        if [0 = count p x c 1; : 0];
        : (sum;::)@\:0^{ (y%m) * x[`fa][x] m:network.i.mag y }[o] each 0^p[x c 0] -/: p x c 1
        }[o;p;c] peach t;
    
    v: where not 0 = count each t c 1;
    e: count[p]#enlist 0 0f;
    : $[0 = count v; e; @[;;;]/[e; ii t[c]@\:v; (-;+); flip p2 v]];
    }

// note - unused search variable y
// r is quad tree record
.z.m.qp.network.i.barneshut:{[o;p;y;r] o[`theta] >= r[`w]%network.i.mag p - r`c }
.z.m.qp.network.i.coarsen:{[t;c]
    n: t[c 0]!network.i.neighbors[t;c];
    h: 2 {[n;x] distinct each raze each x,'n x }[n]/n;      // three-hop reachable
    v: network.i.indset[t;c];
    : flip c!(v; v where each v in/: h v);
    }
// Permutation-based independent set
.z.m.qp.network.i.indset:{[t;c]
    build: {[t;c;a;v]
        if [0 = count v; : a];
        n: v!network.i.neighbors[t;c] where t[c 0] in v;
        n: (n inter\: v)except'v;
        w: p where til[count p] < min each p?n p: neg[count v]?v;
        e: v except w,raze n w;
        : .z.s[t;c;a,w;e] };
    
    : build[t;c;();t c 0]
    }

// Initialize options dictionary
.z.m.qp.network.i.init:{[o;t;x;y]
    n: count t;
    e: (!). 1#'(`;::);
    o: $[(::) ~ o; e; o,e];
    o: o,k!?[k in key o; o k:key network.i.DEF; value network.i.DEF];    // inherit defaults
    if [network.i.isfunc o`repulse; o[`repulse]: o[`repulse]t];
    if [network.i.isfunc o`pos; o[`pos]: o[`pos][t;x]];
    if [network.i.isfunc o`k; o[`k]: o[`k][network.i.width o`pos;n]];
    : o
    }

.z.m.qp.network.i.isfunc:{[x] type[x] in 100 103 104h }

.z.m.qp.network.i.layout:{[t;x;y;o]
    n: count t;
    if [1 >= n; : network.i.withedges[x,y] flip (x,y,`px__`py__)!(t x; t y; 0f; 0f)];
    
    o[`pos]: o[`pos]+1_count[o`pos]{ {(x%16)+1_2 rand\x%8} network.i.width y }[;0^o`pos]\`;
    r: o[`ticks] network.i.tick[network.i.repulse o`repulse;o;t;x,y]/o`speed`pos;
    
    : network.i.withedges[x,y] ![t; (); 0b; (x,y,`px__`py__)!(x; y; (r 1;x;0); (r 1;x;1) )];

    }
.z.m.qp.network.i.mag:{ sqrt sum x * x }


.z.m.qp.network.i.multilevel:{[t;x;y;o]
    o : network.i.init[o;t;x;y];
    cc: c where ii:0 < count each c:network.i.coarsen[t;x,y];
    
    if [0 < count where not ii; '"Nodes cannot be removed from coarse graph"]; // TODO - disconnected graphs
    if [(5 > count t)|2 > count cc; : network.i.layout[t;x;y;o]];
    if [count[t] = count cc; : network.i.layout[t;x;y;o]];
    
    cl: .z.s[cc; x; y; o];           // coarse layout
    tt: network.i.refine[t; cl; x,y];  // refined graph
    
    : network.i.layout[t; x; y; o,``pos!(::; ?[tt; (); x; (first;(,';`px__;`py__))])]
    }

.z.m.qp.network.i.neighbors:{[t;c] t[c 1] ,' network.i.parents[t;c] }

.z.m.qp.network.i.parents:{[t;c] t[c 0] { where y in/: x }[t c 1] each t c 0 }


.z.m.qp.network.i.refine:{[t;cl;c]
    v: t lj c[0] xkey ?[cl; (); c[1#0]!1#c 0; `px__`py__!( (first;`px__); (first;`py__) )];
    u: v[c 0] where null v`px__;  // unpositioned nodes
    n: distinct each t[c 0]!network.i.neighbors[t;c];
    p: ?[cl;();c 0;(first;(,';`px__;`py__))] n[u] inter\: cl c 0;
    p[e]: count[e:where 0 = count each p]#enlist enlist 0 0f;
    v[v[c 0]?u;`px__`py__]: avg each 0f^p;
    : network.i.withedges[c] delete ppx__, ppy__ from v
    }

.z.m.qp.network.i.tick:{[repulseF;o;t;c;r] // r is (speed; positions)
    r: (r[0]*o`decay;
        network.i.aggregate[o;r 0;t;c;p] network.i.attract[o;t;c]
            p: network.i.aggregate[o;r 0;t;c;p] repulseF[o] p: r 1);

    if [o`animate;
        ret: network.i.withedges[c] ![t; (); 0b; (c,`px__`py__)!(c 0; c 1; (r 1;c 0;0); (r 1;c 0;1) )];
        .z.m.qp.managed[`$"network-layout";500;500]
            .z.m.qp.theme[.z.m.gg.theme.blank , ``legend_use!(::;0b)]
             .z.m.qp.stack (
                .z.m.qp.segment[ret; `px__; `py__; `ppx__; `ppy__]
                    .z.m.qp.s.geom ``alpha!(::;0x8f);
                .z.m.qp.point[ret; `px__; `py__]
                    .z.m.qp.s.geom ``size!(::;3));
        system"usleep 300"];
    
    : r;
    }
 

.z.m.qp.network.i.width:{[p] (-).(max;min)@\:p[;0] }
// Add parent x and y coordinates to each record of ungrouped t
.z.m.qp.network.i.withedges:{[c;t]
    e: ?[t; enlist(=;0;(each;count;c 1)); 0b; (c,`px__`py__)!(c 0;(each;first;c 1);`px__;`py__)];
    d: ?[t; (); c 0; `px__`py__!((first; `px__);(first;`py__))];
    : ![e,ungroup t;();0b;`ppx__`ppy__!(((d; c 1);1#`px__); ((d; c 1);1#`py__))]
    }

.z.m.qp.network.layout:{[t;x;y;o]
    
    t: update index__: i from 0!t;
    
    isNested: {(x~lower x) & y~upper x} . .z.m.gg.h.metatype[t] each (x;y);
    
    toLayout:
        $[(98h ~ type t) & isNested & not 1 = count .z.m.gg.tbl.colnames t;
            x xkey t;
        (98h ~ type t) & not[isNested] & 2 < count .z.m.gg.tbl.colnames t;
            (x;y) xkey t;
            t];
    
    r: network.i.multilevel[0!network.format[0!toLayout;x,y];x;y;o];
    
    dropped: cols[0!toLayout] except (x;y;`px__;`py__;`ppx__;`ppy__);
    
    if [0 < count dropped;
        k: $[99h ~ type toLayout;
            $[not[isNested] and all (x;y) in cols key toLayout; (x;y); raze x];
            (x;y)];
         r: r lj k xkey (dropped#0!toLayout) ,' k#0!toLayout];
    
    : r;
    }
.z.m.qp.network.i.repulse:`FruchtermanReingold`BarnesHut!(
    
    {[o;p]
        : {[o;p;x] sum 0^(d%m)*o[`fr][o] m:network.i.mag flip d:p[x]-/:value p }[o;p] peach key p
        };

    {[o;p]
        qt: .z.m.axds.qtree.new[o`maxdepth; raze flip (min;max)@\:/:flip value p; p];
        : {[qt;o;p;x]
            ii: .z.m.axds.qtree.search[o`maxdepth; qt; .z.m.axds.qtree.root qt; p x; network.i.barneshut[o;p x]];
            : sum 0^(d%m)*qt[`ps][ii]*o[`fr][o] m:network.i.mag flip d:p[x] -/:qt[`c] ii;
            }[qt;o;p] peach key p
        }
     
    )
.z.m.qp.network.i.DEF:(!) . (`u#;::) @' flip (
    (`;         ::);
    (`decay;    .96);
    (`speed;    2.5);
    (`ticks;    50);
    (`c;        1000);
    (`maxdepth; 4);
    (`repulse;  {[t] $[400 > count t; `FruchtermanReingold; `BarnesHut] });
    (`fr;       {[o;m] o[`c]*o[`k]*o[`k]%.5*m });
    (`fa;       {[o;m] 5*m*m%o`k });
    (`k;        {[w;n] w*w%sqrt 1+n });
    (`pos;      {[t;x] ?[t;();x;enlist,2#enlist(+;-250;(rand;500f))] });
    (`maxdist;  {[s;p] s * network.i.width[p] % 15 });
    (`theta;    1.2);
    (`animate;  0b)
    )
system "d .z.m";

system "d .z.m.qp";
.z.m.qp.tree.i.ancestor:{[g;vil;v;da]
    $[g[vil;`a] in g[first g[v;`parents]]`children; g[vil;`a]; da]
    }
.z.m.qp.tree.i.apportion:{[da;r;g]
    l: tree.i.left[g;r];
    if [not null l; : tree.i.inner[da;r;g;l]];
    (da;g)
    }
.z.m.qp.tree.i.executeShifts:{[g;v]
    sh: 0;
    c: 0;
    last(c;sh;g){[a;w]
        c: a 0;
        sh: a 1;
        g: a 2;
        g[w;`p] +: sh;
        g[w;`m] +: sh;
        c +: g[w;`c];
        sh +: g[w;`s] + c;
        (c;sh;g)
        }/reverse g[v]`children
    }
.z.m.qp.tree.i.firstwalk:{[g;r]
    if [tree.i.isleaf[g;r];
        g[r;`p]: $[not null tree.i.leftmostSibling[g;r]; tree.i.D + g[tree.i.left[g;r];`p]; 0f];
        : g];
    
    da: first g[r]`children; // default ancestor
    
    g: last(da;g){[f;a;r]
        da: a 0;
        g: a 1;
        g: f[g;r];
        : tree.i.apportion[da;r;g];
        }[.z.s]/g[r]`children;
    
    g: tree.i.executeShifts[g;r];
    
    m: .5 * g[first g[r]`children;`p] + g[last g[r]`children;`p];
    l: tree.i.left[g;r];
    
    $[not null l;
        [   g[r;`p]: g[l;`p] + tree.i.D;
            g[r;`m]: g[r;`p] - m];
        g[r;`p]: m];
    
    g
    }
.z.m.qp.tree.i.inner:{[da;r;g;l]
    vir:vor:r;
    vil:l;
    vol:tree.i.leftmostSibling[g;r];
    sir:g[r;`m];
    sor:g[r;`m];
    sil:g[vil;`m];
    sol:g[vol;`m];
    while [(not null tree.i.nextRight[g;vil])& not null tree.i.nextLeft[g;vir];
        vil:tree.i.nextRight[g;vil];
        vir:tree.i.nextLeft[g;vir];
        vol:tree.i.nextLeft[g;vol];
        vor:tree.i.nextRight[g;vor];
        g[vor;`a]:r;
        sx:tree.i.D+(g[vil;`p]+sil)- g[vir;`p]+sir;
        if [sx > 0;
            g: tree.i.moveSubtree[g; tree.i.ancestor[g;vil;r;da]; r; sx];
            sir +: sx;
            sor +: sx];
        sir+:g[vir;`m];
        sor+:g[vor;`m];
        sil+:g[vil;`m];
        sol+:g[vol;`m]];
    $[(not null tree.i.nextRight[g;vil])&null tree.i.nextRight[g;vor];
        [
            g[vor;`t]: tree.i.nextRight[g;vil];
            g[vor;`m] +: sil - sor];
    [   $[(not null tree.i.nextLeft[g;vir])&null tree.i.nextLeft[g;vol];
        [
            g[vol;`t]: tree.i.nextLeft[g;vir];
            g[vol;`m] +: sir - sol]; ::];
        da: r]];
    (da;g)
    }
.z.m.qp.tree.i.isleaf:{[g;r] 0 = count g[r]`children }
.z.m.qp.tree.i.left:{[g;r] cs: g[first g[r]`parents]`children; cs -1+cs?r }
.z.m.qp.tree.i.leftmostSibling:{[g;r]
    c: first g[first g[r;`parents];`children];
    $[c=g[r;`id];0N;c]
    }
.z.m.qp.tree.i.moveSubtree:{[g;wl;wr;s]
    subtrees: g[wr;`n] - g[wl;`n];
    g[wr;`c] -: s % subtrees;
    g[wr;`s] +: s;
    g[wl;`c] +: s % subtrees;
    g[wr;`p] +: s;
    g[wr;`m] +: s;
    g
    }
.z.m.qp.tree.i.nextLeft:{[g;r] $[0 = count g[r]`children; g[r;`t]; first g[r]`children] }
.z.m.qp.tree.i.nextRight:{[g;r] $[0 = count g[r]`children; g[r;`t]; last g[r]`children] }
.z.m.qp.tree.i.secondwalk:{[g;d;m;r]
    g[r;`x]: g[r;`p] + m;
    g[r;`y]: d;
    g .z.s[;d+1;m+g[r;`m];]/g[r]`children
    }

.z.m.qp.tree.layout:{[t;id;children;o]

    if [o ~ (::); o : ()!()];
    o: (``inverty`addthreads!(::;0b;0b)) , o;
    
    t: ([] id: .z.m.gg.h.column[t;id]; children: .z.m.gg.h.column[t;children]);
    t[`parents]: t[`id]where each {y in/: x`children}[t] each t`id;
    
    ii: t[`id]!til count t;
    t: update ii id, ii children, ii parents from t;
    r: first where 0 = count each t`parents;
    
    t[`m`a`p`t`c`n`s`x`y]: (0f;t`id;0n;0N;0f;0;0f;0f;0f);
    t: {[g;n;r] g[r;`n]: n; .z.s/[g;1+til count g[r]`children;g[r]`children] }[t;1;r];

    t2: tree.i.firstwalk[t;r];
    t3: tree.i.secondwalk[t2;0f;neg t2[r;`m];r];
    nodes: ``parents`m`a`p`c`n`s _ t3;
    
    if [not o`inverty;
        nodes: update y: max[y]-y from nodes];
    
    edges: (`x`y _ update x2__:x,y2__:y from ungroup `id`children xkey ``parents _ nodes) lj `children xcol 1!`id`x`y#nodes;
    
    ii: value[ii]!key ii;
    nodes: (id;children) xcol `x`y _update ii id, ii children, x__:x, y__:y from nodes;
    edges: (id;children) xcol `x`y _update ii id, ii children, x__:x, y__:y from edges;
    
    ret: `nodes`edges!(nodes;edges);
    
    if [o`addthreads;
        ret[`threads]: (`x`y _ update x2__:x__,y2__:y__ from select from nodes where not null t) lj `t xcol 1!`t`x__`y__#nodes];
    
    ret[`nodes]: ``t _ ret`nodes;
    ret[`edges]: ``t _ ret`edges;
    
    ret
 
    }
 
.z.m.qp.tree.i.D:1
system "d .z.m";

system "d .z.m.qp";

// @param t {table} 
// @param x {symbol} Category/label column
// @param y {symbol} Numeric column
// @param o {dict|null} options 
// @returns {table} treemap rectangle positions keyed by their label
.z.m.qp.treemap.layout:{[t;x;y;o]
    if [(::) ~ o; o: ()!()];
    if [all `x__`x2__ in key o; o[`x2__] -: o`x__];
    if [all `y__`y2__ in key o; o[`y2__] -: o`y__];
    o: (``pad`x__`y__`x2__`y2__!(::;0b;0;0;100;100)) , o;
    o[`x`y`x2`y2]: o`x__`y__`x2__`y2__;
    f: $[o`pad;treemap.i.psquarify;treemap.i.squarify];
    t: y xdesc t;
    v: treemap.i.norm[t y;o`x2;o`y2];
    r: f[v] . o`x`y`x2`y2;
    : x xkey @[;x;:;t x] `x`y`x2`y2 _"f"$update x__:x, x2__: x+x2, y__:y, y2__:y+y2 from r
    }

// @private
.z.m.qp.treemap.onLoad:{[]
    treemap.i.norm:     { x*(y*z)%sum x };
    treemap.i.pad:      { if [2 < x`x2; x[`x] +: 1; x[`x2] -: 2]; if [2 < x`y2; x[`y] +: 1; x[`y2] -: 2]; x };
    treemap.i.layrow:   {[s;x;y;dx;dy] w:sum[s]%dy;first(();y){[xx;w;x;y](x[0],enlist `x`y`x2`y2!(xx;x 1;w;y%w);x[1]+y%w)}[x;w]/s };
    treemap.i.laycol:   {[s;x;y;dx;dy] w:sum[s]%dx;first(();x){[xx;w;x;y](x[0],enlist `x`y`x2`y2!(x 1;xx;y%w;w);x[1]+y%w)}[y;w]/s };
    treemap.i.lay:      {[s;x;y;dx;dy] $[dx>=dy;treemap.i.layrow;treemap.i.laycol][s;x;y;dx;dy] };
    treemap.i.lrow:     {[s;x;y;dx;dy] w:sum[s]%dy; (x+w;y;dx-w;dy) };
    treemap.i.lcol:     {[s;x;y;dx;dy] w:sum[s]%dx; (x;y+w;dx;dy-w) };
    treemap.i.left:     {[s;x;y;dx;dy] $[dx>=dy;treemap.i.lrow;treemap.i.lcol][s;x;y;dx;dy] };
    treemap.i.worst:    {[s;x;y;dx;dy] max {max (x[`x2]%x`y2;x[`y2]%x`x2)} each treemap.i.lay[s;x;y;dx;dy] };
    treemap.i.squarify: {[s;x;y;dx;dy]
        if [0 = count s; : ()];
        if [1 = count s; : treemap.i.lay[s;x;y;dx;dy]];
        ii: {[s;x;y;dx;dy;ii](ii<count s)&treemap.i.worst[s til ii;x;y;dx;dy]>=treemap.i.worst[s til ii+1;x;y;dx;dy]}[s;x;y;dx;dy](1+)/1;
        treemap.i.lay[ii#s;x;y;dx;dy],.z.s[ii _s] . treemap.i.left[ii#s;x;y;dx;dy] };
    treemap.i.psquarify: {[s;x;y;dx;dy] treemap.i.pad each treemap.i.squarify[s;x;y;dx;dy] };
    }

.z.m.qp.treemap.onLoad[];
system "d .z.m";

system "d .z.m.qp";
// @subcategory Hierarchical Visuals
// @fileOverview Layout for a hierarchical tree. 
// A stack tree layout. Output is x, y, x2, y2 coordinates for .z.m.qp.rect.
//
// Useful for weighted trees (trace timelines, etc). When used in polar coordinates,
// becomes a Sunburst Chart.
//
// Options:
//
// - [``` `expand ```] expand children to take entire width of the parent.
// - [``` `filldepth ```] depth at which children are assigned a colour (default 4).
// - [``` `colours ```] a list of 0xrrggbb colours to use when filling.
//
// @param t {table} table of a tree - should contain a scalar id column and a nested child column pointing to other ids 
// @param id {symbol} id column 
// @param children {symbol} children column 
// @param weight {symbol} weight (numeric) column 
// @param o {dict|null} options
// @returns {dict (nodes: table; edges: table)} Node and edges layout table
//
// @format .z.m.qp.i.qdformatter
//
// @example Basic layout
// 
//      t: .z.m.gg.cheat.i.assemble[];
//      t: update w:count each children from t;
// 
//      rr: .z.m.qp.treestack.layout[t;`id;`children;`w;``expand!(::;1b)];
// 
//     .z.m.qp.rect[rr;`x__;`y__;`x2__;`y2__] 
//         .z.m.qp.s.geom[``colour!(::;0xffffff)]
// 
// 
// @example Adding a fill and alpha scale
// 
//     .z.m.qp.theme[.z.m.gg.theme.blank , ``legend_use!(::;0b)]
//     .z.m.qp.rect[rr;`x__;`y__;`x2__;`y2__] 
//         .z.m.qp.s.geom[``colour!(::;0xffffff)] ,
//         .z.m.qp.s.aes[`fill`alpha; `id`d__] ,
//         .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat rr[`id]!rr`fill__]
// 
// 
// @example Sunburst chart
// 
//     .z.m.qp.theme[.z.m.gg.theme.blank]
//     .z.m.qp.theme[``legend_use!(::;0b)]
//     .z.m.qp.rect[rr;`y__;`x__;`y2__;`x2__] 
//         .z.m.qp.s.geom[``colour!(::;0xffffff)] ,
//         .z.m.qp.s.aes[`fill`alpha; `id`d__] ,
//         .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat rr[`id]!rr`fill__] ,
//         .z.m.qp.s.coord[.z.m.gg.coords.polar]
//
.z.m.qp.treestack.layout:{[t;id;children;weight;o]
    if [o ~ (::); o : ()!()];
    o: (``expand`filldepth`colours!(::;1b;4;enlist[.z.m.gg.colour.DarkGray],.z.m.gg.colour.brewer[`Set2;8])) , o;
    
    t: ([] id: .z.m.gg.h.column[t;id]; children: .z.m.gg.h.column[t;children]; w: .z.m.gg.h.column[t;weight]);
    t[`parents]: t[`id]where each {y in/: x`children}[t] each t`id;
    ii: t[`id]!til count t;
    t: update ii id, ii children, ii parents from t;
    r: first where 0 = count each t`parents;
    
    arrange : {[opts; fill; g; l; a; ii; o]
        ra:  g g[ii]`children;
        if [0 = count ra; : ra];
        if [opts`expand; ra[`w]: a * ra[`w] % sum ra`w];
        if [l = opts`filldepth; fill: rand 1_opts`colours];

        t: ([] id      : ra`id;
               d__     : l;
               fill__  : (count ra)#enlist fill;
               x__     : "f"$o+0,sums -1_ra`w;
               w__     : 0^ra`w;
               y__     : l;
               y2__    : l + 1);

        : t , raze .z.s[opts; fill; g; l + 1]'[t`w__; ra`id; t`x__];
        };

    r: enlist[`id`d__`fill__`x__`w__`y__`y2__!(t[r]`id;0f;first o`colours;0f;t[r]`w;0f;1f)] , arrange[o; first o`colours; t; 1f; t[r]`w; r; 0f];
    r: update x__:"f"$x__, x2__: "f"$x__ + w__ from r;
    r: update tx__: x__+w__%2, ty__: y__+0.5 from r;
    
    ii: value[ii]!key ii;
    : id xcol update ii id from `id xcols r;
    }

system "d .z.m";

system "d .z.m.gg";
// @localize dnl-file
.z.m.gg.cheat.i.assemble:{[]
    t  : ([] s:`a`b`c`d`e; x: 1 3 2 0 4; y:4 1 2 5 7; y2:2 -1 3 -4 -5; x2:4 6 7 5 8);
    t2 : ([]s: 200?8?`1; y: 200?100f);
    ps : .z.m.qp.s.theme `legend_use`axis_use_x`axis_use_y!000b;
    ts : .z.m.qp.s.geom[enlist[`size]!enlist 11], .z.m.qp.s.theme
        `legend_use`axis_use_x`axis_use_y`axis_use_z`plot_background_fill`grid_majorLine_fill`grid_minorLine_fill!(0b;0b;0b;0b;0x00000000; 0x00000000; 0x00000000);
    L  : {.z.m.qp.text[([]l:enlist x; x:enlist 0; y:enlist 0); `x; `y; `l; y , .z.m.qp.s.geom ``align!(::;`middle)]}[;ts];
    L2 : {
        .z.m.qp.text[([]l:(x;y); o:`a`b; s:1 0; x:0 0; y: 1 0); `x; `y; `l;
            z,
            .z.m.qp.s.scale[`size; .z.m.gg.scale.circle.radius[8;11]],
            .z.m.qp.s.geom[`minSize`maxSize`align!(10;11;`middle)],
            .z.m.qp.s.aes[`size; `s],
            .z.m.qp.s.scale[`y; .z.m.gg.scale.limits[-1 2] .z.m.gg.scale.linear],
            .z.m.qp.s.aes[`fill; `o],
            .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat (.z.m.gg.colour.Black; .z.m.gg.colour.Gray)]]
        }[;;ts];
    L3 : {[x;y;z;z2]
        .z.m.qp.text[([]l:(x;y;z); o:`a`b`b; s:1 0 0; x:0 0 0; y: 2 1 0); `x; `y; `l]
            z2,
            .z.m.qp.s.scale[`size; .z.m.gg.scale.circle.radius[8;11]],
            .z.m.qp.s.geom[`minSize`maxSize`align!(10;11;`middle)],
            .z.m.qp.s.aes[`size; `s],
            .z.m.qp.s.scale[`y; .z.m.gg.scale.limits[0 3] .z.m.gg.scale.linear],
            .z.m.qp.s.aes[`fill; `o],
            .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat (.z.m.gg.colour.Black; .z.m.gg.colour.Gray)]
        }[;;;ts];

    
    d: `t`t2`ps`ts`L`L2`L3!(t; t2; ps; ts; L; L2; L3);
    
    : .z.m.qp.title[.z.m.axlocalize.t`.gg_cheatTitle] .z.m.qp.layout[`hori_w; 1.2 1.5 1 1 1 1 1] (
        cheat.i.geometries d;
        cheat.i.scales d;
        cheat.i.themes d;
        cheat.i.deps d;
        cheat.i.settings d)
    }

// @localize dnl-file
.z.m.gg.cheat.i.deps:{[d]
    : .z.m.qp.title[.z.m.axlocalize.t`.gg_depsTitle]
        .z.m.qp.layout[`vert_w; 1 0.5 8] (
            .z.m.qp.theme[cheat.i.theme]
            .z.m.qp.theme[`axis_use_x`axis_use_y!(0b; 0b)]
            .z.m.qp.layout[`vert; ::] (
                    d[`L]".z.m.qp.s.link[s]";
                    d[`L]".z.m.qp.s.primary[s]";
                    d[`L]".z.m.qp.s.secondary[s]");
            .z.m.qp.empty[];
            .z.m.qp.title[.z.m.axlocalize.t`.gg_compositionTitle]
            .z.m.qp.theme[cheat.i.theme]
            .z.m.qp.theme[`axis_use_x`axis_use_y!(0b; 0b)]
            .z.m.qp.layout[`vert; ::] (
                .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.stack (.z.m.qp.point[d`t; `x; `y2; ::]; .z.m.qp.line[d`t; `x; `y; ::]);  d[`L]".z.m.qp.stack vs");
                .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.split (.z.m.qp.point[d`t; `x; `y2; ::]; .z.m.qp.line[d`t; `x; `y; ::]);  d[`L]".z.m.qp.split vs (dual y axes)");
                .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.layout[`hori; ::] (.z.m.qp.line[d`t; `x; `y; d `ps]; .z.m.qp.point[d`t; `x; `y2; d `ps]);       d[`L]".z.m.qp.layout[`hori; ::] vs");
                .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.line[d`t; `x; `y; d `ps]; .z.m.qp.point[d`t; `x; `y2; d `ps]);    d[`L]".z.m.qp.layout[`hori_w; ws] vs");
                .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.layout[`vert; ::] (.z.m.qp.line[d`t; `x; `y; d `ps]; .z.m.qp.point[d`t; `x; `y2; d `ps]);       d[`L]".z.m.qp.layout[`vert; ::] vs");
                .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.layout[`vert_w; 1 2] (.z.m.qp.line[d`t; `x; `y; d `ps]; .z.m.qp.point[d`t; `x; `y2; d `ps]);    d[`L]".z.m.qp.layout[`vert_w; ws] vs")))
    }

// @localize dnl-file
.z.m.gg.cheat.i.geometries:{[d]
    : .z.m.qp.title[.z.m.axlocalize.t`.gg_geomTitle]
        .z.m.qp.theme[cheat.i.theme]
        .z.m.qp.layout[`vert; ::]
            (.z.m.qp.layout[`vert; ::] (d[`L]"t = table"; d[`L]"x* y* = columns";d[`L]"s = settings (.z.m.qp.s.*)"); .z.m.qp.empty[]) ,
            $[`addPath in key .z.m.axskia; enlist .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.area[d`t; `s; `y; d `ps]; d[`L2][".z.m.qp.area[d`t; x; y; s]";"fill,alpha"]); ()] , (
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.bar[d`t; `s; `y; d `ps];               d[`L3][".z.m.qp.bar[d`t; x; y; s]";"fill,alpha,size";"colour,strokewidth"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.hbar[d`t; `y; `s; d `ps];              d[`L3][".z.m.qp.hbar[d`t; x; y; s]";"fill,alpha,size";"colour,strokewidth"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.boxplot[d`t2; `s; `y; d `ps];          d[`L]".z.m.qp.boxplot[d`t; x; y; s]");
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.empty[];                                d[`L]".z.m.qp.empty[]");
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.hboxplot[d`t2; `y; `s; d `ps];         d[`L]".z.m.qp.hboxplot[d`t; x; y; s]");
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.heatmap[d`t2; `s; `y; d `ps];          d[`L3][".z.m.qp.heatmap[d`t; x; y; s]";"fill,alpha";"colour,strokewidth"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.hhistogram[d`t2; `s; d `ps];           d[`L3][".z.m.qp.hhistogram[d`t; y; s]";"fill,alpha";"colour,strokewidth"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.hinterval[d`t; `x; `x2; `y; d `ps];    d[`L3][".z.m.qp.hhinterval[d`t; x; x2; y; s]";"fill,alpha";"colour,strokewidth"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.histogram[d`t2; `s; d `ps];            d[`L3][".z.m.qp.histogram[d`t; y; s]";"fill,alpha";"colour,strokewidth"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.interval[d`t; `x; `y; `y2; d `ps];     d[`L3][".z.m.qp.interval[d`t; x; y; y2; s]";"fill,alpha,size";"colour,strokewidth"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.line[d`t; `s; `y; d `ps];              d[`L2][".z.m.qp.line[d`t; x; y; s]";"fill,alpha,size"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.path[d`t; `x2; `y; d `ps];             d[`L2][".z.m.qp.path[d`t; x; y; s]";"fill,alpha,size"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.point[d`t; `x; `y; d `ps];             d[`L3][".z.m.qp.point[d`t; x; y; s]";"fill,alpha,size";"colour,strokewidth"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.polygon[([]x:(1 2 3; 4 5 6); y:(1 2 1; 3 4 3)); `x; `y; d `ps]; d[`L3][".z.m.qp.polygon[d`t; xs; ys; s]";"fill,alpha";"colour,strokewidth"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.segment[d`t; `x; `y; `x2; `y2; d `ps]; d[`L2][".z.m.qp.segment[d`t; x; y; x2; y2; s]";"fill,alpha,size"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.rect[d`t; `x; `y; `x2; `y2; d `ps];    d[`L3][".z.m.qp.rect[d`t; x; y; x2; y2; s]";"fill,alpha";"colour,strokewidth"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.ribbon[d`t; `x; `y; `y2; d `ps];       d[`L2][".z.m.qp.ribbon[d`t; x; y; y2; s]";"fill,alpha"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.text[d`t;`x;`y;`y; d `ps];             d[`L3][".z.m.qp.text[d`t; x; y; l; s]";"fill,alpha,size,angle";"colour,strokewidth"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.tile[d`t; `x; `y; d `ps];              d[`L3][".z.m.qp.tile[d`t; x; y; s]";"fill,alpha";"colour,strokewidth"]);
            .z.m.qp.layout[`hori_w; 1 2] (.z.m.qp.quantile[d`t2; `y; d `ps];             d[`L3][".z.m.qp.quantile[d`t; y; s]";"fill,alpha,size";"colour,strokewidth"])
            );
    }

// @localize dnl-file
.z.m.gg.cheat.i.scales:{[d]
    : .z.m.qp.title["Scales"]
        .z.m.qp.theme[cheat.i.theme]
        .z.m.qp.layout[`vert; ::] (
            d[`L2]["scale.default";.z.m.axlocalize.t`.gg_acceptsAnything];
            d[`L3]["scale.*";"log, power[n], mercator[isLat]";"TEMPORAL*, categorical, weekday"];
            .z.m.qp.empty[];
            .z.m.qp.layout[`hori_w; 1 2.5] (
                .z.m.qp.bar[d`t; `s; `y; d[`ps], .z.m.qp.s.aes[`fill; `s], .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat (.z.m.gg.colour.Red; .z.m.gg.colour.Blue; .z.m.gg.colour.Green)]];
                d[`L]"scale.colour.cat[cs]");
            .z.m.qp.layout[`hori_w; 1 2.5] (.z.m.qp.bar[d`t; `s; `y; d[`ps], .z.m.qp.s.aes[`fill; `s] , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat10]];  d[`L]"scale.colour.cat10");
            .z.m.qp.layout[`hori_w; 1 2.5] (.z.m.qp.bar[d`t; `s; `y; d[`ps], .z.m.qp.s.aes[`fill; `s] , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat20]];  d[`L]"scale.colour.cat20");
            .z.m.qp.empty[];
            .z.m.qp.layout[`hori_w; 1 2.5] (
                .z.m.qp.bar[d`t; `x; `y; d[`ps], .z.m.qp.s.aes[`fill; `x] , .z.m.qp.s.scale[`fill;
                .z.m.gg.scale.colour.gradient[.z.m.gg.colour.SteelBlue; .z.m.gg.colour.FireBrick]]];  d[`L]"scale.colour.gradient[c1; c2]");
            .z.m.qp.layout[`hori_w; 1 2.5] (
                .z.m.qp.bar[d`t; `x; `y; d[`ps], .z.m.qp.s.aes[`fill; `x] , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.gradient2[2; .z.m.gg.colour.SteelBlue; .z.m.gg.colour.Green; .z.m.gg.colour.FireBrick]]];
                d[`L]"scale.colour.gradient2[m; c1; c2; c3]");
            .z.m.qp.empty[];
            .z.m.qp.layout[`hori_w; 1 2.5] (.z.m.qp.point[d`t; `x; `y; d[`ps], .z.m.qp.s.aes[`size; `x] , .z.m.qp.s.scale[`size; .z.m.gg.scale.circle.area[1;50]]];   d[`L]"scale.cicle.area[m; M]");
            .z.m.qp.layout[`hori_w; 1 2.5] (.z.m.qp.point[d`t; `x; `y; d[`ps], .z.m.qp.s.aes[`size; `x] , .z.m.qp.s.scale[`size; .z.m.gg.scale.circle.radius[1;4]]];  d[`L]"scale.cicle.radius[m; M]");
            .z.m.qp.layout[`hori_w; 1 2.5] (.z.m.qp.line[d`t; `x; `y; d[`ps], .z.m.qp.s.aes[`size; `x] , .z.m.qp.s.scale[`size; .z.m.gg.scale.line.size[1;6]]];       d[`L]"scale.line.size[m; M]");
            .z.m.qp.empty[];
            .z.m.qp.layout[`hori_w; 1 2.5] (.z.m.qp.point[d`t; `x; `y; d[`ps], .z.m.qp.s.aes[`alpha; `x] , .z.m.qp.s.scale[`size; .z.m.gg.scale.alpha[1;50]]];  d[`L]"scale.alpha[m; M]");
            .z.m.qp.empty[];
            .z.m.qp.layout[`hori_w; 1 2.5] (.z.m.qp.bar[d`t; `x; `y; d[`ps], .z.m.qp.s.scale[`x; .z.m.gg.scale.extension[.8] .z.m.gg.scale.linear]];  d[`L]"scale.extension[p] s");
            .z.m.qp.layout[`hori_w; 1 2.5] (.z.m.qp.bar[d`t; `x; `y; d[`ps], .z.m.qp.s.scale[`x; .z.m.gg.scale.limits[-1 5] .z.m.gg.scale.linear]];   d[`L]"scale.limits[(m;M)] s");
            .z.m.qp.empty[]);
    }

// @localize dnl-file
.z.m.gg.cheat.i.settings:{[d]
    :
        .z.m.qp.layout[`vert_w; 1.5 1] (
            .z.m.qp.title[.z.m.axlocalize.t[`.gg_settingsTitle]," (.z.m.qp.s.*)"]
            .z.m.qp.theme[cheat.i.theme]
            .z.m.qp.layout[`vert; ::] (
                d[`L]"aes[aes; column]";
                d[`L]"scale[aes; scale]";
                d[`L]"aggr[.z.m.st.a.*]";
                d[`L]"geom[...]";
                d[`L]"labels[`x`y..!...]";
                d[`L]"stat[.z.m.gg.stat.*]";
                d[`L]"theme[theme]";
                d[`L]"binx[d; s; p]";
                d[`L]"biny[d; s; p]";
                d[`L]"secondary[id]";
                d[`L]"primary[id]";
                d[`L]"link[linkid]";
                d[`L]"legend[`a`b`c!colours]";
                d[`L]"textalign[align]";
                d[`L]"coord[coords]");
            .z.m.qp.title["Stat Transforms"]
            .z.m.qp.theme[cheat.i.theme]
            .z.m.qp.layout[`vert; ::] (
                d[`L]"stat.outliers[cc; nc]";
                d[`L]"stat.bin1d[c; s; a]";
                d[`L]"stat.bin2d[cs; s; s; a]";
                d[`L]"stat.binNd[cs; ss; a]";
                d[`L]"stat.sbin1d[c; s; sc; a]";
                d[`L]"stat.sbin2d[cs; s; s; sc; sc; a]";
                d[`L]"stat.sbinNd[cs; ss; scs; a]";
                d[`L]"stat.summary[cc; nc]";
                d[`L]"stat.reg.line[xc; yc]";
                d[`L]"stat.quantile[c]";
                d[`L]"stat.quartiles[cc; nc]"))
    }

// @localize dnl-file
.z.m.gg.cheat.i.themes:{[d]
    : .z.m.qp.layout[`vert_w; 3 1 6] (
          .z.m.qp.title[.z.m.axlocalize.t`.gg_coordTitle]
            .z.m.qp.theme[cheat.i.theme]
            .z.m.qp.layout[`vert; ::] (
                .z.m.qp.layout[`hori; 1 2] (.z.m.qp.theme[.z.m.gg.theme.default] .z.m.qp.bar[d`t; `s; `y; d `ps];     d[`L]"coords.rect");
                .z.m.qp.layout[`hori; 1 2] (.z.m.qp.theme[.z.m.gg.theme.default] .z.m.qp.theme[enlist[`aspect_ratio]!enlist `square] .z.m.qp.bar[d`t; `s; `y; d[`ps],.z.m.qp.s.coord .z.m.gg.coords.polar]; d[`L]"coords.polar");
                .z.m.qp.layout[`hori; 1 2] (.z.m.qp.theme[.z.m.gg.theme.default] .z.m.qp.point3D[d`t; `s; `y; `x; .z.m.qp.s.aes[`fill;`x],d `ps];     d[`L]"coords.cube"));
            .z.m.qp.empty[];
        
            .z.m.qp.title[.z.m.axlocalize.t`.gg_themeTitle]
            .z.m.qp.theme[cheat.i.theme]
            .z.m.qp.theme[`axis_use_x`axis_use_y!11b]
            
            .z.m.qp.layout[`vert; ::] (
                .z.m.qp.layout[`hori; 1 2] (.z.m.qp.theme[.z.m.gg.theme.default]  .z.m.qp.bar[d`t; `s; `y; d `ps];        d[`L]"theme.default");
                .z.m.qp.layout[`hori; 1 2] (.z.m.qp.theme[.z.m.gg.theme.light]    .z.m.qp.bar[d`t; `s; `y; d `ps];        d[`L]"theme.light");
                .z.m.qp.layout[`hori; 1 2] (.z.m.qp.theme[.z.m.gg.theme.transparent] .z.m.qp.bar[d`t; `s; `y; d `ps];     d[`L]"theme.transparent");
                .z.m.qp.layout[`hori; 1 2] (.z.m.qp.theme[.z.m.gg.theme.blank]    .z.m.qp.bar[d`t; `s; `y; d `ps];        d[`L]"theme.blank");
                .z.m.qp.layout[`hori; 1 2] (.z.m.qp.theme[.z.m.gg.theme.clean]    .z.m.qp.bar[d`t; `s; `y; d `ps];        d[`L]"theme.clean");
                .z.m.qp.layout[`hori; 1 2] (.z.m.qp.theme[.z.m.gg.theme.white]    .z.m.qp.bar[d`t; `s; `y; d `ps];        d[`L]"theme.white");
                .z.m.qp.layout[`hori; 1 2] (.z.m.qp.theme[.z.m.gg.theme.dark]     .z.m.qp.bar[d`t; `s; `y; d `ps];        d[`L]"theme.dark");
                .z.m.qp.layout[`hori; 1 2] (.z.m.qp.theme[.z.m.gg.theme.deepblue] .z.m.qp.bar[d`t; `s; `y; d `ps];        d[`L]"theme.deepblue")));
    }

// @fileOverview 
// Render a cheatsheet of objects and signatures of the visualization library
// @localize dnl-file
// @example
// .z.m.gg.cheat.sheet[]
.z.m.gg.cheat.sheet:{[]
    .z.m.qp.png[`:cheatsheet.png;1500;1100] .z.m.qp.theme[``canvas_fill!(::;0xffffffff)] cheat.i.assemble[]
    }

.z.m.gg.cheat.i.translations:.z.m.axlocalize.addTranslations (!) . flip
    enlist
    (`en; (!) . flip (
        (`.gg_themeTitle; "Themes");
        (`.gg_coordTitle; "Coordinate Systems");
        (`.gg_statTitle; "Stat Transforms");
        (`.gg_settingsTitle; "Settings");
        (`.gg_acceptsAnything; "accepts anything");
        (`.gg_geomTitle ;"Geometries");
        (`.gg_depsTitle; "Dependencies");
        (`.gg_compositionTitle; "Composition");
        (`.gg_cheatTitle; "GG Cheatsheet/Reference")))
.z.m.gg.cheat.i.theme:`margin_left`margin_right`margin_top`margin_bottom`canvas_fill`padding_left`padding_right`padding_top`padding_bottom!(10; 10; 10; 10; 0xff,0xffffff; 0; 0; 2; 2)
system "d .z.m";

system "d .z.m.qp";

.z.m.qp.polar.pie:{[table; x; settings]
    if [settings ~ (::); settings:()!()];
    
    .z.m.qp.theme[``aspect_ratio`axis_use_x`axis_use_y!(::;`square;0b;0b)]
        .z.m.qp.bar[table;`const__;`count__]
              .z.m.qp.s.stat[.z.m.gg.stat.pie[x; .z.m.st.a.count[]]]
            , .z.m.qp.s.aes[`group;x]
            , .z.m.qp.s.aes[`fill;x]
            , .z.m.qp.s.scale[`fill; .z.m.gg.scale.colour.cat10]
            , .z.m.qp.s.scale[`y; .z.m.gg.scale.limits[0 0N] .z.m.gg.scale.linear]
            , .z.m.qp.s.scale[`x; .z.m.gg.scale.limits[-0.0001 0.0001] .z.m.gg.scale.linear]
            , .z.m.qp.s.geom[``position!(::;`stack)]
            , .z.m.qp.s.coord[.z.m.gg.coords.polar]
            , settings
    }
system "d .z.m";

export:([.z.m.gg;.z.m.qp])
