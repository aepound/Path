# Path
Class for representing filesystem paths in MATLAB.

The `Path` class allow you to solve your path-related problems using short and readable code.

[![View Path on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/87552-path)

## Features
 - Get and set path name, parent, root, stem and extension
 - Filter paths by extension, name, etc. using wildcards
 - List files recursively
 - Handle lists of paths
 - Clean and resolve paths
 - Build absolute and relative paths
 - Automatically create folder when writing files and throw error on failure
 - Get folder of currently executing MATLAB file

 ## Examples
 ### Path properties
 ```Matlab
>> file = Path("C:\data) \ "model.dat"
    Path("C:\data\model.dat")
>> file.parent
    Path("C:\data")
>> file.stem
    "model"
>> file.extension
    ".dat"
 ```
 ### Arrays of paths
 ```Matlab
>> personalFolders = Path("Astronauts") / ["Arthur", "Trillian", "Zaphod"]
     Path("Astronauts\Andrew")
     Path("Astronauts\Trudy")
     Path("Astronauts\Sniffels")
>> personalFolders.join("DONT_PANIC.txt").createEmptyFile;
``` 
### Filtering and chaining
```Matlab
>> files = Path("Sketchy Folder").listDeepFiles
    Path("Sketchy Folder\DeleteStuffVirus.exe")
    Path("Sketchy Folder\System32\nastyWorm.dll")
    Path("Sketchy Folder\dark_corner\half_a_sandwich.dat")
    Path("Sketchy Folder\WormholeResearch.pdf")
>> files.where("Stem", ["*Virus*", "*Worm*"], "ExtensionNot", ".pdf").copyToFolder("D:\Quarantine");
```
### Get path of executing file
```Matlab
>> scriptFile = Path.ofCaller
    File("/MATLAB Drive/YesIMadeAnExtraScriptToDemonstrateThis.m")
>> scriptFile.parent.cd;
```
## Installation
Download this repository or soley the file `Path.m` and add it to your MATLAB search path. 
Requires R2019b or newer.
 
## Documentation
Find the documentation in the [wiki](https://www.github.com/MartinKoch123/Path/wiki).
 


 
