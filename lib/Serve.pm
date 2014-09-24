package Serve;
use Mojo::Base 'Mojolicious::Controller';
use strict;
use warnings;

#----------------------------------------------
sub new{
#----------------------------------------------
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my $self = {};

   bless($self, $class);
return $self;
}#-------------

#---------------------------------
sub err_hash_fields{
#---------------------------------
my($self, $c, $arr_ref, $message) = @_;
my %err_hash;
my $language = $c->top_config->{'exist_langs'};
my $empty_field_mess = $c->lang_config->{'empty_field'}->{$language} || 'Empty field';

    foreach(@$arr_ref){
        # Формуємо хеш повідомлень про незаповнене поле форми
        $err_hash{$_} = $empty_field_mess if(!$c->param($_));
    }

return %err_hash;
}#--------

#---------------------------------
sub err_hash_fields_comments{
#---------------------------------
use Mojo::Util qw(trim);
my($self, $c, $arr_ref, $message) = @_;
my %err_hash;
my $language = $c->top_config->{'exist_langs'};
my $empty_field_mess = $c->lang_config->{'empty_field'}->{$language} || 'Empty field';

    foreach(@$arr_ref){
        if($_ eq 'log_in' || $_ eq 'passw'){
            my $val = trim($c->param($_));
            $val = $c->session('client')->[1] if( !$val && $c->session('client') );
            # Формуємо хеш повідомлень про незаповнене поле форми
            $err_hash{$_} = $empty_field_mess if(!$val);
        }else{
            $err_hash{$_} = $empty_field_mess if(!$c->param($_));
        }
    }

return %err_hash;
}#--------

#---------------------------------
sub err_hash_fields_plus{
#---------------------------------
my($self, $c, $arr_ref, $message) = @_;
my %err_hash;
my $empty_field_mess = $message;

        $err_hash{$arr_ref} = $empty_field_mess; # if(!$c->param($_));

return $err_hash{$arr_ref};
}#--------

#-------------------------------------
sub select_struct {
#-------------------------------------
my($self, $levels_arr_ref) = @_;
my %hash_dir_subs;
use Data::Dumper;

#print "\@$levels_arr_ref \= @$levels_arr_ref\n";

# Перебираємо масив з назвами таблиць рівнів меню
foreach my $curr_level(@$levels_arr_ref){
	
my @parent_dir = ();
my $db = DB->db;

# Формуємо масив унікальних значень @parent_dir материнських директорій з таблиці поточного рівня
@parent_dir = $db->query(qq[ SELECT DISTINCT parent_dir FROM $curr_level ORDER BY queue ])->list;

my @hashref_arr = ();

foreach my $curr_parent_dir(@parent_dir){

    @hashref_arr = $db->query(qq[ SELECT * FROM $curr_level WHERE parent_dir = "$curr_parent_dir" ORDER BY queue ])->hashes;
	
    foreach(@hashref_arr){

    $_->{level} = $curr_level;
        if( $hash_dir_subs{$_->{'title_alias'}} ){
            $_->{subs} = $hash_dir_subs{$_->{'title_alias'}};
            my $title_alias = $_->{'title_alias'};
            #print "\$curr_level \= $curr_level \$title_alias \= $title_alias $_->{'list_enable'}";
		
            # Для розділів, що мають вкладені, встановлюємо list_enable = 'no' (односторінковий розділ).
            # Це власне індексна сторінка розділу, де міститься анотація до вкладених розділів
            $db->query(qq[UPDATE $curr_level SET list_enable = 'no' WHERE title_alias = "$title_alias" ]) if($curr_level ne 'level0');
        }
    }

}

#print "\Dumper(\%hash_dir_subs) \=", Dumper(\%hash_dir_subs), "<br>\n";

my @subs_arr = ();

foreach my $curr_parent_dir(@parent_dir){
	foreach(@hashref_arr){
		if($_->{parent_dir} eq $curr_parent_dir){
		push @subs_arr, $_;
		}else{
			@subs_arr = ();
			next;
		}
		
		$hash_dir_subs{$curr_parent_dir} = [@subs_arr];
	}
}	

}############################################################
#print "hash_dir_subs \= ", Dumper(\%hash_dir_subs), "\n";

return \%hash_dir_subs;
}#----------

#-------------------------------------------------
sub get_menu_form {
#-------------------------------------------------
my($self, $c, $data) = @_;
my $menu_form;
my $deviation = 50;
my $select_attr = "";

my $empty_field_alert = $c->lang_config->{'empty_field'}->{ $c->top_config->{'exist_langs'} };
my $new_chapter_label = $c->lang_config->{'labels'}->{ $c->top_config->{'exist_langs'} }->{'new_chapter'};
my $index_for_subs_label = $c->lang_config->{'labels'}->{ $c->top_config->{'exist_langs'} }->{'index_for_subs'};
my $max_level = $c->top_config->{ $c->top_config->{'routine'} }->{'max_level'};
my $db = DB->db();
$db->abstract = SQL::Abstract->new;

my $checkbox_form=<<FORM;
<div class="form-group">
    <div class="col-sm-offset-2 col-sm-10">
      <div class="checkbox">
        <label style="color:red">
<input type="checkbox" name="del_chapter" value="yes"> видалити   
        </label>
        ||
    </div>
  </div>
</div>
FORM

$checkbox_form = "" if( $data->{'level'} eq 'level0' );
	my($templ_list_checked, $templ_without_list_checked, $templ_add_existed);
	
my $level_deviation = $deviation * (split(//, $data->{level}))[-1];
my $level_color = $c->top_config->{'block_color'}->{$data->{level}};

my($count_of_level) = DB::Select->count_rows($data->{level});

$menu_form.=<<HTML;
<div style="text-align:left; 
margin:4px;
width:740px; 
padding:10px;
border-width: thin;
border-color: #A0A0A0;
border-style: solid; 
background-color: $level_color; margin-left: ${level_deviation}px">

<form method="post" action="/menu_manage" onSubmit="return validate_Form(this)" class="form-horizontal" role="form">

<div class="row">

<div class="col-md-4" style="margin-left:15px">

<div class="form-group">
<input class="form-control" type="text" name="title" value="$data->{title}">
</div>

</div>

<div class="col-md-3">
    $checkbox_form
 </div>

<div class="col-md-4">
 <div class="form-group">
 <label for="selectQueue" class="col-sm-5 control-label">черговість:</label>
 <div class="col-xs-5">
  <select class="form-control" id="selectQueue" placeholder="selectQueue" size="1" name="queue">
HTML

for my $curr_queue(1..$count_of_level){
	$select_attr = 'selected' if($curr_queue eq $data->{queue});
	$menu_form.="<option value=\"$curr_queue\" $select_attr>$curr_queue\n";
	$select_attr = "";
}
$menu_form.=<<HTML;
</select>
</div>
</div>
</div>

</div>
HTML

if( $data->{subs} && $data->{level} ne 'level0' ){
	$templ_add_existed = "<b style=\"color: blue\"><u>$index_for_subs_label</u></b>\n";
    $db->update($data->{level}, {'children' => 'yes'}, {'id' => $data->{'id'}});
}else{
    if($data->{'list_enable'} eq 'yes'){$templ_list_checked = 'checked'}
    if($data->{'list_enable'} eq 'no'){$templ_without_list_checked = 'checked'}

	$templ_add_existed=<<HTML;
<div class="row">

<div class="col-xs-2">
<div class="radio">
  <label class="radio-inline">
    <input type="radio" name="list_enable" value="yes" $templ_list_checked> multy
  </label>
</div>
</div>

<div class="col-xs-2">
<div class="radio">
  <label class="radio-inline">
<input type="radio" name="list_enable" value="no" $templ_without_list_checked> one page
  </label>
</div>
</div>

</div>
HTML

}
	$data->{url} =~ s/^[\/]+//;

$menu_form.=<<HTML;

$templ_add_existed

<div>
<br>
description:<br>
<input class="form-control" type="text" name="description" value=\"$data->{description}\">
keywords:<br>
<input type="hidden" name="id" value=\"$data->{'id'}\">
<input type="hidden" name="template" value=\"$data->{'template'}\">
<input class="form-control" type="text" name="keywords" value=\"$data->{keywords}\">
<input type="hidden" name="level" value=\"$data->{level}\">
<input type="hidden" name="url" value=\"/$data->{url}\">
<input type="hidden" name="title_alias" value=\"$data->{'title_alias'}\">
<input type="submit" class="btn btn-primary" style="margin-top:4px" name="edit" value="редагувати">
</div>
</form>

<!------------------------------------------->
<script type="text/javascript">
function validate_Form( editTitle ){
    if ( editTitle.title.value.length < 1 ){
        alert( '$empty_field_alert \"$new_chapter_label\"' );
        return false;
    }
return true;
}
</script>
<!------------------------------------------>
HTML

if( $data->{'level'} ne $max_level ){

$menu_form.=<<HTML;
<form method="post" action="/menu_manage" onSubmit="return validate_form(this)" class="form-horizontal" role="form">
<div class="row">
<div class="form-group" id="mr_menu_download">

<div class="col-sm-3">
        Новий розділ:
    </div>

    <div class="col-md-5">
        <input class="form-control" type="text" name="new_title">
    </div>
    <div class="col-xs-2">
        <div class="radio">
            <label class="radio-inline">
            <input type="radio" name="new_list_enable" value="yes"> multi
            </label>
        </div>
    </div>
    <div class="col-xs-2">
        <div class="radio">
            <label class="radio-inline">
            <input type="radio" name="new_list_enable" value="no"> one page
            </label>
        </div>
    </div>
    
    <div class="col-md-4" style="padding:4px">
    
    <div class="col-xs-4">
        <div class="radio">
            <label class="radio-inline">
            <input type="radio" name="template" value="article"> article
            </label>
        </div>
    </div>
    <div class="col-xs-4">
        <div class="radio">
            <label class="radio-inline">
            <input type="radio" name="template" value="gallery"> gallery
            </label>
        </div>
    </div>
    <div class="col-xs-4">
        <input type="submit" class="btn btn-success" name="add" value="додати новий розділ">
    </div>
    </div>
</div>

<input type="hidden" name="level" value="$data->{level}">
<input type="hidden" name="url" value="/$data->{url}">
<input type="hidden" name="title_alias" value="$data->{title_alias}">
</div>

</form>
HTML

}

if( $data->{'level'} ne $max_level ){
$menu_form.=<<HTML;
<!------------------------------------------->
<script type="text/javascript">
function validate_form( nextLevel ){
    if ( nextLevel.new_title.value.length < 1 ){
        alert( '$empty_field_alert \"$new_chapter_label\"' );
        return false;
    }
return true;
}
</script>
<!------------------------------------------>
HTML

}

if( !$data->{'subs'} || $data->{level} eq 'level0'){
    my $action = '/list_content_manage';
    $action = '/article_manage' if( $data->{'list_enable'} eq 'no' );

$menu_form.=<<HTML;
<form method="post" action=\"$action\">
<br>
<div>

<input type="hidden" name="level_id" value=\"$data->{'id'}\">
<input type="hidden" name="title" value=\"$data->{'title'}\">
<input type="hidden" name="template" value=\"$data->{'template'}\">
<input type="hidden" name="list_enable" value=\"$data->{'list_enable'}\">
<input type="hidden" name="level" value=\"$data->{level}\">
<input type="hidden" name="url" value=\"/$data->{url}\">
<input type="hidden" name="title_alias" value=\"$data->{'title_alias'}\">
<input type="hidden" name="direct" value=\"$data->{title_alias}\">
<input type="submit" class="btn btn-info" name="add_publication" value="контент">

</div>

</form>
HTML

}

$menu_form.="</div>\n";

###########################################################################
return $menu_form;
}#---------------

#-----------------------------------------
sub data_explore {
#-----------------------------------------
my($self, $title_alias, $level, $max_level) = @_;
my($title_als, $levels_string, $parent_dir, $result, $numb_items_in_level);
my $db = DB->db;
$db->abstract = SQL::Abstract->new;

    my $next_level = 'level'.(substr($level, -1, 1) + 1);

    $result = $db->query(qq[ SELECT $next_level.title_alias, $next_level.level, $next_level.parent_dir 
                                FROM $next_level WHERE $next_level.parent_dir = "$title_alias" ]);
                                while( ($title_als, $levels_string, $parent_dir) = $result->list ){
                                    if($levels_string){ 
                                        $levels_string = $levels_string; 
                                        last; 
                                    }

                                }

if( $levels_string ){

    foreach my $curr_level( $level..$max_level ){

        if( $curr_level eq $level ){
            $result = $db->select( $curr_level, ['title_alias'], { title_alias => "$title_alias" } );
            ($numb_items_in_level) = $db->select( $level, ['count(*)'] )->list;
            $db->delete($level, { title_alias => "$title_alias" });
        }else{
            DB::Select->drop_table( $curr_level );
            $result = $db->select( $curr_level, ['title_alias'] );
        }
                     while( my($table) = $result->list ){
                        DB::Select->drop_table( $table );
                     }
                     print "\n";
    }
}
else{
    my($table, $parent_dir) = $db->select( $level, ['title_alias', 'parent_dir'], { title_alias => "$title_alias" } )->list;

    ($numb_items_in_level) = $db->select( $level, ['count(*)'] )->list;
    DB::Select->drop_table( $table );
    $db->delete($level, { title_alias => "$title_alias" });
    
    if( $numb_items_in_level < 2 ){

        DB::Select->drop_table( $level );
        DB::Select->drop_table( $parent_dir );
        my $prev_level = 'level'.(substr($level, -1, 1) - 1);

        if( $prev_level ne 'level0' ){
            $db->delete( $prev_level, { title_alias => "$parent_dir" } );
        }
    }
}

}#----------------
1;