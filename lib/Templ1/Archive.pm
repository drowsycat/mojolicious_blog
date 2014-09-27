package Archive;
use Mojo::Base 'Mojolicious::Controller';
use DB::Select;
use MyBlog::AuthorizeForm;
use Mojo::Util qw(trim encode decode);

#------------------------------------
sub archive_menu {
#------------------------------------
my($self, $c) = @_;
my $language = $c->top_config->{'exist_langs'};
my $template = $c->template;
my $table_archive_menu = $c->top_config->{'table'}->{'archive_menu'};
my(@levels, @title_alias, @year_month, @month, @years, @archive_url, 
   %exist, %exist_year, %year_month, $common_menu, $common_menu_orig);

my $db = DB->db();
$db->abstract = SQL::Abstract->new;

my $levels_obj = DB::Select->like_table_obj_list('level');
while( my($level) = $levels_obj->list ){
    push @levels, $level;
}
foreach(@levels){
    my @title_alias_curr = $db->select($_, ['distinct(title_alias)'])->flat;
    push @title_alias, @title_alias_curr;
}
foreach(@title_alias){
    my $result = $db->select($_, ['distinct(left(curr_date, 7))']);
    while( my($year_month) = $result->list ){
        next if($exist{$year_month});
        push @year_month, $year_month;
        $exist{$year_month} = 1;
    }
}
my $i = 0;
foreach(sort @year_month){
    if($exist_year{(split(/-/, $_))[0]}){
        push @month, (split(/-/, $_))[1];
        $year_month{(split(/-/, $_))[0]} = [@month];
    }else{
        @month = ();
        $exist_year{(split(/-/, $_))[0]} = 1;
        push @month, (split(/-/, $_))[1];
        $year_month{(split(/-/, $_))[0]} = [@month];
    }
$i++;
}

#my $show_class;
#if($i == 0){ $show_class='class="li_month_disable"'; }

print "";

$common_menu = "<div class=\"panel-group\" id=\"accordion\">\n";
foreach(reverse sort keys %year_month){
$common_menu.=<<ARCH_MENU;
    <div>
        <a data-toggle="collapse" data-parent="#accordion" href="#$_">
          $_
        </a>
    </div>
    <div id="$_" class="panel-collapse collapse">
      <div class="panel-body" id="archive_month_block">
      <ul>
ARCH_MENU

    foreach my $month(@{$year_month{$_}}){
        push @archive_url, '/archive/'.$_.'/'.$month;
        $common_menu.="<li id=\"li_archive_month\"><a href=\"/archive/$_/$month\" class=\"archive_month_label\">".$c->lang_config->{'num_month'}->{$month}->{$language}."</a></li>\n";
    }

$common_menu.=<<ARCH_MENU;
      </ul>
      </div>
    </div>
ARCH_MENU

}
$common_menu.="</div>\n";

$common_menu_orig = $common_menu;

my($id) = $db->select($table_archive_menu, ['id'], {'url' => 'common'})->list;
if(!$id){
    $db->insert($table_archive_menu, {'url' => 'common', menu => $common_menu});
}else{
    $db->update($table_archive_menu, {menu => $common_menu}, {'url' => 'common'});
}

    foreach my $curr_url( @archive_url ){
        
        my $curr_year = (split(/\//, $curr_url))[2];
        if($common_menu =~ /(<div id=")($curr_year)\"\s+class\=\"panel\-collapse\s+collapse\">/){
            $common_menu =~ s/(<div id=")($curr_year)\"\s+class\=\"panel\-collapse\s+collapse\">/${1}${2}\" class\=\"panel-collapse collapse in">/;
        }
        if($common_menu =~ /(\<li[^\/]*)($curr_url)([^>]*>)(\w+)(<\/a><\/li>)/){
            my $senc = $4;
            $common_menu =~ s/${1}${2}${3}${4}${5}/<li id\=\"li_archive_month\" class\=\"li_month_disable\">$senc<\/li>/;
        }
        my($url_exist) = $db->select($table_archive_menu, ['id'], {'url' => $curr_url})->list;
        if(!$url_exist){
            $db->insert($table_archive_menu, {'url' => $curr_url, menu => $common_menu});
        }else{
            $db->update($table_archive_menu, {menu => $common_menu}, {'url' => $curr_url});
        }
        $common_menu = $common_menu_orig;

    }

return $common_menu;
}#-------------

#----------------------------------------
sub year_month {
#----------------------------------------
my($app, $self) = @_;
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
my $table_archive_menu = $self->top_config->{'table'}->{'archive_menu'};
my $table_rubric = $self->top_config->{'table'}->{'rubric'};
my $pagination_attr_file = 'conf/pgn_articl';
my(@levels, @title_alias, @year_month, %exist, %date_Data_hash, %total_Data_hash, %pagination_attr, 
   %page_data_hash, %date_Data_hash_mod, 
   $message, @other_data, @other_month, $current_page, $total_pages, $i_begin, $i_end);
my $url = $self->req->url;
$url =~ s/\?page\=.*$//;
my $url_mod = $url;
my @url_components = split(/\//, $url);
my $year = $url_components[-2];
my $year_month_url = $year.'-'.$url_components[-1];
my $month = ucfirst($self->lang_config->{'num_month'}->{$url_components[-1]}->{$language});

my $file = Mojo::Asset::File->new( path => $pagination_attr_file );
my $pagination_attr = $file->slurp;
my @pgn_attr = split(/\|/, $pagination_attr);
$pagination_attr{ (split(/\:/, $pgn_attr[0]))[0] } = (split(/\:/, $pgn_attr[0]))[1];
$pagination_attr{ (split(/\:/, $pgn_attr[1]))[0] } = (split(/\:/, $pgn_attr[1]))[1];
$pagination_attr{ (split(/\:/, $pgn_attr[2]))[0] } = (split(/\:/, $pgn_attr[2]))[1];
$pagination_attr{ (split(/\:/, $pgn_attr[3]))[0] } = (split(/\:/, $pgn_attr[3]))[1];

# Кількість анотацій статей на одній сторінці
my $limit_str = $pagination_attr{'annot_numb'};
$current_page = 1;

#**********************************
if($self->param('page')){
#**********************************
    $current_page = $self->param('page');
    $url_mod =~ s/\?page\=.*$//;
}#***********

my $db = DB->db();
$db->abstract = SQL::Abstract->new;
my $db2 = $db;
$db2->abstract = SQL::Abstract->new;

my $levels_obj = DB::Select->like_table_obj_list('level');
while( my($level) = $levels_obj->list ){
    push @levels, $level;
}
foreach(@levels){
    my @title_alias_curr = $db->select($_, ['distinct(title_alias)'])->flat;
    push @title_alias, @title_alias_curr;
}
foreach(@title_alias){    
    my $result = $db->select($_, ['*'], {curr_date => {like => "$year_month_url%"}});
    while( my $data = $result->hash ){
        my($rubric) = $db2->select( $table_rubric, ['rubric'], {'id' => "$data->{'rubric_id'}"} )->list if($data->{'rubric_id'} != 0);
        $data->{'rubric'} = uc $rubric if $rubric;
        $data->{'children'} = $db2->select( $data->{'level'}, ['children'], {'id' => "$data->{'level_id'}"} )->list;
        if($data->{'children'} eq 'yes'){
        next;
        }
        $data->{'url'} = $db2->select( $data->{'level'}, ['url'], {'id' => "$data->{'level_id'}"} )->list;
        $data->{'url'} = "" if($data->{'url'} eq '/');
        $date_Data_hash{$data->{'curr_date'}} = $data;
    }
}
$total_pages = int( (scalar keys %date_Data_hash)/$limit_str );
$total_pages = $total_pages + 1 if( (scalar keys %date_Data_hash)%$limit_str );

$i_begin = 1 if($current_page == 1);
$i_begin = ($current_page - 1) * $limit_str + 1;
$i_end = ($current_page - 1) * $limit_str + $limit_str;

# Формуємо дані про статті '%date_Data_hash_mod' на даний місяць для діапазону '$i_begin .. $i_end', 
# що відповідає обмеженню $limit_str на кількість анотацій у списку для даної сторінки $current_page
my $i = 1;
foreach(reverse sort keys %date_Data_hash){
    if($i < $i_begin){
        $i++; next;
    }
    if($i > $i_end || !$date_Data_hash{$_}){
        last;
    }
    $date_Data_hash_mod{$_} = $date_Data_hash{$_};

$i++;
}

foreach(@title_alias){
    my $result = $db->query(qq[ SELECT DISTINCT(LEFT(curr_date, 7)) FROM $_ WHERE curr_date LIKE "$year%"
                                AND curr_date NOT LIKE "$year_month_url%"]);
    while( my($year_month) = $result->list ){
        next if($exist{$year_month});
        push @other_month, $year_month;
        $exist{$year_month} = 1;
    }
}

my($menu) = $db->select('level0', ['menu'], {'url' => '/'})->list;
$menu =~ s/\s+class\=\"active\"//;
my($archive_menu) = $db->select($table_archive_menu, ['menu'], {'url' => $url})->list;
$message = MyBlog::AuthorizeForm->authorize_form( $self, uc($template).'/archive' );
my $ref_id_name_rubric = Templ1::RubricList->rubric_list($self);

$self->render(
template => lc($template).'/archive',
language => $language,
current_page => $current_page,
total_pages => $total_pages,
pagination_attr => {%pagination_attr},
url_chaptr => $url_mod,
message => $message,
year_month => $month.' '.$url_components[-2],
menu => $menu,
content => {%date_Data_hash_mod},
other_month => [@other_month],
archive_menu => $archive_menu,
title => $self->lang_config->{'labels'}->{$language}->{'archive'}.'. '.$month.' '.$url_components[-2],
rubrics => $ref_id_name_rubric
);
}#-------------
1;
