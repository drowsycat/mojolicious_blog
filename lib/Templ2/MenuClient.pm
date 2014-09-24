package Templ2::MenuClient;
use Mojo::Base 'Mojolicious::Controller';
#----------------------------------
sub menu{
#----------------------------------
my($self, $c, $ref_hash_dir_subs) = @_;
my %hash_dir_subs = %{$ref_hash_dir_subs};

my $menu_components=<<MENU;
<nav class="navbar navbar-default" role="navigation" id="navbar-1">
<div class="container-fluid">
<div class="collapse navbar-collapse" id="navbar-collapse-1">
<ul class="nav navbar-nav">
MENU

my $select_attr = "";
foreach(@{$hash_dir_subs{NULL}}){#*****************

if($_->{subs} ){
        if( $_->{level} ne 'level0' ){
$menu_components.=<<MENU;
        <li class="dropdown">
        <a href="#" class="dropdown-toggle" data-toggle="dropdown">$_->{title} <span class="caret"></span></a>
        <ul class="dropdown-menu" role="menu">
MENU

        }else{
            $menu_components.="<li><a href=\"$_->{url}\">$_->{title}</a></li>\n";
        }
        my $menu_compnts = __PACKAGE__->select_including( $c, $_->{subs} );
		$menu_components.=$menu_compnts;
	}

} # foreach **************

return $menu_components."</div>\n</div>\n</nav>\n";
}#--------------

#----------------------------------------
sub select_including{
#----------------------------------------
my($self, $c, $ref_subs_content) = @_;
my $menu_subs_components;
my @subs_content = @$ref_subs_content;

foreach my $data(@subs_content){ #---------------

	if( $data->{subs} ){
$menu_subs_components.=<<MENU;
        <li class="dropdown">
        <a href="#" class="dropdown-toggle" data-toggle="dropdown">$data->{title} <span class="caret"></span></a>
        <ul class="dropdown-menu" role="menu">
MENU

        my $menu_subs_compnts = __PACKAGE__->select_including( $c, $data->{subs});
		$menu_subs_components.=$menu_subs_compnts;
	}else{
        $menu_subs_components.="<li><a href=\"$data->{url}\">$data->{title}</a></li>\n";
    }
    
} # foreach ----------------------

return $menu_subs_components."</ul>\n";
}#-------------
1;