# A uncomplete clone of [jo](https://github.com/jpmens/jo) in [ZIG](https://ziglang.org)

[jo](https://github.com/jpmens/jo) is a simple cli tool for generating JSON from the shell. It is written in C
[ZIG](https://ziglang.org) is a new programming language "trying to fix C". 

## Build

For building zjo a [zig compiler version 0.6.0](https://ziglang.org/download/release-0.6.0)
or newer is needed.  Clone the git repo with its submodule(s).

        git clone --recurse-submodules https://zickzackv/zjo

Compile the project with 

        zig build
		

## Install

Install the binary into a location of your path and use it. 


## Usage

     zjo [-a,-o,-h] [word ...]

The command generates json document from the given command line
arguments. By default JSON objects are created. 
     
	$ zjo key1=value1 key2=value2 key3=value3
	{ "key1": "value1", "key2": "value2", "key3": "value3" }
         
		 
	$ zjo 1=1 2='"2"' 3=2 4=5
    {"4":5,"2":"2","1":1,"3":2}

With the switch `-a` zjo will produce a JSON array. 

    $ zjo -a $(seq 1 15)
	["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15"]

zjo tries to parse JSON objects, so that one can produce more complex
JSON documents.

    $ zjo 1=[2.565] x=1 y=$(zjo -a $(seq 1 10))
	{"x":1,"y":["1","2","3","4","5","6","7","8","9","10"],"1":[2.565e+00]}

## Missing Features from the original

This clone of jo lacks a lot of features from the original. See the
following list of (currently) missing features:


* key value with path specification

    The original has the option to specify the same key suffixed with
    '[]'. The values of the key are then appended to an array. `jo
    a[]=1 a[]=2`

* pretty printing of JSON documents
  
    Pretty printing the JSON document can be accomplished with
    [jq](https://stedolan.github.io/jq/)
  
		$ zjo key1=value1 key2=value2 key3=value3 | jq
        {
		  "key1": "value1",
		  "key2": "value2",
		  "key3": "value3"
		}
		
* key path with delimiter

    Specifing complex object path with a custom delemiter is a missing
    feature.
	  
    	  $ jo -d '.'  key1=value1 key2=value2 key3.key5.key.5=true
          {"key1":"value1","key2":"value2","key3":{"key5":{"key":{"5":true}}}}

* type coercing

    zjo does not has its own type recognition build in.  It will not
    convert e.g. the string "true" to the boolean true. Other jo type
    sepcification '-s' are also not supported.
  
* other key value delimeter than '='
  
    jo does support more then one key value delimeter like '@' and
    ':'. zjo does only support '='.
  
* version information

    There is simply no option for printing its own version / release.
  
* reading from stdin

    Reading argument style string from stdin is not (yet) supported by
    zjo.

## Credits

* zig-args lib for argument parsing

    [zig-args](https://github.com/MasterQ32/zig-args) by [MasterQ32](https://github.com/MasterQ32)

## Disclaimer

This is my first project in ZIG. Its whole purpose was to learn ZIG
and not to write the perfect clone of a existing tool. I learned a lot
about using ZIG and remembered my old C progamming days in
university. That was fun!




Fabian 
