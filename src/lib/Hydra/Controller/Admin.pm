package Hydra::Controller::Admin;

use strict;
use warnings;
use base 'Hydra::Base::Controller::REST';
use Hydra::Helper::Nix;
use Hydra::Helper::CatalystUtils;
use Hydra::Helper::AddBuilds;
use Data::Dump qw(dump);
use Digest::SHA1 qw(sha1_hex);
use Config::General;


sub admin : Chained('/') PathPart('admin') CaptureArgs(0) {
    my ($self, $c) = @_;
    requireAdmin($c);
    $c->stash->{admin} = 1;
}


sub users : Chained('admin') PathPart('users') Args(0) : ActionClass('REST') { }

sub users_GET {
    my ($self, $c) = @_;
    $c->stash->{template} = 'users.tt';
    $self->status_ok(
        $c,
        entity => [$c->model('DB::Users')->search({},{
            order_by => "me.username",
            columns => [ 'fullname', 'emailonerror', 'username', 'emailaddress' ],
            prefetch => 'userroles',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        })]
    );
}


sub machines : Chained('admin') PathPart('machines') Args(0) : ActionClass('REST') { }

sub machines_GET {
    my ($self, $c) = @_;
    $c->stash->{template} = 'machines.tt';
    $self->status_ok(
        $c,
        entity => getMachines
    );
}


sub failedcache : Chained('admin') Path('failed-cache') Args(0) : ActionClass('REST') { }

sub failedcache_DELETE {
    my ($self, $c) = @_;
    my $r = `nix-store --clear-failed-paths '*'`;
    $self->status_ok(
        $c,
        entity => {}
    );
}


sub vcscache : Chained('admin') Path('vcs-cache') Args(0) : ActionClass('REST') { }

sub vscache_DELETE {
    my ($self, $c) = @_;

    print "Clearing path cache\n";
    $c->model('DB::CachedPathInputs')->delete_all;

    print "Clearing git cache\n";
    $c->model('DB::CachedGitInputs')->delete_all;

    print "Clearing subversion cache\n";
    $c->model('DB::CachedSubversionInputs')->delete_all;

    print "Clearing bazaar cache\n";
    $c->model('DB::CachedBazaarInputs')->delete_all;

    $self->status_ok(
        $c,
        entity => {}
    );
}


sub managenews : Chained('admin') Path('news') Args(0) {
    my ($self, $c) = @_;

    $c->stash->{newsItems} = [$c->model('DB::NewsItems')->search({}, {order_by => 'createtime DESC'})];

    $c->stash->{template} = 'news.tt';
}


sub news_submit : Chained('admin') Path('news/submit') Args(0) {
    my ($self, $c) = @_;

    requirePost($c);

    my $contents = trim $c->request->params->{"contents"};
    my $createtime = time;

    $c->model('DB::NewsItems')->create({
        createtime => $createtime,
        contents => $contents,
        author => $c->user->username
    });

    $c->res->redirect("/admin/news");
}


sub news_delete : Chained('admin') Path('news/delete') Args(1) {
    my ($self, $c, $id) = @_;

    txn_do($c->model('DB')->schema, sub {
        my $newsItem = $c->model('DB::NewsItems')->find($id)
          or notFound($c, "Newsitem with id $id doesn't exist.");
        $newsItem->delete;
    });

    $c->res->redirect("/admin/news");
}


1;
