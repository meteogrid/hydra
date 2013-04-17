package Setup;

use strict;
use Exporter;
use Hydra::Helper::Nix;
use Hydra::Model::DB;
use Hydra::Helper::AddBuilds;
use Cwd;
use Digest::SHA1  qw(sha1_hex);
use LWP::UserAgent;
use JSON;
 
our @ISA = qw(Exporter);
our @EXPORT = qw(nrBuildsForJobset queuedBuildsForJobset nrQueuedBuildsForJobset createBaseJobset createJobsetWithOneInput evalSucceeds runBuild updateRepository request_json login);

sub nrBuildsForJobset {
    my ($jobset) = @_;
    return $jobset->builds->search({},{})->count ;
}

sub queuedBuildsForJobset {
    my ($jobset) = @_;
    return $jobset->builds->search({finished => 0});
}

sub nrQueuedBuildsForJobset {
    my ($jobset) = @_;
    return queuedBuildsForJobset($jobset)->count ;
}

sub createBaseJobset {
    my ($jobsetName, $nixexprpath) = @_;

    my $db = Hydra::Model::DB->new;
    my $project = $db->resultset('Projects')->update_or_create({name => "tests", displayname => "", owner => "root"});
    my $jobset = $project->jobsets->create({name => $jobsetName, nixexprinput => "jobs", nixexprpath => $nixexprpath, emailoverride => ""});

    my $jobsetinput;
    my $jobsetinputals;

    $jobsetinput = $jobset->jobsetinputs->create({name => "jobs", type => "path"});
    $jobsetinputals = $jobsetinput->jobsetinputalts->create({altnr => 0, value => getcwd."/jobs"});

    return $jobset;
}

sub createJobsetWithOneInput {
    my ($jobsetName, $nixexprpath, $name, $type, $uri) = @_;
    my $jobset = createBaseJobset($jobsetName, $nixexprpath);

    my $jobsetinput;
    my $jobsetinputals;

    $jobsetinput = $jobset->jobsetinputs->create({name => $name, type => $type});
    $jobsetinputals = $jobsetinput->jobsetinputalts->create({altnr => 0, value => $uri});

    return $jobset;
}

sub evalSucceeds {
    my ($jobset) = @_;
    my ($res, $stdout, $stderr) = captureStdoutStderr(60, ("../src/script/hydra-evaluator", $jobset->project->name, $jobset->name));
    chomp $stdout; chomp $stderr;
    print STDERR "Evaluation errors for jobset ".$jobset->project->name.":".$jobset->name.": \n".$jobset->errormsg."\n" if $jobset->errormsg;
    print STDERR "STDOUT: $stdout\n" if $stdout ne "";
    print STDERR "STDERR: $stderr\n" if $stderr ne "";
    return !$res;
}

sub runBuild {
    my ($build) = @_;
    my ($res, $stdout, $stderr) = captureStdoutStderr(60, ("../src/script/hydra-build", $build->id));
    print "STDERR: $stderr" if $stderr ne "";
    return !$res;
}

sub updateRepository {
    my ($scm, $update) = @_;
    my ($res, $stdout, $stderr) = captureStdoutStderr(60, ($update, $scm));
    die "unexpected update error with $scm: $stderr\n" if $res;
    my ($message, $loop, $status) = $stdout =~ m/::(.*) -- (.*) -- (.*)::/;
    print STDOUT "Update $scm repository: $message\n";
    return ($loop eq "continue", $status eq "updated");
}

my $ua = LWP::UserAgent->new;
$ua->cookie_jar( {} );

sub login {
    return request_json({ uri => "/login", method => "POST", data => { username => "root", password => "foobar" } });
}

sub request_json {
    my ($opts) = @_;
    my $req = HTTP::Request->new;
    $req->method($opts->{method} or "GET");
    $req->uri("http://localhost:3000$opts->{uri}");
    $req->header(Accept => "application/json");
    $req->content(encode_json($opts->{data})) if defined $opts->{data};
    return $ua->request($req);
}

1;
