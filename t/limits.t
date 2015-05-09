use Native::LibC;
use Test;

plan 1;

is libc::CHAR_BIT, 8;
