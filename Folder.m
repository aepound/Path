classdef Folder < Path
    % Folder Represents a folder path.
    %       Type 'Path.help' to see the documentation.
    
    methods
        
        %% Name
        function result = name(objects)
            result = objects.selectFolder(@(obj) Folder(obj.stem_ + obj.extension_));
        end
        
        function result = setName(objects, varargin)
            result = objects.parent.appendFolder(varargin{:});
        end
        
        %% Append         
        function result = append(objects, appendage)
            arguments
                objects(1, :)
            end
            arguments (Repeating)
                appendage (1, :) string {mustBeNonmissing}
            end
            
            appendage = Path.clean(appendage{:});            
            extension = regexp(appendage, "(?<!\.|^)\.[^\.]*$", "once", "match");
            if all(ismissing(extension))
                result = objects.appendFolder(appendage);
            elseif all(~ismissing(extension))
                result = objects.appendFile_(appendage);
            else
                error("Folder:append:Ambiguous", "Could not determine if file or folder. Occurence of extensions is ambiguous. Use methods ""appendFile"" or ""appendFolder"" instead.");
            end
        end
        
        function result = appendFile(objects, appendage)
            arguments
                objects(1, :)
            end
            arguments (Repeating)
                appendage (1, :) string {mustBeNonmissing}
            end            
            appendage = Path.clean(appendage{:});                  
            result = objects.appendFile_(appendage);
        end
        
        function result = appendFolder(objects, appendage)
            arguments
                objects(1, :)
            end
            arguments (Repeating)
                appendage (1, :) string {mustBeNonmissing}
            end            
            appendage = Path.clean(appendage{:});               
            result = objects.appendFolder_(appendage);
        end
        
        function result = mrdivide(objects, appendage)
            result = objects.append(appendage);
        end
        
        function result = mldivide(objects, appendage)
            result = objects.append(appendage);
        end
        
        %% File system interaction                
        function result = exists(objects)
            result = arrayfun(@(obj) isfolder(obj.string), objects);
        end            
        
        function mustExist(objects)
            for obj = objects
                if ~obj.exists
                    exception = MException("Folder:mustExist:Failed", "Folder ""%s"" not found.", obj.string);
                    throwAsCaller(exception);
                end
            end
        end 
        
        function mkdir(objects)
            for obj = objects
                if obj.exists
                    return;
                end
                try
                    mkdir(obj.string);
                catch exception
                    extendError(exception, "MATLAB:MKDIR", "Error while creating folder ""%s"".", obj);
                end
            end
        end
        
        function result = containedFiles(objects)
            filePaths = strings(1, 0);
            objects.mustExist;
            for obj = objects.unique_
                contentInfo = obj.dir;
                fileInfo = contentInfo(~[contentInfo.isdir]);
                for i = 1 : length(fileInfo)
                    filePaths(end+1) = obj.string + "\" + fileInfo(i).name;
                end
            end
            result = File(filePaths);
        end
        
        function result = containedSubfiles(objects)
            filePaths = strings(1, 0);
            objects.mustExist;
            for obj = objects.unique_
                filePaths = [filePaths, listFiles(obj.string)];
            end
            result = File(filePaths);
        end
    end
    
    methods (Static)
        
        function result = ofMatlabElement(elements)
            result = File.ofMatlabElement(elements).parent;
        end

        
        function result = ofCaller
            stack = dbstack;
            if length(stack) == 1
                error("Folder:ofCaller:NoCaller", "This method was not called from another file."); end
            callingFile = stack(2).file;
            result = File.ofMatlabElement(callingFile).parent;
        end 
        

    end
    
    methods (Access = private)
        function result = appendFile_(objects, files)
            if isempty(objects) || isempty(files)
                result = objects;
                return 
            elseif isscalar(objects) || isscalar(files) || length(objects) == length(files)
                result = File(objects.string + filesep + files.string);
            else
                error("Folder:append:LengthMismatch", "Length of object array, %i, and length of appendage array, %i, must either match or one of them must be scalar.", length(objects), length(files));
            end
        end
        
        function result = appendFolder_(objects, folders)
            if isempty(objects) || isempty(folders)
                result = objects;
                return 
            elseif isscalar(objects) || isscalar(folders) || length(objects) == length(folders)
                result = Folder(objects.string + filesep + folders.string);
            else
                exception = MException("Folder:append:LengthMismatch", "Length of object array, %i, and length of appendage array, %i, must either match or one of them must be scalar.", length(objects), length(folders));
                throwAsCaller(exception);
            end
        end
    end
    
    
end

function result = listFiles(folder)    
    result = strings(0);    
    folderContents = dir(folder)';    
    for folderContent = folderContents
        path = fullfile(folder, folderContent.name);
        if folderContent.isdir
            if folderContent.name == "." || folderContent.name == ".."
                continue; end
            result = [result, listFiles(path)];
        else
            result(end+1) = path;
        end        
    end    
end