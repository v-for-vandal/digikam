.pragma library

function defaultArrayAccessor( array, index ) {
    return array[index];
}

// Returns position of the element equal to value. If there is not one,
// then returns position that element should be inserted, in form (-x -1)
function binarySearch( array, value, accessor, start, end ) {
    if( start === undefined || start < 0) {
        start = 0;
    }
    if( end === undefined ) {
        console.assert( array.length !== undefined, "array has no length property. Use explicit value for 'end' argument")
        end = array.length;
    }

    if( start >= end ) {
        return -1;
    }
    if( accessor === undefined) {
        accessor = defaultArrayAccessor;
    }

    var low = start;
    var high = end;

    while( low < high ) {
        var mid = Math.floor( (low + high) / 2 );
        var midValue = accessor(array, mid);
        if( midValue < value) {
            low = mid + 1;
        } else if( midValue > value) {
            high = mid;
        } else {
            return mid;
        }
    }

    // Not found
    return -low - 1;
}
