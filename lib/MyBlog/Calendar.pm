package MyBlog::Calendar;
use Mojo::Base 'Mojolicious::Controller';
use MyBlog::NumMonth;
#use Mojo::Parameters;

#---------------------------
sub calendar {
#---------------------------
my $self = shift;

my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
# Хеш 'число-назва місяця'
my %Num_mon = MyBlog::NumMonth->new->num_month($self);

my $current_val = $self->param('number');
$current_val = 1 unless $self->param('number');
$current_val++ if($self->param('number'));

$self->render(
template     => lc($template).'/calendar', 
language     => $language,
num_month    => {%Num_mon},
current_val  => $current_val 
);
}#-------------
1;