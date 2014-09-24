package MyBlog::Manager;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(slurp spurt trim);
#use Data::Dumper;
use MyBlog::RegExp;
use MyBlog::MenuForm;
use DB::Create;
use DB::Insert;
use DB::Select;
use Serve;
use Transliter;

#---------------------------------
sub start {
#---------------------------------
my $self = shift;

my(%err_hash, $message);
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;

$self->render(
language => $language,
message => 'OK!',
title => $self->lang_config->{'labels'}->{$language}->{'masterroom'}
);
}#---------------
1;