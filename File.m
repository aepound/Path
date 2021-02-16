classdef File < Path
    % File Represents a file path.    
    %       Type 'Path.help' to see the documentation.
    
    methods
        
        %% Name
        function result = name(objects)
            result = objects.selectFile(@(obj) File(obj.stem_ + obj.extension_));
        end
        
        function result = setName(objects, varargin)
            result = objects.parent.appendFile(varargin{:});
        end
        
        %% Stem
        function result = stem(objects)
            result = objects.selectString(@(obj) obj.stem_);
        end
        
        function objects = setStem(objects, stems)
            arguments
                objects(1, :)
                stems (1, :) string {mustBeNonmissing, Path.mustBeValidName, Path.mustBeEqualSizeOrScalar(stems, objects)}
            end
            if isscalar(stems)
                stems = repmat(stems, 1, objects.count);
            end
            for i = 1 : length(objects)
                objects(i).stem_ = stems(i);
            end
        end
        
        function result = hasStem(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.stem_, pattern, true));
        end
        
        function result = whereStemIs(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.stem_, pattern, true));
        end
        
        function result = hasNotStem(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.stem_, pattern, false));
        end
        
        function result = whereStemIsNot(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.stem_, pattern, false));
        end
        
        %% Extension
        function result = extension(objects)
            result = objects.selectString(@(obj) obj.extension_);
        end
        
        function result = hasExtension(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.extension_, pattern, true));
        end
        
        function result = whereExtensionIs(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.extension_, pattern, true));
        end
        
        function result = hasNotExtension(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.extension_, pattern, false));
        end
        
        function result = whereExtensionIsNot(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.extension_, pattern, false));
        end
        
        %% File system interaction
        function result = exists(objects)
            result = arrayfun(@(obj) isfile(obj.string), objects);
        end
                
        function mustExist(objects)
            for obj = objects
                if ~obj.exists
                    exception = MException("File:mustExist:Failed", "File ""%s"" not found.", obj.string);
                    throwAsCaller(exception);
                end
            end
        end 
        
        function createEmptyFile(objects)
            for obj = objects
                obj.parent.mkdir;
                fileId = fopen(obj.string, 'w');
                fclose(fileId);
            end
        end
        
        function varargout = fopen(obj, varargin)
            arguments; obj (1, 1); end
            arguments (Repeating); varargin; end
            [varargout{1:nargout}] = fopen(obj.string, varargin{:});
        end
        
        function [id, closer] = open(obj, permission, varargin)
            arguments
                obj (1, 1)
                permission (1, 1) string = "r";
            end
            arguments (Repeating); varargin; end
            
            if permission.startsWith("r")
                obj.mustExist;
            else
                obj.parent.mkdir;
            end                
            [id, errorMessage] = obj.fopen(permission, varargin{:});
            if id == -1
                error(errorMessage); end
            if nargout == 2
                closer = onCleanup(@() fclose(id)); end
        end
        
        function [id, closer] = openForReading(obj)
            id = obj.open;
            if nargout == 2
                closer = onCleanup(@() fclose(id)); end
        end
        
        function [id, closer] = openForWriting(obj)
            id = obj.open("w");
            if nargout == 2
                closer = onCleanup(@() fclose(id)); end
        end
        
        function [id, closer] = openForWritingText(obj)
            id = obj.open("wt");
            if nargout == 2
                closer = onCleanup(@() fclose(id)); end
        end
        
        function [id, closer] = openForAppendingText(obj)
            id = obj.open("at");
            if nargout == 2
                closer = onCleanup(@() fclose(id)); end
        end
        
        function copyToFolder(objects, targetFolder)
            arguments
                objects
                targetFolder (1, 1) Folder
            end
            for i = 1 : objects.count
                obj = objects(i);
                obj.mustExist;
                if isfile(targetFolder.string)
                    error("Path:copyToFolder:TargetFolderIsFile", "The target folder ""%s"" is an existing file.", targetFolder); end
                try                    
                    targetFolder.mkdir;
                    target = targetFolder \ obj.name;
                    copyfile(obj.string, target.string);
                catch exception
                    extendError(exception, ["MATLAB:COPYFILE:", "MATLAB:MKDIR:"], "Unable to copy file ""%s"" to folder ""%s"".", obj, targetFolder);
                end
            end
        end
        
        function moveToFolder(objects, targetFolder)
            arguments
                objects
                targetFolder (1, 1) Folder
            end
            for i = 1 : objects.count
                obj = objects(i);
                obj.mustExist;
                if isfile(targetFolder.string)
                    error("Path:moveToFolder:TargetFolderIsFile", "The target folder ""%s"" is an existing file.", targetFolder); end
                try                    
                    targetFolder.mkdir;
                    target = targetFolder \ obj.name;
                    movefile(obj.string, target.string);
                catch exception
                    extendError(exception, ["MATLAB:MOVEFILE:", "MATLAB:MKDIR:"], "Unable to move file ""%s"" to folder ""%s"".", obj, targetFolder);
                end
            end
        end
        
        function delete(objects)
            for obj = objects
                if obj.exists
                    delete(obj.string)
                end
            end
        end
        
        function result = readText(obj)
            arguments
                obj (1, 1)
            end
            obj.mustExist;
            result = string(fileread(obj.string));
            result = result.replace(sprintf("\r\n"), newline);
        end
        
        function writeText(obj, text)
            arguments
                obj (1, 1)
                text (1, 1) string
            end
            [fileId, cleanUp] = obj.openForWritingText;
            fprintf(fileId, "%s", text);            
        end
        
        function result = bytes(objects)
            result = [objects.dir.bytes];
        end
        
        %% Save and load
        function save(obj, variables)
            arguments
                obj (1, 1)
            end
            arguments (Repeating)
                variables (1, 1) string {mustBeValidVariableName}
            end
            if isempty(variables)
                error("Path:load:MissingArgument", "Not enough inputs arguments.");
            end
            for variable = [variables{:}]
                saveStruct.(variable) = evalin("caller", variable);
            end
            obj.parent.mkdir;
            save(obj.string, "-struct", "saveStruct");
        end
        
        function varargout = load(obj, variables)
            arguments
                obj (1, 1)
            end
            arguments (Repeating)
                variables (1, 1) string {mustBeValidVariableName}
            end
            
            if nargout ~= length(variables)
                error("Path:load:InputOutputMismatch", "The number of outputs, %i, must match the number of variables to load, %i.", nargout, length(variables)); end
            data = load(obj.string, variables{:});
            varargout = {};
            for variable = string(variables)
                if ~isfield(data, variable)
                    error("Path:load:VariableNotFound", "Variable ""%s"" not found in file ""%s"".", variable, obj); end
                varargout{end+1} = data.(variable);
            end
        end
        
        function result = mrdivide(~, ~)
            error("Not supported for objects of class File");
        end
        
        function result = mldivide(~, ~)
            error("Not supported for objects of class File");
        end
    end
    
    methods (Static)
        
        function result = ofMatlabElement(elements)
            arguments
                elements (1, :) string {mustBeNonmissing}
            end
            result = File.empty;
            for element = elements
                path = string(which(element));
                
                % If the queried element happens to have the name of a
                % variable in this function, temporarily rename that
                % variable.
                if path == "variable"
                    temp = eval(element);
                    clearvars(element);
                    path = string(which(element));
                    eval(element + " = temp");
                end
                
                if path.startsWith("built")
                    
                    % Remove "build in" and brackets.
                    path = regexprep(path, ["^[^\(]*\(", "\)$"], "");
                elseif path == ""
                    error("File:ofMatlabElement:NotFound", "Element ""%s"" is not on the search path.", element);
                end
                result(end+1) = File(path);
            end
        end
        
        function result = ofCaller
            stack = dbstack;
            if length(stack) == 1
                error("File:ofCaller:NoCaller", "This method was not called from another file."); end
            callingFile = stack(2).file;
            result = File.ofMatlabElement(callingFile);
        end 
        

    end
    
end