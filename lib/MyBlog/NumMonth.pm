package MyBlog::NumMonth;
use Mojo::Base 'Mojolicious::Controller';

#---------------------------
sub num_month {
#---------------------------
my($self, $c) = @_;

my $language = $c->top_config->{'exist_langs'};
my $template = $c->template;

# Хеш 'число-назва місяця'
my %Num_mon = ('01' => $c->lang_config->{'num_month'}->{'1'}->{$language},
               '02' => $c->lang_config->{'num_month'}->{'2'}->{$language},
               '03' => $c->lang_config->{'num_month'}->{'3'}->{$language},
               '04' => $c->lang_config->{'num_month'}->{'4'}->{$language},
               '05' => $c->lang_config->{'num_month'}->{'5'}->{$language},
               '06' => $c->lang_config->{'num_month'}->{'6'}->{$language},
               '07' => $c->lang_config->{'num_month'}->{'7'}->{$language},
               '08' => $c->lang_config->{'num_month'}->{'8'}->{$language},
               '09' => $c->lang_config->{'num_month'}->{'9'}->{$language},
               '10' => $c->lang_config->{'num_month'}->{'10'}->{$language},
               '11' => $c->lang_config->{'num_month'}->{'11'}->{$language},
               '12' => $c->lang_config->{'num_month'}->{'12'}->{$language},);
return(%Num_mon);
}#-------------
1;