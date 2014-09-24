package MyBlog::Client;
use Mojo::Base 'Mojolicious::Controller';
use MyBlog::ArticleProper;

#----------------------------------
sub index {
#----------------------------------
my $self = shift;
my $template = $self->template;

require "$template.pm";
my $Template = $template->new;

    # Видаємо ту ж саму індексну сторінку, якщо дані про користувача і його пароль неправдиві
    #return $self->render(template => "$work_routn/main/index", languages => $self->langs, news_block => 'news_block'); # unless $self->users->check($self, $user, $pass);
    return $Template->index($self);
}#-------------

#----------------------------------
sub article {
#----------------------------------
my $self = shift;
my $template = $self->template;
require "$template.pm";
my $Template = $template->new;

my $ref_article_proper = MyBlog::ArticleProper->new->article_proper($self, $template, 'article');

    # Видаємо ту ж саму індексну сторінку, якщо дані про користувача і його пароль неправдиві
    #return $self->render(template => "$work_routn/main/index", languages => $self->langs, news_block => 'news_block'); # unless $self->users->check($self, $user, $pass);
    return $Template->article( $self, $ref_article_proper );
}#-------------

#----------------------------------
sub article_sub {
#----------------------------------
my $self = shift;
my $template = $self->template;
require "$template.pm";
my $Template = $template->new;

my $ref_article_proper = MyBlog::ArticleProper->new->article_proper($self, $template, 'article_sub');

    # Видаємо ту ж саму індексну сторінку, якщо дані про користувача і його пароль неправдиві
    #return $self->render(template => "$work_routn/main/index", languages => $self->langs, news_block => 'news_block'); # unless $self->users->check($self, $user, $pass);
    return $Template->article( $self, $ref_article_proper );
}#-------------

#----------------------------------
sub archive {
#----------------------------------
my $self = shift;
my $template = $self->template;
require "$template.pm";
my $Template = $template->new;

    return $Template->archive($self, $template);
}#-------------
1;