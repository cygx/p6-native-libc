use Native::LibC <malloc sizeof>;

class Point is repr('CStruct') {
    has num64 $.x;
    has num64 $.y;
}

my @triangle := malloc(3 * sizeof(Point)).to(Point).grab(3);
@triangle[^3] =
    Point.new(x => 0e0, y => 0e0),
    Point.new(x => 0e0, y => 1.2e0),
    Point.new(x => 1.8e0, y => 0.6e0);

my $com = malloc(sizeof(Point)).to(Point);
$com.lv = Point.new(
    x => ([+] @triangle>>.x) / 3,
    y => ([+] @triangle>>.y) / 3
);

say $com.rv;
