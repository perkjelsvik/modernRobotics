% cStruct: A class to deal with structures such as in C.
% 
% All methods are static methods, one can instantiate it to get a shorthand.
%
% For example instead of cStruct.unpack(...), we can do c = cStruct(); c.unpack(...).
%
% With 'bytes' we consider a vector of uint8(). With values we mean a vector
% of doubles. This class is strongly influenced on Python's excellent struct module:
% https://docs.python.org/3.5/library/struct.html
%
%       values = cStruct.unpack(fmt, bytes) - Unpack bytes according to fmt into values.
%       bytes = cStruct.pack(fmt, values) - Pack values according to format into bytes.
%       size = cStruct.calcsize(fmt) - Calculate the bytes necessary to accomodate fmt.
%
% If a format is used more than once, the following two methods can be used to create
% a function. This is more efficient for longer formats, but is more of a convenience.
%
%       pack_fun = cStruct.create_packer(fmt) - Creates a function that performs @(x) cStruct.pack(fmt, x)
%       unpack_fun = cStruct.create_unpacker(fmt) - Creates a function that performs @(x) cStruct.unpack(fmt, x)
%
% The format should be a string with letters representing the type. Spaces are
% ignored.
% The following types are handled, no packing is done (#pragma pack 1)
%        I: uint32_t, i: int32_t
%        H: uint16_t, h: int16_t
%        B: uint8_t, b: int8_t
%        d: double, f: float
%
% Examples:
%               cStruct.unpack('H', [57 05]) == 1337
%               cStruct.unpack('H B', [57 05 39]) == [1337 39]
%               cStruct.pack('hB', [-1337, 08]) == [199 250 8]
%
% MIT License Copyright (c) 2016 Ivor Wanders.


%
% The MIT License (MIT)
%
% Copyright (c) 2016 Ivor Wanders
%
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
%
classdef cStruct
    
    methods
        function obj = cStruct()
            % c = cStruct() Create a shorthand to use the methods in the class.
        end
        function repr = disp(obj)
            disp('cStruct: A class to deal with structures such as in C.');
        end
    end

    properties (SetAccess = immutable, Constant = true, Hidden=true)
        format = struct(...
            'I', struct('unpack', struct('length', 4, 'fun', @(x) typecast(uint8(x), 'uint32')),...
                        'pack', struct('length', 1, 'fun', @(x) typecast(uint32(x), 'uint8'))),...
            'H', struct('unpack', struct('length', 2, 'fun', @(x) typecast(uint8(x), 'uint16')),...
                        'pack', struct('length', 1, 'fun', @(x) typecast(uint16(x), 'uint8'))),...
            'B', struct('unpack', struct('length', 1, 'fun', @(x) typecast(uint8(x), 'uint8')),...
                         'pack', struct('length', 1, 'fun', @(x) typecast(uint8(x), 'uint8'))),...
            'i', struct('unpack', struct('length', 4, 'fun', @(x) typecast(uint8(x), 'int32')),...
                         'pack', struct('length', 1, 'fun', @(x) typecast(int32(x), 'uint8'))),...
            'h', struct('unpack', struct('length', 2, 'fun', @(x) typecast(uint8(x), 'int16')),...
                         'pack', struct('length', 1, 'fun', @(x) typecast(int16(x), 'uint8'))),...
            'b', struct('unpack', struct('length', 1, 'fun', @(x) typecast(uint8(x), 'int8')),...
                         'pack', struct('length', 1, 'fun', @(x) typecast(int8(x), 'uint8'))),...
            'f', struct('unpack', struct('length', 4, 'fun', @(x) typecast(uint8(x), 'single')),...
                         'pack', struct('length', 1, 'fun', @(x) typecast(single(x), 'uint8'))),...
            'd', struct('unpack', struct('length', 8, 'fun', @(x) typecast(uint8(x), 'double')),...
                         'pack', struct('length', 1, 'fun', @(x) typecast(double(x), 'uint8')))...
        ...
        )
    end


    methods(Static, Access=protected)
        
        function [z] = worker(fmt, action, input_vector)
            % worker(fmt, action, bytes) This function does the work of actually converting with the format string.
            %
            % action should be 'pack' or 'unpack', representing the field used from the format property.
            % vector should be a mat of doubles.
            % This walks through the format, interpretes it uses the appropriate length from the
            % input_vector to convert to the right data type, appending that to the result.
            z = []; % result.
            offset = 0; % current offset in input_vector.
            for i=1:size(fmt,2) % run through the format.
                type = fmt(i); % this char represents which datatype is at this position.
                if (type == ' ')
                    continue % disregard space
                end
                % Retrieve the appropriate structure with length and cast function:
                spec = getfield(getfield(cStruct.format, type), action);
                % Get the right slice of the vector:
                slice = input_vector(offset+1:offset+spec.length);
                % Use the function to convert the slice.
                v = spec.fun(slice);
                % Append the result.
                z = [z v];
                % Increment the offset.
                offset = offset + spec.length;
            end
        end

        function fun = create_worker(fmt, action)
            % create_worker(fmt, action) This function creates a function that peforms the necessary action on its
            % argument.
            %
            % action should be 'pack' or 'unpack', representing the field used from the format property.
            % This function creates a function that accepts one input_vector argument that's either bytes or values.
            f = {}; % cell array to hold the functions for each individual part.
            offset = 0; % current offset in the input.
            for i=1:size(fmt,2) % run through the format.
                type = fmt(i); % this char represents which datatype is at this position.
                if (type == ' ')
                    continue % disregard space
                end
                % Retrieve the appropriate structure with length and cast function:
                spec = getfield(getfield(cStruct.format, type), action);
                % Add a function to the list of functions which slices the appropriate part of the input
                f{end+1} = @(input_vector) spec.fun(input_vector(offset+1:offset+spec.length));
                % Increase the offset in the input.
                offset = offset + spec.length;
            end

            % Function in case errors occur, in that case we want to assume there are 0 bytes.
            function result = errorfun(S, varargin)
               result = uint8(0);
            end

            % We have to treat unpack slightly different from pack.
            % This wrapped function ensures that we actually return a matrix from our list of functions based on the
            % input.
            % Using cellfun to apply the input_vector to each element of the cell array f and ultimately convert the
            % cell array back into a matrix.
            % UniformOutput is required because the length of output differs from the input.
            % ErrorHandler ensures that we can read 0 bytes in case we run out of bytes to read in the input vector y.
            if strcmp(action, 'pack')
                fun = @(input_vector) cell2mat(cellfun(@(y) y(input_vector), f, 'UniformOutput', false,...
                                                                                        'ErrorHandler', @errorfun));
            else
                % We have to cast the entire array back to doubles, as matlab won't accept different data types in one
                % matrix.
                % UniformOutput is required because the length of output differs from the input.
                % ErrorHandler ensures that we can read 0 bytes in case we run out of bytes to read in the input vector.
                fun = @(input_vector) cellfun(@(x) double(x), cellfun(@(y) y(input_vector), f, ...
                                                                'UniformOutput', false, 'ErrorHandler', @errorfun));
                % Also, Matlab magically returns a matrix here, instead of a cell array....
            end
        end

    end

    methods(Static)
        function [len] = calcsize(fmt)
            % calcsize(fmt) Calculate the number of bytes the format would occupy.
            len = 0;
            for i=1:size(fmt,2)
                type = fmt(i);
                if (type == ' ')
                    continue
                end
                spec = getfield(getfield(cStruct.format, type), 'unpack');
                len = len + spec.length;
            end
        end

        function [z] = unpack(fmt, bytes)
            % values = unpack(fmt, bytes) Unpack bytes according to fmt.
            % values is of type double.
            z = cStruct.worker(fmt, 'unpack', bytes);
        end

        function [z] = pack(fmt, values)
            % bytes = pack(fmt, values) Pack values into bytes according to fmt.
            % bytes is of type uint8.
            z = cStruct.worker(fmt, 'pack', values);
        end

        function fun = unpacker(fmt)
            % fun = unpacker(fmt) Create unpack function for format.
            % values = fun(bytes), bytes is of type uint8, values of double.
            fun = cStruct.create_worker(fmt, 'unpack');
        end

        function fun = packer(fmt)
            % fun = packer(fmt) Create pack function for format.
            % bytes = fun(values), bytes is of type uint8, values of double.
            fun = cStruct.create_worker(fmt, 'pack');
        end

        function selftest()
            % Perform an extensive selftest.

            % " ".join(["{:d}".format(a) for a in struct.pack('f', 13.37)]
            assert(cStruct.unpack('B', [139]) == 139)
            assert(cStruct.unpack('H', [57 05]) == 1337)
            assert(cStruct.unpack('I', [241 203 245 13]) == 234212337)
            assert(cStruct.unpack('b', [139]) == -117)
            assert(cStruct.unpack('i', [15 52 10 242]) == -234212337)
            assert(cStruct.unpack('h', [199 250]) == -1337)
            assert(single(cStruct.unpack('f', [133 235 85 65])) == single(13.37))
            assert(double(cStruct.unpack('d', [61 10 215 163 112 189 42 64])) == double(13.37))
            p = cStruct.unpacker('B');assert(p([139]) == 139)
            p = cStruct.unpacker('H');assert(p([57 05]) == 1337)
            p = cStruct.unpacker('I');assert(p([241 203 245 13]) == 234212337)
            p = cStruct.unpacker('HBB');assert(all(p([57 05, 139, 110]) == [1337 139 110]))
            assert(cStruct.pack('B', [139]) == 139)
            assert(all(cStruct.pack('H', [1337]) == [57 05]))
            assert(all(cStruct.pack('I', [234212337]) == [241 203 245 13]))
            assert(all(cStruct.pack('b', [-117]) == 139))
            assert(all(cStruct.pack('i', [-234212337]) == [15 52 10 242]))
            assert(all(cStruct.pack('h', [-1337]) == [199 250]))
            assert(all(cStruct.pack('f', [13.37]) == [133 235 85 65]))
            assert(all(cStruct.pack('d', [13.37]) == [61 10 215 163 112 189 42 64]))
            p = cStruct.packer('B');assert(all(p([139]) == 139))
            p = cStruct.packer('H');assert(all(p([1337]) == [57 05]))
            p = cStruct.packer('I');assert(all(p([234212337]) == [241 203 245 13]))
            p = cStruct.packer('i');assert(all(p([-234212337]) == [15 52 10 242]))
            p = cStruct.packer('H BB');assert(all(p([1337 139 110]) == [57 05, 139, 110]))

            assert(cStruct.worker('B', 'unpack',  [139]) == 139)
            assert(cStruct.worker('H', 'unpack', [57 05]) == 1337)
            assert(cStruct.worker('I', 'unpack', [241 203 245 13]) == 234212337)
            assert(all(cStruct.worker('H', 'pack', [1337]) == [57 05]))
            assert(all(cStruct.worker('I', 'pack', [234212337]) == [241 203 245 13]))
            assert(all(cStruct.worker('B', 'pack', [139]) == 139))
            assert(all(cStruct.worker('b', 'pack', [-117]) == 139))

            assert(cStruct.calcsize('B') == 1)
            assert(cStruct.calcsize('H') == 2)
            assert(cStruct.calcsize('d') == 8)
            assert(cStruct.calcsize('f') == 4)
            assert(cStruct.calcsize('f b') == 5)
            
        end

        function benchmark()
            function [z] = benchmark_unpack_factory(fmt)
                len = cStruct.calcsize(fmt);
                useless_input = zeros(1, len);
                function a()
                    foo = cStruct.unpack(fmt, useless_input);
                end
                z = @a;
            end
            function [z] = benchmark_unpacker_factory(fmt)
                len = cStruct.calcsize(fmt);
                useless_input = zeros(1, len);
                preformatted = cStruct.unpacker(fmt);
                function a()
                    foo = preformatted(useless_input);
                end
                z = @a;
            end
            
            N = 1000;
            disp(['Running each test for N=' num2str(N) ' times.']);
            tests = {'B', 'BB', 'BBBB', 'BBBBBBBB', 'BBBBBBBBBBBBBBBB', 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'};
            for t=1:size(tests, 2)
                disp(['Testing unpack(' tests{t} ', ...):'])
                x = benchmark_unpack_factory( tests{t} );
                tic
                    for i=1:N
                        x();
                    end
                toc
                x = benchmark_unpacker_factory( tests{t} );
                disp(['Testing f = unpacker(' tests{t} '), f(...)'])
                tic
                    for i=1:N
                        x();
                    end
                toc
                disp(' ');
            end
        end

    end
end