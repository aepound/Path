classdef test_FilePath < matlab.unittest.TestCase

  properties (Constant)
    testDir = FilePath.ofMatlabFile("test_FilePath").parent / "test";
  end

  methods
    function assertAllFalse(obj, values)
      obj.assertFalse(any(values));
    end

    function assertFileExists(obj, files)
      for file = files
        obj.assertTrue(isfile(string(file)));
      end
    end

    function assertFileDoesNotExists(obj, files)
      for file = files
        obj.assertFalse(isfile(string(file)))
      end
    end

    function assertDirExists(obj, dirs)
      for dir = dirs
        obj.assertTrue(isfolder(string(dir)));
      end
    end

    function assertDirDoesNotExist(obj, dirs)
      for dir = dirs
        obj.assertFalse(isfolder(string(dir)));
      end
    end

    function assertError2(obj, func, expected)
      % Version of assertError which allows expecting one of multiple
      % error IDs.
      actual = "";
      try
        func()
      catch exc
        actual = exc.identifier;
      end
      obj.assertTrue(ismember(actual, expected));
    end

    function result = testRoot(obj)
      if ispc
        result = "C:";
      else
        result = "/tmp";
      end
    end

    function result = testRoot2(obj)
      if ispc
        result = "D:";
      else
        result = "/tmp2";
      end
    end

    function result = testRootPattern(obj)
      if ispc
        result = "C*";
      else
        result = "/t*";
      end
    end
  end

  methods(TestMethodTeardown)
    function removeTestDir(testCase)
      if testCase.testDir.exists
        rmdir(testCase.testDir.string, "s");
      end
    end

    function closeFiles(testCase)
      fclose all;
    end
  end

  methods (Test)

    %% Constructor
    function constructWithStringVector(obj)
      obj.assertEqual(FilePath(["one", "two"]).string, ["one", "two"]);
    end

    function constructWithChars(obj)
      obj.assertEqual(FilePath("test"), FilePath('test'))
    end

    function constructWithCharCell(obj)
      actual = FilePath({'one', 'two'});
      expected = FilePath(["one", "two"]);
      obj.assertEqual(actual, expected);
    end

    function constructWithStringCell(obj)
      actual = FilePath({"one", "two"});
      expected = FilePath(["one", "two"]);
      obj.assertEqual(actual, expected);
    end

    function constructWithPathSeparator(obj)
      obj.assertEqual(FilePath("one"+pathsep+" two"), FilePath(["one", "two"]));
      obj.assertEqual(FilePath(" "+pathsep+" "), FilePath([".", "."]));
    end

    function constructDefault(obj)
      obj.assertEqual(FilePath().string, ".");
    end

    function constructEmpty(obj)
      obj.assertSize(FilePath(string.empty), [1, 0]);
      obj.assertSize(FilePath({}), [1, 0]);
    end

    function constructWithMultipleArguments(obj)
      actual = FilePath('a', "b"+pathsep+" c", {'d', "e"+pathsep+" f"}, ["g", "h"]);
      expected = FilePath(["a" "b" "c" "d" "e" "f" "g", "h"]);
      obj.assertEqual(actual, expected);
    end

    %% Factories
    function ofMatlabFile(obj)
      actual = FilePath.ofMatlabFile(["mean", "test_FilePath"]).string;
      expected = string({which("mean") which("test_FilePath")});
      obj.assertEqual(actual, expected);
      obj.assertError(@() FilePath.ofMatlabFile("npofas&/"), "FilePath:ofMatlabFile:NotFound");
    end

    function this(obj)
      obj.assertEqual(FilePath.this, FilePath(which("test_FilePath")));
      obj.assertEqual(FilePath.this(2), FilePath(which(adjustSeparators("+matlab\+unittest\TestRunner.m"))));
    end

    function here(obj)
      obj.assertEqual(FilePath.here, FilePath.this.parent);
      obj.assertEqual(FilePath.here(2), FilePath.this(2).parent);
    end

    function pwd(obj)
      obj.assertEqual(FilePath.pwd, FilePath(pwd));
    end

    function home(obj)
      if ispc
        obj.assertEqual(FilePath.home, FilePath(getenv("USERPROFILE")));
      else
        obj.assertEqual(FilePath.home, FilePath(getenv("HOME")));
      end
    end

    function matlab(obj)
      obj.assertEqual(FilePath.matlab, FilePath(matlabroot));
    end

    function searchFilePath(obj)
      obj.assertEqual(FilePath.searchPath, FilePath(path));
    end

    function userPath(obj)
      obj.assertEqual(FilePath.userPath, FilePath(userpath));
    end

    function tempFile(obj)
      obj.assertEqual(FilePath.tempFile(0), FilePath.empty)
      files = FilePath.tempFile(2);
      obj.assertEqual(files.count, 2);
      obj.assertEqual(files.parent, FilePath(tempdir, tempdir));
      obj.assertNotEqual(files(1).nameString, files(2).nameString);
    end

    function tempDir(obj)
      obj.assertEqual(FilePath.tempDir, FilePath(tempdir));
    end

    %% Conversion
    function string(obj)
      obj.assertEqual(FilePath(["one", "two"]).string, ["one", "two"]);
      obj.assertEqual(FilePath.empty.string, strings(1, 0));
    end

    function char(obj)
      obj.assertEqual('test', FilePath("test").char);
    end

    function cellstr(obj)
      obj.assertEqual(FilePath("one").cellstr, {'one'});
      obj.assertEqual(FilePath(["one", "two"]).cellstr, {'one', 'two'});
    end

    function quote(obj)
      obj.assertEqual(FilePath(["a/b.c", "d.e"]).quote, adjustSeparators(["""a/b.c""", """d.e"""]))
      obj.assertEqual(FilePath.empty.quote, strings(1, 0))
    end

    %% Clean
    function clean_stripWhitespace(obj)
      obj.assertEqual("test", FilePath(sprintf("\n \ttest  \r")).string);
    end

    function clean_removesRepeatingSeparators(obj)
      s = filesep;
      actual = FilePath("one" + s + s + s + "two" + s + s + "three").string;
      expected = adjustSeparators("one/two/three");
      obj.assertEqual(actual, expected);
    end

    function clean_removesOuterSeparators(obj)
      s = filesep;
      actual = FilePath([s 'one/two/three' s]).string;
      if ispc
        expected = "one\two\three";
      else
        expected = "/one/two/three";
      end
      obj.assertEqual(actual, expected);
    end

    function clean_removesCurrentDirDots(obj)
      actual = FilePath("\.\.\one\.\two.three\.\.four\.\.\").string;
      if ispc
        expected = "one\two.three\.four";
      else
        expected = "/one/two.three/.four";
      end
      obj.assertEqual(actual, expected);
    end

    function clean_replacesSeparatorVariations(obj)
      actual = FilePath("one/two\three").string;
      expected = adjustSeparators("one/two/three");
      obj.assertEqual(actual, expected);
    end

    function clean_resolvesParentDirDots(obj)
      tests = {
        % Input / Expected (Windows) / Expected (Linux)
        "one/two/three/../../four", "one/four", "one/four"
        "a\..\b", "b", "/b"
        };
      for test = tests'
        actual = FilePath(test{1}).string;
        if ispc
          expected = FilePath(test{2}).string;
        else
          expected = FilePath(test{3}).string;
        end
        obj.assertEqual(actual, expected);
      end
    end

    %% Name
    function name(obj)
      obj.assertEqual(FilePath(obj.testRoot + "/one/two/three.ext").name.string, "three.ext");
      obj.assertEqual(FilePath("one.two.three.ext").name.string, "one.two.three.ext");
      obj.assertEqual(FilePath("one").name.string, "one");
      obj.assertEqual(FilePath("..").name.string, "..");
      obj.assertEqual(FilePath(".").name.string, ".");
      obj.assertEmpty(FilePath.empty.name);
    end

    function setName(obj)
      files = FilePath("a.b", "c/d");
      obj.assertEqual(files.setName("f.g"), FilePath("f.g", "c/f.g"));
      obj.assertEqual(files.setName("f.g", "h/i"), FilePath("f.g", "c/h/i"));
      obj.assertError(@() files.setName("f", "g", "h"), "FilePath:join:LengthMismatch");
    end

    function nameString(obj)
      testPaths = {
        FilePath(obj.testRoot + "/one/two/three.ext")
        FilePath("../../one/three.ext")
        FilePath("one")
        FilePath("..")
        FilePath(".")
        };

      for testPath = testPaths'
        obj.assertEqual(testPath{1}.name.string, testPath{1}.nameString);
      end

      obj.assertEqual(FilePath.empty.nameString, strings(1, 0));
      obj.assertEqual(FilePath("a", "b").nameString, ["a", "b"]);
    end

    %% Extension
    function extension(obj)
      obj.assertEqual(FilePath(obj.testRoot + "/one/two/three.ext").extension, ".ext");
      obj.assertEqual(FilePath("one.two.three.ext").extension, ".ext");
      obj.assertEqual(FilePath("one.").extension, ".");
      obj.assertEqual(FilePath("one").extension, "");
      obj.assertEqual(FilePath("..").extension, "");
      obj.assertEqual(FilePath(".").extension, "");
    end

    function setExtension(obj)
      obj.assertEqual(FilePath("a.b", "c.d", "e").setExtension(".f"), FilePath("a.f", "c.f", "e.f"));
      obj.assertEqual(FilePath("a.b", "c.d", "e").setExtension([".f", "", "g"]), FilePath("a.f", "c", "e.g"));
      obj.assertEqual(FilePath.empty.setExtension(".a"), FilePath.empty);
    end

    %% Stem
    function stem(obj)
      obj.assertEqual(FilePath(obj.testRoot + "/one/two/three.ext").stem, "three");
      obj.assertEqual(FilePath("one.two.three.ext").stem, "one.two.three");
      obj.assertEqual(FilePath("one").stem, "one");
      obj.assertEqual(FilePath("..").stem, "..");
      obj.assertEqual(FilePath(".").stem, ".");
      obj.assertEmpty(FilePath.empty.stem);
      obj.assertInstanceOf(FilePath.empty.stem, "string")
    end

    function setStem(obj)
      files = FilePath("a.b", "c/d");
      obj.assertEqual(files.setStem("e"), FilePath("e.b", "c/e"));
      obj.assertEqual(files.setStem(["e", "f"]), FilePath("e.b", "c/f"));
      obj.assertEqual(files.setStem(""), FilePath(".b", "c"));
      obj.assertError(@() files.setStem("a/\b"), "FilePath:Validation:InvalidName");
      obj.assertError(@() files.setStem(["a", "b", "c"]), "FilePath:Validation:InvalidSize");
    end

    function addStemSuffix(obj)
      obj.assertEqual(FilePath("a/b.c").addStemSuffix("_s"), FilePath("a/b_s.c"))
      obj.assertEqual(FilePath("a/b.c", "d/e").addStemSuffix("_s"), FilePath("a/b_s.c", "d/e_s"));
      obj.assertEqual(FilePath("a/b.c", "d/e").addStemSuffix(["_s1", "_s2"]), FilePath("a/b_s1.c", "d/e_s2"));
      obj.assertEqual(FilePath("a/b.c").addStemSuffix(""), FilePath("a/b.c"))
      obj.assertEqual(FilePath.empty.addStemSuffix("s"), FilePath.empty);
      obj.assertError(@() FilePath("a/b.c", "d/e").addStemSuffix(["_s1", "_s2", "_s3"]), "FilePath:Validation:InvalidSize");
      obj.assertError(@() FilePath("a/b.c", "d/e").addStemSuffix("/"), "FilePath:Validation:InvalidName");
    end

    %% Parent
    function parent(obj)
      obj.assertEqual(FilePath(obj.testRoot + "/one/two/three.ext").parent, FilePath(obj.testRoot + "/one/two"));
      obj.assertEqual(FilePath("../../one/three.ext").parent, FilePath("../../one"));
      obj.assertEqual(FilePath("one").parent, FilePath("."));
      obj.assertEqual(FilePath("..").parent, FilePath("."));
      obj.assertEqual(FilePath(".").parent, FilePath("."));
    end

    function parentString(obj)
      testPaths = {
        FilePath(obj.testRoot + "/one/two/three.ext")
        FilePath("../../one/three.ext")
        FilePath("one")
        FilePath("..")
        FilePath(".")
        };

      for testPath = testPaths'
        obj.assertEqual(testPath{1}.parent.string, testPath{1}.parentString);
      end

      obj.assertEqual(FilePath.empty.parentString, strings(1, 0));
      obj.assertEqual(FilePath("a/b", "c/d").parentString, ["a", "c"]);
    end

    function setParent(obj)
      files = FilePath("a.b", "c/d", "e/f/g");
      obj.assertEqual(files.setParent("h"), FilePath("h/a.b", "h/d", "h/g"))
    end

    function hasParent(obj)
      obj.assertEqual(FilePath("a/b/c", obj.testRoot + "/d/e", "hello.txt").hasParent, [true, true, false]);
      obj.assertEqual(FilePath.empty.hasParent(), logical.empty(1, 0));
    end

    %% Root
    function root(obj)
      tests = {
        FilePath(obj.testRoot + "/one/two.ext").root, FilePath(obj.testRoot)
        FilePath("one/two").root, FilePath(".")
        FilePath(obj.testRoot + "/a", "b.txt").root, FilePath(obj.testRoot, ".")
        };

      for test = tests'
        [actual, expected] = test{:};
        obj.assertEqual(actual, expected);
      end
    end

    function rootString(obj)
      tests = {
        FilePath(obj.testRoot + "/one/two.ext")
        FilePath("one/two").root
        FilePath.empty
        FilePath("C:\a", "b")
        };

      for test = tests'
        path = test{1};
        obj.assertEqual(path.root.string, path.rootString);
      end
    end

    function setRoot(obj)
      obj.assertEqual(FilePath(obj.testRoot + "/a/b.c", "e/f.g").setRoot(obj.testRoot2), FilePath(obj.testRoot2 + "/a/b.c", obj.testRoot2 + "/e/f.g"));
      obj.assertEqual(FilePath.empty.setRoot(obj.testRoot), FilePath.empty);
      obj.assertEqual(FilePath(obj.testRoot + "/a/b").setRoot("../c/d"), FilePath("../c/d/a/b"));
      obj.assertError(@() FilePath("a").setRoot(pathsep), "FilePath:Validation:ContainsPathsep");
    end

    %% Regex
    function regexprep(obj)
      testPaths = {strings(0), "a.b", ["test01\two.txt", "1\2\3.x"]};
      expression = {'\w', '\d\d'};
      replace = {'letter', 'numbers'};
      for testPath = testPaths
        expected = FilePath(regexprep(testPath{1}, expression, replace));
        actual = FilePath(testPath{1}).regexprep(expression, replace);
        obj.assertEqual(actual, expected);
      end
    end

    %% Properties
    function isRelative(obj)
      obj.assertTrue(all(FilePath(".", "..", "a/b.c", "../../a/b/c").isRelative));
      obj.assertFalse(any(FilePath(obj.testRoot+"\", obj.testRoot+"\a\b.c", "\\test\", "\\test\a\b").isRelative));
    end

    function isAbsolute(obj)
      obj.assertFalse(any(FilePath(".", "..", "a/b.c", "../../a/b/c").isAbsolute));
      obj.assertTrue(any(FilePath(obj.testRoot+"\", obj.testRoot+"\a\b.c", "\\test\", "\\test\a\b").isAbsolute));
    end

    function equalAndNotEqual(obj)
      files = FilePath("one/two", "a\b.c", "three/four", "a\b.c");
      obj.assertEqual(files(1:2) == files(3:4), [false, true]);
      obj.assertEqual(files(1:2) ~= files(3:4), [true, false]);
      obj.assertEqual(files(2) == files(3:4), [false, true]);
      obj.assertEqual(files(3:4) ~= files(2), [true, false]);
      obj.assertTrue(FilePath("one/two") == FilePath("one/two"));
    end

    function parts(obj)
      testRootWithoutLeadingSeparator = regexprep(obj.testRoot, "^" + regexptranslate("escape", filesep), "");
      obj.assertEqual(FilePath(obj.testRoot + "/a/b\\c.e\").parts, [testRootWithoutLeadingSeparator, "a", "b", "c.e"]);
      obj.assertEqual(FilePath(".\..\/\../a/b\\c.e\").parts, ["..", "..", "a", "b", "c.e"]);
      obj.assertEqual(FilePath().parts, ".");

      obj.assertError2(@() FilePath.empty.parts, ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);
      obj.assertError2(@() FilePath("a", "b").parts, ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);
    end

    function strlength(obj)
      obj.assertEqual(FilePath("a/b.c", "d.e").strlength, [5, 3])
      obj.assertEmpty(FilePath.empty.strlength)
    end

    %% Filter
    function where_and_is(obj)
      files = FilePath(obj.testRoot + "\on.e/t=wo.ab.txt");

      tests = {
        {"Parent", obj.testRoot + "\o*"}, 1
        {"ParentNot", obj.testRoot + "\o*"}, []
        {"Parent", "*a*"}, []
        {"ParentNot", "*a*"}, 1

        {"Name", "*.ab.txt"}, 1
        {"NameNot", "*.ab.txt"}, []
        {"Name", "test"}, []
        {"NameNot", "test"}, 1

        {"Root", "*:"}, 1
        {"RootNot", "*:"}, []
        {"Root", "*hello*"}, []
        {"RootNot", "*hello"}, 1

        {"Stem", "*o.a*"}, 1
        {"StemNot", "*o.a*"}, []
        {"Stem", "*wa*"}, []
        {"StemNot", "*wa*"}, 1

        {"Extension", ".txt"}, 1
        {"ExtensionNot", ".txt"}, []
        {"Extension", ".c"} []
        {"ExtensionNot", ".c"}, 1
        };

      for test = tests'
        [args, indices] = test{:};

        % Test 'where'
        actual = files.where(args{:});
        if isempty(indices)
          expected = FilePath.empty;
        else
          expected = files(indices);
        end
        obj.assertEqual(actual, expected);

        % Test 'is'
        actual = files.is(args{:});
        expected = ~isempty(indices);
        obj.assertEqual(actual, expected);
      end
    end

    function where_and_is2(obj)

      files = FilePath([ ...
        obj.testRoot + "/on.e/t=wo.ab.txt"
        "=.23f/asdf.%43"
        "..\..\p"
        "dir\file"
        ] ...
        );

      tests = {
        {"Parent", "*i*", "RootNot", obj.testRoot, "Name", ["file", "t=wo.ab.txt"]}, logical([0, 0, 0, 1])
        {"NameNot", "*f*", "Name", ["p", "file"]}, logical([0, 0, 1, 0])
        {"Root", [".", obj.testRoot]}, logical([1, 1, 1, 1])
        {"ParentNot", "*"}, logical([0, 0, 0, 0])
        {"ExtensionNot", ".txt", "Parent", "*i*"}, logical([0, 0, 0, 1])
        };

      for test = tests'
        [args, expectedIndices] = test{:};

        % Test 'where'
        expected = files(expectedIndices);
        actual = files.where(args{:});
        obj.assertEqual(actual, expected);

        % Test 'is'
        expected = expectedIndices;
        actual = files.is(args{:});
        obj.assertEqual(actual, expected);

      end

      % Test dirs and empty
      obj.assertEqual(FilePath.empty.where("Name", "*"), FilePath.empty)
      obj.assertEqual(FilePath(["a/b", "c/d"]).where("Name", "*b*"), FilePath("a/b"))

      obj.assertEqual(FilePath.empty.is("Name", "*"), logical.empty(1, 0))
      obj.assertEqual(FilePath(["a/b", "c/d"]).is("Name", "*b*"), [true, false])
    end

    %% Absolute/Relative
    function absolute(obj)
      obj.assertEqual(...
        FilePath("a.b", obj.testRoot + "/c/d.e").absolute, ...
        [FilePath.pwd / "a.b", FilePath(obj.testRoot + "/c/d.e")] ...
        );
      obj.assertEqual(...
        FilePath("a.b", obj.testRoot + "/c/d.e").absolute(obj.testRoot + "\x\y"), ...
        [FilePath(obj.testRoot + "\x\y\a.b"), FilePath(obj.testRoot + "/c/d.e")] ...
        );

      obj.assertEqual(...
        FilePath("a.b").absolute("x\y"), ...
        FilePath.pwd / "x\y\a.b" ...
        );

      obj.assertEqual(FilePath(obj.testRoot).absolute, FilePath(obj.testRoot));
      obj.assertEqual(FilePath.empty.absolute, FilePath.empty);
    end

    function relative(obj)
      referencePath = FilePath(obj.testRoot + "/a/b/c");
      file1 = FilePath(obj.testRoot + "/a/d/e.f");
      obj.assertEqual(file1.relative(referencePath), FilePath("..\..\d\e.f"));

      dir1 = FilePath(obj.testRoot);
      obj.assertEqual(dir1.relative(referencePath), FilePath("..\..\.."));

      obj.assertEqual(referencePath.relative(referencePath), FilePath("."));

      obj.assertEqual(FilePath.empty.relative(referencePath), FilePath.empty);

      file2 = FilePath(obj.testRoot2 + "/a.b");
      obj.assertError(@() file2.relative(referencePath), "FilePath:relative:RootsDiffer");

      dir2 = FilePath("a/b");
      obj.assertEqual(dir2.relative, dir2.relative(pwd));

      file3 = FilePath("a.b");
      referenceDir2 = FilePath("b/c").absolute;
      obj.assertEqual(file3.relative(referenceDir2), FilePath("..\..\a.b"));

      obj.assertError2(@() file3.relative([FilePath, FilePath]), ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);

      obj.assertEqual(file3.relative("."), file3);
      obj.assertEqual(FilePath("a.b", "c/d").relative, FilePath("a.b", "c/d"));
    end

    %% Array
    function isEmpty(obj)
      obj.assertFalse(FilePath("a", "b").isEmpty)
      obj.assertTrue(FilePath.empty.isEmpty)
    end

    function count(obj)
      obj.assertEqual(FilePath("a", "b").count, 2);
    end

    function sort(obj)
      [sortedFiles, indices] = FilePath("a", "c", "b").sort;
      obj.assertEqual(sortedFiles, FilePath("a", "b", "c"));
      obj.assertEqual(indices, [1, 3, 2]);

      [sortedFiles, indices] = FilePath("a", "c", "b").sort("descend");
      obj.assertEqual(sortedFiles, FilePath("c", "b", "a"));
      obj.assertEqual(indices, [2, 3, 1]);
    end

    function unique(obj)
      obj.assertEqual(FilePath("a", "b", "a").unique_, FilePath("a", "b"));
      obj.assertEqual(FilePath.empty.unique_, FilePath.empty);
    end

    function deal(obj)
      files = FilePath("a.b", "c.d");
      [file1, file2] = files.deal;
      obj.assertEqual(file1, files(1));
      obj.assertEqual(file2, files(2));

      obj.assertError(@testFun, "FilePath:deal:InvalidNumberOfOutputs");
      function testFun
        [file1, file2, file3] = files.deal;
      end
    end

    function vertcat_(obj)
      actual = [FilePath("a"); FilePath("b")];
      expected = FilePath("a", "b");
      obj.assertEqual(actual, expected);
    end

    function transpose(obj)
      obj.assertError(@() FilePath("a")', "FilePath:transpose:NotSupported");
      obj.assertError(@() FilePath("a").', "FilePath:transpose:NotSupported");
    end

    function subsasgn_(obj)

      obj.assertError(@() makeColumn, "FilePath:subsasgn:MultiRowsNotSupported");
      obj.assertError(@() make3dArray, "FilePath:subsasgn:MultiRowsNotSupported");
      files = FilePath;
      files(2) = FilePath;
      files(1, 3) = FilePath;

      function makeColumn()
        files = FilePath("a");
        files(2, 1) = FilePath("b");
      end

      function make3dArray()
        files = FilePath("a");
        files(1, 1, 1) = FilePath("b");
      end
    end

    %% Join
    function join(obj)
      obj.assertEqual(FilePath("one").join(""), FilePath("one"));
      obj.assertEqual(FilePath("one").join(["one", "two"]), FilePath("one/one", "one/two"));
      obj.assertEqual(FilePath("one", "two").join("one"), FilePath("one/one", "two/one"));
      obj.assertEmpty(FilePath.empty.join("one"), FilePath);
      obj.assertEqual(FilePath("one").join(strings(0)), FilePath("one"));
      obj.assertError(@() FilePath("one", "two", "three").join(["one", "two"]), "FilePath:join:LengthMismatch");
      obj.assertEqual(FilePath("a").join("b", 'c', {'d', "e", "f"}), FilePath("a/b", "a/c", "a/d", "a/e", "a/f"));
      obj.assertEqual(FilePath("one").join(["one.a", "two.b"]), FilePath("one/one.a", "one/two.b"));

      [file1, file2] = FilePath("a").join("b.c", "d.e");
      obj.assertEqual(file1, FilePath("a/b.c"));
      obj.assertEqual(file2, FilePath("a/d.e"));

      obj.assertError(@testFun, "FilePath:deal:InvalidNumberOfOutputs");
      function testFun
        [file1, file2, file3] = FilePath("a").join("b.c", "d.e");
      end
    end

    function mrdivide(obj)
      obj.assertEqual(FilePath("one") / "two", FilePath("one/two"));
      [file1, file2] = FilePath("a") / ["b.c", "d.e"]; %#ok<RHSFN>
      obj.assertEqual(file1, FilePath("a/b.c"));
      obj.assertEqual(file2, FilePath("a/d.e"));

      obj.assertError(@testFun, "FilePath:deal:InvalidNumberOfOutputs");
      function testFun
        [file1, file2, file3] = FilePath("a") / ["b.c", "d.e"]; %#ok<RHSFN>
      end
    end

    function mldivide(obj)
      obj.assertEqual(FilePath("one") \ "two", FilePath("one/two"));
      [file1, file2] = FilePath("a") \ ["b.c", "d.e"]; %#ok<RHSFN>
      obj.assertEqual(file1, FilePath("a/b.c"));
      obj.assertEqual(file2, FilePath("a/d.e"));

      obj.assertError(@testFun, "FilePath:deal:InvalidNumberOfOutputs");
      function testFun
        [file1, file2, file3] = FilePath("a") \ ["b.c", "d.e"]; %#ok<RHSFN>
      end
    end

    function addSuffix(obj)
      obj.assertEqual(FilePath("a/b.c").addSuffix("_s"), FilePath("a/b.c_s"))
      obj.assertEqual(FilePath("a/b.c", "d/e").addSuffix("_s"), FilePath("a/b.c_s", "d/e_s"));
      obj.assertEqual(FilePath("a/b.c", "d/e").addSuffix(["d\e.f", "g\h\i.j"]), FilePath("a/b.cd\e.f", "d/eg\h\i.j"));
      obj.assertEqual(FilePath.empty.addSuffix("s"), FilePath.empty);
      obj.assertError(@() FilePath("a/b.c", "d/e").addSuffix(["_s1", "_s2", "_s3"]), "FilePath:Validation:InvalidSize");
    end

    function plus_left(obj)
      obj.assertEqual(FilePath("a/b.c") + "_s", FilePath("a/b.c_s"))
      obj.assertEqual(FilePath("a/b.c", "d/e") + "_s", FilePath("a/b.c_s", "d/e_s"));
      obj.assertEqual(FilePath("a/b.c", "d/e") + ["d\e.f", "g\h\i.j"], FilePath("a/b.cd\e.f", "d/eg\h\i.j"));
      obj.assertEqual(FilePath.empty + "s", FilePath.empty);
      obj.assertError(@() FilePath("a/b.c", "d/e") + ["_s1", "_s2", "_s3"], "FilePath:Validation:InvalidSize");
    end

    function plus_right(obj)
      obj.assertEqual("a/b.c" + FilePath("_s"), FilePath("a/b.c_s"))
      obj.assertEqual(["a/b.c", "d/e"] + FilePath("_s"), FilePath("a/b.c_s", "d/e_s"));
      obj.assertEqual(["a/b.c", "d/e"] + FilePath(["d\e.f", "g\h\i.j"]), FilePath("a/b.cd\e.f", "d/eg\h\i.j"));
      obj.assertEqual(strings(0) + FilePath("s"), FilePath.empty);
      obj.assertError(@() ["a/b.c", "d/e"] + FilePath(["_s1", "_s2", "_s3"]), "FilePath:Validation:InvalidSize");
    end

    function tempFileName(obj)
      obj.assertEqual(FilePath("a").tempFileName(0), FilePath.empty);
      files = FilePath("a").tempFileName(2);
      obj.assertLength(files, 2);
      obj.assertNotEqual(files(1), files(2));
      obj.assertEqual(files(1).parent, FilePath("a"));
    end

    %% File system interaction
    function cd(obj)
      obj.testDir.mkdir;
      actual = pwd;
      expected = obj.testDir.cd.char;
      obj.assertEqual(actual, expected);
      obj.assertEqual(pwd, obj.testDir.char);
      cd(actual);
    end

    function mkdir(obj)
      obj.testDir.join(["a", "b/a"]).mkdir;
      obj.assertDirExists(obj.testDir / ["a", "b/a"]);
    end

    function createEmptyFile(obj)
      obj.testDir.join("a.b", "c/d.e").createEmptyFile;
      obj.assertFileExists(obj.testDir / ["a.b", "c/d.e"]);
    end

    function isFileAndIsDir(obj)
      paths = obj.testDir / ["a.b", "c/d.e"];
      obj.assertEqual(paths.exists, [false, false]);
      obj.assertEqual(paths.isDir, [false, false]);
      obj.assertEqual(paths.isFile, [false, false]);
      obj.assertError(@() paths.mustExist, "FilePath:NotFound");
      obj.assertError(@() paths.mustBeDir, "FilePath:NotFound");
      obj.assertError(@() paths.mustBeFile, "FilePath:NotFound");

      paths.createEmptyFile;
      obj.assertEqual(paths.exists, [true, true]);
      obj.assertEqual(paths.isFile, [true, true]);
      obj.assertEqual(paths.isDir, [false, false]);
      paths.mustExist;
      paths.mustBeFile;
      obj.assertError(@() paths.mustBeDir, "FilePath:NotADir");

      delete(paths(1).string, paths(2).string);
      paths.mkdir;

      obj.assertEqual(paths.exists, [true, true]);
      obj.assertEqual(paths.isDir, [true, true]);
      obj.assertEqual(paths.isFile, [false, false]);
      paths.mustExist;
      paths.mustBeDir
      obj.assertError(@() paths.mustBeFile, "FilePath:NotAFile");
    end

    function fopen(obj)
      file = obj.testDir / "a.b";
      file.parent.mkdir;
      [id, errorMessage] = file.fopen("w", "n", "UTF-8");
      obj.assertFalse(id == -1);
      obj.assertEqual(errorMessage, '');
      fclose(id);
      obj.assertError2(@() fopen([file, file]), ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);
    end

    function open(obj)
      file = obj.testDir / "a.b";
      obj.assertError2(@() open([file, file]), ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);
      obj.assertError(@() file.open, "FilePath:NotFound");
      id = file.open("w");
      obj.assertFalse(id == -1);
      fclose(id);

      % Assert that auto clean closes the file.
      id = openWithCleaner(file);
      obj.assertFalse(id == -1);
      obj.assertError(@() fclose(id), "MATLAB:badfid_mx");

      % Assert that auto clean does not raise an error if the file
      % has already been closed.
      openWithCleaner(file);

      function id = openWithCleaner(file)
        [id, autoClean] = file.openForReading;
      end

      function openWithCleaner2(file)
        [id, autoClean] = file.openForReading;
        fclose(id);
      end
    end

    function listFiles(obj)
      files = obj.testDir / ["a.b", "c.d", "e/f.g"];
      files.createEmptyFile;
      dirs = [obj.testDir, obj.testDir];
      obj.assertEqual(dirs.listFiles, obj.testDir / ["a.b", "c.d"]);
      obj.assertError(@() FilePath("klajsdfoi67w3pi47n").listFiles, "FilePath:NotFound");
    end

    function listDeepFiles(obj)
      files = obj.testDir.join("a.b", "c.d", "e/f/g.h");
      files.createEmptyFile;
      dirs = [obj.testDir, obj.testDir];
      obj.assertEqual(dirs.listDeepFiles, obj.testDir.join("a.b", "c.d", "e/f/g.h"));
      obj.assertError(@() FilePath("klajsdfoi67w3pi47n").listDeepFiles, "FilePath:NotFound");
      emptyDir = obj.testDir.join("empty");
      emptyDir.mkdir;
      obj.assertEqual(emptyDir.listDeepFiles, FilePath.empty);
    end

    function listDirs(obj)
      files = obj.testDir / ["a.b", "c/d.e", "e/f/g.h", "i/j.k"];
      files.createEmptyFile;
      dirs = [obj.testDir, obj.testDir];
      obj.assertEqual(dirs.listDirs, obj.testDir / ["c", "e", "i"]);
      obj.assertError(@() FilePath("klajsdfoi67w3pi47n").listDirs, "FilePath:NotFound");
    end

    function listDeepDirs(obj)
      files = obj.testDir / ["a.b", "c/d.e", "e/f/g.h", "i/j.k"];
      files.createEmptyFile;
      dirs = [obj.testDir, obj.testDir];
      obj.assertEqual(dirs.listDeepDirs, obj.testDir / ["c", "e", "e/f", "i"]);
      obj.assertError(@() FilePath("klajsdfoi67w3pi47n").listDeepDirs, "FilePath:NotFound");
    end

    function delete_(obj)

      % Delete files
      files = obj.testDir / ["a.b", "c/d.e", "e/f"];
      files(1:2).createEmptyFile;
      obj.assertTrue(all(files(1:2).isFile));
      files.delete;
      obj.assertFalse(any(files.isFile));

      dirs = obj.testDir / ["a", "b"];
      dirs.mkdir;
      dirs(1).join("c.d").createEmptyFile;
      %obj.assertError(@() dirs(1).delete, "MATLAB:RMDIR:NoDirectoriesRemoved");
      obj.assertError(@() dirs(1).delete, "MATLAB:RMDIR:DirectoryNotRemoved");
      dirs.delete("s");
      obj.assertDirDoesNotExist(dirs);
    end

    function readText(obj)
      expected = sprintf("line1\nline2\n");
      file = obj.testDir / "a.txt";
      fileId = file.openForWritingText;
      fprintf(fileId, "%s", expected);
      fclose(fileId);
      actual = file.readText;
      obj.assertEqual(actual, expected);
    end

    function writeText(obj)
      expected = sprintf("line1\nline2\n");
      file = obj.testDir / "a.txt";
      file.writeText(expected);
      actual = string(fileread(file.string));
      actual = actual.replace(sprintf("\r\n"), newline);
      obj.assertEqual(actual, expected);
    end

    function bytes(obj)
      oldDir = FilePath.here.cd;
      file1 = "../FilePath.m";
      fileInfo(1) = dir(file1);
      fileInfo(2) = dir("test_FilePath.m");
      obj.assertEqual(FilePath(file1, "test_FilePath.m").bytes, [fileInfo(1).bytes, fileInfo(2).bytes]);
      obj.assertEqual(FilePath.empty.bytes, zeros(1, 0));
      oldDir.cd;

      obj.testDir.mkdir;
      obj.assertError(@() obj.testDir.bytes, "FilePath:NotAFile");
    end

    function modifiedDate(obj)
      files = obj.testDir.join("a.b", "c.d");
      files.createEmptyFile;
      content = dir(obj.testDir.string);
      actual(1) = datetime(content({content.name} == "a.b").datenum, "ConvertFrom", "datenum");
      actual(2) = datetime(content({content.name} == "c.d").datenum, "ConvertFrom", "datenum");
      obj.assertEqual(actual, files.modifiedDate);

      actual = datetime(content({content.name} == ".").datenum, "ConvertFrom", "datenum");
      obj.assertEqual(actual, obj.testDir.modifiedDate)
    end

    %% Copy and move
    function copy_n_to_n(obj)
      sourceFiles = obj.testDir / ["a.b", "c/d.e"];
      sourceDirs = obj.testDir / ["f", "g"];
      targets = obj.testDir / ["f.g", "h/i.j", "k", "l/m"];

      files = obj.testDir / ["f/b.c", "g/e/f.h"];
      files.createEmptyFile;
      sourceFiles.createEmptyFile;

      sources = [sourceFiles, sourceDirs];
      sources.copy(targets);

      expectedNewFiles = obj.testDir / ["k/b.c", "l/m/e/f.h"];
      expectedNewFiles.mustBeFile;
      targets(1:2).mustBeFile;
      targets(3:4).mustBeDir;
      sourceFiles.mustBeFile;
      sourceDirs.mustBeDir;
    end

    function copy_File_1_to_n(obj)
      source = obj.testDir / "k.l";
      targets = obj.testDir / ["m.n", "o/p.q"];

      source.createEmptyFile;
      source.copy(targets);

      source.mustBeFile;
      targets.mustBeFile;
    end

    function copy_Dir_1_to_n(obj)
      files = obj.testDir / "a/b.c";
      files.createEmptyFile;

      sources = obj.testDir / "a";
      targets = obj.testDir / ["i", "j/k"];

      sources.copy(targets);

      targets.mustBeDir;
      newFiles = obj.testDir / ["i/b.c", "j/k/b.c"];
      newFiles.mustBeFile;
      sources.mustBeDir;
    end

    function copy_n_to_1(obj)
      sources = obj.testDir / ["a.b", "c/d.e"];
      targets = obj.testDir / "f.g";

      obj.assertError2(@() sources.copy(targets), "FilePath:copyOrMove:InvalidNumberOfTargets")
    end

    function copyToDir_n_to_1(obj)
      sources = obj.testDir / ["a.b", "c/d.e", "f/g"];
      obj.testDir.join("f/g/h/i.j").createEmptyFile;
      sources(1:2).createEmptyFile;
      sources(3).mkdir;
      target = obj.testDir / "target";

      sources.copyToDir(target);

      target.join(sources(1:2).name).mustBeFile;
      target.join(sources(3).name).mustBeDir;
      target.join("g/h/i.j").mustBeFile;
      sources.mustExist;
    end

    function copyToDir_File_1_to_n(obj)
      source = obj.testDir / "a.b";
      targets = obj.testDir / ["t1", "t2"];
      source.createEmptyFile;

      source.copyToDir(targets);

      targets.join(source.name).mustBeFile;
      source.mustBeFile;
    end

    function copyToDir_Dir_1_to_n(obj)
      source = obj.testDir / "a";
      source.join("b/d.c").createEmptyFile;
      targets = obj.testDir / ["t1", "t2"];

      source.copyToDir(targets);

      targets.join("a/b/d.c").mustBeFile;
      source.mustExist;
    end

    function copyToDir_n_to_n(obj)
      sources = obj.testDir / ["a.b", "c/d.e", "f/g"];
      obj.testDir.join("f/g/h/i.j").createEmptyFile;
      sources(1:2).createEmptyFile;
      sources(3).mkdir;

      targets = obj.testDir / ["t1", "t2", "t3"];

      sources.copyToDir(targets);
      targets(1:2).join(sources(1:2).name).mustBeFile;
      targets(3).join("g/h/i.j").mustBeFile;
      sources.mustExist;
    end

    function move_n_to_n(obj)
      sources = obj.testDir / ["a", "d/e.f"];
      targets = obj.testDir / ["f", "h/i.j"];
      sources(2).createEmptyFile;
      sources(1).join("b.c").createEmptyFile;

      sources.move(targets);
      targets(1).join("b.c").mustBeFile;
      targets(2).mustBeFile;
      obj.assertAllFalse(sources.exists);
    end

    function move_1_to_n(obj)
      source = obj.testDir / "a.b";
      targets = obj.testDir / ["f.g", "h/i.j"];
      obj.assertError2(@() source.move(targets), "FilePath:copyOrMove:InvalidNumberOfTargets")
    end

    function move_n_to_1(obj)
      source = obj.testDir / ["a.b", "c.d"];
      targets = obj.testDir / "e.g";
      obj.assertError2(@() source.move(targets), "FilePath:copyOrMove:InvalidNumberOfTargets")
    end

    function moveToDir_n_to_1(obj)
      sources = obj.testDir / ["a.b", "c"];
      target = obj.testDir / "t";
      sources(1).createEmptyFile;
      sources(2).join("d.e").createEmptyFile;

      sources.moveToDir(target);

      target.join(sources(1).name).mustBeFile;
      target.join("c/d.e").mustBeFile
      obj.assertAllFalse(sources.exists);

      FilePath.empty.moveToDir(target);
    end

    function moveToDir_n_to_n(obj)
      sources = obj.testDir / ["a.b", "c"];
      targets = obj.testDir / ["t", "t2"];
      sources(1).createEmptyFile;
      sources(2).join("d.e").createEmptyFile;

      sources.moveToDir(targets);

      targets(1).join(sources(1).name).mustBeFile;
      targets(2).join("c/d.e").mustBeFile;
      obj.assertAllFalse(sources.exists);
    end

    function moveToDir_1_to_n(obj)
      source = obj.testDir / "a.b";
      targets = obj.testDir / ["t1", "t2"];
      obj.assertError2(@() source.moveToDir(targets), "FilePath:copyOrMove:InvalidNumberOfTargets")
    end

    %% Save and load
    function save(obj)
      a = 1;
      b = "test";
      file = obj.testDir / "data.mat";
      file.save("a", "b");
      clearvars("a", "b");
      load(file.string, "a", "b");
      obj.assertEqual(a, 1);
      obj.assertEqual(b, "test");
    end

    function load(obj)
      a = 1;
      b = "test";
      file = obj.testDir / "data.mat";
      obj.testDir.mkdir;
      save(file.string, "a", "b");
      clearvars("a", "b");
      [a, b] = file.load("a", "b");
      obj.assertEqual(a, 1);
      obj.assertEqual(b, "test");

      raisedError = false;
      try
        a = file.load("a", "b");
      catch exception
        obj.assertEqual(string(exception.identifier), "FilePath:load:InputOutputMismatch");
        raisedError = true;
      end
      obj.assertTrue(raisedError);
      raisedError = false;
      warning("off", "MATLAB:load:variableNotFound");
      try
        c = file.load("c");
      catch exception
        obj.assertEqual(string(exception.identifier), "FilePath:load:VariableNotFound");
        raisedError = true;
      end
      warning("on", "MATLAB:load:variableNotFound");
      obj.assertTrue(raisedError);
    end

  end
end

function s = adjustSeparators(s)
  s = s.replace(["/", "\"], filesep);
end
