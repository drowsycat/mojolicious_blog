package MyBlog::RegExp;
use Mojo::Base 'Mojolicious::Controller';
use strict;
use warnings;

#---------------------------
sub name_clean {
#---------------------------
my($self, $arg) = @_;

$arg =~ s/[\%\#&;\`\\|\*~<>^()\[\]{}\$\n\r]+//g;
return $arg;
}#-------------

#---------------------------
sub search_clean {
#---------------------------
my($self, $arg) = @_;

$arg =~s/\,\s+/ /g ;
$arg =~ s/\<[^<>]+\>//g;
$arg =~ s/\.+/\./g;
$arg =~ s/\/+/\//g;
$arg =~ s/[&;`"\\|*?~<>^()\[\]{}\$\n\r]+//g;
return $arg;
}#-------------

#---------------------------
sub email_clean {
#---------------------------
my($self, $c, $arg) = @_;
my $err;

$arg =~ s/[\'\%\#&;\:`\\|\*?~<>^()\[\]{}\$\n\r]+//g;

if( !($arg =~ /\@/) ){
    #return $c->stash(email_err => 'Wrong symbols');
    $err = 'Wrong symbols';
}
return($arg, $err);
}#-------------
1;
