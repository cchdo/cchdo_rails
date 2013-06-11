# Utilities for working with file streams

def copy(filea, fileb)
    fileb.write(filea.read())
end
