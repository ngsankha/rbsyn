def sketch_1(x)
    foo = 10
    ## x => String
    x + _? + _? + 1
    # x + x + foo + 1
end

def sketch_2(y)
    ## y => Integer
    sketch_1(_? + 3)
    # sketch_1(y + 3)
end
