package Transliter;
use Mojo::Base 'Mojolicious::Controller';

#---------------------------
sub transliter {
#---------------------------
my $self = shift;
my $arg;

if(@_){ ($arg) = @_; }

$arg =~ tr/АБВГДЕЄЖЗИІЇЙКЛМНОПРСТУФХЦЧШЩЮЯЬЪЭЫИ/абвгдеєжзиіїйклмнопрстуфхцчшщюяьъэыи/;
$arg =~ tr/абвгдеєжзиіїйклмнопрстуфхцчшщюяьъэыи«»`/abvhdeegzyiijklmnoprstufxzcccuj__eyi___/;
$arg =~ s/[\W]+/\_/g;

return $arg;
}#----------------
1;