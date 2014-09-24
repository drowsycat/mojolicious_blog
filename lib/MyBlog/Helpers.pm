package MyBlog::Helpers;
use Mojolicious::Plugins;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

#--------------------------------
sub register {
#--------------------------------
my($self, $app) = shift;

$app->helper(mypluginhelper => sub { return 'I am your helper and I live in a plugin!'; });
# Хелпер для об'єкта конфігурації найвищого рівня (Об'єкт, де міститься інфа про шаблони, мови і т. п.)
$app->helper(top_config => sub {$app->plugin('JSONConfig', {file => 'conf/top_conf.json'})});

}#-------------
1;