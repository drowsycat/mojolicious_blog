package MyBlog;
use Mojo::Base 'Mojolicious';
use Mojo::Util qw(slurp);
use Serve;

# This method will run once at server start
#----------------------------------------
sub startup {
#----------------------------------------
  my $self = shift;
  $self->mode('development');
  $self->plugin( 'bootstrap_pagination' );
  
  # Documentation browser under "/perldoc"
  #$self->plugin('PODRenderer');
  $self->secrets(['Mojolicious rocks']);
 
    # Хелпер для об'єкта визначення задіяного шаблону
    $self->helper(template => sub { slurp 'public/document/work_routine' });
    # Хелпер для об'єкта допоміжного класу 'Serve'
    $self->helper(serve => sub { state $serve = Serve->new });
    # Хелпер для об'єкта конфігурації найвищого рівня (Об'єкт, де міститься інфа про шаблони, мови і т. п.)
    $self->helper(top_config => sub {$self->plugin('JSONConfig', {file => 'conf/'.$self->template.'/top_conf.json'})});
    # Хелпер для об'єкта визначення службових фраз
    $self->helper(lang_config => sub {state $lang_conf = $self->plugin('JSONConfig', {file => 'conf/lang_conf.json'})});
    # Хелпер для визначення стилю мініатюр зображень
    $self->helper(thumb_img_style => sub { slurp 'conf/thumb_img_style' });
    # Хелпер для формування псевдоніма (англійською) назви розділу (підрозділу)
    $self->helper(alias_modif => sub { 
        my $self = shift;
        my $arg = shift if(@_);
        $arg =~ s/[\s\W]+/_/g; return $arg; 
    });
    # Хелпер для чистки тексту статті для індексації
    $self->helper(clean_text => sub { my $self = shift;
        my $arg = shift if(@_); $arg =~ s/\&nbsp\;/ /g;
                                $arg =~ s/\&raquo\;/ /g;
                                $arg =~ s/\&mdash\;/ /g;
                                $arg =~ s/\&laquo\;/ /g;
                                $arg =~ s/\s+/ /g;
                                $arg =~ s/\<[^<>]+\>//g;
                                $arg =~ s/[&;`\\|\"\*?~^()\$\n\r]+//g;
        return $arg; 
    });
    # Хелпер для отримання масиву правильних розширень завантажуваних файлів зображень
    $self->helper(valid_img_format => sub {['.jpg', '.gif', '.png', '.bmp']});
    # Хелпер для отримання масиву правильних розширень завантажуваних файлів документів
    $self->helper(valid_doc_format => sub {['.doc', '.docx', '.pdf', '.txt']});
    # Хелпер для отримання масиву правильних розширень завантажуваних файлів медіа
    $self->helper(valid_media_format => sub {['.flv', '.mp3', '.mp4', '.avi']});
    
  my $template = $self->template;

  # Router
  my $r = $self->routes;

  # Normal route to controller
  #$r->get('/')->to('example#welcome');
  $r->any('/access')->to('author#access');
  $r->any('/dbaccess')->to('author#dbaccess');
  $r->any('/admin')->to('author#admin');
  $r->any('/registration')->to('login-auth#registration');
  
  my $logged_in = $r->under->to('login#logged_in');
  $logged_in->any('/manager')->to('manager#start');
  $logged_in->any('/menu_manage')->to('menu#menu_manage')->name('menu_manage');
  $logged_in->any('/list_content_manage')->to('list#list_content');
  $logged_in->any('/article_manage')->to('list#article');
  $logged_in->any('/thumb_img')->to('thumb#thumb_img');
  $logged_in->any('/add_rubric')->to('rubric#add_rubric');
  $logged_in->any('/edit_rubric')->to('rubric#edit_rubric');
  $logged_in->any('/upload_image')->to('upload#upload')->name('upload_image');
  $logged_in->any('/upload_document')->to('upload#upload')->name('upload_document');
  $logged_in->any('/upload_media')->to('upload#upload')->name('upload_media');
  
  $logged_in->any('/comments_setting')->to('comments#comments_setting');
  $logged_in->any('/rss_setting')->to('rss#rss_setting');
  $logged_in->any('/pagination_articl')->to('pagination#pgn_articl');
  
  $r->route('/mytemplate')->to(namespace => $template, action => 'mytemplate')->name('mytemplate');

  $r->route('/calendar')->to('calendar#calendar')->name('calendar');
  $r->route('/rubric/:id', id => qr/[0-9]+/)->to(namespace => $template.'::RubricList', action => 'show_rubrics')->name('show_rubrics');
  $r->route('/articles-feed')->to('rss#articles_feed')->name('articles-feed');
  $r->route('/comments-feed')->to('rss#comments_feed')->name('comments-feed');
  $r->route('/archive/:year/:month')->to('client#archive', year => qr/\d{4}/, month => qr/\d{2}/)->name('year_month');
  $r->route('/search_artcl')->to('searching#search_artcl')->name('search_artcl');
  
  #$r->route('/')->to('client#index')->name('index');
  # Можна використовувати простір імен, пов'язаний з встановленим шаблоном !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  $r->route('/foo')->to(namespace => $template.'::Foo', action => 'foo')->name('foo');
  
  #$r->route('/:chapter', chapter => qr/[\d\_a-zA-Z]+/)->to('client#index')->name('chapter');
  $r->route('/:chapter', chapter => qr/[\d\_a-zA-Z]+/)->to(namespace => $template, action => 'index')->name('chapter');
  #$r->route('/:chapter/:subchapter', chapter => qr/[\d\_a-zA-Z]+/, 
  #                                   subchapter => qr/[\d\_a-zA-Z]+/)
  #                                   ->to('client#index')->name('subchapter');
  $r->route('/:chapter/:subchapter', chapter => qr/[\d\_a-zA-Z]+/, 
                                     subchapter => qr/[\d\_a-zA-Z]+/)
                                     ->to(namespace => $template, action => 'index')->name('subchapter');
  $r->route('/:chapter/:id/:article', chapter => qr/[\d\_a-zA-Z]+/, 
                                      id => qr/[0-9]+/, 
                                      article => qr/[\w\d\-]+/)
                                      ->to('client#article')->name('article');
  $r->route('/:chapter/:subchapter/:id/:article', chapter => qr/[\d\_a-zA-Z]+/, 
                                                  id => qr/[0-9]+/, 
                                                  article => qr/[\w\d\-]+/)
                                                  ->to('client#article_sub')->name('article_sub');
  $r->route('/')->to(namespace => $template, action => 'index')->name('index');
                                                  
use DB;  
  state $db = DB->connect_db([@{$self->top_config->{'need_tables_adm'}}]);
}#------------
1;