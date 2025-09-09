use Test::More tests => 7;
use_ok 'Shape', qw(
    Circle(radius)
    Rectangle(width, height)
    Pointless()
);

my $c = Shape::Circle(5);
is $c->name, 'Circle', 'name is Circle';
is_deeply $c->data, [5], 'data is [5]';
is $c->value, 0, 'ordinal is 0';
ok $c->is('Circle'), 'is Circle';
is "$c", "Circle(5)", 'stringifies correctly';

my $area = $c->match(
    Circle => sub { my ($r) = @_; 3.14 * $r * $r },
    _      => sub { 0 }
);
is $area, 78.5, 'match works';
